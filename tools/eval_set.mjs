// Accuracy on the Wikipedia evaluation set (tools/fetch_eval.py) and simulation of the
// personal memory: node eval_set.mjs
//
// Image embeddings are cached in tools/testimg/wiki/embeddings.json; delete it after changing
// the model. Non-food article pictures (portraits, maps, buildings) are filtered out first.
import fs from 'node:fs';
import path from 'node:path';
import {
  AutoProcessor, AutoTokenizer, CLIPTextModelWithProjection, CLIPVisionModelWithProjection, RawImage,
} from '@huggingface/transformers';
import { ROOT, MODEL_ID, readDishes } from './common.mjs';

const SCALE = 50; // DishCatalog._logitScale
const WIKI = path.join(ROOT, 'tools/testimg/wiki');
const CACHE = path.join(WIKI, 'embeddings.json');

const dishes = readDishes();
const byId = Object.fromEntries(dishes.map((d) => [d.id, d]));
const meta = JSON.parse(fs.readFileSync(path.join(ROOT, 'assets/dish_embeddings.json')));
const bin = fs.readFileSync(path.join(ROOT, 'assets/dish_embeddings.bin'));
const textEmb = new Float32Array(bin.buffer, bin.byteOffset, bin.length / 4);
const dim = meta.dim;
const dot = (a, ao, b, bo) => { let s = 0; for (let k = 0; k < dim; k++) s += a[ao + k] * b[bo + k]; return s; };

// --- image embeddings (cached) ---
let cache = fs.existsSync(CACHE) ? JSON.parse(fs.readFileSync(CACHE)) : {};
const files = fs.readdirSync(WIKI).filter((d) => byId[d]).flatMap((d) =>
  fs.readdirSync(path.join(WIKI, d)).filter((f) => f.endsWith('.jpg')).map((f) => `${d}/${f}`));
const missing = files.filter((f) => !cache[f]);
if (missing.length) {
  const processor = await AutoProcessor.from_pretrained(MODEL_ID);
  const model = await CLIPVisionModelWithProjection.from_pretrained(MODEL_ID, { dtype: 'fp16' });
  for (const [i, f] of missing.entries()) {
    try {
      const { image_embeds } = await model(await processor(await RawImage.read(path.join(WIKI, f))));
      cache[f] = Array.from(image_embeds.normalize().data, (x) => +x.toFixed(5));
    } catch (e) { cache[f] = null; }
    if (i % 50 === 49) { fs.writeFileSync(CACHE, JSON.stringify(cache)); process.stderr.write(`${i + 1}/${missing.length}\n`); }
  }
  fs.writeFileSync(CACHE, JSON.stringify(cache));
}

// --- food filter: keep photos that look like food rather than people, maps, buildings… ---
const tokenizer = await AutoTokenizer.from_pretrained(MODEL_ID);
const textModel = await CLIPTextModelWithProjection.from_pretrained(MODEL_ID, { dtype: 'fp32' });
const FOOD = ['a photo of food', 'a photo of a dish on a plate', 'a photo of a drink', 'a photo of fruit or vegetables'];
const OTHER = ['a portrait photo of a person', 'a map', 'a photo of a building', 'a painting', 'a page of text',
  'a landscape photo', 'a photo of an animal', 'a photo of a plant in a field', 'a photo of a market or a shop'];
const { text_embeds } = await textModel(tokenizer([...FOOD, ...OTHER], { padding: 'max_length', truncation: true }));
const filterEmb = text_embeds.normalize().data;
const isFood = (v) => {
  let best = -1, bestI = 0;
  for (let i = 0; i < FOOD.length + OTHER.length; i++) { const s = dot(v, 0, filterEmb, i * dim); if (s > best) { best = s; bestI = i; } }
  return bestI < FOOD.length;
};

const photos = files
  .filter((f) => cache[f] && isFood(cache[f]))
  .map((f) => ({ file: f, dish: f.split('/')[0], v: Float32Array.from(cache[f]) }));
