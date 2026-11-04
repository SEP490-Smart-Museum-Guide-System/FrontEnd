export const weekDays = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'];
const empty = () => ({ start: '', end: '', days: weekDays.map((_, i) => i), custom: false });
const dayIndex = name => {
  const normalized = name.trim().toLocaleLowerCase('vi');
  const aliases = ['thứ hai', 'thứ ba', 'thứ tư', 'thứ năm', 'thứ sáu', 'thứ bảy', 'chủ nhật'];
  const index = weekDays.findIndex(day => day.toLocaleLowerCase('vi') === normalized);
  return index >= 0 ? index : aliases.indexOf(normalized);
};
export function parseOpeningHours(value = '') {
  if (!value.trim()) return empty();
  const match = value.trim().match(/^(\d{2}:\d{2})\s*[-–]\s*(\d{2}:\d{2})(?:\s*\(([^)]+)\))?$/);
  if (!match) return { ...empty(), custom: true, raw: value };
  const validTime = t => /^([01]\d|2[0-3]):[0-5]\d$/.test(t);
  if (!validTime(match[1]) || !validTime(match[2]) || match[2] <= match[1]) return { ...empty(), custom: true, raw: value };
  let days = empty().days;
  if (match[3]) {
    const parts = match[3].split(/\s*[-–]\s*/);
    if (parts.length === 2) {
      const from = dayIndex(parts[0]), to = dayIndex(parts[1]);
      if (from < 0 || to < from) return { ...empty(), custom: true, raw: value };
      days = days.filter(i => i >= from && i <= to);
    } else {
      days = match[3].split(',').map(dayIndex);
      if (days.some(i => i < 0)) return { ...empty(), custom: true, raw: value };
    }
  }
  return { start: match[1], end: match[2], days, custom: false };
}
export function formatOpeningHours(draft) {
  if (draft.custom) return draft.raw;
  if (!draft.start || !draft.end || draft.end <= draft.start || !draft.days.length) return '';
  return `${draft.start} - ${draft.end} (${[...draft.days].sort((a, b) => a - b).map(i => weekDays[i]).join(', ')})`;
}
