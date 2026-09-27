import React, { createContext, useContext, useState, useEffect } from 'react';
import {
  initialMuseums,
  initialArtifacts,
  initialTours,
  initialExhibitions,
  initialCurationQueue,
  initialUsers,
  initialPassPackages,
  initialTransactions,
  initialReviews,
  initialAuditLogs
} from '../data/mockData';

const AppContext = createContext();

export function AppProvider({ children }) {
  // Current active staff/admin role
  const [currentRole, setCurrentRole] = useState(() => {
    return localStorage.getItem('smgs_web_role') || 'administrator';
  });

  // Active selected museum for staff/curator/admin scope
  const [selectedMuseumId, setSelectedMuseumId] = useState('mus-01');

  // Navigation tab
  const [activeTab, setActiveTab] = useState('overview');

  // Core data states
  const [museums, setMuseums] = useState(initialMuseums);
  const [artifacts, setArtifacts] = useState(initialArtifacts);
  const [tours, setTours] = useState(initialTours);
  const [exhibitions, setExhibitions] = useState(initialExhibitions);
  const [curationQueue, setCurationQueue] = useState(initialCurationQueue);
  const [users, setUsers] = useState(initialUsers);
  const [passPackages, setPassPackages] = useState(initialPassPackages);
  const [transactions, setTransactions] = useState(initialTransactions);
  const [reviews, setReviews] = useState(initialReviews);
  const [auditLogs, setAuditLogs] = useState(initialAuditLogs);

  // Global Toast Notifications
  const [toasts, setToasts] = useState([]);

  // Sync role to localStorage
  useEffect(() => {
    localStorage.setItem('smgs_web_role', currentRole);
  }, [currentRole]);

  const showToast = (message, type = 'success') => {
    const id = Date.now() + Math.random();
    setToasts(prev => [...prev, { id, message, type }]);
    setTimeout(() => {
      setToasts(prev => prev.filter(t => t.id !== id));
    }, 4000);
  };

  const logAction = (action, details) => {
    const currentUser = users.find(u => u.role === currentRole) || users[0];
    const newLog = {
      id: `log-${Date.now()}`,
      timestamp: new Date().toISOString().replace('T', ' ').slice(0, 16),
      user: `${currentUser.name} (${currentUser.email})`,
      role: currentRole === 'administrator' ? 'Administrator' : currentRole === 'curator' ? 'Curator' : 'Museum Staff',
      action,
      details
    };
    setAuditLogs(prev => [newLog, ...prev]);
  };

  // Artifact Actions
  const addArtifact = (newArt) => {
    const artWithId = {
      ...newArt,
      id: `art-${String(Date.now()).slice(-4)}`,
      code: `SMGS-ART-${String(artifacts.length + 1).padStart(3, '0')}`,
      qrCode: `SMGS-QR-VNMH-${String(artifacts.length + 1).padStart(3, '0')}`,
      viewsCount: 0,
      scansCount: 0,
      quizPassRate: '0%',
      quizzes: newArt.quizzes || [],
      multilingual: newArt.multilingual || {}
    };
    setArtifacts(prev => [artWithId, ...prev]);
    logAction('ARTIFACT_CREATE', `Thêm mới hiện vật: ${artWithId.name}`);
    showToast(`Đã thêm hiện vật "${artWithId.name}" thành công!`);
  };

  const updateArtifact = (updatedArt) => {
    setArtifacts(prev => prev.map(a => a.id === updatedArt.id ? updatedArt : a));
    logAction('ARTIFACT_UPDATE', `Cập nhật thông tin hiện vật: ${updatedArt.name}`);
    showToast(`Đã lưu thay đổi hiện vật "${updatedArt.name}"!`);
  };

  const deleteArtifact = (id) => {
    const target = artifacts.find(a => a.id === id);
    setArtifacts(prev => prev.filter(a => a.id !== id));
    logAction('ARTIFACT_DELETE', `Xóa hiện vật: ${target ? target.name : id}`);
    showToast(`Đã xóa hiện vật khỏi hệ thống!`, 'warning');
  };

  // Curation Actions
  const submitToCuration = (item) => {
    const newItem = {
      ...item,
      id: `cur-${String(Date.now()).slice(-3)}`,
      submittedDate: new Date().toISOString().replace('T', ' ').slice(0, 16),
      status: 'pending'
    };
    setCurationQueue(prev => [newItem, ...prev]);
    logAction('CURATION_SUBMIT', `Gửi nội dung vào hàng đợi kiểm duyệt: ${newItem.title}`);
    showToast(`Nội dung đã được gửi vào hàng đợi kiểm duyệt!`);
  };

  const approveCurationItem = (id, note = '') => {
    const item = curationQueue.find(c => c.id === id);
    if (!item) return;

    setCurationQueue(prev => prev.map(c => c.id === id ? { ...c, status: 'approved', feedback: note } : c));
    logAction('CURATION_APPROVE', `Phê duyệt và xuất bản: ${item.title}`);
    showToast(`Đã phê duyệt và xuất bản thành công!`);
  };

  const rejectCurationItem = (id, reason) => {
    const item = curationQueue.find(c => c.id === id);
    if (!item) return;

    setCurationQueue(prev => prev.map(c => c.id === id ? { ...c, status: 'rejected', feedback: reason } : c));
    logAction('CURATION_REJECT', `Từ chối nội dung: ${item.title}. Lý do: ${reason}`);
    showToast(`Đã từ chối nội dung!`, 'warning');
  };

  const requestRevisionCurationItem = (id, feedback) => {
    const item = curationQueue.find(c => c.id === id);
    if (!item) return;

    setCurationQueue(prev => prev.map(c => c.id === id ? { ...c, status: 'revision_requested', feedback } : c));
    logAction('CURATION_REVISION_REQUEST', `Yêu cầu hiệu đính: ${item.title}. Góp ý: ${feedback}`);
    showToast(`Đã gửi yêu cầu hiệu chỉnh tới nhân viên!`, 'warning');
  };

  // Tour Actions
  const addTour = (newTour) => {
    const tourWithId = {
      ...newTour,
      id: `tour-${String(Date.now()).slice(-3)}`,
      code: `TOUR-SMGS-${String(tours.length + 1).padStart(2, '0')}`,
      rating: 5.0,
      reviewsCount: 0,
      status: 'published'
    };
    setTours(prev => [tourWithId, ...prev]);
    logAction('TOUR_CREATE', `Tạo lộ trình Tour mới: ${tourWithId.title}`);
    showToast(`Đã tạo tour "${tourWithId.title}" thành công!`);
  };

  // Review Replies
  const replyToReview = (reviewId, replyText) => {
    setReviews(prev => prev.map(r => {
      if (r.id === reviewId) {
        return {
          ...r,
          officialReply: replyText,
          replyDate: new Date().toISOString().replace('T', ' ').slice(0, 16),
          status: 'replied'
        };
      }
      return r;
    }));
    logAction('REVIEW_REPLY', `Phản hồi đánh giá của khách tham quan ID: ${reviewId}`);
    showToast('Đã gửi phản hồi chính thức từ bảo tàng!');
  };

  // Transactions / Refund
  const refundTransaction = (txnId) => {
    setTransactions(prev => prev.map(t => t.id === txnId ? { ...t, status: 'refunded' } : t));
    logAction('TRANSACTION_REFUND', `Hoàn tiền cho giao dịch: ${txnId}`);
    showToast(`Giao dịch ${txnId} đã được hoàn tiền thành công!`);
  };

  // Users
  const addUser = (newUser) => {
    const userWithId = {
      ...newUser,
      id: `usr-${String(Date.now()).slice(-3)}`,
      status: 'active',
      lastLogin: 'Chưa đăng nhập'
    };
    setUsers(prev => [...prev, userWithId]);
    logAction('USER_CREATE', `Thêm tài khoản nhân viên: ${newUser.name} (${newUser.email})`);
    showToast(`Đã tạo tài khoản cho ${newUser.name}!`);
  };

  const toggleUserStatus = (userId) => {
    setUsers(prev => prev.map(u => {
      if (u.id === userId) {
        const nextStatus = u.status === 'active' ? 'inactive' : 'active';
        logAction('USER_STATUS_CHANGE', `Chuyển trạng thái người dùng ${u.email} sang: ${nextStatus}`);
        return { ...u, status: nextStatus };
      }
      return u;
    }));
    showToast('Đã cập nhật trạng thái tài khoản!');
  };

  // Active museum helper
  const currentMuseum = museums.find(m => m.id === selectedMuseumId) || museums[0];

  return (
    <AppContext.Provider value={{
      currentRole,
      setCurrentRole,
      selectedMuseumId,
      setSelectedMuseumId,
      currentMuseum,
      activeTab,
      setActiveTab,
      museums,
      setMuseums,
      artifacts,
      addArtifact,
      updateArtifact,
      deleteArtifact,
      tours,
      addTour,
      exhibitions,
      curationQueue,
      submitToCuration,
      approveCurationItem,
      rejectCurationItem,
      requestRevisionCurationItem,
      users,
      addUser,
      toggleUserStatus,
      passPackages,
      transactions,
      refundTransaction,
      reviews,
      replyToReview,
      auditLogs,
      logAction,
      toasts,
      showToast
    }}>
      {children}
    </AppContext.Provider>
  );
}

export function useApp() {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error('useApp must be used within an AppProvider');
  }
  return context;
}
