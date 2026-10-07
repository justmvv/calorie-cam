// Multi-item plate detection check on tools/testimg/combo: node eval_plate.mjs
// Mirrors the app: the whole photo plus 5 overlapping windows (corners and center, 60% of each
// side); see web/food_ai.js (regions) and DishCatalog.suggestPlate.
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

export const WINDOWS = [[0, 0], [0.4, 0], [0, 0.4], [0.4, 0.4], [0.2, 0.2]]; // origins; size 0.6 × 0.6

const processor = await AutoProcessor.from_pretrained(MODEL_ID);
const model = await CLIPVisionModelWithProjection.from_pretrained(MODEL_ID, { dtype: 'fp16' });
async function embed(image) {
  const { image_embeds } = await model(await processor(image));
  return image_embeds.normalize().data;
}

const dir = path.join(ROOT, 'tools/testimg/combo');
for (const f of fs.readdirSync(dir).sort()) {
  const image = await RawImage.read(path.join(dir, f));
  const full = classify(await embed(image));
  const regions = [];
  for (const [x, y] of WINDOWS) {
    const x0 = Math.round(x * image.width), y0 = Math.round(y * image.height);
    const crop = await image.crop([x0, y0, x0 + Math.round(0.6 * image.width) - 1, y0 + Math.round(0.6 * image.height) - 1]);
    regions.push(classify(await embed(crop))[0]);
  }
  const name = (id) => byId[id].name_en;
  console.log(`\n${f}\n  full:    ${full.slice(0, 4).map((m) => `${name(m.id)} ${(m.p * 100).toFixed(0)}%`).join(' | ')}`);
  console.log(`  regions: ${regions.map((m) => `${name(m.id)} ${(m.p * 100).toFixed(0)}% [${byId[m.id].category}]`).join(' | ')}`);
}
