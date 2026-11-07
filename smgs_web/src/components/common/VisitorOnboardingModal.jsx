import React, { useState, useEffect } from 'react';
import { QrCode, Headphones, Compass, BookOpen, ChevronRight, CheckCircle2 } from 'lucide-react';
import './visitorGuidebook.css';

const ONBOARDING_KEY = 'has_seen_visitor_onboarding_v1';

export default function VisitorOnboardingModal({ isOpen, onClose }) {
  const [open, setOpen] = useState(false);
  const [currentStep, setCurrentStep] = useState(0);

  useEffect(() => {
    if (isOpen !== undefined) {
      setOpen(isOpen);
    } else {
      const hasSeen = localStorage.getItem(ONBOARDING_KEY);
      if (!hasSeen) {
        setOpen(true);
      }
    }
  }, [isOpen]);

  const handleComplete = () => {
    localStorage.setItem(ONBOARDING_KEY, 'true');
    setOpen(false);
    if (onClose) onClose();
  };

  const steps = [
    {
      badge: 'BƯỚC 1 · TƯƠNG TÁC',
      title: 'Quét mã & Nhận diện',
      description:
          'Chạm biểu tượng Quét mã QR tại chân tủ kính hoặc dùng AI Vision để mở hồ sơ lịch sử và hình ảnh 3D chỉ trong 1 giây.',
      icon: QrCode,
    },
    {
      badge: 'BƯỚC 2 · LẮNG NGHE',
      title: 'Thuyết minh Âm thanh AI',
      description:
          'Lắng nghe câu chuyện khảo cổ sống động được AI tổng hợp từ kịch bản chuẩn mực của Giám tuyển; dễ dàng điều chỉnh tốc độ đọc.',
      icon: Headphones,
    },
    {
      badge: 'BƯỚC 3 · KHÁM PHÁ',
      title: 'Sơ đồ Tầng & Chỉ đường',
      description:
          'Không lo lạc lối giữa các gian trưng bày. Bản đồ số tự động tính toán lộ trình ngắn nhất đưa bạn đến vị trí chính xác của hiện vật.',
      icon: Compass,
    },
  ];

  if (!open) {
    return (
      <button
        type="button"
        className="visitor-guidebook-float-btn"
        onClick={() => {
          setCurrentStep(0);
          setOpen(true);
        }}
        title="Mở Sổ tay hướng dẫn & Cẩm nang nhập môn"
      >
        <BookOpen size={18} />
        <span>Sổ tay hướng dẫn</span>
      </button>
    );
  }

  const current = steps[currentStep];
  const IconComponent = current.icon;

  return (
    <div className="onboarding-overlay" role="dialog" aria-modal="true">
      <div className="onboarding-card">
        {/* Header */}
        <div className="onboarding-header">
          <span className="onboarding-heritage-badge">SMGS • HƯỚNG DẪN NHẬP MÔN</span>
          <button
            type="button"
            className="onboarding-skip-btn"
            onClick={handleComplete}
            aria-label="Bỏ qua hướng dẫn"
          >
            Bỏ qua
          </button>
        </div>

        {/* Slide Content */}
        <div className="onboarding-body">
          <div className="onboarding-icon-wrapper">
            <IconComponent size={40} className="onboarding-icon" />
          </div>
          <span className="onboarding-step-badge">{current.badge}</span>
          <h2 className="onboarding-title">{current.title}</h2>
          <p className="onboarding-desc">{current.description}</p>
        </div>

        {/* Footer */}
        <div className="onboarding-footer">
          <div className="onboarding-dots">
            {steps.map((_, idx) => (
              <span
                key={idx}
                className={`onboarding-dot ${idx === currentStep ? 'active' : ''}`}
              />
            ))}
          </div>

          <button
            type="button"
            className="onboarding-action-btn"
            onClick={() => {
              if (currentStep < steps.length - 1) {
                setCurrentStep(s => s + 1);
              } else {
                handleComplete();
              }
            }}
          >
            {currentStep === steps.length - 1 ? (
              <>
                <span>Bắt đầu khám phá</span>
                <CheckCircle2 size={18} />
              </>
            ) : (
              <>
                <span>Tiếp tục</span>
                <ChevronRight size={18} />
              </>
            )}
          </button>
        </div>
      </div>
    </div>
  );
}
