import { getAuthToken } from './auth';

const API_BASE = (import.meta.env?.VITE_API_BASE_URL ?? '/api').replace(/\/+$/, '');

function getAuthHeaders(isJson = true) {
  const token = getAuthToken();
  const headers = {
    'Accept': 'application/json',
    ...(token ? { Authorization: `Bearer ${token}` } : {})
  };
  if (isJson) {
    headers['Content-Type'] = 'application/json';
  }
  return headers;
}

/**
 * Get list of museums assigned to the current user (Staff/Admin)
 */
export async function getMyMuseumsApi() {
  const response = await fetch(`${API_BASE}/me/museums`, {
    method: 'GET',
    headers: getAuthHeaders()
  });
  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.message || `Lỗi khi tải danh sách bảo tàng phân công (${response.status})`);
  }
  return data;
}

/**
 * Get indoor structure of a museum ('unknown' | 'single' | 'floors')
 */
export async function getIndoorStructureApi(museumId) {
  const response = await fetch(`${API_BASE}/museums/${museumId}/indoor-structure`, {
    method: 'GET',
    headers: getAuthHeaders()
  });
  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.message || `Lỗi khi đọc cấu trúc sơ đồ bảo tàng (${response.status})`);
  }
  return data;
}

/**
 * Set indoor structure layout ('single' | 'floors')
 */
export async function updateIndoorStructureApi(museumId, layout) {
  const response = await fetch(`${API_BASE}/museums/${museumId}/indoor-structure`, {
    method: 'PUT',
    headers: getAuthHeaders(),
    body: JSON.stringify({ layout })
  });
  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.message || `Lỗi khi cập nhật cấu trúc bảo tàng (${response.status})`);
  }
  return data;
}

/**
 * Create a new building for a museum
 */
export async function createBuildingApi(museumId, { name }) {
  const response = await fetch(`${API_BASE}/museums/${museumId}/buildings`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify({ name })
  });
  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.message || `Lỗi khi tạo tòa nhà (${response.status})`);
  }
  return data;
}

/**
 * Create a new floor for a building
 */
export async function createFloorApi(museumId, { buildingId, levelNo, name }) {
  const response = await fetch(`${API_BASE}/museums/${museumId}/floors`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify({ buildingId, levelNo, name })
  });
  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.message || `Lỗi khi tạo tầng (${response.status})`);
  }
  return data;
}

/**
 * Assign staff to manage museum indoor maps (Admin only)
 */
export async function assignIndoorStaffApi(museumId, { userId }) {
  const response = await fetch(`${API_BASE}/museums/${museumId}/indoor-staff`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify({ userId })
  });
  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.message || `Lỗi khi phân công nhân viên (${response.status})`);
  }
  return data;
}

/**
 * Get list of indoor maps in a museum
 */
export async function getIndoorMapsApi(museumId) {
  const response = await fetch(`${API_BASE}/museums/${museumId}/indoor-maps`, {
    method: 'GET',
    headers: getAuthHeaders()
  });
  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.message || `Lỗi khi tải danh sách sơ đồ (${response.status})`);
  }
  return data;
}

/**
 * Create an indoor map for a museum
 */
export async function createIndoorMapApi(museumId, { floorId = null, name }) {
  const response = await fetch(`${API_BASE}/museums/${museumId}/indoor-maps`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify({ floorId, name })
  });
  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.message || `Lỗi khi tạo sơ đồ mới (${response.status})`);
  }
  return data;
}

/**
 * Get draft version of an indoor map
 */
export async function getIndoorMapDraftApi(mapId) {
  const response = await fetch(`${API_BASE}/indoor-maps/${mapId}/draft`, {
    method: 'GET',
    headers: getAuthHeaders()
  });
  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.message || `Lỗi khi tải bản nháp sơ đồ (${response.status})`);
  }
  return data;
}

/**
 * Get linkable artifacts and galleries for a map
 */
export async function getIndoorMapLinksApi(mapId) {
  const response = await fetch(`${API_BASE}/indoor-maps/${mapId}/links`, {
    method: 'GET',
    headers: getAuthHeaders()
  });
  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.message || `Lỗi khi tải danh sách liên kết hiện vật / phòng (${response.status})`);
  }
  return data;
}

