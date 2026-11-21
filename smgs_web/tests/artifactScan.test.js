import test from 'node:test';
import assert from 'node:assert/strict';
import { prepareScanDataset, validateGlbPreview, startScanSafely, cancelScanJob } from '../src/services/artifactScanApi.js';
import { scanProgress } from '../src/components/artifacts/scanProgress.js';
const file = (name, path = name, size = 100) => ({ name, webkitRelativePath: path, size });
const photos = Array.from({ length: 5 }, (_, i) => file(`${i}.png`, `dataset/images/${i}.png`));

test('cancel reaches the artifact-scoped backend with JWT and preserves a rejected request', async t => {
  const storage = globalThis.localStorage;
  globalThis.localStorage = { getItem: () => 'staff-token' };
  t.after(() => { globalThis.localStorage = storage; });
  let rejected = false;
  t.mock.method(globalThis, 'fetch', async (url, options) => {
    assert.equal(url, '/api/artifacts/7/scans/job-id/cancel');
    assert.equal(options.method, 'POST');
    assert.equal(options.headers.Authorization, 'Bearer staff-token');
    return new Response(JSON.stringify(rejected ? { message: 'Job đã hoàn tất' } : { data: { status: 'CANCELLED', progress: 45 } }), { status: rejected ? 409 : 200 });
  });
  assert.deepEqual(await cancelScanJob(7, 'job-id'), { status: 'CANCELLED', progress: 45 });
  rejected = true;
  await assert.rejects(cancelScanJob(7, 'job-id'), /Job đã hoàn tất/);
  for (const status of ['FAILED', 'CANCELLED', 'DISCARDED']) {
    assert.equal(scanProgress({ job: { status, progress: 45 } }).running, false);
  }
});

test('folder excludes atlas, keeps image filenames and chooses calibrated benchmark only with both references', () => {
  const data = prepareScanDataset([...photos, file('atlas.jpg', 'dataset/atlas.jpg'), file('metadata.json'), file('source.obj')]);
  assert.equal(data.images.length, 5); assert.equal(data.mode, 'benchmark');
  assert.equal(prepareScanDataset(photos).mode, 'photos');
  assert.equal(prepareScanDataset([...photos, file('source.obj')], 'photos').mode, 'photos');
  assert.throws(() => prepareScanDataset([...photos, file('source.obj')]), /metadata/);
  assert.throws(() => prepareScanDataset(photos, 'benchmark'), /Thiếu/);
});
test('reject mixed datasets and invalid upload sizes', () => {
  assert.throws(() => prepareScanDataset(photos.slice(1)), /5 đến 200/);
  assert.throws(() => prepareScanDataset([...photos, file('x.png', 'other/images/x.png')]), /một hiện vật/);
  assert.throws(() => prepareScanDataset([...photos, file('huge.png', 'dataset/images/huge.png', 21000000)]), /20 MiB/);
});
test('GLB preview validates version and declared file length before rendering', async () => {
  const raw = new Uint32Array([0x46546c67, 2, 12]);
  await validateGlbPreview(new File([raw], 'valid.glb'));
  raw[2] = 100;
  await assert.rejects(validateGlbPreview(new File([raw], 'truncated.glb')), /GLB 2/);
  await assert.rejects(validateGlbPreview(new File(['fake'], 'fake.glb')), /GLB 2/);
});

test('upload percent never masquerades as reconstruction progress, even at 100%', () => {
  for (const percent of [0, 1, 100]) {
    const state = scanProgress({ uploading: true, uploadProgress: percent });
    assert.equal(state.step, 2); assert.equal(state.percent, percent); assert.equal(state.running, false);
  }
  assert.equal(scanProgress({ job: { status: 'QUEUED', progress: 0 } }).step, 3);
  assert.equal(scanProgress({ job: { status: 'QUEUED', progress: 0 } }).percent, 0);
  assert.equal(scanProgress({}).percent, 0);
  assert.equal(scanProgress({ job: { status: 'REVIEW_REQUIRED', progress: 100 } }).step, 4);
});

test('returns an accepted job immediately; an existing active job prevents duplicate upload', async () => {
  const job = { scanJobId: 'accepted', artifactId: 2, status: 'QUEUED', progress: 0 };
  let uploads = 0;
  const upload = async () => { uploads++; return job; };
  assert.deepEqual(await startScanSafely(2, {}, { getJobs: async () => [], upload }), { job, recovered: false });
  assert.deepEqual(await startScanSafely(2, {}, { getJobs: async () => [job], upload }), { job, recovered: true });
  assert.equal(uploads, 1);
});

test('a lost 202 response recovers the persisted job without resending photos', async () => {
  const job = { scanJobId: 'persisted', artifactId: 2, status: 'PROCESSING', progress: 1 };
  let checks = 0, uploads = 0;
  const result = await startScanSafely(2, {}, {
    getJobs: async () => ++checks === 1 ? [] : [job],
    upload: async () => { uploads++; throw Object.assign(new Error('timeout'), { code: 'UPLOAD_TIMEOUT' }); }
  });
  assert.deepEqual(result, { job, recovered: true });
  assert.equal(uploads, 1); assert.equal(checks, 2);
});

test('ambiguous uploads require a job check; validation errors never retry or restore arbitrary jobs', async () => {
  for (const rows of [[], [{ scanJobId: 'foreign', artifactId: 9 }],
      [{ scanJobId: 'a', artifactId: 2 }, { scanJobId: 'b', artifactId: 2 }]]) {
    let calls = 0;
    await assert.rejects(startScanSafely(2, {}, {
      getJobs: async () => ++calls === 1 ? [] : rows,
      upload: async () => { throw Object.assign(new Error('network'), { code: 'UPLOAD_NETWORK' }); }
    }), { requiresJobCheck: true });
  }
  let calls = 0;
  await assert.rejects(startScanSafely(2, {}, {
    getJobs: async () => { calls++; return []; },
    upload: async () => { throw Object.assign(new Error('invalid images'), { status: 422 }); }
  }), { status: 422 });
  assert.equal(calls, 1);
});
