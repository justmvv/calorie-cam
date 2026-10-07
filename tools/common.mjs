import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
// Override for experiments: MODEL=Xenova/mobileclip_s2 node …
export const MODEL_ID = process.env.MODEL ?? 'Xenova/mobileclip_s2';

// Vision model precision: fp16 (default; int8/q8 broke MobileCLIP-S0 completely).
export const VISION_DTYPE = process.env.DTYPE ?? 'fp16';

// Several phrasings per dish; their embeddings are averaged (prompt ensembling).
export const TEMPLATES = [
  'a photo of {}, a type of food.',
  'a photo of a plate of {}.',
  'a close-up photo of {}.',
];

export function readDishes() {
  const lines = fs.readFileSync(path.join(ROOT, 'assets/dishes.tsv'), 'utf8')
    .split('\n').filter((l) => l.trim() && !l.startsWith('#'));
  const header = lines.shift().split('\t');
  return lines.map((l) => Object.fromEntries(l.split('\t').map((v, i) => [header[i], v])));
}
