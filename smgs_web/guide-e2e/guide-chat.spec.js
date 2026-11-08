import { test, expect } from '@playwright/test';

// HTTP fixtures verify the real Flutter screen. These are NOT results from a live model/DB.
const data = (supported = true) => ({ statusCode: 200, data: {
  artifactId: 17, supported,
  answer: supported ? 'Bình gốm dùng để đựng nước.' : 'Nội dung đã xuất bản của hiện vật chưa đủ thông tin.',
  sources: supported ? [{ contentVersionId: 91, versionNo: 2, title: 'Bình đựng nước', languageCode: 'vi' }] : [],
} });

test('Visitor asks a question and follow-up with source, then clears chat', async ({ page }) => {
  const requests = [], errors = [];
  page.on('pageerror', e => errors.push(e.message));
  await page.route('**/api/artifacts/17/guide/messages', async route => {
    requests.push(route.request().postDataJSON());
    await route.fulfill({ json: data() });
  });
  await page.goto('/');
  await page.getByRole('button', { name: 'Hiện vật này có ý nghĩa gì?', exact: true }).click({ force: true });
  await expect(page.getByText('Bình gốm dùng để đựng nước.', { exact: true })).toBeVisible();
  await expect(page.getByText('Bình đựng nước · Phiên bản 2', { exact: true })).toBeVisible();
  expect(requests[0].history).toEqual([]);
  await page.screenshot({ path: 'test-results/guide-chat-mobile.png' });
  await page.getByRole('textbox').fill('Nó dùng làm gì?');
  await page.getByRole('button', { name: 'Gửi', exact: true }).click({ force: true });
  await expect.poll(() => requests.length).toBe(2);
  expect(requests[1].history.map(turn => turn.role)).toEqual(['user', 'assistant']);
  await expect(page.getByText('Bình gốm dùng để đựng nước.', { exact: true })).toHaveCount(2);
  await page.getByRole('button', { name: 'Cuộc trò chuyện mới' }).click({ force: true });
  await expect(page.getByText('Bình gốm dùng để đựng nước.', { exact: true })).toHaveCount(0);
  expect(errors).toEqual([]);
});

test('Unavailable model shows an error and allows retry, without a fabricated answer', async ({ page }) => {
  let count = 0;
  await page.route('**/api/artifacts/17/guide/messages', route => ++count === 1
    ? route.fulfill({ status: 503, json: { message: 'Trợ lý chưa được kết nối dịch vụ AI.' } })
    : route.fulfill({ json: data() }));
  await page.goto('/');
  await page.getByRole('button', { name: 'Hiện vật này có ý nghĩa gì?', exact: true }).click({ force: true });
  await expect(page.getByText(/Chưa thể trả lời lúc này/)).toBeVisible();
  await expect(page.getByRole('button', { name: 'Đọc và nghe câu trả lời' })).toHaveCount(0);
  await page.getByRole('button', { name: 'Thử lại câu hỏi' }).click({ force: true });
  await expect(page.getByText('Bình gốm dùng để đựng nước.', { exact: true })).toBeVisible();
  expect(count).toBe(2);
});

test('Insufficient source data produces a refusal with no citation or audio action', async ({ page }) => {
  await page.route('**/api/artifacts/17/guide/messages', route => route.fulfill({ json: data(false) }));
  await page.goto('/');
  await page.getByRole('button', { name: 'Hiện vật này có ý nghĩa gì?', exact: true }).click({ force: true });
  await expect(page.getByText('Nội dung đã xuất bản của hiện vật chưa đủ thông tin.', { exact: true })).toBeVisible();
  await expect(page.getByText('Nội dung tham khảo', { exact: true })).toHaveCount(0);
  await expect(page.getByRole('button', { name: 'Đọc và nghe câu trả lời' })).toHaveCount(0);
});
