import { useEffect, useState } from 'react';
import { backend } from '../../services/backend';

export function MuseumCategoryPicker({ categories, selected = [], onChange, disabled }) {
  const [search, setSearch] = useState('');
  return <fieldset disabled={disabled} className="museum-category-picker">
    <legend>Danh mục bảo tàng</legend>
    <div className="category-chips">
      {categories.filter(category => selected.includes(category.id)).map(category =>
        <button type="button" key={category.id} onClick={() => onChange(selected.filter(id => id !== category.id))}>
          {category.name} ×
        </button>)}
    </div>
    <input aria-label="Tìm danh mục" placeholder="Tìm danh mục…" value={search} onChange={e => setSearch(e.target.value)} />
    <div className="category-options">
      {categories.filter(category => category.name.toLowerCase().includes(search.toLowerCase().trim())).map(category =>
        <label key={category.id}><input type="checkbox" checked={selected.includes(category.id)}
          onChange={e => onChange(e.target.checked ? [...selected, category.id] : selected.filter(id => id !== category.id))} />
          {category.name}
        </label>)}
    </div>
  </fieldset>;
}

const blank = { code: '', name: '', description: '', displayOrder: 0, isActive: true };

export default function MuseumCategories({ onClose, onChanged }) {
  const [rows, setRows] = useState(null);
  const [draft, setDraft] = useState(null);
  const [search, setSearch] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    const controller = new AbortController();
    backend('museum-categories/management', { signal: controller.signal }).then(setRows)
      .catch(e => { if (!controller.signal.aborted) setError(e.message); });
    return () => controller.abort();
  }, []);

  async function save(event) {
    event.preventDefault();
    if (busy) return;
    setError('');
    setBusy(true);
    try {
      await backend(draft.id ? `museum-categories/${draft.id}` : 'museum-categories', {
        method: draft.id ? 'PUT' : 'POST',
        body: { ...draft, name: draft.name.trim(), code: draft.code.trim() },
      });
      setRows(await backend('museum-categories/management'));
      setDraft(null);
      onChanged();
    } catch (e) {
      setError(e.message);
    } finally {
      setBusy(false);
    }
  }

  return <div className="card museum-category-manager">
    <header><h3>Danh mục bảo tàng</h3>
      <button type="button" className="btn btn-secondary" disabled={busy} onClick={onClose}>Đóng</button>
    </header>
    {error && <p role="alert">{error}</p>}
    <div className="museum-category-actions">
      <input aria-label="Tìm danh mục quản lý" placeholder="Tìm danh mục…" value={search} onChange={e => setSearch(e.target.value)} />
      <button type="button" className="btn btn-primary" disabled={busy} onClick={() => setDraft({ ...blank, displayOrder: Math.max(0, ...(rows ?? []).map(row => row.displayOrder)) + 1 })}>Thêm danh mục</button>
    </div>
    {draft && <form onSubmit={save}>
      <label>Mã danh mục<input value={draft.code} disabled={busy || Boolean(draft.id)} required pattern="[a-z0-9]+(-[a-z0-9]+)*" maxLength={80} onChange={e => setDraft({ ...draft, code: e.target.value })} /></label>
      <label>Tên danh mục<input value={draft.name} disabled={busy} required maxLength={120} onChange={e => setDraft({ ...draft, name: e.target.value })} /></label>
      <label>Thứ tự<input value={draft.displayOrder} disabled={busy} required type="number" min={0} max={2147483647} onChange={e => setDraft({ ...draft, displayOrder: Number(e.target.value) })} /></label>
      <label>Mô tả<textarea value={draft.description ?? ''} disabled={busy} maxLength={1000} onChange={e => setDraft({ ...draft, description: e.target.value })} /></label>
      <label><input type="checkbox" checked={draft.isActive} disabled={busy} onChange={e => setDraft({ ...draft, isActive: e.target.checked })} /> Đang hoạt động</label>
      <div className="museum-category-actions">
        <button type="submit" className="btn btn-primary" disabled={busy}>Lưu danh mục</button>
        <button type="button" className="btn btn-secondary" disabled={busy} onClick={() => setDraft(null)}>Hủy</button>
      </div>
    </form>}
    {rows === null && !error && <p role="status">Đang tải danh mục…</p>}
    <ul>
      {rows?.filter(row => `${row.name} ${row.code}`.toLowerCase().includes(search.toLowerCase().trim())).map(row =>
        <li key={row.id}><div><strong>{row.name}</strong><small>{row.displayOrder} · {row.museumCount} bảo tàng · {row.isActive ? 'Đang hoạt động' : 'Đã vô hiệu hóa'}</small></div>
          <button type="button" className="btn btn-secondary" disabled={busy} onClick={() => setDraft(row)}>Chỉnh sửa</button></li>)}
    </ul>
  </div>;
}
