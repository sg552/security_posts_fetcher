const { test, expect } = require('@playwright/test');

test.only('localhost locator', async ({ context }) => {
  const page = await context.newPage();
  await page.goto("https://www.kanxue.com/")
  const html = await page.content();
  await page.waitForTimeout(2000);
  console.log(html);

  for(var i = 0; i < page_end ; i++){
    console.log(i)
    page.locator('text=加载更多').first().click()
    await page.waitForTimeout(2000);
    if(i >= page_start){
      console.log(await page.content());
    }
  }


});

