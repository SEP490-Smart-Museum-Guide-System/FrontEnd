import { test, expect } from '@playwright/test';
const staffId = '11111111-1111-4111-8111-111111111111';
async function fixture(page, role = 'Admin') {
  const writes = [], reads = [], errors = [];
  page.on('pageerror', error => errors.push(error.message));
  const state = {
    accounts: [{ id: staffId, fullName: 'Nhân viên thử', email: 'staff@example.invalid', phoneNumber: '0912345678', roles: ['Museum Staff'], assignments: [], isActive: true }],
    topics: [], artifactTopics: [], badges: [], questions: [{ id: 1, artifactId: 11, content: 'Câu hỏi chờ duyệt', explanation: 'Giải thích kiểm thử', languageCode: 'vi', status: 'draft', options: [{ id: 1, content: 'Lựa chọn đúng', isCorrect: true }, { id: 2, content: 'Lựa chọn khác', isCorrect: false }] }], quizzes: [], resources: [], products: [], rejectAccount: false,
    orders: [{ id: '22222222-2222-4222-8222-222222222222', museumId: 7, productName: 'Gói kiểm thử', productKind: 'digital', amount: 12000, currency: 'VND', seats: 1, buyerName: 'Khách kiểm thử', buyerDetails: {}, status: 'pending', createdAt: '2026-11-04T00:00:00Z' }],
    transactions: [{ id: '33333333-3333-4333-8333-333333333333', status: 'pending', createdAt: '2026-11-04T00:00:00Z' }],
  };
  const structure = { layout: 'floors', buildings: [{ id: 2, name: 'Nhà A' }], floors: [{ id: 3, buildingId: 2, buildingName: 'Nhà A', name: 'Tầng 1', levelNo: 1 }], galleries: [{ id: 4, floorId: 3, name: 'Phòng kiểm thử' }] };
  const museum = { id: 7, name: 'Bảo tàng kiểm thử', isActive: true };
  const artifact = { id: 11, museumId: 7, galleryId: 4, name: 'Hiện vật kiểm thử', code: 'HV-11', isActive: true, media: [] };
  await page.addInitScript(data => { localStorage.setItem('smgs_web_session', JSON.stringify(data)); }, { accessToken: 'fixture-token', fullName: 'Quản trị kiểm thử', email: 'tester@example.invalid', roles: [role], accessTokenExpiration: new Date(Date.now() + 3600000).toISOString() });
  await page.route('**/api/**', async route => {
    const request = route.request(), path = new URL(request.url()).pathname.replace(/^\/api\//, ''), method = request.method();
    const body = request.postDataJSON();
    const ok = data => route.fulfill({ status: 200, json: { data } });
    if (method !== 'GET') writes.push({ method, path, body }); else reads.push(request.url());
    if (path === 'museums' && method === 'GET') return ok({ items: [museum], totalPages: 1, totalCount: 1 });
    if (path === 'me/museums') return ok([museum]);
    if (path === 'museums/cities') return ok([]);
    if (path === 'artifacts') return ok({ items: [artifact], totalPages: 1, totalCount: 1 });
    if (path === 'museums/7/galleries') return ok([{ id: 4, name: 'Phòng kiểm thử', floorId: 3 }]);
    if (path === 'museums/7/indoor-structure') return ok(structure);
    if (path === 'museums/7/galleries/4' && method === 'PUT') { Object.assign(structure.galleries[0], body); return ok(structure.galleries[0]); }
    if (path === 'admin/assignments') return ok(state.accounts.flatMap(u => u.assignments));
    if (path.startsWith('admin/assignments/') && method === 'DELETE') { state.accounts[0].assignments = state.accounts[0].assignments.filter(a => a.id !== Number(path.split('/').at(-1))); return ok(true); }
    if (path === 'admin/roles') return ok(['Admin', 'Museum Staff', 'Staff', 'Curator', 'Visitor']);
    if (path === 'admin/accounts' && method === 'GET') return ok({ items: state.accounts, totalPages: 1, totalCount: state.accounts.length });
    if (path === `admin/accounts/${staffId}` && method === 'GET') return ok(state.accounts[0]);
    if (path === `admin/accounts/${staffId}` && method === 'PUT') {
      if (state.rejectAccount) return route.fulfill({ status: 400, json: { message: 'Email đã được sử dụng.' } });
      Object.assign(state.accounts[0], body); return ok(state.accounts[0]);
    }
    if (path === `admin/accounts/${staffId}/roles` && method === 'PUT') { state.accounts[0].roles = body.roles; return ok(state.accounts[0]); }
    if (path === `admin/accounts/${staffId}/assignments` && method === 'GET') return ok(state.accounts[0].assignments);
    if (path === `admin/accounts/${staffId}/assignments` && method === 'POST') { const assignment = { id: 9, ...body, museumName: museum.name, galleryName: 'Phòng kiểm thử', artifactName: artifact.name }; state.accounts[0].assignments.push(assignment); return ok(assignment); }
    if (path === `admin/accounts/${staffId}/assignments/9` && method === 'DELETE') { state.accounts[0].assignments = []; return ok(true); }
    if (path === 'question-bank/questions' && method === 'GET') return ok(state.questions);
    if (path === 'question-bank/questions' && method === 'POST') { const row = { ...body, id: 2, artifactId: 11, status: 'draft', options: body.options.map((o, i) => ({ ...o, id: i + 10 })) }; state.questions.push(row); return ok(row); }
    if (path === 'question-bank/questions/1/review') { state.questions[0].status = body.approve ? 'approved' : 'rejected'; return ok(state.questions[0]); }
    if (path === 'question-bank/quizzes' && method === 'GET') return ok(state.quizzes);
    if (path === 'question-bank/quizzes' && method === 'POST') { const row = { ...body, id: 5, status: 'draft', questions: body.questionIds.map(id => ({ questionId: id })) }; state.quizzes.push(row); return ok(row); }
    if (path === 'question-bank/quizzes/5/publish') { state.quizzes[0].status = 'published'; return ok(state.quizzes[0]); }
    if (path === 'commerce/museums/7/resources' && method === 'GET') return ok(state.resources);
    if (path === 'commerce/museums/7/resources' && method === 'POST') { const row = { ...body, id: 6, museumId: 7 }; state.resources.push(row); return ok(row); }
    if (path === 'commerce/museums/7/products/manage') return ok(state.products);
    if (path === 'commerce/museums/7/products' && method === 'POST') { const row = { ...body, id: 8, museumId: 7 }; state.products.push(row); return ok(row); }
    if (path === 'commerce/museums/7/orders') return ok(state.orders);
    if (path === `commerce/orders/${state.orders[0].id}/manage`) return ok({ order: state.orders[0], transactions: state.transactions, invoice: state.orders[0].status === 'paid' ? { number: 'SMGS-TEST', amount: 12000, currency: 'VND', buyerName: 'Khách kiểm thử', issuedAt: '2026-11-04T00:00:00Z' } : null });
    if (path === `commerce/payments/${state.transactions[0].id}/confirm`) { Object.assign(state.transactions[0], body, { status: body.succeeded ? 'succeeded' : 'failed' }); state.orders[0].status = body.succeeded ? 'paid' : 'pending'; return ok(state.transactions[0]); }
    if (path === 'commerce/museums/7/revenue') return ok([{ currency: 'VND', paidOrders: 1, revenue: 12000, failedAttempts: 0 }]);
    if (path === 'museums/7/topics' || path === 'topics') { if (method === 'GET') return ok({ items: state.topics, totalPages: 1, totalCount: state.topics.length }); const row = { ...body, id: 13, artifactCount: 0, isActive: true }; state.topics.push(row); return ok(row); }
    if (path === 'artifacts/11/topics') { if (method === 'PUT') state.artifactTopics = state.topics.filter(t => body.topicIds.includes(t.id)); return ok(state.artifactTopics); }
    if (path === 'gamification/badges') { if (method === 'POST') { const row = { id: 12, ...body, ruleJson: JSON.stringify({ Metric: body.metric, Threshold: body.threshold }) }; state.badges.push(row); return ok(row); } return ok(state.badges); }
    if (['feedbacks', 'complaints', 'tours/manage', 'artifact-contents', 'artifacts/11/contents/versions', 'gamification/badges', 'museums/7/indoor-maps'].includes(path)) return ok([]);
    return route.fulfill({ status: 404, json: { message: `Fixture chưa hỗ trợ ${method} ${path}` } });
  });
  await page.goto('/');
  return { state, writes, reads, errors };
}
test('account edits reject failures, change role, assign and revoke exact scope', async ({ page }) => {
  const f = await fixture(page);
  await page.getByRole('button', { name: 'Người dùng & Phân quyền', exact: true }).click();
  await page.getByRole('button', { name: 'Chi tiết & chỉnh sửa' }).click();
  const dialog = page.getByRole('dialog', { name: 'Chi tiết tài khoản' });
  f.state.rejectAccount = true;
  await dialog.getByLabel('Email', { exact: true }).fill('taken@example.invalid');
  await dialog.getByRole('button', { name: 'Lưu thông tin', exact: true }).click();
  await expect(dialog.getByRole('alert')).toContainText('Email đã được sử dụng');
  await expect(dialog.getByLabel('Email', { exact: true })).toHaveValue('taken@example.invalid');
  f.state.rejectAccount = false;
  await dialog.getByLabel('Họ và tên').fill('Nhân viên cập nhật');
  await dialog.getByLabel('Email', { exact: true }).fill('changed@example.invalid');
  await dialog.getByRole('button', { name: 'Lưu thông tin', exact: true }).click();
  await expect.poll(() => f.state.accounts[0].fullName).toBe('Nhân viên cập nhật');
  await expect(dialog.getByLabel('Vai trò', { exact: true })).toBeVisible();
  await dialog.getByLabel('Vai trò', { exact: true }).selectOption('Curator');
  await dialog.getByRole('button', { name: 'Lưu vai trò', exact: true }).click();
  await expect.poll(() => f.state.accounts[0].roles).toEqual(['Curator']);
  await dialog.getByLabel('Bảo tàng', { exact: true }).selectOption('7');
  await dialog.getByLabel('Phòng trưng bày', { exact: true }).selectOption('4');
  await dialog.getByLabel('Hiện vật', { exact: true }).selectOption('11');
  await dialog.getByRole('button', { name: 'Thêm phân công' }).click();
  await expect.poll(() => f.state.accounts[0].assignments.length).toBe(1);
  expect(f.state.accounts[0].assignments[0]).toMatchObject({ museumId: 7, galleryId: 4, artifactId: 11 });
  page.once('dialog', dialog => dialog.accept());
  await dialog.getByRole('button', { name: 'Thu hồi', exact: true }).click();
  await expect.poll(() => f.state.accounts[0].assignments.length).toBe(0);
  expect(f.errors).toEqual([]);
});
test('curator reviews a question, builds a quiz from approved questions and publishes', async ({ page }) => {
  const f = await fixture(page, 'Curator');
  await page.getByRole('button', { name: 'Thẩm định câu hỏi & quiz', exact: true }).click();
  await page.getByLabel('Hiện vật', { exact: true }).selectOption('11');
  await page.getByRole('button', { name: 'Thẩm định', exact: true }).click();
  await page.getByRole('dialog').getByRole('button', { name: 'Lưu', exact: true }).click();
  await expect.poll(() => f.state.questions[0].status).toBe('approved');
  await expect(page.getByRole('dialog')).toHaveCount(0);
  await page.getByRole('button', { name: 'Tạo bộ câu hỏi', exact: true }).click();
  await page.getByLabel('Tên bộ câu hỏi').fill('Bộ câu hỏi đã duyệt');
  await page.getByRole('checkbox', { name: 'Câu hỏi chờ duyệt' }).check();
  await page.getByRole('dialog').getByRole('button', { name: 'Lưu', exact: true }).click();
  await expect.poll(() => f.state.quizzes.length).toBe(1);
  page.once('dialog', dialog => dialog.accept());
  await page.getByRole('button', { name: 'Xuất bản', exact: true }).click();
  await expect.poll(() => f.state.quizzes[0].status).toBe('published');
  expect(f.writes.find(r => r.path === 'question-bank/quizzes')?.body).toMatchObject({ questionIds: [1], questionsPerAttempt: 1 });
  expect(f.errors).toEqual([]);
});
test('museum staff creates question options with exactly one correct answer', async ({ page }) => {
  const f = await fixture(page, 'Museum Staff');
  await page.getByRole('button', { name: 'Ngân hàng câu hỏi', exact: true }).click();
  await page.getByLabel('Hiện vật', { exact: true }).selectOption('11');
  await page.getByRole('button', { name: 'Thêm câu hỏi', exact: true }).click();
  await page.getByLabel('Nội dung câu hỏi').fill('Câu hỏi được tạo từ form');
  await page.getByLabel('Nội dung đáp án 1').fill('Đáp án A');
  await page.getByLabel('Nội dung đáp án 2').fill('Đáp án B');
  await page.getByLabel('Đáp án đúng 2').check();
  await page.getByRole('dialog').getByRole('button', { name: 'Lưu', exact: true }).click();
  await expect.poll(() => f.state.questions.length).toBe(2);
  expect(f.state.questions[1].options.map(o => o.isCorrect)).toEqual([false, true]);
  await expect(page.getByRole('button', { name: 'Thẩm định', exact: true })).toHaveCount(0);
  expect(f.errors).toEqual([]);
});
test('commerce config saves real resource IDs and confirms payment before invoice appears', async ({ page }) => {
  const f = await fixture(page);
  await page.getByRole('button', { name: 'Dịch vụ số & giao dịch', exact: true }).click();
  await page.getByRole('button', { name: 'Nội dung & quyền', exact: true }).click();
  await page.getByRole('button', { name: 'Thêm nội dung / quyền', exact: true }).click();
  await page.getByRole('dialog').getByLabel('Tên', { exact: true }).fill('Thuyết minh hiện vật');
  await page.getByLabel('Mức truy cập').selectOption('premium');
  await page.getByLabel('Hiện vật liên quan').selectOption('11');
  await page.getByRole('button', { name: 'Lưu cấu hình', exact: true }).click();
  await expect.poll(() => f.state.resources.length).toBe(1);
  await page.getByRole('button', { name: 'Gói dịch vụ', exact: true }).click();
  await page.getByRole('button', { name: 'Thêm gói dịch vụ', exact: true }).click();
  await page.getByRole('dialog').getByLabel('Tên', { exact: true }).fill('Gói mới');
  await page.getByLabel('Giá', { exact: true }).fill('12000');
  await page.getByLabel('Thời hạn tính từ lúc thanh toán (giờ)').fill('24');
  await page.getByRole('checkbox', { name: 'Thuyết minh hiện vật', exact: true }).check();
  await page.getByRole('button', { name: 'Lưu cấu hình', exact: true }).click();
  await expect.poll(() => f.state.products.length).toBe(1);
  expect(f.state.products[0]).toMatchObject({ resourceIds: [6], validityHours: 24, validityStartsAt: 'payment', price: 12000 });
  await page.getByRole('button', { name: 'Đơn hàng', exact: true }).click();
  await page.getByRole('button', { name: 'Chi tiết & đối soát' }).click();
  await expect(page.getByText('Thông tin hóa đơn', { exact: true })).toHaveCount(0);
  await page.getByRole('button', { name: 'Đối soát lần thanh toán này' }).click();
  await page.getByLabel('Mã tham chiếu thanh toán').fill('REF-REAL-TEST');
  page.once('dialog', dialog => dialog.accept());
  await page.getByRole('button', { name: 'Xác nhận đối soát', exact: true }).click();
  await expect(page.getByText('SMGS-TEST', { exact: true })).toBeVisible();
  expect(f.state.orders[0].status).toBe('paid');
  await page.getByRole('dialog').getByRole('button', { name: 'Đóng', exact: true }).click();
  await page.getByRole('button', { name: 'Báo cáo doanh thu', exact: true }).click();
  await expect(page.getByText('1 đơn đã thanh toán · 0 lần thanh toán thất bại')).toBeVisible();
  expect(f.reads.some(url => url.includes('/revenue?from=') && url.includes('to='))).toBe(true);
  expect(f.errors).toEqual([]);
});

test('topic creation and assignment persist the exact selected IDs', async ({ page }) => {
  const f = await fixture(page);
  await page.getByRole('button', { name: 'Chủ đề hiện vật', exact: true }).click();
  await page.getByRole('button', { name: 'Thêm chủ đề', exact: true }).click();
  await page.getByLabel('Tên chủ đề').fill('Văn hóa kiểm thử');
  await page.getByRole('button', { name: 'Lưu chủ đề', exact: true }).click();
  await expect.poll(() => f.state.topics.length).toBe(1);
  await page.getByLabel('Hiện vật để gán chủ đề').selectOption('11');
  await page.getByRole('checkbox', { name: 'Văn hóa kiểm thử', exact: true }).check();
  await page.getByRole('button', { name: 'Lưu danh sách chủ đề', exact: true }).click();
  await expect.poll(() => f.state.artifactTopics.length).toBe(1);
  expect(f.writes.find(r => r.path === 'artifacts/11/topics')?.body).toEqual({ topicIds: [13] });
  expect(f.errors).toEqual([]);
});
test('spatial editor sends real floor ID when editing a gallery', async ({ page }) => {
  const f = await fixture(page);
  await page.getByRole('button', { name: 'Bản đồ trong bảo tàng', exact: true }).click();
  await page.getByText('Quản lý tòa nhà, tầng & phòng trưng bày', { exact: true }).click();
  await page.getByRole('button', { name: 'Sửa phòng', exact: true }).click();
  await page.getByRole('dialog').getByLabel('Tên', { exact: true }).fill('Phòng đã cập nhật');
  await page.getByRole('dialog').getByRole('button', { name: 'Lưu', exact: true }).click();
  await expect(page.getByText('Phòng đã cập nhật', { exact: true })).toBeVisible();
  expect(f.writes.find(r => r.path === 'museums/7/galleries/4')?.body).toMatchObject({ name: 'Phòng đã cập nhật', floorId: 3 });
  expect(f.errors).toEqual([]);
});
test('badge definitions use the server rule JSON casing and create only on confirmation', async ({ page }) => {
  const f = await fixture(page);
  await page.getByRole('button', { name: 'Huy hiệu khám phá', exact: true }).click();
  await page.getByRole('button', { name: 'Tạo huy hiệu', exact: true }).click();
  await page.getByLabel('Mã huy hiệu').fill('TEST-3');
  await page.getByLabel('Tên huy hiệu').fill('Ba câu trả lời đúng');
  await page.getByLabel('Điều kiện').selectOption('quiz_correct');
  await page.getByLabel('Mốc đạt').fill('3');
  await page.getByRole('dialog').getByRole('button', { name: 'Tạo huy hiệu', exact: true }).click();
  await expect(page.getByText('Số câu trả lời đúng: 3', { exact: true })).toBeVisible();
  expect(f.state.badges[0]).toMatchObject({ metric: 'quiz_correct', threshold: 3, museumId: null });
  expect(f.errors).toEqual([]);
});

test('AI quiz suggestions enter the editable question bank instead of artifact-content review', async ({ page }) => {
  const f = await fixture(page, 'Museum Staff');
  await page.getByRole('button', { name: 'Xưởng nội dung AI', exact: true }).click();
  await page.getByRole('button', { name: 'Bộ câu hỏi trắc nghiệm', exact: true }).click();
  await page.getByRole('button', { name: 'Sinh nội dung bằng AI', exact: true }).click();
  await expect(page.locator('textarea')).toBeVisible();
  await page.locator('textarea').fill(JSON.stringify([{ question: 'Câu gợi ý đã hiệu đính', options: ['Dữ kiện đã kiểm chứng', 'Lựa chọn còn lại'], correctIndex: 0, explanation: 'Cần đối chiếu tài liệu bảo tàng' }]));
  await page.getByRole('button', { name: 'Chỉnh sửa & lưu vào Ngân hàng câu hỏi', exact: true }).click();
  await expect(page.getByRole('heading', { name: 'Gợi ý từ Xưởng AI', exact: true })).toBeVisible();
  expect(f.writes).toEqual([]);
  await page.getByRole('button', { name: 'Chỉnh sửa & lưu câu', exact: true }).click();
  await expect(page.getByLabel('Nội dung câu hỏi')).toHaveValue('Câu gợi ý đã hiệu đính');
  await page.getByRole('dialog').getByRole('button', { name: 'Lưu', exact: true }).click();
  await expect.poll(() => f.state.questions.length).toBe(2);
  expect(f.writes.filter(r => r.path.includes('/contents'))).toEqual([]);
  expect(f.state.questions[1].status).toBe('draft');
  await expect(page.getByRole('button', { name: 'Đã lưu câu hỏi', exact: true })).toBeDisabled();
  expect(f.errors).toEqual([]);
});
