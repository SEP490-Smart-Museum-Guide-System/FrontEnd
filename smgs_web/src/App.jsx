import './components/common/business.css';
import './components/common/refined.css';
import QuestionBank from './components/curation/QuestionBank';
import TopicManager from './components/artifacts/TopicManager';
import BadgeManager from './components/analytics/BadgeManager';
import CommerceManager from './components/transactions/CommerceManager';
import React, { useState } from 'react';
import { ShieldAlert, CreditCard } from 'lucide-react';
import { useApp } from './context/AppContext';
import Header from './components/layout/Header';
import Sidebar from './components/layout/Sidebar';
import RoleDashboard from './components/analytics/RoleDashboard';
import ArtifactList from './components/artifacts/ArtifactList';
import AIContentStudio from './components/ai_studio/AIContentStudio';
import CurationCenter from './components/curation/CurationCenter';
import SubmissionStatus from './components/curation/SubmissionStatus';
import MuseumManager from './components/museums/MuseumManager';
import MuseumStructureTree from './components/museums/MuseumStructureTree';

import TourManager from './components/tours/TourManager';
import ReviewManager from './components/reviews/ReviewManager';
import UserManager from './components/users/UserManager';
import TransactionManager from './components/transactions/TransactionManager';
import AuditLogs from './components/logs/AuditLogs';
import SystemOperations from './components/operations/SystemOperations';
import ToastContainer from './components/common/ToastContainer';
import LoginScreen from './components/auth/LoginScreen';
import IndoorMapManager from './components/indoor_maps/IndoorMapManager';

