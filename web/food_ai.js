// On-device food recognition: MobileCLIP-S0 (vision encoder) via onnxruntime-web.
// Dart calls window.foodAI.analyze(bytes) and gets the photo embedding plus a JPEG thumbnail;
// matching against catalog dishes happens in Dart.
(() => {
  const MODEL_URL = 'models/vision_model.onnx';
  const INPUT_SIZE = 256; // preprocessor_config.json: shortest_edge=256, center crop 256
  const THUMB_SIZE = 320;

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

  // Resize the shorter side, center-crop, pixels in [0, 1], NCHW layout.
  function toTensor(bitmap) {
    const scale = INPUT_SIZE / Math.min(bitmap.width, bitmap.height);
    const w = bitmap.width * scale, h = bitmap.height * scale;
    const c = canvas(INPUT_SIZE, INPUT_SIZE);
    const ctx = c.getContext('2d', { willReadFrequently: true });
    ctx.imageSmoothingQuality = 'high';
    ctx.drawImage(bitmap, (INPUT_SIZE - w) / 2, (INPUT_SIZE - h) / 2, w, h);
    const { data } = ctx.getImageData(0, 0, INPUT_SIZE, INPUT_SIZE);
    const plane = INPUT_SIZE * INPUT_SIZE;
    const out = new Float32Array(3 * plane);
    for (let i = 0; i < plane; i++) {
      out[i] = data[i * 4] / 255;
      out[plane + i] = data[i * 4 + 1] / 255;
      out[2 * plane + i] = data[i * 4 + 2] / 255;
    }
    return new ort.Tensor('float32', out, [1, 3, INPUT_SIZE, INPUT_SIZE]);
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

  window.foodAI = {
    // Preload the model (first time: ~23 MB download, then from cache).
    async warmUp() { await loadSession(); },

    async analyze(bytes) {
      const bitmap = await createImageBitmap(new Blob([bytes]), { imageOrientation: 'from-image' });
      try {
        const session = await loadSession();
        const result = await session.run({ pixel_values: toTensor(bitmap) });
        const v = result.image_embeds.data;
        let norm = 0;
        for (let i = 0; i < v.length; i++) norm += v[i] * v[i];
        norm = Math.sqrt(norm);
        const embedding = Float32Array.from(v, (x) => x / norm);
        return { embedding, thumbnail: await thumbnail(bitmap) };
      } finally {
        bitmap.close();
      }
    },
  };
})();
