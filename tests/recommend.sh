#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/recommend.sh"

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

diagnosis="CURRENT_STAGE=feature
STAGE_CONFIDENCE=medium
HEALTH_ISSUES=MISSING_PRD"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
export HOME="$tmpdir"
mkdir -p "$HOME/.claude/skills/gstack/demo-skill"

cat >"$HOME/.claude/skills/gstack/demo-skill/SKILL.md" <<'EOF'
---
name: demo-skill
description: |
  Use when the user needs a demo workflow.
  Helps verify multiline description parsing.
---
EOF

result="$(recommend_skills "$diagnosis")"

assert_contains "$result" "可用技能"
assert_contains "$result" "推荐规则"
assert_contains "$result" "当前阶段: feature"
assert_contains "$result" "健康问题: MISSING_PRD"
assert_contains "$result" "3-5"

skill_count="$(echo "$result" | grep -c '^[A-Za-z0-9_-].*: ' || true)"
if [ "$skill_count" -lt 1 ]; then
  fail "no skills found in output"
fi

assert_contains "$result" "demo-skill: Use when the user needs a demo workflow. Helps verify multiline description parsing."

echo "PASS"
