#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  printf '%s' "$haystack" | grep -qxF "$needle" || fail "expected output to contain: $needle"
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  if printf '%s' "$haystack" | grep -qxF "$needle"; then
    fail "expected output to NOT contain: $needle"
  fi
}

# --- Source dependencies ---
VERSION_FILE="$ROOT_DIR/VERSION"
source "$ROOT_DIR/lib/detection.sh"
source "$ROOT_DIR/lib/updates.sh"

# --- Test 1: check_routing_coverage against real router table ---
echo "Test 1: check_routing_coverage against real router table"

result="$(ROOT_DIR="$ROOT_DIR" check_routing_coverage)" || fail "check_routing_coverage failed on real router table"
# Should complete without error (may report missing skills, which is OK)
[ -n "$result" ] || fail "check_routing_coverage returned empty"

echo "  PASS"

# --- Test 2: check_routing_coverage with isolated HOME (no plugins) ---
echo "Test 2: check_routing_coverage with no plugins installed"

_isolated_home="$(mktemp -d)"
result="$(HOME="$_isolated_home" ROOT_DIR="$ROOT_DIR" check_routing_coverage)" || true
rm -rf "$_isolated_home"
# Should report missing items, not crash
[ -n "$result" ] || fail "expected non-empty output even with no plugins"

echo "  PASS"

# --- Test 3: check_plugin_completeness with isolated HOME ---
echo "Test 3: check_plugin_completeness with no plugins file"

_isolated_home="$(mktemp -d)"
result="$(HOME="$_isolated_home" check_plugin_completeness)" && fail "expected non-zero exit when plugins file missing" || true
rm -rf "$_isolated_home"

echo "  PASS"

# --- Test 4: Dependency arrays are populated ---
echo "Test 4: Dependency arrays are populated"

[ -n "$SUPERPOWERS_PLUGIN" ] || fail "SUPERPOWERS_PLUGIN is empty"
[ ${#REQUIRED_PLUGINS[@]} -gt 0 ] || fail "REQUIRED_PLUGINS is empty"
[ ${#OPTIONAL_SKILLS[@]} -gt 0 ] || fail "OPTIONAL_SKILLS is empty"

echo "  PASS (${#REQUIRED_PLUGINS[@]} required, ${#OPTIONAL_SKILLS[@]} skills)"

# --- Test 5: check_codesop_document_consistency version alignment (real repo) ---
echo "Test 5: check_codesop_document_consistency version alignment"

result="$(ROOT_DIR="$ROOT_DIR" VERSION_FILE="$ROOT_DIR/VERSION" check_codesop_document_consistency)" || true
printf '%s' "$result" | grep -q "版本" || fail "version alignment line missing"

echo "  PASS"

# --- Test 6: check_codesop_document_consistency detects version mismatch ---
echo "Test 6: check_codesop_document_consistency detects version mismatch"

_mismatch_dir="$(mktemp -d)"
echo "1.0.0" > "$_mismatch_dir/VERSION"
echo '{"version": "2.0.0"}' > "$_mismatch_dir/skill.json"
mkdir -p "$_mismatch_dir/config"
echo '# Current Version: 3.0.0' > "$_mismatch_dir/PRD.md"
cp "$ROOT_DIR/config/codesop-router.md" "$_mismatch_dir/config/" 2>/dev/null || true
result="$(ROOT_DIR="$_mismatch_dir" VERSION_FILE="$_mismatch_dir/VERSION" check_codesop_document_consistency)" || true
printf '%s' "$result" | grep -q "版本不一致" || fail "should detect version mismatch"
rm -rf "$_mismatch_dir"

echo "  PASS"

# --- Test 7: check_codesop_document_consistency detects stale references ---
echo "Test 7: check_codesop_document_consistency detects stale references"

_stale_dir="$(mktemp -d)"
echo "2.0.0" > "$_stale_dir/VERSION"
echo '{"version": "2.0.0"}' > "$_stale_dir/skill.json"
echo '# Current Version: 2.0.0' > "$_stale_dir/PRD.md"
mkdir -p "$_stale_dir/config" "$_stale_dir/templates/system" "$_stale_dir/commands"
cp "$ROOT_DIR/config/codesop-router.md" "$_stale_dir/config/" 2>/dev/null || true
echo "Use codesop-setup for setup" > "$_stale_dir/README.md"
: > "$_stale_dir/SKILL.md"
: > "$_stale_dir/templates/system/AGENTS.md"
: > "$_stale_dir/commands/codesop-init.md"
: > "$_stale_dir/commands/codesop-update.md"
result="$(ROOT_DIR="$_stale_dir" VERSION_FILE="$_stale_dir/VERSION" check_codesop_document_consistency)" || true
printf '%s' "$result" | grep -q "过时引用" || fail "should detect stale reference 'codesop-setup'"
rm -rf "$_stale_dir"

echo "  PASS"

# --- Test 8: check_project_document_drift flags code-only changes ---
echo "Test 8: check_project_document_drift flags code-only changes"

_project_dir="$(mktemp -d)"
git -C "$_project_dir" init -q
printf '@CLAUDE.md\n' > "$_project_dir/AGENTS.md"
printf '# guide\n' > "$_project_dir/CLAUDE.md"
printf '# Current Version: 1.0.0\n' > "$_project_dir/PRD.md"
printf '# demo\n' > "$_project_dir/README.md"
git -C "$_project_dir" add AGENTS.md CLAUDE.md PRD.md README.md
git -C "$_project_dir" -c user.name='codesop' -c user.email='codesop@example.com' commit -qm "baseline"
printf 'console.log(1)\n' > "$_project_dir/app.js"
result="$(PROJECT_ROOT="$_project_dir" check_project_document_drift)" || true
printf '%s' "$result" | grep -q "当前项目可能存在文档漂移" || fail "should warn when code changes exist without doc updates"
rm -rf "$_project_dir"

echo "  PASS"

# --- Test 9: check_project_document_drift sees doc updates ---
echo "Test 9: check_project_document_drift sees doc updates"

_project_dir="$(mktemp -d)"
git -C "$_project_dir" init -q
printf '@CLAUDE.md\n' > "$_project_dir/AGENTS.md"
printf '# guide\n' > "$_project_dir/CLAUDE.md"
printf '# Current Version: 1.0.0\n' > "$_project_dir/PRD.md"
printf '# demo\n' > "$_project_dir/README.md"
git -C "$_project_dir" add AGENTS.md CLAUDE.md PRD.md README.md
git -C "$_project_dir" -c user.name='codesop' -c user.email='codesop@example.com' commit -qm "baseline"
printf 'notes\n' >> "$_project_dir/README.md"
result="$(PROJECT_ROOT="$_project_dir" check_project_document_drift)" || true
printf '%s' "$result" | grep -q "当前修改已包含文档更新" || fail "should recognize doc updates"
rm -rf "$_project_dir"

echo "  PASS"

# --- Test 10: Document consistency arrays are populated ---
echo "Test 10: Document consistency arrays are populated"

[ ${#STALE_TERMS[@]} -gt 0 ] || fail "STALE_TERMS is empty"
[ ${#DOC_SCAN_TARGETS[@]} -gt 0 ] || fail "DOC_SCAN_TARGETS is empty"
[ ${#README_SKILL_ALIASES[@]} -gt 0 ] || fail "README_SKILL_ALIASES is empty"

echo "  PASS (${#STALE_TERMS[@]} stale terms, ${#DOC_SCAN_TARGETS[@]} scan targets, ${#README_SKILL_ALIASES[@]} aliases)"

echo ""
echo "PASS"
