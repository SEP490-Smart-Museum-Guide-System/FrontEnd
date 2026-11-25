import React, { useState } from 'react';
import { backend } from '../../services/backend';
import { useApp } from '../../context/AppContext';
import { Field, Modal, PageTitle, LoadState, ErrorNotice, Empty, useData, useAction } from '../common/BusinessUI';
const metrics = { scan_artifacts: 'Số hiện vật đã quét', quiz_correct: 'Số câu trả lời đúng', tours_completed: 'Số tour khác nhau đã hoàn thành' };
const rateLabels = { scanPoints: 'Quét hiện vật mới', correctAnswerPoints: 'Trả lời đúng câu mới', tourPoints: 'Lần đầu hoàn thành tour' };

function RewardSettings() {
  const rates = useData('reward-settings', signal => backend('gamification/settings', { signal }));
  const action = useAction('Đã lưu mức điểm.');
  return <section className="card business-card"><h3>Điểm thưởng khám phá</h3>
    <LoadState resource={rates}>{rates.data && <form onSubmit={event => {
      event.preventDefault();
      const values = new FormData(event.currentTarget);
      const body = Object.fromEntries(Object.keys(rateLabels).map(key => [key, Number(values.get(key))]));
      action.run(() => backend('gamification/settings', { method: 'PUT', body }), rates.reload);
    }}>
      {Object.entries(rateLabels).map(([key, label]) => <Field key={key} label={label}>
        <input className="form-input" name={key} type="number" min="0" max="10000" required defaultValue={rates.data[key]} />
      </Field>)}
      <ErrorNotice>{action.error}</ErrorNotice>
      <button className="btn btn-primary" disabled={action.busy}>Lưu mức điểm</button>
    </form>}</LoadState>
  </section>;
}

export default function BadgeManager() {
  const list = useData('badge-definitions', signal => backend('gamification/badges', { signal }), []);
  const [adding, setAdding] = useState(false);
  return <><PageTitle description="Thiết lập mốc quét hiện vật và trả lời đúng để hệ thống tự trao huy hiệu.">Huy hiệu khám phá</PageTitle><RewardSettings /><div className="business-toolbar"><button className="btn btn-primary" onClick={() => setAdding(true)}>Tạo huy hiệu</button><button className="btn btn-secondary" onClick={list.reload}>Tải lại</button></div><LoadState resource={list}><div className="business-grid">{list.data.map(b => { let rule = {}; try { rule = JSON.parse(b.ruleJson); } catch {} return <article className="card business-card" key={b.id}><h3>{b.name}</h3><p>{b.code}</p><p>{metrics[rule.metric || rule.Metric]}: {rule.threshold ?? rule.Threshold}</p></article>; })}</div>{!list.data.length && <Empty>Chưa có huy hiệu.</Empty>}</LoadState>{adding && <BadgeForm onClose={() => setAdding(false)} onSaved={() => { setAdding(false); list.reload(); }} />}</>;
}
function BadgeForm({ onClose, onSaved }) {
  const { museums } = useApp();
  const [form, setForm] = useState({ code: '', name: '', museumId: '', metric: 'scan_artifacts', threshold: 1 }), action = useAction('Đã lưu huy hiệu.');
  const change = e => setForm(p => ({ ...p, [e.target.name]: e.target.value }));
  return <Modal title="Tạo huy hiệu" busy={action.busy} onClose={onClose}><form onSubmit={e => { e.preventDefault(); action.run(() => backend('gamification/badges', { method: 'POST', body: { ...form, code: form.code.trim(), name: form.name.trim(), museumId: form.museumId ? Number(form.museumId) : null, threshold: Number(form.threshold) } }), onSaved); }}><ErrorNotice>{action.error}</ErrorNotice><Field label="Mã huy hiệu"><input className="form-input" name="code" required maxLength={50} value={form.code} onChange={change} /></Field><Field label="Tên huy hiệu"><input className="form-input" name="name" required maxLength={200} value={form.name} onChange={change} /></Field><Field label="Phạm vi"><select className="form-select" name="museumId" value={form.museumId} onChange={change}><option value="">Toàn hệ thống</option>{museums.map(m => <option key={m.id} value={m.id}>{m.name}</option>)}</select></Field><Field label="Điều kiện"><select className="form-select" name="metric" value={form.metric} onChange={change}>{Object.entries(metrics).map(([key, label]) => <option key={key} value={key}>{label}</option>)}</select></Field><Field label="Mốc đạt"><input className="form-input" type="number" name="threshold" required min={1} max={100000} value={form.threshold} onChange={change} /></Field><button className="btn btn-primary" disabled={action.busy}>Tạo huy hiệu</button></form></Modal>;
}
