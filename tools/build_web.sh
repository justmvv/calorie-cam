#!/usr/bin/env bash
# Release PWA build with versioned URLs (keeps caches from serving stale code).
#   tools/build_web.sh [flutter build web args, e.g. --base-href /calorie-cam/]
#
# Browsers may serve a <script> from the memory cache, bypassing the service worker, so files
# that change from build to build get unique URLs:
#   main.dart.js, flutter_bootstrap.js, food_ai.js, camera.js → ?v=<build hash>
#   assets/ → b-<build hash>/assets/ (Flutter's assetBase; the dish catalog and its embeddings
#             must always come from the same release as the code)
#   canvaskit/ → canvaskit-<engine revision>/ (changes with the Flutter version)
#
# Version: the name comes from pubspec.yaml (version: X.Y.Z+N), the build number from
# $BUILD_NUMBER (CI sets the run number) or else from pubspec. Both are compiled into the app
# (shown in Settings) and written to version.json.
#
# The manifest "id" is set to the base href: an id is resolved against the origin, not the
# manifest's folder, so a relative "./" would claim the whole <user>.github.io origin.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=build/web

BASE_HREF=/
for ((i = 1; i <= $#; i++)); do
  case "${!i}" in
    --base-href) j=$((i + 1)); BASE_HREF="${!j}" ;;
    --base-href=*) BASE_HREF="${!i#--base-href=}" ;;
  esac
done

PUBSPEC_VERSION=$(grep -E '^version:' pubspec.yaml | awk '{print $2}')
VERSION_NAME=${PUBSPEC_VERSION%%+*}
BUILD_NUMBER=${BUILD_NUMBER:-${PUBSPEC_VERSION##*+}}

flutter build web --release --no-web-resources-cdn \
  --build-name="$VERSION_NAME" --build-number="$BUILD_NUMBER" \
  --dart-define=APP_VERSION="$VERSION_NAME" --dart-define=BUILD_NUMBER="$BUILD_NUMBER" \
  "$@"

VERSION=$( (cat "$OUT/main.dart.js" "$OUT/food_ai.js" "$OUT/camera.js" "$OUT/flutter_bootstrap.js"
            find "$OUT/assets" -type f | LC_ALL=C sort | xargs cat) | shasum -a 256 | cut -c1-12)
REV=$(grep -o '"engineRevision":"[0-9a-f]*"' "$OUT/flutter_bootstrap.js" | cut -d'"' -f4)
[ -n "$REV" ] || { echo "engineRevision not found in flutter_bootstrap.js" >&2; exit 1; }

sed -i.bak "s/^const buildVersion = '';/const buildVersion = '$VERSION';/" "$OUT/flutter_bootstrap.js"
sed -i.bak -e "s#src=\"flutter_bootstrap.js\"#src=\"flutter_bootstrap.js?v=$VERSION\"#" \
           -e "s#src=\"food_ai.js\"#src=\"food_ai.js?v=$VERSION\"#" \
           -e "s#src=\"camera.js\"#src=\"camera.js?v=$VERSION\"#" "$OUT/index.html"
sed -i.bak "s#\"id\": \"[^\"]*\"#\"id\": \"$BASE_HREF\"#" "$OUT/manifest.json"
rm -f "$OUT"/*.bak
rm -rf "$OUT/canvaskit-$REV" && mv "$OUT/canvaskit" "$OUT/canvaskit-$REV"
rm -rf "$OUT"/b-* && mkdir "$OUT/b-$VERSION" && mv "$OUT/assets" "$OUT/b-$VERSION/assets"

grep -q "buildVersion = '$VERSION'" "$OUT/flutter_bootstrap.js"
grep -q "flutter_bootstrap.js?v=$VERSION" "$OUT/index.html"
grep -q "\"id\": \"$BASE_HREF\"" "$OUT/manifest.json"
[ -f "$OUT/b-$VERSION/assets/AssetManifest.bin" ]
echo "Version $VERSION_NAME+$BUILD_NUMBER, build $VERSION, CanvasKit $REV, manifest id $BASE_HREF"
