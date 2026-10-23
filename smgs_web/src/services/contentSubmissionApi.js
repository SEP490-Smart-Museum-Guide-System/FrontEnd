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

export async function submitArtifactContentApi(artifactId, contentData) {
  const response = await fetch(`${API_BASE}/artifacts/${artifactId}/contents`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify({
      languageCode: contentData.languageCode || 'vi',
      title: contentData.title,
      description: contentData.description
    })
  });

  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.message || `Lỗi khi gửi bản thảo nội dung lên hàng đợi (${response.status})`);
  }
  return data;
}

export async function getPublishedArtifactContentApi(artifactId, languageCode = 'vi') {
  const response = await fetch(`${API_BASE}/artifacts/${artifactId}/contents/published?languageCode=${encodeURIComponent(languageCode)}`, {
    method: 'GET',
    headers: getAuthHeaders()
  });

  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.message || `Không thể tải nội dung đã xuất bản (${response.status})`);
  }
  return data;
}
