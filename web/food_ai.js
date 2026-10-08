// On-device food recognition: MobileCLIP-S2 (vision encoder) via onnxruntime-web.
// Dart calls window.foodAI.analyze(bytes) for the whole photo (embedding + JPEG thumbnail), then
// window.foodAI.analyzeRegions(bytes) for parts of it (to find a side dish next to the main one);
// matching against catalog dishes happens in Dart.
(() => {
  const MODEL_URL = 'models/vision_model.onnx';
  const INPUT_SIZE = 256; // preprocessor_config.json: shortest_edge=256, center crop 256
  const THUMB_SIZE = 320;
  // Parts of the photo: a 3 × 3 grid of overlapping half-size windows (origins as fractions), so
  // each dish of a set lunch tray gets a window of its own. Keep in sync with tools/eval_plate.mjs.
  const REGIONS = [0, 0.25, 0.5].flatMap((y) => [0, 0.25, 0.5].map((x) => [x, y]));
  const REGION_SIZE = 0.5;

  let sessionPromise = null;
  let backend = null; // 'webgpu' or 'wasm', for diagnostics

  function loadScript(src) {
    return new Promise((resolve, reject) => {
      const s = document.createElement('script');
      s.src = src;
      s.onload = resolve;
      s.onerror = () => reject(new Error(`failed to load ${src}`));
      document.head.append(s);
    });
  }

  // Whether WebGPU gave the same result as the CPU on this device ('ok' / 'bad'), per model.
  const GPU_CHECK_KEY = `calorie_cam.gpu_check:${MODEL_URL}:v1`;
  const storage = {
    get: (k) => { try { return localStorage.getItem(k); } catch (_) { return null; } },
    set: (k, v) => { try { localStorage.setItem(k, v); } catch (_) {} },
  };
  const OPTIONS = { graphOptimizationLevel: 'all' };

  // The GPU is ~10× faster than the CPU for this model: use WebGPU where the browser offers an
  // adapter (most current Android phones in Chrome), otherwise the lighter CPU-only runtime.
  // Mobile GPUs can compute this fp16 model wrongly (overflow → NaN or garbage), so on first use
  // the GPU result for a test image is compared with the CPU's; the GPU is used only if they agree.
  async function createSession() {
    let gpu = navigator.gpu ? await navigator.gpu.requestAdapter().catch(() => null) : null;
    if (storage.get(GPU_CHECK_KEY) === 'bad') gpu = null;
    await loadScript(gpu ? 'ort/ort.webgpu.min.js' : 'ort/ort.wasm.min.js');
    // Absolute URL: a relative path in dynamic import() is treated as a bare module specifier.
    ort.env.wasm.wasmPaths = new URL('ort/', document.baseURI).href;
    // Multithreading requires cross-origin isolation.
    ort.env.wasm.numThreads = self.crossOriginIsolated ? Math.min(4, navigator.hardwareConcurrency || 1) : 1;
    if (gpu) {
      try {
        const session = await ort.InferenceSession.create(MODEL_URL, { ...OPTIONS, executionProviders: ['webgpu'] });
        if (storage.get(GPU_CHECK_KEY) !== 'ok') {
          const cpu = await cpuSession();
          const agree = await sameResult(session, cpu);
          storage.set(GPU_CHECK_KEY, agree ? 'ok' : 'bad');
          if (!agree) {
            console.warn('WebGPU result differs from the CPU on this device; using the CPU');
            backend = 'wasm';
            return cpu;
          }
        }
        backend = 'webgpu';
        return session;
      } catch (e) {
        console.warn('WebGPU unavailable, using the CPU:', e);
      }
    }
    return cpuSession();
  }

  function cpuSession() {
    backend = 'wasm';
    return ort.InferenceSession.create(MODEL_URL, { ...OPTIONS, executionProviders: ['wasm'] });
  }

  // A smooth synthetic test picture (gradients and stripes), the same on every device.
  function testInput() {
    const plane = INPUT_SIZE * INPUT_SIZE;
    const px = new Float32Array(3 * plane);
    for (let y = 0; y < INPUT_SIZE; y++) {
      for (let x = 0; x < INPUT_SIZE; x++) {
        const i = y * INPUT_SIZE + x;
        px[i] = x / INPUT_SIZE;
        px[plane + i] = y / INPUT_SIZE;
        px[2 * plane + i] = 0.5 + 0.5 * Math.sin((x + y) / 9);
      }
    }
    return new ort.Tensor('float32', px, [1, 3, INPUT_SIZE, INPUT_SIZE]);
  }

  async function sameResult(a, b) {
    const input = testInput();
    const va = normalized((await a.run({ pixel_values: input })).image_embeds.data, 1);
    const vb = normalized((await b.run({ pixel_values: input })).image_embeds.data, 1);
    if (!va || !vb) return false;
    let cos = 0;
    for (let k = 0; k < va.length; k++) cos += va[k] * vb[k];
    return cos >= 0.98;
  }

  // L2-normalizes each of `count` vectors; null if any value is NaN/infinite or a vector is zero.
  function normalized(v, count) {
    const dim = v.length / count;
    const out = new Float32Array(v.length);
    for (let r = 0; r < count; r++) {
      let norm = 0;
      for (let k = 0; k < dim; k++) norm += v[r * dim + k] ** 2;
      norm = Math.sqrt(norm);
      if (!Number.isFinite(norm) || norm < 1e-6) return null;
      for (let k = 0; k < dim; k++) out[r * dim + k] = v[r * dim + k] / norm;
    }
    return out;
  }

  function loadSession() {
    sessionPromise ??= createSession().catch((e) => { sessionPromise = null; throw e; });
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
    const input = new ort.Tensor('float32', pixels, [rects.length, 3, INPUT_SIZE, INPUT_SIZE]);
    const run = async () => normalized((await (await loadSession()).run({ pixel_values: input })).image_embeds.data, rects.length);
    let out = await run();
    if (!out && backend === 'webgpu') {
      // The GPU passed the check but failed on this photo: switch to the CPU for good.
      console.warn('Invalid WebGPU output; switching to the CPU');
      storage.set(GPU_CHECK_KEY, 'bad');
      sessionPromise = cpuSession();
      out = await run();
    }
    if (!out) throw new Error('the recognition model returned invalid numbers');
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
    // Preload the model (first time: ~72 MB download, then from cache).
    async warmUp() { await loadSession(); },

    // 'webgpu' or 'wasm' once the model is loaded.
    get backend() { return backend; },

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
