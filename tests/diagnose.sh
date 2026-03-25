#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/diagnose.sh"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"

  if [[ "$haystack" != *"$needle"* ]]; then
    fail "expected output to contain: $needle"
  fi
}

signals="GIT_BRANCH=feature/test
GIT_UNTRACKED=2
GIT_UNCOMMITTED=3
CONFIG_CLAUDE_MD=true
CONFIG_AGENTS_MD=true
CONFIG_PRD_MD=false
CONFIG_PLAN_MD=false
HAS_PACKAGE_JSON=true"

result="$(diagnose_project "$signals")"

assert_contains "$result" "CURRENT_STAGE=feature"
assert_contains "$result" "STAGE_CONFIDENCE=medium"
assert_contains "$result" "HEALTH_ISSUES=MISSING_PRD,MISSING_PLAN"

echo "PASS"
