#!/bin/bash

set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
UPSTREAM_REPO_URL="${UPSTREAM_REPO_URL:-https://git.drupalcode.org/project/ai_best_practices.git}"
UPSTREAM_REF="${UPSTREAM_REF:-1.0.x}"
WORK_DIR="$(mktemp -d)"
UPSTREAM_DIR="$WORK_DIR/upstream"
UPSTREAM_DIR_OVERRIDE="${UPSTREAM_DIR_OVERRIDE:-}"

cleanup() {
  rm -rf "$WORK_DIR"
}

trap cleanup EXIT

resolve_source_path() {
  local source_name="$1"
  local candidate

  for candidate in \
    "$UPSTREAM_DIR/$source_name" \
    "$UPSTREAM_DIR/references/$source_name" \
    "$UPSTREAM_DIR/backend/$source_name" \
    "$UPSTREAM_DIR/frontend/$source_name" \
    "$UPSTREAM_DIR/references/backend/$source_name" \
    "$UPSTREAM_DIR/references/frontend/$source_name"; do
    if [[ -f "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  candidate="$(find "$UPSTREAM_DIR" -maxdepth 4 -type f -name "$source_name" | head -n 1)"
  if [[ -n "$candidate" ]]; then
    printf '%s\n' "$candidate"
    return 0
  fi

  return 1
}

sync_file() {
  local source_name="$1"
  local destination="$2"
  local source_path

  source_path="$(resolve_source_path "$source_name")" || {
    echo "Missing upstream file: $source_name" >&2
    return 1
  }

  mkdir -p "$(dirname "$ROOT_DIR/$destination")"

  if [[ -f "$ROOT_DIR/$destination" ]] && cmp -s "$source_path" "$ROOT_DIR/$destination"; then
    echo "Unchanged: $destination"
    return 0
  fi

  cp "$source_path" "$ROOT_DIR/$destination"
  echo "Updated: $destination"
}

if [[ -n "$UPSTREAM_DIR_OVERRIDE" ]]; then
  UPSTREAM_DIR="$UPSTREAM_DIR_OVERRIDE"
  echo "Using local upstream directory: $UPSTREAM_DIR"
else
  echo "Cloning $UPSTREAM_REPO_URL ($UPSTREAM_REF)"
  if ! git clone --depth 1 --branch "$UPSTREAM_REF" "$UPSTREAM_REPO_URL" "$UPSTREAM_DIR"; then
    echo "Falling back to upstream default branch"
    git clone --depth 1 "$UPSTREAM_REPO_URL" "$UPSTREAM_DIR"
  fi
fi

declare -a FILE_MAPPINGS=(
  "configuration.md:references/backend/configuration.md"
  "documentation.md:references/backend/documentation.md"
  "common-mistakes.md:references/backend/common-mistakes.md"
  "testing.md:references/backend/testing.md"
  "render-pipeline.md:references/frontend/render-pipeline.md"
  "accessibility.md:references/frontend/accessibility.md"
  "devops.md:references/devops.md"
)

for mapping in "${FILE_MAPPINGS[@]}"; do
  IFS=":" read -r source_name destination <<< "$mapping"
  sync_file "$source_name" "$destination"
done
