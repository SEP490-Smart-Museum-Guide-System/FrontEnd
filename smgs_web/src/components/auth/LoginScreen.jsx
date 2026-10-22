import React, { useState } from 'react';
import { ArrowRight, Landmark, MapPinned, Loader2 } from 'lucide-react';
import { useApp } from '../../context/AppContext';

export default function LoginScreen() {
  const { login } = useApp();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const submit = async (event) => {
    event.preventDefault();
    if (loading) return;
    setError(''); setLoading(true);
    try {
      const result = await login(email, password);
      if (!result?.success) setError(result?.error || 'Email hoặc mật khẩu chưa đúng.');
    } finally { setLoading(false); }
  };

  return (
    <main className="login-page">
      <section className="login-hero">
        <div className="login-seal"><Landmark size={28} /></div>
        <p className="login-eyebrow">SMGS · DI SẢN VIỆT</p>
        <h1>Cổng nghiệp vụ<br />bảo tàng thông minh.</h1>
        <p>Dành cho quản trị viên, nhân viên bảo tàng, nhân viên hệ thống và giám tuyển.</p>
        <div className="login-feature"><MapPinned size={19} />
          <span>Khách tham quan sử dụng ứng dụng Visitor để khám phá và tìm đường đến bảo tàng.</span>
        </div>
      </section>
      <section className="login-panel">
        <div><span className="login-eyebrow login-eyebrow-dark">ĐĂNG NHẬP HỆ THỐNG</span>
          <h2>Chào bạn trở lại</h2><p>Đăng nhập bằng tài khoản đã được cấp.</p></div>
        <form onSubmit={submit} className="login-form">
          <label>Email<input className="form-input" type="email" autoComplete="username"
            value={email} onChange={event => setEmail(event.target.value)}
            placeholder="name@smgs.vn" required maxLength={256} disabled={loading} /></label>
          <label>Mật khẩu<input className="form-input" type="password" autoComplete="current-password"
            value={password} onChange={event => setPassword(event.target.value)}
            placeholder="Nhập mật khẩu" required maxLength={1024} disabled={loading} /></label>
          {error && <p className="login-error" role="alert">{error}</p>}
          <button className="btn btn-primary login-submit" type="submit" disabled={loading}>
            {loading ? <><Loader2 size={17} className="animate-spin" /> Đang xác thực…</> : <>Đăng nhập <ArrowRight size={17} /></>}
          </button>
        </form>
        <p><a href="/visitor/">Đăng nhập ứng dụng Khách tham quan</a></p>
        <p><a href="/visitor/?mode=register">Đăng ký tài khoản Khách tham quan</a></p>
      </section>
    </main>
  );
}
