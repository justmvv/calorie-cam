# Calorie Cam

A Flutter PWA food diary: take a photo of a dish, the app suggests what it is and how many calories it has, and after you confirm, the entry goes into your diary. There is a monthly heatmap and a breakdown for every day.

Everything runs **locally in the browser**: recognition is done by an on-device model, and the diary is stored in SQLite (WASM) in browser storage. After the first load no network is needed.

The UI is available in **English, Spanish, Dutch and Russian**. By default it follows the system language (unsupported languages fall back to English); it can be switched in Settings.

## How it works

```
photo ──► web/food_ai.js ─────────────────► embedding (512) ──► DishCatalog.classify ──► top 5 dishes
          (onnxruntime-web + MobileCLIP-S0)                      (cosine similarity with
                                                                  dish text embeddings)
user picks the dish and portion ──► kcal = kcal/100 g × grams ──► Drift (SQLite WASM)
```

- **Recognition:** zero-shot [MobileCLIP-S0](https://github.com/apple/ml-mobileclip) (fp16 vision encoder, ~23 MB). A dish is recognized if it's in the catalog; no model retraining is needed. Besides the whole photo, five overlapping parts of it are analyzed in one batch, so a side dish or salad next to the main dish is put on the plate too (`DishCatalog.suggestPlate`: one dish per role — main, side, salad, … — with per-role confidence thresholds; tune with `tools/eval_plate.mjs`).
- **Catalog:** [`assets/dishes.tsv`](assets/dishes.tsv), ~250 dishes — Russian, Spanish, Dutch (including the Indonesian-Dutch classics) and international — with names in every UI language, calories/protein/fat/carbs per 100 g and a typical portion. Text embeddings are precomputed in `assets/dish_embeddings.*`.
- **Database:** [`lib/data/db.dart`](lib/data/db.dart): `meals` (what, how much, when; nutrition already scaled to the portion), `photos` (~15 KB JPEG thumbnails), `products` (the user's own products, per 100 g) and `meal_sets` (saved sets of items). Rows have global UUIDs, a millisecond `updated_at_ms` and soft deletes (tombstones), so backups from different moments or devices merge cleanly.
- **Localization:** ARB files in [`lib/l10n/`](lib/l10n/) (`flutter gen-l10n`). Logged entries are shown with the catalog name in the current language.
- **Offline and updates:** see the section below.

Portion weight is not estimated from the photo — that isn't reliable. The user sets the portion; the ½/×1/×1.5/×2 presets are relative to the dish's typical portion.

## Adding a meal

- **Photo** → the main dish and, if visible, a side/salad are preselected; other options are chips. **Add photo** puts more photos into the same meal (e.g. a set lunch: soup, main, drink); each item keeps the thumbnail of its photo.
- **Portion in grams or in kcal**: the amount field of an item (and of a diary entry when editing it) switches between grams and calories for the whole item — when the total is known exactly, type it in; the grams and macros follow from the dish's calorie density.
- **Edit calories** (tap the "kcal per 100 g" line of an item): type the numbers from the package, per 100 g or per portion; optionally save as one of **My products**.
- **Search** lists **Enter calories manually**, **My sets**, **My products** (swipe to delete) and the catalog. The bookmark button saves the current plate as a set.
- **Share the day** (share icon on the day) renders a picture of the day — total, macros, dishes — and hands it as a PNG to the share sheet.

## Running

```bash
tools/fetch_assets.sh          # once: model and onnxruntime-web into web/ (not stored in git)
flutter pub get
dart run build_runner build    # Drift code
flutter run -d chrome          # development
tools/build_web.sh             # release PWA in build/web (versioned URLs)
```

On a phone you need **HTTPS**, otherwise the browser won't allow the camera or the service worker. Then choose "Add to Home Screen" in Safari or Chrome.

## Versions

`version:` in `pubspec.yaml` is the release (bump it with each set of changes and add an entry to
[CHANGELOG.md](CHANGELOG.md)); CI uses the GitHub Actions run number as the build number.
Settings shows e.g. "Version 1.5.0 · build 57 (394ddf3)".

## Publishing (GitHub Pages)

The workflow [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml) runs on every push to `main`: it downloads the model, runs the tests, builds the PWA with `--base-href /<repo>/` and publishes it to `https://<user>.github.io/<repo>/`.

One-time repository setting: **Settings → Pages → Source: GitHub Actions**. On the free plan, Pages only works for public repositories.

The MobileCLIP model is distributed under Apple's license; the license text is published next to the model (`models/LICENSE-MobileCLIP.txt`).

The first load is ≈ 45 MB (23 MB model + 12 MB ONNX runtime + the app); after that everything comes from the cache.

## Backup

Settings → Backup:

- **Export diary** writes a JSON file (`calorie-cam-backup-<date>.json`, format version 2: entries, photos as base64, My products, My sets, daily goal and language) and opens the system share sheet — on Android pick Google Drive, Files or a messenger. Where file sharing isn't available it is downloaded instead. The file is prepared when Settings opens: Chrome opens the share sheet only within a few seconds of a tap.
- **Import from file** (version 1 or 2) merges a backup by UUID: new entries are added, an entry present on both sides keeps the newer edit, deletions stay deleted, and importing the same file twice changes nothing. Settings are restored only into an empty diary (e.g. a new phone).
- On start the app calls `navigator.storage.persist()` so the browser doesn't evict the diary when space runs low; Settings shows whether it was granted (Chrome grants it to installed PWAs).

Format and merge rules: [`lib/data/backup.dart`](lib/data/backup.dart); tests (including the v1 → v2 schema migration): [`test/backup_test.dart`](test/backup_test.dart).

## Caching and auto-update

The app works offline but never gets stuck on an old version:

- **[`web/sw.js`](web/sw.js).** The model and onnxruntime (~35 MB) are cache-first. Everything else is network-first and bypasses the browser HTTP cache (GitHub Pages sends `max-age=600`); the cache is used only without a network. Flutter's built-in service worker is disabled.
- **[`tools/build_web.sh`](tools/build_web.sh).** Chrome may serve a `<script>` from its memory cache, bypassing the service worker, so every build gets its own URLs: `main.dart.js?v=<hash>`, `flutter_bootstrap.js?v=…`, `food_ai.js?v=…`, `b-<hash>/assets/` (Flutter's `assetBase`, so the dish catalog and its embeddings always come from the same release as the code), `canvaskit-<engine revision>/`. The service worker removes old versions from the cache.
- **[`lib/update_checker.dart`](lib/update_checker.dart).** CI compiles `BUILD_ID` (the commit sha) into the app and publishes it as `build_id.txt`. The app compares versions on start, when it returns from the background, and every 30 minutes. On the home screen it reloads silently; in the middle of an entry it shows an "Update" button instead. A guard prevents reload loops.
- When you change the model or the onnxruntime version in `tools/fetch_assets.sh`, bump `ASSETS_CACHE` in `web/sw.js`.

## Adding or editing a dish

1. Edit `assets/dishes.tsv`: `name_<lang>` columns are display names (one per UI language), `prompt` is an English description for the model, `category` is one of the category ids translated in `lib/l10n/`. The more distinctive the prompt ("layered salad with grated beetroot on top"), the better the recognition.
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

Add `lib/l10n/app_<code>.arb` (copy `app_en.arb`), a `name_<code>` column to the catalog (picked up automatically; missing names fall back to English), and the language to the list in [`lib/ui/settings_page.dart`](lib/ui/settings_page.dart). The tests check that every dish and category has a translation in every UI language.

## Tests

```bash
flutter test
```

## Known limitations

- There is no real object detector: sides are found by looking at parts of the photo, which works when the side takes a noticeable part of the plate; small items (a sauce, a slice of bread) may need adding by hand.
- Similar dishes (pelmeni, manti, khinkali) get confused, which is why the top 5 options are always shown.
- Safari may clear data of a site that hasn't been opened for a long time. The risk is lower for a PWA installed to the home screen; export a backup regularly.
