import React, { useState } from 'react';
import { useApp } from './context/AppContext';
import Header from './components/layout/Header';
import Sidebar from './components/layout/Sidebar';
import RoleDashboard from './components/analytics/RoleDashboard';
import ArtifactList from './components/artifacts/ArtifactList';
import AIContentStudio from './components/ai_studio/AIContentStudio';
import CurationCenter from './components/curation/CurationCenter';
import MuseumManager from './components/museums/MuseumManager';
import TourManager from './components/tours/TourManager';
import ReviewManager from './components/reviews/ReviewManager';
import UserManager from './components/users/UserManager';
import TransactionManager from './components/transactions/TransactionManager';
import AuditLogs from './components/logs/AuditLogs';
import ToastContainer from './components/common/ToastContainer';

export default function App() {
  const { activeTab, setActiveTab } = useApp();
  const [selectedStudioArtifact, setSelectedStudioArtifact] = useState(null);

  const handleOpenAIStudio = (artifact) => {
    setSelectedStudioArtifact(artifact);
    setActiveTab('ai_studio');
  };

  const renderContent = () => {
    switch (activeTab) {
      case 'overview':
        return <RoleDashboard onNavigate={setActiveTab} />;
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
      case 'tours':
        return <TourManager />;
      case 'reviews':
        return <ReviewManager />;
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

  return (
    <div className="app-container">
      {/* Sidebar navigation */}
      <Sidebar />

      {/* Main Content Area */}
      <div className="main-content">
        <Header />
        <main className="page-body">
          {renderContent()}
        </main>
      </div>

      {/* Global Toast Alert Layer */}
      <ToastContainer />
    </div>
  );
}
