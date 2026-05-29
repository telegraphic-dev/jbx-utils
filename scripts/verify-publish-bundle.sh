#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
JBX=${JBX:-jbx}
CACHE_DIR=${JBX_CACHE_DIR:-"$ROOT/.jbx-cache"}
TARGET_DIR=${JBX_TARGET_DIR:-"$ROOT/target/publish"}
BUNDLE=${JBX_BUNDLE:-"$ROOT/target/jbx-utils-central-bundle.zip"}
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

BASE="dev/telegraphic/jbx/jbx-utils/$VERSION"
jar tf "$BUNDLE" | grep -q "$BASE/jbx-utils-$VERSION.jar"
jar tf "$BUNDLE" | grep -q "$BASE/jbx-utils-$VERSION-sources.jar"
jar tf "$BUNDLE" | grep -q "$BASE/jbx-utils-$VERSION-javadoc.jar"
jar tf "$BUNDLE" | grep -q "$BASE/jbx-utils-$VERSION.pom"
jar tf "$BUNDLE" | grep -q "$BASE/jbx-utils-$VERSION-jbx-docs.md"
jar tf "$BUNDLE" | grep -q "$BASE/jbx-utils-$VERSION-jbx-docs.json"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
unzip -q "$BUNDLE" "$BASE/jbx-utils-$VERSION.jar" -d "$TMP"
jar tf "$TMP/$BASE/jbx-utils-$VERSION.jar" | grep -q 'dev/telegraphic/jbx/check/JbxCheckCompiler.class'
jar tf "$TMP/$BASE/jbx-utils-$VERSION.jar" | grep -q 'dev/telegraphic/jbx/graph/JbxGraph.class'
