// Multi-item plate detection check on tools/testimg/combo: node eval_plate.mjs
// Mirrors the app: the whole photo plus a 3 × 3 grid of half-size windows, combined the way
// DishCatalog.suggestPlate does (one dish per role, per-role thresholds, at most 5 items).
import fs from 'node:fs';
import path from 'node:path';
import { AutoProcessor, CLIPVisionModelWithProjection, RawImage } from '@huggingface/transformers';
import { ROOT, MODEL_ID, readDishes } from './common.mjs';

const SCALE = 50; // DishCatalog._logitScale
const dishes = readDishes();
const byId = Object.fromEntries(dishes.map((d) => [d.id, d]));
const meta = JSON.parse(fs.readFileSync(path.join(ROOT, 'assets/dish_embeddings.json')));
const bin = fs.readFileSync(path.join(ROOT, 'assets/dish_embeddings.bin'));
const emb = new Float32Array(bin.buffer, bin.byteOffset, bin.length / 4);

function classify(v) {
  const logits = meta.ids.map((_, i) => {
    let s = 0; for (let k = 0; k < meta.dim; k++) s += v[k] * emb[i * meta.dim + k];
    return s * SCALE;
  });
  const max = Math.max(...logits);
  const exps = logits.map((l) => Math.exp(l - max));
  const sum = exps.reduce((a, b) => a + b, 0);
  return meta.ids.map((id, i) => ({ id, p: exps[i] / sum })).sort((a, b) => b.p - a.p);
}

// Keep in sync with REGIONS in web/food_ai.js and DishCatalog.suggestPlate.
const WINDOWS = [0, 0.25, 0.5].flatMap((y) => [0, 0.25, 0.5].map((x) => [x, y]));
const SIZE = 0.5;
const MIN = { soup: 0.4, main: 0.3, side: 0.15, salad: 0.15, bread: 0.3, fruit: 0.3, drink: 0.4, dessert: 0.4 };
const role = (d) => d.id === 'french_fries' ? 'side' : ({ soup: 'soup', side: 'side', salad: 'salad', vegetable: 'salad',
  bread: 'bread', fruit: 'fruit', drink: 'drink', dessert: 'dessert' })[d.category] ?? 'main';

const processor = await AutoProcessor.from_pretrained(MODEL_ID);
const model = await CLIPVisionModelWithProjection.from_pretrained(MODEL_ID, { dtype: 'fp16' });
async function embed(image) {
  const { image_embeds } = await model(await processor(image));
  return image_embeds.normalize().data;
}

const dir = path.join(ROOT, 'tools/testimg/combo');
for (const f of fs.readdirSync(dir).filter((f) => f.endsWith('.jpg')).sort()) {
  const image = await RawImage.read(path.join(dir, f));
  const full = classify(await embed(image));
  const tops = [];
  for (const [x, y] of WINDOWS) {
    const x0 = Math.round(x * image.width), y0 = Math.round(y * image.height);
    const crop = await image.crop([x0, y0, x0 + Math.round(SIZE * image.width) - 1, y0 + Math.round(SIZE * image.height) - 1]);
    tops.push(classify(await embed(crop))[0]);
  }
  tops.sort((a, b) => b.p - a.p);
  const picked = [full[0]];
  const roles = new Set([role(byId[full[0].id])]);
  for (const m of tops) {
    const r = role(byId[m.id]);
    if (roles.has(r) || m.p < MIN[r]) continue;
    if (picked.length >= 5) break;
    picked.push(m); roles.add(r);
  }
  const name = (id) => byId[id].name_en;
  console.log(`\n${f}\n  plate:   ${picked.map((m) => `${name(m.id)} ${(m.p * 100).toFixed(0)}%`).join(' + ')}`);
  console.log(`  regions: ${tops.map((m) => `${name(m.id)} ${(m.p * 100).toFixed(0)}%`).join(' | ')}`);
}
