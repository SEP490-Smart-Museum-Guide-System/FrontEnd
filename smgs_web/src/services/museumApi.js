const API_BASE = 'http://localhost:5169/api';

function getAuthHeaders() {
  const token = localStorage.getItem('smgs_web_jwt_token');
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

export async function createMuseumApi(museumData) {
  const response = await fetch(`${API_BASE}/museums`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify({
      name: museumData.name,
      description: museumData.description || null,
      address: museumData.address || null,
      cityCode: museumData.cityCode || null,
      latitude: museumData.latitude ? Number(museumData.latitude) : null,
      longitude: museumData.longitude ? Number(museumData.longitude) : null,
      openingHours: museumData.openingHours || null,
      coverImageUrl: museumData.coverImageUrl || museumData.image || null
    })
  });

  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.message || `Không thể tạo bảo tàng mới (${response.status})`);
  }
  return data;
}

export async function updateMuseumApi(id, museumData) {
  const response = await fetch(`${API_BASE}/museums/${id}`, {
    method: 'PUT',
    headers: getAuthHeaders(),
    body: JSON.stringify({
      name: museumData.name,
      description: museumData.description || null,
      address: museumData.address || null,
      cityCode: museumData.cityCode || null,
      latitude: museumData.latitude ? Number(museumData.latitude) : null,
      longitude: museumData.longitude ? Number(museumData.longitude) : null,
      openingHours: museumData.openingHours || null,
      coverImageUrl: museumData.coverImageUrl || museumData.image || null
    })
  });

  const data = await response.json().catch(() => null);
  if (!response.ok) {
    throw new Error(data?.message || `Không thể cập nhật bảo tàng (${response.status})`);
  }
  return data;
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
