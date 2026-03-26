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

home_dir="$tmpdir/home"
project_dir="$tmpdir/project"
mkdir -p "$home_dir/.local/bin" "$project_dir"

ln -s "$CLI" "$home_dir/.local/bin/codesop"

cat >"$project_dir/package.json" <<'EOF'
{
  "name": "demo-web",
  "dependencies": {
    "react": "19.0.0"
  }
}
EOF

output="$(HOME="$home_dir" bash "$home_dir/.local/bin/codesop" init "$project_dir")"

assert_contains "$output" "项目识别："
assert_contains "$output" "主语言：TypeScript/JavaScript"
assert_contains "$output" "配置计划："
assert_contains "$output" "已生成文件："

echo "PASS"
