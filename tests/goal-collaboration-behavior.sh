#!/bin/bash
#
# /goal 协同四步行为测试（SKILL §8.7）—— v4.0 spec-as-goal 范式核心
#
# v4.4 诊断 P1-4：/goal §8.7 协同四步（启动/每轮/退出/失败码）+ round-N.md 证据包
# + deliver-gate 衔接此前无文本锚定测试。本测试补这块——防 §8.7 机制被改坏而无测试报警。
# golden-content grep（同 spec-as-goal-behavior 模式），dispatch 实测降级 dogfood。
#

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$(dirname "$0")/test_helpers.sh"

SKILL="$ROOT_DIR/SKILL.md"

[ -f "$SKILL" ] || fail "SKILL.md missing"

assert_in_file() {
  local file="$1" needle="$2" label="$3"
  grep -Fq "$needle" "$file" || fail "$label: $file missing: $needle"
}

echo "=== §8.7 A: /goal 协同四步（spec-gate 通过 → deliver-gate）==="

assert_in_file "$SKILL" "### A. /goal 协同四步" "§8.7 协同四步 section 存在"
assert_in_file "$SKILL" "| **① 交接**" "① 交接（spec-gate approved→/goal handoff，AI 生成命令交用户手动发）"
assert_in_file "$SKILL" "| **② 每轮**" "② 每轮（dispatch 独立 subagent 出证据包）"
assert_in_file "$SKILL" "| **③ 退出**" "③ 退出（读最后证据包→deliver-gate）"
assert_in_file "$SKILL" "| **④ 失败码**" "④ 失败码（N 轮未收敛→停升级人）"

echo "  PASS 协同四步（①交接 / ②每轮 / ③退出 / ④失败码）"

echo ""
echo "=== ②每轮：证据包产出 round-N.md + 独立 subagent ==="
assert_in_file "$SKILL" "round-N.md" "round-N.md 证据包文件"
assert_in_file "$SKILL" "goal-evidence" "goal-evidence 目录"
assert_in_file "$SKILL" "dispatch 独立 subagent" "dispatch 独立 subagent（古德哈特防御）"
echo "  PASS 每轮证据包产出"

echo ""
echo "=== ③退出 → deliver-gate 衔接 ==="
assert_in_file "$SKILL" "进入 deliver-gate" "退出接 deliver-gate"
assert_in_file "$SKILL" "风险分级" "deliver-gate 风险分级（low 自动/high 人审）"
echo "  PASS deliver-gate 衔接"

echo ""
echo "=== ④失败码：不静默改走普通执行 ==="
assert_in_file "$SKILL" "停 + 升级人" "失败码停 + 升级人"
assert_in_file "$SKILL" "不静默改走普通执行" "不静默改走普通执行（防放飞 AI）"
echo "  PASS 失败码不静默"

echo ""
echo "All /goal collaboration behavior tests passed (§8.7 协同四步锚定)."
