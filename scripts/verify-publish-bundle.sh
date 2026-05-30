#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
JBX=${JBX:-jbx}
CACHE_DIR=${JBX_CACHE_DIR:-"$ROOT/.jbx-cache"}
TARGET_ROOT=${JBX_TARGET_DIR:-"$ROOT/target/publish"}
BUNDLE_ROOT=${JBX_BUNDLE_DIR:-"$ROOT/target"}
VERSION=${JBX_VERSION:-0.1.0}

verify_project() {
  local project=$1
  local package_path=$2
  local expected_class=$3
  local forbidden_class=$4
  local target_dir="$TARGET_ROOT/$project"
  local bundle="$BUNDLE_ROOT/$project-central-bundle.zip"
  local base="dev/telegraphic/jbx/$project/$VERSION"

  mkdir -p "$(dirname "$bundle")"

  "$JBX" publish \
    --dry-run \
    --skip-signing \
    --file "$ROOT/$project/jbx.json" \
    --output "$bundle" \
    --target-dir "$target_dir" \
    --cache-dir "$CACHE_DIR"

  jar tf "$bundle" | grep -q "$base/$project-$VERSION.jar"
  jar tf "$bundle" | grep -q "$base/$project-$VERSION-sources.jar"
  jar tf "$bundle" | grep -q "$base/$project-$VERSION-javadoc.jar"
  jar tf "$bundle" | grep -q "$base/$project-$VERSION.pom"
  jar tf "$bundle" | grep -q "$base/$project-$VERSION-jbx-docs.md"
  jar tf "$bundle" | grep -q "$base/$project-$VERSION-jbx-docs.json"

  local tmp
  tmp=$(mktemp -d)
  unzip -q "$bundle" "$base/$project-$VERSION.jar" -d "$tmp"
  jar tf "$tmp/$base/$project-$VERSION.jar" | grep -q "$package_path/$expected_class.class"
  if jar tf "$tmp/$base/$project-$VERSION.jar" | grep -q "$forbidden_class"; then
    echo "$project jar unexpectedly contains $forbidden_class" >&2
    exit 1
  fi
  rm -rf "$tmp"
}

verify_project jbx-check dev/telegraphic/jbx/check JbxCheckCompiler 'dev/telegraphic/jbx/graph/JbxGraph.class'
verify_project jbx-graph dev/telegraphic/jbx/graph JbxGraph 'dev/telegraphic/jbx/check/JbxCheckCompiler.class'
verify_project jbx-rewrite dev/telegraphic/jbx/rewrite JbxRewrite 'dev/telegraphic/jbx/graph/JbxGraph.class'
