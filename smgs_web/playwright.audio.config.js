import { defineConfig } from '@playwright/test';
export default defineConfig({
  testDir: './audio-e2e', timeout: 30000, workers: 1,
  use: {
    baseURL: 'http://127.0.0.1:5199',
    channel: process.env.PLAYWRIGHT_CHANNEL || (process.platform === 'win32' ? 'msedge' : undefined),
    headless: true, viewport: { width: 480, height: 1000 },
    launchOptions: { args: ['--mute-audio'] },
    trace: 'retain-on-failure', screenshot: 'only-on-failure',
  },
  webServer: {
    command: 'python -m http.server 5199 --bind 127.0.0.1 --directory ../smgs_mobile/build/audio_harness',
    url: 'http://127.0.0.1:5199', reuseExistingServer: false,
  },
});
