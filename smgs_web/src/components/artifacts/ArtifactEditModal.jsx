import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { X, Save, Layers, Landmark } from 'lucide-react';

export default function ArtifactEditModal({ artifact, onClose, onSave }) {
  const { currentMuseum, museums, currentRole } = useApp();

  const isNew = !artifact || !artifact.id;

  const [formData, setFormData] = useState({
    id: artifact?.id || '',
    name: artifact?.name || '',
    altName: artifact?.altName || '',
    museumId: artifact?.museumId || currentMuseum.id,
    museumName: artifact?.museumName || currentMuseum.name,
    buildingName: artifact?.buildingName || 'Tòa nhà A',
    floorName: artifact?.floorName || 'Tầng 1',
    galleryName: artifact?.galleryName || 'Phòng Văn hóa Đông Sơn',
    qrCode: artifact?.qrCode || '',
    mapPosition: artifact?.mapPosition || '',
    mapIcon: artifact?.mapIcon || 'Hiện vật',
    mapX: artifact?.mapX ?? 50,
    mapY: artifact?.mapY ?? 50,
    theme: artifact?.theme || 'Đông Sơn & Thời đại Kim khí',
    period: artifact?.period || 'Văn hóa Đông Sơn (Thế kỷ II - III TCN)',
    dating: artifact?.dating || 'Khoảng 2.500 năm trước',
    material: artifact?.material || 'Hợp kim đồng',
    dimensions: artifact?.dimensions || '',
    isNationalTreasure: artifact?.isNationalTreasure || false,
    has3DModel: artifact?.has3DModel || false,
    modelUrl: artifact?.modelUrl || '/assets/models/trong_dong_dong_son.glb',
    image: artifact?.image || '/assets/images/ngoc-lu-web.jpg',
    referenceImages: artifact?.referenceImages || [],
    audioUrl: artifact?.audioUrl || '',
    accessLevel: artifact?.accessLevel || 'free',
    audioDuration: artifact?.audioDuration || '03:30',
    status: artifact?.status || 'draft',
    shortDesc: artifact?.shortDesc || '',
    fullDesc: artifact?.fullDesc || ''
  });

  const handleChange = (field, value) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!formData.name.trim()) {
      alert('Vui lòng nhập tên hiện vật');
      return;
    }
    onSave(formData);
    onClose();
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-dialog" style={{ maxWidth: '840px' }} onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div style={{
              width: '36px',
              height: '36px',
              borderRadius: '8px',
              background: 'var(--color-burgundy-100)',
              color: 'var(--color-burgundy-700)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center'
            }}>
              <Layers size={20} />
            </div>
            <div>
              <h3 className="modal-title font-serif">{isNew ? 'Thêm Hiện Vật Mới' : `Chỉnh Sửa: ${formData.name}`}</h3>
              <p style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-500)' }}>
                Nhập đầy đủ thông số nghiệp vụ và nội dung kiểm định di sản
              </p>
            </div>
          </div>
          <button type="button" onClick={onClose} className="btn btn-secondary btn-sm" style={{ borderRadius: '50%', padding: '6px' }}>
            <X size={18} />
          </button>
        </div>

        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', flex: 1, overflow: 'hidden' }}>
          <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            {/* Row 1: Name & Alt Name */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
              <div className="form-group" style={{ marginBottom: 0 }}>
                <label className="form-label">Tên hiện vật (Tiếng Việt) *</label>
                <input
                  type="text"
                  className="form-input"
                  value={formData.name}
                  onChange={(e) => handleChange('name', e.target.value)}
                  placeholder="Ví dụ: Trống đồng Ngọc Lũ"
                  required
                />
              </div>
              <div className="form-group" style={{ marginBottom: 0 }}>
                <label className="form-label">Tên gọi khác</label>
                <input
                  type="text"
                  className="form-input"
                  value={formData.altName}
                  onChange={(e) => handleChange('altName', e.target.value)}
                  placeholder="Ví dụ: Ngoc Lu Bronze Drum"
                />
              </div>
            </div>

            {/* Row 2: Space Hierarchy */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '16px' }}>
              <div className="form-group" style={{ marginBottom: 0 }}>
                <label className="form-label">Bảo tàng</label>
                <select
                  className="form-select"
                  value={formData.museumId}
                  onChange={(e) => {
                    const m = museums.find(x => x.id === e.target.value);
                    setFormData(prev => ({
                      ...prev,
                      museumId: e.target.value,
                      museumName: m ? m.name : prev.museumName
                    }));
                  }}
                >
                  {(currentRole === 'museumStaff' ? [currentMuseum] : museums).map(m => (
                    <option key={m.id} value={m.id}>{m.name}</option>
                  ))}
                </select>
              </div>

              <div className="form-group" style={{ marginBottom: 0 }}>
                <label className="form-label">Tòa nhà & Tầng</label>
                <input
                  type="text"
                  className="form-input"
                  value={`${formData.buildingName} — ${formData.floorName}`}
                  onChange={(e) => handleChange('buildingName', e.target.value)}
                  placeholder="Tòa nhà A — Tầng 1"
                />
              </div>

              <div className="form-group" style={{ marginBottom: 0 }}>
                <label className="form-label">Phòng / Khu trưng bày</label>
                <input
                  type="text"
                  className="form-input"
                  value={formData.galleryName}
                  onChange={(e) => handleChange('galleryName', e.target.value)}
                  placeholder="Phòng Văn hóa Đông Sơn"
                />
              </div>
            </div>

            {/* Row 3: Period, Dating, Material */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '16px' }}>
              <div className="form-group" style={{ marginBottom: 0 }}>
                <label className="form-label">Thời kỳ / Triều đại</label>
                <input
                  type="text"
                  className="form-input"
                  value={formData.period}
                  onChange={(e) => handleChange('period', e.target.value)}
                  placeholder="Văn hóa Đông Sơn (Thế kỷ II - III TCN)"
                />
              </div>
              <div className="form-group" style={{ marginBottom: 0 }}>
                <label className="form-label">Chất liệu</label>
                <input
                  type="text"
                  className="form-input"
                  value={formData.material}
                  onChange={(e) => handleChange('material', e.target.value)}
                  placeholder="Hợp kim Đồng"
                />
              </div>
              <div className="form-group" style={{ marginBottom: 0 }}>
                <label className="form-label">Chủ đề</label>
                <input
                  type="text"
                  className="form-input"
                  value={formData.theme}
                  onChange={(e) => handleChange('theme', e.target.value)}
                  placeholder="Đông Sơn & Thời đại Kim khí"
                />
              </div>
            </div>

            {/* Row 4: Dimensions & Status */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
              <div className="form-group" style={{ marginBottom: 0 }}>
                <label className="form-label">Kích thước & Trọng lượng</label>
                <input
                  type="text"
                  className="form-input"
                  value={formData.dimensions}
                  onChange={(e) => handleChange('dimensions', e.target.value)}
                  placeholder="Đường kính: 79cm, Cao: 63cm..."
                />
              </div>
              <div className="form-group" style={{ marginBottom: 0 }}>
                <label className="form-label">Trạng thái phát hành</label>
                <select
                  className="form-select"
                  value={formData.status}
                  onChange={(e) => handleChange('status', e.target.value)}
                >
                  <option value="published">Đã xuất bản (Khách có thể xem và quét QR)</option>
                  <option value="pending">Chờ kiểm tra nội dung</option>
                  <option value="draft">Bản nháp nội bộ</option>
                </select>
              </div>
            </div>

            <div className="card" style={{ padding: '18px', display: 'grid', gap: '14px' }}>
              <strong style={{ color: 'var(--color-burgundy-900)' }}>Mã QR, bản đồ & tư liệu số</strong>
              <div className="artifact-edit-grid">
                <label className="form-group"><span className="form-label">Mã QR</span><input className="form-input" value={formData.qrCode} onChange={e => handleChange('qrCode', e.target.value)} placeholder="Tự tạo nếu để trống" /></label>
                <label className="form-group"><span className="form-label">Vị trí trên bản đồ</span><input className="form-input" value={formData.mapPosition} onChange={e => handleChange('mapPosition', e.target.value)} placeholder="Ví dụ: Tầng 1, phòng Đông Sơn, tọa độ A3" /></label>
                <label className="form-group"><span className="form-label">Biểu tượng trên bản đồ</span><input className="form-input" value={formData.mapIcon} onChange={e => handleChange('mapIcon', e.target.value)} placeholder="Ví dụ: Trống đồng" /></label>
                <label className="form-group"><span className="form-label">Quyền truy cập nội dung</span><select className="form-select" value={formData.accessLevel} onChange={e => handleChange('accessLevel', e.target.value)}><option value="free">Miễn phí</option><option value="premium">Cần gói nâng cao</option></select></label>
                <label className="form-group"><span className="form-label">Ảnh đại diện</span><input className="form-input" value={formData.image} onChange={e => handleChange('image', e.target.value)} placeholder="Đường dẫn ảnh" /></label>
                <label className="form-group"><span className="form-label">Âm thanh thuyết minh</span><input className="form-input" value={formData.audioUrl} onChange={e => handleChange('audioUrl', e.target.value)} placeholder="Đường dẫn âm thanh" /></label>
              </div>
              <label className="form-group"><span className="form-label">Ảnh tư liệu bổ sung (mỗi dòng một đường dẫn)</span><textarea className="form-textarea" rows={3} value={formData.referenceImages.join('\n')} onChange={e => handleChange('referenceImages', e.target.value.split('\n').map(value => value.trim()).filter(Boolean))} /></label>
              <label className="form-group"><span className="form-label">Mô hình 3D</span><input className="form-input" value={formData.modelUrl} onChange={e => handleChange('modelUrl', e.target.value)} placeholder="Đường dẫn mô hình 3D" /></label>
              <div><span className="form-label">Đặt biểu tượng trên sơ đồ phòng</span><div className="artifact-map-preview" role="button" tabIndex={0} aria-label="Chọn vị trí hiện vật trên sơ đồ phòng" onClick={event => { const rect = event.currentTarget.getBoundingClientRect(); setFormData(prev => ({ ...prev, mapX: Math.round((event.clientX - rect.left) / rect.width * 100), mapY: Math.round((event.clientY - rect.top) / rect.height * 100) })); }} onKeyDown={event => { if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); setFormData(prev => ({ ...prev, mapX: 50, mapY: 50 })); } }}><div className="artifact-map-marker" style={{ left: `${formData.mapX}%`, top: `${formData.mapY}%` }}>{formData.mapIcon || 'Hiện vật'}</div></div><small>Chạm vào sơ đồ để đặt vị trí · {formData.mapX}%, {formData.mapY}%</small></div>
            </div>

            {/* Checkboxes: National treasure & 3D model */}
            <div style={{ display: 'flex', gap: '24px', background: '#FAF7F2', padding: '12px 16px', borderRadius: '8px' }}>
              <label style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '0.875rem', cursor: 'pointer' }}>
                <input
                  type="checkbox"
                  checked={formData.isNationalTreasure}
                  onChange={(e) => handleChange('isNationalTreasure', e.target.checked)}
                />
                <span style={{ fontWeight: '600', color: 'var(--color-burgundy-900)' }}>⭐ Bảo vật Quốc gia</span>
              </label>

              <label style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '0.875rem', cursor: 'pointer' }}>
                <input
                  type="checkbox"
                  checked={formData.has3DModel}
                  onChange={(e) => handleChange('has3DModel', e.target.checked)}
                />
                <span style={{ fontWeight: '600', color: 'var(--color-charcoal-800)' }}>Đã có mô hình 3D AR (.glb)</span>
              </label>
            </div>

            {/* Short Desc */}
            <div className="form-group" style={{ marginBottom: 0 }}>
              <label className="form-label">Tóm tắt ngắn (Hiển thị thẻ bài & danh sách)</label>
              <textarea
                className="form-textarea"
                rows={2}
                value={formData.shortDesc}
                onChange={(e) => handleChange('shortDesc', e.target.value)}
                placeholder="Tóm tắt 2-3 câu nổi bật về hiện vật..."
              />
            </div>

            {/* Full Narration */}
            <div className="form-group" style={{ marginBottom: 0 }}>
              <label className="form-label">Nội dung thuyết minh chi tiết</label>
              <textarea
                className="form-textarea"
                rows={5}
                value={formData.fullDesc}
                onChange={(e) => handleChange('fullDesc', e.target.value)}
                placeholder="Nội dung thuyết minh hoàn chỉnh có hoa văn, tích sử, giá trị văn hóa..."
              />
            </div>
          </div>

          <div className="modal-footer">
            <button type="button" onClick={onClose} className="btn btn-secondary">
              Hủy bỏ
            </button>
            <button type="submit" className="btn btn-primary">
              <Save size={16} /> Lưu hiện vật
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
