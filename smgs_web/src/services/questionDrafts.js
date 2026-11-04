// AI output is only a draft. The editor still requires every option before saving.
export function parseQuestionDrafts(text) {
  let rows;
  try { rows = JSON.parse(text); } catch { throw new Error('Nội dung câu hỏi cần là danh sách JSON hợp lệ. Hãy chỉnh lại hoặc nhập câu hỏi trong Ngân hàng câu hỏi.'); }
  if (!Array.isArray(rows) || !rows.length || rows.length > 100) throw new Error('Cần từ 1 đến 100 câu hỏi gợi ý.');
  return rows.map((row, index) => {
    if (!row || typeof row.question !== 'string' || !row.question.trim() || row.question.length > 4000 || !Array.isArray(row.options) || row.options.length < 2 || row.options.length > 6 || !Number.isInteger(row.correctIndex) || row.correctIndex < 0 || row.correctIndex >= row.options.length) throw new Error(`Câu ${index + 1} chưa có nội dung, lựa chọn hoặc đáp án đúng hợp lệ.`);
    const options = row.options.map((content, i) => {
      if (content != null && typeof content !== 'string' || (content?.length || 0) > 1000) throw new Error(`Đáp án của câu ${index + 1} không hợp lệ.`);
      return { content: content || '', isCorrect: i === row.correctIndex };
    });
    if (row.explanation != null && (typeof row.explanation !== 'string' || row.explanation.length > 4000)) throw new Error(`Giải thích câu ${index + 1} không hợp lệ.`);
    return { content: row.question, options, explanation: row.explanation || '', languageCode: 'vi' };
  });
}
