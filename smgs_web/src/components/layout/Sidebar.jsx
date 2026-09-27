import React from 'react';
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
  FileText
} from 'lucide-react';

export default function Sidebar() {
  const { currentRole, currentMuseum, activeTab, setActiveTab, curationQueue, reviews, artifacts } = useApp();

  const museumArtifactIds = new Set(artifacts.filter(item => item.museumId === currentMuseum.id).map(item => item.id));
  const pendingCuration = curationQueue.filter(c => c.status === 'pending' && museumArtifactIds.has(c.targetArtifactId)).length;
  const pendingReviews = reviews.filter(r => r.status === 'pending_reply' && r.museumName === currentMuseum.name).length;

  // Navigation schema per role
  const getNavSections = () => {
    if (currentRole === 'administrator') {
      return [
        {
          title: 'Quản trị hệ thống',
          items: [
            { id: 'overview', label: 'Tổng quan hệ thống', icon: LayoutDashboard },
            { id: 'museums', label: 'Bảo tàng & Không gian', icon: Landmark },
            { id: 'artifacts', label: 'Kho hiện vật', icon: Layers },
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
    } else if (currentRole === 'curator') {
      return [
        {
          title: 'Trung tâm Giám định & Duyệt',
          items: [
            { id: 'overview', label: 'Tổng quan kiểm duyệt', icon: LayoutDashboard },
            { id: 'curation_queue', label: 'Hàng đợi Kiểm duyệt', icon: CheckSquare, badge: pendingCuration },
            { id: 'curation_artifacts', label: 'Hiện vật & Thuyết minh', icon: Layers },
            { id: 'reviews', label: 'Đánh giá từ Khách', icon: MessageSquare, badge: pendingReviews },
          ]
        },
        {
          title: 'Báo cáo & Lịch sử',
          items: [
            { id: 'audit', label: 'Lịch sử Phê duyệt', icon: FileText },
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
            { id: 'artifacts', label: 'Quản lý Hiện vật & QR', icon: Layers },
            { id: 'ai_studio', label: 'Xưởng nội dung AI', icon: Sparkles, highlight: true },
          ]
        },
        {
          title: 'Không gian & Trải nghiệm',
          items: [
            { id: 'spaces', label: 'Cấu trúc Không gian', icon: Building2 },
            { id: 'tours', label: 'Hành trình & triển lãm', icon: Compass },
          ]
        }
      ];
    }
  };

  const navSections = getNavSections();

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
          <div key={sIdx} style={{ marginBottom: '12px' }}>
            <div className="sidebar-section-title">{sec.title}</div>
            {sec.items.map(item => {
              const Icon = item.icon;
              const isActive = activeTab === item.id;
              return (
                <button
                  key={item.id}
                  type="button"
                  onClick={() => setActiveTab(item.id)}
                  className={`sidebar-item ${isActive ? 'active' : ''}`}
                  style={item.highlight ? { color: 'var(--color-gold-400)', fontWeight: '600' } : {}}
                >
                  <Icon size={18} color={item.highlight && !isActive ? 'var(--color-gold-400)' : 'currentColor'} />
                  <span>{item.label}</span>
                  {item.badge !== undefined && item.badge > 0 && (
                    <span className="badge">{item.badge}</span>
                  )}
                </button>
              );
            })}
          </div>
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
      </div>
    </aside>
  );
}
