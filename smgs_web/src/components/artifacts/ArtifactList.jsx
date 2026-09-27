import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import {
  Layers,
  Search,
  Filter,
  Plus,
  Box,
  QrCode,
  Sparkles,
  Eye,
  Edit2,
  Trash2,
  Award,
  Grid,
  List,
  Volume2
} from 'lucide-react';
import ArtifactDetailModal from './ArtifactDetailModal';
import ArtifactEditModal from './ArtifactEditModal';

export default function ArtifactList({ onOpenAIStudio }) {
  const {
    artifacts,
    addArtifact,
    updateArtifact,
    deleteArtifact,
    selectedMuseumId,
    currentMuseum,
    currentRole
  } = useApp();

  const [searchTerm, setSearchTerm] = useState('');
  const [selectedGallery, setSelectedGallery] = useState('all');
  const [selectedStatus, setSelectedStatus] = useState('all');
  const [filterTreasureOnly, setFilterTreasureOnly] = useState(false);
  const [viewMode, setViewMode] = useState('table'); // 'table' | 'grid'

  // Modals state
  const [selectedArtifact, setSelectedArtifact] = useState(null);
  const [editingArtifact, setEditingArtifact] = useState(null);
  const [isCreatingNew, setIsCreatingNew] = useState(false);

  // Filter artifacts
  const filteredArtifacts = artifacts.filter(art => {
    // Museum scope: if role is staff, filter by museum unless 'all'
    if (selectedMuseumId !== 'all' && art.museumId !== selectedMuseumId) {
      return false;
    }
    if (selectedGallery !== 'all' && art.galleryName !== selectedGallery) {
      return false;
    }
    if (selectedStatus !== 'all' && art.status !== selectedStatus) {
      return false;
    }
    if (filterTreasureOnly && !art.isNationalTreasure) {
      return false;
    }
    if (searchTerm.trim()) {
      const q = searchTerm.toLowerCase();
      const matchName = art.name.toLowerCase().includes(q);
      const matchCode = art.code.toLowerCase().includes(q);
      const matchQR = art.qrCode.toLowerCase().includes(q);
      const matchMaterial = art.material.toLowerCase().includes(q);
      const matchTheme = art.theme.toLowerCase().includes(q);
      return matchName || matchCode || matchQR || matchMaterial || matchTheme;
    }
    return true;
  });

  // Unique galleries list for filter
  const galleryList = Array.from(new Set(artifacts.map(a => a.galleryName))).filter(Boolean);

  const totalTreasureCount = artifacts.filter(a => a.isNationalTreasure).length;
  const total3DCount = artifacts.filter(a => a.has3DModel).length;
  const totalScans = artifacts.reduce((acc, curr) => acc + (curr.scansCount || 0), 0);

  return (
    <div>
      {/* Page Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '24px', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <h2 style={{ fontSize: '1.625rem', fontWeight: '700', color: 'var(--color-burgundy-900)' }} className="font-serif">
            Kho Quản Lý Hiện Vật & Mã QR
          </h2>
          <p style={{ fontSize: '0.875rem', color: 'var(--color-charcoal-500)', marginTop: '4px' }}>
            Hệ thống quản lý định danh số, tư liệu thuyết minh, mã QR và mô hình 3D cho các hiện vật bảo tàng
          </p>
        </div>

        <div style={{ display: 'flex', gap: '12px' }}>
          <button
            type="button"
            onClick={() => setIsCreatingNew(true)}
            className="btn btn-primary"
          >
            <Plus size={16} /> Thêm hiện vật mới
          </button>
        </div>
      </div>

      {/* Metrics Row */}
      <div className="stat-grid" style={{ marginBottom: '24px' }}>
        <div className="stat-card stat-card-burgundy">
          <div className="stat-icon-wrapper">
            <Layers size={24} />
          </div>
          <div>
            <div className="stat-value">{artifacts.length}</div>
            <div className="stat-label">Tổng số hiện vật số hóa</div>
          </div>
        </div>

        <div className="stat-card stat-card-gold">
          <div className="stat-icon-wrapper">
            <Award size={24} />
          </div>
          <div>
            <div className="stat-value">{totalTreasureCount}</div>
            <div className="stat-label">Bảo vật Quốc gia</div>
          </div>
        </div>

        <div className="stat-card stat-card-blue">
          <div className="stat-icon-wrapper">
            <Box size={24} />
          </div>
          <div>
            <div className="stat-value">{total3DCount}</div>
            <div className="stat-label">Mô hình 3D tương tác (AR)</div>
          </div>
        </div>

        <div className="stat-card stat-card-green">
          <div className="stat-icon-wrapper">
            <QrCode size={24} />
          </div>
          <div>
            <div className="stat-value">{totalScans.toLocaleString()}</div>
            <div className="stat-label">Lượt quét QR ghi nhận</div>
          </div>
        </div>
      </div>

      {/* Filter and Control Bar */}
      <div className="card" style={{ padding: '16px 20px', marginBottom: '24px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '16px', flexWrap: 'wrap' }}>
          {/* Search box */}
          <div style={{ position: 'relative', flex: 1, minWidth: '260px' }}>
            <Search size={16} color="var(--color-charcoal-400)" style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)' }} />
            <input
              type="text"
              className="form-input"
              style={{ paddingLeft: '36px' }}
              placeholder="Tìm theo tên hiện vật, mã hiện vật, mã QR, thời kỳ..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>

          {/* Gallery Filter */}
          <select
            className="form-select"
            style={{ width: 'auto', minWidth: '180px' }}
            value={selectedGallery}
            onChange={(e) => setSelectedGallery(e.target.value)}
          >
            <option value="all">Tất cả phòng trưng bày</option>
            {galleryList.map(g => (
              <option key={g} value={g}>{g}</option>
            ))}
          </select>

          {/* Status Filter */}
          <select
            className="form-select"
            style={{ width: 'auto', minWidth: '150px' }}
            value={selectedStatus}
            onChange={(e) => setSelectedStatus(e.target.value)}
          >
            <option value="all">Tất cả trạng thái</option>
            <option value="published">Đã xuất bản</option>
            <option value="pending">Chờ kiểm duyệt</option>
            <option value="draft">Bản nháp</option>
          </select>

          {/* National Treasure Toggle */}
          <label style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '0.8125rem', cursor: 'pointer', fontWeight: '600' }}>
            <input
              type="checkbox"
              checked={filterTreasureOnly}
              onChange={(e) => setFilterTreasureOnly(e.target.checked)}
            />
            <span>⭐ Chỉ Bảo vật Quốc gia</span>
          </label>

          {/* View Mode Switcher */}
          <div style={{ display: 'flex', border: '1px solid var(--color-paper-border)', borderRadius: '8px', overflow: 'hidden' }}>
            <button
              type="button"
              onClick={() => setViewMode('table')}
              style={{
                padding: '7px 12px',
                background: viewMode === 'table' ? 'var(--color-paper-accent)' : '#FFF',
                color: viewMode === 'table' ? 'var(--color-burgundy-700)' : 'var(--color-charcoal-500)',
                borderRight: '1px solid var(--color-paper-border)'
              }}
              title="Xem dạng Bảng"
            >
              <List size={16} />
            </button>
            <button
              type="button"
              onClick={() => setViewMode('grid')}
              style={{
                padding: '7px 12px',
                background: viewMode === 'grid' ? 'var(--color-paper-accent)' : '#FFF',
                color: viewMode === 'grid' ? 'var(--color-burgundy-700)' : 'var(--color-charcoal-500)'
              }}
              title="Xem dạng Thẻ ảnh"
            >
              <Grid size={16} />
            </button>
          </div>
        </div>
      </div>

      {/* Artifacts Display: Table View */}
      {viewMode === 'table' ? (
        <div className="card">
          <div className="table-container">
            <table className="data-table">
              <thead>
                <tr>
                  <th style={{ width: '80px' }}>Ảnh</th>
                  <th>Tên hiện vật & Mã định danh</th>
                  <th>Vị trí trưng bày</th>
                  <th>Niên đại & Chất liệu</th>
                  <th style={{ textAlign: 'center' }}>Tính năng số</th>
                  <th>Trạng thái</th>
                  <th style={{ textAlign: 'right' }}>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {filteredArtifacts.length > 0 ? (
                  filteredArtifacts.map(art => (
                    <tr key={art.id}>
                      {/* Image Thumbnail */}
                      <td>
                        <div style={{
                          width: '56px',
                          height: '56px',
                          borderRadius: '8px',
                          overflow: 'hidden',
                          border: '1px solid var(--color-paper-border)',
                          background: '#1A1F26',
                          cursor: 'pointer'
                        }}
                        onClick={() => setSelectedArtifact(art)}
                        >
                          <img
                            src={art.image || '/assets/images/ngoc-lu-web.jpg'}
                            alt={art.name}
                            style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                            onError={(e) => { e.target.src = '/assets/images/national-museum-web.jpg'; }}
                          />
                        </div>
                      </td>

                      {/* Name & Code */}
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                          <button
                            type="button"
                            onClick={() => setSelectedArtifact(art)}
                            style={{ fontWeight: '600', fontSize: '0.9375rem', color: 'var(--color-burgundy-800)', textAlign: 'left' }}
                          >
                            {art.name}
                          </button>
                          {art.isNationalTreasure && (
                            <span className="badge-status badge-treasure" style={{ fontSize: '0.65rem' }}>Bảo vật QG</span>
                          )}
                        </div>
                        <div style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-500)', marginTop: '2px', display: 'flex', gap: '8px' }}>
                          <span>Mã: <code style={{ color: 'var(--color-charcoal-800)' }}>{art.code}</code></span>
                          <span>•</span>
                          <span>QR: <code style={{ color: 'var(--color-burgundy-700)' }}>{art.qrCode}</code></span>
                        </div>
                      </td>

                      {/* Location */}
                      <td>
                        <div style={{ fontSize: '0.8125rem', fontWeight: '500' }}>{art.galleryName}</div>
                        <div style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-500)' }}>
                          {art.buildingName} — {art.floorName}
                        </div>
                      </td>

                      {/* Period & Material */}
                      <td>
                        <div style={{ fontSize: '0.8125rem' }}>{art.period}</div>
                        <div style={{ fontSize: '0.75rem', color: 'var(--color-charcoal-500)' }}>{art.material}</div>
                      </td>

                      {/* Digital Features */}
                      <td>
                        <div style={{ display: 'flex', gap: '6px', justifyContent: 'center' }}>
                          {art.has3DModel ? (
                            <span title="Có mô hình 3D AR" style={{ background: '#DCFCE7', color: '#166534', padding: '4px 6px', borderRadius: '4px', fontSize: '0.7rem', display: 'flex', alignItems: 'center', gap: '3px' }}>
                              <Box size={12} /> 3D
                            </span>
                          ) : (
                            <span title="Chưa có 3D" style={{ background: '#F1F5F9', color: '#94A3B8', padding: '4px 6px', borderRadius: '4px', fontSize: '0.7rem' }}>
                              No 3D
                            </span>
                          )}

                          <span title="Mã QR định danh" style={{ background: 'var(--color-burgundy-50)', color: 'var(--color-burgundy-700)', padding: '4px 6px', borderRadius: '4px', fontSize: '0.7rem', display: 'flex', alignItems: 'center', gap: '3px' }}>
                            <QrCode size={12} /> QR
                          </span>

                          {art.quizzes && art.quizzes.length > 0 && (
                            <span title={`${art.quizzes.length} câu hỏi trắc nghiệm`} style={{ background: 'var(--color-gold-50)', color: 'var(--color-gold-700)', padding: '4px 6px', borderRadius: '4px', fontSize: '0.7rem', display: 'flex', alignItems: 'center', gap: '3px' }}>
                              Quiz: {art.quizzes.length}
                            </span>
                          )}
                        </div>
                      </td>

                      {/* Status */}
                      <td>
                        <span className={`badge-status badge-${art.status}`}>
                          {art.status === 'published' ? 'Đã xuất bản' : art.status === 'pending' ? 'Chờ duyệt' : 'Bản nháp'}
                        </span>
                      </td>

                      {/* Actions */}
                      <td style={{ textAlign: 'right' }}>
                        <div style={{ display: 'inline-flex', gap: '6px' }}>
                          <button
                            type="button"
                            onClick={() => setSelectedArtifact(art)}
                            className="btn btn-secondary btn-sm"
                            title="Xem chi tiết & QR"
                          >
                            <Eye size={14} />
                          </button>
                          <button
                            type="button"
                            onClick={() => onOpenAIStudio(art)}
                            className="btn btn-gold btn-sm"
                            title="Mở AI Content Studio"
                          >
                            <Sparkles size={14} />
                          </button>
                          <button
                            type="button"
                            onClick={() => setEditingArtifact(art)}
                            className="btn btn-secondary btn-sm"
                            title="Chỉnh sửa"
                          >
                            <Edit2 size={14} />
                          </button>
                          {currentRole === 'administrator' && (
                            <button
                              type="button"
                              onClick={() => {
                                if (window.confirm(`Bạn có chắc muốn xóa hiện vật "${art.name}"?`)) {
                                  deleteArtifact(art.id);
                                }
                              }}
                              className="btn btn-secondary btn-sm"
                              style={{ color: 'var(--color-danger)' }}
                              title="Xóa hiện vật"
                            >
                              <Trash2 size={14} />
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={7} style={{ textAlign: 'center', padding: '40px', color: 'var(--color-charcoal-500)' }}>
                      Không tìm thấy hiện vật nào phù hợp với bộ lọc.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      ) : (
        /* Artifacts Display: Grid View */
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '24px' }}>
          {filteredArtifacts.map(art => (
            <div key={art.id} className="card" style={{ display: 'flex', flexDirection: 'column' }}>
              <div style={{
                position: 'relative',
                height: '180px',
                background: '#1A1F26',
                overflow: 'hidden'
              }}>
                <img
                  src={art.image || '/assets/images/ngoc-lu-web.jpg'}
                  alt={art.name}
                  style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                  onError={(e) => { e.target.src = '/assets/images/national-museum-web.jpg'; }}
                />
                <div style={{ position: 'absolute', top: '12px', left: '12px', display: 'flex', gap: '6px' }}>
                  {art.isNationalTreasure && (
                    <span className="badge-status badge-treasure">⭐ Bảo vật QG</span>
                  )}
                </div>
                <div style={{ position: 'absolute', top: '12px', right: '12px' }}>
                  <span className={`badge-status badge-${art.status}`}>
                    {art.status === 'published' ? 'Đã xuất bản' : 'Chờ duyệt'}
                  </span>
                </div>
                {art.has3DModel && (
                  <div style={{
                    position: 'absolute',
                    bottom: '10px',
                    right: '10px',
                    background: 'rgba(0,0,0,0.7)',
                    color: '#FFF',
                    fontSize: '0.7rem',
                    padding: '3px 8px',
                    borderRadius: '4px',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '4px'
                  }}>
                    <Box size={12} color="var(--color-gold-400)" /> 3D AR
                  </div>
                )}
              </div>

              <div style={{ padding: '16px', flex: 1, display: 'flex', flexDirection: 'column' }}>
                <h4 style={{ fontSize: '1rem', fontWeight: '700', marginBottom: '4px', color: 'var(--color-charcoal-950)' }}>
                  {art.name}
                </h4>
                <p style={{ fontSize: '0.75rem', color: 'var(--color-burgundy-700)', fontWeight: '600', marginBottom: '8px' }}>
                  {art.galleryName}
                </p>
                <p style={{ fontSize: '0.8125rem', color: 'var(--color-charcoal-600)', lineHeight: '1.5', flex: 1, marginBottom: '16px', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>
                  {art.shortDesc}
                </p>

                <div style={{ display: 'flex', gap: '8px', borderTop: '1px solid var(--color-paper-border)', paddingTop: '12px' }}>
                  <button
                    type="button"
                    onClick={() => setSelectedArtifact(art)}
                    className="btn btn-secondary btn-sm"
                    style={{ flex: 1 }}
                  >
                    <Eye size={14} /> Xem chi tiết
                  </button>
                  <button
                    type="button"
                    onClick={() => onOpenAIStudio(art)}
                    className="btn btn-gold btn-sm"
                    title="AI Studio"
                  >
                    <Sparkles size={14} />
                  </button>
                  <button
                    type="button"
                    onClick={() => setEditingArtifact(art)}
                    className="btn btn-secondary btn-sm"
                    title="Sửa"
                  >
                    <Edit2 size={14} />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Artifact Detail Modal */}
      {selectedArtifact && (
        <ArtifactDetailModal
          artifact={selectedArtifact}
          onClose={() => setSelectedArtifact(null)}
          onOpenAIStudio={(art) => {
            setSelectedArtifact(null);
            onOpenAIStudio(art);
          }}
          onEdit={(art) => {
            setSelectedArtifact(null);
            setEditingArtifact(art);
          }}
        />
      )}

      {/* Artifact Edit / Create Modal */}
      {(editingArtifact || isCreatingNew) && (
        <ArtifactEditModal
          artifact={editingArtifact}
          onClose={() => {
            setEditingArtifact(null);
            setIsCreatingNew(false);
          }}
          onSave={(artData) => {
            if (isCreatingNew) {
              addArtifact(artData);
            } else {
              updateArtifact(artData);
            }
          }}
        />
      )}
    </div>
  );
}
