import React, { useState } from 'react';
import { useApp } from './context/AppContext';
import Header from './components/layout/Header';
import Sidebar from './components/layout/Sidebar';
import RoleDashboard from './components/analytics/RoleDashboard';
import ArtifactList from './components/artifacts/ArtifactList';
import AIContentStudio from './components/ai_studio/AIContentStudio';
import CurationCenter from './components/curation/CurationCenter';
import SubmissionStatus from './components/curation/SubmissionStatus';
import MuseumManager from './components/museums/MuseumManager';

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

  const handleOpenAIStudio = (artifact) => {
    setSelectedStudioArtifact(artifact);
    setActiveTab('ai_studio');
  };

  const renderContent = () => {
    const sources = { overview: Object.keys(loading), artifacts: ['artifacts'], curation_artifacts: ['artifacts'], museums: ['museums'], spaces: ['museums'], users: ['users'], transactions: ['transactions', 'passPackages'], tours: ['tours'], reviews: ['reviews'], review_moderation: ['reviews'], support: ['systemCases'], curation_queue: ['curationQueue'], submission_status: ['curationQueue'] }[activeTab] || [];
    if (sources.some(key => loading[key])) return <p role="status">Đang tải dữ liệu…</p>;
    if (sources.some(key => dataErrors[key])) return <p role="alert">Chưa tải được dữ liệu cho màn hình này. Hãy thử lại bằng nút phía trên.</p>;
    if (activeTab === 'audit') return <p role="status">Máy chủ chưa cung cấp API nhật ký hệ thống.</p>;
    if (activeTab === 'refunds') return <p role="status">Máy chủ chưa cung cấp API yêu cầu hoàn tiền. Chưa có dữ liệu để hiển thị.</p>;
    if (activeTab === 'transactions' && currentRole === 'systemStaff') return <p role="status">API giao dịch hiện chưa hỗ trợ quyền Nhân viên hệ thống.</p>;
    if (!currentMuseum && ['artifacts', 'curation_artifacts', 'ai_studio', 'curation_queue', 'submission_status', 'tours', 'reviews', 'spaces'].includes(activeTab)) {
      return <p role="status">{loading.museums ? 'Đang tải bảo tàng…' : 'Chưa có bảo tàng để hiển thị. Hãy tải lại hoặc kiểm tra phân công tài khoản.'}</p>;
    }
    switch (activeTab) {
      case 'overview':
        return <RoleDashboard onNavigate={setActiveTab} />;
      case 'indoor_maps':
        return <IndoorMapManager />;
      case 'museums':
      case 'spaces':
        return <MuseumManager />;
      case 'artifacts':
      case 'curation_artifacts':
        return <ArtifactList onOpenAIStudio={handleOpenAIStudio} />;
      case 'ai_studio':
        return <AIContentStudio initialArtifact={selectedStudioArtifact} />;
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
      case 'users':
        return <UserManager />;
      case 'transactions':
        return <TransactionManager />;
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
          {Object.entries(dataErrors).filter(([, error]) => error).map(([key, error]) => <p role="alert" key={key}>{error} <button className="btn btn-secondary btn-sm" onClick={reload}>Thử lại</button></p>)}
          {renderContent()}
        </main>
      </div>

      {/* Global Toast Alert Layer */}
      <ToastContainer />
    </div>
  );
}
