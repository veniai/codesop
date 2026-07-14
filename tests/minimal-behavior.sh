#!/bin/bash
# v5 Phase 2 R2 minimal 行为改造测试（spec §5 R2）
# 文本结构守卫：校验 SKILL.md §3/§4 含 minimal profile 分支标记（声明跳过仪式）。
# 注意：只校验文本结构存在，**不伪称验证 AI 真行为**（真行为靠人工 dogfood，spec §8）。
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$(dirname "$0")/test_helpers.sh"

skill=$(cat "$ROOT_DIR/SKILL.md")

# §3 minimal 分支标记：声明跳过任务对齐块 / 固定四段 / spec-gate / HTML
assert_contains "$skill" "minimal"
assert_contains "$skill" "跳过"
assert_contains "$skill" "任务对齐块"
assert_contains "$skill" "spec-gate"
assert_contains "$skill" "HTML"
assert_contains "$skill" "固定四段输出"

# 边界：minimal 仍须保留新鲜验证证据（不得以 minimal 跳过验证）
assert_contains "$skill" "验证证据"

# governed fixture 对照：standard/governed 仍走完整 §3
assert_contains "$skill" "governed"

echo "  PASS minimal-behavior（SKILL.md minimal 分支文本结构守卫：标记存在，不伪称行为测试）"
