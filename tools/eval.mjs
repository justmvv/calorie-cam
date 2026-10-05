// Recognition check on the photos in tools/testimg: node eval.mjs [fp32|q8|fp16]
import fs from 'node:fs';
import path from 'node:path';
import { AutoProcessor, CLIPVisionModelWithProjection, RawImage } from '@huggingface/transformers';
import { ROOT, MODEL_ID, readDishes } from './common.mjs';

const dtype = process.argv[2] ?? 'fp32';
const dishes = readDishes();
const meta = JSON.parse(fs.readFileSync(path.join(ROOT, 'assets/dish_embeddings.json')));
const bin = fs.readFileSync(path.join(ROOT, 'assets/dish_embeddings.bin'));
const emb = new Float32Array(bin.buffer, bin.byteOffset, bin.length / 4);
const name = Object.fromEntries(dishes.map((d) => [d.id, d.name_en]));

const processor = await AutoProcessor.from_pretrained(MODEL_ID);
const model = await CLIPVisionModelWithProjection.from_pretrained(MODEL_ID, { dtype });
const dir = path.join(ROOT, 'tools/testimg');
for (const f of fs.readdirSync(dir).sort()) {
  const image = await RawImage.read(path.join(dir, f));
  const { image_embeds } = await model(await processor(image));
  const v = image_embeds.normalize().data;
  const scores = meta.ids.map((id, i) => {
    let s = 0; for (let k = 0; k < meta.dim; k++) s += v[k] * emb[i * meta.dim + k];
    return [id, s];
  }).sort((a, b) => b[1] - a[1]).slice(0, 5);
  console.log(f.padEnd(18), scores.map(([id, s]) => `${name[id]} ${s.toFixed(3)}`).join(' | '));
}
