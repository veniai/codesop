#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/collect-signals.sh"

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

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

cd "$tmpdir"
git init -q
echo "test" > file.txt
git add . && git commit -q -m "init"

expected_branch="$(git branch --show-current)"
signals="$(collect_signals "$tmpdir")"

assert_contains "$signals" "GIT_BRANCH=$expected_branch"
assert_contains "$signals" "GIT_UNTRACKED=0"
assert_contains "$signals" "GIT_UNCOMMITTED=0"
assert_contains "$signals" "CONFIG_CLAUDE_MD=false"
assert_contains "$signals" "CONFIG_PRD_MD=false"
assert_contains "$signals" "HAS_PACKAGE_JSON=false"

echo "PASS"
