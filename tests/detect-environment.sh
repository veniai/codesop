#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DETECTOR="$ROOT_DIR/scripts/detect-environment.sh"

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

make_project() {
  local project_dir="$1"
  local project_kind="$2"

  mkdir -p "$project_dir"

  case "$project_kind" in
    nextjs)
      cat >"$project_dir/package.json" <<'EOF'
{
  "name": "web-app",
  "dependencies": {
    "next": "15.0.0",
    "react": "19.0.0"
  }
}
EOF
      ;;
    fastapi)
      cat >"$project_dir/pyproject.toml" <<'EOF'
[project]
name = "api-service"
dependencies = ["fastapi>=0.115.0"]
EOF
      ;;
    monorepo)
      mkdir -p "$project_dir/packages/app"
      cat >"$project_dir/package.json" <<'EOF'
{
  "name": "workspace-root",
  "workspaces": ["packages/*"]
}
EOF
      ;;
    *)
      fail "unknown fixture kind: $project_kind"
      ;;
  esac
}

run_detector() {
  local project_dir="$1"
  bash "$DETECTOR" "$project_dir"
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

next_dir="$tmpdir/next-project"
make_project "$next_dir" nextjs
next_output="$(run_detector "$next_dir")"
assert_contains "$next_output" "project.language=TypeScript/JavaScript"
assert_contains "$next_output" "project.shape=Web App"
assert_contains "$next_output" "project.framework=Next.js"
assert_contains "$next_output" "output.language=zh-CN"

fastapi_dir="$tmpdir/fastapi-project"
make_project "$fastapi_dir" fastapi
fastapi_output="$(run_detector "$fastapi_dir")"
assert_contains "$fastapi_output" "project.language=Python"
assert_contains "$fastapi_output" "project.shape=Backend Service"
assert_contains "$fastapi_output" "project.framework=FastAPI"

monorepo_dir="$tmpdir/monorepo-project"
make_project "$monorepo_dir" monorepo
monorepo_output="$(run_detector "$monorepo_dir")"
assert_contains "$monorepo_output" "project.shape=Monorepo"

skill_output="$(sed -n '/^### 8\.1 \/codesop init \[path\]/,/^### 8\.2 /p' "$ROOT_DIR/SKILL.md")"
skill_header="$(sed -n '1,120p' "$ROOT_DIR/SKILL.md")"
assert_contains "$skill_header" "skill-first operating system for AI-assisted coding work"
assert_contains "$skill_header" "The skill is the orchestrator. The CLI is infrastructure."
assert_contains "$skill_header" "Read project context in this order:"
assert_contains "$skill_header" '1. `AGENTS.md`'
assert_contains "$skill_header" '2. `PRD.md`'
assert_contains "$skill_header" '3. `README.md` only if needed'
assert_contains "$skill_header" 'The `/codesop` CLI is an optional but preferred mechanical context source.'
assert_contains "$skill_header" 'Call `/codesop` when you need fresh project-state facts from the repo.'
assert_contains "$skill_header" 'Do not call `/codesop` for abstract workflow questions that do not depend on repo state.'
assert_contains "$skill_header" 'Use `PRD.md` for long-term orientation and `/codesop` for fresh mechanical facts.'
assert_contains "$skill_header" "## 1.1 CLI Command Bypass"
assert_contains "$skill_header" 'Do not trigger this skill when the user is explicitly invoking a mechanical subcommand like `/codesop init`'
assert_contains "$skill_header" "## 工作台摘要"
assert_contains "$skill_header" "**长期目标**:"
assert_contains "$skill_header" "**当前阶段**:"
assert_contains "$skill_header" "## Skill 建议"
assert_contains "$skill_output" "Initialize project scaffolding and environment guidance."
assert_contains "$skill_output" "This is a mechanical command, not a workbench-summary command."
assert_contains "$skill_output" '`AGENTS.md` — 填充技术栈、命令、架构规则'
assert_contains "$skill_output" '`CLAUDE.md` — 轻量包装：`@AGENTS.md`'
assert_contains "$skill_output" '`PRD.md` — 活文档：同时记录产品规范、当前进度、最近决策、风险与工作日志'
assert_contains "$skill_output" '`AGENTS.md` 已存在 → 保留，输出 diff 建议。'
assert_contains "$skill_output" "do not add a separate project scorecard"
assert_contains "$skill_output" "do not add workbench routing unless the user explicitly asks for next-step advice"

readme_output="$(sed -n '1,260p' "$ROOT_DIR/README.md")"
assert_contains "$readme_output" "默认中文"
assert_contains "$readme_output" "superpowers"
assert_contains "$readme_output" "gstack"
assert_contains "$readme_output" "更新命令"
assert_contains "$readme_output" '生成完整 `AGENTS.md`、导入型 `CLAUDE.md`、活文档 `PRD.md`'
assert_contains "$readme_output" '如果已有 `AGENTS.md`，保留原文件，并输出终端合并优化建议'
assert_contains "$readme_output" "自动推断测试、lint、类型检查、smoke 命令并写入模板"
assert_contains "$readme_output" '`AGENTS.md` 定义 AI 工作边界'
assert_contains "$readme_output" '`PRD.md` 同时承担产品规范和当前工作记录'

quickstart_output="$(sed -n '1,260p' "$ROOT_DIR/QUICKSTART.md")"
assert_contains "$quickstart_output" "/codesop init"
assert_contains "$quickstart_output" "默认中文"
assert_contains "$quickstart_output" "确认后由当前大模型继续执行"
assert_contains "$quickstart_output" "更新命令"
assert_contains "$quickstart_output" '生成完整 `AGENTS.md`、导入型 `CLAUDE.md`、活文档 `PRD.md`'
assert_contains "$quickstart_output" '如果已有 `AGENTS.md`，保留原文件，并输出终端合并优化建议'
assert_contains "$quickstart_output" "自动推断测试、lint、类型检查、smoke 命令并写入模板"
assert_contains "$quickstart_output" '`PRD.md` 负责记录长期目标、当前进度、最近决策和工作日志'

echo "PASS"
