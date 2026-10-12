import React, { useState } from 'react';
import { ArrowRight, Landmark, MapPinned, ShieldCheck, UserCheck } from 'lucide-react';
import { useApp } from '../../context/AppContext';

const accounts = [
  { email: 'admin@smgs.vn', role: 'Quản trị viên', icon: ShieldCheck },
  { email: 'staff@smgs.vn', role: 'Nhân viên bảo tàng', icon: Landmark },
  { email: 'system@smgs.vn', role: 'Nhân viên hệ thống', icon: UserCheck },
];

export default function LoginScreen() {
  const { login, openVisitorPreview } = useApp();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');

  const submit = (event) => {
    event.preventDefault();
    if (login(email, password)) return;
    setError('Email hoặc mật khẩu chưa đúng. Dùng một tài khoản mẫu bên dưới với mật khẩu smgs123.');
  };

  const chooseAccount = (account) => {
    setEmail(account.email);
    setPassword('smgs123');
    setError('');
  };

  return <main className="login-page">
    <section className="login-hero">
      <div className="login-seal"><Landmark size={28} /></div>
      <p className="login-eyebrow">SMGS · DI SẢN VIỆT</p>
      <h1>Đi vào một không gian<br />được thiết kế cho từng vai trò.</h1>
      <p>Khách tham quan có thể mở Google Maps để chỉ đường. Ba vai trò nghiệp vụ sử dụng cổng web để quản lý, kiểm duyệt và vận hành.</p>
      <div className="login-feature"><MapPinned size={19} /><span><strong>Khách tham quan</strong><br />Mở phần chỉ đường Google Maps ngay trên web.</span></div>
    </section>
    <section className="login-panel">
      <div><span className="login-eyebrow login-eyebrow-dark">ĐĂNG NHẬP THỬ NGHIỆM</span><h2>Chào bạn trở lại</h2><p>Chọn nhanh một vai trò hoặc nhập thông tin đăng nhập.</p></div>
      <form onSubmit={submit} className="login-form">
        <label>Email<input className="form-input" type="email" value={email} onChange={event => setEmail(event.target.value)} placeholder="name@smgs.vn" required /></label>
        <label>Mật khẩu<input className="form-input" type="password" value={password} onChange={event => setPassword(event.target.value)} placeholder="smgs123" required /></label>
        {error && <p className="login-error" role="alert">{error}</p>}
        <button className="btn btn-primary login-submit" type="submit">Đăng nhập <ArrowRight size={17} /></button>
      </form>
      <div className="login-demo-heading"><span /> Hoặc chọn tài khoản mẫu <span /></div>
      <div className="login-account-grid">
        {accounts.map(account => { const Icon = account.icon; return <button key={account.email} type="button" onClick={() => chooseAccount(account)} className="login-account"><Icon size={18} /><span><strong>{account.role}</strong><small>{account.email}</small></span></button>; })}
      </div>
      <button type="button" className="login-visitor-preview" onClick={openVisitorPreview}><MapPinned size={18} /><span><strong>Xem trước giao diện Khách trên web</strong><small>Chỉ để xem UI mobile và kiểm tra nút chỉ đường; Khách vẫn dùng Flutter mobile.</small></span><ArrowRight size={16} /></button>
      <p className="login-hint">Mật khẩu chung: <strong>smgs123</strong></p>
    </section>
  </main>;
}
