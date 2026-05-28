#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
JBX=${JBX:-jbx}
CACHE_DIR=${JBX_CACHE_DIR:-"$ROOT/.jbx-cache"}
TARGET_DIR=${JBX_TARGET_DIR:-"$ROOT/target/publish"}
BUNDLE=${JBX_BUNDLE:-"$ROOT/target/jbx-check-central-bundle.zip"}
VERSION=${JBX_VERSION:-$(python3 - "$ROOT/jbx.json" <<'PY'
import json
import sys
with open(sys.argv[1], encoding='utf-8') as f:
    print(json.load(f)["version"])
PY
)}

mkdir -p "$(dirname "$BUNDLE")"

"$JBX" publish \
  --dry-run \
  --skip-signing \
  --file "$ROOT/jbx.json" \
  --output "$BUNDLE" \
  --target-dir "$TARGET_DIR" \
  --cache-dir "$CACHE_DIR"

BASE="dev/telegraphic/jbx/jbx-check/$VERSION"
jar tf "$BUNDLE" | grep -q "$BASE/jbx-check-$VERSION.jar"
jar tf "$BUNDLE" | grep -q "$BASE/jbx-check-$VERSION-sources.jar"
jar tf "$BUNDLE" | grep -q "$BASE/jbx-check-$VERSION-javadoc.jar"
