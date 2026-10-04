#!/usr/bin/env bash
# Renders the VistaColosseum app's main screens to PNGs for review.
# Usage: render_screens.sh <output-dir>   (run from anywhere)
# Prints one line per test result, then the list of PNGs written.
set -euo pipefail
OUT="${1:?usage: render_screens.sh <output-dir>}"
HERE="$(cd "$(dirname "$0")" && pwd)"
APP="$(cd "$HERE/../../../../app" && pwd)"
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"
TEST="$APP/test/zz_review_render_tmp_test.dart"
sed "s|__OUT_DIR__|$OUT|" "$HERE/render_screens_test.dart.tmpl" > "$TEST"
trap 'rm -f "$TEST"' EXIT
cd "$APP"
# A failing screen is reported but doesn't stop the others.
flutter test "$TEST" --update-goldens 2>&1 | grep -E "^\S.*(\+|-)[0-9]+.*(: [a-z ]+$|\[E\])|All tests passed|Some tests failed" | tail -20 || true
ls -1 "$OUT"/*.png 2>/dev/null
