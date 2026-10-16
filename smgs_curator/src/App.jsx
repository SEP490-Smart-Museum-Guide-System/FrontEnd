import React, { useState } from 'react';
import {
  Archive, Bell, BookOpenCheck, Check, ChevronRight, ClipboardCheck, Clock3,
  FileText, Landmark, LayoutDashboard, LogOut, Menu, RotateCcw,
  ShieldCheck, X
} from 'lucide-react';
import { curator, seedItems } from './data';

const statusText = { pending: 'Chờ thẩm định', revision: 'Yêu cầu hiệu đính', rejected: 'Đã từ chối', published: 'Đã xuất bản' };
const statusClass = { pending: 'pending', revision: 'revision', rejected: 'rejected', published: 'published' };

export default function App() {
  const [loggedIn, setLoggedIn] = useState(() => sessionStorage.getItem('smgs_curator_session') === 'true');
  const [page, setPage] = useState('dashboard');
  const [items, setItems] = useState(seedItems);
  const [selectedId, setSelectedId] = useState('CUR-101');
  const [filter, setFilter] = useState('all');
  const [note, setNote] = useState('');
  const [draft, setDraft] = useState('');
  const [audit, setAudit] = useState([]);
  const [menuOpen, setMenuOpen] = useState(false);

  const selected = items.find(item => item.id === selectedId) || items[0];
  const pending = items.filter(item => item.status === 'pending').length;
  const reviewable = items.filter(item => ['pending', 'revision'].includes(item.status));
  const filtered = filter === 'all' ? items : items.filter(item => item.status === filter);

  const beginReview = (item) => {
    setSelectedId(item.id);
    setDraft(item.proposed);
    setNote(item.feedback || '');
    setPage('review');
    setMenuOpen(false);
  };

  const record = (action, item) => setAudit(previous => [{ id: Date.now(), action, item: item.title, at: new Intl.DateTimeFormat('vi-VN', { dateStyle: 'short', timeStyle: 'short' }).format(new Date()) }, ...previous]);

  const updateDecision = (status) => {
    if (!selected) return;
    if (['revision', 'rejected'].includes(status) && !note.trim()) return;
    const action = status === 'published' ? 'Phê duyệt và xuất bản' : status === 'revision' ? 'Yêu cầu hiệu đính' : 'Từ chối nội dung';
    const changed = { ...selected, proposed: draft, status, feedback: note.trim(), publishedAt: status === 'published' ? 'Vừa xuất bản' : selected.publishedAt };
    setItems(previous => previous.map(item => item.id === selected.id ? changed : item));
    record(action, changed);
    setPage('queue');
    setNote('');
  };

  const logout = () => { sessionStorage.removeItem('smgs_curator_session'); setLoggedIn(false); };
  if (!loggedIn) return <Login onLogin={() => { sessionStorage.setItem('smgs_curator_session', 'true'); setLoggedIn(true); }} />;

  const navigation = [
    ['dashboard', 'Tổng quan', LayoutDashboard], ['queue', 'Hàng đợi thẩm định', ClipboardCheck],
    ['published', 'Nội dung đã xuất bản', BookOpenCheck], ['audit', 'Nhật ký thẩm định', FileText],
  ];

  return <div className="app-shell">
    <aside className={`sidebar ${menuOpen ? 'open' : ''}`}>
      <div className="brand"><span><Landmark size={21} /></span><div><strong>SMGS · GIÁM TUYỂN</strong><small>Cổng kiểm định nội dung</small></div></div>
      <div className="assignment"><span>PHẠM VI ĐƯỢC PHÂN CÔNG</span><strong>{curator.museum}</strong><small>Chỉ nội dung của bảo tàng này</small></div>
      <nav>{navigation.map(([id, label, Icon]) => <button type="button" key={id} className={page === id ? 'active' : ''} onClick={() => { setPage(id); setMenuOpen(false); }}><Icon size={18} />{label}{id === 'queue' && pending > 0 && <b>{pending}</b>}</button>)}</nav>
      <div className="sidebar-note"><ShieldCheck size={17} /><span>Nội dung chỉ được hiển thị cho Khách sau khi Giám tuyển phê duyệt và xuất bản.</span></div>
    </aside>
    <main className="workspace">
      <header className="topbar"><button type="button" className="menu-button" onClick={() => setMenuOpen(!menuOpen)}><Menu size={20} /></button><div className="topbar-title"><span>Không gian thẩm định</span><strong>{page === 'review' ? 'Thẩm định nội dung' : page === 'queue' ? 'Hàng đợi nội dung' : page === 'published' ? 'Kho nội dung đã xuất bản' : page === 'audit' ? 'Nhật ký thẩm định' : 'Tổng quan giám tuyển'}</strong></div><div className="profile"><div>{curator.name.split(' ').at(-1).charAt(0)}</div><span><strong>{curator.name}</strong><small>Giám tuyển</small></span><button type="button" title="Đăng xuất" onClick={logout}><LogOut size={17} /></button></div></header>
      <div className="content">
        {page === 'dashboard' && <Dashboard items={items} pending={pending} onReview={beginReview} />}
        {page === 'queue' && <Queue items={filtered} filter={filter} setFilter={setFilter} onReview={beginReview} />}
        {page === 'review' && <Review item={selected} draft={draft} setDraft={setDraft} note={note} setNote={setNote} onDecision={updateDecision} onBack={() => setPage('queue')} />}
        {page === 'published' && <Published items={items.filter(item => item.status === 'published')} onReview={beginReview} />}
        {page === 'audit' && <Audit entries={audit} />}
      </div>
    </main>
  </div>;
}

