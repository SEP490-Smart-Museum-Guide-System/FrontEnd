import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import {
  Users,
  ShieldCheck,
  UserCheck,
  Sparkles,
  Plus,
  Search,
  Phone,
  Mail,
  Building,
  CheckCircle,
  XCircle,
  Edit2
} from 'lucide-react';

export default function UserManager() {
  const { users, addUser, toggleUserStatus, museums } = useApp();
  const [searchTerm, setSearchTerm] = useState('');
  const [roleFilter, setRoleFilter] = useState('all');
  const [isAddingUser, setIsAddingUser] = useState(false);

  const [newUserForm, setNewUserForm] = useState({
    name: '',
    email: '',
    phone: '',
    role: 'museumStaff',
    museumId: 'mus-01',
    assignedGalleries: ''
  });

  const filteredUsers = users.filter(u => {
    if (roleFilter !== 'all' && u.role !== roleFilter) return false;
    if (searchTerm.trim()) {
      const q = searchTerm.toLowerCase();
      return u.name.toLowerCase().includes(q) || u.email.toLowerCase().includes(q) || u.phone.includes(q);
    }
    return true;
  });

  const handleAddUserSubmit = (e) => {
    e.preventDefault();
    if (!newUserForm.name || !newUserForm.email) {
      alert('Vui lòng nhập họ tên và email');
      return;
    }
    const m = museums.find(x => x.id === newUserForm.museumId);
    addUser({
      name: newUserForm.name,
      email: newUserForm.email,
      phone: newUserForm.phone || '0900 000 000',
      role: newUserForm.role,
      museumId: newUserForm.museumId,
      museumName: m ? m.name : 'Bảo tàng Lịch sử Quốc gia',
      assignedGalleries: newUserForm.assignedGalleries ? newUserForm.assignedGalleries.split(',').map(s => s.trim()) : [],
      permissions: ['manage_artifacts', 'create_ai_content']
    });
    setIsAddingUser(false);
    setNewUserForm({
      name: '',
      email: '',
      phone: '',
      role: 'museumStaff',
      museumId: 'mus-01',
      assignedGalleries: ''
    });
  };

  const getRoleBadge = (role) => {
    switch (role) {
      case 'administrator':
        return <span className="badge-status role-badge-admin" style={{ fontSize: '0.75rem' }}><ShieldCheck size={13} /> Quản trị viên</span>;
      case 'curator':
        return <span className="badge-status role-badge-curator" style={{ fontSize: '0.75rem' }}><Sparkles size={13} /> Kiểm duyệt viên</span>;
      default:
        return <span className="badge-status role-badge-staff" style={{ fontSize: '0.75rem' }}><UserCheck size={13} /> Nhân viên bảo tàng</span>;
    }
  };

  return (
    <div>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '24px', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <h2 style={{ fontSize: '1.625rem', fontWeight: '700', color: 'var(--color-burgundy-900)' }} className="font-serif">
            Quản Lý Nhân Sự & Phân Quyền Hệ Thống
          </h2>
          <p style={{ fontSize: '0.875rem', color: 'var(--color-charcoal-500)', marginTop: '4px' }}>
            Phân bổ quyền hạn truy cập cho Quản trị viên, Kiểm duyệt viên và Nhân viên phụ trách từng bảo tàng
          </p>
        </div>

        <button
          type="button"
          onClick={() => setIsAddingUser(true)}
          className="btn btn-primary"
        >
          <Plus size={16} /> Thêm Tài Khoản Mới
        </button>
      </div>

      {/* Filter and Search Bar */}
      <div className="card" style={{ padding: '16px 20px', marginBottom: '24px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '16px', flexWrap: 'wrap' }}>
          <div style={{ position: 'relative', flex: 1, minWidth: '260px' }}>
            <Search size={16} color="var(--color-charcoal-400)" style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)' }} />
            <input
              type="text"
              className="form-input"
              style={{ paddingLeft: '36px' }}
              placeholder="Tìm theo họ tên, email, số điện thoại..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>

          <select
            className="form-select"
            style={{ width: 'auto', minWidth: '180px' }}
            value={roleFilter}
            onChange={(e) => setRoleFilter(e.target.value)}
          >
            <option value="all">Tất cả vai trò</option>
            <option value="administrator">Quản trị viên</option>
            <option value="curator">Kiểm duyệt viên</option>
            <option value="museumStaff">Nhân viên bảo tàng</option>
          </select>
        </div>
      </div>

      {/* Users Table */}
      <div className="card">
        <div className="table-container">
          <table className="data-table">
            <thead>
              <tr>
                <th>Thành viên</th>
                <th>Vai trò</th>
                <th>Bảo tàng & Khu vực phụ trách</th>
                <th>Liên hệ</th>
                <th>Đăng nhập gần nhất</th>
                <th>Trạng thái</th>
                <th style={{ textAlign: 'right' }}>Thao tác</th>
              </tr>
            </thead>
            <tbody>
              {filteredUsers.map(u => (
                <tr key={u.id}>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                      <div style={{
                        width: '38px',
                        height: '38px',
                        borderRadius: '50%',
                        background: 'linear-gradient(135deg, var(--color-burgundy-700), var(--color-gold-600))',
                        color: '#FFF',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontWeight: '700',
                        fontSize: '0.875rem'
                      }}>
                        {u.name.charAt(0)}
                      </div>
                      <div>
                        <div style={{ fontWeight: '600', color: 'var(--color-charcoal-900)' }}>{u.name}</div>
                        <div style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-500)' }}>{u.email}</div>
                      </div>
                    </div>
                  </td>

                  <td>{getRoleBadge(u.role)}</td>

                  <td>
                    <div style={{ fontSize: '0.8125rem', fontWeight: '500' }}>{u.museumName}</div>
                    {u.assignedGalleries && u.assignedGalleries.length > 0 && (
                      <div style={{ fontSize: '0.75rem', color: 'var(--color-burgundy-700)' }}>
                        Phòng: {u.assignedGalleries.join(', ')}
                      </div>
                    )}
                  </td>

                  <td>
                    <div style={{ fontSize: '0.8125rem', display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <Phone size={13} color="var(--color-charcoal-400)" />
                      <span>{u.phone}</span>
                    </div>
                  </td>

                  <td>
                    <span style={{ fontSize: '0.8125rem', color: 'var(--color-charcoal-600)' }}>{u.lastLogin}</span>
                  </td>

                  <td>
                    <span className={`badge-status badge-${u.status === 'active' ? 'active' : 'inactive'}`}>
                      {u.status === 'active' ? 'Đang kích hoạt' : 'Đã khóa'}
                    </span>
                  </td>

                  <td style={{ textAlign: 'right' }}>
                    <button
                      type="button"
                      onClick={() => toggleUserStatus(u.id)}
                      className="btn btn-secondary btn-sm"
                    >
                      {u.status === 'active' ? 'Khóa TK' : 'Mở khóa'}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Add User Modal */}
      {isAddingUser && (
        <div className="modal-overlay" onClick={() => setIsAddingUser(false)}>
          <div className="modal-dialog" style={{ maxWidth: '580px' }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3 className="modal-title font-serif">Tạo Tài Khoản Nhân Viên / Quản Trị</h3>
              <button type="button" onClick={() => setIsAddingUser(false)} className="btn btn-secondary btn-sm">✕</button>
            </div>
            <form onSubmit={handleAddUserSubmit}>
              <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                <div className="form-group" style={{ marginBottom: 0 }}>
                  <label className="form-label">Họ và tên *</label>
                  <input
                    type="text"
                    className="form-input"
                    value={newUserForm.name}
                    onChange={(e) => setNewUserForm(prev => ({ ...prev, name: e.target.value }))}
                    placeholder="Ví dụ: Nguyễn Văn An"
                    required
                  />
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">Email nội bộ *</label>
                    <input
                      type="email"
                      className="form-input"
                      value={newUserForm.email}
                      onChange={(e) => setNewUserForm(prev => ({ ...prev, email: e.target.value }))}
                      placeholder="an.nv@smgs.vn"
                      required
                    />
                  </div>
                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">Số điện thoại</label>
                    <input
                      type="text"
                      className="form-input"
                      value={newUserForm.phone}
                      onChange={(e) => setNewUserForm(prev => ({ ...prev, phone: e.target.value }))}
                      placeholder="0912 345 678"
                    />
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">Vai trò hệ thống</label>
                    <select
                      className="form-select"
                      value={newUserForm.role}
                      onChange={(e) => setNewUserForm(prev => ({ ...prev, role: e.target.value }))}
                    >
                      <option value="museumStaff">Nhân viên bảo tàng</option>
                      <option value="curator">Kiểm duyệt viên</option>
                      <option value="administrator">Quản trị viên</option>
                    </select>
                  </div>
                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">Bảo tàng phụ trách</label>
                    <select
                      className="form-select"
                      value={newUserForm.museumId}
                      onChange={(e) => setNewUserForm(prev => ({ ...prev, museumId: e.target.value }))}
                    >
                      {museums.map(m => (
                        <option key={m.id} value={m.id}>{m.name}</option>
                      ))}
                    </select>
                  </div>
                </div>

                <div className="form-group" style={{ marginBottom: 0 }}>
                  <label className="form-label">Phòng / Khu phân công quản lý (cách nhau bởi dấu phẩy)</label>
                  <input
                    type="text"
                    className="form-input"
                    value={newUserForm.assignedGalleries}
                    onChange={(e) => setNewUserForm(prev => ({ ...prev, assignedGalleries: e.target.value }))}
                    placeholder="Ví dụ: Phòng Đông Sơn, Phòng Sa Huỳnh"
                  />
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" onClick={() => setIsAddingUser(false)} className="btn btn-secondary">Hủy</button>
                <button type="submit" className="btn btn-primary">Tạo tài khoản</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
