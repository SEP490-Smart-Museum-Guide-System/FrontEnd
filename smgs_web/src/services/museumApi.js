import { getAuthToken } from './auth';

const API_BASE = (import.meta.env?.VITE_API_BASE_URL ?? '/api').replace(/\/+$/, '');

function getAuthHeaders() {
  const token = getAuthToken();
  return {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    ...(token ? { Authorization: `Bearer ${token}` } : {})
  };
}

export async function getMuseumsApi(query = {}) {
  const params = new URLSearchParams();
  if (query.page) params.append('page', query.page);
  if (query.pageSize) params.append('pageSize', query.pageSize);
  if (query.searchTerm) params.append('searchTerm', query.searchTerm);
  if (query.cityCode) params.append('cityCode', query.cityCode);

  const url = `${API_BASE}/museums${params.toString() ? `?${params.toString()}` : ''}`;
  const response = await fetch(url, {
    method: 'GET',
    headers: getAuthHeaders()
  });

  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.message || `Lỗi khi tải danh sách bảo tàng (${response.status})`);
  }
  return data;
}

export async function getMuseumByIdApi(id) {
  const response = await fetch(`${API_BASE}/museums/${id}`, {
    method: 'GET',
    headers: getAuthHeaders()
  });

  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.message || `Lỗi khi tải chi tiết bảo tàng (${response.status})`);
  }
  return data;
}

export async function getCitiesApi() {
  const response = await fetch(`${API_BASE}/museums/cities`, {
    method: 'GET',
    headers: getAuthHeaders()
  });

  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.message || `Lỗi khi tải danh mục tỉnh thành (${response.status})`);
  }
  return data;
}

function museumFormData(data, file) {
  const form = new FormData();
  const values = {
    name: data.name, description: data.description, address: data.address, cityCode: data.cityCode,
    latitude: data.latitude, longitude: data.longitude, openingHours: data.openingHours,
    coverImageUrl: data.coverImageUrl ?? data.image,
  };
  for (const [name, value] of Object.entries(values)) {
    if (value !== '' && value != null) form.append(name, String(value));
  }
  if (file) form.append('file', file);
  return form;
}

async function saveMuseum(path, method, data, file) {
  const headers = getAuthHeaders(); delete headers['Content-Type'];
  const response = await fetch(`${API_BASE}/${path}`, { method, headers, body: museumFormData(data, file) });
  const result = await response.json().catch(() => null);
  if (!response.ok) throw new Error(result?.message || `Không thể lưu bảo tàng (${response.status}).`);
  if (!result?.data?.id) throw new Error('Máy chủ chưa trả về thông tin bảo tàng đã lưu.');
  return result;
}

export function createMuseumApi(data, file) {
  return saveMuseum('museums/with-image', 'POST', data, file);
}

export function updateMuseumApi(id, data, file) {
  return saveMuseum(`museums/${id}/with-image`, 'PUT', data, file);
}

export async function deleteMuseumApi(id) {
  const response = await fetch(`${API_BASE}/museums/${id}`, {
    method: 'DELETE',
    headers: getAuthHeaders()
  });

  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.message || `Không thể vô hiệu hóa bảo tàng (${response.status})`);
  }
  return data;
}
