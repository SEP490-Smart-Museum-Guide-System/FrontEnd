import test from 'node:test';
import assert from 'node:assert/strict';
import { uploadReferenceImageApi, deleteReferenceImagesApi, recognizeArtifactApi } from '../src/services/visionApi.js';

test('Vision mutations use assigned-artifact BE routes and a user JWT, without an AI service key', async t => {
  const before = { xhr: globalThis.XMLHttpRequest, storage: globalThis.localStorage };
  t.after(() => { globalThis.XMLHttpRequest = before.xhr; globalThis.localStorage = before.storage; });
  globalThis.localStorage = { getItem: () => 'staff-jwt' };
  let request;
  globalThis.XMLHttpRequest = class {
    upload = {}; headers = {};
    constructor() { request = this; }
    open(method, url) { this.method = method; this.url = url; }
    setRequestHeader(k, v) { this.headers[k] = v; }
    send(body) { this.body = body; }
  };
  const image = new File(['photo'], 'photo.png');
  const indexed = uploadReferenceImageApi({ artifactId: 7, file: image });
  assert.equal(request.url, '/api/artifacts/7/vision/references');
  assert.equal(request.headers.Authorization, 'Bearer staff-jwt');
  assert.equal(request.headers['X-Service-Key'], undefined);
  assert.equal(request.body.get('image').name, 'photo.png');
  request.status = 200; request.responseText = '{"data":{"id":4,"artifactId":7,"status":"indexed"}}'; request.onload();
  assert.deepEqual(await indexed, { ok: true, data: { id: 4, artifactId: 7, status: 'indexed' } });
  const recognition = recognizeArtifactApi({ file: image, museumId: 3 });
  assert.equal(request.url, '/api/vision/recognitions?top_k=3&museum_id=3');
  assert.equal(request.headers.Authorization, 'Bearer staff-jwt');
  request.status = 503; request.responseText = '{"message":"Chưa có ảnh tham chiếu"}'; request.onload();
  await assert.rejects(recognition, /Chưa có ảnh tham chiếu/);
  t.mock.method(globalThis, 'fetch', async (url, options) => {
    assert.equal(url, '/api/artifacts/7/vision/references');
    assert.equal(options.method, 'DELETE');
    assert.equal(options.headers.Authorization, 'Bearer staff-jwt');
    assert.equal(options.headers['X-Service-Key'], undefined);
    return new Response('{"data":{"deleted":1}}');
  });
  assert.deepEqual(await deleteReferenceImagesApi({ artifactId: 7 }), { deleted: 1 });
});
