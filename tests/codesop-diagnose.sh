#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$ROOT_DIR/codesop"

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
echo '{"name":"test"}' > package.json
git add . && git commit -q -m "init"

output="$(bash "$CLI" 2>&1)"

assert_contains "$output" "## 项目诊断"
assert_contains "$output" "**当前阶段**"
assert_contains "$output" "**置信度**"
assert_contains "$output" "**健康状态**"
assert_contains "$output" "## 技能推荐"
assert_contains "$output" "**可用技能**"

echo "PASS"
