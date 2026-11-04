import React, { useEffect, useRef, useState } from 'react';
import { formatOpeningHours, parseOpeningHours, weekDays } from '../../services/openingHours';
export default function OpeningHoursPicker({ value, onChange, disabled }) {
  const [draft, setDraft] = useState(() => parseOpeningHours(value));
  const endInput = useRef(null);
  const error = draft.start && draft.end && draft.end <= draft.start ? 'Giờ đóng cửa phải sau giờ mở cửa.'
    : draft.start && draft.end && !draft.days.length ? 'Chọn ít nhất một ngày mở cửa.' : '';
  useEffect(() => { endInput.current?.setCustomValidity(error); }, [error]);
  const update = next => { setDraft(next); onChange(formatOpeningHours(next)); };
  return <fieldset disabled={disabled} style={{ border: 0, margin: 0, padding: 0, minWidth: 0 }}>
    <legend className="form-label">Lịch mở cửa</legend>
    {draft.custom ? <><p>{value}</p><button type="button" className="btn btn-secondary btn-sm" onClick={() => update(parseOpeningHours(''))}>Chỉnh bằng bộ chọn giờ</button></> : <>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, minmax(0, 1fr))', gap: 12 }}>
        <label>Giờ mở cửa<input className="form-input" type="time" step="60" aria-label="Giờ mở cửa" value={draft.start} required={!!draft.end}
          onChange={e => update({ ...draft, start: e.target.value })} /></label>
        <label>Giờ đóng cửa<input ref={endInput} className="form-input" type="time" step="60" aria-label="Giờ đóng cửa" value={draft.end} required={!!draft.start}
          onChange={e => update({ ...draft, end: e.target.value })} /></label>
      </div>
      <p style={{ marginTop: 10, marginBottom: 6 }}>Ngày mở cửa trong tuần</p>
      <div style={{ display: 'flex', gap: '8px 14px', flexWrap: 'wrap' }}>{weekDays.map((name, index) => <label key={name} style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
        <input type="checkbox" checked={draft.days.includes(index)} onChange={e => update({ ...draft, days: e.target.checked ? [...draft.days, index] : draft.days.filter(i => i !== index) })} />{name}
      </label>)}</div>
      {error && <p role="alert">{error}</p>}
      {(draft.start || draft.end) && <button type="button" className="btn btn-secondary btn-sm" style={{ marginTop: 10 }} onClick={() => update(parseOpeningHours(''))}>Xóa lịch mở cửa</button>}
    </>}
  </fieldset>;
}
