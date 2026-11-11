import React, { useState, useEffect, useCallback } from 'react';
import { createPortal } from 'react-dom';
import { X, ChevronLeft, ChevronRight, Image as ImageIcon, Download } from 'lucide-react';
import { mediaApi } from '../../services/mediaApi';

export default function ArtifactPhotoGalleryModal({ artifact, initialIndex = 0, onClose }) {
  const [currentIndex, setCurrentIndex] = useState(initialIndex);
  const [images, setImages] = useState(artifact?.images || (artifact?.image ? [artifact.image] : []));
  const [imageTitles, setImageTitles] = useState([]);
  const [loading, setLoading] = useState(false);

  // Load full media list from backend if available
  useEffect(() => {
    if (!artifact?.id) return;
    const controller = new AbortController();
    setLoading(true);
    mediaApi(`artifacts/${artifact.id}/media?mediaType=image`, { signal: controller.signal })
      .then(items => {
        if (!controller.signal.aborted && Array.isArray(items) && items.length > 0) {
          const urls = items.map(m => m.fileUrl).filter(Boolean);
          if (urls.length > 0) {
            setImages(urls);
            setImageTitles(items.map(m => m.title || m.fileName || ''));
          }
        }
      })
      .catch(() => {
        // Fall back to existing artifact.images
      })
      .finally(() => {
        if (!controller.signal.aborted) setLoading(false);
      });

    return () => controller.abort();
  }, [artifact?.id]);

  const prevImage = useCallback(() => {
    if (images.length <= 1) return;
    setCurrentIndex(idx => (idx === 0 ? images.length - 1 : idx - 1));
  }, [images.length]);

  const nextImage = useCallback(() => {
    if (images.length <= 1) return;
    setCurrentIndex(idx => (idx === images.length - 1 ? 0 : idx + 1));
  }, [images.length]);

  // Keyboard navigation
  useEffect(() => {
    function handleKeyDown(e) {
      if (e.key === 'Escape') {
        onClose();
      } else if (e.key === 'ArrowLeft') {
        prevImage();
      } else if (e.key === 'ArrowRight') {
        nextImage();
      }
    }
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [onClose, prevImage, nextImage]);

  if (!artifact) return null;

  const currentUrl = images[currentIndex] || artifact.image || '/assets/images/placeholder.svg';
  const currentTitle = imageTitles[currentIndex] || artifact.name;

  return createPortal(
    <div
      style={{
        position: 'fixed',
        inset: 0,
        zIndex: 99999,
        backgroundColor: 'rgba(10, 13, 18, 0.96)',
        backdropFilter: 'blur(10px)',
        display: 'flex',
        flexDirection: 'column',
        userSelect: 'none',
        animation: 'fadeIn 0.2s ease-out'
      }}
      onClick={onClose}
    >
      {/* Top Bar (Facebook-style header) */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          padding: '14px 24px',
          backgroundColor: 'rgba(0, 0, 0, 0.4)',
          borderBottom: '1px solid rgba(255, 255, 255, 0.1)',
          color: '#fff',
          zIndex: 10
        }}
        onClick={e => e.stopPropagation()}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
          <div style={{
            width: 38,
            height: 38,
            borderRadius: 8,
            background: 'rgba(255, 255, 255, 0.1)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: '#f59e0b'
          }}>
            <ImageIcon size={20} />
          </div>
          <div>
            <div style={{ fontSize: '1.05rem', fontWeight: 600, color: '#fef3c7', letterSpacing: '-0.01em' }}>
              {artifact.name}
            </div>
            <div style={{ fontSize: '0.8rem', color: 'rgba(255, 255, 255, 0.65)', marginTop: 2 }}>
              {artifact.code ? `Mã: ${artifact.code}` : ''}
              {artifact.galleryName ? ` • ${artifact.galleryName}` : ''}
            </div>
          </div>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
          {images.length > 0 && (
            <div style={{
              background: 'rgba(255, 255, 255, 0.12)',
              padding: '4px 12px',
              borderRadius: 16,
              fontSize: '0.85rem',
              fontWeight: 600,
              color: '#fff',
              letterSpacing: '0.02em'
            }}>
              {currentIndex + 1} / {images.length}
            </div>
          )}

          <button
            type="button"
            onClick={onClose}
            style={{
              background: 'rgba(255, 255, 255, 0.1)',
              border: 'none',
              borderRadius: '50%',
              width: 36,
              height: 36,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: '#fff',
              cursor: 'pointer',
              transition: 'background 0.2s'
            }}
            onMouseEnter={e => e.currentTarget.style.background = 'rgba(255, 255, 255, 0.25)'}
            onMouseLeave={e => e.currentTarget.style.background = 'rgba(255, 255, 255, 0.1)'}
            title="Đóng (Esc)"
          >
            <X size={20} />
          </button>
        </div>
      </div>

      {/* Main Viewing Stage */}
      <div
        style={{
          flex: 1,
          position: 'relative',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          padding: '20px 40px',
          overflow: 'hidden'
        }}
        onClick={e => e.stopPropagation()}
      >
        {/* Previous Button */}
        {images.length > 1 && (
          <button
            type="button"
            onClick={prevImage}
            style={{
              position: 'absolute',
              left: 24,
              top: '50%',
              transform: 'translateY(-50%)',
              width: 48,
              height: 48,
              borderRadius: '50%',
              background: 'rgba(255, 255, 255, 0.12)',
              border: '1px solid rgba(255, 255, 255, 0.2)',
              color: '#fff',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              zIndex: 5,
              backdropFilter: 'blur(6px)',
              transition: 'all 0.2s'
            }}
            onMouseEnter={e => {
              e.currentTarget.style.background = 'rgba(245, 158, 11, 0.85)';
              e.currentTarget.style.transform = 'translateY(-50%) scale(1.08)';
            }}
            onMouseLeave={e => {
              e.currentTarget.style.background = 'rgba(255, 255, 255, 0.12)';
              e.currentTarget.style.transform = 'translateY(-50%) scale(1)';
            }}
            title="Ảnh trước (Mũi tên trái)"
          >
            <ChevronLeft size={28} />
          </button>
        )}

        {/* Current Image Display */}
        <div style={{
          maxWidth: '85vw',
          maxHeight: images.length > 1 ? '68vh' : '78vh',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          position: 'relative'
        }}>
          <img
            key={currentUrl}
            src={currentUrl}
            alt={currentTitle}
            style={{
              maxWidth: '100%',
              maxHeight: images.length > 1 ? '66vh' : '76vh',
              objectFit: 'contain',
              borderRadius: 8,
              boxShadow: '0 10px 40px rgba(0, 0, 0, 0.6)',
              animation: 'zoomIn 0.22s ease-out'
            }}
            onError={e => {
              e.target.onerror = null;
              e.target.src = '/assets/images/placeholder.svg';
            }}
          />
          {currentTitle && currentTitle !== artifact.name && (
            <div style={{
              marginTop: 10,
              fontSize: '0.85rem',
              color: 'rgba(255, 255, 255, 0.8)',
              background: 'rgba(0, 0, 0, 0.6)',
              padding: '4px 12px',
              borderRadius: 6
            }}>
              {currentTitle}
            </div>
          )}
        </div>

        {/* Next Button */}
        {images.length > 1 && (
          <button
            type="button"
            onClick={nextImage}
            style={{
              position: 'absolute',
              right: 24,
              top: '50%',
              transform: 'translateY(-50%)',
              width: 48,
              height: 48,
              borderRadius: '50%',
              background: 'rgba(255, 255, 255, 0.12)',
              border: '1px solid rgba(255, 255, 255, 0.2)',
              color: '#fff',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              zIndex: 5,
              backdropFilter: 'blur(6px)',
              transition: 'all 0.2s'
            }}
            onMouseEnter={e => {
              e.currentTarget.style.background = 'rgba(245, 158, 11, 0.85)';
              e.currentTarget.style.transform = 'translateY(-50%) scale(1.08)';
            }}
            onMouseLeave={e => {
              e.currentTarget.style.background = 'rgba(255, 255, 255, 0.12)';
              e.currentTarget.style.transform = 'translateY(-50%) scale(1)';
            }}
            title="Ảnh tiếp theo (Mũi tên phải)"
          >
            <ChevronRight size={28} />
          </button>
        )}
      </div>

      {/* Bottom Thumbnail Strip (Facebook-style thumbnail strip) */}
      {images.length > 1 && (
        <div
          style={{
            padding: '12px 24px',
            backgroundColor: 'rgba(0, 0, 0, 0.5)',
            borderTop: '1px solid rgba(255, 255, 255, 0.1)',
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            gap: 10,
            overflowX: 'auto',
            zIndex: 10
          }}
          onClick={e => e.stopPropagation()}
        >
          {images.map((imgUrl, index) => {
            const isActive = index === currentIndex;
            return (
              <div
                key={imgUrl + index}
                onClick={() => setCurrentIndex(index)}
                style={{
                  width: 64,
                  height: 52,
                  borderRadius: 6,
                  overflow: 'hidden',
                  cursor: 'pointer',
                  border: isActive ? '2px solid #f59e0b' : '1px solid rgba(255, 255, 255, 0.25)',
                  boxShadow: isActive ? '0 0 10px rgba(245, 158, 11, 0.6)' : 'none',
                  opacity: isActive ? 1 : 0.55,
                  transform: isActive ? 'scale(1.06)' : 'scale(1)',
                  transition: 'all 0.2s',
                  flexShrink: 0
                }}
                onMouseEnter={e => {
                  if (!isActive) e.currentTarget.style.opacity = '0.85';
                }}
                onMouseLeave={e => {
                  if (!isActive) e.currentTarget.style.opacity = '0.55';
                }}
              >
                <img
                  src={imgUrl}
                  alt={`Thumbnail ${index + 1}`}
                  style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }}
                  onError={e => {
                    e.target.onerror = null;
                    e.target.src = '/assets/images/placeholder.svg';
                  }}
                />
              </div>
            );
          })}
        </div>
      )}
    </div>,
    document.body
  );
}
