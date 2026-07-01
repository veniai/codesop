#!/bin/bash
#
# 防再犯 D：init 访谈死代码已删（v4.4 P0-1）+ 真实模板无占位符
#
# P0-1 背景：codesop init 曾有用户偏好访谈（4 问 + 占位符 sed 替换），但模板
# templates/system/AGENTS.md 已硬编码标准偏好（中文/标准/50行/必要才注释），
# 占位符 0 命中 → 访谈永不触发（死代码）。v4.4 删除访谈机制——偏好由 Claude Code
# /init + 全局 CLAUDE.md 管，codesop init 只生成标准模板。
#
# 本测试防止访谈机制复活（占位符 sed / 访谈函数 / AskUserQuestion 入口回归）。
# 真实模板测试（禁合成 fixture——v4.3.1 诊断 P0-1 假绿测试的根因）。
#

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$(dirname "$0")/test_helpers.sh"

LIB="$ROOT_DIR/lib/init-interview.sh"
CMD="$ROOT_DIR/commands/codesop-init.md"
TPL="$ROOT_DIR/templates/system/AGENTS.md"

[ -f "$LIB" ] || fail "init-interview.sh missing"
[ -f "$CMD" ] || fail "codesop-init.md missing"
[ -f "$TPL" ] || fail "AGENTS.md template missing"

assert_absent() {
  local file="$1" needle="$2" label="$3"
  if grep -Fq "$needle" "$file"; then
    fail "$label: $file 仍含死代码: $needle"
  fi
}

echo "=== D-1: init-interview.sh 访谈 3 函数已删 ==="
assert_absent "$LIB" "check_user_preferences()" "D-1 check_user_preferences 已删"
assert_absent "$LIB" "has_user_preferences()"   "D-1 has_user_preferences 已删"
assert_absent "$LIB" "interview_user_preferences()" "D-1 interview_user_preferences 已删"
echo "  PASS D-1（访谈 3 函数已删）"

echo "=== D-2: init-interview.sh 无占位符 sed 替换 ==="
assert_absent "$LIB" 's/{LANG}/'         "D-2 {LANG} sed 已删"
assert_absent "$LIB" 's/{STYLE}/'        "D-2 {STYLE} sed 已删"
assert_absent "$LIB" 's/{FUNC_LENGTH}/'  "D-2 {FUNC_LENGTH} sed 已删"
assert_absent "$LIB" 's/{COMMENT_STYLE}/' "D-2 {COMMENT_STYLE} sed 已删"
echo "  PASS D-2（占位符 sed 已删）"

echo "=== D-3: commands/codesop-init.md 无访谈入口 ==="
assert_absent "$CMD" "NEEDS_INTERVIEW" "D-3 NEEDS_INTERVIEW 已删"
assert_absent "$CMD" "AskUserQuestion" "D-3 AskUserQuestion 访谈已删"
assert_absent "$CMD" 's/{LANG}/'        "D-3 commands 无占位符 sed"
echo "  PASS D-3（commands 访谈入口已删）"

echo "=== D-4: 真实模板无占位符（标准偏好硬编码）==="
assert_absent "$TPL" "{LANG}"         "D-4 模板无 {LANG}"
assert_absent "$TPL" "{STYLE}"        "D-4 模板无 {STYLE}"
assert_absent "$TPL" "{FUNC_LENGTH}"  "D-4 模板无 {FUNC_LENGTH}"
assert_absent "$TPL" "{COMMENT_STYLE}" "D-4 模板无 {COMMENT_STYLE}"
echo "  PASS D-4（真实模板无占位符，硬编码标准偏好）"

echo "=== D-5: lib/ + commands/ 全无访谈逻辑（防换文件复活）==="
hit=$(grep -rl "check_user_preferences\|has_user_preferences\|interview_user_preferences\|NEEDS_INTERVIEW" "$ROOT_DIR/lib" "$ROOT_DIR/commands" 2>/dev/null || true)
[ -z "$hit" ] || fail "D-5: lib/commands 仍含访谈逻辑: $hit"
echo "  PASS D-5（lib/ + commands/ 全无访谈逻辑）"

echo ""
echo "All init-deadcode-removed tests passed (P0-1 防再犯 D)."
