#!/bin/bash
#
# 对抗式审查 v1 行为测试 R1-R4 (spec §2)
#
# Golden-content 断言：verification patch §C.2 必须包含对抗式审查行为文本。
# 不做真实 dispatch（dispatch 非确定性、慢、依赖运行时）；行为契约由文本锚定，
# 端到端 dogfood 阶段补 dispatch 实测。下限 = patch 含对应行为文本。
#
# Acceptance 映射（spec §2 需求追溯表）：
#   R1 —— verification deliver-gate high 路径加对抗式审查子步骤（边界 bug 11 类）
#   R2 —— 复用动态工作流（AI 自动）+ codex:adversarial-review（用户手动）+ 双机制降级
#   R3 —— 找到的 bug 进证据包 blocking
#   R4 —— 本测试本身（行为契约锚定）
#

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$(dirname "$0")/test_helpers.sh"

PATCH="$ROOT_DIR/patches/superpowers/verification-before-completion-SKILL.md"

[ -f "$PATCH" ] || fail "verification patch missing"

assert_in_file() {
  local file="$1" needle="$2" label="$3"
  grep -Fq "$needle" "$file" || fail "$label: $file missing text: $needle"
}

echo "=== R1: verification deliver-gate high 路径加对抗式审查（边界 bug 11 类）==="

# R1a: §C.2 标题（high-risk deliver 前攻击者视角扫）
assert_in_file "$PATCH" \
  "对抗式审查（high-risk deliver 前，adversarial-review 强化）" \
  "R1 §C.2 section title (adversarial review before high-risk deliver)"

# R1b: 攻击者视角命题（恶意用户怎么搞崩）
assert_in_file "$PATCH" \
  "恶意用户怎么搞崩" \
  "R1 attacker-mindset proposition (how does a malicious user break it)"

# R1c: 边界 bug 类——保留 1 代表 + 开放列表（释放 7 个措辞锁：5 类原始 + 5 类补全的字段锁）
assert_in_file "$PATCH" "资源泄漏"     "R1 boundary bug class 代表 (resource leak)"
assert_in_file "$PATCH" "含但不限于"   "R1 open list marker (non-exhaustive, 允许扩展)"

echo "  PASS R1 (§C.2 high 路径对抗式审查 + 边界 bug 开放列表)"

echo ""
echo "=== R2: 复用动态工作流（AI 自动）+ codex:adversarial-review（用户手动）==="

# R2a: 动态工作流多 agent（AI 自动走，ultracode adversarial verify）
assert_in_file "$PATCH" \
  "动态工作流多 agent（AI 自动走）" \
  "R2 dynamic workflow multi-agent (AI auto, ultracode adversarial verify)"

# R2b: codex:adversarial-review（用户手动，路由卡约束）
assert_in_file "$PATCH" \
  "codex:adversarial-review（用户手动）" \
  "R2 codex:adversarial-review (user manual, router constraint)"

# R2c: 不另造攻击者 agent（复用现有）
assert_in_file "$PATCH" \
  "不另造攻击者 agent" \
  "R2 reuse existing, no new attacker agent"

echo "  PASS R2 (动态工作流 AI 自动 + codex 用户手动 + 不另造)"

echo ""
echo "=== R2 降级: 双机制都不可用 → 单 agent 兜底，不静默跳过 ==="

assert_in_file "$PATCH" \
  "双机制都不可用降级" \
  "R2 dual-mechanism unavailable degrade clause"

assert_in_file "$PATCH" \
  "至少单 agent 攻击者视角扫" \
  "R2 fallback single agent (no silent skip)"

echo "  PASS R2-degrade (双机制不可用 → 单 agent，不静默跳过)"

echo ""
echo "=== R3: 找到的 bug 进证据包 blocking，不清零不交付 ==="

assert_in_file "$PATCH" \
  "找到的 bug 进证据包 blocking" \
  "R3 findings enter evidence-pack as blocking (合并: 不清零不交付)"

echo "  PASS R3 (对抗式审查 bug 进证据包 blocking)"

echo ""
echo "=== low 判定可疑兜底（防 spec 作者误判 low 放过边界 bug，spec 漏洞 2）==="

assert_in_file "$PATCH" \
  "low 判定可疑兜底" \
  "low-suspicion escalation guard header"

assert_in_file "$PATCH" \
  "升级 high" \
  "low-suspicion escalates to high"

echo "  PASS low-guard (low 判定可疑升级 high)"

echo ""
echo "All R1-R4 behavior tests passed (R4 = this test itself)."
