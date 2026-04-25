#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$ROOT_DIR/codesop"

source "$(dirname "$0")/test_helpers.sh"

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

# --- Test: update command templates diff detection ---
echo "--- codesop update templates diff detection ---"

fake_repo="$tmpdir/codesop-repo"
mkdir -p "$fake_repo/templates/project"
(
  cd "$fake_repo"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"

  echo "old template" > templates/project/PRD.md
  echo "old readme" > templates/project/README.md
  git add -A
  git commit -qm "initial"

  echo "new template content" > templates/project/PRD.md
  git add -A
  git commit -qm "update templates"
  new_tmpl_hash="$(git rev-parse HEAD)"
  old_tmpl_hash="$(git log --format=%H --reverse | head -1)"

  # templates changed → diff should be non-empty
  if git diff --quiet "$old_tmpl_hash".."$new_tmpl_hash" -- templates/ 2>/dev/null; then
    echo "FAIL: expected templates diff to be non-empty after template change" >&2; exit 1
  fi

  # non-template change → diff should be empty
  echo "other change" > unrelated.txt
  git add -A
  git commit -qm "non-template change"
  mid_tmpl_hash="$(git rev-parse HEAD)"
  if git diff --quiet "$new_tmpl_hash".."$mid_tmpl_hash" -- templates/ 2>/dev/null; then
    :
  else
    echo "FAIL: expected templates diff to be empty when only non-template files changed" >&2; exit 1
  fi
)

# --- Test: init adapt mode signal in CLI output ---
echo "--- init adapt mode signal ---"

adapt_project="$tmpdir/adapt-project"
mkdir -p "$adapt_project"
echo "@CLAUDE.md" > "$adapt_project/AGENTS.md"
echo "## 当前快照" > "$adapt_project/PRD.md"
echo "# adapt-project" > "$adapt_project/README.md"
cat >"$adapt_project/package.json" <<'PKGEOF'
{
  "name": "adapt-web",
  "dependencies": { "next": "15.0.0" }
}
PKGEOF

adapt_output="$(HOME="$claude_home" bash "$CLI" init "$adapt_project" 2>&1)"

assert_contains "$adapt_output" "ADAPT_MODE:YES"
assert_contains "$adapt_output" "AGENTS.md 已是简单引用格式"
assert_contains "$adapt_output" "PRD.md 已是活文档格式"
assert_contains "$adapt_output" "README.md 已存在"

# Verify files were NOT overwritten in adapt mode
agents_check="$(cat "$adapt_project/AGENTS.md")"
[ "$agents_check" = "@CLAUDE.md" ] || fail "AGENTS.md should not be overwritten in adapt mode"

echo "PASS"
