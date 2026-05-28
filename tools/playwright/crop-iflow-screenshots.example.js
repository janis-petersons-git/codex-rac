const fs = require('fs');
const path = require('path');
const { Jimp, intToRGBA } = require('jimp');

const root = 'C:\\Users\\janis.petersons\\Desktop\\RS';
const sourceDir = path.join(root, '_work', 'playwright_ci', 'artifacts', 'iflow_screenshots_canvaszoom');
const targetDir = path.join(root, '_work', 'playwright_ci', 'artifacts', 'iflow_screenshots_canvaszoom_cropped');
const sourceManifestPath = path.join(sourceDir, 'manifest.json');
const targetManifestPath = path.join(targetDir, 'manifest.json');

const PAD_LEFT = 60;
const PAD_OTHER = 26;
const SAMPLE_STEP = 2;

function isContentPixel({ r, g, b, a }) {
  if (a === 0) return false;
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  const deltaFromWhite = (255 - r) + (255 - g) + (255 - b);
  const saturation = max - min;
  return min < 235 || deltaFromWhite > 45 || (saturation > 12 && deltaFromWhite > 24);
}

function smoothCounts(counts, radius) {
  const result = new Array(counts.length).fill(0);
  for (let i = 0; i < counts.length; i += 1) {
    let sum = 0;
    for (let j = Math.max(0, i - radius); j <= Math.min(counts.length - 1, i + radius); j += 1) {
      sum += counts[j];
    }
    result[i] = sum;
  }
  return result;
}

function findRange(counts, minCount, minRunLength) {
  const smoothed = smoothCounts(counts, 2);
  const runs = [];
  let start = -1;
  for (let i = 0; i < smoothed.length; i += 1) {
    if (smoothed[i] >= minCount && start < 0) start = i;
    if ((smoothed[i] < minCount || i === smoothed.length - 1) && start >= 0) {
      const end = smoothed[i] >= minCount ? i : i - 1;
      if (end - start + 1 >= minRunLength) runs.push({ start, end });
      start = -1;
    }
  }
  if (!runs.length) return null;
  return {
    start: Math.min(...runs.map((run) => run.start)),
    end: Math.max(...runs.map((run) => run.end)),
  };
}

function cropAdjustments(title) {
  const adjustments = [];

  const add = (pattern, adjustment) => {
    if (pattern.test(title || '')) adjustments.push(adjustment);
  };

  add(/Route Idocs From S4HANA/i, { right: 160, forceRight: 1580 });
  add(/Replicate Material From S4HANA/i, { bottom: 45, forceBottom: 1448 });
  add(/Process Customized Material Pre Post Exits/i, { top: 34, right: 60, forceY: 205, leftTrim: 7 });
  add(/SalesKits_ManualTrigger/i, { top: 42, right: 70, forceY: 255 });
  add(/IF_S4_TO_Commerce_CommunicationPreferences/i, { topTrim: 4 });
  add(/Replicate B2B Customer/i, { leftTrim: 45, forceY: 260, rightLimit: 1535 });

  const queryBoxFix = { top: 42, right: 110, forceY: 255 };
  const queryBoxTopRightFix = { top: 42, right: 110, forceY: 255, forceRight: 1175 };
  add(/IF_Commerce_TO_S4_MaterialStock/i, queryBoxTopRightFix);
  add(/IF_Commerce_TO_S4_ListingsAndExclusions/i, { top: 42, forceY: 255 });
  add(/IF_Commerce_TO_S4_GetInventoryReport/i, { top: 42, forceY: 255 });
  add(/IF_Commerce_TO_S4_OrderSimulate/i, queryBoxFix);
  add(/IF_Commerce_TO_S4_ManageSalesOrders/i, queryBoxFix);
  add(/IF_Commerce_TO_S4_GetJobQuoteList/i, queryBoxTopRightFix);
  add(/IF_Commerce_TO_S4_GetJobQuoteDetails/i, { top: 42, right: 110, forceY: 180 });
  add(/IF_Commerce_TO_S4_GetInvoiceList/i, queryBoxFix);
  add(/IF_Commerce_TO_S4_GetInvoiceDetails/i, queryBoxFix);
  add(/IF_Commerce_TO_S4_GetInvoicePDF/i, queryBoxFix);

  return adjustments.reduce((merged, adjustment) => ({
    left: (merged.left || 0) + (adjustment.left || 0),
    top: (merged.top || 0) + (adjustment.top || 0),
    right: (merged.right || 0) + (adjustment.right || 0),
    bottom: (merged.bottom || 0) + (adjustment.bottom || 0),
    leftTrim: Math.max(merged.leftTrim || 0, adjustment.leftTrim || 0),
    topTrim: Math.max(merged.topTrim || 0, adjustment.topTrim || 0),
    forceY: adjustment.forceY ?? merged.forceY,
    forceRight: adjustment.forceRight ?? merged.forceRight,
    forceBottom: adjustment.forceBottom ?? merged.forceBottom,
    rightLimit: adjustment.rightLimit ?? merged.rightLimit,
  }), {});
}

