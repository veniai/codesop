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

# --- Test 1: scan_routed_skills extracts from real SKILL.md ---
echo "Test 1: scan_routed_skills against real SKILL.md"

routed="$(scan_routed_skills)" || fail "scan_routed_skills failed on real SKILL.md"
[ -n "$routed" ] || fail "scan_routed_skills returned empty for real SKILL.md"

# Spot-check known skills that must be routed
assert_contains "$routed" "office-hours"
assert_contains "$routed" "writing-plans"
assert_contains "$routed" "subagent-driven-development"
assert_contains "$routed" "systematic-debugging"
assert_contains "$routed" "investigate"
assert_contains "$routed" "review"
assert_contains "$routed" "ship"
assert_contains "$routed" "verification-before-completion"

# Verify normalization: abbreviations should NOT appear
assert_not_contains "$routed" "subagent-driven-dev"
assert_not_contains "$routed" "verification-before-comp"
assert_not_contains "$routed" "TDD"

# Verify test-driven-development is the normalized name
assert_contains "$routed" "test-driven-development"

echo "  PASS"

# --- Test 2: scan_routed_skills with a minimal fake SKILL.md ---
echo "Test 2: scan_routed_skills with minimal fake SKILL.md"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

cat > "$tmpdir/SKILL.md" <<'SKILLEOF'
## 6. Workflow Mapping

### 6.1 New Feature
office-hours (gstack)
writing-plans (superpowers)
TDD (sp)
subagent-driven-dev (sp)
verification-before-comp (sp)

### 6.2 Bug Fix
investigate (gstack)
systematic-debugging (superpowers)

## 7. Routing Policy
SKILLEOF

# Override ROOT_DIR temporarily
_orig_root="$ROOT_DIR"
ROOT_DIR="$tmpdir"

routed="$(scan_routed_skills)" || fail "scan_routed_skills failed on fake SKILL.md"

ROOT_DIR="$_orig_root"

assert_contains "$routed" "office-hours"
assert_contains "$routed" "writing-plans"
assert_contains "$routed" "test-driven-development"
assert_contains "$routed" "subagent-driven-development"
assert_contains "$routed" "verification-before-completion"
assert_contains "$routed" "investigate"
assert_contains "$routed" "systematic-debugging"

# Abbreviations must be normalized away
assert_not_contains "$routed" "TDD"
assert_not_contains "$routed" "subagent-driven-dev"
assert_not_contains "$routed" "verification-before-comp"

# Should extract exactly 7 unique skills
# Use grep -c to count non-empty lines (command substitution strips trailing newline)
count="$(printf '%s\n' "$routed" | grep -c .)"
[ "$count" = "7" ] || fail "expected 7 unique skills, got $count"

echo "  PASS"

# --- Test 3: scan_routed_skills handles missing section gracefully ---
echo "Test 3: scan_routed_skills with missing section 6"

cat > "$tmpdir/SKILL.md" <<'SKILLEOF'
# No workflow mapping here
## 5. Something Else
## 7. Routing Policy
SKILLEOF

ROOT_DIR="$tmpdir"
routed="$(scan_routed_skills)" || fail "scan_routed_skills failed on empty section"
ROOT_DIR="$_orig_root"

[ -z "$routed" ] || fail "expected empty output when section 6 is missing, got: $routed"

echo "  PASS"

# --- Test 4: check_skill_routing_coverage handles no installed skills ---
echo "Test 4: check_skill_routing_coverage with no installed skills"

# scan_installed_skills returns nothing when dirs don't exist
result="$(check_skill_routing_coverage)" || fail "expected exit 0 when no skills installed"
[ "$result" = "路由覆盖：所有已安装 skill 均已收录" ] || fail "unexpected output: $result"

echo "  PASS"

echo "PASS"
