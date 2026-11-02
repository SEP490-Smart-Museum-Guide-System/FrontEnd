import test from 'node:test';
import assert from 'node:assert/strict';
import { validateMediaFile, uploadMedia, mediaApi } from '../src/services/mediaApi.js';

test('image/GLB selection rejects empty, unsupported, external glTF and oversized files', () => {
  validateMediaFile({ name: 'image.webp', size: 12 });
  validateMediaFile({ name: 'model.glb', size: 12 }, true);
  for (const file of [null, { name: 'a.png', size: 0 }, { name: 'a.svg', size: 10 }, { name: 'a.png', size: 16 * 1024 * 1024 }])
    assert.throws(() => validateMediaFile(file));
  assert.throws(() => validateMediaFile({ name: 'a.gltf', size: 10 }, true));
});

test('authenticated multipart upload reports progress, API errors and cancellation', async () => {
  const oldXHR = globalThis.XMLHttpRequest, oldStorage = globalThis.localStorage;
  globalThis.localStorage = { getItem: key => key === 'smgs_web_jwt_token' ? 'test-token' : null };
  let request;
  globalThis.XMLHttpRequest = class {
    upload = {}; headers = {};
    constructor() { request = this; }
    open(method, url) { this.method = method; this.url = url; }
    setRequestHeader(key, value) { this.headers[key] = value; }
    send(body) { this.body = body; }
    abort() { this.onabort(); this.onloadend(); }
  };
  try {
    let progress;
    const form = new FormData(); form.append('file', new Blob(['content']), 'a.png');
    const promise = uploadMedia('artifacts/1/media', form, value => progress = value);
    assert.equal(request.headers.Authorization, 'Bearer test-token');
    assert.equal(request.headers['Content-Type'], undefined);
    assert.equal(request.body, form);
    request.upload.onprogress({ lengthComputable: true, loaded: 5, total: 10 }); assert.equal(progress, 50);
    request.status = 201; request.responseText = '{"data":{"id":1}}'; request.onload(); request.onloadend();
    assert.deepEqual(await promise, { id: 1 });
    const failed = uploadMedia('museums/1/image', form);
    request.status = 503; request.responseText = '{"message":"Storage unavailable"}'; request.onload(); request.onloadend();
    await assert.rejects(failed, /Storage unavailable/);
    const controller = new AbortController(); const canceled = uploadMedia('artifacts/1/model-3d', form, undefined, controller.signal);
    controller.abort(); await assert.rejects(canceled, { name: 'AbortError' });
    const timeout = uploadMedia('artifacts/1/model-3d', form); request.ontimeout(); await assert.rejects(timeout, /quá thời gian/);
  } finally { globalThis.XMLHttpRequest = oldXHR; globalThis.localStorage = oldStorage; }
});

test('preview and deletion use backend authentication without R2 credentials', async () => {
  const oldFetch = globalThis.fetch, oldStorage = globalThis.localStorage;
  globalThis.localStorage = { getItem: () => 'token' };
  globalThis.fetch = async (url, options) => {
    assert.equal(options.headers.Authorization, 'Bearer token');
    assert.equal(url, '/api/artifacts/1/media/2/file');
    return new Response('image', { status: 200 });
  };
  try { assert.equal(await (await mediaApi('artifacts/1/media/2/file', { blob: true })).text(), 'image'); }
  finally { globalThis.fetch = oldFetch; globalThis.localStorage = oldStorage; }
});
