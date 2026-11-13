import {test, expect} from '@playwright/test';
for (const [role,label,section,target] of [
  ['Admin','Tổng quan hệ thống','Nội dung & trải nghiệm','Kho hiện vật'],
  ['Museum Staff','Bàn làm việc','Không gian & trải nghiệm','Chủ đề hiện vật'],
  ['Curator','Tổng quan thẩm định','Tra cứu & nhật ký','Tra cứu hiện vật'],
  ['Staff','Tổng quan vận hành','Giám sát hệ thống','Kiểm duyệt phản hồi'],
]) test(`${role}: grouped navigation stays accessible`,async({page})=>{
  await page.addInitScript(role=>localStorage.setItem('smgs_web_session',JSON.stringify({accessToken:'ui-test',fullName:'Kiểm tra giao diện',email:'ui@example.com',roles:[role],accessTokenExpiration:new Date(Date.now()+3600000).toISOString()})),role);
  await page.route('**/api/**',route=>{const path=new URL(route.request().url()).pathname;
    const data=path==='/api/museums'||path==='/api/me/museums'?[{id:1,name:'Bảo tàng thử',isActive:true}]:path.endsWith('/indoor-structure')?{buildings:[],floors:[],galleries:[]}:[];
    return route.fulfill({json:{data}});
  });
  const errors=[];page.on('pageerror',error=>errors.push(error.message));
  await page.goto('/');
  await expect(page.locator('.sidebar-menu').getByRole('button',{name:new RegExp('^'+label)})).toBeVisible();
  const toggle=page.getByRole('button',{name:section,exact:false});
  if(await toggle.getAttribute('aria-expanded')==='false')await toggle.click();
  await expect(page.locator('.sidebar-menu').getByRole('button',{name:new RegExp('^'+target)})).toBeVisible();
  await page.locator('.sidebar-menu').getByRole('button',{name:new RegExp('^'+target)}).click();
  await expect(page.locator('.sidebar-menu').getByRole('button',{name:new RegExp('^'+target)})).toHaveAttribute('aria-current','page');
  expect(errors).toEqual([]);
});
