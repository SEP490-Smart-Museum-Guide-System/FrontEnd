import { getAuthToken } from './auth.js';

const base = (import.meta.env?.VITE_API_BASE_URL ?? '/api').replace(/\/+$/, '');

export async function backend(path, { method = 'GET', body, signal, timeoutMs = 15000 } = {}) {
  const token = getAuthToken();
  const response = await fetch(`${base}/${path}`, {
    method, signal: signal ? AbortSignal.any([signal, AbortSignal.timeout(timeoutMs)]) : AbortSignal.timeout(timeoutMs),
    headers: { Accept: 'application/json', ...(body ? { 'Content-Type': 'application/json' } : {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  const result = await response.json().catch(() => null);
  if (!response.ok || result?.isSuccess === false) {
    throw new Error(result?.message || `Không thể tải hoặc lưu dữ liệu (${response.status}).`);
  }
  if (!result || !Object.hasOwn(result, 'data')) throw new Error('Phản hồi máy chủ không hợp lệ.');
  return result.data;
}

// Both paginated envelopes and array endpoints are used by the BE.
// Empty data is authoritative; never replace it with demo records.
export async function allPages(path, options = {}) {
  const rows = [];
  const pagedArray = options.pagedArray ?? /^(tours(?:\/manage)?|question-bank\/questions|commerce\/(?:orders\/me|passes\/me|museums\/[^/]+\/orders)|quiz-attempts\/me|recognitions\/me|gamification\/me\/transactions)$/.test(path.split('?')[0]);
  for (let page = 1; ; page++) {
    const data = await backend(`${path}${path.includes('?') ? '&' : '?'}page=${page}&pageSize=50`, options);
    const items = Array.isArray(data) ? data : data?.items;
    if (!Array.isArray(items)) throw new Error('Danh sách trả về không hợp lệ.');
    rows.push(...items);
    if (Array.isArray(data) ? (!pagedArray || items.length < 50) : (page >= data.totalPages || rows.length >= data.totalCount || items.length === 0)) return rows;
    if (page >= 1000) throw new Error('Danh sách quá lớn. Vui lòng lọc dữ liệu.');
  }
}

export const apiRoles = { administrator: 'Admin', museumStaff: 'Museum Staff', curator: 'Curator', systemStaff: 'Staff', visitor: 'Visitor' };
export function museumView(m) {
  return { ...m, backendId: m.id, shortName: m.name, code: String(m.id), address: m.address ?? '',
    image: m.coverImageUrl || '', description: m.description || '', openingHours: m.openingHours || '',
    status: m.isActive ? 'active' : 'inactive', googleMapsVisible: m.isActive, buildings: [] };
}
export function artifactView(a) {
  const imageMedia = a.media?.filter(m => m.mediaType === 'image') || [];
  const imageUrls = imageMedia.map(m => m.fileUrl).filter(Boolean);
  const primaryImage = imageUrls[0] || a.image || '';
  const allImages = imageUrls.length > 0 ? imageUrls : (primaryImage ? [primaryImage] : []);
  return { ...a, backendId: a.id, code: a.code || '', qrCode: a.qrCode || '', category: a.topics?.map(t => t.name).filter(Boolean).join(', ') || '',
    era: '', period: '', dating: '', material: '', theme: '', dimensions: '', galleryName: a.galleryName || '',
    image: primaryImage,
    images: allImages,
    imageCount: allImages.length,
    status: a.isActive ? 'published' : 'draft', has3DModel: !!a.model3D,
    modelUrl: a.model3D?.modelUrl || '', referenceImages: [], audioDuration: '',
    audioUrl: a.media?.find(m => m.mediaType === 'audio')?.fileUrl || '',
    shortDesc: '', fullDesc: '', quizzes: [], multilingual: {}, approvedAiContent: [] };
}
export function tourView(t) {
  const ids = (t.items || []).slice().sort((a, b) => a.orderNo - b.orderNo).map(i => i.artifactId);
  return { ...t, code: String(t.id), duration: `${t.estimatedMinutes} phút`, artifacts: ids,
    stopsCount: ids.length, theme: '', rating: null, reviewsCount: null };
}
export function accountView(a) {
  return { ...a, name: a.fullName, phone: a.phoneNumber || '',
    role: Object.keys(apiRoles).find(key => apiRoles[key] === a.roles?.[0]) || '',
    museumId: a.assignments?.[0]?.museumId ?? null,
    museumName: a.assignments?.map(x => x.museumName).join(', ') || 'Chưa phân công',
    assignedGalleries: a.assignments?.map(x => x.galleryName).filter(Boolean) || [],
    permissions: [], lastLogin: 'Chưa có dữ liệu', status: a.isActive ? 'active' : 'inactive' };
}
export function reviewView(r, museums) {
  const isGuid = typeof r.visitorId === 'string' && /^[0-9a-f-]{36}$/i.test(r.visitorId);
  const visitorName = r.visitorName || (isGuid ? 'Khách tham quan' : r.visitorId) || 'Khách tham quan';
  return { ...r, museumName: museums.find(m => m.id === r.museumId)?.name || `Bảo tàng #${r.museumId}`,
    visitorName, rating: r.overallRating, comment: r.comment || '',
    timestamp: r.createdAt, date: r.createdAt, targetName: `Lượt tham quan #${r.visitId}`, targetType: 'museum',
    officialReply: r.staffResponse?.content || '', replyDate: r.staffResponse?.createdAt || '',
    status: r.staffResponse ? 'replied' : 'pending_reply', hidden: r.moderationStatus === 'Hidden' };
}
export function complaintView(c) {
  const isGuid = typeof c.visitorId === 'string' && /^[0-9a-f-]{36}$/i.test(c.visitorId);
  const visitorDisplay = c.visitorName || (isGuid ? 'Khách tham quan' : c.visitorId) || 'Khách tham quan';
  return { ...c, type: 'complaint', title: c.subject, description: c.body, detail: c.body, visitor: visitorDisplay,
    visitorName: visitorDisplay, museum: '', priority: '', note: c.resolutionNote || '',
    status: ({ Open: 'new', New: 'new', InProgress: 'in_progress', Resolved: 'resolved', Closed: 'resolved' })[c.status] || 'new' };
}
