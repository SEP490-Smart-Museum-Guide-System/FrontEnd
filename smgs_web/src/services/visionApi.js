/**
 * AI Vision Integration Service
 * Connects to SMGS Artifact Vision Microservice (Port 8001)
 * Extracts 512-d CLIP ViT-B/32 ONNX vector embeddings for visual artifact recognition.
 */

const VISION_BASE = (import.meta.env?.VITE_VISION_API_URL ?? '/ai-vision').replace(/\/+$/, '');
const DEFAULT_SERVICE_KEY = import.meta.env?.VITE_AI_SERVICE_API_KEY || 'local-curator-key';

/**
 * Check health and number of indexed reference embeddings
 * @returns {Promise<{ ok: boolean, status: string, referenceCount: number }>}
 */
export async function checkVisionHealthApi() {
  try {
    const response = await fetch(`${VISION_BASE}/health`, {
      method: 'GET',
      headers: { 'Accept': 'application/json' },
      signal: AbortSignal.timeout(4000)
    });
    if (!response.ok) {
      return { ok: false, status: `HTTP ${response.status}`, referenceCount: 0 };
    }
    const data = await response.json();
    return {
      ok: data?.status === 'ok',
      status: data?.status || 'unknown',
      referenceCount: data?.reference_count ?? 0,
      modelReady: data?.model_ready ?? false
    };
  } catch (error) {
    return { ok: false, status: 'unavailable', referenceCount: 0, error: error.message };
  }
}

/**
 * Index a reference image for an artifact into the vector database
 * @param {Object} params
 * @param {number|string} params.artifactId - ID of the target artifact
 * @param {File|Blob} params.file - Image file to index
 * @param {string} [params.serviceKey] - X-Service-Key authentication header
 * @returns {Promise<{ ok: boolean, message: string }>}
 */
export async function uploadReferenceImageApi({ artifactId, file, serviceKey = DEFAULT_SERVICE_KEY }) {
  const formData = new FormData();
  formData.append('image', file);

  const response = await fetch(`${VISION_BASE}/api/v1/references?artifact_id=${encodeURIComponent(artifactId)}`, {
    method: 'POST',
    headers: {
      'X-Service-Key': serviceKey
    },
    body: formData
  });

  if (!response.ok) {
    let detail = `Lỗi lập chỉ mục ảnh tham chiếu (${response.status})`;
    try {
      const errJson = await response.json();
      if (errJson?.detail) detail = errJson.detail;
    } catch {}
    throw new Error(detail);
  }

  const data = await response.json();
  return { ok: true, data };
}

/**
 * Delete all reference embeddings for an artifact
 * @param {Object} params
 * @param {number|string} params.artifactId
 * @param {string} [params.serviceKey]
 */
export async function deleteReferenceImagesApi({ artifactId, serviceKey = DEFAULT_SERVICE_KEY }) {
  const response = await fetch(`${VISION_BASE}/api/v1/references/${encodeURIComponent(artifactId)}`, {
    method: 'DELETE',
    headers: {
      'X-Service-Key': serviceKey
    }
  });

  if (!response.ok) {
    let detail = `Lỗi gỡ bỏ ảnh tham chiếu (${response.status})`;
    try {
      const errJson = await response.json();
      if (errJson?.detail) detail = errJson.detail;
    } catch {}
    throw new Error(detail);
  }

  return response.json();
}

/**
 * Recognize an artifact from an uploaded or captured photo
 * @param {Object} params
 * @param {File|Blob} params.file
 * @param {number} [params.topK=3]
 * @param {string} [params.serviceKey]
 * @returns {Promise<{ matched: boolean, artifactId?: number, similarity: number, margin: number, requiresConfirmation: boolean, topCandidates: Array }>}
 */
export async function recognizeArtifactApi({ file, topK = 3, serviceKey = DEFAULT_SERVICE_KEY }) {
  const formData = new FormData();
  formData.append('image', file);

  const response = await fetch(`${VISION_BASE}/api/v1/recognitions?top_k=${topK}`, {
    method: 'POST',
    headers: {
      'X-Service-Key': serviceKey
    },
    body: formData
  });

  if (!response.ok) {
    let detail = `Lỗi nhận diện ảnh (${response.status})`;
    try {
      const errJson = await response.json();
      if (errJson?.detail) detail = errJson.detail;
    } catch {}
    throw new Error(detail);
  }

  return response.json();
}
