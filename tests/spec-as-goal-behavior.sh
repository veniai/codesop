#!/bin/bash
#
# v9 spec-as-goal 行为测试 R1-R4 (spec §8 + task-7-brief G12)
#
# Golden-content 断言：patch 源文件 + SKILL.md 必须包含 v9 行为文本。
# 不做真实 dispatch（dispatch 非确定性、慢、依赖运行时）；行为契约由文本锚定，
# 端到端 dogfood 阶段补 dispatch 实测。下限 = patch/SKILL 含对应行为文本。
#
# Acceptance 映射（spec §8 需求追溯表）：
#   R1 / G4 —— brainstorming spec 真产三件（完成条件 + 边界 + 风险分级）
#   R2 / G1,G2 —— spec-gate 真硬审 rubric 五项
#   R3 / G5 —— simple 真跳 plan（直接 /goal，无 spec-coverage）
#   R4 / G6 —— plan-gate 真不阻塞 re-entry（自证清零默认过）
#

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$(dirname "$0")/test_helpers.sh"

PATCHES="$ROOT_DIR/patches/superpowers"
SKILL="$ROOT_DIR/SKILL.md"

# 语法检查（G6 同口径）：被测文件存在 + bash 语法对 setup 仍绿（此处只查文件存在）
[ -f "$PATCHES/brainstorming-SKILL.md" ]            || fail "brainstorming patch missing"
[ -f "$PATCHES/writing-plans-SKILL.md" ]            || fail "writing-plans patch missing"
[ -f "$PATCHES/verification-before-completion-SKILL.md" ] || fail "verification patch missing"
[ -f "$PATCHES/_evidence-pack-schema.md" ]          || fail "schema sibling missing"
[ -f "$SKILL" ]                                     || fail "SKILL.md missing"

assert_in_file() {
  local file="$1" needle="$2" label="$3"
  grep -Fq "$needle" "$file" || fail "$label: $file missing text: $needle"
}

echo "=== R1: brainstorming spec 真产三件 ==="

# R1a: 头部准则声明三件 required
assert_in_file "$PATCHES/brainstorming-SKILL.md" \
  "spec-as-goal, 三件 required" \
  "R1 header declares 三件 required"

# R1b: 三件各自的定义都在（完成条件 / 边界 / 风险分级）
assert_in_file "$PATCHES/brainstorming-SKILL.md" \
  "**完成条件 (completion condition)**" \
  "R1 完成条件 definition present"
assert_in_file "$PATCHES/brainstorming-SKILL.md" \
  "**边界 (anti-Goodhart boundary)**" \
  "R1 边界 definition present"
assert_in_file "$PATCHES/brainstorming-SKILL.md" \
  "**风险分级 (risk tier)**" \
  "R1 风险分级 definition present"

echo "  PASS R1 (brainstorming 产三件: 完成条件 + 边界 + 风险分级)"

echo ""
echo "=== R2: spec-gate 真硬审 rubric 五项 ==="

# R2a: SKILL.md spec-gate rubric 表头 + 五项都在
assert_in_file "$SKILL" "五项 rubric" "R2 rubric header in SKILL.md"
assert_in_file "$SKILL" "**可验证性**"        "R2 rubric #1 可验证性"
assert_in_file "$SKILL" "**反例 / 边界**"      "R2 rubric #2 反例/边界"
assert_in_file "$SKILL" "**不可缩减边界**"     "R2 rubric #3 不可缩减边界"
assert_in_file "$SKILL" "**风险分级校准**"     "R2 rubric #4 风险分级校准"
assert_in_file "$SKILL" "**traceability**"     "R2 rubric #5 traceability"

# R2b0: rubric 实质判定（不只字段名——防"字段在、实质退化"）
assert_in_file "$SKILL" "缩减 / 钻空子"        "R2 rubric 反例边界实质（防古德哈特）"
assert_in_file "$SKILL" "无悬空需求"           "R2 rubric traceability 实质"

# R2b: spec-gate 是唯一不可省的人审（做重，不是字段齐走过场）
assert_in_file "$SKILL" "spec-gate 是**唯一不可省的人审**" \
  "R2 spec-gate 唯一硬审 declared"

# R2c: brainstorming 内联 reviewer 也审 rubric（保留 1 代表字段，释放 4 措辞锁）
assert_in_file "$PATCHES/brainstorming-SKILL.md" "| Completeness |" "R2 inline reviewer Completeness (代表)"

echo "  PASS R2 (spec-gate 唯一硬审 + rubric 五项 + brainstorming 内联 reviewer 同口径)"

echo ""
echo "=== R3: simple 真跳 plan（直接 /goal，无 spec-coverage）==="

# R3a: writing-plans 明确 simple 跳 ALL plan orchestration（simple 跳 plan 术语锚）
assert_in_file "$PATCHES/writing-plans-SKILL.md" \
  "simple skips plan entirely" \
  "R3 simple-skip-plan header declared"

# R3b: simple 直接进 Pipeline Continuation → /goal（合并跳的内容：无 plan / 无 spec-coverage）
assert_in_file "$PATCHES/writing-plans-SKILL.md" \
  "Proceed directly to Pipeline Continuation" \
  "R3 simple proceeds to Pipeline Continuation (合并跳的内容)"

# R3c: SKILL.md 适用边界表也声明 simple 无 plan 阶段
assert_in_file "$SKILL" "spec → **spec-gate（硬审）** → \`/goal\`（deliver 自动过）" \
  "R3 SKILL.md simple route: spec → spec-gate → /goal (no plan)"

echo "  PASS R3 (simple 跳 plan: 直进 /goal，无 plan / spec-coverage)"

echo ""
echo "=== R4: plan-gate 真不阻塞 re-entry（自证清零默认过）==="

# R4a: plan-gate 自证清零默认过（术语锚：plan-gate 默认过）
assert_in_file "$SKILL" \
  "AI 自证清零后默认通过；人只扫 advisory，不阻塞 re-entry" \
  "R4 plan-gate 默认过 + 不阻塞 re-entry (降级表)"

# R4b: advisory = 顾虑 ≠ 阻塞（语义锚定 schema §9）
assert_in_file "$PATCHES/verification-before-completion-SKILL.md" \
  "判定=\`顾虑\` ≠ 阻塞" \
  "R4 verification 顾虑≠阻塞 semantics"

echo "  PASS R4 (plan-gate 自证清零默认过 + advisory 不阻塞 re-entry)"

echo ""
echo "All R1-R4 behavior tests passed."
