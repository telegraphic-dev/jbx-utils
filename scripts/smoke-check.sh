#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
JBX=${JBX:-jbx}
CLASSES=${CLASSES:-"$ROOT/target/classes"}
SAMPLE_DIR=${SAMPLE_DIR:-"$ROOT/target/smoke"}
CACHE_DIR=${JBX_CACHE_DIR:-"$ROOT/.jbx-cache"}

rm -rf "$CLASSES" "$SAMPLE_DIR"
mkdir -p "$CLASSES" "$SAMPLE_DIR"

javac --release 21 -d "$CLASSES" "$ROOT/src/JbxCheckCompiler.java"

cat > "$SAMPLE_DIR/Broken.java" <<'JAVA'
class Broken {
  int value() {
    return missing;
  }
}
JAVA

set +e
output=$(java -cp "$CLASSES" dev.telegraphic.jbx.check.JbxCheckCompiler -Xlint:all -proc:none -- "$SAMPLE_DIR/Broken.java" 2>&1)
status=$?
set -e

if [ "$status" -eq 0 ]; then
  echo "expected compiler wrapper to fail for Broken.java" >&2
  echo "$output" >&2
  exit 1
fi

printf '%s\n' "$output" | python3 -m json.tool >/dev/null
printf '%s\n' "$output" | grep -q '"ok": false'
printf '%s\n' "$output" | grep -q 'cannot find symbol'

set +e
invalid_output=$(java -cp "$CLASSES" dev.telegraphic.jbx.check.JbxCheckCompiler --definitely-not-a-javac-option -- "$SAMPLE_DIR/Broken.java" 2>&1)
invalid_status=$?
set -e

if [ "$invalid_status" -eq 0 ]; then
  echo "expected invalid javac option to fail" >&2
  echo "$invalid_output" >&2
  exit 1
fi

printf '%s\n' "$invalid_output" | python3 -m json.tool >/dev/null
printf '%s\n' "$invalid_output" | grep -q '"ok": false'
printf '%s\n' "$invalid_output" | grep -q 'error: invalid flag: --definitely-not-a-javac-option'

cat > "$SAMPLE_DIR/Example.java" <<'JAVA'
class Example {
  void main() {
    String message = "hello";
    IO.println(message);
  }
}
JAVA

"$JBX" run "$ROOT/src/JbxGraph.java" --cache-dir "$CACHE_DIR" -- dump "$SAMPLE_DIR/Example.java" > "$SAMPLE_DIR/Example.json"
python3 - "$SAMPLE_DIR/Example.json" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
assert data["!"] == "com.github.javaparser.ast.CompilationUnit", data
PY

"$JBX" run "$ROOT/src/JbxGraph.java" --cache-dir "$CACHE_DIR" -- import "$SAMPLE_DIR/Example.json" > "$SAMPLE_DIR/RoundTrip.java"
grep -q 'class Example' "$SAMPLE_DIR/RoundTrip.java"
grep -q 'String message = "hello";' "$SAMPLE_DIR/RoundTrip.java"
