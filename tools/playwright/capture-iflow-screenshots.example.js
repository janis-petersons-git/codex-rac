const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

function sanitizeFileName(value) {
  return value.replace(/[\\/:*?"<>|]+/g, '_').replace(/\s+/g, '_');
}

function zoomOutClicksForTitle(title) {
  const rules = [
    [/Route Idocs From S4HANA/i, 5],
    [/Replicate Material From S4HANA/i, 5],
    [/Replicate B2B Customer/i, 5],
    [/SalesKits$/i, 3],
    [/SalesKits_/i, 2],
    [/CommunicationPreferences/i, 2],
    [/Access DataStore/i, 1],
    [/FetchToken/i, 1],
    [/Process Customized Material/i, 1],
  ];
  for (const [pattern, clicks] of rules) {
    if (pattern.test(title)) return clicks;
  }
  return 1;
}

function panForTitle(title) {
  const rules = [
    [/Process Customized Material/i, { dx: 0, dy: 120 }],
    [/SalesKits_ManualTrigger/i, { dx: 0, dy: 120 }],
    [/IF_Commerce_TO_S4_/i, { dx: 0, dy: 130 }],
  ];
  for (const [pattern, pan] of rules) {
    if (pattern.test(title)) return pan;
  }
  return { dx: 0, dy: 0 };
}

async function maybeClick(page, roleOptions, timeout = 3000) {
  try {
    const locator = page.getByRole(roleOptions.role, roleOptions.options).first();
    if (await locator.count()) {
      await locator.click({ timeout });
      return true;
    }
  } catch (_) {
    return false;
  }
  return false;
}

async function panCanvas(page, pan) {
  if (!pan || (!pan.dx && !pan.dy)) return false;

  // The SAP designer canvas can open with the iFlow partly hidden under
  // the toolbar. Dragging the white canvas area down mirrors the manual fix.
  const start = await page.evaluate(() => {
    const candidates = [
      ...document.querySelectorAll('svg'),
      ...document.querySelectorAll('canvas'),
      ...document.querySelectorAll('[class*="canvas" i]'),
    ]
      .map((node) => node.getBoundingClientRect && node.getBoundingClientRect())
      .filter((rect) => rect && rect.width > 500 && rect.height > 400)
      .sort((a, b) => (b.width * b.height) - (a.width * a.height));

    const rect = candidates[0];
    if (!rect) return { x: Math.round(window.innerWidth * 0.62), y: Math.round(window.innerHeight * 0.58) };

    return {
      x: Math.min(rect.right - 160, Math.max(rect.left + 420, rect.left + rect.width * 0.62)),
      y: Math.min(rect.bottom - 180, Math.max(rect.top + 360, rect.top + rect.height * 0.58)),
    };
  });

  await page.mouse.move(start.x, start.y);
  await page.mouse.down();
  await page.mouse.move(start.x + pan.dx, start.y + pan.dy, { steps: 16 });
  await page.mouse.up();
  await page.waitForTimeout(700);
  return true;
}

async function clickCanvasZoomOut(page) {
  const box = await page.evaluate(() => {
    const title = [...document.querySelectorAll('title')]
      .find((node) => (node.textContent || '').includes('Zoom Out'));
    const target = title && title.parentElement;
    if (!target || !target.getBoundingClientRect) return null;
    const rect = target.getBoundingClientRect();
    return { x: rect.x, y: rect.y, w: rect.width, h: rect.height };
  });
  if (box && box.w > 0 && box.h > 0) {
    await page.mouse.click(box.x + box.w / 2, box.y + box.h / 2);
    return true;
  }

  // Fallback for tenants where the SVG title is not exposed.
  await page.keyboard.press('F7').catch(() => {});
  return false;
}

async function main() {
  const baseDir = process.cwd();
  const outDir = path.resolve(baseDir, 'artifacts', 'iflow_screenshots_canvaszoom');
  const storageStatePath = path.resolve(baseDir, 'artifacts', 'ci_storage_state.json');
  const uploadedPath = path.resolve('examples/migration/sample-uploaded-iflows.json');
  fs.mkdirSync(outDir, { recursive: true });

  const uploaded = JSON.parse(fs.readFileSync(uploadedPath, 'utf8'));

  const browser = await chromium.launch({
    channel: 'msedge',
    headless: true,
  });

  const context = await browser.newContext({
    storageState: storageStatePath,
    viewport: { width: 1800, height: 1200 },
    deviceScaleFactor: 1,
  });

  const results = [];
  for (const artifact of uploaded) {
    const page = await context.newPage();
    const url = `https://<tenant-host>/shell/design/contentpackage/<package-id>/integrationflows/${encodeURIComponent(artifact.Id)}`;
    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 120000 });
    await page.waitForLoadState('networkidle', { timeout: 120000 }).catch(() => {});
    await page.waitForTimeout(4500);

    await maybeClick(page, { role: 'button', options: { name: 'Collapse Navigation' } }, 4000);
    await page.waitForTimeout(1000);

    const zoomClicks = zoomOutClicksForTitle(artifact.Title);
    for (let i = 0; i < zoomClicks; i += 1) {
      await clickCanvasZoomOut(page);
      await page.waitForTimeout(500);
    }

    const pan = panForTitle(artifact.Title);
    await panCanvas(page, pan);

    const fileName = `${sanitizeFileName(artifact.Title)}.png`;
    const screenshotPath = path.join(outDir, fileName);
    await page.screenshot({ path: screenshotPath, animations: 'disabled' });

    results.push({
      title: artifact.Title,
      id: artifact.Id,
      version: artifact.Version,
      url,
      canvasZoomOutClicks: zoomClicks,
      pan,
      screenshotPath,
    });

    await page.close();
  }

  fs.writeFileSync(path.join(outDir, 'manifest.json'), JSON.stringify(results, null, 2), 'utf8');
  console.log(JSON.stringify({ count: results.length, outDir }, null, 2));
  await browser.close();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
