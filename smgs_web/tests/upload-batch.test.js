import { test } from 'node:test';
import assert from 'node:assert/strict';
import { uploadBatch } from '../src/services/uploadBatch.js';
test('partial photo failure retries only failed images, retaining successful uploads', async () => {
  const files = [{name:'a.jpg'}, {name:'b.jpg'}, {name:'c.jpg'}], calls = [];
  const first = await uploadBatch(files, {upload: async file => {calls.push(file.name); if(file.name === 'b.jpg') throw new Error('Lỗi mạng'); return file.name; }});
  assert.deepEqual(first.saved.map(x => x.file.name), ['a.jpg','c.jpg']);
  assert.equal(first.failed[0].message, 'Lỗi mạng');
  const retry = await uploadBatch(first.failed.map(x => x.file), {upload: async file => {calls.push(file.name); return file.name; }});
  assert.deepEqual(calls, ['a.jpg','b.jpg','c.jpg','b.jpg']); assert.equal(retry.saved.length,1);
});
test('cancellation prevents remaining uploads and leaves them available for retry', async () => {
  const controller = new AbortController();
  const result = await uploadBatch([1,2,3], {signal:controller.signal, upload:async file => {controller.abort(); return file; }});
  assert.equal(result.saved.length,1); assert.deepEqual(result.failed.map(x => x.file),[2,3]);
});
