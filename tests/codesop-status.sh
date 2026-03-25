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

output="$(bash "$CLI" status 2>&1)"

assert_contains "$output" "## 项目状态（纯事实）"
assert_contains "$output" "版本信息"
assert_contains "$output" "Git 状态"

if [[ "$output" == *"建议"* ]] || [[ "$output" == *"推荐"* ]] || [[ "$output" == *"应该"* ]]; then
  fail "status output contains recommendation words"
fi

echo "PASS"
