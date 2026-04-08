#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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

assert_not_contains() {
  local haystack="$1"
  local needle="$2"

  if [[ "$haystack" == *"$needle"* ]]; then
    fail "expected output to not contain: $needle"
  fi
}

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
assert_contains "$skill_full" "**长期目标**:"
assert_contains "$skill_full" "**当前阶段**:"
assert_contains "$skill_full" "**文档状态**:"
assert_contains "$skill_full" "## 下一步建议"
assert_contains "$skill_full" "4. **末行**"
assert_contains "$skill_full" "Perform a quick document drift scan"
assert_contains "$skill_full" "Use this scan to decide whether doc updates belong in the next workflow chain"
assert_contains "$skill_full" "check_project_document_drift"
assert_contains "$skill_full" "The final line may mention 1 to 3 skills in sequence"
assert_contains "$skill_full" "Use natural language; slash commands are optional, not required"
assert_contains "$skill_full" "When git status is dirty and the user did not explicitly say to ignore it, prefer a cleanup-first workflow"
assert_not_contains "$skill_full" "**当前分支**: ... **阻塞/风险**: ... **最近决策**: ... **下一步**: ..."
assert_not_contains "$skill_full" "文档一致性：（粘贴 check_document_consistency 输出）"
assert_contains "$skill_output" "Generate AGENTS.md"
assert_contains "$skill_output" '`/codesop init [path]`'
assert_contains "$skill_output" '`/codesop update`'
assert_contains "$skill_full" "## 5. Completion Gate"
assert_contains "$skill_full" "## 文档判定"
assert_contains "$skill_full" "- CLAUDE.md: 已更新 / 未更新，原因：..."
assert_contains "$skill_full" "Case A — Dirty worktree"
assert_contains "$skill_full" "Case B — Clean worktree"
assert_contains "$skill_full" "先用 finishing-a-development-branch 处理当前未提交改动；如果这次改动影响 PRD.md/README.md"
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
assert_contains "$readme_output" "当前项目"

version_value="$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")"
skill_version="$(sed -n 's/.*"version": "\(.*\)".*/\1/p' "$ROOT_DIR/skill.json" | head -1)"
prd_version="$(sed -n 's/^# Current Version: //p' "$ROOT_DIR/PRD.md" | head -1)"
changelog_head="$(sed -n '1,10p' "$ROOT_DIR/CHANGELOG.md")"

[ "$skill_version" = "$version_value" ] || fail "expected skill.json version to match VERSION"
[ "$prd_version" = "$version_value" ] || fail "expected PRD.md version to match VERSION"
if [[ "$changelog_head" != *"## [Unreleased]"* ]] && [[ "$changelog_head" != *"## [$version_value]"* ]]; then
  fail "expected CHANGELOG.md head to be Unreleased or current VERSION heading"
fi

echo "PASS"
