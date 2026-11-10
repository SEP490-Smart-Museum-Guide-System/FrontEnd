import { test, expect } from '@playwright/test';

async function openModal(page) {
  const users = [
    { id: 'staff', fullName: 'Nhân viên An', email: 'an@example.com', roles: ['Museum Staff'] },
    { id: 'curator', fullName: 'Giám tuyển Bình', email: 'binh@example.com', roles: ['Curator'] },
    { id: 'dual', fullName: 'Nhân viên Chi', email: 'chi@example.com', roles: ['Museum Staff', 'Curator'] },
  ];
  const assignment = u => ({ id: u.id, userId: u.id, userFullName: u.fullName, userEmail: u.email, userRoles: u.roles, museumId: 7, galleryId: null, artifactId: null, assignedAt: '2026-11-10T00:00:00Z' });
  const state = { assignments: [assignment(users[0])], writes: [], fail: false };
  await page.addInitScript(() => localStorage.setItem('smgs_web_session', JSON.stringify({ accessToken: 'test', fullName: 'Admin', email: 'admin@example.com', roles: ['Admin'], accessTokenExpiration: new Date(Date.now() + 3600000).toISOString() })));
  await page.route('**/api/**', async route => {
    const req = route.request(), url = new URL(req.url()), path = url.pathname.replace('/api/', '');
    const ok = data => route.fulfill({ json: { data } });
    if (req.method() === 'POST') {
      state.writes.push({ path, body: req.postDataJSON() });
      const user = users.find(u => path === `admin/accounts/${u.id}/assignments`);
      expect(user).toBeTruthy();
      expect(req.postDataJSON()).toEqual({ museumId: 7 });
      state.assignments.push(assignment(user));
      return ok(state.assignments.at(-1));
    }
    if (req.method() === 'DELETE') { state.writes.push({ path }); state.assignments = state.assignments.filter(a => path !== `admin/assignments/${a.id}`); return ok(null); }
    if (path === 'admin/accounts') {
      if (state.fail) return route.fulfill({ status: 503, json: { message: 'Không tải được nhân viên' } });
      const role = url.searchParams.get('role'), keyword = (url.searchParams.get('keyword') || '').toLowerCase();
      const rows = users.filter(u => (!role || u.roles.includes(role)) && `${u.fullName} ${u.email}`.toLowerCase().includes(keyword));
      // A one-item page exercises the existing allPages helper.
      const pageNumber = Number(url.searchParams.get('page') || 1);
      return ok({ items: rows.slice(pageNumber - 1, pageNumber), totalCount: rows.length, totalPages: rows.length });
    }
    if (path === 'admin/assignments') return ok(state.assignments);
    if (path === 'museums') return ok({ items: [{ id: 7, name: 'Bảo tàng thử', isActive: true }], totalCount: 1 });
    if (path.endsWith('/indoor-structure')) return ok({ buildings: [], floors: [], galleries: [] });
    return ok([]);
  });
  await page.goto('/');
  await page.getByRole('button', { name: 'Quản lý bảo tàng', exact: true }).click();
  await page.getByRole('button', { name: 'Phân công nhân viên', exact: true }).click();
  return state;
}

test('loads both roles, deduplicates, filters, assigns and confirms revoke', async ({ page }) => {
  const state = await openModal(page);
  const modal = page.getByRole('dialog');
  const candidates = modal.getByRole('region', { name: 'Danh sách nhân viên có thể phân công' });
  await expect(candidates.getByRole('button')).toHaveCount(3);
  await expect(candidates.getByRole('button', { name: 'Đã phân công' })).toBeDisabled();
  await modal.getByLabel('Lọc theo role').selectOption('Curator');
  await expect(candidates.getByRole('button')).toHaveCount(2);
  await modal.getByLabel('Tìm kiếm nhân viên (theo Tên hoặc Email)').fill('binh@');
  await expect(candidates.getByRole('button')).toHaveCount(1);
  await candidates.getByRole('button', { name: 'Phân công', exact: true }).click();
  await expect(candidates.getByRole('button', { name: 'Đã phân công' })).toBeDisabled();
  await expect(modal.getByText('Danh sách nhân viên đang phụ trách (2)', { exact: false })).toBeVisible();
  await expect(modal.getByText('10/11/2026', { exact: false }).first()).toBeVisible();
  expect(state.writes).toHaveLength(1);
  page.once('dialog', dialog => dialog.dismiss());
  await modal.getByRole('button', { name: 'Gỡ', exact: true }).last().click();
  expect(state.writes).toHaveLength(1);
  page.once('dialog', dialog => dialog.accept());
  await modal.getByRole('button', { name: 'Gỡ', exact: true }).last().click();
  await expect(candidates.getByRole('button', { name: 'Phân công', exact: true })).toBeEnabled();
  expect(state.writes).toHaveLength(2);
});

test('search errors are visible and do not fall back to unrelated accounts', async ({ page }) => {
  const state = await openModal(page);
  const modal = page.getByRole('dialog');
  await expect(modal.getByRole('region').getByRole('button')).toHaveCount(3);
  state.fail = true;
  await modal.getByLabel('Tìm kiếm nhân viên (theo Tên hoặc Email)').fill('missing');
  await expect(modal.getByRole('alert')).toHaveText('Không tải được nhân viên');
  await expect(modal.getByRole('region').getByRole('button')).toHaveCount(0);
});

