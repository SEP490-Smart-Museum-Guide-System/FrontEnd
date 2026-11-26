import { backend } from './backend.js';
import { mediaApi, uploadMedia, validateMediaFile } from './mediaApi.js';

export const scanPath = (artifactId, jobId = '') => `artifacts/${artifactId}/scans${jobId ? '/' + encodeURIComponent(jobId) : ''}`;
export const getScanJobs = (id, signal) => backend(scanPath(id), { signal });
export const getScanJob = (id, job, signal) => backend(scanPath(id, job), { signal });
export const getScanModel = (id, job, signal) => mediaApi(scanPath(id, job) + '/model', { blob: true, signal });
export const saveScanModel = (id, job) => backend(scanPath(id, job) + '/save', { method: 'POST', timeoutMs: 180000 });
export const discardScanModel = (id, job) => backend(scanPath(id, job) + '/discard', { method: 'POST' });
export const cancelScanJob = (id, job) => backend(scanPath(id, job) + '/cancel', { method: 'POST', timeoutMs: 30000 });
export const SCAN_UPLOAD_TIMEOUT_MS = 15 * 60 * 1000;
const activeScan = job => ['QUEUED', 'PROCESSING', 'FINALIZING', 'REVIEW_REQUIRED'].includes(job?.status);

// Never automatically resend an ambiguous upload: the server may already have
// persisted a job even when the 202 response is lost.
export async function startScanSafely(id, dataset, { onProgress, signal, getJobs = getScanJobs, upload = startArtifactScan } = {}) {
  const before = await getJobs(id, signal);
  const existing = before.find(activeScan);
  if (existing) return { job: existing, recovered: true };
  try {
    const job = await upload(id, dataset, onProgress, signal);
    if (!job?.scanJobId || Number(job.artifactId) !== Number(id)) {
      const error = new Error('Máy chủ chưa xác nhận mã tác vụ.');
      error.code = 'UPLOAD_RESPONSE_INVALID';
      throw error;
    }
    return { job, recovered: false };
  } catch (error) {
    if (signal?.aborted || error.name === 'AbortError') throw error;
    const ambiguous = ['UPLOAD_NETWORK', 'UPLOAD_TIMEOUT', 'UPLOAD_RESPONSE_INVALID'].includes(error.code) || error.status >= 500;
    if (!ambiguous) throw error;
    try {
      const known = new Set(before.map(job => job.scanJobId));
      const after = await getJobs(id, signal);
      const received = after.filter(job => Number(job.artifactId) === Number(id) && !known.has(job.scanJobId));
      if (received.length === 1) return { job: received[0], recovered: true };
    } catch { /* Keep the original upload error and require an explicit job check. */ }
    error.requiresJobCheck = true;
    error.message = 'Chưa xác nhận được máy chủ đã nhận bộ ảnh. Kiểm tra job đã nhận trước khi gửi lại để tránh tạo trùng.';
    throw error;
  }
}

export function prepareScanDataset(files, mode = 'auto', { quality = 'balanced', captureOrder = 'unordered' } = {}) {
  if (!['balanced', 'detailed', 'preview'].includes(quality) || !['unordered', 'ordered'].includes(captureOrder)) throw new Error('Chất lượng hoặc thứ tự ảnh không hợp lệ.');
  const entries = Array.from(files || []);
  const path = f => (f.webkitRelativePath || f.name).replaceAll('\\', '/');
  const imageFolders = new Set(entries.filter(f => /(^|\/)images\/[^/]+\.(png|jpe?g)$/i.test(path(f))).map(f => path(f).slice(0, path(f).lastIndexOf('/'))));
  if (imageFolders.size > 1) throw new Error('Chọn folder của một hiện vật, không chọn nhiều dataset cùng lúc.');
  const images = entries.filter(f => /\.(png|jpe?g)$/i.test(f.name) && (!imageFolders.size || path(f).startsWith([...imageFolders][0] + '/')));
  // Explicit ordered capture uses natural filename order, consistently across browsers.
  if (captureOrder === 'ordered') images.sort((a, b) => path(a).localeCompare(path(b), 'en', { numeric: true }));
  if (images.length < 5 || images.length > 200) throw new Error('Chọn từ 5 đến 200 ảnh JPG/PNG của cùng một hiện vật.');
  const metadataFiles = entries.filter(f => f.name.toLowerCase() === 'metadata.json');
  const objects = entries.filter(f => /\.obj$/i.test(f.name));
  if (mode !== 'photos' && (objects.length > 1 || metadataFiles.length > 1)) throw new Error('Folder chứa nhiều hiện vật hoặc nhiều file tham chiếu.');
  const metadata = mode === 'photos' ? null : metadataFiles[0];
  const referenceObj = mode === 'photos' ? null : objects[0];
  // Auto mode only enables benchmark when the complete reference pair exists.
  // An incomplete optional pair falls back to ordinary photo reconstruction.
  const selected = metadata && referenceObj ? 'benchmark' : 'photos';
  if (mode === 'benchmark' && selected !== 'benchmark') throw new Error('Thiếu metadata.json hoặc OBJ tham chiếu.');
  const selectedMetadata = selected === 'benchmark' ? metadata : null;
  const selectedReferenceObj = selected === 'benchmark' ? referenceObj : null;
  if (images.some(f => f.size <= 0 || f.size > 20 * 1024 * 1024)) throw new Error('Mỗi ảnh phải lớn hơn 0 và không quá 20 MiB.');
  if (selectedMetadata?.size > 2 * 1024 * 1024 || selectedReferenceObj?.size > 64 * 1024 * 1024) throw new Error('Metadata tối đa 2 MiB; OBJ tối đa 64 MiB.');
  const bytes = images.reduce((sum, f) => sum + f.size, 0) + (selectedMetadata?.size || 0) + (selectedReferenceObj?.size || 0);
  if (bytes > 500 * 1024 * 1024) throw new Error('Bộ dữ liệu tối đa 500 MiB.');
  return { images, metadata: selectedMetadata, referenceObj: selectedReferenceObj, mode: selected, bytes, quality, captureOrder };
}

export function startArtifactScan(id, dataset, progress, signal) {
  const form = new FormData();
  form.append('mode', dataset.mode);
  form.append('quality', dataset.quality || 'balanced');
  form.append('captureOrder', dataset.captureOrder || 'unordered');
  for (const image of dataset.images) form.append('images', image, image.name);
  if (dataset.metadata) form.append('metadata', dataset.metadata, 'metadata.json');
  if (dataset.referenceObj) form.append('referenceObj', dataset.referenceObj, dataset.referenceObj.name);
  return uploadMedia(scanPath(id), form, progress, signal, { timeoutMs: SCAN_UPLOAD_TIMEOUT_MS });
}

export async function validateGlbPreview(file) {
  validateMediaFile(file, true);
  const header = new DataView(await file.slice(0, 12).arrayBuffer());
  if (header.byteLength < 12 || header.getUint32(0, true) !== 0x46546c67 || header.getUint32(4, true) !== 2 || header.getUint32(8, true) !== file.size)
    throw new Error('File không phải GLB 2 hợp lệ hoặc bị thiếu dữ liệu.');
}
