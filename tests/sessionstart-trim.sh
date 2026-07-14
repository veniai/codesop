#!/bin/bash
# v5 Phase 2 R4 SessionStart 瘦身测试（spec §5 R4）
# kernel 独立文件 ≤30 行 + 七类各语义断言 + floor 判定入口 + full router 完整性 + setup 注入 kernel。
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$(dirname "$0")/test_helpers.sh"

command -v sha256sum >/dev/null 2>&1 || { echo "SKIP: sha256sum unavailable"; exit 0; }

kernel="$ROOT_DIR/config/codesop-router-kernel.md"
full="$ROOT_DIR/config/codesop-router.md"

# --- kernel 文件存在 + ≤30 行 ---
[ -f "$kernel" ] || fail "kernel 文件不存在: $kernel"
kl=$(wc -l < "$kernel" | tr -d ' ')
[ "$kl" -le 30 ] || fail "kernel 行数 $kl > 30"

kc=$(cat "$kernel")
# --- 七类不变量各语义断言（不只关键词，每类一句语义）---
assert_contains "$kc" "用户优先级"
assert_contains "$kc" "用户指令/明确授权优先"
assert_contains "$kc" "任务范围"
assert_contains "$kc" "只改任务相关"
assert_contains "$kc" "安全"
assert_contains "$kc" "不硬编码"
assert_contains "$kc" "失败披露"
assert_contains "$kc" "显式报告"
assert_contains "$kc" "根因"
assert_contains "$kc" "根因证据"
assert_contains "$kc" "验证证据"
assert_contains "$kc" "新鲜验证"
assert_contains "$kc" "高风险升级人"
assert_contains "$kc" "请求人审批"

# --- floor/profile 判定入口 ---
assert_contains "$kc" "floor 不可降"
assert_contains "$kc" "judge_profile"
assert_contains "$kc" "codesop-router.md"   # 指向 full router

# --- full router 文件存在 + 完整（技能总表 + 链路组装）---
[ -f "$full" ] || fail "full router 不存在: $full"
fc=$(cat "$full")
assert_contains "$fc" "技能总表"
assert_contains "$fc" "链路组装"

# --- setup 注入 kernel（非 full router）+ 仍安装 full router + sha256 基线 ---
setup=$(cat "$ROOT_DIR/setup")
assert_contains "$setup" "codesop-router-kernel.md"
assert_contains "$setup" 'cat $HOME/.claude/codesop-router-kernel.md'
assert_contains "$setup" 'codesop-router.md'           # full router 仍安装
assert_contains "$setup" "full-router-sha256"          # sha256 基线 stamp

# --- codex 复核 P1：升级迁移（旧 guarded full hook → kernel）---
# 重现 setup configure_hooks 的迁移 jq：旧 `[ ! -f ... ] && cat .../codesop-router.md`（guarded）
# 含 "codesop-router.md" → 匹配迁移正则 → 替换为 kernel command。
old_hook_cmd='[ ! -f /home/u/.claude/.codesop-router-disabled ] && cat /home/u/.claude/codesop-router.md'
mig_settings='{"hooks":{"SessionStart":[{"matcher":"","hooks":[{"type":"command","command":"'"$old_hook_cmd"'"}]}]}}'
new_hook_cmd='[ ! -f /home/u/.claude/.codesop-router-disabled ] && cat /home/u/.claude/codesop-router-kernel.md'
mig_out=$(echo "$mig_settings" | jq --arg cmd "$new_hook_cmd" 'if .hooks.SessionStart then .hooks.SessionStart |= map(if (.hooks|type)=="array" then .hooks |= map(if ((.command? // "")|tostring|test("codesop-router\\.md")) then .command=$cmd else . end) else . end) else . end')
assert_contains "$mig_out" "codesop-router-kernel.md"
# 旧 full cat（非 kernel）应已被替换掉
if echo "$mig_out" | grep -q 'cat [^ ]*/codesop-router\.md'; then fail "旧 guarded full hook 未迁移到 kernel"; fi

echo "  PASS sessionstart-trim（kernel ≤30 行 [$kl] + 七类语义 + floor 入口 + full router 完整 + setup 注入 kernel + 升级迁移）"
