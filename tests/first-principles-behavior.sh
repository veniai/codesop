#!/bin/bash
#
# 第一性原理强化 v1 行为测试 R1-R3 (spec §2)
#
# Golden-content 断言：brainstorming patch + SKILL/路由卡 必须包含"第一性原理"行为文本。
# 不做真实 dispatch（dispatch 非确定性、慢、依赖运行时）；行为契约由文本锚定，
# 端到端 dogfood 阶段补 dispatch 实测。下限 = patch/SKILL/路由卡 含对应行为文本。
#
# Acceptance 映射（spec §2 需求追溯表）：
#   R1 —— brainstorming 造方案前走第一性原理推导（从基本事实推，再对比类比）
#   R2 —— systematic-debugging 排查走第一性原理找根因（不照搬"类似 bug 这样修"）
#   R3 —— 本测试本身（行为契约锚定）
#

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$(dirname "$0")/test_helpers.sh"

PATCHES="$ROOT_DIR/patches/superpowers"
SKILL="$ROOT_DIR/SKILL.md"
ROUTER="$ROOT_DIR/config/codesop-router.md"

# 语法检查：被测文件存在
[ -f "$PATCHES/brainstorming-SKILL.md" ] || fail "brainstorming patch missing"
[ -f "$SKILL" ]                          || fail "SKILL.md missing"
[ -f "$ROUTER" ]                         || fail "router card missing"

assert_in_file() {
  local file="$1" needle="$2" label="$3"
  grep -Fq "$needle" "$file" || fail "$label: $file missing text: $needle"
}

echo "=== R1: brainstorming 造方案前走第一性原理推导 ==="

# R1a: "Exploring approaches" 段显式声明第一性原理推导（造方案前推，不照搬类比）
assert_in_file "$PATCHES/brainstorming-SKILL.md" \
  "第一性原理推导 (first-principles derivation, BEFORE proposing approaches)" \
  "R1 Exploring approaches declares first-principles derivation before proposing"

# R1b: 推导从基本事实/约束出发（不是类比照搬）
assert_in_file "$PATCHES/brainstorming-SKILL.md" \
  "derive the solution from the problem's irreducible basic facts and constraints" \
  "R1 derivation from basic facts/constraints (not analogy copy)"

# R1c: 推导后对比类比——divergence 是关键（不照搬类比）
assert_in_file "$PATCHES/brainstorming-SKILL.md" \
  "Compare derivation vs analogy" \
  "R1 compare derivation vs analogy (weigh trade-offs after derivation)"

# R1d: 复杂度边界——complex/moderate 走，simple/trivial 跳（对齐 spec §3）
assert_in_file "$PATCHES/brainstorming-SKILL.md" \
  "Walk this for complex / moderate tasks" \
  "R1 complexity boundary: complex/moderate walk, simple/trivial skip"

# R1e: Key Principles 也锚定第一性原理（铁律级）
assert_in_file "$PATCHES/brainstorming-SKILL.md" \
  "First-principles before analogy" \
  "R1 Key Principles anchors first-principles as a standing principle"

# R1f: header changelog 记录 first-principles v1 patch（叠加，不推翻 v9）
assert_in_file "$PATCHES/brainstorming-SKILL.md" \
  "(first-principles v1) First-principles derivation step" \
  "R1 header changelog records the patch (additive over v9)"

echo "  PASS R1 (brainstorming 造方案前走第一性原理推导 + 对比类比 + 复杂度边界 + Key Principle)"

echo ""
echo "=== R2: systematic-debugging 走第一性原理找根因 ==="

# R2a: SKILL.md 铁律 "No fix without root cause" 强化第一性原理找根因
assert_in_file "$SKILL" \
  "No fix without root cause investigation（第一性原理找根因：从基本事实/约束推根因，不照搬\"类似 bug 这样修\"）" \
  "R2 SKILL.md iron rule strengthens first-principles root-cause"

# R2b: 路由卡调试路径显式第一性原理找根因（强化"无根因不修 bug"）
assert_in_file "$ROUTER" \
  "第一性原理找根因：从基本事实/约束推根因，不照搬\"类似 bug 这样修\"" \
  "R2 router debug path declares first-principles root-cause"

echo "  PASS R2 (SKILL 铁律 + 路由卡调试路径都显式第一性原理找根因，强化无根因不修)"

echo ""
echo "All R1-R2 behavior tests passed (R3 = this test itself)."
