import React, { useState } from 'react';
import { ArrowRight, BookOpenCheck, Landmark, MapPinned, ShieldCheck, UserCheck, UsersRound, Loader2 } from 'lucide-react';
import { useApp } from '../../context/AppContext';

const accounts = [
  { email: 'admin@smgs.vn', role: 'Quản trị viên (Database)', icon: ShieldCheck },
  { email: 'staff@smgs.vn', role: 'Nhân viên bảo tàng', icon: Landmark },
  { email: 'system@smgs.vn', role: 'Nhân viên hệ thống', icon: UserCheck },
  { email: 'curator@smgs.vn', role: 'Giám tuyển', icon: BookOpenCheck },
  { email: 'khach@smgs.vn', role: 'Khách tham quan · mobile', icon: UsersRound },
];

export default function LoginScreen() {
  const { login } = useApp();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const submit = async (event) => {
    event.preventDefault();
    setError('');
    setLoading(true);
    const result = await login(email, password);
    setLoading(false);
    if (!result?.success) {
      setError(result?.error || 'Email hoặc mật khẩu chưa đúng.');
    }
  };

  const loginSeedAccount = async (account) => {
    setError('');
    setLoading(true);
    const result = await login(account.email, 'smgs123');
    setLoading(false);
    if (!result?.success) {
      setError(result?.error || 'Không thể mở tài khoản mẫu này.');
    }
  };

  return (
    <main className="login-page">
      <section className="login-hero">
        <div className="login-seal"><Landmark size={28} /></div>
        <p className="login-eyebrow">SMGS · DI SẢN VIỆT</p>
        <h1>Đi vào một không gian<br />được thiết kế cho từng vai trò.</h1>
        <p>Khách tham quan có thể mở Google Maps để chỉ đường. Bốn vai trò nghiệp vụ cùng sử dụng cổng web để quản lý, thẩm định và vận hành.</p>
        <div className="login-feature">
          <MapPinned size={19} />
          <span><strong>Khách tham quan</strong><br />Mở phần chỉ đường Google Maps ngay trên web.</span>
        </div>
      </section>

      <section className="login-panel">
        <div>
          <span className="login-eyebrow login-eyebrow-dark">ĐĂNG NHẬP HỆ THỐNG</span>
          <h2>Chào bạn trở lại</h2>
          <p>Nhập thông tin tài khoản hoặc chọn nhanh vai trò để trải nghiệm.</p>
        </div>

        <form onSubmit={submit} className="login-form">
          <label>
            Email
            <input
              className="form-input"
              type="email"
              value={email}
              onChange={event => setEmail(event.target.value)}
              placeholder="name@smgs.vn"
              required
              disabled={loading}
            />
          </label>
          <label>
            Mật khẩu
            <input
              className="form-input"
              type="password"
              value={password}
              onChange={event => setPassword(event.target.value)}
              placeholder="Nhập mật khẩu..."
              required
              disabled={loading}
            />
          </label>
          {error && <p className="login-error" role="alert">{error}</p>}
          <button className="btn btn-primary login-submit" type="submit" disabled={loading}>
            {loading ? (
              <>
                <Loader2 size={17} className="animate-spin" />
                Đang xác thực với máy chủ...
              </>
            ) : (
              <>
                Đăng nhập <ArrowRight size={17} />
              </>
            )}
          </button>
        </form>

        <div className="login-demo-heading">
          <span /> Hoặc chọn tài khoản mẫu <span />
        </div>
        <div className="login-account-grid">
          {accounts.map(account => {
            const Icon = account.icon;
            return (
              <button
                key={account.email}
                type="button"
                onClick={() => loginSeedAccount(account)}
                className="login-account"
                disabled={loading}
              >
                <Icon size={18} />
                <span>
                  <strong>{account.role}</strong>
                  <small>{account.email}</small>
                </span>
              </button>
            );
          })}
        </div>
        <p className="login-hint">Kết nối trực tiếp tới <strong>Backend API & PostgreSQL</strong></p>
      </section>
    </main>
  );
}