/**
 * Save draft graph (nodes, markers, edges) with revision check
 */
export async function updateIndoorMapDraftApi(mapId, { revision, nodes, markers, edges }) {
  const response = await fetch(`${API_BASE}/indoor-maps/${mapId}/draft`, {
    method: 'PUT',
    headers: getAuthHeaders(),
    body: JSON.stringify({ revision, nodes, markers, edges })
  });
  const data = await response.json().catch(() => null);
  if (!response.ok) {
    if (response.status === 409) {
      throw new Error('Dữ liệu sơ đồ đã bị thay đổi bởi phiên khác (409 Conflict). Vui lòng tải lại trước khi lưu.');
    }
    throw new Error(data?.message || `Lỗi khi lưu bản nháp sơ đồ (${response.status})`);
  }
  return data;
}

/**
 * Upload map image (PNG/JPG, max 10MB)
 */
export async function uploadIndoorMapImageApi(mapId, file, revision, confirm = false) {
  const formData = new FormData();
  formData.append('file', file);
  formData.append('revision', revision);
  formData.append('confirm', String(confirm));

  const response = await fetch(`${API_BASE}/indoor-maps/${mapId}/image`, {
    method: 'POST',
    headers: getAuthHeaders(false),
    body: formData
  });
  const data = await response.json().catch(() => null);
  if (!response.ok) {
    if (response.status === 409) {
      throw new Error('Phiên bản sơ đồ đã thay đổi (409). Cần tải lại bản nháp.');
    }
    throw new Error(data?.message || `Lỗi tải lên ảnh sơ đồ (${response.status})`);
  }
  return data;
}

/**
 * Fetch map image blob using staff/admin auth header
 */
export async function fetchIndoorMapImageBlob(mapId, imageKey) {
  const url = `${API_BASE}/indoor-maps/${mapId}/image?key=${encodeURIComponent(imageKey)}`;
  const response = await fetch(url, {
    method: 'GET',
    headers: getAuthHeaders(false)
  });
  if (!response.ok) {
    throw new Error(`Không thể tải ảnh sơ đồ (${response.status})`);
  }
  const blob = await response.blob();
  return URL.createObjectURL(blob);
}

/**
 * Preview route in editor
 */
export async function previewRouteApi(mapId, { revision, fromNodeId, toNodeId, accessibleOnly = false }) {
  const response = await fetch(`${API_BASE}/indoor-maps/${mapId}/preview-route`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify({ revision, fromNodeId, toNodeId, accessibleOnly })
  });
  const data = await response.json().catch(() => null);
  if (!response.ok) {
    if (response.status === 422) {
      throw new Error('Không tìm thấy đường đi giữa hai điểm này (422).');
    }
    throw new Error(data?.message || `Lỗi khi thử đường đi (${response.status})`);
  }
  return data;
}

/**
 * Publish indoor map to visitors
 */
export async function publishIndoorMapApi(mapId, revision) {
  const response = await fetch(`${API_BASE}/indoor-maps/${mapId}/publish`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify({ revision })
  });
  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.message || `Lỗi khi xuất bản sơ đồ (${response.status})`);
  }
  return data;
}

/**
 * Unpublish indoor map from visitors
 */
export async function unpublishIndoorMapApi(mapId, revision) {
  const response = await fetch(`${API_BASE}/indoor-maps/${mapId}/unpublish`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify({ revision })
  });
  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.message || `Lỗi khi ngừng xuất bản sơ đồ (${response.status})`);
  }
  return data;
}

/**
 * Get artifact QR image URL / Blob
 */
export async function fetchArtifactQrBlob(mapId, markerId) {
  const response = await fetch(`${API_BASE}/indoor-maps/${mapId}/qr/${markerId}`, {
    method: 'GET',
    headers: getAuthHeaders(false)
  });
  if (!response.ok) {
    throw new Error(`Không tải được mã QR (${response.status})`);
  }
  const blob = await response.blob();
  return URL.createObjectURL(blob);
}
