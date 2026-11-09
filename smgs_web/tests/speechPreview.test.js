import test from 'node:test';
import assert from 'node:assert/strict';
import { createSpeechPreview } from '../src/services/speechPreviewApi.js';

globalThis.localStorage = { getItem: key => key === 'smgs_web_jwt_token' ? 'jwt-test-only' : null };
function wav() { const bytes = new Uint8Array(46); bytes.set(new TextEncoder().encode('RIFF')); bytes.set(new TextEncoder().encode('WAVE'), 8); return bytes; }

test('staff preview sends edited script and JWT to artifact-scoped BE and receives audio bytes', async t => {
  t.mock.method(globalThis, 'fetch', async (url, request) => {
    assert.equal(url, '/api/artifacts/17/ai/speech-preview');
    assert.equal(request.headers.Authorization, 'Bearer jwt-test-only');
    assert.deepEqual(JSON.parse(request.body), { text: 'Bản đọc đã hiệu đính.' });
    assert.ok(!Object.keys(request.headers).some(k => /service-key/i.test(k)));
    return new Response(wav(), { headers: { 'Content-Type': 'audio/wav' } });
  });
  assert.equal((await createSpeechPreview(17, ' Bản đọc đã hiệu đính. ')).size, 46);
});

test('speech preview rejects service failures and HTML/corrupt audio; it never returns demo files', async t => {
  const stub = t.mock.method(globalThis, 'fetch');
  for (const status of [403, 429, 503]) {
    stub.mock.mockImplementation(async () => new Response(JSON.stringify({ message: 'Bộ đọc chưa sẵn sàng.' }), { status }));
    await assert.rejects(createSpeechPreview(17, 'Bản đọc'), /chưa sẵn sàng/);
  }
  for (const type of ['text/html', 'audio/wav']) {
    stub.mock.mockImplementation(async () => new Response('<html>Not audio</html>', { headers: { 'Content-Type': type } }));
    await assert.rejects(createSpeechPreview(17, 'Bản đọc'), /âm thanh hợp lệ/);
  }
  await assert.rejects(createSpeechPreview('demo', 'Bản đọc'), /chọn hiện vật/);
});
