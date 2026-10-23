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

export async function getCurationContentsApi(query = {}) {
  const params = new URLSearchParams();
  if (query.museumId !== undefined && query.museumId !== null && query.museumId !== '') {
    params.append('museumId', query.museumId);
  }
  if (query.artifactId !== undefined && query.artifactId !== null && query.artifactId !== '') {
    params.append('artifactId', query.artifactId);
  }
  if (query.status) {
    params.append('status', query.status);
  }
  if (query.page) params.append('page', query.page);
  if (query.pageSize) params.append('pageSize', query.pageSize);

  const url = `${API_BASE}/artifact-contents${params.toString() ? `?${params.toString()}` : ''}`;
  const response = await fetch(url, {
    method: 'GET',
    headers: getAuthHeaders()
  });

  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.message || `Lỗi khi tải danh sách kiểm duyệt (${response.status})`);
  }
  return data;
}

export async function getCurationContentByIdApi(id) {
  const response = await fetch(`${API_BASE}/artifact-contents/${id}`, {
    method: 'GET',
    headers: getAuthHeaders()
  });

  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.message || `Lỗi khi tải chi tiết nội dung kiểm duyệt (${response.status})`);
  }
  return data;
}

export async function approveCurationContentApi(id, note = '') {
  const response = await fetch(`${API_BASE}/artifact-contents/${id}/approve`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify({ note: note || '' })
  });

  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.message || `Lỗi khi phê duyệt nội dung (${response.status})`);
  }
  return data;
}

export async function rejectCurationContentApi(id, note = '') {
  const response = await fetch(`${API_BASE}/artifact-contents/${id}/reject`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify({ note: note || '' })
  });

  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.message || `Lỗi khi từ chối nội dung (${response.status})`);
  }
  return data;
}
