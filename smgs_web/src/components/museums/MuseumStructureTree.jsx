import React, { useState, useEffect } from 'react';
import { backend } from '../../services/backend';
import { useApp } from '../../context/AppContext';
import {
  Building2,
  FolderTree,
  DoorOpen,
  Plus,
  Edit3,
  Trash2,
  ChevronDown,
  ChevronRight,
  Layers,
  Map,
  Compass,
  AlertTriangle,
  Loader2,
  Landmark,
  PackageCheck
} from 'lucide-react';
import { createPortal } from 'react-dom';

export default function MuseumStructureTree() {
  const { currentMuseum, museums, currentRole, setActiveTab, setSelectedMuseumId, artifacts, showToast } = useApp();

  const [selectedMuseumId, setLocalMuseumId] = useState(currentMuseum?.id || museums[0]?.id || null);
  const activeMuseum = currentRole === 'museumStaff'
    ? currentMuseum
    : museums.find(m => m.id === selectedMuseumId) || currentMuseum || museums[0];

  const [structure, setStructure] = useState({ buildings: [], floors: [], galleries: [] });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  // Trạng thái đóng/mở từng tòa nhà (Set of building IDs)
  const [expandedBuildings, setExpandedBuildings] = useState(new Set());

  // Modal quản lý Thêm/Sửa: { type: 'building' | 'floor' | 'gallery', mode: 'add' | 'edit', data?: object, parentId?: number }
  const [modalState, setModalState] = useState(null);
  const [submitting, setSubmitting] = useState(false);

  // 1. Tải cấu trúc không gian (Tòa nhà, Tầng, Phòng) từ API
  const loadStructure = async () => {
    if (!activeMuseum?.id) return;
    setLoading(true);
    setError('');
    try {
      const data = await backend(`museums/${activeMuseum.id}/indoor-structure`);
      const blds = data.buildings || [];
      const flrs = data.floors || [];
      const gals = data.galleries || [];

      setStructure({ buildings: blds, floors: flrs, galleries: gals });

      // Mặc định mở rộng tất cả các tòa nhà
      setExpandedBuildings(new Set(blds.map(b => b.id)));
    } catch (err) {
      setError(err.message || 'Không thể tải cấu trúc bảo tàng.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadStructure();
  }, [activeMuseum?.id]);

  const toggleBuilding = (bldId) => {
    setExpandedBuildings(prev => {
      const next = new Set(prev);
      if (next.has(bldId)) next.delete(bldId);
      else next.add(bldId);
      return next;
    });
  };

  // 2. Xóa Tòa nhà (với quy tắc kiểm tra phụ thuộc theo Mục 10)
  const handleDeleteBuilding = async (building) => {
    const relatedFloors = structure.floors.filter(f => f.buildingId === building.id);
    if (relatedFloors.length > 0) {
      const confirmMsg = `Tòa nhà "${building.name}" hiện đang có ${relatedFloors.length} tầng và các phòng trưng bày trực thuộc.\n\nTheo quy tắc bảo toàn dữ liệu, bạn nên xử lý/chuyển các tầng và hiện vật trước khi xóa.\n\nBạn có chắc chắn muốn xóa tòa nhà này không?`;
      if (!window.confirm(confirmMsg)) return;
    } else {
      if (!window.confirm(`Bạn có chắc chắn muốn xóa tòa nhà "${building.name}"?`)) return;
    }

    try {
      await backend(`museums/${activeMuseum.id}/buildings/${building.id}`, { method: 'DELETE' });
      showToast(`Đã xóa tòa nhà "${building.name}".`, 'success');
      await loadStructure();
    } catch (err) {
      showToast(err.message || 'Không thể xóa tòa nhà.', 'error');
    }
  };

  // 3. Xóa Tầng (với quy tắc kiểm tra phòng & sơ đồ theo Mục 10)
  const handleDeleteFloor = async (floor) => {
    const relatedGalleries = structure.galleries.filter(g => g.floorId === floor.id);
    if (relatedGalleries.length > 0) {
      const confirmMsg = `Tầng "${floor.name || `Tầng ${floor.levelNo}`}" đang chứa ${relatedGalleries.length} phòng trưng bày.\n\nBạn cần xóa hoặc chuyển các phòng trưng bày trước để đảm bảo an toàn dữ liệu hiện vật.\n\nBạn có muốn tiếp tục thử xóa?`;
      if (!window.confirm(confirmMsg)) return;
    } else {
      if (!window.confirm(`Bạn có chắc chắn muốn xóa tầng "${floor.name || `Tầng ${floor.levelNo}`}"?`)) return;
    }

    try {
      await backend(`museums/${activeMuseum.id}/floors/${floor.id}`, { method: 'DELETE' });
      showToast(`Đã xóa tầng.`, 'success');
      await loadStructure();
    } catch (err) {
      showToast(err.message || 'Không thể xóa tầng.', 'error');
    }
  };

  // 4. Xóa Phòng trưng bày (với quy tắc kiểm tra hiện vật theo Mục 10)
  const handleDeleteGallery = async (gallery) => {
    const count = artifacts.filter(a => a.galleryId === gallery.id).length;
    if (count > 0) {
      const msg = `Phòng trưng bày "${gallery.name}" hiện đang chứa ${count} hiện vật.\n\nQuy tắc hệ thống: Vui lòng chuyển các hiện vật sang phòng khác hoặc bỏ gán phòng trước khi xóa phòng này để tránh làm mất liên kết dữ liệu.\n\nBạn có chắc chắn muốn xóa không?`;
      if (!window.confirm(msg)) return;
    } else {
      if (!window.confirm(`Bạn có chắc chắn muốn xóa phòng trưng bày "${gallery.name}"?`)) return;
    }

    try {
      await backend(`museums/${activeMuseum.id}/galleries/${gallery.id}`, { method: 'DELETE' });
      showToast(`Đã xóa phòng trưng bày "${gallery.name}".`, 'success');
      await loadStructure();
    } catch (err) {
      showToast(err.message || 'Không thể xóa phòng trưng bày.', 'error');
    }
  };

  // Chuyển nhanh sang bản đồ sơ đồ tầng
  const handleOpenMap = (floorId) => {
    if (activeMuseum?.id) {
      setSelectedMuseumId?.(activeMuseum.id);
      setActiveTab('indoor_maps');
    }
  };

  return (
    <div style={{ paddingBottom: '40px' }}>
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '16px', marginBottom: '24px' }}>
        <div>
          <h2 style={{ fontSize: '1.625rem', fontWeight: '700', color: 'var(--color-burgundy-900)' }} className="font-serif">
            Cấu Trúc Bảo Tàng
          </h2>
          <p style={{ fontSize: '0.875rem', color: 'var(--color-charcoal-500)', marginTop: '4px' }}>
            Quản lý hệ thống Tòa nhà, Tầng và Phòng trưng bày theo cây phân cấp.
          </p>
        </div>

        <div style={{ display: 'flex', gap: '12px', alignItems: 'center', flexWrap: 'wrap' }}>
          <button
            type="button"
            className="btn btn-primary"
            onClick={() => setModalState({ type: 'building', mode: 'add' })}
            style={{ display: 'flex', alignItems: 'center', gap: '8px' }}
          >
            <Plus size={16} /> Thêm Tòa Nhà Mới
          </button>
        </div>
      </div>

      {/* Bộ chọn bảo tàng nếu là Admin hoặc quản lý nhiều bảo tàng */}
      {currentRole === 'administrator' && museums.length > 1 && (
        <div style={{ display: 'flex', gap: '10px', marginBottom: '20px', flexWrap: 'wrap' }}>
          {museums.map(m => {
            const isSelected = m.id === activeMuseum?.id;
            return (
              <button
                key={m.id}
                type="button"
                onClick={() => setLocalMuseumId(m.id)}
                style={{
                  padding: '8px 16px',
                  borderRadius: '8px',
                  background: isSelected ? 'var(--color-burgundy-900)' : '#FFFFFF',
                  color: isSelected ? '#FFFFFF' : 'var(--color-charcoal-700)',
                  border: '1px solid var(--color-paper-border)',
                  fontSize: '0.875rem',
                  fontWeight: isSelected ? '600' : '500',
                  cursor: 'pointer'
                }}
              >
                {m.name}
              </button>
            );
          })}
        </div>
      )}

      {/* Thông tin bảo tàng hiện tại & Thanh thống kê tóm tắt */}
      {activeMuseum && (
        <div
          style={{
            background: '#FFFFFF',
            padding: '16px 20px',
            borderRadius: '12px',
            border: '1px solid var(--color-paper-border)',
            marginBottom: '24px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            flexWrap: 'wrap',
            gap: '14px',
            boxShadow: 'var(--shadow-sm)'
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div
              style={{
                width: 42,
                height: 42,
                borderRadius: '10px',
                background: 'var(--color-burgundy-50, #FDF2F2)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center'
              }}
            >
              <Landmark size={24} color="var(--color-burgundy-700)" />
            </div>
            <div>
              <h3 style={{ fontSize: '1.125rem', fontWeight: '700', color: 'var(--color-burgundy-900)', margin: 0 }}>
                {activeMuseum.name}
              </h3>
              <p style={{ fontSize: '0.8125rem', color: 'var(--color-charcoal-500)', margin: '2px 0 0 0' }}>
                {activeMuseum.address || 'Chưa cập nhật địa chỉ'}
              </p>
            </div>
          </div>

          <div style={{ display: 'flex', gap: '20px', alignItems: 'center' }}>
            <div style={{ textAlign: 'center' }}>
              <div style={{ fontSize: '1.25rem', fontWeight: '700', color: 'var(--color-burgundy-800)' }}>
                {structure.buildings.length}
              </div>
              <div style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-500)' }}>Tòa nhà</div>
            </div>
            <div style={{ width: 1, height: 28, background: 'var(--color-paper-border)' }} />
            <div style={{ textAlign: 'center' }}>
              <div style={{ fontSize: '1.25rem', fontWeight: '700', color: 'var(--color-gold-700)' }}>
                {structure.floors.length}
              </div>
              <div style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-500)' }}>Tầng</div>
            </div>
            <div style={{ width: 1, height: 28, background: 'var(--color-paper-border)' }} />
            <div style={{ textAlign: 'center' }}>
              <div style={{ fontSize: '1.25rem', fontWeight: '700', color: 'var(--color-charcoal-800)' }}>
                {structure.galleries.length}
              </div>
              <div style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-500)' }}>Phòng</div>
            </div>
          </div>
        </div>
      )}

      {/* Nội dung chính: Cây phân cấp */}
      {loading ? (
        <div style={{ padding: '60px', textAlign: 'center', color: 'var(--color-charcoal-500)' }}>
          <Loader2 size={32} className="spin" style={{ margin: '0 auto 12px auto' }} />
          <p style={{ fontSize: '0.9375rem' }}>Đang tải cấu trúc không gian bảo tàng...</p>
        </div>
      ) : error ? (
        <div className="card" style={{ padding: '24px', textAlign: 'center', color: '#B91C1C' }}>
          <AlertTriangle size={32} style={{ margin: '0 auto 8px auto', display: 'block' }} />
          {error}
          <div style={{ marginTop: '12px' }}>
            <button type="button" className="btn btn-secondary btn-sm" onClick={loadStructure}>
              Thử lại
            </button>
          </div>
        </div>
      ) : structure.buildings.length === 0 ? (
        /* Empty State */
        <div
          style={{
            padding: '60px 24px',
            textAlign: 'center',
            background: '#FFFFFF',
            borderRadius: '12px',
            border: '2px dashed var(--color-paper-border)',
            boxShadow: 'var(--shadow-sm)'
          }}
        >
          <Building2 size={48} color="var(--color-charcoal-300)" style={{ margin: '0 auto 16px auto' }} />
          <h4 style={{ fontSize: '1.125rem', fontWeight: '700', color: 'var(--color-charcoal-800)' }}>
            Chưa có cấu trúc không gian
          </h4>
          <p style={{ fontSize: '0.875rem', color: 'var(--color-charcoal-500)', maxWidth: '460px', margin: '8px auto 20px auto' }}>
            Bảo tàng này chưa có tòa nhà nào. Hãy nhấn nút bên dưới để tạo tòa nhà đầu tiên và bắt đầu thiết lập các tầng và phòng trưng bày.
          </p>
          <button
            type="button"
            className="btn btn-primary"
            onClick={() => setModalState({ type: 'building', mode: 'add' })}
          >
            <Plus size={16} /> Thêm Tòa Nhà Đầu Tiên
          </button>
        </div>
      ) : (
        /* Danh sách Tòa nhà (Tree Root) */
        <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          {structure.buildings.map(building => {
            const isExpanded = expandedBuildings.has(building.id);
            const buildingFloors = structure.floors.filter(f => f.buildingId === building.id);

            return (
              <div
                key={building.id}
                style={{
                  background: '#FFFFFF',
                  borderRadius: '12px',
                  border: '1px solid var(--color-paper-border)',
                  overflow: 'hidden',
                  boxShadow: 'var(--shadow-sm)',
                  transition: 'box-shadow 0.2s ease'
                }}
              >
                {/* 1. Header Tòa nhà */}
                <div
                  style={{
                    padding: '16px 20px',
                    background: 'var(--color-paper-accent, #FAF8F5)',
                    borderBottom: isExpanded ? '1px solid var(--color-paper-border)' : 'none',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    flexWrap: 'wrap',
                    gap: '12px'
                  }}
                >
                  <div
                    onClick={() => toggleBuilding(building.id)}
                    style={{ display: 'flex', alignItems: 'center', gap: '10px', cursor: 'pointer', userSelect: 'none' }}
                  >
                    <button
                      type="button"
                      style={{ background: 'none', border: 'none', padding: 0, cursor: 'pointer', display: 'flex' }}
                    >
                      {isExpanded ? <ChevronDown size={20} color="var(--color-burgundy-800)" /> : <ChevronRight size={20} color="var(--color-charcoal-500)" />}
                    </button>
                    <Building2 size={22} color="var(--color-burgundy-700)" />
                    <div>
                      <span style={{ fontSize: '1.0625rem', fontWeight: '700', color: 'var(--color-burgundy-900)' }}>
                        {building.name}
                      </span>
                      <span style={{ fontSize: '0.75rem', background: '#E2E8F0', padding: '2px 8px', borderRadius: '4px', marginLeft: '10px', color: '#475569', fontWeight: '500' }}>
                        {buildingFloors.length} Tầng
                      </span>
                    </div>
                  </div>

                  <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                    <button
                      type="button"
                      className="btn btn-secondary btn-sm"
                      style={{ fontSize: '0.8125rem', padding: '6px 12px', display: 'flex', alignItems: 'center', gap: '6px' }}
                      onClick={() => setModalState({ type: 'floor', mode: 'add', parentId: building.id })}
                    >
                      <Plus size={14} /> Thêm tầng
                    </button>
                    <button
                      type="button"
                      className="btn btn-secondary btn-sm"
                      style={{ padding: '6px 10px' }}
                      title="Chỉnh sửa tên tòa nhà"
                      onClick={() => setModalState({ type: 'building', mode: 'edit', data: building })}
                    >
                      <Edit3 size={14} />
                    </button>
                    <button
                      type="button"
                      className="btn btn-secondary btn-sm"
                      style={{ padding: '6px 10px', color: '#B91C1C', borderColor: '#FCA5A5' }}
                      title="Xóa tòa nhà"
                      onClick={() => handleDeleteBuilding(building)}
                    >
                      <Trash2 size={14} />
                    </button>
                  </div>
                </div>

                {/* 2. Danh sách Tầng (Khi mở rộng) */}
                {isExpanded && (
                  <div style={{ padding: '16px 20px', display: 'flex', flexDirection: 'column', gap: '16px' }}>
                    {buildingFloors.length === 0 ? (
                      <div style={{ padding: '24px', textAlign: 'center', color: 'var(--color-charcoal-400)', fontSize: '0.875rem' }}>
                        Tòa nhà này chưa có tầng nào. Nhấn "+ Thêm tầng" phía trên để thiết lập các tầng.
                      </div>
                    ) : (
                      buildingFloors.map(floor => {
                        const floorGalleries = structure.galleries.filter(g => g.floorId === floor.id);

                        return (
                          <div
                            key={floor.id}
                            style={{
                              background: '#FFFFFF',
                              borderRadius: '10px',
                              border: '1px solid var(--color-paper-border)',
                              boxShadow: '0 1px 3px rgba(0,0,0,0.02)',
                              overflow: 'hidden'
                            }}
                          >
                            {/* Header Tầng */}
                            <div
                              style={{
                                padding: '12px 16px',
                                background: '#FDFBF7',
                                borderBottom: '1px solid #F1ECE1',
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'space-between',
                                flexWrap: 'wrap',
                                gap: '10px'
                              }}
                            >
                              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                <FolderTree size={18} color="var(--color-gold-600)" />
                                <strong style={{ fontSize: '0.9375rem', color: 'var(--color-charcoal-900)' }}>
                                  {floor.name || `Tầng ${floor.levelNo}`}
                                </strong>
                                <span style={{ fontSize: '0.75rem', background: '#F1F5F9', padding: '2px 6px', borderRadius: '4px', color: '#64748B' }}>
                                  Mức: {floor.levelNo}
                                </span>
                                <span style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-500)', marginLeft: '6px' }}>
                                  ({floorGalleries.length} phòng)
                                </span>
                              </div>

                              <div style={{ display: 'flex', gap: '6px', alignItems: 'center' }}>
                                <button
                                  type="button"
                                  className="btn btn-secondary btn-sm"
                                  style={{ padding: '4px 10px', fontSize: '0.75rem', display: 'flex', alignItems: 'center', gap: '4px' }}
                                  onClick={() => setModalState({ type: 'gallery', mode: 'add', parentId: floor.id })}
                                >
                                  <Plus size={13} /> Thêm phòng
                                </button>
                                <button
                                  type="button"
                                  className="btn btn-secondary btn-sm"
                                  style={{ padding: '4px 10px', fontSize: '0.75rem', display: 'flex', alignItems: 'center', gap: '4px', color: 'var(--color-burgundy-800)' }}
                                  title="Chuyển sang Quản lý sơ đồ bản đồ tầng này"
                                  onClick={() => handleOpenMap(floor.id)}
                                >
                                  <Compass size={13} /> Quản lý sơ đồ
                                </button>
                                <button
                                  type="button"
                                  className="btn btn-secondary btn-sm"
                                  style={{ padding: '4px 8px' }}
                                  title="Sửa tầng"
                                  onClick={() => setModalState({ type: 'floor', mode: 'edit', data: floor, parentId: building.id })}
                                >
                                  <Edit3 size={13} />
                                </button>
                                <button
                                  type="button"
                                  className="btn btn-secondary btn-sm"
                                  style={{ padding: '4px 8px', color: '#B91C1C' }}
                                  title="Xóa tầng"
                                  onClick={() => handleDeleteFloor(floor)}
                                >
                                  <Trash2 size={13} />
                                </button>
                              </div>
                            </div>

                            {/* Danh sách Phòng trưng bày trong tầng */}
                            <div style={{ padding: '14px 16px' }}>
                              {floorGalleries.length === 0 ? (
                                <div style={{ padding: '12px', textAlign: 'center', color: 'var(--color-charcoal-400)', fontSize: '0.8125rem' }}>
                                  Chưa có phòng trưng bày nào trong tầng này. Nhấn "+ Thêm phòng" để bổ sung.
                                </div>
                              ) : (
                                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: '12px' }}>
                                  {floorGalleries.map(gallery => {
                                    const count = artifacts.filter(a => a.galleryId === gallery.id).length;

                                    return (
                                      <div
                                        key={gallery.id}
                                        style={{
                                          padding: '12px 14px',
                                          background: '#FFFFFF',
                                          borderRadius: '8px',
                                          border: '1px solid var(--color-paper-border)',
                                          display: 'flex',
                                          flexDirection: 'column',
                                          justifyContent: 'space-between',
                                          gap: '8px',
                                          boxShadow: '0 1px 2px rgba(0,0,0,0.03)'
                                        }}
                                      >
                                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                                          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                            <DoorOpen size={16} color="var(--color-burgundy-700)" />
                                            <div>
                                              <strong style={{ fontSize: '0.875rem', color: 'var(--color-burgundy-900)' }}>
                                                {gallery.name}
                                              </strong>
                                              {gallery.code && (
                                                <span style={{ fontSize: '0.675rem', fontFamily: 'monospace', background: '#F1F5F9', padding: '1px 5px', borderRadius: '3px', marginLeft: '6px' }}>
                                                  {gallery.code}
                                                </span>
                                              )}
                                            </div>
                                          </div>

                                          <div style={{ display: 'flex', gap: '4px' }}>
                                            <button
                                              type="button"
                                              className="btn btn-secondary btn-sm"
                                              style={{ padding: '3px 6px' }}
                                              title="Sửa phòng"
                                              onClick={() => setModalState({ type: 'gallery', mode: 'edit', data: gallery, parentId: floor.id })}
                                            >
                                              <Edit3 size={12} />
                                            </button>
                                            <button
                                              type="button"
                                              className="btn btn-secondary btn-sm"
                                              style={{ padding: '3px 6px', color: '#B91C1C' }}
                                              title="Xóa phòng"
                                              onClick={() => handleDeleteGallery(gallery)}
                                            >
                                              <Trash2 size={12} />
                                            </button>
                                          </div>
                                        </div>

                                        {gallery.description && (
                                          <p style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-500)', margin: '0', lineHeight: 1.4, display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>
                                            {gallery.description}
                                          </p>
                                        )}

                                        <div style={{ borderTop: '1px solid #F1F5F9', paddingTop: '6px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                          <span style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-700)', fontWeight: '600', display: 'flex', alignItems: 'center', gap: '4px' }}>
                                            <PackageCheck size={13} color="var(--color-burgundy-700)" /> {count} Hiện vật
                                          </span>
                                          <span style={{ fontSize: '0.675rem', color: '#166534', background: '#DCFCE7', padding: '1px 6px', borderRadius: '3px', fontWeight: '500' }}>
                                            Phòng trưng bày
                                          </span>
                                        </div>
                                      </div>
                                    );
                                  })}
                                </div>
                              )}
                            </div>
                          </div>
                        );
                      })
                    )}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}

      {/* Modal xử lý Thêm / Sửa từng đối tượng (Building / Floor / Gallery) */}
      {modalState && (
        <StructureFormModal
          museumId={activeMuseum.id}
          modalState={modalState}
          onClose={() => setModalState(null)}
          onSuccess={async () => {
            setModalState(null);
            await loadStructure();
          }}
        />
      )}
    </div>
  );
}

// Modal Form độc lập cho từng đối tượng
function StructureFormModal({ museumId, modalState, onClose, onSuccess }) {
  const { type, mode, data, parentId } = modalState;
  const { showToast } = useApp();

  const [name, setName] = useState(data?.name || '');
  const [levelNo, setLevelNo] = useState(data?.levelNo ?? 0);
  const [description, setDescription] = useState(data?.description || '');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const title = `${mode === 'add' ? 'Thêm' : 'Chỉnh sửa'} ${
    type === 'building' ? 'Tòa nhà' : type === 'floor' ? 'Tầng' : 'Phòng trưng bày'
  }`;

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!name.trim() || isSubmitting) return;

    setIsSubmitting(true);
    try {
      if (type === 'building') {
        if (mode === 'add') {
          await backend(`museums/${museumId}/buildings`, {
            method: 'POST',
            body: { name: name.trim() }
          });
          showToast(`Đã thêm tòa nhà "${name.trim()}".`, 'success');
        } else {
          await backend(`museums/${museumId}/buildings/${data.id}`, {
            method: 'PUT',
            body: { name: name.trim() }
          });
          showToast(`Đã cập nhật tòa nhà.`, 'success');
        }
      } else if (type === 'floor') {
        if (mode === 'add') {
          await backend(`museums/${museumId}/floors`, {
            method: 'POST',
            body: {
              buildingId: Number(parentId),
              levelNo: Number(levelNo),
              name: name.trim()
            }
          });
          showToast(`Đã thêm tầng mới.`, 'success');
        } else {
          await backend(`museums/${museumId}/floors/${data.id}`, {
            method: 'PUT',
            body: {
              buildingId: Number(parentId || data.buildingId),
              levelNo: Number(levelNo),
              name: name.trim()
            }
          });
          showToast(`Đã cập nhật tầng.`, 'success');
        }
      } else if (type === 'gallery') {
        if (mode === 'add') {
          await backend(`museums/${museumId}/galleries`, {
            method: 'POST',
            body: {
              floorId: Number(parentId),
              name: name.trim(),
              description: description.trim() || null
            }
          });
          showToast(`Đã thêm phòng trưng bày "${name.trim()}".`, 'success');
        } else {
          await backend(`museums/${museumId}/galleries/${data.id}`, {
            method: 'PUT',
            body: {
              floorId: Number(parentId || data.floorId),
              name: name.trim(),
              description: description.trim() || null
            }
          });
          showToast(`Đã cập nhật phòng trưng bày.`, 'success');
        }
      }

      onSuccess();
    } catch (err) {
      showToast(err.message || 'Thao tác không thành công.', 'error');
    } finally {
      setIsSubmitting(false);
    }
  };

  return createPortal(
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-dialog" style={{ maxWidth: '480px', width: '95vw' }} onClick={e => e.stopPropagation()}>
        <div className="modal-header">
          <h3 className="modal-title font-serif">{title}</h3>
          <button type="button" className="btn btn-secondary btn-sm" onClick={onClose}>✕</button>
        </div>
        <form onSubmit={handleSubmit}>
          <div className="modal-body" style={{ display: 'grid', gap: '14px', padding: '20px' }}>
            <label className="form-group" style={{ marginBottom: 0 }}>
              <span className="form-label">Tên {type === 'building' ? 'tòa nhà' : type === 'floor' ? 'tầng' : 'phòng'} *</span>
              <input
                className="form-input"
                required
                maxLength={type === 'gallery' ? 300 : 200}
                value={name}
                onChange={e => setName(e.target.value)}
                placeholder={type === 'building' ? 'Ví dụ: Tòa nhà A, Nhà trưng bày cổ vật' : type === 'floor' ? 'Ví dụ: Tầng trệt, Tầng 1' : 'Ví dụ: Phòng Văn hóa Đông Sơn'}
              />
            </label>

            {type === 'floor' && (
              <label className="form-group" style={{ marginBottom: 0 }}>
                <span className="form-label">Mức số tầng (Level Number) *</span>
                <input
                  type="number"
                  className="form-input"
                  required
                  value={levelNo}
                  onChange={e => setLevelNo(e.target.value)}
                  placeholder="0 cho tầng trệt, 1 cho tầng 1, -1 cho tầng hầm"
                />
              </label>
            )}

            {type === 'gallery' && (
              <label className="form-group" style={{ marginBottom: 0 }}>
                <span className="form-label">Mô tả phòng trưng bày</span>
                <textarea
                  className="form-textarea"
                  rows={3}
                  value={description}
                  onChange={e => setDescription(e.target.value)}
                  placeholder="Giới thiệu khái quát về nội dung và chủ đề phòng trưng bày..."
                />
              </label>
            )}
          </div>
          <div className="modal-footer">
            <button type="button" className="btn btn-secondary" onClick={onClose} disabled={isSubmitting}>
              Hủy
            </button>
            <button type="submit" className="btn btn-primary" disabled={isSubmitting || !name.trim()}>
              {isSubmitting ? 'Đang lưu...' : 'Lưu lại'}
            </button>
          </div>
        </form>
      </div>
    </div>,
    document.body
  );
}
