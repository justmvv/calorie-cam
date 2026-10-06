# Calorie Cam

A Flutter PWA food diary: take a photo of a dish, the app suggests what it is and how many calories it has, and after you confirm, the entry goes into your diary. There is a monthly heatmap and a breakdown for every day.

Everything runs **locally in the browser**: recognition is done by an on-device model, and the diary is stored in SQLite (WASM) in browser storage. After the first load no network is needed.

The UI is available in **English and Russian**. By default it follows the system language (anything other than Russian falls back to English); it can be switched in Settings.

## How it works

```
photo ──► web/food_ai.js ─────────────────► embedding (512) ──► DishCatalog.classify ──► top 5 dishes
          (onnxruntime-web + MobileCLIP-S0)                      (cosine similarity with
                                                                  dish text embeddings)
user picks the dish and portion ──► kcal = kcal/100 g × grams ──► Drift (SQLite WASM)
```

- **Recognition:** zero-shot [MobileCLIP-S0](https://github.com/apple/ml-mobileclip) (fp16 vision encoder, ~23 MB). A dish is recognized if it's in the catalog; no model retraining is needed.
- **Catalog:** [`assets/dishes.tsv`](assets/dishes.tsv), ~200 Russian and international dishes with names in both languages, calories/protein/fat/carbs per 100 g and a typical portion. Text embeddings are precomputed in `assets/dish_embeddings.*`.
- **Database:** [`lib/data/db.dart`](lib/data/db.dart), two tables: `meals` (what, how much, when; nutrition already scaled to the portion) and `photos` (~15 KB JPEG thumbnails).
- **Localization:** ARB files in [`lib/l10n/`](lib/l10n/) (`flutter gen-l10n`). Logged entries are shown with the catalog name in the current language.
- **Offline and updates:** see the section below.

Portion weight is not estimated from the photo — that isn't reliable. The user sets the portion; the ½/×1/×1.5/×2 presets are relative to the dish's typical portion.

## Running

```bash
tools/fetch_assets.sh          # once: model and onnxruntime-web into web/ (not stored in git)
flutter pub get
dart run build_runner build    # Drift code
flutter run -d chrome          # development
tools/build_web.sh             # release PWA in build/web (versioned URLs)
```

On a phone you need **HTTPS**, otherwise the browser won't allow the camera or the service worker. Then choose "Add to Home Screen" in Safari or Chrome.

## Publishing (GitHub Pages)

The workflow [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml) runs on every push to `main`: it downloads the model, runs the tests, builds the PWA with `--base-href /<repo>/` and publishes it to `https://<user>.github.io/<repo>/`.

One-time repository setting: **Settings → Pages → Source: GitHub Actions**. On the free plan, Pages only works for public repositories.

The MobileCLIP model is distributed under Apple's license; the license text is published next to the model (`models/LICENSE-MobileCLIP.txt`).

The first load is ≈ 45 MB (23 MB model + 12 MB ONNX runtime + the app); after that everything comes from the cache.

## Caching and auto-update

The app works offline but never gets stuck on an old version:

- **[`web/sw.js`](web/sw.js).** The model and onnxruntime (~35 MB) are cache-first. Everything else is network-first and bypasses the browser HTTP cache (GitHub Pages sends `max-age=600`); the cache is used only without a network. Flutter's built-in service worker is disabled.
- **[`tools/build_web.sh`](tools/build_web.sh).** Chrome may serve a `<script>` from its memory cache, bypassing the service worker, so every build gets its own URLs: `main.dart.js?v=<hash>`, `flutter_bootstrap.js?v=…`, `food_ai.js?v=…`, `canvaskit-<engine revision>/`. The service worker removes old versions from the cache.
- **[`lib/update_checker.dart`](lib/update_checker.dart).** CI compiles `BUILD_ID` (the commit sha) into the app and publishes it as `build_id.txt`. The app compares versions on start, when it returns from the background, and every 30 minutes. On the home screen it reloads silently; in the middle of an entry it shows an "Update" button instead. A guard prevents reload loops.
- When you change the model or the onnxruntime version in `tools/fetch_assets.sh`, bump `ASSETS_CACHE` in `web/sw.js`.

## Adding or editing a dish

1. Edit `assets/dishes.tsv`: `name_ru` / `name_en` are display names, `prompt` is an English description for the model, `category` is one of the category ids translated in `lib/l10n/`. The more distinctive the prompt ("layered salad with grated beetroot on top"), the better the recognition.
2. Recompute the embeddings:
   ```bash
   cd tools && npm install && node build_embeddings.mjs
   ```
3. Check quality on your own photos: put them into `tools/testimg/` and run `node eval.mjs fp16`.

## Look and icon

The palette lives in [`lib/ui/palette.dart`](lib/ui/palette.dart): herb greens flowing into a saturated blue, used for the theme, the gradient buttons and day card, and the calendar heatmap (pale green → green → deep blue as you approach 150% of the daily goal).

The icon is a faceted heart made of a lighter green half and a darker blue half. It is generated from code, not drawn by hand: [`tools/make_icons.mjs`](tools/make_icons.mjs) writes `tools/icon.svg` and renders every PNG (PWA icons, maskable icons, apple-touch icon, favicon, in-app logo) with headless Chrome:

```bash
cd tools && npm install && node make_icons.mjs   # CHROME_PATH=… if Chrome isn't in /Applications
```

## Adding a UI language

Add `lib/l10n/app_<code>.arb` (copy `app_en.arb`), a `name_<code>` column to the catalog with handling in `Formatting.dishName` ([`lib/ui/format.dart`](lib/ui/format.dart)), and the language to the list in [`lib/ui/settings_page.dart`](lib/ui/settings_page.dart).

## Tests

```bash
flutter test
```

## Known limitations

- A photo may contain several dishes: the model suggests options, and extra items can be added to the plate manually. There is no separate object detector.
- Similar dishes (pelmeni, manti, khinkali) get confused, which is why the top 5 options are always shown.
- Safari may clear data of a site that hasn't been opened for a long time. The risk is lower for a PWA installed to the home screen, but export and backup are the next step.
