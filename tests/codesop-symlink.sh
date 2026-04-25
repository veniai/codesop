#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$ROOT_DIR/codesop"

source "$(dirname "$0")/test_helpers.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

home_dir="$tmpdir/home"
project_dir="$tmpdir/project"
mkdir -p "$home_dir/.local/bin" "$home_dir/.claude" "$project_dir"

ln -s "$CLI" "$home_dir/.local/bin/codesop"

cat >"$project_dir/package.json" <<'EOF'
{
  "name": "demo-web",
  "dependencies": {
    "react": "19.0.0"
  }
}
EOF

output="$(HOME="$home_dir" bash "$home_dir/.local/bin/codesop" init "$project_dir" 2>&1)"

assert_contains "$output" "codesop 初始化面试流程"
assert_contains "$output" "✓ 创建 AGENTS.md"
assert_contains "$output" "✓ 创建 PRD.md"
assert_contains "$output" "✓ 创建 README.md"

[ -f "$project_dir/AGENTS.md" ] || fail "expected AGENTS.md to be generated via symlinked CLI"
[ -L "$home_dir/.claude/CLAUDE.md" ] || fail "expected system CLAUDE.md symlink to be created via symlinked CLI"

echo "PASS"
