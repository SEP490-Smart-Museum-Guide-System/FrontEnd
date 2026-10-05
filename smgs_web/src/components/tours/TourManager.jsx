import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import {
  Compass,
  Calendar,
  Clock,
  MapPin,
  Plus,
  Star,
  Layers,
  Award,
  CheckCircle,
  Eye,
  Tag
} from 'lucide-react';

export default function TourManager() {
  const { tours, addTour, updateTour, exhibitions, artifacts, currentMuseum } = useApp();
  const museumTours = tours.filter(item => item.museumId === currentMuseum.id);
  const museumExhibitions = exhibitions.filter(item => item.museumId === currentMuseum.id);
  const museumArtifacts = artifacts.filter(item => item.museumId === currentMuseum.id);
  const [activeSection, setActiveSection] = useState('tours'); // 'tours' | 'exhibitions'
  const [isCreatingTour, setIsCreatingTour] = useState(false);
  const [editingTour, setEditingTour] = useState(null);

  const [tourForm, setTourForm] = useState({
    title: '',
    duration: '60 phút',
    theme: 'Bảo vật & Lịch sử',
    isPaidGuide: false,
    price: 0,
    description: '',
    selectedArtifacts: []
  });

  const handleCreateTour = (e) => {
    e.preventDefault();
    if (!tourForm.title) {
      alert('Vui lòng nhập tên hành trình tham quan');
      return;
    }
    const data = {
      title: tourForm.title,
      duration: tourForm.duration,
      theme: tourForm.theme,
      isPaidGuide: tourForm.isPaidGuide,
      price: tourForm.isPaidGuide ? Number(tourForm.price) : 0,
      museumId: currentMuseum.id,
      museumName: currentMuseum.name,
      description: tourForm.description,
      stopsCount: tourForm.selectedArtifacts.length || 4,
      artifacts: tourForm.selectedArtifacts
    };
    if (editingTour) updateTour({ ...data, id: editingTour.id });
    else addTour(data);
    setIsCreatingTour(false);
    setEditingTour(null);
    setTourForm({
      title: '',
      duration: '60 phút',
      theme: 'Bảo vật & Lịch sử',
      isPaidGuide: false,
      price: 0,
      description: '',
      selectedArtifacts: []
    });
  };

  const openTourEditor = (tour) => {
    setEditingTour(tour);
    setTourForm({ title: tour.title, duration: tour.duration, theme: tour.theme, isPaidGuide: tour.isPaidGuide, price: tour.price || 0, description: tour.description || '', selectedArtifacts: tour.artifacts || [] });
    setIsCreatingTour(true);
  };

  const toggleArtifactInTour = (artId) => {
    setTourForm(prev => {
      const exists = prev.selectedArtifacts.includes(artId);
      if (exists) {
        return { ...prev, selectedArtifacts: prev.selectedArtifacts.filter(id => id !== artId) };
      } else {
        return { ...prev, selectedArtifacts: [...prev.selectedArtifacts, artId] };
      }
    });
  };

  return (
    <div>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '24px', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <h2 style={{ fontSize: '1.625rem', fontWeight: '700', color: 'var(--color-burgundy-900)' }} className="font-serif">
            Quản Lý Hành Trình & Triển Lãm Chuyên Đề
          </h2>
          <p style={{ fontSize: '0.875rem', color: 'var(--color-charcoal-500)', marginTop: '4px' }}>
            Thiết kế các lộ trình tham quan mẫu có thuyết minh tự động và quản lý lịch sự kiện trưng bày chuyên đề
          </p>
        </div>

        <div style={{ display: 'flex', gap: '12px' }}>
          <button
            type="button"
            onClick={() => { setEditingTour(null); setTourForm({ title: '', duration: '60 phút', theme: 'Bảo vật & Lịch sử', isPaidGuide: false, price: 0, description: '', selectedArtifacts: [] }); setIsCreatingTour(true); }}
            className="btn btn-primary"
          >
            <Plus size={16} /> Tạo Hành Trình Mới
          </button>
        </div>
      </div>

      {/* Tabs Switcher */}
      <div style={{ display: 'flex', gap: '12px', marginBottom: '24px' }}>
        <button
          type="button"
          onClick={() => setActiveSection('tours')}
          style={{
            padding: '10px 20px',
            borderRadius: '8px',
            fontWeight: '600',
            fontSize: '0.875rem',
            background: activeSection === 'tours' ? 'var(--color-burgundy-700)' : '#FFFFFF',
            color: activeSection === 'tours' ? '#FFFFFF' : 'var(--color-charcoal-700)',
            border: activeSection === 'tours' ? '1px solid var(--color-burgundy-800)' : '1px solid var(--color-paper-border)',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            transition: 'all var(--transition-fast)'
          }}
        >
          <Compass size={16} /> Hành Trình Tham Quan ({museumTours.length})
        </button>

        <button
          type="button"
          onClick={() => setActiveSection('exhibitions')}
          style={{
            padding: '10px 20px',
            borderRadius: '8px',
            fontWeight: '600',
            fontSize: '0.875rem',
            background: activeSection === 'exhibitions' ? 'var(--color-burgundy-700)' : '#FFFFFF',
            color: activeSection === 'exhibitions' ? '#FFFFFF' : 'var(--color-charcoal-700)',
            border: activeSection === 'exhibitions' ? '1px solid var(--color-burgundy-800)' : '1px solid var(--color-paper-border)',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            transition: 'all var(--transition-fast)'
          }}
        >
          <Calendar size={16} /> Triển Lãm Chuyên Đề ({museumExhibitions.length})
        </button>
      </div>

      {/* Tour List View */}
      {activeSection === 'tours' && (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(360px, 1fr))', gap: '24px' }}>
          {museumTours.map(tour => (
            <div key={tour.id} className="card" style={{ display: 'flex', flexDirection: 'column' }}>
              <div className="card-header" style={{ background: '#FAF7F2' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <Compass size={18} color="var(--color-burgundy-700)" />
                  <span style={{ fontSize: '0.75rem', fontWeight: '700', color: 'var(--color-charcoal-500)', fontFamily: 'monospace' }}>
                    {tour.code}
                  </span>
                </div>
                {tour.isPaidGuide ? (
                  <span className="badge-status badge-treasure">
                    Nội dung nâng cao: {(tour.price || 0).toLocaleString('vi-VN')} đ
                  </span>
                ) : (
                  <span className="badge-status badge-published">Miễn phí</span>
                )}
              </div>

              <div className="card-body" style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
                <h3 style={{ fontSize: '1.125rem', fontWeight: '700', marginBottom: '8px', color: 'var(--color-charcoal-900)' }}>
                  {tour.title}
                </h3>

                <p style={{ fontSize: '0.8125rem', color: 'var(--color-charcoal-600)', lineHeight: '1.6', marginBottom: '16px', flex: 1 }}>
                  {tour.description}
                </p>

                <div style={{ display: 'flex', flexWrap: 'wrap', gap: '14px', fontSize: '0.8125rem', color: 'var(--color-charcoal-700)', background: '#F8F5EE', padding: '12px', borderRadius: '8px', marginBottom: '16px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                    <Clock size={14} color="var(--color-burgundy-700)" />
                    <span>{tour.duration}</span>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                    <Layers size={14} color="var(--color-burgundy-700)" />
                    <span>{tour.stopsCount} Trạm dừng</span>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                    <Star size={14} color="#EAB308" fill="#EAB308" />
                    <span>{tour.rating} ({tour.reviewsCount} đánh giá)</span>
                  </div>
                </div>

                <div style={{ borderTop: '1px solid var(--color-paper-border)', paddingTop: '12px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-500)' }}>
                    Bảo tàng: {tour.museumName}
                  </span>
                  <button type="button" className="btn btn-secondary btn-sm" onClick={() => openTourEditor(tour)}>Chỉnh sửa tour</button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Exhibition List View */}
      {activeSection === 'exhibitions' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          {museumExhibitions.map(exh => (
            <div key={exh.id} className="card" style={{ padding: '24px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '12px', flexWrap: 'wrap', gap: '12px' }}>
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <h3 style={{ fontSize: '1.25rem', fontWeight: '700', color: 'var(--color-burgundy-900)' }} className="font-serif">
                      {exh.title}
                    </h3>
                    <span className={`badge-status badge-${exh.status === 'active' ? 'active' : 'upcoming'}`}>
                      {exh.status === 'active' ? 'Đang diễn ra' : 'Sắp diễn ra'}
                    </span>
                  </div>
                  <p style={{ fontSize: '0.8125rem', color: 'var(--color-charcoal-500)', marginTop: '4px' }}>
                    Chủ trì giám tuyển: <strong>{exh.curatorName}</strong> • {exh.artifactsCount} hiện vật tham gia
                  </p>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', background: 'var(--color-paper-accent)', padding: '6px 14px', borderRadius: '8px', fontSize: '0.8125rem', fontWeight: '600' }}>
                  <Calendar size={15} color="var(--color-burgundy-700)" />
                  <span>{exh.startDate} ➔ {exh.endDate}</span>
                </div>
              </div>

              <p style={{ fontSize: '0.875rem', color: 'var(--color-charcoal-700)', lineHeight: '1.6', marginBottom: '14px' }}>
                {exh.description}
              </p>

              <div style={{ fontSize: '0.8125rem', color: 'var(--color-charcoal-600)', display: 'flex', alignItems: 'center', gap: '6px' }}>
                <MapPin size={14} color="var(--color-burgundy-700)" />
                <span>Không gian trưng bày: <strong>{exh.location}</strong></span>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Create Tour Modal */}
      {isCreatingTour && (
        <div className="modal-overlay" onClick={() => setIsCreatingTour(false)}>
          <div className="modal-dialog" style={{ maxWidth: '700px' }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3 className="modal-title font-serif">{editingTour ? 'Chỉnh sửa tour' : 'Tạo hành trình mới'}</h3>
              <button type="button" onClick={() => setIsCreatingTour(false)} className="btn btn-secondary btn-sm">✕</button>
            </div>
            <form onSubmit={handleCreateTour}>
              <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                <div className="form-group" style={{ marginBottom: 0 }}>
                  <label className="form-label">Tên hành trình *</label>
                  <input
                    type="text"
                    className="form-input"
                    value={tourForm.title}
                    onChange={(e) => setTourForm(prev => ({ ...prev, title: e.target.value }))}
                    placeholder="Ví dụ: Hành trình Di sản Đông Sơn & Triều Lý"
                    required
                  />
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">Thời lượng ước tính</label>
                    <input
                      type="text"
                      className="form-input"
                      value={tourForm.duration}
                      onChange={(e) => setTourForm(prev => ({ ...prev, duration: e.target.value }))}
                      placeholder="45 phút"
                    />
                  </div>
                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <label className="form-label">Chủ đề</label>
                    <input
                      type="text"
                      className="form-input"
                      value={tourForm.theme}
                      onChange={(e) => setTourForm(prev => ({ ...prev, theme: e.target.value }))}
                      placeholder="Đông Sơn"
                    />
                  </div>
                </div>

                {/* Paid guide toggle */}
                <div style={{ background: '#FAF7F2', padding: '12px 16px', borderRadius: '8px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <label style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '0.875rem', cursor: 'pointer', fontWeight: '600' }}>
                    <input
                      type="checkbox"
                      checked={tourForm.isPaidGuide}
                      onChange={(e) => setTourForm(prev => ({ ...prev, isPaidGuide: e.target.checked }))}
                    />
                    <span>Nội dung nâng cao cần gói trả phí</span>
                  </label>
                  {tourForm.isPaidGuide && (
                    <input
                      type="number"
                      className="form-input"
                      style={{ width: '130px', padding: '6px 10px' }}
                      value={tourForm.price}
                      onChange={(e) => setTourForm(prev => ({ ...prev, price: e.target.value }))}
                      placeholder="Giá (VNĐ)"
                    />
                  )}
                </div>

                {/* Select Artifact Stops */}
                <div className="form-group" style={{ marginBottom: 0 }}>
                  <label className="form-label">Chọn các hiện vật thuộc lộ trình tour:</label>
                  <div style={{ maxHeight: '160px', overflowY: 'auto', border: '1px solid var(--color-paper-border)', borderRadius: '8px', padding: '8px' }}>
                    {museumArtifacts.map(art => (
                      <label key={art.id} style={{ display: 'flex', alignItems: 'center', gap: '8px', padding: '6px', cursor: 'pointer', fontSize: '0.8125rem' }}>
                        <input
                          type="checkbox"
                          checked={tourForm.selectedArtifacts.includes(art.id)}
                          onChange={() => toggleArtifactInTour(art.id)}
                        />
                        <span>{art.name} ({art.galleryName})</span>
                      </label>
                    ))}
                  </div>
                </div>

                {/* Description */}
                <div className="form-group" style={{ marginBottom: 0 }}>
                  <label className="form-label">Mô tả lộ trình</label>
                  <textarea
                    className="form-textarea"
                    rows={3}
                    value={tourForm.description}
                    onChange={(e) => setTourForm(prev => ({ ...prev, description: e.target.value }))}
                    placeholder="Mô tả ý nghĩa và điểm nhấn của tour này..."
                  />
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" onClick={() => setIsCreatingTour(false)} className="btn btn-secondary">Hủy</button>
                <button type="submit" className="btn btn-primary">{editingTour ? 'Lưu thay đổi' : 'Tạo hành trình'}</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
