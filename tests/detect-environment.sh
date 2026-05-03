#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$(dirname "$0")/test_helpers.sh"

skill_output="$(sed -n '/^## 8\. Sub-commands/,/^## 9\./p' "$ROOT_DIR/SKILL.md")"
skill_header="$(sed -n '1,120p' "$ROOT_DIR/SKILL.md")"
skill_full="$(cat "$ROOT_DIR/SKILL.md")"
assert_contains "$skill_header" "skill-first operating system for AI-assisted coding work"
assert_contains "$skill_header" "The skill is the orchestrator. The CLI is infrastructure."
assert_contains "$skill_header" "composes the next workflow chain"
assert_contains "$skill_header" "Read project context in this order:"
assert_contains "$skill_header" '1. `AGENTS.md`'
assert_contains "$skill_header" '2. `PRD.md`'
assert_contains "$skill_header" '3. `README.md` only if needed'
assert_contains "$skill_header" 'Never invoke `/codesop` from within this skill'
assert_contains "$skill_header" 'Use `PRD.md` for long-term orientation and direct git/file commands for mechanical facts.'
assert_contains "$skill_header" 'Do not trigger when the user is explicitly invoking a mechanical subcommand'
assert_not_contains "$skill_full" "recommends the next skill"
assert_contains "$skill_full" "## 工作台摘要"
assert_contains "$skill_full" "**状态**:"
assert_contains "$skill_full" "**分支**:"
assert_contains "$skill_full" "## 下一步建议"
assert_contains "$skill_full" "4. **末行**"
assert_contains "$skill_full" "Perform a quick document drift scan"
assert_contains "$skill_full" "Use this scan to decide whether doc updates belong in the next workflow chain"
assert_contains "$skill_full" "check_project_document_drift"
assert_contains "$skill_full" "末行必须是疑问句"
assert_contains "$skill_full" "场景适配"
assert_contains "$skill_full" "前置 superpowers:finishing-a-development-branch"
assert_not_contains "$skill_full" "**当前分支**: ... **阻塞/风险**: ... **最近决策**: ... **下一步**: ..."
assert_not_contains "$skill_full" "文档一致性：（粘贴 check_document_consistency 输出）"
assert_contains "$skill_output" "Generate AGENTS.md"
assert_contains "$skill_output" '`/codesop init [path]`'
assert_contains "$skill_output" '`/codesop update`'
assert_contains "$skill_full" "## 5. Completion Gate"
assert_contains "$skill_full" "## 文档判定"
assert_contains "$skill_full" "- CLAUDE.md: 已更新 / 未更新，原因：..."
assert_contains "$skill_full" "Complete Example"
assert_contains "$skill_full" "提议 Pipeline"
assert_contains "$skill_full" "工作区有未提交改动"
assert_contains "$skill_output" "Defaults to 中文"

readme_output="$(sed -n '1,260p' "$ROOT_DIR/README.md")"
assert_contains "$readme_output" "superpowers"
assert_contains "$readme_output" 'AGENTS.md'
assert_contains "$readme_output" 'PRD.md'
assert_contains "$readme_output" 'CLAUDE.md'
assert_contains "$readme_output" "codesop update"
assert_contains "$readme_output" "/codesop init"
assert_contains "$readme_output" '`VERSION` 是发布版本的唯一真相源'
assert_contains "$readme_output" "最后一行"
assert_contains "$readme_output" "自然语言工作流指令"
assert_contains "$readme_output" "文档漂移"
assert_contains "$readme_output" "活文档"

version_value="$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")"
skill_version="$(sed -n 's/.*"version": "\(.*\)".*/\1/p' "$ROOT_DIR/skill.json" | head -1)"
prd_version="$(sed -n 's/^# Current Version: //p' "$ROOT_DIR/PRD.md" | head -1)"
changelog_head="$(sed -n '1,10p' "$ROOT_DIR/CHANGELOG.md")"

[ "$skill_version" = "$version_value" ] || fail "expected skill.json version to match VERSION"
[ "$prd_version" = "$version_value" ] || fail "expected PRD.md version to match VERSION"
if [[ "$changelog_head" != *"## [Unreleased]"* ]] && [[ "$changelog_head" != *"## [$version_value]"* ]]; then
  fail "expected CHANGELOG.md head to be Unreleased or current VERSION heading"
fi

# Git health check tests
health_output="$(source "$ROOT_DIR/lib/detection.sh" && check_git_health 2>/dev/null)" || health_output=""

# Function should produce output
assert_contains "$health_output" "ORPHAN_COUNT="
assert_contains "$health_output" "CURRENT="
assert_contains "$health_output" "IS_LEFTOVER="
assert_contains "$health_output" "MAIN_BRANCH="

# SKILL.md should reference git health check
assert_contains "$skill_full" "check_git_health"
assert_contains "$skill_full" "Git 健康检查跳过"

echo "PASS"
