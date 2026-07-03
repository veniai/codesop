#!/bin/bash
#
# spec-gate 可视化行为测试（SKILL §8.7 B + schema §8）—— v4.6 核心
#
# v4.6 spec-gate 可视化重构：dispatch 独立 subagent（交叉检验）+ spec 实质呈现为主
# + evidence pack 为辅 + completed 认 serve URL（外部锚点）。本测试防这些核心被改坏。
#

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$(dirname "$0")/test_helpers.sh"

SKILL="$ROOT_DIR/SKILL.md"
SCHEMA="$ROOT_DIR/patches/superpowers/_evidence-pack-schema.md"

[ -f "$SKILL" ] || fail "SKILL.md missing"
[ -f "$SCHEMA" ] || fail "schema missing"

assert_in_file() {
  local file="$1" needle="$2" label="$3"
  grep -Fq "$needle" "$file" || fail "$label: $file missing: $needle"
}

echo "=== §8.7 B: dispatch 独立 subagent（交叉检验）==="
assert_in_file "$SKILL" "dispatch 全新独立 subagent" "dispatch 独立 subagent"
assert_in_file "$SKILL" "独立于 brainstorming 阶段的 evidence-pack subagent" "独立于 brainstorming subagent"
echo "  PASS dispatch 独立 subagent"

echo "=== §8.7 B: spec 实质为主 + evidence pack 为辅 ==="
assert_in_file "$SKILL" "spec 实质呈现" "spec 实质呈现（主）"
assert_in_file "$SKILL" "功能去留地图" "功能去留地图"
assert_in_file "$SKILL" "改动跨层拓扑" "改动跨层拓扑"
assert_in_file "$SKILL" "rubric 五项" "evidence pack rubric（辅）"
echo "  PASS spec 实质为主 + evidence pack 为辅"

echo "=== §8.7 B: completed 认 serve URL（外部锚点）==="
assert_in_file "$SKILL" "completed 认 serve URL" "completed 认 serve URL"
assert_in_file "$SKILL" "没 serve → 没 URL → task 未完成" "没 serve = task 未完成"
echo "  PASS completed 认 serve URL"

echo "=== schema §8: spec 实质为主 ==="
assert_in_file "$SCHEMA" "spec 实质为主" "schema §8 spec 实质为主"
assert_in_file "$SCHEMA" "spec-gate 可视化" "schema §8 spec-gate 可视化"
echo "  PASS schema §8 spec 实质为主"

echo ""
echo "All spec-gate visualize behavior tests passed (§8.7 B dispatch + spec 实质 + serve URL)."
