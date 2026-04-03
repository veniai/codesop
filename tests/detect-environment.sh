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

skill_output="$(sed -n '/^## 8\. Sub-commands/,/^## 9\./p' "$ROOT_DIR/SKILL.md")"
skill_header="$(sed -n '1,120p' "$ROOT_DIR/SKILL.md")"
skill_full="$(cat "$ROOT_DIR/SKILL.md")"
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
assert_contains "$skill_header" 'Do not trigger when the user is explicitly invoking a mechanical subcommand'
assert_contains "$skill_header" "## 工作台摘要"
assert_contains "$skill_header" "**长期目标**:"
assert_contains "$skill_header" "**当前阶段**:"
assert_contains "$skill_header" "## Skill 建议"
assert_contains "$skill_output" "Generate AGENTS.md"
assert_contains "$skill_output" '`/codesop init [path]`'
assert_contains "$skill_output" '`/codesop update`'
assert_contains "$skill_full" "## 5. Completion Gate"
assert_contains "$skill_full" "## 文档判定"
assert_contains "$skill_full" "- CLAUDE.md: 已更新 / 未更新，原因：..."
assert_contains "$skill_output" "Defaults to 中文"

readme_output="$(sed -n '1,260p' "$ROOT_DIR/README.md")"
assert_contains "$readme_output" "superpowers"
assert_contains "$readme_output" 'AGENTS.md'
assert_contains "$readme_output" 'PRD.md'
assert_contains "$readme_output" 'CLAUDE.md'
assert_contains "$readme_output" "codesop update"
assert_contains "$readme_output" "/codesop init"
assert_contains "$readme_output" '`VERSION` 是发布版本的唯一真相源'

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
