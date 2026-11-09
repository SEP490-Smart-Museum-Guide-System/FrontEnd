import { getAuthToken } from './auth.js';

const API_BASE = (import.meta.env?.VITE_API_BASE_URL ?? '/api').replace(/\/+$/, '');

export async function createSpeechPreview(artifactId, text, signal) {
  const id = Number(artifactId);
  if (!Number.isSafeInteger(id) || id <= 0 || typeof text !== 'string' || !text.trim() || text.length > 12000) {
    throw new Error('Cần chọn hiện vật và nhập bản thuyết minh tối đa 12.000 ký tự.');
  }
  const token = getAuthToken();
  if (!token) throw new Error('Vui lòng đăng nhập lại để nghe bản thuyết minh.');
  const response = await fetch(`${API_BASE}/artifacts/${id}/ai/speech-preview`, {
    method: 'POST', headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json', Accept: 'audio/wav' },
    body: JSON.stringify({ text: text.trim() }),
    signal: signal ? AbortSignal.any([signal, AbortSignal.timeout(70000)]) : AbortSignal.timeout(70000),
  });
  if (!response.ok) {
    const error = await response.json().catch(() => null);
    throw new Error(error?.message || 'Chưa tạo được giọng đọc. Vui lòng thử lại.');
  }
  const blob = await response.blob();
  const header = new Uint8Array(await blob.slice(0, 12).arrayBuffer());
  const ascii = (start, end) => String.fromCharCode(...header.slice(start, end));
  if (!response.headers.get('content-type')?.startsWith('audio/wav') || blob.size < 46 || ascii(0, 4) !== 'RIFF' || ascii(8, 12) !== 'WAVE') {
    throw new Error('Máy chủ chưa trả về tệp âm thanh hợp lệ.');
  }
  return blob;
}
