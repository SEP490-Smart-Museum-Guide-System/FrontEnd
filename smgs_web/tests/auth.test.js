import test from 'node:test';
import assert from 'node:assert/strict';
import { parseStaffSession, requestLogin, readWebSession, saveWebSession, clearWebSession } from '../src/services/auth.js';

const data = (role = 'Admin') => ({ accessToken: 'test-token', email: 'staff@example.invalid',
  fullName: 'Nhân viên thử nghiệm', roles: [role], accessTokenExpiration: new Date(Date.now() + 60000).toISOString() });
const storage = () => {
  const values = new Map();
  return { getItem: key => values.get(key) ?? null, setItem: (key, value) => values.set(key, value), removeItem: key => values.delete(key) };
};

test('only the four authenticated staff roles enter the portal', () => {
  for (const role of ['Admin', 'Museum Staff', 'Staff', 'Curator']) assert.ok(parseStaffSession(data(role)).user.role);
  for (const invalid of [data('Visitor'), data('unknown'), data('toString'), data('__proto__'), { ...data(), roles: [['Admin']] }, { ...data(), roles: [] },
    { ...data(), roles: ['Admin', 'Visitor'] }, { ...data(), roles: { length: 1, 0: 'Admin' } },
    { ...data(), accessToken: '' }, { ...data(), accessTokenExpiration: '2000-01-01' }, null]) {
    assert.throws(() => parseStaffSession(invalid));
  }
});

test('saved sessions restore their own profile; legacy flags and expired sessions do not authenticate', () => {
  const store = storage();
  store.setItem('smgs_web_authenticated', 'true'); store.setItem('smgs_web_role', 'administrator');
  assert.equal(readWebSession(store), null);
  saveWebSession(data('Curator'), store);
  assert.equal(readWebSession(store).user.name, 'Nhân viên thử nghiệm');
  assert.equal(readWebSession(store).user.role, 'curator');
  store.setItem('smgs_web_session', JSON.stringify({ ...data(), accessTokenExpiration: '2000-01-01' }));
  assert.equal(readWebSession(store), null);
  saveWebSession(data(), store); clearWebSession(store); assert.equal(readWebSession(store), null);
});

test('login preserves password whitespace and handles API, network and malformed responses without mock fallback', async () => {
  const originalFetch = globalThis.fetch;
  try {
    globalThis.fetch = async (url, options) => {
      assert.equal(url, '/api/auth/login');
      assert.deepEqual(JSON.parse(options.body), { email: 'staff@example.invalid', password: ' TestPass1 ' });
      return new Response(JSON.stringify({ data: data() }), { status: 200 });
    };
    assert.equal((await requestLogin(' staff@example.invalid ', ' TestPass1 ')).fullName, 'Nhân viên thử nghiệm');
    for (const status of [400, 401, 429, 500]) {
      globalThis.fetch = async () => new Response(JSON.stringify({ message: 'Authentication rejected' }), { status });
      await assert.rejects(requestLogin('admin@smgs.vn', 'smgs123'), /Authentication rejected/);
    }
    globalThis.fetch = async () => { throw new TypeError('Network offline'); };
    await assert.rejects(requestLogin('admin@smgs.vn', 'smgs123'), /Không kết nối/);
    globalThis.fetch = async () => new Response('<html>proxy error</html>', { status: 502 });
    await assert.rejects(requestLogin('x@y.com', 'pass'), /502/);
    globalThis.fetch = async () => new Response('{}', { status: 200 });
    await assert.rejects(requestLogin('x@y.com', 'pass'), /không hợp lệ/);
    globalThis.fetch = async () => new Response(JSON.stringify({ data: data('Visitor') }), { status: 200 });
    await assert.rejects(requestLogin('x@y.com', 'pass'), /Visitor/);
  } finally { globalThis.fetch = originalFetch; }
});

test('real React auth client logs in an admin and rejects Visitor/wrong password',
  { skip: !process.env.SMGS_AUTH_TEST_BASE_URL }, async () => {
    const originalFetch = globalThis.fetch;
    try {
      globalThis.fetch = (url, options) => originalFetch(new URL(url, process.env.SMGS_AUTH_TEST_BASE_URL), options);
      const loggedIn = await requestLogin('admin@auth-test.invalid', ' TestPass1 ');
      const store = storage(); saveWebSession(loggedIn, store);
      assert.equal(readWebSession(store).user.role, 'administrator');
      assert.equal(readWebSession(store).user.name, 'Temporary Admin');
      await assert.rejects(requestLogin('admin@auth-test.invalid', 'wrong-pass'));
      await assert.rejects(requestLogin('visitor@auth-test.invalid', ' TestPass1 '), /Visitor/);
      clearWebSession(store); assert.equal(readWebSession(store), null);
    } finally { globalThis.fetch = originalFetch; }
  });
