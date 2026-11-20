import test from 'node:test';
import assert from 'node:assert/strict';
import { generateStaffDraft, staffDraftRetry } from '../src/services/staffAiApi.js';
globalThis.localStorage = { getItem: () => null };

test('staff AI calls BE with real artifact ID and source; it never sends a model key', async t => {
  t.mock.method(globalThis, 'fetch', async (url, options) => {
    assert.equal(url, '/api/artifacts/17/ai/drafts');
    assert.equal(options.method, 'POST');
    assert.equal(JSON.parse(options.body).sourceText, 'Tư liệu đã kiểm chứng từ nhãn');
    assert.ok(!Object.keys(options.headers).some(k => /service-key|api-key/i.test(k)));
    return new Response(JSON.stringify({ data: { artifactId: 17, mode: 'narration', isDraft: true, languageCode: 'vi', source: { text: 'Tư liệu' }, draft: { title: 'Tiêu đề', narrationText: 'Nội dung do model trả về.' } } }));
  });
  assert.equal((await generateStaffDraft(17, { mode: 'narration', sourceText: 'Tư liệu đã kiểm chứng từ nhãn' })).isDraft, true);
});

test('AI failures and cross-artifact responses never become simulated drafts', async t => {
  const stub = t.mock.method(globalThis, 'fetch');
  for (const status of [403, 422, 502, 503]) {
    stub.mock.mockImplementation(async () => new Response(JSON.stringify({ message: 'Không có bản nháp.' }), { status }));
    await assert.rejects(generateStaffDraft(17, { mode: 'quiz' }), /Không có bản nháp/);
  }
  stub.mock.mockImplementation(async () => new Response(JSON.stringify({ data: { artifactId: 18, mode: 'quiz', isDraft: true, languageCode: 'vi', draft: {} } })));
  await assert.rejects(generateStaffDraft(17, { mode: 'quiz' }), /không đúng hiện vật/);
  await assert.rejects(generateStaffDraft('demo', { mode: 'quiz' }), /đã lưu/);
});

test('real BE configuration errors and 429 stop studio retries, while transient model errors remain bounded', async t => {
  const stub = t.mock.method(globalThis, 'fetch');
  for (const [status, message, expected] of [
    [503, 'Model AI local chưa được kết nối. Chưa tạo bản nháp nào.', 'stop'],
    [503, 'Model local chưa sẵn sàng. Vui lòng thử lại.', 'stop'],
    [429, 'Vui lòng thử lại sau.', 'stop'],
    [422, 'Tư liệu vượt giới hạn model.', 'stop'],
    [503, 'Model đang bận. Vui lòng thử lại.', 'busy'],
    [502, 'Bản nháp AI chưa hợp lệ hoặc thiếu căn cứ.', 'retry'],
  ]) {
    stub.mock.mockImplementation(async () => new Response(JSON.stringify({ message }), { status, headers: { 'Retry-After': '30' } }));
    await assert.rejects(generateStaffDraft(17, { mode: 'quiz' }), error => {
      assert.equal(error.status, status);
      assert.equal(error.retryAfterSeconds, 30);
      assert.equal(staffDraftRetry(error), expected);
      return true;
    });
  }
});
