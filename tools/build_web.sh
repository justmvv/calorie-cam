#!/usr/bin/env bash
# Release PWA build with versioned URLs (keeps caches from serving stale code).
#   tools/build_web.sh [flutter build web args, e.g. --base-href /calorie-cam/]
#
# Browsers may serve a <script> from the memory cache, bypassing the service worker, so files
# that change from build to build get unique URLs:
#   main.dart.js, flutter_bootstrap.js, food_ai.js → ?v=<build hash>
#   canvaskit/ → canvaskit-<engine revision>/ (changes with the Flutter version)
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=build/web

flutter build web --release --no-web-resources-cdn "$@"

VERSION=$(cat "$OUT/main.dart.js" "$OUT/food_ai.js" "$OUT/flutter_bootstrap.js" | shasum -a 256 | cut -c1-12)
REV=$(grep -o '"engineRevision":"[0-9a-f]*"' "$OUT/flutter_bootstrap.js" | cut -d'"' -f4)
[ -n "$REV" ] || { echo "engineRevision not found in flutter_bootstrap.js" >&2; exit 1; }

sed -i.bak "s/^const buildVersion = '';/const buildVersion = '$VERSION';/" "$OUT/flutter_bootstrap.js"
sed -i.bak -e "s#src=\"flutter_bootstrap.js\"#src=\"flutter_bootstrap.js?v=$VERSION\"#" \
           -e "s#src=\"food_ai.js\"#src=\"food_ai.js?v=$VERSION\"#" "$OUT/index.html"
rm -f "$OUT"/*.bak
rm -rf "$OUT/canvaskit-$REV" && mv "$OUT/canvaskit" "$OUT/canvaskit-$REV"

grep -q "buildVersion = '$VERSION'" "$OUT/flutter_bootstrap.js"
grep -q "flutter_bootstrap.js?v=$VERSION" "$OUT/index.html"
echo "Build $VERSION, CanvasKit $REV"
