import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
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
  initialAuditLogs,
  initialSystemCases
} from '../data/mockData';
import {
  getMuseumsApi,
  getCitiesApi,
  createMuseumApi,
  updateMuseumApi,
  deleteMuseumApi
} from '../services/museumApi';

const AppContext = createContext();

export function AppProvider({ children }) {
  // Current active staff/admin user account
  const [currentUser, setCurrentUser] = useState(() => {
    const savedEmail = localStorage.getItem('smgs_web_user_email');
    const user = initialUsers.find(u => u.email === savedEmail);
    return user || initialUsers[0]; // defaults to admin@smgs.vn
  });

  const [currentRole, setRoleState] = useState(() => {
    const savedEmail = localStorage.getItem('smgs_web_user_email');
    const user = initialUsers.find(u => u.email === savedEmail);
    if (user && ['administrator', 'systemStaff', 'museumStaff', 'curator'].includes(user.role)) {
      return user.role;
    }
    const savedRole = localStorage.getItem('smgs_web_role');
    return ['administrator', 'systemStaff', 'museumStaff', 'curator'].includes(savedRole) ? savedRole : 'administrator';
  });
  const [isAuthenticated, setIsAuthenticated] = useState(() => localStorage.getItem('smgs_web_authenticated') === 'true');

  // Bảo tàng mẫu đang được nhân viên bảo tàng phụ trách
  const [selectedMuseumId, setSelectedMuseumId] = useState(() => {
    const savedEmail = localStorage.getItem('smgs_web_user_email');
    const user = initialUsers.find(u => u.email === savedEmail);
    return user?.museumId && user.museumId !== 'all' ? user.museumId : 'mus-01';
  });

  // Navigation tab
  const [activeTab, setActiveTab] = useState('overview');

  const setCurrentRole = (role) => {
    if (!['administrator', 'systemStaff', 'museumStaff', 'curator'].includes(role)) return;
    const targetUser = users.find(u => u.role === role) || users[0];
    setCurrentUser(targetUser);
    setRoleState(role);
    if (targetUser.museumId && targetUser.museumId !== 'all') {
      setSelectedMuseumId(targetUser.museumId);
    }
    setActiveTab('overview');
  };

  const loginAccount = (account) => {
    if (!account) return;
    setCurrentUser(account);
    setRoleState(account.role);
    if (account.museumId && account.museumId !== 'all') {
      setSelectedMuseumId(account.museumId);
    }
    setActiveTab('overview');
    setIsAuthenticated(true);
    localStorage.setItem('smgs_web_authenticated', 'true');
    localStorage.setItem('smgs_web_user_email', account.email);
    localStorage.setItem('smgs_web_role', account.role);
    showToast(`Đã chuyển sang tài khoản: ${account.name} (${account.email})`);
  };

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
  const [systemCases, setSystemCases] = useState(initialSystemCases);

  // Global Toast Notifications
  const [toasts, setToasts] = useState([]);

  // Sync role to localStorage
  useEffect(() => {
    localStorage.setItem('smgs_web_role', currentRole);
  }, [currentRole]);

  const login = async (email, password) => {
    const cleanEmail = email.trim();
    try {
      const response = await fetch('http://localhost:5169/api/auth/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: JSON.stringify({ email: cleanEmail, password }),
      });

      const result = await response.json();
      if (response.ok && result.data?.accessToken) {
        const { accessToken, fullName, email: resEmail } = result.data;
        let role = 'administrator';
        try {
          const payload = JSON.parse(atob(accessToken.split('.')[1]));
          const roleClaim =
            payload['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] ||
            payload.role;
          const rawRole = Array.isArray(roleClaim) ? roleClaim[0] : roleClaim;
          if (rawRole === 'Admin') role = 'administrator';
          else if (rawRole === 'Museum Staff' || rawRole === 'MuseumStaff') role = 'museumStaff';
          else if (rawRole === 'Staff') role = 'systemStaff';
          else if (rawRole === 'Curator') role = 'curator';
          else if (rawRole === 'Visitor') role = 'visitor';
        } catch (_) {}

        if (role === 'visitor') {
          return {
            success: false,
            error: 'Tài khoản này là Khách tham quan (Visitor). Cổng web chỉ dành cho Quản trị viên (Admin) và Nhân viên nghiệp vụ (Staff/Curator). Vui lòng sử dụng app SMGS Mobile.'
          };
        }

        const activeUser = {
          id: resEmail,
          name: fullName || resEmail,
          email: resEmail,
          role: role,
          status: 'active',
          museumId: 'mus-01',
        };

        setCurrentUser(activeUser);
        setRoleState(role);
        if (activeUser.museumId && activeUser.museumId !== 'all') {
          setSelectedMuseumId(activeUser.museumId);
        }
        setActiveTab('overview');
        setIsAuthenticated(true);
        localStorage.setItem('smgs_web_authenticated', 'true');
        localStorage.setItem('smgs_web_user_email', resEmail);
        localStorage.setItem('smgs_web_role', role);
        localStorage.setItem('smgs_web_jwt_token', accessToken);
        showToast(`Đăng nhập thành công: ${fullName} (${role})`);
        return { success: true };
      } else {
        // Fallback kiểm tra tài khoản mẫu nếu chưa có trong DB
        const account = users.find(
          (user) =>
            user.email.toLowerCase() === cleanEmail.toLowerCase() &&
            user.status === 'active'
        );
        if (account && password === 'smgs123') {
          if (account.role === 'visitor') {
            window.location.assign('/visitor/?seed=khach');
            return { success: true };
          }
          loginAccount(account);
          return { success: true };
        }
        return {
          success: false,
          error: result.message || 'Email hoặc mật khẩu không chính xác.',
        };
      }
    } catch (err) {
      console.warn('Backend API connection failed, checking mock accounts...', err);
      const account = users.find(
        (user) =>
          user.email.toLowerCase() === cleanEmail.toLowerCase() &&
          user.status === 'active'
      );
      if (account && password === 'smgs123') {
        if (account.role === 'visitor') {
          window.location.assign('/visitor/?seed=khach');
          return { success: true };
        }
        loginAccount(account);
        return { success: true };
      }
      return {
        success: false,
        error:
          'Không thể kết nối đến máy chủ Backend (http://localhost:5169). Vui lòng kiểm tra Backend đang chạy.',
      };
    }
  };

  const logout = () => {
    setIsAuthenticated(false);
    localStorage.removeItem('smgs_web_authenticated');
    localStorage.removeItem('smgs_web_user_email');
    localStorage.removeItem('smgs_web_role');
    localStorage.removeItem('smgs_web_jwt_token');
    setActiveTab('overview');
  };

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
      role: currentRole === 'administrator' ? 'Quản trị viên' : currentRole === 'systemStaff' ? 'Nhân viên hệ thống' : currentRole === 'curator' ? 'Giám tuyển' : 'Nhân viên bảo tàng',
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
      qrCode: newArt.qrCode?.trim() || `SMGS-QR-${String(artifacts.length + 1).padStart(3, '0')}`,
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
      status: 'pending_review'
    };
    setCurationQueue(prev => [newItem, ...prev]);
    logAction('CURATION_SUBMIT', `Gửi nội dung vào hàng đợi kiểm duyệt: ${newItem.title}`);
    showToast(`Nội dung đã được gửi vào hàng đợi kiểm duyệt!`);
  };

  const approveCurationItem = (id, note = '') => {
    if (currentRole !== 'curator') return showToast('Chỉ Giám tuyển được phê duyệt nội dung.', 'warning');
    const item = curationQueue.find(entry => entry.id === id);
    if (!item) return;
    setCurationQueue(prev => prev.map(entry => entry.id === id ? { ...entry, status: 'published', feedback: note } : entry));
    if (item.targetArtifactId) {
      setArtifacts(prev => prev.map(artifact => artifact.id === item.targetArtifactId ? {
        ...artifact,
        status: 'published',
        approvedAiContent: [...(artifact.approvedAiContent || []), { type: item.type, title: item.title, content: item.proposedContent }]
      } : artifact));
    }
    logAction('CURATION_APPROVE', `Phê duyệt và xuất bản: ${item.title}`);
    showToast('Đã phê duyệt và xuất bản nội dung.');
  };

  const rejectCurationItem = (id, feedback) => {
    if (currentRole !== 'curator') return showToast('Chỉ Giám tuyển được từ chối nội dung.', 'warning');
    const item = curationQueue.find(entry => entry.id === id);
    if (!item) return;
    setCurationQueue(prev => prev.map(entry => entry.id === id ? { ...entry, status: 'rejected', feedback } : entry));
    logAction('CURATION_REJECT', `Từ chối nội dung: ${item.title}. ${feedback}`);
    showToast('Đã gửi lý do từ chối.', 'warning');
  };

  const requestRevisionCurationItem = (id, feedback) => {
    if (currentRole !== 'curator') return showToast('Chỉ Giám tuyển được yêu cầu hiệu đính.', 'warning');
    const item = curationQueue.find(entry => entry.id === id);
    if (!item) return;
    setCurationQueue(prev => prev.map(entry => entry.id === id ? { ...entry, status: 'draft', feedback } : entry));
    logAction('CURATION_REVISION_REQUEST', `Yêu cầu hiệu đính: ${item.title}. ${feedback}`);
    showToast('Đã gửi yêu cầu hiệu đính.', 'warning');
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
    logAction('TOUR_CREATE', `Tạo lộ trình tham quan mới: ${tourWithId.title}`);
    showToast(`Đã tạo tour "${tourWithId.title}" thành công!`);
  };

  const updateTour = (updatedTour) => {
    setTours(prev => prev.map(item => item.id === updatedTour.id ? { ...item, ...updatedTour } : item));
    logAction('TOUR_UPDATE', `Cập nhật tour ${updatedTour.title}`);
    showToast(`Đã cập nhật tour "${updatedTour.title}".`);
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

  const refundTransaction = (txnId) => {
    setTransactions(prev => prev.map(t => t.id === txnId ? { ...t, status: 'refunded' } : t));
    logAction('TRANSACTION_REFUND', `Hoàn tiền cho giao dịch: ${txnId}`);
    showToast(`Giao dịch ${txnId} đã được hoàn tiền thành công!`);
  };

  const updateSystemCase = (caseId, status, note = '') => {
    const target = systemCases.find(item => item.id === caseId);
    if (!target) return;
    if (target.type === 'refund' && status === 'resolved' && target.transactionId) {
      refundTransaction(target.transactionId);
    }
    setSystemCases(prev => prev.map(item => item.id === caseId ? { ...item, status, note } : item));
    logAction('SYSTEM_CASE_UPDATE', `${caseId}: ${status}${note ? ` · ${note}` : ''}`);
    showToast(`Đã cập nhật yêu cầu ${caseId}.`);
  };

  const moderateReview = (reviewId, hidden) => {
    setReviews(prev => prev.map(item => item.id === reviewId ? { ...item, hidden } : item));
    logAction('REVIEW_MODERATE', `${hidden ? 'Ẩn' : 'Hiện lại'} phản hồi ${reviewId}`);
    showToast(hidden ? 'Đã ẩn phản hồi không phù hợp.' : 'Đã hiện lại phản hồi.');
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

  // Cities & Backend Museum Synchronization
  const [cities, setCities] = useState([]);
  const [isLoadingMuseums, setIsLoadingMuseums] = useState(false);

  const loadCities = useCallback(async () => {
    try {
      const res = await getCitiesApi();
      if (res?.data) {
        setCities(res.data);
      }
    } catch (err) {
      console.warn('Backend cities API offline, using fallback:', err.message);
    }
  }, []);

  const loadMuseums = useCallback(async () => {
    setIsLoadingMuseums(true);
    try {
      const res = await getMuseumsApi({ page: 1, pageSize: 50 });
      const items = res?.data?.items;
      if (items && items.length > 0) {
        setMuseums(prevMuseums => {
          return items.map((item) => {
            const match = prevMuseums.find(
              m => m.id === item.id || m.backendId === item.id || m.name.toLowerCase() === item.name.toLowerCase()
            ) || initialMuseums.find(
              m => m.name.toLowerCase() === item.name.toLowerCase()
            );

            return {
              id: item.id,
              backendId: item.id,
              name: item.name,
              shortName: match?.shortName || item.name,
              code: match?.code || `MUS-${String(item.id).padStart(2, '0')}`,
              address: item.address || '',
              cityCode: item.cityCode || '01',
              latitude: item.latitude !== null && item.latitude !== undefined ? Number(item.latitude) : (match?.latitude || 21.0257),
              longitude: item.longitude !== null && item.longitude !== undefined ? Number(item.longitude) : (match?.longitude || 105.8584),
              openingHours: item.openingHours || match?.openingHours || '08:00 - 17:00 (Thứ 3 - Chủ nhật)',
              image: item.coverImageUrl || match?.image || '/assets/images/national-museum-web.jpg',
              description: item.description || match?.description || '',
              artifactCount: match?.artifactCount || 0,
              visitorCountToday: match?.visitorCountToday || 0,
              status: item.isActive ? 'active' : 'inactive',
              googleMapsVisible: item.isActive,
              mapPosition: match?.mapPosition || { x: 50, y: 50 },
              buildings: match?.buildings || [
                {
                  id: `bld-${item.id}-01`,
                  name: 'Tòa nhà chính',
                  code: 'A',
                  floors: [
                    {
                      id: `flr-${item.id}-01`,
                      name: 'Tầng 1 — Trưng bày chuyên đề',
                      number: 1,
                      galleries: [
                        { id: `gal-${item.id}-01`, name: 'Phòng Trưng bày Trung tâm', code: 'A1-MAIN', artifactCount: 0, theme: 'Hiện vật tổng quan' }
                      ]
                    }
                  ]
                }
              ]
            };
          });
        });
      }
    } catch (err) {
      console.warn('Backend museums API unavailable, preserving current museums:', err.message);
    } finally {
      setIsLoadingMuseums(false);
    }
  }, []);

  // Sync cities and museums when authenticated
  useEffect(() => {
    if (isAuthenticated) {
      loadCities();
      loadMuseums();
    }
  }, [isAuthenticated, loadCities, loadMuseums]);

  // Admin CRUD for Museums connected to Backend
  const createMuseum = async (formData) => {
    try {
      const res = await createMuseumApi(formData);
      const createdItem = res?.data;
      if (createdItem) {
        logAction('MUSEUM_CREATE', `Tạo bảo tàng mới: ${createdItem.name} (ID: ${createdItem.id})`);
        showToast(`Đã tạo bảo tàng "${createdItem.name}" thành công trên máy chủ!`);
        await loadMuseums();
        return { success: true, data: createdItem };
      }
      return { success: false, error: 'Không nhận được dữ liệu phản hồi từ máy chủ.' };
    } catch (err) {
      const msg = err.message || 'Lỗi khi tạo bảo tàng mới trên Backend';
      showToast(msg, 'warning');
      return { success: false, error: msg };
    }
  };

  const updateMuseum = async (id, formData) => {
    try {
      const target = museums.find(m => m.id === id);
      const backendId = target?.backendId || (typeof id === 'number' ? id : null);
      if (backendId) {
        await updateMuseumApi(backendId, formData);
      }
      setMuseums(prev => prev.map(m => m.id === id ? { ...m, ...formData, backendId: backendId || m.backendId } : m));
      logAction('MUSEUM_UPDATE', `Cập nhật thông tin bảo tàng: ${formData.name || target?.name}`);
      showToast(`Đã lưu thay đổi cho bảo tàng "${formData.name || target?.name}"!`);
      return { success: true };
    } catch (err) {
      const msg = err.message || 'Lỗi khi cập nhật thông tin bảo tàng';
      showToast(msg, 'warning');
      return { success: false, error: msg };
    }
  };

  const deleteMuseum = async (id) => {
    try {
      const target = museums.find(m => m.id === id);
      const backendId = target?.backendId || (typeof id === 'number' ? id : null);
      if (backendId) {
        await deleteMuseumApi(backendId);
      }
      setMuseums(prev => prev.map(m => m.id === id ? { ...m, status: 'inactive', googleMapsVisible: false } : m));
      logAction('MUSEUM_DELETE', `Vô hiệu hóa bảo tàng: ${target?.name}`);
      showToast(`Đã vô hiệu hóa bảo tàng "${target?.name}" trên hệ thống!`, 'warning');
      return { success: true };
    } catch (err) {
      const msg = err.message || 'Lỗi khi vô hiệu hóa bảo tàng';
      showToast(msg, 'warning');
      return { success: false, error: msg };
    }
  };

  // Google Maps công khai
  const toggleMuseumGoogleMapsVisibility = (museumId) => {
    if (currentRole !== 'administrator') {
      showToast('Chỉ Quản trị viên mới được thay đổi trạng thái hiển thị Google Maps.', 'warning');
      return;
    }

    const target = museums.find(museum => museum.id === museumId);
    if (!target) return;

    const nextVisible = !target.googleMapsVisible;
    setMuseums(prev => prev.map(museum => museum.id === museumId
      ? { ...museum, googleMapsVisible: nextVisible }
      : museum));
    logAction(
      'MUSEUM_GOOGLE_MAPS_VISIBILITY',
      `${nextVisible ? 'Công khai' : 'Ẩn'} ${target.name} trên Google Maps cho khách tham quan`,
    );
    showToast(nextVisible ? `Đã cho phép khách tìm ${target.shortName} trên Google Maps.` : `Đã ẩn ${target.shortName} khỏi bản đồ công khai.`, 'success');
  };

  // Active museum helper
  const currentMuseum = museums.find(m => m.id === selectedMuseumId) || museums[0];

  return (
    <AppContext.Provider value={{
      currentUser,
      currentRole,
      setCurrentRole,
      loginAccount,
      isAuthenticated,
      login,
      logout,
      selectedMuseumId,
      setSelectedMuseumId,
      currentMuseum,
      activeTab,
      setActiveTab,
      museums,
      setMuseums,
      cities,
      isLoadingMuseums,
      loadCities,
      loadMuseums,
      createMuseum,
      updateMuseum,
      deleteMuseum,
      artifacts,
      addArtifact,
      updateArtifact,
      deleteArtifact,
      tours,
      addTour,
      updateTour,
      exhibitions,
      curationQueue,
      submitToCuration,
      approveCurationItem,
      rejectCurationItem,
      requestRevisionCurationItem,
      users,
      addUser,
      toggleUserStatus,
      toggleMuseumGoogleMapsVisibility,
      passPackages,
      transactions,
      refundTransaction,
      systemCases,
      updateSystemCase,
      reviews,
      replyToReview,
      moderateReview,
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
