import React, { useState } from 'react';
import { createPortal } from 'react-dom';
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
  FolderTree,
  Trash2,
  Edit3,
  Clock,
  Globe
} from 'lucide-react';
import MuseumMapPreview from './MuseumMapPreview';

export default function MuseumManager() {
  const {
    museums,
    setMuseums,
    artifacts,
    showToast,
    logAction,
    currentRole,
    currentMuseum,
    toggleMuseumGoogleMapsVisibility,
    cities,
    createMuseum,
    updateMuseum,
    deleteMuseum
  } = useApp();

  const [selectedMuseumId, setSelectedMuseumId] = useState(museums[0]?.id || 'mus-01');
  const [isAddingGallery, setIsAddingGallery] = useState(false);
  const [isEditingMuseum, setIsEditingMuseum] = useState(false);
  const [isAddingMuseum, setIsAddingMuseum] = useState(false);
  const [isConfirmingDelete, setIsConfirmingDelete] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const [museumForm, setMuseumForm] = useState({});
  const [newMuseumData, setNewMuseumData] = useState({
    name: '',
    cityCode: '01',
    address: '',
    latitude: 21.0257,
    longitude: 105.8584,
    openingHours: '08:00 - 17:00 (Thứ 3 - Chủ nhật)',
    coverImageUrl: '/assets/images/national-museum-web.jpg',
    description: ''
  });

  const [newGalleryData, setNewGalleryData] = useState({
    buildingId: '',
    floorId: '',
    name: '',
    code: '',
    theme: ''
  });

  const activeMuseum = currentRole === 'museumStaff'
    ? currentMuseum
    : museums.find(m => m.id === selectedMuseumId) || museums[0];

  const cityOptions = cities && cities.length > 0 ? cities : [
    { key: '01', value: 'Thành phố Hà Nội' },
    { key: '79', value: 'Thành phố Hồ Chí Minh' },
    { key: '48', value: 'Thành phố Đà Nẵng' },
    { key: '46', value: 'Thành phố Huế' },
    { key: '31', value: 'Thành phố Hải Phòng' },
    { key: '92', value: 'Thành phố Cần Thơ' }
  ];

  const handleOpenEditMuseum = () => {
    setMuseumForm({
      name: activeMuseum.name || '',
      cityCode: activeMuseum.cityCode || '01',
      address: activeMuseum.address || '',
      latitude: activeMuseum.latitude ?? 21.0257,
      longitude: activeMuseum.longitude ?? 105.8584,
      openingHours: activeMuseum.openingHours || '08:00 - 17:00 (Thứ 3 - Chủ nhật)',
      image: activeMuseum.image || activeMuseum.coverImageUrl || '',
      description: activeMuseum.description || ''
    });
    setIsEditingMuseum(true);
  };

  const saveMuseumInfo = async (event) => {
    event.preventDefault();
    setIsSubmitting(true);
    try {
      const res = await updateMuseum(activeMuseum.id, museumForm);
      if (res?.success) {
        setIsEditingMuseum(false);
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleCreateMuseum = async (e) => {
    e.preventDefault();
    if (!newMuseumData.name.trim()) {
      showToast('Vui lòng nhập tên bảo tàng.', 'warning');
      return;
    }
    setIsSubmitting(true);
    try {
      const res = await createMuseum({
        name: newMuseumData.name.trim(),
        cityCode: newMuseumData.cityCode,
        address: newMuseumData.address.trim(),
        latitude: newMuseumData.latitude ? Number(newMuseumData.latitude) : null,
        longitude: newMuseumData.longitude ? Number(newMuseumData.longitude) : null,
        openingHours: newMuseumData.openingHours.trim(),
        coverImageUrl: newMuseumData.coverImageUrl.trim(),
        description: newMuseumData.description.trim()
      });

      if (res?.success) {
        if (res.data?.id) {
          setSelectedMuseumId(res.data.id);
        }
        setIsAddingMuseum(false);
        setNewMuseumData({
          name: '',
          cityCode: '01',
          address: '',
          latitude: 21.0257,
          longitude: 105.8584,
          openingHours: '08:00 - 17:00 (Thứ 3 - Chủ nhật)',
          coverImageUrl: '/assets/images/national-museum-web.jpg',
          description: ''
        });
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleConfirmDelete = async () => {
    setIsSubmitting(true);
    try {
      const res = await deleteMuseum(activeMuseum.id);
      if (res?.success) {
        setIsConfirmingDelete(false);
      }
    } finally {
      setIsSubmitting(false);
    }
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
        const buildings = m.buildings || [];
        const updatedBuildings = buildings.map(b => {
          if (b.id === newGalleryData.buildingId) {
            const updatedFloors = (b.floors || []).map(f => {
              if (f.id === newGalleryData.floorId) {
                return { ...f, galleries: [...(f.galleries || []), newGal] };
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
            Quản lý thông tin bảo tàng, không gian trưng bày và trạng thái hiển thị cho khách trên Google Maps.
          </p>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', flexWrap: 'wrap' }}>
          {currentRole === 'administrator' && (
            <button
              type="button"
              onClick={() => setIsAddingMuseum(true)}
              className="btn btn-primary"
            >
              <Plus size={16} /> Thêm Bảo Tàng Mới
            </button>
          )}

          <button
            type="button"
            onClick={() => setIsAddingGallery(true)}
            className="btn btn-secondary"
          >
            <Plus size={16} /> Thêm Phòng / Khu trưng bày
          </button>
        </div>
      </div>

      {/* Museum Selector Tab Strip */}
      {currentRole !== 'museumStaff' && (
        <div style={{ display: 'flex', gap: '12px', marginBottom: '24px', flexWrap: 'wrap' }}>
          {museums.map(m => {
            const isSelected = m.id === activeMuseum.id;
            const isInactive = m.status === 'inactive';
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
                  color: isSelected ? 'var(--color-burgundy-900)' : isInactive ? 'var(--color-charcoal-400)' : 'var(--color-charcoal-700)',
                  boxShadow: isSelected ? 'var(--shadow-sm)' : 'none',
                  transition: 'all var(--transition-fast)',
                  opacity: isInactive ? 0.75 : 1
                }}
              >
                <Landmark size={18} color={isSelected ? 'var(--color-burgundy-700)' : 'currentColor'} />
                <span>{m.name}</span>
                {isInactive && (
                  <span style={{ fontSize: '0.675rem', padding: '2px 6px', background: '#FEE2E2', color: '#991B1B', borderRadius: '4px', fontWeight: '600' }}>
                    Tạm ngưng
                  </span>
                )}
              </button>
            );
          })}
        </div>
      )}

      <MuseumMapPreview
        museums={museums}
        currentRole={currentRole}
        onToggleVisibility={toggleMuseumGoogleMapsVisibility}
      />

      {/* Museum Information Banner */}
      <div className="card" style={{ padding: '24px', marginBottom: '28px', background: 'linear-gradient(135deg, var(--color-paper-card), var(--color-paper-bg))' }}>
        <div className="museum-intro-grid" style={{ display: 'grid', gridTemplateColumns: '220px minmax(0, 1fr)', gap: '24px', alignItems: 'center' }}>
          <div style={{ height: '140px', borderRadius: '10px', overflow: 'hidden', border: '1px solid var(--color-paper-border)' }}>
            <img
              src={activeMuseum.image || activeMuseum.coverImageUrl || '/assets/images/national-museum-web.jpg'}
              alt={activeMuseum.name}
              style={{ width: '100%', height: '100%', objectFit: 'cover' }}
              onError={(e) => { e.target.src = '/assets/images/national-museum-web.jpg'; }}
            />
          </div>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '6px', flexWrap: 'wrap' }}>
              <h3 style={{ fontSize: '1.25rem', fontWeight: '700', color: 'var(--color-burgundy-900)' }}>
                {activeMuseum.name}
              </h3>
              {activeMuseum.status === 'active' ? (
                <span className="badge-status badge-active">Đang hoạt động</span>
              ) : (
                <span className="badge-status" style={{ background: '#FEE2E2', color: '#991B1B' }}>Đã vô hiệu hóa</span>
              )}
              {activeMuseum.backendId && (
                <span style={{ fontSize: '0.7rem', background: '#E2E8F0', padding: '2px 8px', borderRadius: '4px', color: '#475569', fontWeight: '600' }}>
                  Backend ID: #{activeMuseum.backendId}
                </span>
              )}
            </div>
            <p style={{ fontSize: '0.8125rem', color: 'var(--color-charcoal-600)', marginBottom: '8px', display: 'flex', alignItems: 'center', gap: '6px', flexWrap: 'wrap' }}>
              <MapPin size={14} color="var(--color-burgundy-700)" /> {activeMuseum.address}
              {activeMuseum.openingHours && (
                <span style={{ marginLeft: '12px', display: 'inline-flex', alignItems: 'center', gap: '4px' }}>
                  <Clock size={13} color="var(--color-gold-600)" /> {activeMuseum.openingHours}
                </span>
              )}
            </p>
            <p style={{ fontSize: '0.8125rem', color: 'var(--color-charcoal-700)', lineHeight: '1.5' }}>
              {activeMuseum.description}
            </p>

            <div style={{ display: 'flex', gap: '10px', marginTop: '14px', flexWrap: 'wrap' }}>
              {(currentRole === 'museumStaff' || currentRole === 'administrator') && (
                <button
                  className="btn btn-secondary btn-sm"
                  type="button"
                  onClick={handleOpenEditMuseum}
                >
                  <Edit3 size={14} /> Chỉnh sửa thông tin bảo tàng
                </button>
              )}
              {currentRole === 'administrator' && (
                <button
                  className="btn btn-sm"
                  type="button"
                  style={{
                    border: '1px solid #FCA5A5',
                    color: activeMuseum.status === 'inactive' ? 'var(--color-charcoal-500)' : '#B91C1C',
                    background: activeMuseum.status === 'inactive' ? '#F1F5F9' : '#FEF2F2',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px'
                  }}
                  onClick={() => setIsConfirmingDelete(true)}
                  disabled={activeMuseum.status === 'inactive'}
                >
                  <Trash2 size={14} /> {activeMuseum.status === 'inactive' ? 'Đã vô hiệu hóa' : 'Vô hiệu hóa bảo tàng'}
                </button>
              )}
            </div>
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

      {/* Edit Museum Modal */}
      {isEditingMuseum && typeof document !== 'undefined' && createPortal(
        <div className="modal-overlay" onClick={() => setIsEditingMuseum(false)}>
          <div className="modal-dialog" style={{ maxWidth: '640px', width: '95vw', maxHeight: 'calc(100vh - 40px)', display: 'flex', flexDirection: 'column', minHeight: 0 }} onClick={event => event.stopPropagation()}>
            <div className="modal-header">
              <h3 className="modal-title font-serif">Chỉnh Sửa Thông Tin Bảo Tàng</h3>
              <button type="button" className="btn btn-secondary btn-sm" onClick={() => setIsEditingMuseum(false)}>✕</button>
            </div>
            <form onSubmit={saveMuseumInfo} style={{ display: 'flex', flexDirection: 'column', flex: 1, minHeight: 0, overflow: 'hidden' }}>
              <div className="modal-body" style={{ display: 'grid', gap: '14px', flex: 1, minHeight: 0, overflowY: 'auto' }}>
                <label className="form-group" style={{ marginBottom: 0 }}>
                  <span className="form-label">Tên bảo tàng *</span>
                  <input
                    className="form-input"
                    value={museumForm.name || ''}
                    onChange={e => setMuseumForm(prev => ({ ...prev, name: e.target.value }))}
                    required
                  />
                </label>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                  <label className="form-group" style={{ marginBottom: 0 }}>
                    <span className="form-label">Tỉnh / Thành phố *</span>
                    <select
                      className="form-select"
                      value={museumForm.cityCode || '01'}
                      onChange={e => setMuseumForm(prev => ({ ...prev, cityCode: e.target.value }))}
                      required
                    >
                      {cityOptions.map(city => (
                        <option key={city.key} value={city.key}>
                          {city.value} ({city.key})
                        </option>
                      ))}
                    </select>
                  </label>

                  <label className="form-group" style={{ marginBottom: 0 }}>
                    <span className="form-label">Giờ mở cửa</span>
                    <input
                      className="form-input"
                      value={museumForm.openingHours || ''}
                      onChange={e => setMuseumForm(prev => ({ ...prev, openingHours: e.target.value }))}
                      placeholder="08:00 - 17:00 (Thứ 3 - Chủ nhật)"
                    />
                  </label>
                </div>

                <label className="form-group" style={{ marginBottom: 0 }}>
                  <span className="form-label">Địa chỉ bảo tàng *</span>
                  <input
                    className="form-input"
                    value={museumForm.address || ''}
                    onChange={e => setMuseumForm(prev => ({ ...prev, address: e.target.value }))}
                    required
                  />
                </label>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                  <label className="form-group" style={{ marginBottom: 0 }}>
                    <span className="form-label">Tọa độ GPS (Vĩ độ / Lat)</span>
                    <input
                      type="number"
                      step="any"
                      className="form-input"
                      value={museumForm.latitude ?? ''}
                      onChange={e => setMuseumForm(prev => ({ ...prev, latitude: e.target.value }))}
                      placeholder="21.0257"
                    />
                  </label>

                  <label className="form-group" style={{ marginBottom: 0 }}>
                    <span className="form-label">Tọa độ GPS (Kinh độ / Lng)</span>
                    <input
                      type="number"
                      step="any"
                      className="form-input"
                      value={museumForm.longitude ?? ''}
                      onChange={e => setMuseumForm(prev => ({ ...prev, longitude: e.target.value }))}
                      placeholder="105.8584"
                    />
                  </label>
                </div>

                <label className="form-group" style={{ marginBottom: 0 }}>
                  <span className="form-label">Đường dẫn ảnh đại diện (Cover Image URL)</span>
                  <input
                    className="form-input"
                    value={museumForm.image || ''}
                    onChange={e => setMuseumForm(prev => ({ ...prev, image: e.target.value }))}
                    placeholder="/assets/images/..."
                  />
                </label>

                <label className="form-group" style={{ marginBottom: 0 }}>
                  <span className="form-label">Giới thiệu bảo tàng</span>
                  <textarea
                    className="form-textarea"
                    rows={4}
                    value={museumForm.description || ''}
                    onChange={e => setMuseumForm(prev => ({ ...prev, description: e.target.value }))}
                  />
                </label>
              </div>
              <div className="modal-footer" style={{ flexShrink: 0 }}>
                <button type="button" className="btn btn-secondary" onClick={() => setIsEditingMuseum(false)} disabled={isSubmitting}>
                  Hủy
                </button>
                <button type="submit" className="btn btn-primary" disabled={isSubmitting}>
                  {isSubmitting ? 'Đang lưu...' : 'Lưu thông tin'}
                </button>
              </div>
            </form>
          </div>
        </div>,
        document.body
      )}

      {/* Add Museum Modal (Admin only) */}
      {isAddingMuseum && typeof document !== 'undefined' && createPortal(
        <div className="modal-overlay" onClick={() => setIsAddingMuseum(false)}>
          <div className="modal-dialog" style={{ maxWidth: '640px', width: '95vw', maxHeight: 'calc(100vh - 40px)', display: 'flex', flexDirection: 'column', minHeight: 0 }} onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <h3 className="modal-title font-serif">Thêm Bảo Tàng Mới Vào Hệ Thống</h3>
              <button type="button" className="btn btn-secondary btn-sm" onClick={() => setIsAddingMuseum(false)}>✕</button>
            </div>
            <form onSubmit={handleCreateMuseum} style={{ display: 'flex', flexDirection: 'column', flex: 1, minHeight: 0, overflow: 'hidden' }}>
              <div className="modal-body" style={{ display: 'grid', gap: '14px', flex: 1, minHeight: 0, overflowY: 'auto' }}>
                <label className="form-group" style={{ marginBottom: 0 }}>
                  <span className="form-label">Tên bảo tàng *</span>
                  <input
                    className="form-input"
                    value={newMuseumData.name}
                    onChange={e => setNewMuseumData(prev => ({ ...prev, name: e.target.value }))}
                    placeholder="Ví dụ: Bảo tàng Lịch sử Thành phố"
                    required
                  />
                </label>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                  <label className="form-group" style={{ marginBottom: 0 }}>
                    <span className="form-label">Tỉnh / Thành phố *</span>
                    <select
                      className="form-select"
                      value={newMuseumData.cityCode}
                      onChange={e => setNewMuseumData(prev => ({ ...prev, cityCode: e.target.value }))}
                      required
                    >
                      {cityOptions.map(city => (
                        <option key={city.key} value={city.key}>
                          {city.value} ({city.key})
                        </option>
                      ))}
                    </select>
                  </label>

                  <label className="form-group" style={{ marginBottom: 0 }}>
                    <span className="form-label">Giờ mở cửa</span>
                    <input
                      className="form-input"
                      value={newMuseumData.openingHours}
                      onChange={e => setNewMuseumData(prev => ({ ...prev, openingHours: e.target.value }))}
                      placeholder="08:00 - 17:00"
                    />
                  </label>
                </div>

                <label className="form-group" style={{ marginBottom: 0 }}>
                  <span className="form-label">Địa chỉ cụ thể *</span>
                  <input
                    className="form-input"
                    value={newMuseumData.address}
                    onChange={e => setNewMuseumData(prev => ({ ...prev, address: e.target.value }))}
                    placeholder="Số nhà, tên đường, quận/huyện"
                    required
                  />
                </label>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                  <label className="form-group" style={{ marginBottom: 0 }}>
                    <span className="form-label">Vĩ độ (Latitude)</span>
                    <input
                      type="number"
                      step="any"
                      className="form-input"
                      value={newMuseumData.latitude}
                      onChange={e => setNewMuseumData(prev => ({ ...prev, latitude: e.target.value }))}
                      placeholder="21.0257"
                    />
                  </label>

                  <label className="form-group" style={{ marginBottom: 0 }}>
                    <span className="form-label">Kinh độ (Longitude)</span>
                    <input
                      type="number"
                      step="any"
                      className="form-input"
                      value={newMuseumData.longitude}
                      onChange={e => setNewMuseumData(prev => ({ ...prev, longitude: e.target.value }))}
                      placeholder="105.8584"
                    />
                  </label>
                </div>

                <label className="form-group" style={{ marginBottom: 0 }}>
                  <span className="form-label">Đường dẫn ảnh đại diện</span>
                  <input
                    className="form-input"
                    value={newMuseumData.coverImageUrl}
                    onChange={e => setNewMuseumData(prev => ({ ...prev, coverImageUrl: e.target.value }))}
                    placeholder="/assets/images/national-museum-web.jpg"
                  />
                </label>

                <label className="form-group" style={{ marginBottom: 0 }}>
                  <span className="form-label">Giới thiệu bảo tàng</span>
                  <textarea
                    className="form-textarea"
                    rows={3}
                    value={newMuseumData.description}
                    onChange={e => setNewMuseumData(prev => ({ ...prev, description: e.target.value }))}
                    placeholder="Tóm tắt di sản và thông điệp lịch sử..."
                  />
                </label>
              </div>

              <div className="modal-footer" style={{ flexShrink: 0 }}>
                <button type="button" className="btn btn-secondary" onClick={() => setIsAddingMuseum(false)} disabled={isSubmitting}>
                  Hủy
                </button>
                <button type="submit" className="btn btn-primary" disabled={isSubmitting}>
                  {isSubmitting ? 'Đang tạo...' : 'Tạo bảo tàng mới'}
                </button>
              </div>
            </form>
          </div>
        </div>,
        document.body
      )}

      {/* Delete/Deactivate Confirmation Modal */}
      {isConfirmingDelete && typeof document !== 'undefined' && createPortal(
        <div className="modal-overlay" onClick={() => setIsConfirmingDelete(false)}>
          <div className="modal-dialog" style={{ maxWidth: '480px', width: '95vw' }} onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <h3 className="modal-title font-serif" style={{ color: '#B91C1C' }}>Xác Nhận Vô Hiệu Hóa</h3>
              <button type="button" className="btn btn-secondary btn-sm" onClick={() => setIsConfirmingDelete(false)}>✕</button>
            </div>
            <div className="modal-body" style={{ padding: '20px 24px' }}>
              <p style={{ fontSize: '0.9375rem', color: 'var(--color-charcoal-700)', lineHeight: '1.6' }}>
                Bạn có chắc chắn muốn vô hiệu hóa bảo tàng <strong>{activeMuseum.name}</strong> không?
              </p>
              <p style={{ fontSize: '0.8125rem', color: 'var(--color-charcoal-500)', marginTop: '8px' }}>
                Hành động này sẽ ẩn bảo tàng khỏi ứng dụng khách tham quan di động (Mobile) theo quy chế soft-delete của Backend.
              </p>
            </div>
            <div className="modal-footer">
              <button type="button" className="btn btn-secondary" onClick={() => setIsConfirmingDelete(false)} disabled={isSubmitting}>
                Hủy bỏ
              </button>
              <button
                type="button"
                className="btn btn-primary"
                style={{ background: '#B91C1C', borderColor: '#B91C1C' }}
                onClick={handleConfirmDelete}
                disabled={isSubmitting}
              >
                {isSubmitting ? 'Đang xử lý...' : 'Xác nhận vô hiệu hóa'}
              </button>
            </div>
          </div>
        </div>,
        document.body
      )}

      {/* Add Gallery Modal */}
      {isAddingGallery && typeof document !== 'undefined' && createPortal(
        <div className="modal-overlay" onClick={() => setIsAddingGallery(false)}>
          <div className="modal-dialog" style={{ maxWidth: '540px', width: '95vw', maxHeight: 'calc(100vh - 40px)', display: 'flex', flexDirection: 'column', minHeight: 0 }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3 className="modal-title font-serif">Thêm Phòng / Khu Trưng Bày</h3>
              <button type="button" onClick={() => setIsAddingGallery(false)} className="btn btn-secondary btn-sm">
                ✕
              </button>
            </div>
            <form onSubmit={handleAddGallery} style={{ display: 'flex', flexDirection: 'column', flex: 1, minHeight: 0, overflow: 'hidden' }}>
              <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: '14px', flex: 1, minHeight: 0, overflowY: 'auto' }}>
                <div className="form-group" style={{ marginBottom: 0 }}>
                  <label className="form-label">Chọn Tòa nhà *</label>
                  <select
                    className="form-select"
                    value={newGalleryData.buildingId}
                    onChange={(e) => {
                      const bId = e.target.value;
                      const bld = (activeMuseum.buildings || []).find(b => b.id === bId);
                      setNewGalleryData(prev => ({
                        ...prev,
                        buildingId: bId,
                        floorId: bld?.floors?.[0]?.id || ''
                      }));
                    }}
                    required
                  >
                    <option value="">-- Chọn tòa nhà --</option>
                    {(activeMuseum.buildings || []).map(b => (
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
                    {((activeMuseum.buildings || []).find(b => b.id === newGalleryData.buildingId)?.floors || []).map(f => (
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

              <div className="modal-footer" style={{ flexShrink: 0 }}>
                <button type="button" onClick={() => setIsAddingGallery(false)} className="btn btn-secondary">
                  Hủy
                </button>
                <button type="submit" className="btn btn-primary">
                  Tạo phòng trưng bày
                </button>
              </div>
            </form>
          </div>
        </div>,
        document.body
      )}
    </div>
  );
}
