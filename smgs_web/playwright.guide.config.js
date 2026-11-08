import { defineConfig } from '@playwright/test';
export default defineConfig({
  testDir: './guide-e2e', timeout: 40000, workers: 1,
  use: {
    baseURL: 'http://127.0.0.1:5198',
    channel: process.env.PLAYWRIGHT_CHANNEL || (process.platform === 'win32' ? 'msedge' : undefined),
    headless: true, viewport: { width: 390, height: 844 },
    trace: 'retain-on-failure', screenshot: 'only-on-failure',
  },
  webServer: {
    command: 'python -m http.server 5198 --bind 127.0.0.1 --directory ../smgs_mobile/build/guide_harness',
    url: 'http://127.0.0.1:5198', reuseExistingServer: false,
  },
});
