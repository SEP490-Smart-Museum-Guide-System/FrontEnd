// Actual product UI + real JWT/API/PostgreSQL + manually edited script + Piper playback.
// Invoked by SMGS.SpeechLiveChecks; no page.route() or simulated responses.
import { chromium } from '@playwright/test';
import { writeFile } from 'node:fs/promises';
const api = process.env.SMGS_SPEECH_TEST_API;
if (!api?.startsWith('http://127.0.0.1:')) throw new Error('Use the isolated SMGS.SpeechLiveChecks runner.');
const browser = await chromium.launch({ channel: 'msedge', headless: true });
let page;
try {
  page = await browser.newPage({ viewport: { width: 1440, height: 1080 } });
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  // Test Vite instance uses VITE_API_BASE_URL to reach the actual isolated API.
  await page.goto('http://127.0.0.1:4174');
  await page.getByLabel('Email', { exact: true }).fill('admin@museum.vn');
  await page.getByLabel('Mật khẩu', { exact: true }).fill('Abc123@');
  const loginPromise = page.waitForResponse(r => r.url() === api + '/api/auth/login');
  await page.getByRole('button', { name: 'Đăng nhập', exact: true }).click();
  if (!(await loginPromise).ok()) throw new Error('Real seed account login failed.');
  await page.locator('.sidebar-item').filter({ hasText: 'Xưởng nội dung AI' }).click();
  await page.getByLabel('Nội dung bản nháp', { exact: true }).waitFor();
  const output = page.getByLabel('Nội dung bản nháp', { exact: true });
  const script = 'Máy nén khí có công suất bảy phẩy năm mã lực, do Xí nghiệp thiết bị lạnh sản xuất. Thân kim loại sơn màu xanh, phía bên phải có bánh đai.';
  await output.fill(script);
  const panel = page.getByRole('region', { name: 'Nghe bản thuyết minh', exact: true });
  const speechPromise = page.waitForResponse(r => /\/api\/artifacts\/\d+\/ai\/speech-preview$/.test(r.url()));
  await panel.getByRole('button', { name: 'Tạo giọng đọc', exact: true }).click();
  const speech = await speechPromise;
  if (!speech.ok() || !speech.headers()['content-type']?.startsWith('audio/wav')) throw new Error('Actual BE speech response failed.');
  const sentText = JSON.parse(speech.request().postData()).text;
  if (sentText !== script) throw new Error('Player did not use the edited script.');
  const audio = panel.locator('audio');
  await panel.getByRole('button', { name: 'Phát bản đọc', exact: true }).click();
  await page.waitForFunction(() => document.querySelector('audio[aria-label="Bản đọc tiếng Việt"]')?.currentTime > 0.5);
  const during = await audio.evaluate(a => ({ time: a.currentTime, paused: a.paused, duration: a.duration, error: a.error?.message || null }));
  await panel.getByRole('button', { name: 'Tạm dừng bản đọc', exact: true }).click();
  if (!(await audio.evaluate(a => a.paused))) throw new Error('Pause failed.');
  await panel.getByLabel('Tốc độ nghe bản nháp').selectOption('1.25');
  const rate = await audio.evaluate(a => a.playbackRate);
  if (rate !== 1.25) throw new Error('Playback speed failed.');
  await audio.evaluate(a => { a.currentTime = Math.min(2, a.duration / 2); });
  const seek = await audio.evaluate(a => a.currentTime);
  await panel.getByRole('button', { name: 'Phát bản đọc', exact: true }).click();
  await page.waitForFunction(() => document.querySelector('audio[aria-label="Bản đọc tiếng Việt"]')?.ended, null, { timeout: 30000 });
  await panel.screenshot({ path: 'test-results/studio-real-speech.png' });
  await panel.getByRole('button', { name: 'Phát bản đọc', exact: true }).click();
  await page.waitForFunction(() => document.querySelector('audio[aria-label="Bản đọc tiếng Việt"]')?.currentTime > 0.2);
  await audio.evaluate(a => { window.previousNarrationPlayer = a; });
  await output.fill(script + ' Đây là câu vừa chỉnh sửa.');
  if (await panel.locator('audio').count()) throw new Error('Old speech survived an edited script.');
  const stoppedOnEdit = await page.evaluate(() => window.previousNarrationPlayer.paused);
  if (!stoppedOnEdit) throw new Error('Old audio kept playing after script changed.');
  await panel.getByRole('button', { name: 'Tạo giọng đọc', exact: true }).waitFor();
  const report = { date: '2026-11-09', real_product_ui: true, real_jwt_login: true, real_postgresql: 'temporary schema', real_be: true,
    draft_origin: 'Text entered and edited in the actual product editor', real_qwen_generation: false, real_piper: true, audio_source: 'HTTP response in product audio player, no sample WAV file',
    speechStatus: speech.status(), editedTextReachedBE: sentText === script, during, rate, seek,
    completed: true, stoppedOnEdit, editedScriptClearsOldAudio: true, errors, human_listening_verified: false };
  if (errors.length) throw new Error(JSON.stringify(errors));
  await writeFile(new URL('../../../AI-System/evaluations/tts-2026-11-09/system-ui.json', import.meta.url), JSON.stringify(report, null, 2));
  console.log(JSON.stringify(report, null, 2));
} catch (error) {
  await page?.screenshot({ path: 'test-results/studio-real-speech-failed.png' });
  throw error;
} finally { await browser.close(); }
