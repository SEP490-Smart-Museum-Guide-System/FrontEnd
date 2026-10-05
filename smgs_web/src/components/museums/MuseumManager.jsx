import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import {
  Landmark,
  Building2,
  Layers,
  MapPin,
  Plus,
  Users,
  Eye,
  CheckCircle,
  FolderTree
} from 'lucide-react';

export default function MuseumManager() {
  const { museums, setMuseums, artifacts, showToast, logAction, currentRole, currentMuseum } = useApp();
  const [selectedMuseumId, setSelectedMuseumId] = useState(museums[0]?.id || 'mus-01');
  const [isAddingGallery, setIsAddingGallery] = useState(false);
  const [isEditingMuseum, setIsEditingMuseum] = useState(false);
  const [museumForm, setMuseumForm] = useState({});
  const [newGalleryData, setNewGalleryData] = useState({
    buildingId: '',
    floorId: '',
    name: '',
    code: '',
    theme: ''
  });

  const activeMuseum = currentRole === 'museumStaff' ? currentMuseum : museums.find(m => m.id === selectedMuseumId) || museums[0];

  const saveMuseumInfo = (event) => {
    event.preventDefault();
    setMuseums(prev => prev.map(item => item.id === activeMuseum.id ? { ...item, ...museumForm } : item));
    logAction('MUSEUM_UPDATE', `Cập nhật thông tin ${activeMuseum.name}`);
    showToast('Đã lưu thông tin bảo tàng.');
    setIsEditingMuseum(false);
  };

  const handleAddGallery = (e) => {
    e.preventDefault();
    if (!newGalleryData.name || !newGalleryData.buildingId || !newGalleryData.floorId) {
      alert('Vui lòng chọn tòa nhà, tầng và nhập tên phòng trưng bày');
      return;
    }

    const newGal = {
      id: `gal-${Date.now()}`,
      name: newGalleryData.name,
      code: newGalleryData.code || `G-${Date.now().toString().slice(-3)}`,
      artifactCount: 0,
      theme: newGalleryData.theme || 'Chuyên đề chung'
    };

    setMuseums(prev => prev.map(m => {
      if (m.id === activeMuseum.id) {
        const updatedBuildings = m.buildings.map(b => {
          if (b.id === newGalleryData.buildingId) {
            const updatedFloors = b.floors.map(f => {
              if (f.id === newGalleryData.floorId) {
                return { ...f, galleries: [...f.galleries, newGal] };
              }
              return f;
            });
            return { ...b, floors: updatedFloors };
          }
          return b;
        });
        return { ...m, buildings: updatedBuildings };
      }
      return m;
    }));

    logAction('GALLERY_CREATE', `Thêm phòng trưng bày "${newGal.name}" vào bảo tàng ${activeMuseum.name}`);
    showToast(`Đã thêm phòng "${newGal.name}" thành công!`);
    setIsAddingGallery(false);
    setNewGalleryData({ buildingId: '', floorId: '', name: '', code: '', theme: '' });
  };

  return (
    <div>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '24px', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <h2 style={{ fontSize: '1.625rem', fontWeight: '700', color: 'var(--color-burgundy-900)' }} className="font-serif">
            Cấu Trúc Không Gian & Phòng Trưng Bày
          </h2>
          <p style={{ fontSize: '0.875rem', color: 'var(--color-charcoal-500)', marginTop: '4px' }}>
            Quản lý thông tin bảo tàng, tòa nhà, tầng, phòng trưng bày và vị trí trên bản đồ.
          </p>
        </div>

        <button
          type="button"
          onClick={() => setIsAddingGallery(true)}
          className="btn btn-primary"
        >
          <Plus size={16} /> Thêm Phòng / Khu trưng bày
        </button>
      </div>

      {/* Museum Selector Tab Strip */}
      {currentRole !== 'museumStaff' && <div style={{ display: 'flex', gap: '12px', marginBottom: '24px', flexWrap: 'wrap' }}>
        {museums.map(m => {
          const isSelected = m.id === activeMuseum.id;
          return (
            <button
              key={m.id}
              type="button"
              onClick={() => setSelectedMuseumId(m.id)}
              style={{
                padding: '12px 18px',
                borderRadius: '10px',
                background: isSelected ? '#FFFFFF' : 'var(--color-paper-accent)',
                border: isSelected ? '2px solid var(--color-burgundy-700)' : '1px solid var(--color-paper-border)',
                display: 'flex',
                alignItems: 'center',
                gap: '10px',
                fontWeight: isSelected ? '700' : '500',
                color: isSelected ? 'var(--color-burgundy-900)' : 'var(--color-charcoal-700)',
                boxShadow: isSelected ? 'var(--shadow-sm)' : 'none',
                transition: 'all var(--transition-fast)'
              }}
            >
              <Landmark size={18} color={isSelected ? 'var(--color-burgundy-700)' : 'currentColor'} />
              <span>{m.name}</span>
            </button>
          );
        })}
      </div>}

      {/* Museum Information Banner */}
      <div className="card" style={{ padding: '24px', marginBottom: '28px', background: 'linear-gradient(135deg, var(--color-paper-card), var(--color-paper-bg))' }}>
        <div className="museum-intro-grid" style={{ display: 'grid', gridTemplateColumns: '220px minmax(0, 1fr)', gap: '24px', alignItems: 'center' }}>
          <div style={{ height: '140px', borderRadius: '10px', overflow: 'hidden', border: '1px solid var(--color-paper-border)' }}>
            <img
              src={activeMuseum.image || '/assets/images/national-museum-web.jpg'}
              alt={activeMuseum.name}
              style={{ width: '100%', height: '100%', objectFit: 'cover' }}
              onError={(e) => { e.target.src = '/assets/images/national-museum-web.jpg'; }}
            />
          </div>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '6px' }}>
              <h3 style={{ fontSize: '1.25rem', fontWeight: '700', color: 'var(--color-burgundy-900)' }}>
                {activeMuseum.name}
              </h3>
              <span className="badge-status badge-active">Đang hoạt động</span>
            </div>
            <p style={{ fontSize: '0.8125rem', color: 'var(--color-charcoal-600)', marginBottom: '8px', display: 'flex', alignItems: 'center', gap: '6px' }}>
              <MapPin size={14} color="var(--color-burgundy-700)" /> {activeMuseum.address}
            </p>
            <p style={{ fontSize: '0.8125rem', color: 'var(--color-charcoal-700)', lineHeight: '1.5' }}>
              {activeMuseum.description}
            </p>
            {currentRole === 'museumStaff' && <button className="btn btn-secondary btn-sm" type="button" style={{ marginTop: '12px' }} onClick={() => { setMuseumForm({ name: activeMuseum.name, address: activeMuseum.address, description: activeMuseum.description, image: activeMuseum.image }); setIsEditingMuseum(true); }}>Chỉnh sửa thông tin bảo tàng</button>}
          </div>
        </div>
      </div>

      {/* Spatial Structure Tree & Gallery Cards */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
        {activeMuseum.buildings?.map(bld => (
          <div key={bld.id} className="card">
            <div className="card-header" style={{ background: '#FAF7F2' }}>
              <div className="card-title">
                <Building2 size={20} color="var(--color-burgundy-700)" />
                <span>{bld.name}</span>
                <span style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-500)', fontWeight: 'normal' }}>
                  (Mã: {bld.code})
                </span>
              </div>
              <span style={{ fontSize: '0.8125rem', color: 'var(--color-charcoal-500)', fontWeight: '500' }}>
                {bld.floors?.length || 0} Tầng không gian
              </span>
            </div>

            <div className="card-body" style={{ padding: '20px 24px' }}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
                {bld.floors?.map(flr => (
                  <div key={flr.id} style={{ background: '#FAF8F5', padding: '16px 20px', borderRadius: '10px', border: '1px solid var(--color-paper-border)' }}>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '14px' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <FolderTree size={16} color="var(--color-gold-600)" />
                        <h4 style={{ fontSize: '0.9375rem', fontWeight: '700', color: 'var(--color-charcoal-900)' }}>
                          {flr.name}
                        </h4>
                      </div>
                      <span style={{ fontSize: '0.75rem', background: '#E2E8F0', padding: '2px 8px', borderRadius: '4px', fontWeight: '600' }}>
                        {flr.galleries?.length || 0} Phòng trưng bày
                      </span>
                    </div>

                    {/* Galleries Grid */}
                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(260px, 1fr))', gap: '14px' }}>
                      {flr.galleries?.map(gal => {
                        const countInGal = artifacts.filter(a => a.galleryName === gal.name).length || gal.artifactCount || 0;
                        return (
                          <div
                            key={gal.id}
                            style={{
                              background: '#FFFFFF',
                              padding: '14px 16px',
                              borderRadius: '8px',
                              border: '1px solid var(--color-paper-border)',
                              boxShadow: 'var(--shadow-sm)'
                            }}
                          >
                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '6px' }}>
                              <strong style={{ fontSize: '0.875rem', color: 'var(--color-burgundy-900)' }}>
                                {gal.name}
                              </strong>
                              <span style={{ fontSize: '0.675rem', fontFamily: 'monospace', background: '#F1F5F9', padding: '2px 6px', borderRadius: '4px' }}>
                                {gal.code}
                              </span>
                            </div>
                            <div style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-500)', marginBottom: '8px' }}>
                              Chủ đề: {gal.theme}
                            </div>
                            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', borderTop: '1px solid #F1F5F9', paddingTop: '8px' }}>
                              <span style={{ fontSize: '0.75rem', fontWeight: '600', color: 'var(--color-charcoal-700)' }}>
                                🏺 {countInGal} Hiện vật
                              </span>
                              <span style={{ fontSize: '0.7rem', color: 'var(--color-success)', fontWeight: '600' }}>
                                Đã định vị bản đồ
                              </span>
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        ))}
      </div>

      {isEditingMuseum && <div className="modal-overlay" onClick={() => setIsEditingMuseum(false)}><div className="modal-dialog" style={{ maxWidth: '620px' }} onClick={event => event.stopPropagation()}><div className="modal-header"><h3 className="modal-title font-serif">Thông tin bảo tàng</h3><button type="button" className="btn btn-secondary btn-sm" onClick={() => setIsEditingMuseum(false)}>Đóng</button></div><form onSubmit={saveMuseumInfo}><div className="modal-body" style={{ display: 'grid', gap: '14px' }}>{[['name', 'Tên bảo tàng'], ['address', 'Địa chỉ'], ['image', 'Đường dẫn ảnh đại diện']].map(([field, label]) => <label className="form-group" key={field}><span className="form-label">{label}</span><input className="form-input" value={museumForm[field] || ''} onChange={event => setMuseumForm(prev => ({ ...prev, [field]: event.target.value }))} required={field !== 'image'} /></label>)}<label className="form-group"><span className="form-label">Giới thiệu</span><textarea className="form-textarea" rows={4} value={museumForm.description || ''} onChange={event => setMuseumForm(prev => ({ ...prev, description: event.target.value }))} /></label></div><div className="modal-footer"><button type="button" className="btn btn-secondary" onClick={() => setIsEditingMuseum(false)}>Hủy</button><button type="submit" className="btn btn-primary">Lưu thông tin</button></div></form></div></div>}

      {/* Add Gallery Modal */}
      {isAddingGallery && (
        <div className="modal-overlay" onClick={() => setIsAddingGallery(false)}>
          <div className="modal-dialog" style={{ maxWidth: '540px' }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3 className="modal-title font-serif">Thêm Phòng / Khu Trưng Bày</h3>
              <button type="button" onClick={() => setIsAddingGallery(false)} className="btn btn-secondary btn-sm">
                ✕
              </button>
            </div>
            <form onSubmit={handleAddGallery}>
              <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                <div className="form-group" style={{ marginBottom: 0 }}>
                  <label className="form-label">Chọn Tòa nhà *</label>
                  <select
                    className="form-select"
                    value={newGalleryData.buildingId}
                    onChange={(e) => {
                      const bId = e.target.value;
                      const bld = activeMuseum.buildings.find(b => b.id === bId);
                      setNewGalleryData(prev => ({
                        ...prev,
                        buildingId: bId,
                        floorId: bld?.floors[0]?.id || ''
                      }));
                    }}
                    required
                  >
                    <option value="">-- Chọn tòa nhà --</option>
                    {activeMuseum.buildings.map(b => (
                      <option key={b.id} value={b.id}>{b.name}</option>
                    ))}
                  </select>
                </div>

                <div className="form-group" style={{ marginBottom: 0 }}>
                  <label className="form-label">Chọn Tầng *</label>
                  <select
                    className="form-select"
                    value={newGalleryData.floorId}
                    onChange={(e) => setNewGalleryData(prev => ({ ...prev, floorId: e.target.value }))}
                    disabled={!newGalleryData.buildingId}
                    required
                  >
                    <option value="">-- Chọn tầng --</option>
                    {activeMuseum.buildings.find(b => b.id === newGalleryData.buildingId)?.floors.map(f => (
                      <option key={f.id} value={f.id}>{f.name}</option>
                    ))}
                  </select>
                </div>

                <div className="form-group" style={{ marginBottom: 0 }}>
                  <label className="form-label">Tên Phòng / Khu trưng bày *</label>
                  <input
                    type="text"
                    className="form-input"
                    value={newGalleryData.name}
                    onChange={(e) => setNewGalleryData(prev => ({ ...prev, name: e.target.value }))}
                    placeholder="Ví dụ: Phòng Gốm Cổ Đại Việt"
                    required
                  />
                </div>

                <div className="form-group" style={{ marginBottom: 0 }}>
                  <label className="form-label">Mã phòng</label>
                  <input
                    type="text"
                    className="form-input"
                    value={newGalleryData.code}
                    onChange={(e) => setNewGalleryData(prev => ({ ...prev, code: e.target.value }))}
                    placeholder="Ví dụ: A2-GC"
                  />
                </div>

                <div className="form-group" style={{ marginBottom: 0 }}>
                  <label className="form-label">Chủ đề chính</label>
                  <input
                    type="text"
                    className="form-input"
                    value={newGalleryData.theme}
                    onChange={(e) => setNewGalleryData(prev => ({ ...prev, theme: e.target.value }))}
                    placeholder="Ví dụ: Gốm men & Nghệ thuật tạo tác"
                  />
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" onClick={() => setIsAddingGallery(false)} className="btn btn-secondary">
                  Hủy
                </button>
                <button type="submit" className="btn btn-primary">
                  Tạo phòng trưng bày
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
