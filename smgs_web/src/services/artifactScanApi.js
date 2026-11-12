import { backend } from './backend.js';
import { mediaApi, uploadMedia, validateMediaFile } from './mediaApi.js';

export const scanPath = (artifactId, jobId = '') => `artifacts/${artifactId}/scans${jobId ? '/' + encodeURIComponent(jobId) : ''}`;
export const getScanJobs = (id, signal) => backend(scanPath(id), { signal });
export const getScanJob = (id, job, signal) => backend(scanPath(id, job), { signal });
export const getScanModel = (id, job, signal) => mediaApi(scanPath(id, job) + '/model', { blob: true, signal });
export const saveScanModel = (id, job) => backend(scanPath(id, job) + '/save', { method: 'POST', timeoutMs: 180000 });
export const discardScanModel = (id, job) => backend(scanPath(id, job) + '/discard', { method: 'POST' });

export function prepareScanDataset(files, mode = 'auto') {
  const entries = Array.from(files || []);
  const path = f => (f.webkitRelativePath || f.name).replaceAll('\\', '/');
  const imageFolders = new Set(entries.filter(f => /(^|\/)images\/[^/]+\.(png|jpe?g)$/i.test(path(f))).map(f => path(f).slice(0, path(f).lastIndexOf('/'))));
  if (imageFolders.size > 1) throw new Error('Chọn folder của một hiện vật, không chọn nhiều dataset cùng lúc.');
  const images = entries.filter(f => /\.(png|jpe?g)$/i.test(f.name) && (!imageFolders.size || path(f).startsWith([...imageFolders][0] + '/')));
  if (images.length < 5 || images.length > 200) throw new Error('Chọn từ 5 đến 200 ảnh JPG/PNG của cùng một hiện vật.');
  const metadataFiles = entries.filter(f => f.name.toLowerCase() === 'metadata.json');
  const objects = entries.filter(f => /\.obj$/i.test(f.name));
  if (mode !== 'photos' && (objects.length > 1 || metadataFiles.length > 1)) throw new Error('Folder chứa nhiều hiện vật hoặc nhiều file tham chiếu.');
  const metadata = mode === 'photos' ? null : metadataFiles[0];
  const referenceObj = mode === 'photos' ? null : objects[0];
  if (Boolean(metadata) !== Boolean(referenceObj)) throw new Error('Cần cả metadata.json và OBJ, hoặc chọn chế độ chỉ ảnh.');
  const selected = metadata && referenceObj ? 'benchmark' : 'photos';
  if (mode === 'benchmark' && selected !== 'benchmark') throw new Error('Thiếu metadata.json hoặc OBJ tham chiếu.');
  if (images.some(f => f.size <= 0 || f.size > 20 * 1024 * 1024)) throw new Error('Mỗi ảnh phải lớn hơn 0 và không quá 20 MiB.');
  if (metadata?.size > 2 * 1024 * 1024 || referenceObj?.size > 64 * 1024 * 1024) throw new Error('Metadata tối đa 2 MiB; OBJ tối đa 64 MiB.');
  const bytes = images.reduce((sum, f) => sum + f.size, 0) + (metadata?.size || 0) + (referenceObj?.size || 0);
  if (bytes > 500 * 1024 * 1024) throw new Error('Bộ dữ liệu tối đa 500 MiB.');
  return { images, metadata, referenceObj, mode: selected, bytes };
}

export function startArtifactScan(id, dataset, progress, signal) {
  const form = new FormData();
  form.append('mode', dataset.mode);
  for (const image of dataset.images) form.append('images', image, image.name);
  if (dataset.metadata) form.append('metadata', dataset.metadata, 'metadata.json');
  if (dataset.referenceObj) form.append('referenceObj', dataset.referenceObj, dataset.referenceObj.name);
  return uploadMedia(scanPath(id), form, progress, signal);
}

export async function validateGlbPreview(file) {
  validateMediaFile(file, true);
  const header = new DataView(await file.slice(0, 12).arrayBuffer());
  if (header.byteLength < 12 || header.getUint32(0, true) !== 0x46546c67 || header.getUint32(4, true) !== 2 || header.getUint32(8, true) !== file.size)
    throw new Error('File không phải GLB 2 hợp lệ hoặc bị thiếu dữ liệu.');
}
