import React from 'react';
import { backend } from '../../services/backend';
import { useData } from '../common/BusinessUI';
export default function MuseumCityPicker({ value, onChange, disabled }) {
  const resource = useData('museum-city-options', async signal => {
    const data = await backend('museums/cities', { signal });
    const rows = Array.isArray(data) ? data : Object.entries(data || {}).map(([code, name]) => ({ code, name }));
    const cities = rows.map(c => ({ code: String(c.code ?? c.Code ?? c.key ?? '').padStart(2, '0'), name: c.name ?? c.Name ?? c.value }))
      .filter(c => /^(?!00)\d{2}$/.test(c.code) && typeof c.name === 'string' && c.name.trim());
    if (!cities.length) throw new Error('Chưa tải được danh sách tỉnh / thành phố.');
    return cities;
  }, []);
  return <div className="form-group" style={{ marginBottom: 0 }}>
    <label className="form-label" htmlFor="museum-city-select">Tỉnh / Thành phố *</label>
    <select id="museum-city-select" aria-label="Tỉnh / Thành phố" className="form-select" required disabled={disabled || resource.busy || !!resource.error}
      value={resource.data.some(c => c.code === value) ? value : ''} onChange={e => onChange(e.target.value)}>
      <option value="" disabled>{resource.busy ? 'Đang tải tỉnh / thành phố…' : 'Chọn tỉnh / thành phố'}</option>
      {resource.data.map(c => <option key={c.code} value={c.code}>{c.name} ({c.code})</option>)}
    </select>
    {resource.busy && <p role="status">Đang tải danh sách tỉnh / thành phố…</p>}
    {resource.error && <div><p role="alert">{resource.error}</p><button type="button" className="btn btn-secondary btn-sm" onClick={resource.reload}>Tải lại tỉnh / thành phố</button></div>}
  </div>;
}
