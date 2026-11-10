import test from 'node:test';
import assert from 'node:assert/strict';
import { mapLabel } from '../src/components/indoor_maps/mapLabel.js';
test('map labels explain the scope without repeating legacy generated names', () => {
  const floor = { name: 't', buildingName: 'a' };
  assert.equal(mapLabel({ name: 'a / t' }, floor), 'Tòa nhà: a · Tầng: t');
  assert.equal(mapLabel({ name: 'Trưng bày' }, floor), 'Tòa nhà: a · Tầng: t · Sơ đồ: Trưng bày');
  assert.equal(mapLabel({ name: 'Chung' }), 'Mặt bằng chung — Chung');
});
