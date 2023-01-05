const { test, expect } = require('@playwright/test');

test.only('localhost locator', async ({ context}) => {
  const page = await context.newPage();
  await page.goto("https://www.kanxue.com/")
  const html = await page.content();
  await page.waitForTimeout(5000);
  console.log(html);

  for(var i = 0; i < 30; i++){
    console.log(i)
    page.locator('text=加载更多').first().click()
    await page.waitForTimeout(5000);
    /*
    console.log(await page.title());
    console.log(await page.url());
    */
    console.log(await page.content());
  }


});

