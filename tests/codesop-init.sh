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

output="$(HOME="$empty_home" bash "$CLI" init "$project_dir")"

assert_contains "$output" "项目识别："
assert_contains "$output" "主语言：TypeScript/JavaScript"
assert_contains "$output" "项目形态：Web App"
assert_contains "$output" "框架：Next.js"
assert_contains "$output" "环境识别："
assert_contains "$output" "Claude Code：未检测到"
assert_contains "$output" "Codex：未检测到"
assert_contains "$output" "OpenCode/OpenClaw：未检测到"
assert_contains "$output" "superpowers：未安装"
assert_contains "$output" "gstack：未安装"
assert_contains "$output" "配置计划："
assert_contains "$output" "默认生成语言：中文"
assert_contains "$output" "建议生成：项目级 AGENTS.md 或 CLAUDE.md"
assert_contains "$output" "已生成文件："
assert_contains "$output" "AGENTS.md"
assert_contains "$output" "CLAUDE.md"
assert_contains "$output" "PRD.md"
assert_contains "$output" "建议安装命令："
assert_contains "$output" "superpowers：先安装 Claude Code、Codex 或 OpenCode/OpenClaw 之后再按对应宿主安装"
assert_contains "$output" "gstack：git clone https://github.com/garrytan/gstack.git ~/gstack && cd ~/gstack && ./setup --host auto"
assert_contains "$output" "确认后再安装"
assert_contains "$output" "下一步："
assert_contains "$output" "如果你确认，我可以直接按上面的命令继续执行"

[ -f "$project_dir/AGENTS.md" ] || fail "expected AGENTS.md to be generated"
[ -f "$project_dir/CLAUDE.md" ] || fail "expected CLAUDE.md to be generated"
[ -f "$project_dir/PRD.md" ] || fail "expected PRD.md to be generated"

agents_content="$(sed -n '1,260p' "$project_dir/AGENTS.md")"
assert_contains "$agents_content" "项目级 AI 执行契约"
assert_contains "$agents_content" "## 1. 指令优先级"
assert_contains "$agents_content" "## 2. 架构边界（Pragmatic Clean）"
assert_contains "$agents_content" "## 5. 自动文档同步规则（强制）"
assert_contains "$agents_content" "npm test"
assert_contains "$agents_content" "npm run lint"
assert_contains "$agents_content" "npm run typecheck"
assert_contains "$agents_content" "npm run dev"
assert_contains "$agents_content" "项目名称：project"
assert_contains "$agents_content" "建议技术栈：TypeScript/JavaScript / Next.js"

claude_content="$(sed -n '1,80p' "$project_dir/CLAUDE.md")"
assert_contains "$claude_content" "@AGENTS.md"
assert_contains "$claude_content" "AGENTS.md is the source of truth"

prd_content="$(sed -n '1,260p' "$project_dir/PRD.md")"
assert_contains "$prd_content" "# Product:"
assert_contains "$prd_content" "# Current Version: 1.0.0"
assert_contains "$prd_content" "## 0. 使用说明"
assert_contains "$prd_content" "## 1. 当前快照"
assert_contains "$prd_content" "## 2. 当前进度"
assert_contains "$prd_content" "## 3. 最近决策记录"
assert_contains "$prd_content" "## 4. 版本历史"
assert_contains "$prd_content" "## 5. 产品核心规范"
assert_contains "$prd_content" "## 6. 当前风险与假设"
assert_contains "$prd_content" "## 7. 工作日志"
assert_contains "$prd_content" "**当前阶段**: discovery | planning | implementation | testing | review | release | maintenance"
assert_contains "$prd_content" "**下一步**: [最明确的一步动作]"
assert_contains "$prd_content" "**后续**: [下一步是什么]"
assert_contains "$prd_content" "技术栈: TypeScript/JavaScript / Next.js"

assert_contains "$agents_content" "- 项目阶段变化"
assert_contains "$agents_content" "- 出现阻塞或阻塞解除"
assert_contains "$agents_content" "- 更新 PRD 的稳定区：产品核心规范、里程碑、验收标准、架构/实体/用例"
assert_contains "$agents_content" "- 更新 PRD 的流动区：当前快照、当前进度、最近决策记录、风险与假设、工作日志"
assert_contains "$agents_content" "- 纯重构且不改变行为"
assert_contains "$agents_content" "- 测试或注释微调"

