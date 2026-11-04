import { test, expect } from '@playwright/test';
const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aWQ0AAAAASUVORK5CYII=', 'base64');
async function fixture(page) {
  const state = { rows: [{ id: 7, name: 'Bảo tàng kiểm thử', cityCode: '79', address: 'Địa chỉ hiện tại', isActive: true, coverImageUrl: '' }], writes: [], reject: false, rejectCities: false };
  await page.addInitScript(session => localStorage.setItem('smgs_web_session', JSON.stringify(session)), {
    accessToken: 'fixture-token', fullName: 'Quản trị thử', email: 'admin@example.invalid', roles: ['Admin'], accessTokenExpiration: new Date(Date.now() + 3600000).toISOString(),
  });
  await page.route('**/api/**', async route => {
    const request = route.request(), path = new URL(request.url()).pathname.replace('/api/', '');
    const ok = data => route.fulfill({ status: 200, json: { data } });
    if (request.method() !== 'GET') {
      state.writes.push({ path, contentType: request.headers()['content-type'], body: request.postDataBuffer().toString() });
      if (state.reject) return route.fulfill({ status: 503, json: { message: 'Không lưu được ảnh. Hãy thử lại.' } });
      if (path === 'museums/with-image') { const row = { id: 8, name: 'Bảo tàng mới', address: 'Địa chỉ mới', cityCode: '79', isActive: true, coverImageUrl: '/api/museums/images/new.png' }; state.rows.push(row); return ok(row); }
      if (path === 'museums/7/with-image') { state.rows[0].coverImageUrl = '/api/museums/images/edited.png'; return ok(state.rows[0]); }
    }
    if (path === 'museums') return ok({ items: state.rows, totalCount: state.rows.length, totalPages: 1 });
    if (path === 'museums/cities') return state.rejectCities ? route.fulfill({ status: 503, json: { message: 'Chưa tải được tỉnh thành' } }) : ok([{ code: '79', name: 'Hồ Chí Minh' }]);
    if (path.endsWith('/indoor-structure')) return ok({ buildings: [], floors: [], galleries: [] });
    if (/^museums\/images\//.test(path)) return route.fulfill({ contentType: 'image/png', body: png });
    if (['artifacts', 'admin/accounts', 'complaints', 'feedbacks'].includes(path)) return ok({ items: [], totalCount: 0, totalPages: 1 });
    return ok([]);
  });
  await page.goto('/');
  await page.getByRole('button', { name: 'Bảo tàng & Google Maps', exact: true }).click();
  return state;
}
test('create museum selects an image, previews and sends it with metadata on save', async ({ page }) => {
  const state = await fixture(page);
  await page.getByRole('button', { name: 'Thêm Bảo Tàng Mới', exact: true }).click();
  const modal = page.locator('.modal-dialog');
  await modal.getByLabel('Tên bảo tàng *', { exact: true }).fill('Bảo tàng mới');
  await modal.getByRole('combobox', { name: /Tỉnh \/ Thành phố/ }).selectOption('79');
  await modal.getByLabel('Địa chỉ cụ thể *', { exact: true }).fill('Địa chỉ mới');
  await modal.getByLabel('Chọn ảnh đại diện').setInputFiles({ name: 'museum-cover.png', mimeType: 'image/png', buffer: png });
  await expect(modal.getByAltText('Xem trước ảnh đại diện bảo tàng')).toHaveAttribute('src', /^blob:/);
  expect(state.writes).toHaveLength(0);
  await modal.getByRole('button', { name: 'Tạo bảo tàng mới', exact: true }).click();
  await expect(modal).toHaveCount(0);
  expect(state.writes).toHaveLength(1);
  expect(state.writes[0].path).toBe('museums/with-image');
  expect(state.writes[0].contentType).toContain('multipart/form-data; boundary=');
  expect(state.writes[0].body).toContain('filename="museum-cover.png"');
  expect(state.writes[0].body).toContain('Bảo tàng mới');
  expect(state.writes[0].body).not.toContain('blob:');
});

test('city loading failure can be retried without losing museum form fields', async ({ page }) => {
  const state = await fixture(page);
  state.rejectCities = true;
  await page.getByRole('button', { name: 'Thêm Bảo Tàng Mới', exact: true }).click();
  const modal = page.locator('.modal-dialog');
  await modal.getByLabel('Tên bảo tàng *', { exact: true }).fill('Tên đang nhập');
  await expect(modal.getByRole('combobox', { name: 'Tỉnh / Thành phố', exact: true })).toBeDisabled();
  await expect(modal.getByRole('button', { name: 'Tải lại tỉnh / thành phố' })).toBeVisible();
  state.rejectCities = false;
  await modal.getByRole('button', { name: 'Tải lại tỉnh / thành phố' }).click();
  await modal.getByRole('combobox', { name: 'Tỉnh / Thành phố', exact: true }).selectOption('79');
  await expect(modal.getByLabel('Tên bảo tàng *', { exact: true })).toHaveValue('Tên đang nhập');
  expect(state.writes).toHaveLength(0);
});

test('opening hours select times and weekdays and reject a closing time before opening', async ({ page }) => {
  const state = await fixture(page);
  await page.getByRole('button', { name: 'Thêm Bảo Tàng Mới', exact: true }).click();
  const modal = page.locator('.modal-dialog');
  await modal.getByLabel('Tên bảo tàng *', { exact: true }).fill('Bảo tàng mới');
  await modal.getByRole('combobox', { name: /Tỉnh \/ Thành phố/ }).selectOption('79');
  await modal.getByLabel('Địa chỉ cụ thể *', { exact: true }).fill('Địa chỉ mới');
  await modal.getByLabel('Giờ mở cửa', { exact: true }).fill('08:30');
  await modal.getByLabel('Giờ đóng cửa', { exact: true }).fill('07:00');
  await expect(modal.getByRole('alert')).toHaveText('Giờ đóng cửa phải sau giờ mở cửa.');
  await modal.getByRole('button', { name: 'Tạo bảo tàng mới', exact: true }).click();
  expect(state.writes).toHaveLength(0);
  await modal.getByLabel('Giờ đóng cửa', { exact: true }).fill('17:15');
  await modal.getByRole('checkbox', { name: 'Thứ 2', exact: true }).uncheck();
  await modal.getByRole('checkbox', { name: 'Chủ nhật', exact: true }).uncheck();
  await modal.getByRole('button', { name: 'Tạo bảo tàng mới', exact: true }).click();
  await expect(modal).toHaveCount(0);
  expect(state.writes).toHaveLength(1);
  expect(state.writes[0].body).toContain('08:30 - 17:15 (Thứ 3, Thứ 4, Thứ 5, Thứ 6, Thứ 7)');
});
test('edit keeps the selected image and fields on server rejection, then retries', async ({ page }) => {
  const state = await fixture(page);
  await page.getByRole('button', { name: 'Chỉnh sửa thông tin bảo tàng', exact: true }).click();
  const modal = page.locator('.modal-dialog');
  await modal.getByLabel('Chọn ảnh đại diện').setInputFiles({ name: 'updated.png', mimeType: 'image/png', buffer: png });
  state.reject = true;
  await modal.getByRole('button', { name: 'Lưu thông tin', exact: true }).click();
  await expect(page.getByText('Không lưu được ảnh. Hãy thử lại.', { exact: true })).toBeVisible();
  await expect(modal.getByLabel('Tên bảo tàng *', { exact: true })).toHaveValue('Bảo tàng kiểm thử');
  await expect(modal.getByAltText('Xem trước ảnh đại diện bảo tàng')).toHaveAttribute('src', /^blob:/);
  state.reject = false;
  await modal.getByRole('button', { name: 'Lưu thông tin', exact: true }).click();
  await expect(modal).toHaveCount(0);
  expect(state.writes.map(w => w.path)).toEqual(['museums/7/with-image', 'museums/7/with-image']);
});
test('unsupported and oversized images do not upload; cancel never persists the selection', async ({ page }) => {
  const state = await fixture(page);
  await page.getByRole('button', { name: 'Thêm Bảo Tàng Mới', exact: true }).click();
  const modal = page.locator('.modal-dialog');
  const input = modal.getByLabel('Chọn ảnh đại diện');
  await input.setInputFiles({ name: 'bad.svg', mimeType: 'image/svg+xml', buffer: Buffer.from('<svg/>') });
  await expect(modal.getByRole('alert')).toContainText('PNG, JPEG hoặc WebP');
  await input.setInputFiles({ name: 'large.png', mimeType: 'image/png', buffer: Buffer.alloc(16 * 1024 * 1024) });
  await expect(modal.getByRole('alert')).toContainText('15 MB');
  await input.setInputFiles({ name: 'cancel.png', mimeType: 'image/png', buffer: png });
  await modal.getByRole('button', { name: 'Hủy', exact: true }).click();
  await expect(modal).toHaveCount(0); expect(state.writes).toHaveLength(0);
});