function Login({ onLogin }) {
  const [email, setEmail] = useState(''); const [password, setPassword] = useState(''); const [error, setError] = useState('');
  const submit = event => { event.preventDefault(); if (email.trim().toLowerCase() === curator.email && password === 'smgs123') onLogin(); else setError('Tài khoản này không có quyền truy cập Cổng Giám tuyển.'); };
  return <main className="login"><section className="login-story"><div className="seal"><Landmark size={31} /></div><span>SMGS · CỔNG GIÁM TUYỂN</span><h1>Gìn giữ tính xác thực<br />cho từng câu chuyện di sản.</h1><p>Không gian độc lập để thẩm định, hiệu đính, phê duyệt và xuất bản nội dung trước khi đến với Khách tham quan.</p><div><ShieldCheck size={19} /> Nội dung được phân công theo từng bảo tàng</div></section><section className="login-form"><p>ĐĂNG NHẬP GIÁM TUYỂN</p><h2>Chào mừng trở lại</h2><span>Đăng nhập bằng tài khoản được phân công.</span><form onSubmit={submit}><label>Email<input value={email} onChange={event => setEmail(event.target.value)} type="email" placeholder="curator@smgs.vn" required /></label><label>Mật khẩu<input value={password} onChange={event => setPassword(event.target.value)} type="password" placeholder="smgs123" required /></label>{error && <div className="login-error">{error}</div>}<button type="submit">Đăng nhập <ChevronRight size={18} /></button></form><button className="seed" type="button" onClick={() => { setEmail(curator.email); setPassword('smgs123'); setError(''); }}>Điền tài khoản mẫu: curator@smgs.vn</button><small>Mật khẩu mẫu: <strong>smgs123</strong></small></section></main>;
}

