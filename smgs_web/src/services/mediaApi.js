import { getAuthToken } from './auth.js';

const base = (import.meta.env?.VITE_API_BASE_URL ?? '/api').replace(/\/+$/, '');

export function validateMediaFile(file, model = false, maxMb = model ? 100 : 15) {
  if (!file || file.size === 0) throw new Error('Vui lòng chọn file không rỗng.');
  if (!(model ? /\.glb$/i : /\.(png|jpe?g|webp)$/i).test(file.name))
    throw new Error(model ? 'Chỉ hỗ trợ mô hình .glb tự chứa.' : 'Chọn ảnh PNG, JPEG hoặc WebP.');
  if (file.size > maxMb * 1024 * 1024) throw new Error(`File tối đa ${maxMb} MB.`);
}

export function uploadMedia(path, form, onProgress = () => {}, signal) {
  return new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest();
    const abort = () => xhr.abort();
    xhr.open('POST', `${base}/${path}`);
    xhr.setRequestHeader('Authorization', `Bearer ${getAuthToken()}`);
    xhr.timeout = 180000;
    xhr.upload.onprogress = e => { if (e.lengthComputable) onProgress(Math.round(e.loaded * 100 / e.total)); };
    xhr.onload = () => {
      let result;
      try { result = JSON.parse(xhr.responseText); } catch { /* Non-JSON gateway error. */ }
      if (xhr.status >= 200 && xhr.status < 300) resolve(result?.data);
      else reject(new Error(result?.message || `Không thể tải file (${xhr.status}).`));
    };
    xhr.onerror = () => reject(new Error('Mất kết nối khi tải file. Vui lòng thử lại.'));
    xhr.ontimeout = () => reject(new Error('Tải file quá thời gian. Vui lòng thử lại.'));
    xhr.onabort = () => reject(new DOMException('Đã hủy tải file.', 'AbortError'));
    xhr.onloadend = () => signal?.removeEventListener('abort', abort);
    if (signal?.aborted) { reject(new DOMException('Đã hủy tải file.', 'AbortError')); return; }
    signal?.addEventListener('abort', abort, { once: true });
    xhr.send(form);
  });
}

export async function mediaApi(path, { method = 'GET', blob = false, signal } = {}) {
  const response = await fetch(`${base}/${path}`, { method, signal, headers: { Authorization: `Bearer ${getAuthToken()}` } });
  if (response.ok && blob) return response.blob();
  const result = await response.json().catch(() => null);
  if (!response.ok) { const error = new Error(result?.message || `Không thể xử lý media (${response.status}).`); error.status = response.status; throw error; }
  return result?.data;
}
