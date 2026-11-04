import test from 'node:test';
import assert from 'node:assert/strict';
import { checkVisionHealthApi } from '../src/services/visionApi.js';
import { getScanJobStatusApi, submitScanJobApi } from '../src/services/scan3dApi.js';

test('Vision health reads the actual model readiness and reference_images contract', async t => {
  t.mock.method(globalThis, 'fetch', async () => new Response(JSON.stringify({ status: 'ok', model_ready: true, reference_images: 17 })));
  const health = await checkVisionHealthApi();
  assert.equal(health.modelReady, true);
  assert.equal(health.referenceCount, 17);
});
test('3D job failures retain the reason returned by the scan service', async t => {
  t.mock.method(globalThis, 'fetch', async () => new Response(JSON.stringify({ status: 'FAILED', error: 'Không chạy được COLMAP.' })));
  const job = await getScanJobStatusApi('fixture-job');
  assert.equal(job.errorMessage, 'Không chạy được COLMAP.');
});
test('3D uploads outside the actual 5–80 image limit are rejected before network access', async t => {
  const fetch = t.mock.method(globalThis, 'fetch', () => { throw new Error('unexpected network call'); });
  for (const count of [0, 3, 4, 81]) {
    await assert.rejects(submitScanJobApi({ artifactId: 7, files: Array(count).fill(new Blob(['fixture'])) }), /5.*80/);
  }
  assert.equal(fetch.mock.callCount(), 0);
});

test('five artifact photos are submitted as one scan job', async t => {
  const fetch = t.mock.method(globalThis, 'fetch', async (_url, options) => {
    assert.equal(options.body.getAll('images').length, 5);
    assert.equal(options.body.get('artifact_id'), '7');
    return new Response(JSON.stringify({ scanJobId: 'five-photo-job', status: 'QUEUED' }), { status: 202 });
  });
  const job = await submitScanJobApi({ artifactId: 7, files: Array.from({ length: 5 }, () => new Blob(['fixture'], { type: 'image/png' })) });
  assert.equal(job.scanJobId, 'five-photo-job');
  assert.equal(fetch.mock.callCount(), 1);
});
