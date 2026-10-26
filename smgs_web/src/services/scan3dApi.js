/**
 * 3D Scan Integration Service
 * Connects to SMGS 3D Photogrammetry Scan Service (Port 8002 / 8012)
 * Orchestrates multi-photo COLMAP reconstruction to 3D GLB models with curator approval gate.
 */

const SCAN_BASE = (import.meta.env?.VITE_SCAN_API_URL ?? '/ai-scan').replace(/\/+$/, '');
const DEFAULT_SERVICE_KEY = import.meta.env?.VITE_SCAN_SERVICE_API_KEY || 'dev-only-change-this-key';

/**
 * Check if the 3D Scan service is available
 * @returns {Promise<{ ok: boolean, status: string, colmapAvailable?: boolean }>}
 */
export async function checkScanHealthApi() {
  try {
    const response = await fetch(`${SCAN_BASE}/health`, {
      method: 'GET',
      headers: { 'Accept': 'application/json' },
      signal: AbortSignal.timeout(4000)
    });
    if (!response.ok) {
      return { ok: false, status: `HTTP ${response.status}` };
    }
    const data = await response.json();
    return {
      ok: data?.status === 'ok',
      status: data?.status || 'unknown',
      colmapAvailable: data?.colmap_available ?? false
    };
  } catch (error) {
    return { ok: false, status: 'unavailable', error: error.message };
  }
}

/**
 * Submit multi-photo dataset for 3D Photogrammetry reconstruction
 * @param {Object} params
 * @param {number|string} params.artifactId - ID of the target artifact
 * @param {FileList|File[]} params.files - 10 to 80 photos taken around the object
 * @param {Object} [params.metadata] - Device / capture metadata
 * @param {string} [params.serviceKey]
 * @returns {Promise<{ scanJobId: string, artifactId: number, status: string }>}
 */
export async function submitScanJobApi({ artifactId, files, metadata = {}, serviceKey = DEFAULT_SERVICE_KEY }) {
  if (!files || files.length < 3) {
    throw new Error('Cần tối thiểu 3 ảnh nhiều góc để tiến hành tái tạo 3D (khuyến nghị 15-40 ảnh).');
  }

  const formData = new FormData();
  formData.append('artifact_id', String(artifactId));
  formData.append('capture_metadata', JSON.stringify({ device: 'SMGS Curator Web Portal', ...metadata }));

  for (const file of Array.from(files)) {
    formData.append('images', file);
  }

  const response = await fetch(`${SCAN_BASE}/api/v1/scans`, {
    method: 'POST',
    headers: {
      'X-Service-Key': serviceKey
    },
    body: formData
  });

  if (!response.ok) {
    let detail = `Lỗi khởi tạo tác vụ quét 3D (${response.status})`;
    try {
      const errJson = await response.json();
      if (errJson?.detail) detail = errJson.detail;
    } catch {}
    throw new Error(detail);
  }

  return response.json();
}

/**
 * Check reconstruction job status
 * @param {string} scanJobId
 * @param {string} [serviceKey]
 * @returns {Promise<{ scanJobId: string, artifactId: number, status: 'QUEUED'|'PROCESSING'|'REVIEW_REQUIRED'|'COMPLETED'|'FAILED', modelUrl?: string, errorMessage?: string }>}
 */
export async function getScanJobStatusApi(scanJobId, serviceKey = DEFAULT_SERVICE_KEY) {
  const response = await fetch(`${SCAN_BASE}/api/v1/scans/${encodeURIComponent(scanJobId)}`, {
    method: 'GET',
    headers: {
      'Accept': 'application/json',
      'X-Service-Key': serviceKey
    }
  });

  if (!response.ok) {
    let detail = `Lỗi kiểm tra tiến trình 3D (${response.status})`;
    try {
      const errJson = await response.json();
      if (errJson?.detail) detail = errJson.detail;
    } catch {}
    throw new Error(detail);
  }

  return response.json();
}

/**
 * Approve reconstructed GLB model for publication
 * @param {string} scanJobId
 * @param {string} [serviceKey]
 */
export async function approveScanJobApi(scanJobId, serviceKey = DEFAULT_SERVICE_KEY) {
  const response = await fetch(`${SCAN_BASE}/api/v1/scans/${encodeURIComponent(scanJobId)}/approve`, {
    method: 'POST',
    headers: {
      'Accept': 'application/json',
      'X-Service-Key': serviceKey
    }
  });

  if (!response.ok) {
    let detail = `Lỗi phê duyệt mô hình 3D (${response.status})`;
    try {
      const errJson = await response.json();
      if (errJson?.detail) detail = errJson.detail;
    } catch {}
    throw new Error(detail);
  }

  return response.json();
}