function Dashboard({ items, pending, onReview }) {
  const latest = items.filter(item => item.status === 'pending').slice(0, 3);
  return <><section className="hero"><span>TRÁCH NHIỆM GIÁM TUYỂN</span><h1>Kiểm định trước khi<br />di sản được kể tiếp.</h1><p>Thẩm định thông tin hiện vật, bản dịch, thuyết minh và quiz AI của Bảo tàng Lịch sử Quốc gia.</p><button type="button" onClick={() => latest[0] && onReview(latest[0])}>Bắt đầu thẩm định <ChevronRight size={17} /></button></section><section className="metrics"><Metric value={pending} label="Mục chờ thẩm định" tone="burgundy" /><Metric value={items.filter(item => item.status === 'revision').length} label="Đang chờ hiệu đính" tone="gold" /><Metric value={items.filter(item => item.status === 'published').length} label="Đã xuất bản" tone="green" /></section><section className="panel"><div className="panel-title"><div><span>NỘI DUNG ƯU TIÊN</span><h2>Cần thẩm định hôm nay</h2></div><button type="button" onClick={() => latest[0] && onReview(latest[0])}>Mở mục đầu tiên</button></div>{latest.map(item => <QueueRow key={item.id} item={item} onReview={onReview} />)}</section></>;
}
function Metric({ value, label, tone }) { return <article className={`metric ${tone}`}><strong>{value}</strong><span>{label}</span></article>; }
function Queue({ items, filter, setFilter, onReview }) { return <><section className="page-intro"><span>HÀNG ĐỢI NỘI DUNG</span><h1>Thẩm định và quyết định xuất bản</h1><p>Chỉ các nội dung đã được Museum Staff đệ trình thuộc phạm vi được phân công.</p></section><div className="filters">{[['all','Tất cả'],['pending','Chờ thẩm định'],['revision','Yêu cầu hiệu đính'],['published','Đã xuất bản'],['rejected','Đã từ chối']].map(([id,label]) => <button key={id} onClick={() => setFilter(id)} className={filter === id ? 'selected' : ''}>{label}</button>)}</div><section className="panel queue-panel">{items.length ? items.map(item => <QueueRow key={item.id} item={item} onReview={onReview} />) : <p className="empty">Chưa có nội dung trong trạng thái này.</p>}</section></> }
function QueueRow({ item, onReview }) { return <article className="queue-row"><div className="type-icon"><Archive size={19} /></div><div className="queue-main"><div><span className="content-type">{item.type}</span><span className={`status ${statusClass[item.status]}`}>{statusText[item.status]}</span></div><h3>{item.title}</h3><p>{item.artifact} · {item.summary}</p><small><Clock3 size={13} /> {item.submittedAt} · {item.submittedBy}</small></div><button type="button" onClick={() => onReview(item)}>{item.status === 'published' ? 'Xem hồ sơ' : 'Thẩm định'} <ChevronRight size={16} /></button></article>; }
function Review({ item, draft, setDraft, note, setNote, onDecision, onBack }) { if (!item) return null; const canDecide = ['pending','revision'].includes(item.status); return <><button className="back" onClick={onBack}><ChevronRight size={16} /> Quay lại hàng đợi</button><section className="review-head"><div><span className="content-type">{item.type}</span><h1>{item.title}</h1><p>{item.artifact} · Đệ trình bởi {item.submittedBy}</p></div><span className={`status ${statusClass[item.status]}`}>{statusText[item.status]}</span></section><section className="review-grid"><article className="review-panel"><header><span>PHIÊN BẢN ĐÃ XUẤT BẢN</span><small>Chỉ đọc</small></header><p>{item.current}</p></article><article className="review-panel proposed"><header><span>NỘI DUNG ĐỆ TRÌNH</span><small>Có thể hiệu đính</small></header><textarea value={draft} onChange={event => setDraft(event.target.value)} readOnly={!canDecide} /></article></section><section className="check-panel"><div><div><span>DANH SÁCH KIỂM TRA</span><h2>Xác thực nội dung</h2></div><small>Phạm vi: {curator.museum}</small></div>{item.checks.map(check => <label key={check}><input type="checkbox" defaultChecked={item.status === 'published'} disabled={!canDecide} /> <span>{check}</span></label>)}</section>{canDecide && <section className="note-panel"><label>Ghi chú thẩm định / yêu cầu hiệu đính<textarea value={note} onChange={event => setNote(event.target.value)} placeholder="Nêu rõ nguồn, thuật ngữ hoặc chi tiết cần hiệu đính khi cần…" /></label></section>}<footer className="decision"><button className="reject" disabled={!canDecide} onClick={() => onDecision('rejected')}><X size={16} /> Từ chối</button><button className="revision" disabled={!canDecide} onClick={() => onDecision('revision')}><RotateCcw size={16} /> Yêu cầu hiệu đính</button><button className="approve" disabled={!canDecide} onClick={() => onDecision('published')}><Check size={16} /> Phê duyệt & xuất bản</button></footer></> }
function Published({ items, onReview }) { return <><section className="page-intro"><span>KHO TRI THỨC ĐÃ CÔNG BỐ</span><h1>Nội dung đã được Giám tuyển phê duyệt</h1><p>Các mục ở đây là nguồn có thể phục vụ trải nghiệm Khách tham quan.</p></section><section className="panel">{items.map(item => <QueueRow key={item.id} item={item} onReview={onReview} />)}</section></> }
function Audit({ entries }) { return <><section className="page-intro"><span>NHẬT KÝ THẨM ĐỊNH</span><h1>Dấu vết quyết định nội dung</h1><p>Nhật ký mô phỏng trong phiên làm việc hiện tại.</p></section><section className="panel audit">{entries.length ? entries.map(entry => <article key={entry.id}><Bell size={17} /><div><strong>{entry.action}</strong><span>{entry.item}</span></div><small>{entry.at}</small></article>) : <p className="empty">Chưa có quyết định nào trong phiên này.</p>}</section></> }
