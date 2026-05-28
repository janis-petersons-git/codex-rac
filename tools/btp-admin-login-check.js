const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

function parseCredentialFile(filePath) {
  const raw = fs.readFileSync(filePath, 'utf8')
    .split(/\r?\n/)
    .map(line => line.trim())
    .filter(Boolean);

  if (raw.length < 2) {
    throw new Error('Credential file must contain username on line 1 and password on line 2.');
  }

  return { username: raw[0], password: raw[1] };
}

async function clickIfVisible(page, locators) {
  for (const locator of locators) {
    if (await locator.count().catch(() => 0)) {
      if (await locator.first().isVisible().catch(() => false)) {
        await locator.first().click({ timeout: 10000 }).catch(() => {});
        return true;
      }
    }
  }
  return false;
}

async function fillFirstVisible(page, selectors, value) {
  for (const selector of selectors) {
    const locator = page.locator(selector).first();
    if (await locator.count().catch(() => 0)) {
      if (await locator.isVisible().catch(() => false)) {
        await locator.fill(value);
        return true;
      }
    }
  }
  return false;
}

async function dismissCookies(page) {
  await clickIfVisible(page, [
    page.getByRole('button', { name: /Accept All/i }),
    page.getByRole('button', { name: /Allow All/i }),
    page.getByRole('button', { name: /Pienemt visus/i }),
  ]);
}

async function main() {
  const credentialPath = process.argv[2];
  if (!credentialPath) {
    throw new Error('Usage: node tools/btp-admin-login-check.js <credential-file>');
  }

  const { username, password } = parseCredentialFile(credentialPath);
  const outDir = path.resolve(process.cwd(), 'artifacts', 'btp-admin-check');
  fs.mkdirSync(outDir, { recursive: true });

  const browser = await chromium.launch({
    channel: 'msedge',
    headless: true,
  });

  const context = await browser.newContext({
    viewport: { width: 1440, height: 1200 },
  });

  const page = await context.newPage();
  const checkpoints = [];

  await page.goto('https://account.hanatrial.ondemand.com/trial/#/home/trial', {
    waitUntil: 'domcontentloaded',
    timeout: 120000,
  });
  checkpoints.push({ step: 'open-trial-home', url: page.url() });
  await page.waitForTimeout(3000);
  await dismissCookies(page);

  const openedTrial = await clickIfVisible(page, [
    page.getByRole('link', { name: /Go To Your Trial Account/i }),
    page.getByRole('button', { name: /Go To Your Trial Account/i }),
    page.getByRole('link', { name: /Go to your trial account/i }),
    page.getByRole('button', { name: /Go to your trial account/i }),
  ]);

  if (openedTrial) {
    await page.waitForLoadState('domcontentloaded', { timeout: 120000 }).catch(() => {});
    await page.waitForTimeout(2000);
    checkpoints.push({ step: 'open-trial-account', url: page.url() });
  }

  if (/accounts\.sap\.com|account\.sap\.com|hanatrial\.ondemand\.com/i.test(page.url())) {
    await fillFirstVisible(page, [
      'input[type="email"]',
      'input[autocomplete="username"]',
      'input[name="username"]',
      'input[name="j_username"]',
      'input[type="text"]',
    ], username);

    await clickIfVisible(page, [
      page.getByRole('button', { name: /Continue/i }),
      page.getByRole('button', { name: /Next/i }),
      page.getByRole('button', { name: /Sign In/i }),
      page.getByRole('button', { name: /Log On/i }),
      page.locator('button[type="submit"]'),
      page.locator('input[type="submit"]'),
    ]);

    await page.waitForTimeout(2000);

    const passwordFilled = await fillFirstVisible(page, [
      'input[type="password"]',
      'input[autocomplete="current-password"]',
      'input[name="password"]',
      'input[name="j_password"]',
    ], password);

    if (!passwordFilled) {
      throw new Error(`Password field was not found after username submission. Current URL: ${page.url()}`);
    }

    await clickIfVisible(page, [
      page.getByRole('button', { name: /Continue/i }),
      page.getByRole('button', { name: /Sign In/i }),
      page.getByRole('button', { name: /Log On/i }),
      page.locator('button[type="submit"]'),
      page.locator('input[type="submit"]'),
    ]);
  }

  await page.waitForLoadState('networkidle', { timeout: 120000 }).catch(() => {});
  await page.waitForTimeout(5000);

  const finalUrl = page.url();
  const title = await page.title();
  const body = await page.locator('body').innerText().catch(() => '');
  const success =
    /cockpit|trial|subaccount|global account|integration suite/i.test(`${title}\n${body}`) &&
    !/invalid|error|wrong password|unsuccessful/i.test(body);

  const screenshotPath = path.join(outDir, 'btp-login-check.png');
  await page.screenshot({ path: screenshotPath, fullPage: true }).catch(() => {});

  const result = {
    success,
    finalUrl,
    title,
    checkpoints,
    observed_markers: body.split(/\r?\n/).map(v => v.trim()).filter(Boolean).slice(0, 40),
    screenshotPath,
    ranAt: new Date().toISOString(),
  };

  fs.writeFileSync(
    path.join(outDir, 'btp-login-check.json'),
    JSON.stringify(result, null, 2),
    'utf8'
  );

  await browser.close();

  if (!success) {
    throw new Error(`Login/access check did not reach an expected BTP page. Final URL: ${finalUrl}`);
  }

  console.log(JSON.stringify(result, null, 2));
}

main().catch(error => {
  console.error(error.stack || String(error));
  process.exit(1);
});