async function cropImage(sourcePath, targetPath, title) {
  const image = await Jimp.read(sourcePath);
  const { width, height } = image.bitmap;
  const isHugeB2B = /Replicate B2B Customer/i.test(title || '');

  // The raw capture includes the SAP shell header and toolbar. Start analysis
  // below those UI elements, keep enough left margin for sender participants,
  // and stop before the canvas zoom controls on the far right.
  const analysis = {
    left: isHugeB2B ? 20 : Math.max(60, Math.round(width * 0.035)),
    top: isHugeB2B ? 95 : Math.max(190, Math.round(height * 0.16)),
    right: isHugeB2B ? width - 85 : Math.min(width - 270, Math.round(width * 0.88)),
    bottom: isHugeB2B ? height - 70 : height - 45,
  };

  const colCounts = new Array(analysis.right - analysis.left).fill(0);
  const rowCounts = new Array(analysis.bottom - analysis.top).fill(0);

  for (let y = analysis.top; y < analysis.bottom; y += SAMPLE_STEP) {
    for (let x = analysis.left; x < analysis.right; x += SAMPLE_STEP) {
      if (isContentPixel(intToRGBA(image.getPixelColor(x, y)))) {
        colCounts[x - analysis.left] += 1;
        rowCounts[y - analysis.top] += 1;
      }
    }
  }

  const xRange = findRange(colCounts, 3, 14);
  const yRange = findRange(rowCounts, 3, 4);
  if (!xRange || !yRange) {
    await image.write(targetPath);
    return { copied: true, originalWidth: width, originalHeight: height, croppedWidth: width, croppedHeight: height };
  }

  const adjustment = cropAdjustments(title);
  let x = Math.max(analysis.left, analysis.left + xRange.start - PAD_LEFT - (adjustment.left || 0));
  let y = Math.max(analysis.top, analysis.top + yRange.start - PAD_OTHER - (adjustment.top || 0));
  let right = Math.min(analysis.right, analysis.left + xRange.end + PAD_OTHER + (adjustment.right || 0));
  let bottom = Math.min(analysis.bottom, analysis.top + yRange.end + PAD_OTHER + (adjustment.bottom || 0));

  if (adjustment.leftTrim) {
    x = Math.min(right - 120, x + adjustment.leftTrim);
  }
  if (adjustment.topTrim) {
    y = Math.min(bottom - 120, y + adjustment.topTrim);
  }
  if (adjustment.forceY !== undefined) {
    y = Math.max(0, Math.min(bottom - 120, adjustment.forceY));
  }
  if (adjustment.forceRight !== undefined) {
    right = Math.min(width, Math.max(right, adjustment.forceRight));
  }
  if (adjustment.rightLimit !== undefined) {
    right = Math.max(x + 120, Math.min(right, adjustment.rightLimit));
  }
  if (adjustment.forceBottom !== undefined) {
    bottom = Math.min(height, Math.max(bottom, adjustment.forceBottom));
  }

  const cropped = image.clone().crop({ x, y, w: right - x, h: bottom - y });
  await cropped.write(targetPath);

  return {
    copied: false,
    originalWidth: width,
    originalHeight: height,
    croppedWidth: right - x,
    croppedHeight: bottom - y,
    x,
    y,
    right,
    bottom,
  };
}

async function main() {
  fs.mkdirSync(targetDir, { recursive: true });
  const manifest = JSON.parse(fs.readFileSync(sourceManifestPath, 'utf8'));
  const croppedManifest = [];
  const report = [];

  for (const entry of manifest) {
    const sourcePath = entry.screenshotPath;
    const targetPath = path.join(targetDir, path.basename(sourcePath));
    const crop = await cropImage(sourcePath, targetPath, entry.title);
    croppedManifest.push({
      ...entry,
      originalScreenshotPath: sourcePath,
      screenshotPath: targetPath,
      crop,
    });
    report.push({
      title: entry.title,
      file: path.basename(targetPath),
      ...crop,
    });
  }

  fs.writeFileSync(targetManifestPath, JSON.stringify(croppedManifest, null, 2), 'utf8');
  fs.writeFileSync(path.join(targetDir, 'crop_report.json'), JSON.stringify(report, null, 2), 'utf8');
  console.log(JSON.stringify({ count: report.length, targetDir }, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
