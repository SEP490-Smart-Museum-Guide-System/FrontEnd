import { backend } from './backend.js';

export async function generateStaffDraft(artifactId, options, signal) {
  const id = Number(artifactId);
  if (!Number.isSafeInteger(id) || id <= 0) throw new Error('Hãy chọn hiện vật đã lưu trên máy chủ.');
  if (!['narration', 'quiz'].includes(options.mode)) throw new Error('Chế độ tạo bản nháp không hợp lệ.');
  const result = await backend(`artifacts/${id}/ai/drafts`, { method: 'POST', body: options, signal, timeoutMs: 115000 });
  if (result?.artifactId !== id || result.mode !== options.mode || result.isDraft !== true || result.languageCode !== 'vi' || !result.draft || typeof result.source?.text !== 'string') {
    throw new Error('Phản hồi AI không đúng hiện vật hoặc không phải bản nháp tiếng Việt.');
  }
  if (options.mode === 'narration' && (typeof result.draft.title !== 'string' || typeof result.draft.narrationText !== 'string' || !result.draft.narrationText.trim())) {
    throw new Error('Bản thuyết minh AI không hợp lệ.');
  }
  if (options.mode === 'quiz' && (typeof result.draft.question !== 'string' || !Array.isArray(result.draft.options) || !Number.isInteger(result.draft.correctIndex))) {
    throw new Error('Câu hỏi AI không hợp lệ.');
  }
  return result;
}
