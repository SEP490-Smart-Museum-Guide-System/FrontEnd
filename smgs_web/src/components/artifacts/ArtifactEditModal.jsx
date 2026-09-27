import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { X, Save, Layers, Landmark } from 'lucide-react';

export default function ArtifactEditModal({ artifact, onClose, onSave }) {
  const { currentMuseum, museums } = useApp();

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
    theme: artifact?.theme || 'Đông Sơn & Thời đại Kim khí',
    period: artifact?.period || 'Văn hóa Đông Sơn (Thế kỷ II - III TCN)',
    dating: artifact?.dating || 'Khoảng 2.500 năm trước',
    material: artifact?.material || 'Hợp kim Đồng (Bronze)',
    dimensions: artifact?.dimensions || '',
    isNationalTreasure: artifact?.isNationalTreasure || false,
    has3DModel: artifact?.has3DModel || false,
    modelUrl: artifact?.modelUrl || '/assets/models/trong_dong_dong_son.glb',
    image: artifact?.image || '/assets/images/ngoc-lu-web.jpg',
    audioDuration: artifact?.audioDuration || '03:30',
    status: artifact?.status || 'published',
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
                <label className="form-label">Tên quốc tế (English)</label>
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
                  {museums.map(m => (
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
                <label className="form-label">Chủ đề (Theme)</label>
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
                  <option value="pending">Chờ kiểm duyệt viên duyệt (Pending Review)</option>
                  <option value="draft">Bản nháp nội bộ (Draft)</option>
                </select>
              </div>
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
