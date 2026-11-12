import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { backend, allPages } from '../../services/backend';
import { Field, Modal, PageTitle, LoadState, ErrorNotice, Empty, useData, useAction } from '../common/BusinessUI';
export default function TopicManager() {
  const { currentMuseum, artifacts, reload, currentRole, museums, setSelectedMuseumId } = useApp();
  const museumId = currentMuseum?.id;
  const topics = useData(`topics:${museumId}`, signal => museumId ? allPages(`museums/${museumId}/topics`, { signal }) : [], []);
  const [modal, setModal] = useState(null), [artifactId, setArtifactId] = useState('');
  const selected = artifacts.some(a => a.museumId === museumId && String(a.id) === artifactId) ? artifactId : '';
  const assigned = useData(`tags:${selected}`, signal => selected ? backend(`artifacts/${selected}/topics`, { signal }) : [], []);
  const action = useAction('Đã cập nhật chủ đề hiện vật.');
  const refreshed = () => { topics.reload(); assigned.reload(); reload(); };
  return <div><PageTitle description={currentMuseum?.name}>Chủ đề hiện vật</PageTitle>{currentRole === 'administrator' && <select className="form-select" aria-label="Bảo tàng đang quản lý" value={currentMuseum?.id || ''} onChange={e => setSelectedMuseumId(Number(e.target.value))}><option value="" disabled>Chọn bảo tàng</option>{museums.map(m => <option key={m.id} value={m.id}>{m.name}</option>)}</select>}<div className="business-toolbar"><button className="btn btn-primary" disabled={!museumId} onClick={() => setModal({})}>Thêm chủ đề</button><button className="btn btn-secondary" onClick={topics.reload}>Tải lại</button></div><ErrorNotice>{action.error}</ErrorNotice>
    <LoadState resource={topics}><div className="business-grid">{topics.data.map(t => <article className="card business-card" key={t.id}><h3>{t.name}</h3><p>{t.description}</p><p>{t.artifactCount} hiện vật · {t.isActive ? 'Hoạt động' : 'Tạm ẩn'}</p><div className="business-actions"><button className="btn btn-secondary" onClick={() => setModal(t)}>Sửa</button><button className="btn btn-secondary" disabled={action.busy} onClick={() => { if (window.confirm(`Xóa chủ đề “${t.name}”?`)) action.run(() => backend(`topics/${t.id}`, { method: 'DELETE' }), refreshed); }}>Xóa</button></div></article>)}</div>{!topics.data.length && <Empty>Chưa có chủ đề.</Empty>}</LoadState>
    <section className="card business-card"><h3>Chủ đề theo hiện vật</h3><select className="form-select" aria-label="Hiện vật để gán chủ đề" value={selected} onChange={e => setArtifactId(e.target.value)}><option value="">Chọn hiện vật</option>{artifacts.filter(a => a.museumId === museumId).map(a => <option key={a.id} value={a.id}>{a.name}</option>)}</select>{selected && <LoadState resource={assigned}>{!assigned.data.length && <Empty>Hiện vật chưa có chủ đề.</Empty>}{assigned.data.map(t => <div className="business-actions" key={t.id}>{t.name}<button className="btn btn-secondary btn-sm" disabled={action.busy} onClick={() => action.run(() => backend(`artifacts/${selected}/topics/${t.id}`, { method: 'DELETE' }), refreshed)}>Gỡ chủ đề</button></div>)}<TagForm key={`${selected}:${assigned.data.map(t => t.id).join(',')}`} artifactId={selected} assigned={assigned.data} topics={topics.data} onSaved={refreshed} /></LoadState>}</section>
    {modal && <TopicForm key={modal.id || 'new'} topic={modal} museumId={museumId} onClose={() => setModal(null)} onSaved={() => { setModal(null); refreshed(); }} />}
  </div>;
}
function TopicForm({ topic, museumId, onClose, onSaved }) {
  const [name, setName] = useState(topic.name || ''), [description, setDescription] = useState(topic.description || ''), [isActive, setActive] = useState(topic.isActive ?? true), action = useAction('Đã cập nhật chủ đề hiện vật.');
  return <Modal title={topic.id ? 'Sửa chủ đề' : 'Thêm chủ đề'} busy={action.busy} onClose={onClose}><form onSubmit={e => { e.preventDefault(); action.run(() => backend(topic.id ? `topics/${topic.id}` : `museums/${museumId}/topics`, { method: topic.id ? 'PUT' : 'POST', body: { museumId, name: name.trim(), description: description.trim() || null, isActive } }), onSaved); }}><ErrorNotice>{action.error}</ErrorNotice><Field label="Tên chủ đề"><input className="form-input" required maxLength={200} value={name} onChange={e => setName(e.target.value)} /></Field><Field label="Mô tả"><textarea className="form-input" maxLength={2000} value={description} onChange={e => setDescription(e.target.value)} /></Field>{topic.id && <label className="business-check"><input type="checkbox" checked={isActive} onChange={e => setActive(e.target.checked)} />Đang hoạt động</label>}<button className="btn btn-primary" disabled={action.busy}>Lưu chủ đề</button></form></Modal>;
}
function TagForm({ artifactId, assigned, topics, onSaved }) {
  const [ids, setIds] = useState(assigned.map(t => t.id)), action = useAction('Đã cập nhật chủ đề hiện vật.');
  const rows = [...topics, ...assigned.filter(t => !topics.some(row => row.id === t.id))];
  return <form onSubmit={e => { e.preventDefault(); action.run(() => backend(`artifacts/${artifactId}/topics`, { method: 'PUT', body: { topicIds: ids } }), onSaved); }}><ErrorNotice>{action.error}</ErrorNotice>{rows.map(t => <label className="business-check" key={t.id}><input type="checkbox" checked={ids.includes(t.id)} onChange={e => setIds(p => e.target.checked ? [...p, t.id] : p.filter(id => id !== t.id))} />{t.name}</label>)}<button className="btn btn-primary" disabled={action.busy}>Lưu danh sách chủ đề</button></form>;
}
