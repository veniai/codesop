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

skill_output="$(sed -n '/^### 2\.1 \/codesop init \[path\]/,/^### 2\.2 /p' "$ROOT_DIR/SKILL.md")"
assert_contains "$skill_output" "默认中文"
assert_contains "$skill_output" "检测当前机器上的 Claude Code、Codex、OpenCode/OpenClaw"
assert_contains "$skill_output" "先按当前宿主工具给安装命令和说明，等用户确认后，由当前大模型继续执行"
assert_contains "$skill_output" "update suggestions when ecosystems are already installed"
assert_contains "$skill_output" '<project>/AGENTS.md` as the full project instruction file'
assert_contains "$skill_output" '<project>/CLAUDE.md` as a lightweight wrapper that imports `@AGENTS.md`'
assert_contains "$skill_output" 'If `<project>/AGENTS.md` already exists, keep it and print a diff-like merge suggestion'

readme_output="$(sed -n '1,260p' "$ROOT_DIR/README.md")"
assert_contains "$readme_output" "默认中文"
assert_contains "$readme_output" "superpowers"
assert_contains "$readme_output" "gstack"
assert_contains "$readme_output" "更新命令"
assert_contains "$readme_output" '生成完整 `AGENTS.md`、导入型 `CLAUDE.md`、独立 `PRD.md`'
assert_contains "$readme_output" '如果已有 `AGENTS.md`，保留原文件，并输出终端合并优化建议'
assert_contains "$readme_output" "自动推断测试、lint、类型检查、smoke 命令并写入模板"

quickstart_output="$(sed -n '1,260p' "$ROOT_DIR/QUICKSTART.md")"
assert_contains "$quickstart_output" "/codesop init"
assert_contains "$quickstart_output" "默认中文"
assert_contains "$quickstart_output" "确认后由当前大模型继续执行"
assert_contains "$quickstart_output" "更新命令"
assert_contains "$quickstart_output" '生成完整 `AGENTS.md`、导入型 `CLAUDE.md`、独立 `PRD.md`'
assert_contains "$quickstart_output" '如果已有 `AGENTS.md`，保留原文件，并输出终端合并优化建议'
assert_contains "$quickstart_output" "自动推断测试、lint、类型检查、smoke 命令并写入模板"

echo "PASS"
