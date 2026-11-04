import test from 'node:test';
import assert from 'node:assert/strict';
import { allPages, backend, artifactView, museumView } from '../src/services/backend.js';

globalThis.localStorage = { getItem: () => null };
const response = data => new Response(JSON.stringify({ data }));
test('empty DB lists remain empty; an array endpoint is never paginated repeatedly', async t => {
  t.mock.method(globalThis, 'fetch', async () => response([]));
  assert.deepEqual(await allPages('museums'), []);
  const rows = Array.from({ length: 50 }, (_, id) => ({ id }));
  globalThis.fetch = t.mock.fn(async () => response(rows));
  assert.deepEqual(await allPages('commerce/museums/7/products'), rows);
  assert.equal(globalThis.fetch.mock.callCount(), 1);
});

test('all pages are loaded without losing filters or duplicating records', async t => {
  const urls = [];
  t.mock.method(globalThis, 'fetch', async url => {
    urls.push(url);
    const page = Number(new URL(url, 'https://example.invalid').searchParams.get('page'));
    return response({ items: [{ id: page }], totalPages: 2, totalCount: 2 });
  });
  assert.deepEqual(await allPages('artifacts?museumId=7'), [{ id: 1 }, { id: 2 }]);
  assert.ok(urls.every(url => url.includes('museumId=7')));
});

test('HTTP errors and malformed success responses never become empty or sample data', async t => {
  const stub = t.mock.method(globalThis, 'fetch');
  for (const status of [401, 403, 500]) {
    stub.mock.mockImplementation(async () => new Response(JSON.stringify({ message: 'Không thể tải dữ liệu' }), { status }));
    await assert.rejects(allPages('museums'), /Không thể tải dữ liệu/);
  }
  stub.mock.mockImplementation(async () => response({ invalid: true }));
  await assert.rejects(allPages('artifacts'), /không hợp lệ/);
  stub.mock.mockImplementation(async () => new Response('{}'));
  await assert.rejects(backend('museums'), /không hợp lệ/);
});

test('adapters do not invent geographic, media, QR or analytics values', () => {
  const museum = museumView({ id: 7, name: 'Bảo tàng từ DB', isActive: true });
  assert.equal(museum.image, '');
  assert.equal(museum.latitude, undefined);
  assert.equal(museum.openingHours, '');
  const artifact = artifactView({ id: 1, museumId: 7, name: 'Hiện vật từ DB' });
  assert.equal(artifact.code, '');
  assert.equal(artifact.qrCode, '');
  assert.equal(artifact.scansCount, undefined);
  assert.equal(artifact.modelUrl, '');
});

test('array endpoints with pagination fetch the next page while preserving filters', async t => {
  const calls = [];
  t.mock.method(globalThis, 'fetch', async url => {
    calls.push(url); const page = Number(new URL(url, 'https://example.invalid').searchParams.get('page'));
    return response(page === 1 ? Array.from({ length: 50 }, (_, id) => ({ id })) : [{ id: 50 }]);
  });
  const rows = await allPages('question-bank/questions?artifactId=11', { pagedArray: true });
  assert.equal(rows.length, 51); assert.equal(calls.length, 2);
  assert.ok(calls.every(url => url.includes('artifactId=11')));
});
