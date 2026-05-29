const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

async function main() {
  const outDir = path.resolve(process.cwd(), 'artifacts', 'ui_inspect');
  fs.mkdirSync(outDir, { recursive: true });
  const browser = await chromium.launch({ channel: 'msedge', headless: true });
  const context = await browser.newContext({
    storageState: path.resolve(process.cwd(), 'artifacts', 'ci_storage_state.json'),
    viewport: { width: 1800, height: 1200 },
    deviceScaleFactor: 1,
  });
  const page = await context.newPage();
  const url = 'https://<tenant-host>/shell/design/contentpackage/<package-id>/integrationflows/<artifact-id>';
  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 120000 });
  await page.waitForLoadState('networkidle', { timeout: 120000 }).catch(() => {});
  await page.waitForTimeout(7000);
  await page.screenshot({ path: path.join(outDir, 'route_loaded.png'), fullPage: false });

  const info = await page.evaluate(() => {
    const visibleText = (el) => {
      const rect = el.getBoundingClientRect();
      if (!rect.width || !rect.height) return false;
      const style = getComputedStyle(el);
      if (style.visibility === 'hidden' || style.display === 'none' || Number(style.opacity) === 0) return false;
      return true;
    };
    const elements = [...document.querySelectorAll('button, [role="button"], a, input, [title], [aria-label], .sapMBtn, .sapUiIcon')];
    return elements
      .filter(visibleText)
      .map((el, i) => {
        const rect = el.getBoundingClientRect();
        return {
          i,
          tag: el.tagName,
          role: el.getAttribute('role'),
          text: (el.innerText || el.textContent || '').trim().slice(0, 100),
          title: el.getAttribute('title'),
          aria: el.getAttribute('aria-label'),
          id: el.id,
          cls: el.className && String(el.className).slice(0, 180),
          x: Math.round(rect.x),
          y: Math.round(rect.y),
          w: Math.round(rect.width),
          h: Math.round(rect.height),
        };
      });
  });
  fs.writeFileSync(path.join(outDir, 'route_ui_elements.json'), JSON.stringify(info, null, 2), 'utf8');
  console.log(JSON.stringify({ count: info.length, outDir }, null, 2));
  await browser.close();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
