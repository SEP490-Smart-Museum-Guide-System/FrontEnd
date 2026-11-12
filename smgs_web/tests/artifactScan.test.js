import test from 'node:test';
import assert from 'node:assert/strict';
import { prepareScanDataset, validateGlbPreview } from '../src/services/artifactScanApi.js';
const file = (name, path = name, size = 100) => ({ name, webkitRelativePath: path, size });
const photos = Array.from({ length: 5 }, (_, i) => file(`${i}.png`, `dataset/images/${i}.png`));

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
