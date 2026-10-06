// Generates the app icon — a faceted heart made of two halves (lighter herb green and darker
// saturated blue) — as tools/icon.svg and renders the PNGs the PWA needs via headless Chrome.
//   node make_icons.mjs            (CHROME_PATH overrides the Chrome location)
import fs from 'node:fs';
import path from 'node:path';
import puppeteer from 'puppeteer-core';
import { ROOT } from './common.mjs';

// Left half of the heart in a 512×512 box; the right half is its mirror image.
// C is the top notch, B the bottom tip; M1, M2 lie on the center seam.
const P = {
  C: [256, 148], B: [256, 452], M1: [256, 240], M2: [256, 360],
  P1: [214, 98], P2: [160, 78], P3: [104, 90], P4: [62, 132], P5: [48, 192],
  P6: [62, 256], P7: [104, 320], P8: [176, 392],
  I1: [150, 170], I2: [120, 250], I3: [196, 300],
};
const FACETS = [
  ['C', 'P1', 'I1'], ['P1', 'P2', 'I1'], ['P2', 'P3', 'I1'], ['P3', 'P4', 'I1'], ['P4', 'P5', 'I1'],
  ['P5', 'I2', 'I1'], ['P5', 'P6', 'I2'], ['P6', 'P7', 'I2'], ['P7', 'I3', 'I2'], ['P7', 'P8', 'I3'],
  ['P8', 'M2', 'I3'], ['P8', 'B', 'M2'], ['I1', 'I2', 'I3'], ['I1', 'I3', 'M1'], ['I1', 'M1', 'C'],
  ['I3', 'M2', 'M1'],
];
const OUTLINE = ['C', 'P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7', 'P8', 'B'];

// Each half shades between a dark and a light tone; light comes from the top left.
const HALVES = [
  { mirror: false, dark: [62, 127, 44], light: [178, 222, 132] }, // herb green, lighter half
  { mirror: true, dark: [9, 34, 120], light: [47, 107, 234] }, // saturated blue, darker half
];
const JITTER = [0.08, -0.06, 0.1, -0.04, 0.05, -0.08, 0.06, -0.05, 0.09, -0.07, 0.04, -0.09, 0.07, -0.03, 0.02, -0.06];

const mix = (a, b, t) => a.map((v, i) => Math.round(v + (b[i] - v) * t));
const rgb = (c) => `rgb(${c.join(',')})`;

function heart() {
  const parts = [];
  for (const half of HALVES) {
    const pt = (k) => (half.mirror ? [512 - P[k][0], P[k][1]] : P[k]);
    FACETS.forEach((f, i) => {
      const pts = f.map(pt);
      const cx = pts.reduce((s, p) => s + p[0], 0) / 3;
      const cy = pts.reduce((s, p) => s + p[1], 0) / 3;
      const t = Math.min(1, Math.max(0, 1.25 - (cx + cy) / 620 + JITTER[i] * 1.6));
      parts.push(`<polygon points="${pts.map((p) => p.join(',')).join(' ')}" fill="${rgb(mix(half.dark, half.light, t))}"/>`);
    });
  }
  const left = OUTLINE.map((k) => P[k]);
  const outline = [...left, ...left.slice(0, -1).reverse().map(([x, y]) => [512 - x, y])];
  const seam = ['C', 'M1', 'M2', 'B'].map((k) => P[k].join(',')).join(' ');
  return `
    <g stroke="rgba(255,255,255,0.55)" stroke-width="3" stroke-linejoin="round">${parts.join('')}</g>
    <polyline points="${seam}" fill="none" stroke="rgba(255,255,255,0.9)" stroke-width="6" stroke-linejoin="round"/>
    <polygon points="${outline.map((p) => p.join(',')).join(' ')}" fill="none" stroke="rgba(10,40,45,0.7)" stroke-width="7" stroke-linejoin="round"/>`;
}

// scale — share of the canvas the heart occupies; background — false for a transparent icon.
function svg({ scale, background }) {
  const s = scale, off = (512 - 512 * s) / 2;
  const bg = background
    ? `<defs><linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
         <stop offset="0" stop-color="#F1F8E9"/><stop offset="1" stop-color="#E3ECFF"/></linearGradient></defs>
       <rect width="512" height="512" fill="url(#bg)"/>`
    : '';
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">${bg}
    <g transform="translate(${off} ${off + 512 * s * 0.02}) scale(${s})">${heart()}</g></svg>`;
}

const OUTPUTS = [
  { file: 'web/icons/Icon-192.png', size: 192, scale: 0.86, background: true },
  { file: 'web/icons/Icon-512.png', size: 512, scale: 0.86, background: true },
  // Maskable icons are cropped by the OS: keep the heart inside the central safe zone.
  { file: 'web/icons/Icon-maskable-192.png', size: 192, scale: 0.66, background: true },
  { file: 'web/icons/Icon-maskable-512.png', size: 512, scale: 0.66, background: true },
  { file: 'web/icons/apple-touch-icon.png', size: 180, scale: 0.8, background: true },
  { file: 'web/favicon.png', size: 64, scale: 1, background: false },
  { file: 'assets/logo.png', size: 256, scale: 1, background: false },
];

fs.writeFileSync(path.join(ROOT, 'tools/icon.svg'), svg({ scale: 1, background: false }));

const browser = await puppeteer.launch({
  executablePath: process.env.CHROME_PATH ?? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  headless: 'new',
});
const page = await browser.newPage();
for (const o of OUTPUTS) {
  await page.setViewport({ width: o.size, height: o.size });
  await page.setContent(`<html><body style="margin:0;background:transparent">
    <div style="width:${o.size}px;height:${o.size}px">${svg(o).replace('<svg ', `<svg width="${o.size}" height="${o.size}" `)}</div>
    </body></html>`);
  await page.screenshot({ path: path.join(ROOT, o.file), omitBackground: true, clip: { x: 0, y: 0, width: o.size, height: o.size } });
  console.log(`${o.file} ${o.size}px`);
}
await browser.close();
