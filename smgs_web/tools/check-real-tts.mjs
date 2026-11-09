// Live Vite proxy + real TTS + actual frontend adapter + Edge media decoder.
// Start Vite on 4173 and tools/start-local-tts.ps1 first; no BE/DB calls mocked.
import { chromium } from '@playwright/test';
import { readFile, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';

const reportUrl = new URL('../../../AI-System/evaluations/tts-2026-11-09/', import.meta.url);
const report = JSON.parse(await readFile(new URL('results.json', reportUrl), 'utf8'));
const browser = await chromium.launch({ channel: 'msedge', headless: true });
try {
  const page = await browser.newPage();
  // Use the real server origin/proxy without loading the product's login/DB flow.
  await page.goto('http://127.0.0.1:4173/ai-tts/ready');
  const health = await page.evaluate(async () => (await import('/src/services/ttsApi.js')).checkTtsHealthApi());
  if (!health.ok) throw new Error(`Real TTS unavailable: ${JSON.stringify(health)}`);
  const cases = [];
  for (const sample of report.cases.slice(0, 3)) {
    const result = await page.evaluate(async ({ text, speed }) => {
      const service = await import('/src/services/ttsApi.js');
      const response = await service.generateSpeechApi({ text, speed });
      const context = new AudioContext();
      try {
        const decoded = await context.decodeAudioData(await response.blob.arrayBuffer());
        let peak = 0;
        for (const n of decoded.getChannelData(0)) peak = Math.max(peak, Math.abs(n));
        window.ttsTestAudio = new Audio(response.audioUrl);
        const button = document.createElement('button');
        button.id = 'play-real-tts'; button.textContent = 'Phát thử TTS tiếng Việt';
        button.onclick = () => window.ttsTestAudio.play().catch(e => { window.ttsTestPlaybackError = e.message; });
        document.body.replaceChildren(button);
        return { bytes: response.blob.size, voice: response.voice, cacheHit: response.cacheHit,
          decodedDuration: decoded.duration, decodedSampleRate: decoded.sampleRate, peak };
      } finally { await context.close(); }
    }, sample);
    await page.locator('#play-real-tts').click();
    await page.waitForFunction(() => window.ttsTestAudio.currentTime > 0.5 || window.ttsTestPlaybackError, null, { timeout: 10000 });
    const during = await page.evaluate(() => ({ currentTime: window.ttsTestAudio.currentTime,
      paused: window.ttsTestAudio.paused, error: window.ttsTestPlaybackError || window.ttsTestAudio.error?.message || null }));
    if (during.error || during.paused || during.currentTime < 0.5 || result.peak < 0.001) throw new Error(JSON.stringify({ during, result }));
    await page.waitForFunction(() => window.ttsTestAudio.ended, null, { timeout: 20000 });
    const ended = await page.evaluate(() => ({ ended: window.ttsTestAudio.ended, currentTime: window.ttsTestAudio.currentTime,
      duration: window.ttsTestAudio.duration, error: window.ttsTestAudio.error?.message || null }));
    if (ended.error) throw new Error(ended.error);
    const cache = await page.evaluate(async ({ text, speed }) => {
      const r = await (await import('/src/services/ttsApi.js')).generateSpeechApi({ text, speed });
      return { cacheHit: r.cacheHit, sameUrl: r.audioUrl === window.ttsTestAudio.src };
    }, sample);
    if (!cache.cacheHit || !cache.sameUrl) throw new Error('Frontend session audio cache failed');
    cases.push({ name: sample.name, ...result, during, ...ended, clientCache: cache });
    await page.evaluate(() => URL.revokeObjectURL(window.ttsTestAudio.src));
  }
  const data = { date: '2026-11-09', scope: 'Actual React TTS adapter + Vite proxy + Piper HTTP + Edge headless playback',
    backend_db_tested: false, flutter_player_tested: false, human_listening_verified: false, health, cases };
  await writeFile(new URL('browser-playback.json', reportUrl), JSON.stringify(data, null, 2));
  console.log(JSON.stringify({ report: fileURLToPath(new URL('browser-playback.json', reportUrl)), ...data }, null, 2));
} finally { await browser.close(); }
