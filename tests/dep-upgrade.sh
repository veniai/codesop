#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$(dirname "$0")/test_helpers.sh"

# --- dependencies.sh manifest ---

manifest_output="$(cat "$ROOT_DIR/config/dependencies.sh")"
assert_contains "$manifest_output" "DEP_MANIFEST"
assert_contains "$manifest_output" "superpowers@claude-plugins-official"
assert_contains "$manifest_output" "core|yes|6.0.2"
assert_contains "$manifest_output" "code-review@claude-plugins-official"
assert_contains "$manifest_output" "codex@openai-codex"

# Every entry should have 5 pipe-separated fields
entry_count=0
while IFS= read -r line; do
  [[ "$line" =~ ^[[:space:]]*$ ]] && continue
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  [[ "$line" =~ DEP_MANIFEST ]] && continue
  [[ "$line" =~ ^[[:space:]]*\) ]] && continue
  field_count=$(echo "$line" | tr -cd '|' | wc -c | tr -d ' ')
  [ "$field_count" -eq 4 ] || fail "Expected 4 pipes in: $line (got $field_count)"
  entry_count=$((entry_count + 1))
done < <(sed -n '/^DEP_MANIFEST=/,/^[[:space:]]*)/p' "$ROOT_DIR/config/dependencies.sh")
[ "$entry_count" -ge 8 ] || fail "Expected >= 8 entries in DEP_MANIFEST, got $entry_count"

# --- updates.sh has upgrade functions ---

updates_output="$(cat "$ROOT_DIR/lib/updates.sh")"
assert_contains "$updates_output" "_dep_manifest_load"
assert_contains "$updates_output" "_dep_parse"
assert_contains "$updates_output" "_dep_upgrade_one"
assert_contains "$updates_output" "dep_patch_compat"
assert_contains "$updates_output" "upgrade_managed_deps"
assert_contains "$updates_output" "install_managed_deps"
assert_contains "$updates_output" "claude plugin update"
assert_contains "$updates_output" "claude plugin install"
assert_contains "$updates_output" "has_required_fail"

# --- patch_skills() compat check in setup ---

setup_output="$(cat "$ROOT_DIR/setup")"
assert_contains "$setup_output" "dependencies.sh"
assert_contains "$setup_output" "install_managed_deps"
assert_contains "$setup_output" "inst_mm"
assert_contains "$setup_output" "patch_mm"
assert_contains "$setup_output" "skipping patches"

# --- commands.sh integration ---

commands_output="$(cat "$ROOT_DIR/lib/commands.sh")"
assert_contains "$commands_output" "upgrade_managed_deps"

echo "PASS"
