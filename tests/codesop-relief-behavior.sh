#!/bin/bash
#
# v4.9 codesop 减负行为测试（spec 2026-07-05-v4.9-relief-design）
#
# 集中断言：simple 出口（1.1/1.2）+ 术语锚补全（2.1：外部锚点 AND / diff 守护 / pre-/goal）
# + spec-gate 禁止降级 + 自动 dispatch（4.1/4.2）+ dogfood 文本契约（2.3）
#
# 文本锚定（grep），真 dispatch/serve 实测在 plan/实施阶段补（同 first-principles-behavior 模式）：
# 不做真实 dispatch（非确定性、慢、依赖运行时）；行为契约由文本锚定。

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$(dirname "$0")/test_helpers.sh"

SKILL="$ROOT_DIR/SKILL.md"
ROUTER="$ROOT_DIR/config/codesop-router.md"
PATCHES="$ROOT_DIR/patches/superpowers"
SCHEMA="$PATCHES/_evidence-pack-schema.md"
VERIF="$PATCHES/verification-before-completion-SKILL.md"
BS="$PATCHES/brainstorming-SKILL.md"

[ -f "$SKILL" ] || fail "SKILL missing"
[ -f "$ROUTER" ] || fail "router missing"
[ -f "$BS" ] || fail "brainstorming patch missing"
[ -f "$SCHEMA" ] || fail "schema missing"
[ -f "$VERIF" ] || fail "verification patch missing"

assert_in_file() {
  local file="$1" needle="$2" label="$3"
  grep -Fq "$needle" "$file" || fail "$label: $file missing: $needle"
}

echo "=== 1.2 simple 跳 codex（1.1 落地）==="
assert_in_file "$BS"     "simple 可跳 codex"        "simple skip codex (brainstorming)"
assert_in_file "$ROUTER" "simple 可跳 codex"        "simple skip codex (router)"
assert_in_file "$SCHEMA" "simple 可跳 codex"        "simple skip codex (schema §4 ①)"
assert_in_file "$BS"     "high-risk override 仍必走" "override still enforced (high-risk)"
echo "  PASS simple 跳 codex + override 仍必走"

echo ""
echo "=== 2.1 术语锚补全（外部锚点 / diff 守护 / pre-/goal）==="
assert_in_file "$SKILL" "外部锚点"                    "外部锚点 anchor (SKILL)"
assert_in_file "$VERIF" "diff 守护"                    "diff 守护 anchor (verification)"
assert_in_file "$SKILL" "pre-/goal preparation segment" "pre-/goal segment anchor (SKILL)"
echo "  PASS 术语锚补全（3 个原缺）"

echo ""
echo "=== 4.1/4.2 spec-gate 禁止降级 + 自动 dispatch ==="
assert_in_file "$SKILL" "禁止降级"              "4.1 禁止降级 (SKILL §8.7 B)"
assert_in_file "$SKILL" "自动 dispatch spec-gate" "4.2 自动 dispatch (SKILL)"
assert_in_file "$BS"    "自动 dispatch spec-gate" "4.2 自动 dispatch (brainstorming terminal)"
echo "  PASS spec-gate 禁止降级 + 自动 dispatch"

echo ""
echo "=== 2.3 dogfood 文本契约（spec-gate 流程：dispatch + serve + ready/approved）==="
assert_in_file "$SKILL" "dispatch 全新独立 subagent" "dispatch subagent"
assert_in_file "$SKILL" "serve"                       "serve"
assert_in_file "$SKILL" "ready / approved 拆分"        "ready/approved 状态机"
echo "  PASS dogfood 文本契约（真 dispatch/serve 实测待 plan 阶段补）"

echo ""
echo "=== 5.7 SessionStart hook opt-out ==="
assert_in_file "$ROUTER" "可忽略"                       "router 可忽略声明"
grep -Fq "codesop-router-disabled" "$ROOT_DIR/setup" || fail "5.7 setup opt-out missing"
echo "  PASS SessionStart hook opt-out"

echo ""
echo "All v4.9 relief behavior tests passed."