export default function App() {
  const { activeTab, setActiveTab, isAuthenticated, currentMuseum, currentRole, dataErrors, loading, reload } = useApp();
  const [selectedStudioArtifact, setSelectedStudioArtifact] = useState(null);
  const [selectedStudioMode, setSelectedStudioMode] = useState('narration');
  const [questionDrafts, setQuestionDrafts] = useState(null);

  const handleOpenAIStudio = (artifact, mode = 'narration') => {
    setSelectedStudioArtifact(artifact);
    setSelectedStudioMode(mode);
    setActiveTab('ai_studio');
  };

  const renderContent = () => {
    const sources = { overview: Object.keys(loading), artifacts: ['artifacts'], curation_artifacts: ['artifacts'], ai_studio: ['museums', 'artifacts'], museums: ['museums'], spaces: ['museums'], users: [], transactions: [], tours: ['tours'], reviews: ['reviews'], review_moderation: ['reviews'], support: ['systemCases'], curation_queue: ['curationQueue'], submission_status: ['curationQueue'] }[activeTab] || [];
    if (sources.some(key => loading[key])) return <p role="status">Đang tải dữ liệu…</p>;
    if (sources.some(key => dataErrors[key])) return <p role="alert">Chưa tải được dữ liệu cho màn hình này. Hãy thử lại bằng nút phía trên.</p>;
    if (activeTab === 'audit') {
      return (
        <div className="card" style={{ padding: '40px 24px', textAlign: 'center', maxWidth: '640px', margin: '40px auto' }}>
          <ShieldAlert size={40} color="var(--color-burgundy-700)" style={{ margin: '0 auto 16px' }} />
          <h3 style={{ fontSize: '1.125rem', fontWeight: '700', color: 'var(--color-burgundy-900)', marginBottom: '8px' }}>
            Nhật ký kiểm toán hệ thống
          </h3>
          <p style={{ fontSize: '0.875rem', color: 'var(--color-charcoal-600)', lineHeight: '1.6', margin: 0 }}>
            Máy chủ hiện chưa kích hoạt API nhật ký kiểm toán trực tiếp cho giao diện quản trị. Mọi hoạt động bảo mật và giao dịch vẫn được lưu vết độc lập trên hệ thống máy chủ.
          </p>
        </div>
      );
    }
    if (activeTab === 'transactions' && currentRole === 'systemStaff') {
      return (
        <div className="card" style={{ padding: '40px 24px', textAlign: 'center', maxWidth: '640px', margin: '40px auto' }}>
          <CreditCard size={40} color="var(--color-burgundy-700)" style={{ margin: '0 auto 16px' }} />
          <h3 style={{ fontSize: '1.125rem', fontWeight: '700', color: 'var(--color-burgundy-900)', marginBottom: '8px' }}>
            Đối soát giao dịch hệ thống
          </h3>
          <p style={{ fontSize: '0.875rem', color: 'var(--color-charcoal-600)', lineHeight: '1.6', margin: 0 }}>
            Theo quy định phân quyền, quyền Nhân viên hệ thống theo dõi và hỗ trợ khiếu nại qua mục "Hỗ trợ & khiếu nại". Báo cáo doanh thu và đối soát chi tiết được phân quyền cho Quản trị viên và Nhân viên bảo tàng phụ trách.
          </p>
        </div>
      );
    }
    if (!currentMuseum && ['artifacts', 'curation_artifacts', 'ai_studio', 'curation_queue', 'submission_status', 'tours', 'reviews', 'spaces', 'topics', 'question_bank'].includes(activeTab)) {
      return <p role="status">{loading.museums ? 'Đang tải bảo tàng…' : 'Chưa có bảo tàng để hiển thị. Hãy tải lại hoặc kiểm tra phân công tài khoản.'}</p>;
    }
    switch (activeTab) {
      case 'overview':
        return <RoleDashboard onNavigate={setActiveTab} />;
      case 'indoor_maps':
        return <IndoorMapManager />;
      case 'museums':
        return <MuseumManager />;
      case 'spaces':
        return <MuseumStructureTree />;
      case 'artifacts':
      case 'curation_artifacts':
        return <ArtifactList onOpenAIStudio={handleOpenAIStudio} />;
      case 'ai_studio':
        return <AIContentStudio initialArtifact={selectedStudioArtifact} initialMode={selectedStudioMode} onOpenQuestionBank={drafts => { setQuestionDrafts(drafts); setActiveTab('question_bank'); }} />;
      case 'curation_queue':
        return <CurationCenter />;
      case 'submission_status':
        return <SubmissionStatus />;
      case 'tours':
        return <TourManager />;
      case 'reviews':
        return <ReviewManager />;
      case 'support':
      case 'refunds':
      case 'review_moderation':
      case 'operations':
        return <SystemOperations mode={activeTab} />;
      case 'topics':
        return ['administrator', 'museumStaff'].includes(currentRole) ? <TopicManager key={currentMuseum?.id} /> : null;
      case 'question_bank':
        return ['administrator', 'museumStaff', 'curator'].includes(currentRole) ? <QuestionBank key={currentMuseum?.id} imported={questionDrafts} onOpenAI={artifact => handleOpenAIStudio(artifact, 'quiz')} /> : null;
      case 'badges':
        return currentRole === 'administrator' ? <BadgeManager /> : null;
      case 'users':
        return <UserManager />;
      case 'transactions':
        return <CommerceManager />;
      case 'audit':
        return <AuditLogs />;
      default:
        return <RoleDashboard onNavigate={setActiveTab} />;
    }
  };

  if (!isAuthenticated) return <LoginScreen />;

  return (
    <div className="app-container">
      {/* Sidebar navigation */}
      <Sidebar />

      {/* Main Content Area */}
      <div className="main-content">
        <Header />
        <main className="page-body">
          {Object.values(loading).some(Boolean) && <p role="status">Đang tải dữ liệu từ máy chủ…</p>}
          {Object.values(dataErrors).some(Boolean) && <details className="business-error"><summary>Một số dữ liệu chưa tải được</summary>{[...new Set(Object.values(dataErrors).filter(Boolean))].map(error => <p key={error}>{error}</p>)}<button className="btn btn-secondary btn-sm" onClick={reload}>Tải lại dữ liệu</button></details>}
          {renderContent()}
        </main>
      </div>

      {/* Global Toast Alert Layer */}
      <ToastContainer />
      
    </div>
  );
}
