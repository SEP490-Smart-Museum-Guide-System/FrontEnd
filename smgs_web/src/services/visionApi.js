import { backend } from './backend.js';
import { uploadMedia } from './mediaApi.js';

// The BE checks the user's museum assignment and supplies the private Vision key.
export async function checkVisionHealthApi() {
  try {
    const data = await backend('vision/health', { timeoutMs: 8000 });
    return {
      ok: data?.status === 'ok',
      status: data?.status || 'unknown',
      referenceCount: data?.reference_images ?? data?.reference_count ?? 0,
      modelReady: data?.model_ready ?? false,
    };
  } catch (error) {
    return { ok: false, status: error.status ? `HTTP ${error.status}` : 'unavailable', referenceCount: 0, error: error.message };
  }
}

export async function uploadReferenceImageApi({ artifactId, file }) {
  const form = new FormData();
  form.append('image', file);
  const data = await uploadMedia(`artifacts/${encodeURIComponent(artifactId)}/vision/references`, form);
  return { ok: true, data };
}

export function deleteReferenceImagesApi({ artifactId }) {
  return backend(`artifacts/${encodeURIComponent(artifactId)}/vision/references`, { method: 'DELETE' });
}

export function recognizeArtifactApi({ file, topK = 3, museumId }) {
  const form = new FormData();
  form.append('image', file);
  const query = new URLSearchParams({ top_k: String(topK) });
  if (museumId != null) query.set('museum_id', String(museumId));
  return uploadMedia(`vision/recognitions?${query}`, form);
}
