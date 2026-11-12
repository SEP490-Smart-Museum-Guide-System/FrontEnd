import React, { useEffect, useState } from 'react';
import { useApp } from '../../context/AppContext';
import {
  LayoutDashboard,
  Layers,
  Sparkles,
  Building2,
  Compass,
  CheckSquare,
  MessageSquare,
  Users,
  CreditCard,
  ShieldAlert,
  Landmark,
  FileText,
  LifeBuoy,
  Activity,
  RotateCcw,
  Map
} from 'lucide-react';

export default function Sidebar() {
  const { currentRole, currentMuseum, activeTab, setActiveTab, curationQueue, reviews, artifacts } = useApp();

  const museumArtifactIds = new Set(artifacts.filter(item => item.museumId === currentMuseum?.id).map(item => item.id));
  const pendingCuration = curationQueue.filter(c => c.status === 'pending_review' && museumArtifactIds.has(c.targetArtifactId)).length;
  const pendingReviews = reviews.filter(r => r.status === 'pending_reply' && r.museumName === currentMuseum?.name).length;

  // Navigation schema per role
  const getNavSections = () => {
    if (currentRole === 'administrator') {
      return [
        {
          title: 'Quản trị hệ thống',
          items: [
            { id: 'overview', label: 'Tổng quan hệ thống', icon: LayoutDashboard },
            { id: 'museums', label: 'Quản lý bảo tàng', icon: Landmark },
            { id: 'indoor_maps', label: 'Bản đồ trong bảo tàng', icon: Compass },
            { id: 'artifacts', label: 'Kho hiện vật', icon: Layers },
            { id: 'topics', label: 'Chủ đề hiện vật', icon: Layers },
            { id: 'question_bank', label: 'Ngân hàng câu hỏi', icon: CheckSquare },
            { id: 'ai_studio', label: 'Xưởng nội dung AI', icon: Sparkles },
            { id: 'badges', label: 'Huy hiệu khám phá', icon: Sparkles },
          ]
        },
        {
          title: 'Vận hành & Kinh doanh',
          items: [
            { id: 'users', label: 'Người dùng & Phân quyền', icon: Users },
            { id: 'transactions', label: 'Dịch vụ số & giao dịch', icon: CreditCard },
          ]
        },
        {
          title: 'Kiểm toán & Cấu hình',
          items: [
            { id: 'audit', label: 'Nhật ký hệ thống', icon: ShieldAlert },
          ]
        }
      ];
  } else if (currentRole === 'systemStaff') {
      return [
        {
        title: 'Hỗ trợ & vận hành hệ thống',
          items: [
          { id: 'overview', label: 'Tổng quan vận hành', icon: LayoutDashboard },
          { id: 'support', label: 'Hỗ trợ & khiếu nại', icon: LifeBuoy },
          { id: 'refunds', label: 'Yêu cầu hoàn tiền', icon: RotateCcw },
          { id: 'transactions', label: 'Đối soát giao dịch', icon: CreditCard },
          { id: 'review_moderation', label: 'Kiểm duyệt phản hồi', icon: MessageSquare },
          { id: 'operations', label: 'Lỗi vận hành & chất lượng AI', icon: Activity },
          ]
        },
        {
        title: 'Theo dõi toàn hệ thống',
          items: [
          { id: 'audit', label: 'Nhật ký vận hành', icon: FileText },
          ]
        }
      ];
    } else if (currentRole === 'curator') {
      return [
        {
          title: 'Thẩm định nội dung bảo tàng',
          items: [
            { id: 'overview', label: 'Tổng quan thẩm định', icon: LayoutDashboard },
            { id: 'curation_queue', label: 'Hàng đợi phê duyệt', icon: CheckSquare, badge: pendingCuration, highlight: true },
            { id: 'artifacts', label: 'Tra cứu hiện vật', icon: Layers },
            { id: 'question_bank', label: 'Thẩm định câu hỏi & quiz', icon: CheckSquare },
          ]
        },
        {
          title: 'Theo dõi',
          items: [
            { id: 'audit', label: 'Nhật ký thẩm định', icon: FileText },
          ]
        }
      ];
    } else {
      // museumStaff
      return [
        {
          title: 'Bàn làm việc Nghiệp vụ',
          items: [
            { id: 'overview', label: 'Bàn làm việc', icon: LayoutDashboard },
            { id: 'spaces', label: 'Cấu trúc bảo tàng', icon: Building2 },
            { id: 'indoor_maps', label: 'Bản đồ trong bảo tàng', icon: Compass },
            { id: 'artifacts', label: 'Quản lý Hiện vật & QR', icon: Layers },
            { id: 'topics', label: 'Chủ đề hiện vật', icon: Layers },
            { id: 'question_bank', label: 'Ngân hàng câu hỏi', icon: CheckSquare },
            { id: 'ai_studio', label: 'Xưởng nội dung AI', icon: Sparkles, highlight: true },
            { id: 'submission_status', label: 'Đệ trình & phản hồi Giám tuyển', icon: CheckSquare, badge: pendingCuration },
          ]
        },
        {
          title: 'Trải nghiệm & báo cáo bảo tàng',
          items: [
            { id: 'tours', label: 'Tuyến tham quan & nội dung trả phí', icon: Compass },
            { id: 'reviews', label: 'Phản hồi về bảo tàng', icon: MessageSquare, badge: pendingReviews },
            { id: 'transactions', label: 'Doanh thu bảo tàng', icon: CreditCard },
          ]
        }
      ];
    }
  };

  const original = getNavSections().flatMap(section => section.items);
  const groups = currentRole === 'administrator' ? [
    ['Tổng quan & quản trị', ['overview', 'museums', 'users']],
    ['Nội dung & trải nghiệm', ['artifacts', 'indoor_maps', 'topics', 'ai_studio', 'question_bank', 'badges']],
    ['Kinh doanh & nhật ký', ['transactions', 'audit']],
  ] : currentRole === 'museumStaff' ? [
    ['Công việc chính', ['overview', 'artifacts', 'ai_studio', 'submission_status']],
    ['Không gian & trải nghiệm', ['spaces', 'indoor_maps', 'topics', 'question_bank', 'tours']],
    ['Phản hồi & doanh thu', ['reviews', 'transactions']],
  ] : currentRole === 'curator' ? [
    ['Thẩm định', ['overview', 'curation_queue', 'question_bank']],
    ['Tra cứu & nhật ký', ['artifacts', 'audit']],
  ] : [
    ['Hỗ trợ khách', ['overview', 'support', 'refunds']],
    ['Giám sát hệ thống', ['review_moderation', 'operations', 'transactions', 'audit']],
  ];
  const navSections = groups.map(([title, ids]) => ({ title, items: ids.map(id => original.find(item => item.id === id)).filter(Boolean) }));
  const activeSection = navSections.find(section => section.items.some(item => item.id === activeTab))?.title;
  const [expanded, setExpanded] = useState(() => new Set([navSections[0].title, activeSection]));
  useEffect(() => { setExpanded(previous => new Set([...previous, activeSection])); }, [activeSection]);

  return (
    <aside className="sidebar">
      {/* Sidebar Header */}
      <div className="sidebar-header">
        <div className="sidebar-logo-icon">
          <span>🏛</span>
        </div>
        <div className="sidebar-brand-text">
          <h1>SMGS · DI SẢN</h1>
          <p>Không gian nghiệp vụ</p>
        </div>
      </div>

      {/* Navigation Menu */}
      <div className="sidebar-menu">
        {navSections.map((sec, sIdx) => (
          <section key={sec.title} className="nav-section">
            <button type="button" className="nav-section-toggle" aria-expanded={expanded.has(sec.title)} aria-controls={`nav-section-${sIdx}`} onClick={() => setExpanded(previous => { const next = new Set(previous); if (next.has(sec.title)) next.delete(sec.title); else next.add(sec.title); return next; })}>{sec.title}<span aria-hidden="true">{expanded.has(sec.title) ? '−' : '+'}</span></button>
            <div id={`nav-section-${sIdx}`} hidden={!expanded.has(sec.title)}>
            {sec.items.map(item => {
              const Icon = item.icon;
              const isActive = activeTab === item.id;
              return (
                <button
                  key={item.id}
                  type="button"
                  onClick={() => setActiveTab(item.id)}
                  className={`sidebar-item ${isActive ? 'active' : ''}`}
                  aria-current={isActive ? 'page' : undefined}
                >
                  <Icon size={18} />
                  <span>{item.label}</span>
                  {item.badge !== undefined && item.badge > 0 && (
                    <span className="badge">{item.badge}</span>
                  )}
                </button>
              );
            })}
            </div>
          </section>
        ))}
      </div>

      {/* Sidebar Footer */}
      <div className="sidebar-footer">
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span style={{
              width: '8px',
              height: '8px',
              borderRadius: '50%',
              background: '#22C55E',
              boxShadow: '0 0 8px #22C55E'
            }} />
            <span style={{ fontSize: '0.75rem', color: 'var(--color-gold-100)' }}>Bản giao diện thử nghiệm</span>
          </div>
        </div>
        <small style={{ display: 'block', marginTop: '8px', color: 'var(--color-gold-100)' }}>Khách tham quan sử dụng ứng dụng di động.</small>
      </div>
    </aside>
  );
}
