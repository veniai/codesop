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
source "$ROOT_DIR/lib/output.sh"
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

[ ${#CORE_PLUGINS[@]} -gt 0 ] || fail "CORE_PLUGINS is empty"
[ ${#OPTIONAL_PLUGINS[@]} -gt 0 ] || fail "OPTIONAL_PLUGINS is empty"
[ ${#OPTIONAL_SKILLS[@]} -gt 0 ] || fail "OPTIONAL_SKILLS is empty"

echo "  PASS (${#CORE_PLUGINS[@]} core, ${#OPTIONAL_PLUGINS[@]} optional, ${#OPTIONAL_SKILLS[@]} skills)"

echo ""
echo "PASS"
