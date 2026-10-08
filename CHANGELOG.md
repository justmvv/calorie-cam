# Changelog

Versions follow `version:` in `pubspec.yaml`; the build number is the GitHub Actions run that
published it. The running version is shown at the bottom of Settings.

## 1.6.1 — 2026-10-08

- Fixed: on some phones the GPU computed the model wrongly (invalid numbers), and the app showed
  the first dishes of the catalog with no real percentages. Now the GPU is used only after its
  result for a test picture matches the CPU's on that device, any invalid result switches to the
  CPU for good, and invalid numbers can no longer turn into a list. Settings shows GPU or CPU next
  to the version.

## 1.6.0 — 2026-10-08

- Bigger recognition model: MobileCLIP-S2 instead of S0 — 55% vs 47% right on the first try,
  79% vs 74% in the top 5 (763 Wikipedia photos of 235 dishes). The model download grows from
  23 to 72 MB (once; then cached).
- Recognition runs on the GPU (WebGPU) where the browser supports it: parts of the photo are
  analyzed ~10× faster; other browsers use the CPU as before.
- Recognition memory: each logged photo is remembered with what ended up on the plate; a similar
  photo next time gets "As last time" (put on the plate right away when nearly identical), which
  also recognizes your own products and canteen sets. Settings shows the count and can forget it;
  backups include it.
- Set lunch: soup and a main can be picked together; the photo is analyzed as a 3 × 3 grid and up
  to 5 items are put on the plate.
- Gentle context hints: breakfast dishes in the morning, soups at midday, dishes you eat often.

## 1.5.0 — 2026-10-07

- Plates with sides: besides the whole photo, parts of it are analyzed so a side dish or salad is
  put on the plate next to the main dish.
- Several photos per meal (set lunch); each item keeps its own thumbnail.
- Portion can be typed as calories for the whole item instead of grams (also when editing a diary
  entry); calories of any item can be edited, e.g. from a package label.
- My products and My sets; "Enter calories manually" in search.
- Share the day as a picture.
- Tapping another recognized option replaces the suggested dish instead of adding both.
- Catalog: pumpkin and millet porridge, liver fritters, unsweetened coffee drinks, sugar.
- Removed "Search the web": no way to do it automatically without a paid API key.
- Fixed: undo notification after deleting stayed on screen; backup export failing on Android.
- App version shown in Settings.

## 1.4.0 — 2026-10-07

- Backup: JSON export/import with merging, persistent storage; protein and granola bars.

## 1.3.0 — 2026-10-07

- Spanish and Dutch UI, dish names and local cuisine.

## 1.2.0 — 2026-10-06

- New look (herb green to blue) and the faceted heart icon; fixes for the shared github.io origin.

## 1.1.0 — 2026-10-05

- English UI with a language switch; offline cache without stale versions and auto-update.

## 1.0.0 — 2026-10-02

- First version: on-device dish recognition, diary, monthly heatmap, day details.
