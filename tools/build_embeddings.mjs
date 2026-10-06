// Computes MobileCLIP text embeddings for every dish in the catalog.
// Output: assets/dish_embeddings.bin  (float32 LE, N×dim, same order as ids)
//         assets/dish_embeddings.json ({model, dim, ids})
import fs from 'node:fs';
import path from 'node:path';
import { AutoTokenizer, CLIPTextModelWithProjection } from '@huggingface/transformers';
import { ROOT, MODEL_ID, TEMPLATES, readDishes } from './common.mjs';

const dishes = readDishes();
const tokenizer = await AutoTokenizer.from_pretrained(MODEL_ID);
const textModel = await CLIPTextModelWithProjection.from_pretrained(MODEL_ID, { dtype: 'fp32' });

const vectors = [];
for (const d of dishes) {
  // A prompt may list several descriptions separated by " | " (e.g. a food that looks different
  // wrapped and unwrapped); every description × template is embedded and averaged.
  const texts = d.prompt.split('|').flatMap((p) => TEMPLATES.map((t) => t.replace('{}', p.trim())));
  const inputs = tokenizer(texts, { padding: 'max_length', truncation: true });
  const { text_embeds } = await textModel(inputs);
  const rows = text_embeds.normalize().tolist();
  const mean = rows[0].map((_, i) => rows.reduce((s, r) => s + r[i], 0) / rows.length);
  const norm = Math.hypot(...mean);
  vectors.push(mean.map((v) => v / norm));
}

const dim = vectors[0].length;
const buf = Buffer.alloc(vectors.length * dim * 4);
vectors.flat().forEach((v, i) => buf.writeFloatLE(v, i * 4));
fs.writeFileSync(path.join(ROOT, 'assets/dish_embeddings.bin'), buf);
fs.writeFileSync(path.join(ROOT, 'assets/dish_embeddings.json'),
  JSON.stringify({ model: MODEL_ID, dim, ids: dishes.map((d) => d.id) }));
console.log(`${dishes.length} dishes, dim=${dim}, ${buf.length} bytes`);
