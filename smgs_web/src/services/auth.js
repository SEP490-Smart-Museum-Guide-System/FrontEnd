const sessionKey = 'smgs_web_session';
const staffRoles = { Admin: 'administrator', 'Museum Staff': 'museumStaff', Staff: 'systemStaff', Curator: 'curator' };
const apiBaseUrl = (import.meta.env?.VITE_API_BASE_URL ?? '/api').replace(/\/+$/, '');

export function parseStaffSession(data) {
  const rawRole = Array.isArray(data?.roles) && data.roles.length === 1 ? data.roles[0] : null;
  if (rawRole === 'Visitor') {
    throw new Error('Tài khoản Visitor vui lòng sử dụng ứng dụng Khách tham quan.');
  }
  const role = typeof rawRole === 'string' && Object.hasOwn(staffRoles, rawRole) ? staffRoles[rawRole] : null;
  const expiresAt = Date.parse(data?.accessTokenExpiration);
  if (!role || typeof data?.accessToken !== 'string' || !data.accessToken ||
      typeof data.email !== 'string' || !data.email || typeof data.fullName !== 'string' ||
      !data.fullName.trim() || !Number.isFinite(expiresAt) || expiresAt <= Date.now()) {
    throw new Error('Phiên đăng nhập không hợp lệ hoặc đã hết hạn. Vui lòng đăng nhập lại.');
  }
  return { accessToken: data.accessToken, expiresAt,
    // shortcut: auth has no museum membership field; replace with membership API when available.
    user: { id: data.email, name: data.fullName, email: data.email, role, status: 'active', museumId: 'mus-01' } };
}

export function clearWebSession(storage = globalThis.localStorage) {
  for (const key of [sessionKey, 'smgs_web_authenticated', 'smgs_web_user_email', 'smgs_web_role', 'smgs_web_jwt_token']) {
    storage.removeItem(key);
  }
}

export function readWebSession(storage = globalThis.localStorage) {
  try { return parseStaffSession(JSON.parse(storage.getItem(sessionKey))); }
  catch { clearWebSession(storage); return null; }
}

export function saveWebSession(data, storage = globalThis.localStorage) {
  const session = parseStaffSession(data);
  clearWebSession(storage);
  storage.setItem(sessionKey, JSON.stringify(data));
  return session;
}

export async function requestLogin(email, password) {
  let response;
  try {
    response = await fetch(`${apiBaseUrl}/auth/login`, {
      method: 'POST', headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
      body: JSON.stringify({ email: email.trim(), password }), signal: AbortSignal.timeout(10000),
    });
  } catch {
    throw new Error('Không kết nối được máy chủ hoặc yêu cầu quá hạn. Vui lòng kiểm tra mạng và thử lại.');
  }
  let body;
  try { body = JSON.parse(await response.text()); } catch { /* A proxy may return HTML. */ }
  if (!response.ok) {
    throw new Error(typeof body?.message === 'string' ? body.message : `Không thể đăng nhập (${response.status}).`);
  }
  parseStaffSession(body?.data);
  return body.data;
}
