// On-device food recognition: MobileCLIP-S0 (vision encoder) via onnxruntime-web.
// Dart calls window.foodAI.analyze(bytes) for the whole photo (embedding + JPEG thumbnail), then
// window.foodAI.analyzeRegions(bytes) for parts of it (to find a side dish next to the main one);
// matching against catalog dishes happens in Dart.
(() => {
  const MODEL_URL = 'models/vision_model.onnx';
  const INPUT_SIZE = 256; // preprocessor_config.json: shortest_edge=256, center crop 256
  const THUMB_SIZE = 320;
  // Parts of the photo: windows of 60% × 60% at the corners and the center (origins as fractions).
  // Keep in sync with tools/eval_plate.mjs.
  const REGIONS = [[0, 0], [0.4, 0], [0, 0.4], [0.4, 0.4], [0.2, 0.2]];
  const REGION_SIZE = 0.6;

  let sessionPromise = null;

  function loadSession() {
    if (!sessionPromise) {
      // Absolute URL: a relative path in dynamic import() is treated as a bare module specifier.
      ort.env.wasm.wasmPaths = new URL('ort/', document.baseURI).href;
      // Multithreading requires cross-origin isolation.
      ort.env.wasm.numThreads = self.crossOriginIsolated
        ? Math.min(4, navigator.hardwareConcurrency || 1) : 1;
      sessionPromise = ort.InferenceSession
        .create(MODEL_URL, { executionProviders: ['wasm'], graphOptimizationLevel: 'all' })
        .catch((e) => { sessionPromise = null; throw e; });
    }
    return sessionPromise;
  }

  function canvas(w, h) {
    if (typeof OffscreenCanvas !== 'undefined') return new OffscreenCanvas(w, h);
    const c = document.createElement('canvas');
    c.width = w; c.height = h;
    return c;
  }

  // Pixels of the source rectangle (sx, sy, sw, sh): the shorter side resized to INPUT_SIZE,
  // center-cropped, written into `out` at `offset` as [0, 1] floats in CHW layout.
  function writePixels(bitmap, [sx, sy, sw, sh], out, offset) {
    const scale = INPUT_SIZE / Math.min(sw, sh);
    const w = sw * scale, h = sh * scale;
    const c = canvas(INPUT_SIZE, INPUT_SIZE);
    const ctx = c.getContext('2d', { willReadFrequently: true });
    ctx.imageSmoothingQuality = 'high';
    ctx.drawImage(bitmap, sx, sy, sw, sh, (INPUT_SIZE - w) / 2, (INPUT_SIZE - h) / 2, w, h);
    const { data } = ctx.getImageData(0, 0, INPUT_SIZE, INPUT_SIZE);
    const plane = INPUT_SIZE * INPUT_SIZE;
    for (let i = 0; i < plane; i++) {
      out[offset + i] = data[i * 4] / 255;
      out[offset + plane + i] = data[i * 4 + 1] / 255;
      out[offset + 2 * plane + i] = data[i * 4 + 2] / 255;
    }
  }

  // Runs the model on a batch of rectangles; returns L2-normalized embeddings, concatenated.
  async function embed(bitmap, rects) {
    const size = 3 * INPUT_SIZE * INPUT_SIZE;
    const pixels = new Float32Array(rects.length * size);
    rects.forEach((r, i) => writePixels(bitmap, r, pixels, i * size));
    const session = await loadSession();
    const input = new ort.Tensor('float32', pixels, [rects.length, 3, INPUT_SIZE, INPUT_SIZE]);
    const v = (await session.run({ pixel_values: input })).image_embeds.data;
    const dim = v.length / rects.length;
    const out = new Float32Array(v.length);
    for (let r = 0; r < rects.length; r++) {
      let norm = 0;
      for (let k = 0; k < dim; k++) norm += v[r * dim + k] ** 2;
      norm = Math.sqrt(norm);
      for (let k = 0; k < dim; k++) out[r * dim + k] = v[r * dim + k] / norm;
    }
    return out;
  }

  async function thumbnail(bitmap) {
    const scale = Math.min(1, THUMB_SIZE / Math.max(bitmap.width, bitmap.height));
    const w = Math.round(bitmap.width * scale), h = Math.round(bitmap.height * scale);
    const c = canvas(w, h);
    c.getContext('2d').drawImage(bitmap, 0, 0, w, h);
    const blob = c.convertToBlob
      ? await c.convertToBlob({ type: 'image/jpeg', quality: 0.75 })
      : await new Promise((r) => c.toBlob(r, 'image/jpeg', 0.75));
    return new Uint8Array(await blob.arrayBuffer());
  }

  async function withBitmap(bytes, fn) {
    const bitmap = await createImageBitmap(new Blob([bytes]), { imageOrientation: 'from-image' });
    try {
      return await fn(bitmap);
    } finally {
      bitmap.close();
    }
  }

  window.foodAI = {
    // Preload the model (first time: ~23 MB download, then from cache).
    async warmUp() { await loadSession(); },

    // Whole photo: embedding (512 floats) and a JPEG thumbnail.
    analyze(bytes) {
      return withBitmap(bytes, async (b) => ({
        embedding: await embed(b, [[0, 0, b.width, b.height]]),
        thumbnail: await thumbnail(b),
      }));
    },

    // Parts of the photo: REGIONS.length embeddings, concatenated.
    analyzeRegions(bytes) {
      return withBitmap(bytes, (b) => embed(b, REGIONS.map(([x, y]) => [
        x * b.width, y * b.height, REGION_SIZE * b.width, REGION_SIZE * b.height,
      ])));
    },
  };
})();