const dropped = files.length - photos.length;

// --- zero-shot ---
function zeroShot(v) {
  const logits = meta.ids.map((_, i) => dot(v, 0, textEmb, i * dim) * SCALE);
  const max = Math.max(...logits);
  const exps = logits.map((l) => Math.exp(l - max));
  const sum = exps.reduce((a, b) => a + b, 0);
  return meta.ids.map((id, i) => ({ id, logit: logits[i], p: exps[i] / sum }));
}
const rank = (scores, id) => [...scores].sort((a, b) => b.logit - a.logit).findIndex((s) => s.id === id);

const acc = (ranks) => ({
  top1: (100 * ranks.filter((r) => r === 0).length / ranks.length).toFixed(1),
  top3: (100 * ranks.filter((r) => r < 3).length / ranks.length).toFixed(1),
  top5: (100 * ranks.filter((r) => r < 5).length / ranks.length).toFixed(1),
});
const zsRanks = photos.map((p) => rank(zeroShot(p.v), p.dish));
console.log(`photos: ${photos.length} food (${dropped} non-food dropped), dishes: ${new Set(photos.map((p) => p.dish)).size}`);
console.log('zero-shot:', acc(zsRanks));

// Confidence calibration: how often is the top-1 right when its probability is ≥ x?
for (const t of [0.2, 0.4, 0.6, 0.8]) {
  const sel = photos.map((p) => { const s = zeroShot(p.v).sort((a, b) => b.p - a.p)[0]; return { ok: s.id === p.dish, p: s.p }; })
    .filter((x) => x.p >= t);
  console.log(`  top-1 prob ≥ ${t}: ${sel.length} photos, ${(100 * sel.filter((x) => x.ok).length / Math.max(1, sel.length)).toFixed(0)}% correct`);
}

// --- personal memory simulation ---
// History: the first photo of every dish (as if the user had logged each dish once). Queries:
// the other photos. The memory adds a bonus to dishes whose past photos look similar.
const byDish = {};
for (const p of photos) (byDish[p.dish] ??= []).push(p);
const history = Object.values(byDish).map((ps) => ps[0]);
const queries = Object.values(byDish).flatMap((ps) => ps.slice(1));

// Image-image similarity: same dish vs different dish.
const same = [], diff = [];
for (const q of queries) for (const h of history) (h.dish === q.dish ? same : diff).push(dot(q.v, 0, h.v, 0));
const pct = (a, x) => { const s = [...a].sort((p, q) => p - q); return s[Math.floor(x * (s.length - 1))].toFixed(3); };
console.log(`image similarity same dish: median ${pct(same, 0.5)}, p10 ${pct(same, 0.1)}, p90 ${pct(same, 0.9)}`);
console.log(`image similarity diff dish: median ${pct(diff, 0.5)}, p99 ${pct(diff, 0.99)}, p99.9 ${pct(diff, 0.999)}`);

export function withMemory(v, hist, { floor, weight }) {
  const scores = zeroShot(v);
  const best = {};
  for (const h of hist) { const s = dot(v, 0, h.v, 0); if (s > (best[h.dish] ?? -1)) best[h.dish] = s; }
  for (const s of scores) s.logit += weight * Math.max(0, (best[s.id] ?? 0) - floor) * SCALE;
  return scores;
}
console.log(`memory queries: ${queries.length}; zero-shot on them:`, acc(queries.map((q) => rank(zeroShot(q.v), q.dish))));
let bestCfg = null;
for (const floor of [0.5, 0.6, 0.65, 0.7, 0.75])
  for (const weight of [1, 2, 4, 8]) {
    const a = acc(queries.map((q) => rank(withMemory(q.v, history, { floor, weight }), q.dish)));
    if (!bestCfg || +a.top1 > +bestCfg.a.top1) bestCfg = { floor, weight, a };
  }
console.log('memory, best of grid:', bestCfg);