codex_home="$tmpdir/home-codex"
mkdir -p "$codex_home/.codex"

codex_output="$(HOME="$codex_home" bash "$CLI" init "$project_dir")"
assert_contains "$codex_output" "Codex：已检测到"
assert_contains "$codex_output" "superpowers：在 Codex 中执行：Fetch and follow instructions from https://raw.githubusercontent.com/obra/superpowers/refs/heads/main/.codex/INSTALL.md"
assert_contains "$codex_output" "gstack：git clone https://github.com/garrytan/gstack.git ~/gstack && cd ~/gstack && ./setup --host codex"
assert_contains "$codex_output" "如果你确认，我可以直接按上面的命令继续执行"

claude_home="$tmpdir/home-claude"
mkdir -p "$claude_home/.claude"

claude_output="$(HOME="$claude_home" bash "$CLI" init "$project_dir")"
assert_contains "$claude_output" "Claude Code：已检测到"
assert_contains "$claude_output" "superpowers：在 Claude Code 中执行：/plugin install superpowers@claude-plugins-official"
assert_contains "$claude_output" "gstack：git clone https://github.com/garrytan/gstack.git ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup"
assert_contains "$claude_output" "如果你确认，我可以直接按上面的命令继续执行"

installed_home="$tmpdir/home-installed"
mkdir -p "$installed_home/.claude/plugins/superpowers" "$installed_home/.claude/skills/gstack" "$installed_home/.claude"

installed_output="$(HOME="$installed_home" bash "$CLI" init "$project_dir")"
assert_contains "$installed_output" "superpowers：已安装"
assert_contains "$installed_output" "gstack：已安装"
assert_contains "$installed_output" "配置计划："
assert_contains "$installed_output" "更新建议："
assert_contains "$installed_output" "下一步："
assert_contains "$installed_output" "/plugin update superpowers"
assert_contains "$installed_output" "/gstack-upgrade"
assert_contains "$installed_output" "如果你确认，我可以继续执行对应更新步骤"

existing_dir="$tmpdir/project-existing"
mkdir -p "$existing_dir"
cat >"$existing_dir/package.json" <<'EOF'
{
  "name": "existing-web",
  "dependencies": {
    "next": "15.0.0"
  }
}
EOF
cat >"$existing_dir/AGENTS.md" <<'EOF'
# Existing Project Rules

## 1. 指令优先级
1. 用户当前指令
2. AGENTS.md
EOF

existing_output="$(HOME="$empty_home" bash "$CLI" init "$existing_dir")"
assert_contains "$existing_output" "已保留现有文件："
assert_contains "$existing_output" "AGENTS.md"
assert_contains "$existing_output" "AGENTS.md 合并优化建议："
assert_contains "$existing_output" "--- current/AGENTS.md"
assert_contains "$existing_output" "+++ suggested/AGENTS.md"
assert_contains "$existing_output" "+## 5. 自动文档同步规则（强制）"
assert_contains "$existing_output" "+## 6. 交付前验证"
assert_contains "$existing_output" "+## 7. 最终输出格式"

python_dir="$tmpdir/python-project"
mkdir -p "$python_dir"
cat >"$python_dir/pyproject.toml" <<'EOF'
[project]
name = "python-service"
dependencies = ["fastapi>=0.115.0"]
EOF

python_output="$(HOME="$empty_home" bash "$CLI" init "$python_dir")"
[ -f "$python_dir/AGENTS.md" ] || fail "expected python AGENTS.md to be generated"
python_agents="$(sed -n '1,260p' "$python_dir/AGENTS.md")"
assert_contains "$python_agents" "pytest"
assert_contains "$python_agents" "ruff check ."
assert_contains "$python_agents" "mypy ."
assert_contains "$python_agents" "uv run"
assert_contains "$python_agents" "建议技术栈：Python / FastAPI"

echo "PASS"
