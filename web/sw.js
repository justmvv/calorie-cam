// PWA offline cache. Principle: the app never gets stuck on an old version.
//
// - The model and onnxruntime (models/, ort/) are cache-first: ~35 MB that only change
//   together with tools/fetch_assets.sh. Bump ASSETS_CACHE when ORT_VERSION or the model changes.
// - Everything else is network-first and bypasses the browser HTTP cache (cache: 'no-cache'):
//   GitHub Pages sends max-age=600, so without this a release could serve a new index.html
//   with an old main.dart.js for 10 minutes. ETag revalidation is cheap (304).
//   The cache is used only when there is no network.
// - Requests with cache: 'no-store' (the version check) are left alone.
// CacheStorage is shared by every app on the origin (all *.github.io/<repo>/ projects of a user),
// so this worker only ever touches caches with its own prefix.
const PREFIX = 'calorie-cam-';
const APP_CACHE = `${PREFIX}app`;
const ASSETS_CACHE = `${PREFIX}assets-v1`;
const IMMUTABLE = [/\/models\//, /\/ort\//];

self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (e) => e.waitUntil(
  caches.keys()
    .then((keys) => Promise.all(keys
      .filter((k) => k.startsWith(PREFIX) && k !== APP_CACHE && k !== ASSETS_CACHE)
      .map((k) => caches.delete(k))))
    .then(() => self.clients.claim()),
));

self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET' || req.cache === 'no-store' || new URL(req.url).origin !== location.origin) return;
  e.respondWith(IMMUTABLE.some((r) => r.test(req.url)) ? cacheFirst(req) : networkFirst(req));
});

async function cacheFirst(req) {
  const cache = await caches.open(ASSETS_CACHE);
  const hit = await cache.match(req);
  if (hit) return hit;
  const res = await fetch(req);
  if (res.ok) cache.put(req, res.clone());
  return res;
}

async function networkFirst(req) {
  const cache = await caches.open(APP_CACHE);
  try {
    // Build a new request from the URL: a navigate-mode Request can't be cloned with a RequestInit.
    const res = await fetch(req.url, { cache: 'no-cache', credentials: 'same-origin' });
    if (res.ok) {
      await dropOldVersions(cache, req.url);
      cache.put(req, res.clone());
    }
    return res;
  } catch (err) {
    const hit = await cache.match(req, { ignoreSearch: true });
    if (hit) return hit;
    throw err;
  }
}

// Versioned files (main.dart.js?v=…, b-<build>/assets/…, canvaskit-<rev>/…) get a new URL with
// every release; drop the old copies so the cache doesn't grow.
const versionless = (url) => {
  const u = new URL(url);
  return u.pathname.replace(/\/canvaskit-[0-9a-f]+\//, '/canvaskit/').replace(/\/b-[0-9a-f]+\//, '/b/');
};

async function dropOldVersions(cache, url) {
  const key = versionless(url);
  for (const old of await cache.keys()) {
    if (old.url !== url && versionless(old.url) === key) await cache.delete(old);
  }
}
