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

project_dir="$tmpdir/project"
mkdir -p "$project_dir"
cat >"$project_dir/package.json" <<'EOF'
{
  "name": "demo-web",
  "dependencies": {
    "next": "15.0.0",
    "react": "19.0.0"
  }
}
EOF

empty_home="$tmpdir/home-empty"
mkdir -p "$empty_home"

if non_claude_output="$(HOME="$empty_home" bash "$CLI" init "$project_dir" 2>&1)"; then
  fail "expected init outside Claude Code environment to fail"
fi

assert_contains "$non_claude_output" "codesop init 需要 Claude Code 环境"
assert_contains "$non_claude_output" "claude"
assert_contains "$non_claude_output" "/codesop-init"

claude_home="$tmpdir/home-claude"
mkdir -p "$claude_home/.claude"

claude_output="$(HOME="$claude_home" bash "$CLI" init "$project_dir" 2>&1)"

assert_contains "$claude_output" "codesop 初始化面试流程"
assert_contains "$claude_output" "=== Phase 0: 工具检测与环境配置 ==="
assert_contains "$claude_output" "=== Phase 1: 用户偏好 ==="
assert_contains "$claude_output" "=== Phase 3: 项目级文件 ==="
assert_contains "$claude_output" "=== Phase 4: 技能检查 ==="
assert_contains "$claude_output" "✓ 创建 AGENTS.md"
assert_contains "$claude_output" "✓ 创建 PRD.md"
assert_contains "$claude_output" "✓ 创建 README.md"
assert_contains "$claude_output" "=== 技能依赖检查 ==="
assert_contains "$claude_output" "初始化完成"
assert_contains "$claude_output" "在 Claude Code 中运行 /init 生成 CLAUDE.md"
assert_contains "$claude_output" "运行 '/codesop' 进入工作台并选择下一步 workflow"

[ -f "$project_dir/AGENTS.md" ] || fail "expected AGENTS.md to be generated"
[ -f "$project_dir/PRD.md" ] || fail "expected PRD.md to be generated"
[ -f "$project_dir/README.md" ] || fail "expected README.md to be generated"
[ ! -f "$project_dir/CLAUDE.md" ] || fail "did not expect init to generate CLAUDE.md directly"
[ -L "$claude_home/.claude/CLAUDE.md" ] || fail "expected system CLAUDE.md symlink to be created"

agents_content="$(sed -n '1,40p' "$project_dir/AGENTS.md")"
assert_contains "$agents_content" "@CLAUDE.md"
[ "$agents_content" = "@CLAUDE.md" ] || fail "expected AGENTS.md to stay a thin wrapper"

prd_content="$(sed -n '1,120p' "$project_dir/PRD.md")"
assert_contains "$prd_content" "## 1. 当前快照"
assert_contains "$prd_content" "## 3. 最近决策记录"
assert_contains "$prd_content" "## 5. 产品核心规范"
assert_contains "$prd_content" "## 7. 工作日志"

readme_content="$(sed -n '1,120p' "$project_dir/README.md")"
assert_contains "$readme_content" "# project"
assert_contains "$readme_content" "## 快速开始"

echo "PASS"
