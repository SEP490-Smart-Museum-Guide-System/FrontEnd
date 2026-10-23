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

export async function getArtifactsApi(query = {}) {
  const params = new URLSearchParams();
  if (query.museumId !== undefined && query.museumId !== null && query.museumId !== '') {
    params.append('museumId', query.museumId);
  }
  if (query.galleryId !== undefined && query.galleryId !== null && query.galleryId !== '') {
    params.append('galleryId', query.galleryId);
  }
  if (query.keyword) params.append('keyword', query.keyword);
  if (query.isActive !== undefined && query.isActive !== null) params.append('isActive', query.isActive);
  if (query.page) params.append('page', query.page);
  if (query.pageSize) params.append('pageSize', query.pageSize);

  const url = `${API_BASE}/artifacts${params.toString() ? `?${params.toString()}` : ''}`;
  const response = await fetch(url, {
    method: 'GET',
    headers: getAuthHeaders()
  });

  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.message || `Lỗi khi tải danh sách hiện vật (${response.status})`);
  }
  return data;
}

export async function getArtifactByIdApi(id) {
  const response = await fetch(`${API_BASE}/artifacts/${id}`, {
    method: 'GET',
    headers: getAuthHeaders()
  });

  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.message || `Lỗi khi tải chi tiết hiện vật (${response.status})`);
  }
  return data;
}

export async function createArtifactApi(artifactData) {
  const response = await fetch(`${API_BASE}/artifacts`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify({
      museumId: Number(artifactData.museumId),
      galleryId: artifactData.galleryId ? Number(artifactData.galleryId) : null,
      code: artifactData.code || null,
      name: artifactData.name,
      qrCode: artifactData.qrCode || null,
      mapNodeId: artifactData.mapNodeId ? Number(artifactData.mapNodeId) : null,
      mapX: artifactData.mapX !== undefined && artifactData.mapX !== null ? Number(artifactData.mapX) : null,
      mapY: artifactData.mapY !== undefined && artifactData.mapY !== null ? Number(artifactData.mapY) : null,
      mapIcon: artifactData.mapIcon || null,
      accessLevel: artifactData.accessLevel || 'free'
    })
  });

  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.message || `Không thể tạo hiện vật mới (${response.status})`);
  }
  return data;
}

export async function updateArtifactApi(id, artifactData) {
  const response = await fetch(`${API_BASE}/artifacts/${id}`, {
    method: 'PUT',
    headers: getAuthHeaders(),
    body: JSON.stringify({
      galleryId: artifactData.galleryId ? Number(artifactData.galleryId) : null,
      code: artifactData.code || null,
      name: artifactData.name,
      qrCode: artifactData.qrCode || null,
      mapNodeId: artifactData.mapNodeId ? Number(artifactData.mapNodeId) : null,
      mapX: artifactData.mapX !== undefined && artifactData.mapX !== null ? Number(artifactData.mapX) : null,
      mapY: artifactData.mapY !== undefined && artifactData.mapY !== null ? Number(artifactData.mapY) : null,
      mapIcon: artifactData.mapIcon || null,
      accessLevel: artifactData.accessLevel || 'free'
    })
  });

  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.message || `Không thể cập nhật hiện vật (${response.status})`);
  }
  return data;
}

export async function deleteArtifactApi(id) {
  const response = await fetch(`${API_BASE}/artifacts/${id}`, {
    method: 'DELETE',
    headers: getAuthHeaders()
  });

  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.message || `Không thể vô hiệu hóa hiện vật (${response.status})`);
  }
  return data;
}

export function getArtifactQrImageUrl(id) {
  return `${API_BASE}/artifacts/${id}/qr-image`;
}

export async function downloadArtifactQrImageApi(id, artifactName = '') {
  const response = await fetch(`${API_BASE}/artifacts/${id}/qr-image`, {
    method: 'GET'
  });

  if (!response.ok) {
    throw new Error(`Không thể tải ảnh QR code (${response.status})`);
  }

  const blob = await response.blob();
  const url = window.URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  const safeName = (artifactName || `artifact-${id}`).replace(/[^a-zA-Z0-9_-]/g, '_');
  link.download = `QR_${safeName}.png`;
  document.body.appendChild(link);
  link.click();
  link.remove();
  window.URL.revokeObjectURL(url);
}

export async function regenerateArtifactQrApi(id) {
  const response = await fetch(`${API_BASE}/artifacts/${id}/regenerate-qr`, {
    method: 'POST',
    headers: getAuthHeaders()
  });

  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.message || `Không thể tạo lại mã QR (${response.status})`);
  }
  return data;
}

export async function scanArtifactQrApi(qrCode) {
  const response = await fetch(`${API_BASE}/artifacts/scan/${encodeURIComponent(qrCode)}`, {
    method: 'GET',
    headers: getAuthHeaders()
  });

  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.message || `Không tìm thấy thông tin hiện vật từ mã QR (${response.status})`);
  }
  return data;
}
