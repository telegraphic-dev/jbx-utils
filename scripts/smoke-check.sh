#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CLASSES=${CLASSES:-"$ROOT/target/classes"}
SAMPLE_DIR=${SAMPLE_DIR:-"$ROOT/target/smoke"}

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
