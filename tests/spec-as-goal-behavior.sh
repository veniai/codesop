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

# R1c: evidence-pack (a) verdict 把缺三件判为 没满足（blocker）—— 真硬约束
assert_in_file "$PATCHES/brainstorming-SKILL.md" \
  "Missing 三件 on a requirement = " \
  "R1 evidence-pack verdict treats 三件-missing as blocker"

# R1d: 边界是硬 floor（违反 = 整条 fail，防古德哈特）
assert_in_file "$PATCHES/brainstorming-SKILL.md" \
  "The boundary is a hard floor" \
  "R1 边界 anti-Goodhart hard-floor clause"

echo "  PASS R1 (brainstorming 产三件: 完成条件 + 边界 + 风险分级 + 没满足硬判)"

echo ""
echo "=== R2: spec-gate 真硬审 rubric 五项 ==="

# R2a: SKILL.md spec-gate rubric 表头 + 五项都在
assert_in_file "$SKILL" "五项 rubric" "R2 rubric header in SKILL.md"
assert_in_file "$SKILL" "**可验证性**"        "R2 rubric #1 可验证性"
assert_in_file "$SKILL" "**反例 / 边界**"      "R2 rubric #2 反例/边界"
assert_in_file "$SKILL" "**不可缩减边界**"     "R2 rubric #3 不可缩减边界"
assert_in_file "$SKILL" "**风险分级校准**"     "R2 rubric #4 风险分级校准"
assert_in_file "$SKILL" "**traceability**"     "R2 rubric #5 traceability"

# R2b: spec-gate 是唯一不可省的人审（做重，不是字段齐走过场）
assert_in_file "$SKILL" "spec-gate 是**唯一不可省的人审**" \
  "R2 spec-gate 唯一硬审 declared"

# R2c: brainstorming 内联 reviewer 也审 rubric（Completeness/Consistency/Clarity/Scope/YAGNI/三件）
assert_in_file "$PATCHES/brainstorming-SKILL.md" "| Completeness |" "R2 inline reviewer Completeness"
assert_in_file "$PATCHES/brainstorming-SKILL.md" "| Consistency |" "R2 inline reviewer Consistency"
assert_in_file "$PATCHES/brainstorming-SKILL.md" "| Clarity |"     "R2 inline reviewer Clarity"
assert_in_file "$PATCHES/brainstorming-SKILL.md" "| Scope |"       "R2 inline reviewer Scope"
assert_in_file "$PATCHES/brainstorming-SKILL.md" "| YAGNI |"       "R2 inline reviewer YAGNI"

echo "  PASS R2 (spec-gate 唯一硬审 + rubric 五项 + brainstorming 内联 reviewer 同口径)"

echo ""
echo "=== R3: simple 真跳 plan（直接 /goal，无 spec-coverage）==="

# R3a: writing-plans 明确 simple 跳 ALL plan orchestration
assert_in_file "$PATCHES/writing-plans-SKILL.md" \
  "simple skips plan entirely" \
  "R3 simple-skip-plan header declared"

# R3b: 跳的具体内容——无 Lightweight Plan / 无 spec-coverage / 无 File Structure
assert_in_file "$PATCHES/writing-plans-SKILL.md" \
  "Skip ALL plan orchestration" \
  "R3 simple Skip ALL plan orchestration"
assert_in_file "$PATCHES/writing-plans-SKILL.md" \
  "No Lightweight Plan, no spec-coverage review, no File Structure" \
  "R3 simple skips Lightweight Plan + spec-coverage + File Structure"

# R3c: simple 直接进 Pipeline Continuation → /goal（不是退化到 plan）
assert_in_file "$PATCHES/writing-plans-SKILL.md" \
  "Proceed directly to Pipeline Continuation" \
  "R3 simple proceeds to Pipeline Continuation"

# R3d: SKILL.md 适用边界表也声明 simple 无 plan 阶段
assert_in_file "$SKILL" "spec → **spec-gate（硬审）** → \`/goal\`（deliver 自动过）" \
  "R3 SKILL.md simple route: spec → spec-gate → /goal (no plan)"

# R3e: simple 有 NO spec-coverage（spec §4.6 simple 完成条件 = test + lint only）
assert_in_file "$PATCHES/writing-plans-SKILL.md" \
  "simple has NO spec-coverage" \
  "R3 simple has NO spec-coverage"

echo "  PASS R3 (simple 跳 plan: 无 Lightweight Plan / spec-coverage / File Structure → 直进 /goal)"

echo ""
echo "=== R4: plan-gate 真不阻塞 re-entry（自证清零默认过）==="

# R4a: SKILL.md 三 human-gate 降级表声明 plan-gate 不阻塞 re-entry
assert_in_file "$SKILL" \
  "AI 自证清零后默认通过；人只扫 advisory，不阻塞 re-entry" \
  "R4 plan-gate 默认过 + 不阻塞 re-entry (降级表)"

# R4b: §8.7 D 节 plan-gate 流程也声明默认过
assert_in_file "$SKILL" \
  "AI 自证清零（plan 任务全 done / 无遗留 advisory blocker）→ **默认通过**，进 A① 调 /goal" \
  "R4 plan-gate §8.7D default-pass"

# R4c: 人扫 advisory 不阻塞
assert_in_file "$SKILL" \
  "人扫 advisory（如有），**不阻塞 re-entry**" \
  "R4 plan-gate 人扫 advisory 不阻塞 re-entry"

# R4d: writing-plans 侧 plan-gate 不在本 patch 范围、不在此阻塞（口径一致）
assert_in_file "$PATCHES/writing-plans-SKILL.md" \
  "Do not block here." \
  "R4 writing-plans 不在 plan-gate 阻塞"

# R4e: advisory = 顾虑 ≠ 阻塞（语义锚定 schema §9）
assert_in_file "$PATCHES/verification-before-completion-SKILL.md" \
  "判定=\`顾虑\` ≠ 阻塞" \
  "R4 verification 顾虑≠阻塞 semantics"

echo "  PASS R4 (plan-gate 自证清零默认过 + advisory 不阻塞 re-entry + schema 语义锚定)"

echo ""
echo "All R1-R4 behavior tests passed."
