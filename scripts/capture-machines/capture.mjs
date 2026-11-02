// Renders each machine figure page and writes a shadowless, trimmed,
// transparent PNG to priv/static/images/machines/<slug>.png.
import { chromium } from 'playwright';
import { writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';

const base = process.argv[2] ?? 'http://localhost:4000';
const outDir = fileURLToPath(new URL('../../priv/static/images/machines/', import.meta.url));
const HEIGHT = 520;

const MACHINES = [
  { slug: 'xin-xam', path: '/xin-xam' },
  { slug: 'giai-nghiep', path: '/giai-nghiep' },
];

const SHADOW_DECL = 'const castShadow = (pts3, z0=0, clip=null) => {';
const NO_SHADOW = "const castShadow = () => ''; const __castShadow = (pts3, z0=0, clip=null) => {";

const HIDE_ALL_BUT_FIGURE = `
  html, body, #fig { background: transparent !important; }
  body * { visibility: hidden !important; }
  #fig, #fig * { visibility: visible !important; }
  #gnglow { display: none !important; } /* giải nghiệp's "touch here" hint ring */
`;

async function trimAndScale(page, png, height) {
  return page.evaluate(async ({ src, height }) => {
    const img = new Image();
    img.src = src;
    await img.decode();
    const c = document.createElement('canvas');
    c.width = img.width;
    c.height = img.height;
    const ctx = c.getContext('2d');
    ctx.drawImage(img, 0, 0);
    const { data } = ctx.getImageData(0, 0, c.width, c.height);
    let x0 = c.width, y0 = c.height, x1 = -1, y1 = -1;
    for (let y = 0; y < c.height; y++) {
      for (let x = 0; x < c.width; x++) {
        if (data[(y * c.width + x) * 4 + 3] > 8) {
          if (x < x0) x0 = x;
          if (x > x1) x1 = x;
          if (y < y0) y0 = y;
          if (y > y1) y1 = y;
        }
      }
    }
    if (x1 < 0) throw new Error('figure rendered nothing');
    const w = x1 - x0 + 1, h = y1 - y0 + 1;
    const out = document.createElement('canvas');
    out.height = height;
    out.width = Math.round((w * height) / h);
    const o = out.getContext('2d');
    o.imageSmoothingQuality = 'high';
    o.drawImage(c, x0, y0, w, h, 0, 0, out.width, out.height);
    return { url: out.toDataURL('image/png'), width: out.width, height: out.height };
  }, { src: 'data:image/png;base64,' + png.toString('base64'), height });
}

const browser = await chromium.launch();
try {
  const page = await browser.newPage({ viewport: { width: 1400, height: 1400 }, deviceScaleFactor: 2 });
  const figurePaths = new Set(MACHINES.map((m) => m.path));
  await page.route((url) => figurePaths.has(url.pathname), async (route) => {
    const res = await route.fetch();
    const html = await res.text();
    if (!html.includes(SHADOW_DECL)) throw new Error(`castShadow not found in ${route.request().url()}; the figure build changed`);
    await route.fulfill({ response: res, body: html.replace(SHADOW_DECL, NO_SHADOW) });
  });

  for (const { slug, path } of MACHINES) {
    await page.goto(base + path + '?welcome=0', { waitUntil: 'networkidle' });
    await page.addStyleTag({ content: HIDE_ALL_BUT_FIGURE });
    await page.evaluate(() => document.fonts.ready);
    await page.evaluate(() => new Promise((r) => requestAnimationFrame(() => requestAnimationFrame(r))));
    const shot = await page.locator('#fig').screenshot({ omitBackground: true });
    const { url, width, height } = await trimAndScale(page, shot, HEIGHT);
    await writeFile(outDir + slug + '.png', Buffer.from(url.split(',')[1], 'base64'));
    console.log(`${slug} ${width}×${height}`);
  }
} finally {
  await browser.close();
}
