import { test, expect } from '@playwright/test';

// Valid PCM WAV fixture, not a mock player. Chromium decodes and plays these bytes.
function wav(seconds = 8) {
  const rate = 16000, size = rate * seconds * 2;
  const bytes = Buffer.alloc(44 + size);
  bytes.write('RIFF'); bytes.writeUInt32LE(size + 36, 4); bytes.write('WAVEfmt ', 8);
  bytes.writeUInt32LE(16, 16); bytes.writeUInt16LE(1, 20); bytes.writeUInt16LE(1, 22);
  bytes.writeUInt32LE(rate, 24); bytes.writeUInt32LE(rate * 2, 28);
  bytes.writeUInt16LE(2, 32); bytes.writeUInt16LE(16, 34);
  bytes.write('data', 36); bytes.writeUInt32LE(size, 40);
  for (let i = 0; i < rate * seconds; i++) bytes.writeInt16LE(Math.round(Math.sin(i * 2 * Math.PI * 220 / rate) * 1000), 44 + i * 2);
  return bytes;
}

async function observeAudio(page) {
  await page.addInitScript(() => {
    window.__audioNodes = [];
    const play = HTMLMediaElement.prototype.play;
    HTMLMediaElement.prototype.play = function (...args) {
      window.__audioNodes.push(this);
      return play.apply(this, args);
    };
  });
}
const playing = page => page.evaluate(() => {
  const audio = window.__audioNodes.at(-1);
  return !!audio && !audio.paused && audio.currentTime > 0.15;
});

test('real browser WAV playback supports pause, seek, rate, replay and cleanup', async ({ page }) => {
  await observeAudio(page);
  let requests = 0;
  await page.route('**/ai-tts/api/v1/speech', async route => {
    requests++;
    expect(route.request().postDataJSON().speed).toBe(1);
    await route.fulfill({ status: 200, contentType: 'audio/wav', body: wav() });
  });
  await page.goto('/');
  await page.getByRole('button', { name: 'Nghe thuyết minh âm thanh', exact: true }).click({ force: true });
  await expect.poll(() => playing(page)).toBe(true);
  expect(await page.evaluate(() => window.__audioNodes.at(-1).duration)).toBeCloseTo(8, 1);
  await page.getByRole('button', { name: 'Tạm dừng thuyết minh', exact: true }).click({ force: true });
  await expect.poll(() => page.evaluate(() => window.__audioNodes.at(-1).paused)).toBe(true);
  const before = await page.evaluate(() => window.__audioNodes.at(-1).currentTime);
  await page.waitForTimeout(300);
  expect(await page.evaluate(() => window.__audioNodes.at(-1).currentTime)).toBeCloseTo(before, 1);
  await page.getByRole('checkbox', { name: '1.25x', exact: true }).click({ force: true });
  expect(await page.evaluate(() => window.__audioNodes.at(-1).playbackRate)).toBe(1.25);
  const slider = page.getByRole('slider');
  const bounds = await slider.boundingBox();
  // Flutter exposes the slider thumb as the semantics element, not the whole track.
  const playerBounds = await page.getByRole('button', { name: 'Nghe thuyết minh âm thanh', exact: true }).boundingBox();
  await page.mouse.move(bounds.x + bounds.width / 2, bounds.y + bounds.height / 2);
  await page.mouse.down();
  await page.mouse.move(playerBounds.x + playerBounds.width * 0.7, bounds.y + bounds.height / 2, { steps: 8 });
  await page.mouse.up();
  await expect.poll(() => page.evaluate(() => window.__audioNodes.at(-1).currentTime)).toBeGreaterThan(3);
  await page.getByRole('button', { name: 'Nghe thuyết minh âm thanh', exact: true }).click({ force: true });
  await expect.poll(() => playing(page)).toBe(true);
  await page.evaluate(() => { window.__audioNodes.at(-1).currentTime = 7.9; });
  await page.getByRole('button', { name: 'Nghe lại thuyết minh', exact: true }).click({ force: true });
  await expect.poll(() => playing(page)).toBe(true);
  expect(await page.evaluate(() => window.__audioNodes.at(-1).currentTime)).toBeLessThan(2);
  expect(requests).toBe(1);
  await page.getByRole('button', { name: 'Đóng trình phát', exact: true }).click({ force: true });
  await expect.poll(() => page.evaluate(() => window.__audioNodes.at(-1).paused)).toBe(true);
  await expect.poll(() => page.evaluate(() => window.__audioNodes.at(-1).getAttribute('src'))).toBe('');
});

test('failed TTS shows retry; only successful WAV can start playback', async ({ page }) => {
  await observeAudio(page);
  let requests = 0;
  await page.route('**/ai-tts/api/v1/speech', route => {
    requests++;
    return requests === 1
      ? route.fulfill({ status: 503, json: { detail: 'unavailable' } })
      : route.fulfill({ status: 200, contentType: 'audio/wav', body: wav() });
  });
  await page.goto('/');
  await page.getByRole('button', { name: 'Nghe thuyết minh âm thanh', exact: true }).click({ force: true });
  await expect(page.getByText('Chưa tải được âm thanh. Kiểm tra kết nối và thử lại.', { exact: true })).toBeVisible();
  expect(await page.evaluate(() => window.__audioNodes.length)).toBe(0);
  await page.getByRole('button', { name: 'Nghe thuyết minh âm thanh', exact: true }).click({ force: true });
  await expect.poll(() => playing(page)).toBe(true);
  expect(requests).toBe(2);
});
