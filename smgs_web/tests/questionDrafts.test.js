import test from 'node:test';
import assert from 'node:assert/strict';
import { parseQuestionDrafts } from '../src/services/questionDrafts.js';
test('AI suggestions map to editable Vietnamese question drafts and never include persistence IDs', () => {
  const [draft] = parseQuestionDrafts(JSON.stringify([{ question: 'Câu hỏi gợi ý', options: ['A', 'B'], correctIndex: 1, explanation: 'Giải thích' }]));
  assert.deepEqual(draft, { content: 'Câu hỏi gợi ý', languageCode: 'vi', explanation: 'Giải thích', options: [{ content: 'A', isCorrect: false }, { content: 'B', isCorrect: true }] });
  assert.equal(draft.id, undefined);
});
test('missing source facts remain blank for the required editor rather than fabricated', () => {
  const [draft] = parseQuestionDrafts(JSON.stringify([{ question: 'Câu hỏi gợi ý', options: [null, 'B'], correctIndex: 0 }]));
  assert.equal(draft.options[0].content, '');
});
test('malformed or unsupported suggestions cannot be submitted as questions', () => {
  for (const value of ['not json', '{}', '[]', JSON.stringify([{ question: 'Q', options: ['A', 'B'], correctIndex: 5 }]), JSON.stringify([{ question: '', options: ['A', 'B'], correctIndex: 0 }])]) assert.throws(() => parseQuestionDrafts(value));
});
