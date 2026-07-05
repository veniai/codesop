#!/bin/bash
#
# spec-gate 可视化行为测试（SKILL §8.7 B + schema §8）—— v4.6 核心
#
# v4.6 spec-gate 可视化重构：dispatch 独立 subagent（交叉检验）+ spec 实质呈现为主
# + evidence pack 为辅 + ready/approved 拆分（URL=ready，人点通过=approved）。本测试防这些核心被改坏。
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

echo "=== §8.7 B: ready/approved 拆分（URL=ready，人点通过=approved）==="
assert_in_file "$SKILL" "ready / approved 拆分" "ready/approved 拆分 declared"
assert_in_file "$SKILL" "task completed **只认 approved**" "completed 只认 approved（不被 ready 绕过）"
assert_in_file "$SKILL" "没 serve → 没 URL → 没 ready → 不触发人审" "没 serve = 没 ready = task 未完成"
echo "  PASS ready/approved 拆分"

echo "=== schema §8: spec 实质为主 ==="
assert_in_file "$SCHEMA" "spec 实质为主" "schema §8 spec 实质为主"
assert_in_file "$SCHEMA" "spec-gate 可视化" "schema §8 spec-gate 可视化"
echo "  PASS schema §8 spec 实质为主"

echo "=== schema §8: Layer 1 白话摘要（4 块，不提术语）==="
assert_in_file "$SCHEMA" "要解决的问题" "Layer 1 块1 要解决的问题"
assert_in_file "$SCHEMA" "实际会改变什么" "Layer 1 块2 实际会改变什么"
assert_in_file "$SCHEMA" "为什么这样改" "Layer 1 块3 为什么这样改"
assert_in_file "$SCHEMA" "明确不改变什么" "Layer 1 块4 明确不改变什么"
echo "  PASS Layer 1 白话四块"

echo "=== schema §8b: deliver-gate 可视化（复用两层，交付证据）==="
assert_in_file "$SCHEMA" "deliver-gate 可视化" "schema §8b deliver-gate 可视化"
assert_in_file "$SCHEMA" "交付证据" "schema §8b Layer 2 交付证据"
assert_in_file "$SKILL" "schema §8b" "SKILL §8.7 D 引用 schema §8b"
echo "  PASS deliver-gate 可视化"

echo ""
echo "All spec-gate visualize behavior tests passed (§8.7 B dispatch + spec 实质 + ready/approved + Layer 1 + §8b)."
