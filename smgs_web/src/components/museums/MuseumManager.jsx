import { backend } from '../../services/backend';
import MediaUpload from '../common/MediaUpload';
import { mediaApi } from '../../services/mediaApi';
import React, { useState, useEffect, useRef } from 'react';
import MuseumCoverPicker from './MuseumCoverPicker';
import MuseumCityPicker from './MuseumCityPicker';
import OpeningHoursPicker from './OpeningHoursPicker';
import { createPortal } from 'react-dom';
import { useApp } from '../../context/AppContext';
import {
  Landmark,
  ExternalLink,
  Navigation,
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
import MuseumStaffAssignModal from './MuseumStaffAssignModal';
import { ShieldCheck } from 'lucide-react';

export default function MuseumManager() {
  const {
    museums,
    setActiveTab, setSelectedMuseumId: selectMuseum,
    setMuseums,
    artifacts,
    showToast,
    logAction,
    currentRole,
    currentMuseum,
    toggleMuseumGoogleMapsVisibility,
    createMuseum,
    updateMuseum,
    deleteMuseum
  } = useApp();

  const [selectedMuseumId, setSelectedMuseumId] = useState(museums[0]?.id || null);
  const [isEditingMuseum, setIsEditingMuseum] = useState(false);
  const [isAddingMuseum, setIsAddingMuseum] = useState(false);
  const [isConfirmingDelete, setIsConfirmingDelete] = useState(false);
  const [isAssigningStaff, setIsAssigningStaff] = useState(false);
  const [assignedStaff, setAssignedStaff] = useState([]);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const [newCoverFile, setNewCoverFile] = useState(null);
  const [editCoverFile, setEditCoverFile] = useState(null);
  const submitLock = useRef(false);
  const [museumForm, setMuseumForm] = useState({});
  const [newMuseumData, setNewMuseumData] = useState({
    name: '',
    cityCode: '',
    address: '',
    latitude: '',
    longitude: '',
    openingHours: '',
    coverImageUrl: '',
    description: ''
  });



  const activeMuseum = currentRole === 'museumStaff'
    ? currentMuseum
    : museums.find(m => m.id === selectedMuseumId) || museums[0];

  // Tải danh sách nhân viên phụ trách bảo tàng
  const loadAssignedStaff = async () => {
    if (!activeMuseum?.id) return;
    try {
      const data = await backend(`admin/assignments?museumId=${activeMuseum.id}`);
      setAssignedStaff(Array.isArray(data) ? data : []);
    } catch {
      setAssignedStaff([]);
    }
  };

  useEffect(() => {
    loadAssignedStaff();
  }, [activeMuseum?.id]);

  const [structure, setStructure] = useState({ id: null, buildings: [], loading: false, error: '' });
  useEffect(() => {
    const controller = new AbortController();
    if (!activeMuseum) return () => controller.abort();
    const id = activeMuseum.id;
    setStructure({ id, buildings: [], loading: true, error: '' });
    backend(`museums/${id}/indoor-structure`, { signal: controller.signal }).then(data => {
      if (controller.signal.aborted) return;
      const buildings = data.buildings.map(b => ({ ...b, floors: data.floors.filter(f => f.buildingId === b.id).map(f => ({ ...f, galleries: data.galleries.filter(g => g.floorId === f.id) })) }));
      setStructure({ id, buildings, loading: false, error: '' });
    }).catch(e => { if (!controller.signal.aborted) setStructure({ id, buildings: [], loading: false, error: e.message }); });
    return () => controller.abort();
  }, [activeMuseum?.id]);
  const buildings = structure.id === activeMuseum?.id ? structure.buildings : [];

  const handleOpenEditMuseum = () => {
    setEditCoverFile(null);
    setMuseumForm({
      name: activeMuseum?.name || '',
      cityCode: activeMuseum?.cityCode || '',
      address: activeMuseum?.address || '',
      latitude: activeMuseum?.latitude ?? '',
      longitude: activeMuseum?.longitude ?? '',
      openingHours: activeMuseum?.openingHours || '',
      image: activeMuseum?.image || activeMuseum?.coverImageUrl || '',
      description: activeMuseum?.description || ''
    });
    setIsEditingMuseum(true);
  };

  const saveMuseumInfo = async (event) => {
    event.preventDefault();
    if (submitLock.current) return;
    if (!/^(?!00)\d{2}$/.test(museumForm.cityCode || '')) { showToast('Hãy chọn tỉnh / thành phố hợp lệ.', 'warning'); return; }
    if (museumForm.latitude !== '' && museumForm.latitude !== null && museumForm.latitude !== undefined) {
      const lat = Number(museumForm.latitude);
      if (isNaN(lat) || lat < -90 || lat > 90) { showToast('Vĩ độ (Latitude) phải nằm trong khoảng từ -90 đến 90.', 'warning'); return; }
    }
    if (museumForm.longitude !== '' && museumForm.longitude !== null && museumForm.longitude !== undefined) {
      const lng = Number(museumForm.longitude);
      if (isNaN(lng) || lng < -180 || lng > 180) { showToast('Kinh độ (Longitude) phải nằm trong khoảng từ -180 đến 180.', 'warning'); return; }
    }
    submitLock.current = true;
    setIsSubmitting(true);
    try {
      const res = await updateMuseum(activeMuseum?.id, museumForm, editCoverFile);
      if (res?.success) {
        setIsEditingMuseum(false);
      }
    } finally {
      submitLock.current = false;
      setIsSubmitting(false);
    }
  };

  const handleCreateMuseum = async (e) => {
    e.preventDefault();
    if (submitLock.current) return;
    if (!/^(?!00)\d{2}$/.test(newMuseumData.cityCode || '')) { showToast('Hãy chọn tỉnh / thành phố hợp lệ.', 'warning'); return; }
    if (!newMuseumData.name.trim()) {
      showToast('Vui lòng nhập tên bảo tàng.', 'warning');
      return;
    }
    if (newMuseumData.latitude !== '' && newMuseumData.latitude !== null && newMuseumData.latitude !== undefined) {
      const lat = Number(newMuseumData.latitude);
      if (isNaN(lat) || lat < -90 || lat > 90) { showToast('Vĩ độ (Latitude) phải nằm trong khoảng từ -90 đến 90.', 'warning'); return; }
    }
    if (newMuseumData.longitude !== '' && newMuseumData.longitude !== null && newMuseumData.longitude !== undefined) {
      const lng = Number(newMuseumData.longitude);
      if (isNaN(lng) || lng < -180 || lng > 180) { showToast('Kinh độ (Longitude) phải nằm trong khoảng từ -180 đến 180.', 'warning'); return; }
    }
    submitLock.current = true;
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
      }, newCoverFile);

      if (res?.success) {
        if (res.data?.id) {
          setSelectedMuseumId(res.data.id);
        }
        setIsAddingMuseum(false);
        setNewCoverFile(null);
        setNewMuseumData({
          name: '',
          cityCode: '',
          address: '',
          latitude: '',
          longitude: '',
          openingHours: '',
          coverImageUrl: '',
          description: ''
        });
      }
    } finally {
      submitLock.current = false;
      setIsSubmitting(false);
    }
  };

  const handleConfirmDelete = async () => {
    setIsSubmitting(true);
    try {
      const res = await deleteMuseum(activeMuseum?.id);
      if (res?.success) {
        setIsConfirmingDelete(false);
      }
    } finally {
      setIsSubmitting(false);
    }
  };



  return (
    <div>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '24px', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <h2 style={{ fontSize: '1.625rem', fontWeight: '700', color: 'var(--color-burgundy-900)' }} className="font-serif">
            Quản lý bảo tàng
          </h2>
          <p style={{ fontSize: '0.875rem', color: 'var(--color-charcoal-500)', marginTop: '4px' }}>
            Quản lý thông tin cơ bản, trạng thái hoạt động và phân công nhân viên phụ trách bảo tàng.
          </p>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', flexWrap: 'wrap' }}>
          {currentRole === 'administrator' && (
            <button
              type="button"
              onClick={() => { setNewCoverFile(null); setIsAddingMuseum(true); }}
              className="btn btn-primary"
            >
              <Plus size={16} /> Thêm Bảo Tàng Mới
            </button>
          )}

          <button
            type="button"
            disabled={!activeMuseum}
            onClick={() => { selectMuseum(activeMuseum.id); setActiveTab('spaces'); }}
            className="btn btn-secondary"
            style={{ display: 'flex', alignItems: 'center', gap: '6px' }}
          >
            <FolderTree size={16} /> Cấu trúc bảo tàng
          </button>
        </div>
      </div>

      {/* Museum Selector Tab Strip */}
      {currentRole !== 'museumStaff' && (
        <div style={{ display: 'flex', gap: '12px', marginBottom: '24px', flexWrap: 'wrap' }}>
          {museums.map(m => {
            const isSelected = m.id === activeMuseum?.id;
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



      {!activeMuseum && <div className="card" style={{ padding: 24 }}>Chưa có bảo tàng để hiển thị. Hãy thêm bảo tàng hoặc thử tải lại dữ liệu.</div>}
      {activeMuseum && <>
      {/* Museum Information Banner */}
      <div className="card" style={{ padding: '24px', marginBottom: '28px', background: 'linear-gradient(135deg, var(--color-paper-card), var(--color-paper-bg))' }}>
        <div className="museum-intro-grid" style={{ display: 'grid', gridTemplateColumns: '220px minmax(0, 1fr)', gap: '24px', alignItems: 'center' }}>
          <div style={{ height: '140px', borderRadius: '10px', overflow: 'hidden', border: '1px solid var(--color-paper-border)' }}>
            {activeMuseum.image || activeMuseum.coverImageUrl ? <img
              src={activeMuseum.image || activeMuseum.coverImageUrl}
              alt={activeMuseum.name}
              style={{ width: '100%', height: '100%', objectFit: 'cover' }}
            /> : <div style={{ padding: 28 }}><Landmark size={32} /><p>Chưa có ảnh bảo tàng</p></div>}
          </div>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '6px', flexWrap: 'wrap' }}>
              <h3 style={{ fontSize: '1.25rem', fontWeight: '700', color: 'var(--color-burgundy-900)' }}>
                {activeMuseum?.name}
              </h3>
              {activeMuseum?.status === 'active' ? (
                <span className="badge-status badge-active">Đang hoạt động</span>
              ) : (
                <span className="badge-status" style={{ background: '#FEE2E2', color: '#991B1B' }}>Đã vô hiệu hóa</span>
              )}
              {activeMuseum?.backendId && (
                <span style={{ fontSize: '0.7rem', background: '#E2E8F0', padding: '2px 8px', borderRadius: '4px', color: '#475569', fontWeight: '600' }}>
                  Backend ID: #{activeMuseum?.backendId}
                </span>
              )}
            </div>
            <p style={{ fontSize: '0.8125rem', color: 'var(--color-charcoal-600)', marginBottom: '8px', display: 'flex', alignItems: 'center', gap: '6px', flexWrap: 'wrap' }}>
              <MapPin size={14} color="var(--color-burgundy-700)" /> {activeMuseum?.address}
              {activeMuseum?.address && (
                <a
                  href={`https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(activeMuseum.address)}`}
                  target="_blank"
                  rel="noreferrer"
                  style={{ fontSize: '0.75rem', color: 'var(--color-burgundy-700)', display: 'inline-flex', alignItems: 'center', gap: '4px', textDecoration: 'none', background: '#FDF2F2', padding: '2px 8px', borderRadius: '4px', fontWeight: '500' }}
                  title="Mở chỉ đường trên Google Maps"
                >
                  <Navigation size={12} /> Chỉ đường <ExternalLink size={11} />
                </a>
              )}
              {activeMuseum?.openingHours && (
                <span style={{ marginLeft: '12px', display: 'inline-flex', alignItems: 'center', gap: '4px' }}>
                  <Clock size={13} color="var(--color-gold-600)" /> {activeMuseum?.openingHours}
                </span>
              )}
            </p>
            <p style={{ fontSize: '0.8125rem', color: 'var(--color-charcoal-700)', lineHeight: '1.5' }}>
              {activeMuseum?.description}
            </p>

            {['administrator', 'museumStaff'].includes(currentRole) && Number(activeMuseum?.backendId || activeMuseum?.id) > 0 && <>
              <MediaUpload key={activeMuseum?.id} path={`museums/${activeMuseum?.backendId || activeMuseum?.id}/image`} label="Ảnh bảo tàng"
                onSaved={data => setMuseums(prev => prev.map(m => m.id === activeMuseum?.id ? { ...m, image: data.coverImageUrl, coverImageUrl: data.coverImageUrl } : m))} />
              <button type="button" disabled={isSubmitting} onClick={async () => {
                setIsSubmitting(true);
                try { await mediaApi(`museums/${activeMuseum?.backendId || activeMuseum?.id}/image`, { method: 'DELETE' });
                  setMuseums(prev => prev.map(m => m.id === activeMuseum?.id ? { ...m, image: '', coverImageUrl: '' } : m)); showToast('Đã gỡ ảnh bảo tàng.');
                } catch (e) { showToast(e.message, 'error'); } finally { setIsSubmitting(false); }
              }}>Gỡ ảnh bảo tàng</button>
            </>}
            {/* Hiển thị nhân viên phụ trách */}
            <div style={{ marginTop: '12px', padding: '10px 14px', background: 'rgba(255, 255, 255, 0.7)', borderRadius: '8px', border: '1px solid var(--color-paper-border)' }}>
              <div style={{ fontSize: '0.8125rem', fontWeight: '600', color: 'var(--color-charcoal-800)', marginBottom: '6px', display: 'flex', alignItems: 'center', gap: '6px' }}>
                <ShieldCheck size={16} color="var(--color-gold-600)" />
                Nhân viên phụ trách ({assignedStaff.length}):
              </div>
              {assignedStaff.length === 0 ? (
                <span style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-500)', fontStyle: 'italic' }}>
                  Chưa có nhân viên nào được phân công. Bấm "Phân công nhân viên" để gán.
                </span>
              ) : (
                <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }}>
                  {assignedStaff.map(a => (
                    <span
                      key={a.id}
                      style={{
                        fontSize: '0.75rem',
                        padding: '3px 8px',
                        borderRadius: '4px',
                        background: '#F1F5F9',
                        color: 'var(--color-charcoal-700)',
                        border: '1px solid #E2E8F0',
                        fontWeight: '500'
                      }}
                    >
                      👤 {a.userFullName || a.userEmail || `Staff #${a.userId?.substring(0, 6)}`}
                    </span>
                  ))}
                </div>
              )}
            </div>

            <div style={{ display: 'flex', gap: '10px', marginTop: '14px', flexWrap: 'wrap' }}>
              {(currentRole === 'museumStaff' || currentRole === 'administrator') && (
                <button
                  className="btn btn-secondary btn-sm"
                  type="button"
                  onClick={handleOpenEditMuseum}
                >
                  <Edit3 size={14} /> Chỉnh sửa thông tin
                </button>
              )}
              {currentRole === 'administrator' && (
                <button
                  className="btn btn-secondary btn-sm"
                  type="button"
                  onClick={() => setIsAssigningStaff(true)}
                  style={{ display: 'flex', alignItems: 'center', gap: '6px' }}
                >
                  <Users size={14} /> Phân công nhân viên
                </button>
              )}
              <button
                className="btn btn-secondary btn-sm"
                type="button"
                onClick={() => { selectMuseum(activeMuseum.id); setActiveTab('spaces'); }}
                style={{ display: 'flex', alignItems: 'center', gap: '6px' }}
              >
                <FolderTree size={14} /> Cấu trúc không gian &rarr;
              </button>
              {currentRole === 'administrator' && (
                <button
                  className="btn btn-sm"
                  type="button"
                  style={{
                    border: '1px solid #FCA5A5',
                    color: activeMuseum?.status === 'inactive' ? 'var(--color-charcoal-500)' : '#B91C1C',
                    background: activeMuseum?.status === 'inactive' ? '#F1F5F9' : '#FEF2F2',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px'
                  }}
                  onClick={() => setIsConfirmingDelete(true)}
                  disabled={activeMuseum?.status === 'inactive'}
                >
                  <Trash2 size={14} /> {activeMuseum?.status === 'inactive' ? 'Đã vô hiệu hóa' : 'Vô hiệu hóa bảo tàng'}
                </button>
              )}
            </div>
          </div>
        </div>
      </div>



      </>}

      {/* Edit Museum Modal */}
      {isEditingMuseum && typeof document !== 'undefined' && createPortal(
        <div className="modal-overlay" onClick={() => { if (!submitLock.current) setIsEditingMuseum(false); }}>
          <div className="modal-dialog" style={{ maxWidth: '640px', width: '95vw', maxHeight: 'calc(100vh - 40px)', display: 'flex', flexDirection: 'column', minHeight: 0 }} onClick={event => event.stopPropagation()}>
            <div className="modal-header">
              <h3 className="modal-title font-serif">Chỉnh Sửa Thông Tin Bảo Tàng</h3>
              <button type="button" className="btn btn-secondary btn-sm" onClick={() => { if (!submitLock.current) setIsEditingMuseum(false); }}>✕</button>
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

                <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '12px' }}>
                  <MuseumCityPicker value={museumForm.cityCode || ''} disabled={isSubmitting}
                    onChange={cityCode => setMuseumForm(prev => ({ ...prev, cityCode }))} />

                  <OpeningHoursPicker value={museumForm.openingHours || ''} disabled={isSubmitting}
                    onChange={openingHours => setMuseumForm(prev => ({ ...prev, openingHours }))} />
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
                      min="-90"
                      max="90"
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
                      min="-180"
                      max="180"
                      className="form-input"
                      value={museumForm.longitude ?? ''}
                      onChange={e => setMuseumForm(prev => ({ ...prev, longitude: e.target.value }))}
                      placeholder="105.8584"
                    />
                  </label>
                </div>

                <MuseumCoverPicker file={editCoverFile} currentUrl={museumForm.image || ''}
                  onChange={setEditCoverFile} disabled={isSubmitting} />

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
                <button type="button" className="btn btn-secondary" onClick={() => { if (!submitLock.current) setIsEditingMuseum(false); }} disabled={isSubmitting}>
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
        <div className="modal-overlay" onClick={() => { if (!submitLock.current) setIsAddingMuseum(false); }}>
          <div className="modal-dialog" style={{ maxWidth: '640px', width: '95vw', maxHeight: 'calc(100vh - 40px)', display: 'flex', flexDirection: 'column', minHeight: 0 }} onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <h3 className="modal-title font-serif">Thêm Bảo Tàng Mới Vào Hệ Thống</h3>
              <button type="button" className="btn btn-secondary btn-sm" onClick={() => { if (!submitLock.current) setIsAddingMuseum(false); }}>✕</button>
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

                <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '12px' }}>
                  <MuseumCityPicker value={newMuseumData.cityCode || ''} disabled={isSubmitting}
                    onChange={cityCode => setNewMuseumData(prev => ({ ...prev, cityCode }))} />

                  <OpeningHoursPicker value={newMuseumData.openingHours || ''} disabled={isSubmitting}
                    onChange={openingHours => setNewMuseumData(prev => ({ ...prev, openingHours }))} />
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
                      min="-90"
                      max="90"
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
                      min="-180"
                      max="180"
                      className="form-input"
                      value={newMuseumData.longitude}
                      onChange={e => setNewMuseumData(prev => ({ ...prev, longitude: e.target.value }))}
                      placeholder="105.8584"
                    />
                  </label>
                </div>

                <MuseumCoverPicker file={newCoverFile} onChange={setNewCoverFile} disabled={isSubmitting} />

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
                <button type="button" className="btn btn-secondary" onClick={() => { if (!submitLock.current) setIsAddingMuseum(false); }} disabled={isSubmitting}>
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

      {/* Modal Phân công nhân viên */}
      {isAssigningStaff && activeMuseum && (
        <MuseumStaffAssignModal
          museum={activeMuseum}
          onClose={() => setIsAssigningStaff(false)}
          onAssigned={loadAssignedStaff}
        />
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
                Bạn có chắc chắn muốn vô hiệu hóa bảo tàng <strong>{activeMuseum?.name}</strong> không?
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

    </div>
  );
}
