import { test, expect } from '@playwright/test';

test('Visitor web opens Flutter instead of the React SPA and preserves registration query', async ({ page, request }) => {
  const redirect = await request.get('/visitor?mode=register', { maxRedirects: 0 });
  expect(redirect.status()).toBe(302);
  expect(redirect.headers().location).toBe('/visitor/?mode=register');
  const pageErrors = [];
  page.on('pageerror', error => pageErrors.push(error.message));
  const response = await page.goto('/visitor/');
  expect(response.status()).toBe(200);
  expect(await response.text()).toContain('<base href="/visitor/">');
  await expect(page.locator('flutter-view')).toBeAttached();
  await expect(page.locator('canvas').first()).toBeAttached();
  await expect(page.locator('#loading')).toHaveCount(0);
  await expect(page.locator('#root')).toHaveCount(0);
  expect(pageErrors).toEqual([]);
});
