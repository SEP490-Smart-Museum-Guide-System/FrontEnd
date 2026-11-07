import React, { createContext, useContext, useState, useEffect, useCallback, useRef } from 'react';
import { clearWebSession, readWebSession, requestLogin, saveWebSession } from '../services/auth';
import { backend, allPages, apiRoles, museumView, artifactView, tourView, accountView, reviewView, complaintView } from '../services/backend';
import { createMuseumApi, updateMuseumApi, deleteMuseumApi } from '../services/museumApi';
import { createArtifactApi, updateArtifactApi, deleteArtifactApi, downloadArtifactQrImageApi, regenerateArtifactQrApi } from '../services/artifactApi';
import { approveCurationContentApi, rejectCurationContentApi } from '../services/curationApi';
import { submitArtifactContentApi } from '../services/contentSubmissionApi';

const AppContext = createContext();
export function AppProvider({ children }) {
  const [session, setSession] = useState(readWebSession);
  useEffect(() => {
    if (!session) return;
    const timer = setTimeout(() => { clearWebSession(); setSession(null); }, Math.max(0, session.expiresAt - Date.now()));
    return () => clearTimeout(timer);
  }, [session]);
  const login = async (email, password) => {
    try { setSession(saveWebSession(await requestLogin(email, password))); return { success: true }; }
    catch (e) { return { success: false, error: e.message }; }
  };
  const logout = () => { clearWebSession(); setSession(null); };
  // Never carry cached business records across accounts.
  return <DataProvider key={session?.accessToken || 'anonymous'} session={session} login={login} endSession={logout}>{children}</DataProvider>;
}
function DataProvider({ children, session, login, endSession }) {
  const currentUser = session?.user ?? null;
  const currentRole = currentUser?.role ?? null;
  const isAuthenticated = !!session;
  const [selectedMuseumId, setSelectedMuseumId] = useState(null);
  const [activeTab, setActiveTabState] = useState('overview');
  const guard = useRef(null);
  const registerNavigationGuard = useCallback(fn => { guard.current = fn; return () => { if (guard.current === fn) guard.current = null; }; }, []);
  const setActiveTab = tab => { if (!guard.current || guard.current()) setActiveTabState(tab); };
  const logout = () => { if (!guard.current || guard.current()) endSession(); };
  const [museums, setMuseums] = useState([]), [cities, setCities] = useState([]);
  const [artifacts, setArtifacts] = useState([]), [tours, setTours] = useState([]);
  const [curationQueue, setCurationQueue] = useState([]), [users, setUsers] = useState([]);
  const [passPackages, setPassPackages] = useState([]), [transactions, setTransactions] = useState([]);
  const [reviews, setReviews] = useState([]), [systemCases, setSystemCases] = useState([]);
  const [dataErrors, setDataErrors] = useState({}), [loading, setLoading] = useState({});
  const [toasts, setToasts] = useState([]), [refresh, setRefresh] = useState(0);
  const reload = useCallback(() => setRefresh(n => n + 1), []);
  const showToast = (message, type = 'success') => {
    const id = crypto.randomUUID(); setToasts(prev => [...prev, { id, message, type }]);
    setTimeout(() => setToasts(prev => prev.filter(t => t.id !== id)), 4000);
  };
  const unavailable = message => { showToast(message, 'warning'); return { success: false, error: message }; };
  // Only BE may create persisted audit entries.
  const logAction = () => {};
  const currentMuseum = museums.find(m => String(m.id) === String(selectedMuseumId)) ?? null;
  useEffect(() => {
    if (!session) return;
    const controller = new AbortController(), options = { signal: controller.signal };
    async function load(key, request, setter) {
      setLoading(p => ({ ...p, [key]: true })); setDataErrors(p => ({ ...p, [key]: null }));
      try { const rows = await request(); if (!controller.signal.aborted) setter(rows); }
      catch (e) { if (!controller.signal.aborted) { setter([]); setDataErrors(p => ({ ...p, [key]: e.message })); } }
      finally { if (!controller.signal.aborted) setLoading(p => ({ ...p, [key]: false })); }
    }
    load('museums', async () => {
      let rows = (await allPages('museums', options)).map(museumView);
      if (currentRole === 'museumStaff') {
        const assigned = await backend('me/museums', options);
        rows = rows.filter(m => assigned.some(a => a.id === m.id));
      }
      return rows;
    }, rows => {
      setMuseums(rows); setSelectedMuseumId(prev => rows.some(m => String(m.id) === String(prev)) ? prev : rows[0]?.id ?? null);
    });
    load('cities', () => backend('museums/cities', options), setCities);
    load('artifacts', async () => (await allPages('artifacts', options)).map(artifactView), setArtifacts);
    if (currentRole === 'administrator') load('users', async () => (await allPages('admin/accounts', options)).map(accountView), setUsers);
    if (['administrator', 'systemStaff'].includes(currentRole)) load('systemCases', async () => (await allPages('complaints', options)).map(complaintView), setSystemCases);
    return () => controller.abort();
  }, [session, currentRole, refresh]);
  useEffect(() => {
    if (!session) return;
    const controller = new AbortController(), options = { signal: controller.signal };
    setTours([]); setCurationQueue([]); setReviews([]); setTransactions([]); setPassPackages([]);
    setLoading(p => ({ ...p, tours: false, curationQueue: false, reviews: false, transactions: false, passPackages: false }));
    const museumIds = currentRole === 'administrator' ? museums.filter(m => m.isActive).map(m => m.id) : currentMuseum ? [currentMuseum.id] : [];
    async function load(key, request, setter) {
      setter([]); setLoading(p => ({ ...p, [key]: true })); setDataErrors(p => ({ ...p, [key]: null }));
      try { const rows = await request(); if (!controller.signal.aborted) setter(rows); }
      catch (e) { if (!controller.signal.aborted) setDataErrors(p => ({ ...p, [key]: e.message })); }
      finally { if (!controller.signal.aborted) setLoading(p => ({ ...p, [key]: false })); }
    }
    if (['administrator', 'museumStaff', 'curator'].includes(currentRole) && museumIds.length) {
      load('tours', async () => (await Promise.all(museumIds.map(id => allPages(`tours/manage?museumId=${id}`, options)))).flat().map(tourView), setTours);
      load('curationQueue', async () => {
        const contents = currentRole === 'curator'
          ? (await Promise.all(['pending_review', 'published', 'rejected', 'archived'].map(status => allPages(`artifact-contents?museumId=${currentMuseum.id}&status=${status}`, options)))).flat()
          : (await Promise.all(artifacts.filter(a => museumIds.includes(a.museumId)).map(a => backend(`artifacts/${a.id}/contents/versions`, options)))).flat();
        return contents.map(c => ({ ...c, backendId: c.id, targetArtifactId: c.artifactId,
          museumId: artifacts.find(a => a.id === c.artifactId)?.museumId,
          targetArtifactName: artifacts.find(a => a.id === c.artifactId)?.name || `Hiện vật #${c.artifactId}`,
          proposedContent: c.description || '', changesSummary: c.description || '', submittedDate: c.createdAt,
          feedback: c.reviewNote || '', submittedBy: c.createdBy || '', type: c.isAiGenerated ? 'audio_narration' : 'artifact_update', priority: 'normal' }));
      }, setCurationQueue);
    }
    if (['administrator', 'systemStaff'].includes(currentRole)) load('reviews', async () => (await allPages('feedbacks', options)).map(r => reviewView(r, museums)), setReviews);
    else if (currentRole === 'museumStaff' && currentMuseum) load('reviews', async () => (await allPages(`feedbacks/museum/${currentMuseum.id}`, options)).map(r => reviewView(r, museums)), setReviews);
    if (['administrator', 'museumStaff'].includes(currentRole) && museumIds.length) {
      load('transactions', async () => (await Promise.all(museumIds.map(id => allPages(`commerce/museums/${id}/orders`, options)))).flat().map(o => ({
        ...o, userName: o.buyerName, userEmail: o.buyerDetails?.email || '', packageName: o.productName,
        museumCode: String(o.museumId), timestamp: o.createdAt, paymentMethod: 'Chưa có dữ liệu', status: o.status === 'paid' ? 'completed' : o.status,
      })), setTransactions);
      load('passPackages', async () => (await Promise.all(museumIds.map(id => backend(`commerce/museums/${id}/products/manage`, options)))).flat().map(p => ({
        ...p, durationDays: p.validityHours ? p.validityHours / 24 : null, features: [], activePassesCount: null,
      })), setPassPackages);
    }
    return () => controller.abort();
  }, [session, currentRole, currentMuseum, museums, artifacts, refresh]);
  async function mutate(request, message) {
    try { const data = await request(); reload(); showToast(message); return { success: true, data }; }
    catch (e) { showToast(e.message, 'warning'); return { success: false, error: e.message }; }
  }
  function requireId(id) {
    if (!Number.isInteger(Number(id)) || Number(id) <= 0) throw new Error('Hãy chọn bản ghi đã lưu trên máy chủ. Dữ liệu AI/3D mẫu không thể dùng cho nghiệp vụ.');
    return Number(id);
  }
  const createMuseum = (form, file) => mutate(async () => (await createMuseumApi(form, file)).data, 'Đã tạo bảo tàng.');
  const updateMuseum = (id, form, file) => mutate(() => updateMuseumApi(requireId(id), form, file), 'Đã cập nhật bảo tàng.');
  const deleteMuseum = id => mutate(() => deleteMuseumApi(requireId(id)), 'Đã vô hiệu hóa bảo tàng.');
  const artifactPayload = a => ({ museumId: requireId(a.museumId || currentMuseum?.id), galleryId: a.galleryId ? requireId(a.galleryId) : null, name: a.name, code: a.code || null, qrCode: a.qrCode || null, accessLevel: a.accessLevel || 'free' });
  const addArtifact = a => mutate(async () => (await createArtifactApi(artifactPayload(a))).data, 'Đã thêm hiện vật.');
  const updateArtifact = a => mutate(() => updateArtifactApi(requireId(a.id), artifactPayload(a)), 'Đã lưu thông tin cơ bản. Nội dung thuyết minh và media được lưu riêng.');
  const deleteArtifact = id => mutate(() => deleteArtifactApi(requireId(id)), 'Đã xóa hiện vật.');
  const downloadArtifactQr = (id, name) => mutate(() => downloadArtifactQrImageApi(requireId(id), name), 'Đã tải mã QR.');
  const regenerateArtifactQr = id => mutate(() => regenerateArtifactQrApi(requireId(id)), 'Đã tạo lại mã QR.');
  const submitToCuration = item => mutate(() => submitArtifactContentApi(requireId(item.targetArtifactId), { languageCode: item.languageCode || 'vi', title: item.title, description: item.proposedContent || item.content || '', isAiGenerated: item.isAiGenerated ?? true }), 'Đã gửi bản thảo lên máy chủ.');
  const approveCurationItem = (id, note) => mutate(() => approveCurationContentApi(requireId(id), note), 'Đã xuất bản nội dung.');
  const rejectCurationItem = (id, note) => mutate(() => rejectCurationContentApi(requireId(id), note), 'Đã từ chối nội dung.');
  const requestRevisionCurationItem = () => unavailable('Máy chủ chưa có thao tác trả về bản nháp. Hãy từ chối và ghi rõ yêu cầu chỉnh sửa.');
  const tourPayload = t => ({ title: t.title, description: t.description || '', estimatedMinutes: parseInt(t.duration, 10), artifactIds: t.artifacts.map(requireId) });
  const addTour = t => mutate(() => backend(`tours?museumId=${requireId(t.museumId)}`, { method: 'POST', body: tourPayload(t) }), 'Đã tạo bản nháp hành trình.');
  const updateTour = t => mutate(() => backend(`tours/${requireId(t.id)}`, { method: 'PUT', body: { revision: t.revision, tour: tourPayload(t) } }), 'Đã lưu bản nháp hành trình.');
  const publishTour = t => mutate(() => backend(`tours/${requireId(t.id)}/publish`, { method: 'POST', body: { revision: t.revision } }), 'Đã xuất bản hành trình.');
  const replyToReview = (id, text) => mutate(() => backend(`feedbacks/${id}/response`, { method: 'PUT', body: { content: text } }), 'Đã gửi phản hồi.');
  const moderateReview = (id, hidden) => mutate(() => backend(`feedbacks/${id}/moderation`, { method: 'PATCH', body: { moderationStatus: hidden ? 'Hidden' : 'Visible' } }), 'Đã cập nhật kiểm duyệt phản hồi.');
  const updateSystemCase = (id, status, note = '') => mutate(async () => {
    if (currentRole !== 'systemStaff') throw new Error('Chỉ Nhân viên hệ thống được xử lý khiếu nại.');
    if (!systemCases.find(c => c.id === id)?.assignedTo) await backend(`complaints/${id}/assign`, { method: 'POST' });
    return backend(`complaints/${id}/status`, { method: 'PATCH', body: { status: status === 'resolved' ? 'Resolved' : 'InProgress', resolutionNote: note } });
  }, 'Đã cập nhật khiếu nại.');
  const addUser = u => mutate(() => backend('admin/accounts', { method: 'POST', body: { email: u.email, fullName: u.name, phoneNumber: u.phone || null, password: u.password, roles: [apiRoles[u.role]] } }), 'Đã tạo tài khoản.');
  const toggleUserStatus = id => mutate(() => backend(`admin/accounts/${id}/status`, { method: 'PATCH', body: { isActive: users.find(u => u.id === id)?.status !== 'active' } }), 'Đã cập nhật tài khoản.');
  const refundTransaction = () => unavailable('Máy chủ chưa cung cấp API hoàn tiền. Chưa có giao dịch nào được hoàn tiền.');
  const toggleMuseumGoogleMapsVisibility = () => unavailable('Máy chủ chưa có trường hiển thị bản đồ độc lập. Danh sách công khai hiện theo trạng thái hoạt động của bảo tàng.');
  return <AppContext.Provider value={{ currentUser, currentRole, isAuthenticated, login, logout, selectedMuseumId, setSelectedMuseumId, currentMuseum, activeTab, setActiveTab, registerNavigationGuard,
    museums, setMuseums, cities, artifacts, tours, curationQueue, users, passPackages, transactions, reviews, systemCases, exhibitions: [], auditLogs: [], dataErrors, loading, reload,
    isLoadingMuseums: !!loading.museums, isLoadingArtifacts: !!loading.artifacts, isLoadingCuration: !!loading.curationQueue,
    loadCities: reload, loadMuseums: reload, loadArtifacts: reload, loadCurationQueue: reload,
    createMuseum, updateMuseum, deleteMuseum, addArtifact, updateArtifact, deleteArtifact, downloadArtifactQr, regenerateArtifactQr, submitToCuration, approveCurationItem, rejectCurationItem, requestRevisionCurationItem,
    addTour, updateTour, publishTour, replyToReview, moderateReview, updateSystemCase, addUser, toggleUserStatus, refundTransaction, toggleMuseumGoogleMapsVisibility, logAction, toasts, showToast }}>{children}</AppContext.Provider>;
}
export function useApp() { const context = useContext(AppContext); if (!context) throw new Error('useApp must be used within AppProvider'); return context; }
