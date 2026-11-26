import React, { useState, useEffect, useRef } from 'react';
import ActionGroup from '../common/ActionGroup';
import { createPortal } from 'react-dom';
import { alertAppDialog } from '../common/appDialogs';
import { useApp } from '../../context/AppContext';
import { allPages } from '../../services/backend';
import {
  getIndoorMapsApi,
  getIndoorMapDraftApi,
  fetchIndoorMapImageBlob
} from '../../services/indoorMapApi';
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
  Tag,
  Send,
  Copy,
  ZoomIn,
  ZoomOut,
  Maximize2,
  Map as MapIcon
} from 'lucide-react';

export default function TourManager() {
  const { tours, addTour, updateTour, publishTour, submitTourVersion, createTourVersionDraft, updateTourVersionDraft, exhibitions, artifacts, currentMuseum } = useApp();
  const museumTours = tours.filter(item => item.museumId === currentMuseum?.id);
  const museumExhibitions = exhibitions.filter(item => item.museumId === currentMuseum?.id);
  const museumArtifacts = artifacts.filter(item => item.museumId === currentMuseum?.id);
  const [activeSection, setActiveSection] = useState('tours'); // 'tours' | 'exhibitions'
  const [isCreatingTour, setIsCreatingTour] = useState(false);
  const [editingTour, setEditingTour] = useState(null);

  // Topics for the current museum
  const [topicsList, setTopicsList] = useState([]);

  // Indoor Maps for visual preview
  const [indoorMaps, setIndoorMaps] = useState([]);
  const [selectedMapId, setSelectedMapId] = useState(null);
  const [indoorMapDraft, setIndoorMapDraft] = useState(null);
  const [indoorMapImageUrl, setIndoorMapImageUrl] = useState(null);
  const [mapLoading, setMapLoading] = useState(false);
  const [mapZoom, setMapZoom] = useState(1);
  const [mapPan, setMapPan] = useState({ x: 0, y: 0 });
  const [isPanning, setIsPanning] = useState(false);
  const panStartRef = useRef({ x: 0, y: 0, panX: 0, panY: 0 });

  const [tourForm, setTourForm] = useState({
    title: '',
    duration: '60 phút',
    selectedTopics: [],
    description: '',
    selectedArtifacts: []
  });

  // Load topics of current museum
  useEffect(() => {
    if (!currentMuseum?.id) return;
    let cancelled = false;
    allPages(`museums/${currentMuseum.id}/topics`)
      .then(data => {
        if (!cancelled && Array.isArray(data)) {
          setTopicsList(data);
        }
      })
      .catch(() => {});
    return () => { cancelled = true; };
  }, [currentMuseum?.id]);

  // Load list of indoor maps when modal opens
  useEffect(() => {
    if (!isCreatingTour || !currentMuseum?.id) return;
    let cancelled = false;
    setMapZoom(1);
    setMapPan({ x: 0, y: 0 });
    getIndoorMapsApi(currentMuseum.id)
      .then(res => {
        if (cancelled) return;
        const list = res?.data || res || [];
        setIndoorMaps(list);
        if (list.length > 0) {
          const activeMap = list.find(m => m.publishedAt) || list[0];
          setSelectedMapId(activeMap.id);
        } else {
          setSelectedMapId(null);
          setIndoorMapDraft(null);
          setIndoorMapImageUrl(null);
        }
      })
      .catch(() => {});
    return () => { cancelled = true; };
  }, [isCreatingTour, currentMuseum?.id]);

  // Load draft & image blob for selected indoor map
  useEffect(() => {
    if (!selectedMapId || !isCreatingTour) return;
    let cancelled = false;
    let blobUrl = null;
    setMapLoading(true);

    getIndoorMapDraftApi(selectedMapId)
      .then(async (res) => {
        if (cancelled) return;
        const draft = res?.data || res;
        setIndoorMapDraft(draft);
        if (draft?.imageKey) {
          try {
            blobUrl = await fetchIndoorMapImageBlob(selectedMapId, draft.imageKey);
            if (!cancelled) {
              setIndoorMapImageUrl(blobUrl);
            }
          } catch (_) {
            if (!cancelled) setIndoorMapImageUrl(null);
          }
        } else {
          if (!cancelled) setIndoorMapImageUrl(null);
        }
      })
      .catch(() => {
        if (!cancelled) {
          setIndoorMapDraft(null);
          setIndoorMapImageUrl(null);
        }
      })
      .finally(() => {
        if (!cancelled) setMapLoading(false);
      });

    return () => {
      cancelled = true;
      if (blobUrl) URL.revokeObjectURL(blobUrl);
    };
  }, [selectedMapId, isCreatingTour]);

  // Pan handlers for indoor map preview
  const handleMouseDown = (e) => {
    if (e.button !== 0) return;
    setIsPanning(true);
    panStartRef.current = { x: e.clientX, y: e.clientY, panX: mapPan.x, panY: mapPan.y };
  };

  const handleMouseMove = (e) => {
    if (!isPanning) return;
    const dx = e.clientX - panStartRef.current.x;
    const dy = e.clientY - panStartRef.current.y;
    setMapPan({ x: panStartRef.current.panX + dx, y: panStartRef.current.panY + dy });
  };

  const handleMouseUp = () => setIsPanning(false);

  const getArtifactTopicNames = (art) => {
    if (!art) return [];
    if (Array.isArray(art.topics) && art.topics.length > 0) {
      return art.topics.map(t => (typeof t === 'string' ? t : t?.name)).filter(Boolean);
    }
    if (art.category) {
      return art.category.split(',').map(s => s.trim()).filter(Boolean);
    }
    return [];
  };

  const getTourTopicNames = (tour) => {
    if (tour.theme) {
      return tour.theme.split(',').map(s => s.trim()).filter(Boolean);
    }
    const derived = new Set();
    (tour.artifacts || []).forEach(artId => {
      const art = museumArtifacts.find(a => a.id === artId);
      getArtifactTopicNames(art).forEach(name => derived.add(name));
    });
    return Array.from(derived);
  };

  const handleCreateTour = async (e) => {
    e.preventDefault();
    if (!tourForm.title) {
      alertAppDialog('Vui lòng nhập tên hành trình tham quan', { title: 'Thiếu thông tin' });
      return;
    }
    const data = {
      title: tourForm.title,
      duration: tourForm.duration,
      theme: (tourForm.selectedTopics || []).join(', '),
      isPaidGuide: false,
      price: 0,
      museumId: currentMuseum?.id,
      museumName: currentMuseum?.name,
      description: tourForm.description,
      stopsCount: tourForm.selectedArtifacts.length,
      artifacts: tourForm.selectedArtifacts
    };
    const draftVer = editingTour ? ((editingTour.versions || []).find(v => v.status === 'draft') || (editingTour.status === 'draft' && editingTour.versions?.[0] ? editingTour.versions[0] : null)) : null;
    let result;
    if (draftVer?.id) {
      result = await updateTourVersionDraft(draftVer.id, data);
    } else if (editingTour) {
      result = await updateTour({ ...data, id: editingTour.id, revision: editingTour.revision });
    } else {
      result = await addTour(data);
    }
    if (!result?.success) return;
    setIsCreatingTour(false);
    setEditingTour(null);
    setTourForm({
      title: '',
      duration: '60 phút',
      selectedTopics: [],
      description: '',
      selectedArtifacts: []
    });
  };

  const openTourEditor = (tour) => {
    setEditingTour(tour);
    setTourForm({
      title: tour.title,
      duration: tour.duration,
      selectedTopics: getTourTopicNames(tour),
      description: tour.description || '',
      selectedArtifacts: tour.artifacts || []
    });
    setIsCreatingTour(true);
  };

  const toggleTopicInTour = (topicName) => {
    setTourForm(prev => {
      const current = prev.selectedTopics || [];
      const exists = current.includes(topicName);
      const nextTopics = exists
        ? current.filter(name => name !== topicName)
        : [...current, topicName];
      return { ...prev, selectedTopics: nextTopics };
    });
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

  const imgW = indoorMapDraft?.imageWidth || 1000;
  const imgH = indoorMapDraft?.imageHeight || 700;

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
            onClick={() => {
              setEditingTour(null);
              setTourForm({
                title: '',
                duration: '60 phút',
                selectedTopics: [],
                description: '',
                selectedArtifacts: []
              });
              setIsCreatingTour(true);
            }}
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
            border: 'none',
            cursor: 'pointer',
            transition: 'all 0.2s',
            background: activeSection === 'tours' ? 'var(--color-burgundy-900)' : 'var(--color-paper-card)',
            color: activeSection === 'tours' ? '#FFF' : 'var(--color-charcoal-600)',
            boxShadow: activeSection === 'tours' ? 'var(--shadow-sm)' : 'none'
          }}
        >
          Tuyến Tham Quan ({museumTours.length})
        </button>
        <button
          type="button"
          onClick={() => setActiveSection('exhibitions')}
          style={{
            padding: '10px 20px',
            borderRadius: '8px',
            fontWeight: '600',
            fontSize: '0.875rem',
            border: 'none',
            cursor: 'pointer',
            transition: 'all 0.2s',
            background: activeSection === 'exhibitions' ? 'var(--color-burgundy-900)' : 'var(--color-paper-card)',
            color: activeSection === 'exhibitions' ? '#FFF' : 'var(--color-charcoal-600)',
            boxShadow: activeSection === 'exhibitions' ? 'var(--shadow-sm)' : 'none'
          }}
        >
          Triển Lãm Chuyên Đề ({museumExhibitions.length})
        </button>
      </div>

      {/* Tour List View */}
      {activeSection === 'tours' && (
        <div className="business-grid">
          {museumTours.map(tour => {
            const draftVersion = (tour.versions || []).find(v => v.status === 'draft') || (tour.status === 'draft' && tour.versions?.[0] ? tour.versions[0] : null);
            const hasSubmittedVersion = (tour.versions || []).some(v => v.status === 'submitted');
            return (
              <div key={tour.id} className="card business-card" style={{ display: 'flex', flexDirection: 'column' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '12px', gap: '8px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px', flexWrap: 'wrap' }}>
                    <Compass size={18} color="var(--color-burgundy-700)" />
                    <span style={{ fontSize: '0.75rem', fontWeight: '700', textTransform: 'uppercase', letterSpacing: '0.05em', color: 'var(--color-burgundy-700)' }}>
                      {getTourTopicNames(tour).join(' • ') || 'Tuyến tổng quát'}
                    </span>
                  </div>
                  {hasSubmittedVersion ? (
                    <span className="badge-status badge-gold">Chờ Giám tuyển duyệt</span>
                  ) : (
                    <span className={`badge-status ${tour.status === 'published' ? 'badge-published' : 'badge-draft'}`}>
                      {tour.status === 'published' ? 'Đã xuất bản' : 'Bản nháp'}
                    </span>
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
                      <span>Chưa có thống kê đánh giá</span>
                    </div>
                  </div>

                  <div style={{ borderTop: '1px solid var(--color-paper-border)', paddingTop: '12px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '10px' }}>
                    <span style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-500)' }}>
                      Bảo tàng: {tour.museumName}
                    </span>
                    <ActionGroup visible={1}>
                      <button type="button" className="btn btn-secondary btn-sm" onClick={() => openTourEditor(tour)}>
                        Chỉnh sửa
                      </button>
                      <button
                        type="button"
                        className="btn btn-secondary btn-sm"
                        style={{ display: 'inline-flex', alignItems: 'center', gap: '4px' }}
                        title="Tạo bản sao phiên bản mới (Draft) để chỉnh sửa"
                        onClick={() => createTourVersionDraft(tour.id, draftVersion?.id || tour.activeVersionId)}
                      >
                        <Copy size={12} /> Tạo bản nháp mới
                      </button>
                      {draftVersion && (
                        <button
                          type="button"
                          className="btn btn-primary btn-sm"
                          style={{ display: 'inline-flex', alignItems: 'center', gap: '4px' }}
                          onClick={() => submitTourVersion(draftVersion.id)}
                        >
                          <Send size={12} /> Gửi duyệt
                        </button>
                      )}
                      {tour.status !== "published" && !hasSubmittedVersion && (
                        <button type="button" className="btn btn-gold btn-sm" onClick={() => publishTour(tour)}>
                          Xuất bản hành trình
                        </button>
                      )}
                    </ActionGroup>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Exhibition List View */}
      {activeSection === 'exhibitions' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          <p>Máy chủ chưa cung cấp danh sách triển lãm chuyên đề.</p>
          {museumExhibitions.map(exh => (
            <div key={exh.id} className="card" style={{ padding: '24px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div>
                  <h3 style={{ fontSize: '1.25rem', fontWeight: '700', color: 'var(--color-burgundy-900)' }}>
                    {exh.title}
                  </h3>
                  <div style={{ display: 'flex', gap: '16px', marginTop: '8px', fontSize: '0.875rem', color: 'var(--color-charcoal-600)' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                      <Calendar size={16} />
                      <span>{exh.startDate} - {exh.endDate}</span>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                      <MapPin size={16} />
                      <span>{exh.location}</span>
                    </div>
                  </div>
                  <p style={{ marginTop: '12px', fontSize: '0.875rem', color: 'var(--color-charcoal-700)' }}>
                    {exh.description}
                  </p>
                </div>
                <span className={`badge-status ${exh.status === 'active' ? 'badge-published' : 'badge-draft'}`}>
                  {exh.status === 'active' ? 'Đang Diễn Ra' : 'Sắp Diễn Ra'}
                </span>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Create / Edit Tour Modal (Split View: Form Left, Indoor Map Right) */}
      {isCreatingTour && typeof document !== 'undefined' && createPortal(
        <div className="modal-overlay" onClick={() => setIsCreatingTour(false)}>
          <div
            className="modal-dialog"
            style={{
              maxWidth: '1240px',
              width: '95vw',
              maxHeight: 'calc(100vh - 40px)',
              display: 'flex',
              flexDirection: 'column',
              minHeight: 0
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div className="modal-header">
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <Compass size={20} color="var(--color-burgundy-700)" />
                <h3 className="modal-title font-serif">
                  {editingTour ? 'Chỉnh sửa tuyến tham quan' : 'Tạo hành trình mới'}
                </h3>
              </div>
              <button aria-label="Đóng" type="button" onClick={() => setIsCreatingTour(false)} className="dialog-icon-close btn btn-secondary btn-sm">✕</button>
            </div>

            <form onSubmit={handleCreateTour} style={{ display: 'flex', flexDirection: 'column', flex: 1, minHeight: 0, overflow: 'hidden' }}>
              <div
                className="modal-body"
                style={{
                  display: 'grid',
                  gridTemplateColumns: 'minmax(380px, 460px) 1fr',
                  gap: '20px',
                  flex: 1,
                  minHeight: 0,
                  overflow: 'hidden',
                  padding: '16px'
                }}
              >
                {/* CỘT TRÁI: FORM NHẬP LIỆU */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: '14px', overflowY: 'auto', paddingRight: '6px' }}>
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
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                      <label className="form-label" style={{ marginBottom: 0 }}>
                        Chủ đề tham quan (có thể chọn nhiều):
                      </label>
                      {(tourForm.selectedTopics || []).length > 0 && (
                        <span style={{ fontSize: '0.75rem', fontWeight: '600', color: 'var(--color-burgundy-700)' }}>
                          Đã chọn {tourForm.selectedTopics.length} chủ đề
                        </span>
                      )}
                    </div>
                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px', padding: '8px 10px', border: '1px solid var(--color-paper-border)', borderRadius: '8px', background: '#FFF', maxHeight: '110px', overflowY: 'auto' }}>
                      {topicsList.length > 0 ? topicsList.map(t => {
                        const checked = (tourForm.selectedTopics || []).includes(t.name);
                        return (
                          <label
                            key={t.id}
                            style={{
                              display: 'inline-flex',
                              alignItems: 'center',
                              gap: '6px',
                              padding: '4px 10px',
                              borderRadius: '16px',
                              fontSize: '0.78rem',
                              fontWeight: checked ? '600' : '500',
                              cursor: 'pointer',
                              border: checked ? '1px solid var(--color-burgundy-700)' : '1px solid var(--color-paper-border)',
                              background: checked ? 'var(--color-paper-accent)' : '#FAF7F2',
                              color: checked ? 'var(--color-burgundy-900)' : 'var(--color-charcoal-700)',
                              transition: 'all 0.15s'
                            }}
                          >
                            <input
                              type="checkbox"
                              checked={checked}
                              onChange={() => toggleTopicInTour(t.name)}
                              style={{ margin: 0, cursor: 'pointer' }}
                            />
                            <span>{t.name}</span>
                          </label>
                        );
                      }) : (
                        <span style={{ fontSize: '0.78rem', color: 'var(--color-charcoal-500)' }}>
                          Bảo tàng chưa có chủ đề nào.
                        </span>
                      )}
                    </div>
                  </div>

                  {/* Select Artifact Stops */}
                  <div className="form-group" style={{ marginBottom: 0 }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                      <label className="form-label" style={{ marginBottom: 0 }}>
                        Chọn các hiện vật thuộc tuyến ({tourForm.selectedArtifacts.length} trạm):
                      </label>
                      {tourForm.selectedArtifacts.length > 0 && (
                        <button
                          type="button"
                          className="btn btn-secondary btn-sm"
                          style={{ padding: '2px 8px', fontSize: '0.75rem' }}
                          onClick={() => setTourForm(prev => ({ ...prev, selectedArtifacts: [] }))}
                        >
                          Bỏ chọn tất cả
                        </button>
                      )}
                    </div>
                    <div style={{ maxHeight: '190px', overflowY: 'auto', border: '1px solid var(--color-paper-border)', borderRadius: '8px', padding: '8px', background: '#FFF' }}>
                      {museumArtifacts.map(art => {
                        const isSelected = tourForm.selectedArtifacts.includes(art.id);
                        const stopOrder = tourForm.selectedArtifacts.indexOf(art.id);
                        const artTopics = getArtifactTopicNames(art);
                        const matchesSelectedTopic = (tourForm.selectedTopics || []).length > 0 && artTopics.some(t => tourForm.selectedTopics.includes(t));
                        return (
                          <label
                            key={art.id}
                            style={{
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'space-between',
                              gap: '8px',
                              padding: '6px 8px',
                              borderRadius: '6px',
                              cursor: 'pointer',
                              fontSize: '0.8125rem',
                              background: isSelected ? '#FEF3C7' : (matchesSelectedTopic ? 'rgba(197, 160, 89, 0.12)' : 'transparent'),
                              border: matchesSelectedTopic && !isSelected ? '1px dashed var(--color-gold-400)' : '1px solid transparent',
                              marginBottom: '3px'
                            }}
                          >
                            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', minWidth: 0, flex: 1 }}>
                              <input
                                type="checkbox"
                                checked={isSelected}
                                onChange={() => toggleArtifactInTour(art.id)}
                                style={{ flexShrink: 0 }}
                              />
                              {isSelected && (
                                <span style={{ background: '#F59E0B', color: '#FFF', borderRadius: '4px', padding: '1px 5px', fontSize: '0.7rem', fontWeight: 'bold', flexShrink: 0 }}>
                                  Trạm {stopOrder + 1}
                                </span>
                              )}
                              <span style={{ fontWeight: isSelected ? '600' : 'normal', color: 'var(--color-charcoal-800)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }} title={art.name}>
                                {art.name}
                              </span>
                            </div>

                            <div style={{ display: 'flex', alignItems: 'center', gap: '4px', flexWrap: 'wrap', justifyContent: 'flex-end', flexShrink: 0 }}>
                              {artTopics.length > 0 ? artTopics.map(topicName => (
                                <span
                                  key={topicName}
                                  style={{
                                    fontSize: '0.68rem',
                                    fontWeight: '600',
                                    padding: '1px 7px',
                                    borderRadius: '10px',
                                    background: (tourForm.selectedTopics || []).includes(topicName) ? 'var(--color-burgundy-700)' : '#F1ECE1',
                                    color: (tourForm.selectedTopics || []).includes(topicName) ? '#FFF' : 'var(--color-burgundy-800)',
                                    border: '1px solid var(--color-paper-border)',
                                    whiteSpace: 'nowrap'
                                  }}
                                >
                                  {topicName}
                                </span>
                              )) : (
                                <span style={{ fontSize: '0.68rem', color: 'var(--color-charcoal-400)', fontStyle: 'italic' }}>
                                  Chưa gán chủ đề
                                </span>
                              )}
                            </div>
                          </label>
                        );
                      })}
                      {museumArtifacts.length === 0 && (
                        <p style={{ fontSize: '0.8125rem', color: 'var(--color-charcoal-500)', padding: '8px', textAlign: 'center' }}>
                          Bảo tàng chưa có hiện vật nào.
                        </p>
                      )}
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

                {/* CỘT PHẢI: SƠ ĐỒ MẶT BẰNG BẢO TÀNG */}
                <div style={{ display: 'flex', flexDirection: 'column', background: '#F8F5EE', borderRadius: '8px', border: '1px solid var(--color-paper-border)', padding: '12px', minHeight: 0, overflow: 'hidden' }}>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '10px', gap: '10px', flexWrap: 'wrap' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <MapIcon size={16} color="var(--color-burgundy-700)" />
                      <strong style={{ fontSize: '0.875rem', color: 'var(--color-burgundy-900)' }}>
                        Sơ đồ mặt bằng bảo tàng
                      </strong>
                    </div>

                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      {indoorMaps.length > 1 && (
                        <select
                          className="form-select"
                          style={{ width: 'auto', padding: '4px 8px', fontSize: '0.8125rem' }}
                          value={selectedMapId || ''}
                          onChange={(e) => setSelectedMapId(Number(e.target.value))}
                        >
                          {indoorMaps.map(m => (
                            <option key={m.id} value={m.id}>
                              {m.name} {m.publishedAt ? '(Đã xuất bản)' : ''}
                            </option>
                          ))}
                        </select>
                      )}

                      <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                        <button
                          type="button"
                          className="btn btn-secondary btn-sm"
                          style={{ padding: '4px 8px' }}
                          title="Phóng to"
                          onClick={() => setMapZoom(z => Math.min(3, +(z + 0.25).toFixed(2)))}
                        >
                          <ZoomIn size={14} />
                        </button>
                        <button
                          type="button"
                          className="btn btn-secondary btn-sm"
                          style={{ padding: '4px 8px' }}
                          title="Thu nhỏ"
                          onClick={() => setMapZoom(z => Math.max(0.4, +(z - 0.25).toFixed(2)))}
                        >
                          <ZoomOut size={14} />
                        </button>
                        <button
                          type="button"
                          className="btn btn-secondary btn-sm"
                          style={{ padding: '4px 8px' }}
                          title="Vừa khung"
                          onClick={() => { setMapZoom(1); setMapPan({ x: 0, y: 0 }); }}
                        >
                          <Maximize2 size={14} />
                        </button>
                        <span style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-600)', minWidth: '38px', textAlign: 'right' }}>
                          {Math.round(mapZoom * 100)}%
                        </span>
                      </div>
                    </div>
                  </div>

                  {/* SVG Canvas Area */}
                  <div
                    style={{
                      flex: 1,
                      position: 'relative',
                      overflow: 'hidden',
                      borderRadius: '6px',
                      background: '#FFFFFF',
                      border: '1px solid var(--color-paper-border)',
                      cursor: isPanning ? 'grabbing' : 'grab',
                      userSelect: 'none'
                    }}
                    onMouseDown={handleMouseDown}
                    onMouseMove={handleMouseMove}
                    onMouseUp={handleMouseUp}
                    onMouseLeave={handleMouseUp}
                  >
                    {mapLoading ? (
                      <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--color-charcoal-500)', fontSize: '0.875rem' }}>
                        Đang tải sơ đồ mặt bằng…
                      </div>
                    ) : !indoorMapDraft ? (
                      <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', color: 'var(--color-charcoal-500)', padding: '20px', textAlign: 'center' }}>
                        <MapIcon size={36} color="var(--color-charcoal-400)" style={{ marginBottom: '8px' }} />
                        <p style={{ fontSize: '0.875rem', margin: 0 }}>Bảo tàng này chưa có sơ đồ mặt bằng.</p>
                        <small style={{ color: 'var(--color-charcoal-400)', marginTop: '4px' }}>Hãy thiết lập sơ đồ tại mục "Sơ đồ trưng bày".</small>
                      </div>
                    ) : (
                      <svg
                        width={imgW}
                        height={imgH}
                        viewBox={`0 0 ${imgW} ${imgH}`}
                        style={{
                          transform: `translate(${mapPan.x}px, ${mapPan.y}px) scale(${mapZoom})`,
                          transformOrigin: '0 0',
                          position: 'absolute',
                          top: 0,
                          left: 0
                        }}
                      >
                        {/* 1. Ảnh mặt bằng */}
                        {indoorMapImageUrl && (
                          <image
                            href={indoorMapImageUrl}
                            x={0}
                            y={0}
                            width={imgW}
                            height={imgH}
                            style={{ pointerEvents: 'none' }}
                          />
                        )}

                        {/* 2. Cạnh nối hành lang (Edges) */}
                        {indoorMapDraft.edges?.map((edge, idx) => {
                          const fromNode = (indoorMapDraft.nodes || []).find(n => n.id === edge.fromNodeId);
                          const toNode = (indoorMapDraft.nodes || []).find(n => n.id === edge.toNodeId);
                          if (!fromNode || !toNode) return null;
                          const x1 = fromNode.x * imgW;
                          const y1 = fromNode.y * imgH;
                          const x2 = toNode.x * imgW;
                          const y2 = toNode.y * imgH;
                          return (
                            <line
                              key={edge.id || idx}
                              x1={x1}
                              y1={y1}
                              x2={x2}
                              y2={y2}
                              stroke="#800020"
                              strokeWidth={2.5 / mapZoom}
                              opacity={0.65}
                              strokeDasharray={edge.isAccessible ? 'none' : `${4 / mapZoom},${4 / mapZoom}`}
                            />
                          );
                        })}

                        {/* 3. Đường nối tuyến tham quan giữa các trạm dừng được chọn (Waypoint Polyline) */}
                        {(() => {
                          const selectedPins = tourForm.selectedArtifacts
                            .map(artId => (indoorMapDraft.markers || []).find(m => m.artifactId === artId))
                            .filter(Boolean);
                          if (selectedPins.length < 2) return null;
                          const points = selectedPins.map(p => `${p.x * imgW},${p.y * imgH}`).join(' ');
                          return (
                            <polyline
                              points={points}
                              fill="none"
                              stroke="#F59E0B"
                              strokeWidth={3.5 / mapZoom}
                              strokeDasharray={`${6 / mapZoom},${4 / mapZoom}`}
                              strokeLinecap="round"
                              strokeLinejoin="round"
                              opacity={0.9}
                            />
                          );
                        })()}

                        {/* 4. Nút dẫn đường (Nodes) */}
                        {indoorMapDraft.nodes?.map(node => {
                          const cx = node.x * imgW;
                          const cy = node.y * imgH;
                          return (
                            <g key={node.id}>
                              <circle
                                cx={cx}
                                cy={cy}
                                r={6 / mapZoom}
                                fill="#800020"
                                stroke="#FFF"
                                strokeWidth={1.5 / mapZoom}
                              />
                              <text
                                x={cx}
                                y={cy - 9 / mapZoom}
                                textAnchor="middle"
                                fontSize={10 / mapZoom}
                                fontWeight="600"
                                fill="#1E232B"
                                stroke="#FFF"
                                strokeWidth={2 / mapZoom}
                                paintOrder="stroke"
                              >
                                {node.label}
                              </text>
                            </g>
                          );
                        })}

                        {/* 5. Điểm ghim (Markers: hiện vật, phòng, tiện ích) */}
                        {indoorMapDraft.markers?.map(marker => {
                          const mx = marker.x * imgW;
                          const my = marker.y * imgH;
                          const isSelected = tourForm.selectedArtifacts.includes(marker.artifactId);
                          const stopIndex = tourForm.selectedArtifacts.indexOf(marker.artifactId);
                          const targetNode = marker.nodeId ? (indoorMapDraft.nodes || []).find(n => n.id === marker.nodeId) : null;

                          return (
                            <g
                              key={marker.id}
                              style={{ cursor: marker.artifactId ? 'pointer' : 'default' }}
                              onClick={(e) => {
                                e.stopPropagation();
                                if (marker.artifactId) toggleArtifactInTour(marker.artifactId);
                              }}
                            >
                              {/* Đường dóng nối tới node hành lang */}
                              {targetNode && (
                                <line
                                  x1={mx}
                                  y1={my}
                                  x2={targetNode.x * imgW}
                                  y2={targetNode.y * imgH}
                                  stroke="#C5A059"
                                  strokeWidth={1.5 / mapZoom}
                                  strokeDasharray={`${3 / mapZoom},${3 / mapZoom}`}
                                  opacity={0.7}
                                />
                              )}

                              {/* Vòng tròn ghim */}
                              <circle
                                cx={mx}
                                cy={my}
                                r={isSelected ? 13 / mapZoom : 8 / mapZoom}
                                fill={isSelected ? '#F59E0B' : marker.type === 'artifact' ? '#873C32' : '#2563EB'}
                                stroke="#FFF"
                                strokeWidth={isSelected ? 3 / mapZoom : 2 / mapZoom}
                              />

                              {/* Hiển thị số thứ tự trạm dừng nếu được chọn */}
                              {isSelected ? (
                                <text
                                  x={mx}
                                  y={my + 4 / mapZoom}
                                  textAnchor="middle"
                                  fontSize={11 / mapZoom}
                                  fontWeight="bold"
                                  fill="#FFF"
                                >
                                  {stopIndex + 1}
                                </text>
                              ) : (
                                <circle cx={mx} cy={my} r={2.5 / mapZoom} fill="#FFF" />
                              )}

                              {/* Nhãn tên hiện vật */}
                              <text
                                x={mx}
                                y={my + (isSelected ? 22 / mapZoom : 16 / mapZoom)}
                                textAnchor="middle"
                                fontSize={10.5 / mapZoom}
                                fontWeight={isSelected ? 'bold' : '600'}
                                fill={isSelected ? '#B45309' : marker.type === 'artifact' ? '#800020' : '#1E40AF'}
                                stroke="#FFF"
                                strokeWidth={2.5 / mapZoom}
                                paintOrder="stroke"
                              >
                                {isSelected ? `[Trạm ${stopIndex + 1}] ${marker.label}` : marker.label}
                              </text>
                            </g>
                          );
                        })}
                      </svg>
                    )}
                  </div>

                  {/* Chú giải sơ đồ (Legend) */}
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: '14px', alignItems: 'center', marginTop: '8px', fontSize: '0.75rem', color: 'var(--color-charcoal-600)' }}>
                    <span style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
                      <span style={{ width: '10px', height: '10px', borderRadius: '50%', background: '#873C32', display: 'inline-block' }} />
                      Hiện vật
                    </span>
                    <span style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
                      <span style={{ width: '12px', height: '12px', borderRadius: '50%', background: '#F59E0B', border: '2px solid #B45309', display: 'inline-block' }} />
                      Trạm dừng được chọn
                    </span>
                    <span style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
                      <span style={{ width: '16px', height: '0', borderTop: '2px dashed #F59E0B', display: 'inline-block' }} />
                      Tuyến lộ trình
                    </span>
                    <span style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
                      <span style={{ width: '8px', height: '8px', borderRadius: '50%', background: '#800020', display: 'inline-block' }} />
                      Nút hành lang
                    </span>
                    <span style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
                      <span style={{ width: '16px', height: '0', borderTop: '1.5px solid #800020', display: 'inline-block' }} />
                      Cạnh lối đi
                    </span>
                    <span style={{ marginLeft: 'auto', fontStyle: 'italic', color: 'var(--color-charcoal-400)' }}>
                      Bấm ghim trên sơ đồ để chọn trạm
                    </span>
                  </div>
                </div>
              </div>

              <div className="modal-footer" style={{ flexShrink: 0 }}>
                <button type="button" onClick={() => setIsCreatingTour(false)} className="btn btn-secondary">Hủy</button>
                <button type="submit" className="btn btn-primary">{editingTour ? 'Lưu thay đổi' : 'Tạo hành trình'}</button>
              </div>
            </form>
          </div>
        </div>,
        document.body
      )}
    </div>
  );
}
