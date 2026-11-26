import { backend } from './backend.js';

export function staffDraftRetry(error) {
  // A missing server setting cannot recover by spending nine more requests.
  // Rate limits require a new user attempt after the server's cooldown.
  if ([401, 403, 404, 422, 429, 504].includes(error.status)) return 'stop';
  if (/chưa.*(?:kết nối|cấu hình)|khóa.*chưa đúng/i.test(error.message || '')) return 'stop';
  if (error.status === 503 && /đang bận/i.test(error.message || '')) return 'busy';
  return error.status === 502 || error.retryable === true ? 'retry' : 'stop';
}

export async function generateStaffDraft(artifactId, options, signal) {
  const id = Number(artifactId);
  if (!Number.isSafeInteger(id) || id <= 0) throw new Error('Hãy chọn hiện vật đã lưu trên máy chủ.');
  if (!['narration', 'quiz'].includes(options.mode)) throw new Error('Chế độ tạo bản nháp không hợp lệ.');
  const result = await backend(`artifacts/${id}/ai/drafts`, { method: 'POST', body: options, signal, timeoutMs: 240000 });
  if (result?.artifactId !== id || result.mode !== options.mode || result.isDraft !== true || result.languageCode !== (options.languageCode || 'vi') || !result.draft || typeof result.source?.text !== 'string') {
    throw new Error('Phản hồi AI không đúng hiện vật hoặc không khớp ngôn ngữ bản nháp đã chọn.');
  }
  if (options.mode === 'narration' && (typeof result.draft.title !== 'string' || typeof result.draft.narrationText !== 'string' || !result.draft.narrationText.trim())) {
    throw new Error('Bản thuyết minh AI không hợp lệ.');
  }
  if (options.mode === 'quiz' && Number(options.count || 1) > 1) {
    const set = result.draft;
    const requested = Number(options.count);
    if (set.requestedCount !== requested || !Array.isArray(set.questions) || set.generatedCount !== set.questions.length
      || set.generatedCount < 1 || set.generatedCount > requested || set.complete !== (set.generatedCount === requested)
      || set.isDraft !== true || set.reviewRequired !== true || !Array.isArray(set.warnings)
      || set.questions.some(question => typeof question?.question !== 'string' || !question.question.trim()
        || !Array.isArray(question.options) || question.options.length !== 4
        || !Number.isInteger(question.correctIndex) || question.correctIndex < 0 || question.correctIndex > 3
        || typeof question.explanation !== 'string' || !question.explanation.trim()
        || typeof question.evidenceQuote !== 'string' || !question.evidenceQuote.trim())) {
      throw new Error('Bộ câu hỏi AI trả về không hợp lệ.');
    }
  } else if (options.mode === 'quiz' && (typeof result.draft.question !== 'string' || !Array.isArray(result.draft.options) || !Number.isInteger(result.draft.correctIndex))) {
    throw new Error('Câu hỏi AI không hợp lệ.');
  }
  return result;
}
