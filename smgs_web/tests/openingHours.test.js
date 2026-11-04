import test from 'node:test';
import assert from 'node:assert/strict';
import { parseOpeningHours, formatOpeningHours } from '../src/services/openingHours.js';

test('opening hours preserve legacy schedules instead of silently replacing them', () => {
  const value = 'Sáng 08:00–11:30; chiều 13:00–17:00, nghỉ thứ Hai';
  const parsed = parseOpeningHours(value);
  assert.equal(parsed.custom, true);
  assert.equal(formatOpeningHours(parsed), value);
});
test('weekday ranges and selected weekdays round trip', () => {
  const parsed = parseOpeningHours('08:30 - 17:15 (Thứ 3 - Chủ nhật)');
  assert.deepEqual(parsed.days, [1, 2, 3, 4, 5, 6]);
  assert.deepEqual(parseOpeningHours(formatOpeningHours(parsed)), parsed);
  assert.equal(formatOpeningHours({ ...parsed, days: [5, 1, 3] }), '08:30 - 17:15 (Thứ 3, Thứ 5, Thứ 7)');
  assert.equal(parseOpeningHours('08:00 - 17:00').days.length, 7);
  assert.deepEqual(parseOpeningHours('08:00 - 17:00 (Thứ Ba - Chủ Nhật)').days, [1, 2, 3, 4, 5, 6]);
});
test('incomplete or reversed hours and empty weekdays cannot be saved as a schedule', () => {
  const draft = parseOpeningHours('08:00 - 17:00');
  for (const change of [{ end: '07:00' }, { end: '08:00' }, { start: '' }, { days: [] }]) {
    assert.equal(formatOpeningHours({ ...draft, ...change }), '');
  }
  assert.equal(parseOpeningHours('25:00 - 26:00').custom, true);
});
