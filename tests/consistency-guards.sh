#!/bin/bash
#
# 防再犯一致性守卫（v4.4，治"为什么之前没发现"的三类根因）
#
# A 引用存在：schema/patch 引用的 spec §号在 spec 真实存在（防 P0-3 引用悬空/错引复发）
# B run_all 一致：tests/*.sh（除 helper）== run_all suites（防 P1 uninstall 漏注册复发）
# C 版本快照：VERSION == PRD §1 里程碑 == §4 Current（防 P0-2 PRD 版本脱节复发）
#

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$(dirname "$0")/test_helpers.sh"

SPEC="$ROOT_DIR/docs/superpowers/specs/2026-06-29-spec-as-goal.md"
SCHEMA="$ROOT_DIR/patches/superpowers/_evidence-pack-schema.md"
PRD="$ROOT_DIR/PRD.md"
RUN_ALL="$ROOT_DIR/tests/run_all.sh"

echo "=== A: schema 引用的 spec §号真实存在（从 schema 提取，非硬编码）==="
[ -f "$SPEC" ] || fail "A: spec-as-goal.md 不存在"
# 从 schema 真实提取所有 spec §X.Y 引用，断言每个在 spec 存在（防错引复发）
refs=$(grep -oE 'spec §[0-9]+\.[0-9]+' "$SCHEMA" | grep -oE '[0-9]+\.[0-9]+' | sort -u)
[ -n "$refs" ] || fail "A: schema 无 spec §引用（提取失败）"
for sec in $refs; do
  grep -qE "^#+ $sec([. ]|$)" "$SPEC" || fail "A: schema 引用 spec §$sec 但 spec 无此章节"
done
echo "  PASS A（schema 引用的 spec 章节都存在，提取式校验）"

echo ""
echo "=== B: tests/*.sh（除 helper）== run_all suites（防漏注册/多余）==="
suites=$(grep -oE '[a-z][a-z0-9_-]*\.sh' "$RUN_ALL" | sort -u)
existing=$(ls "$ROOT_DIR"/tests/*.sh | xargs -n1 basename | grep -vE '^test_helpers\.sh$|^run_all\.sh$' | sort -u)
missing=$(comm -23 <(echo "$existing") <(echo "$suites"))
extra=$(comm -13 <(echo "$existing") <(echo "$suites"))
[ -z "$missing" ] || fail "B: tests/ 未注册到 run_all: $missing"
[ -z "$extra" ] || fail "B: run_all 多余注册（文件不存在）: $extra"
echo "  PASS B（tests/ 与 run_all 一致）"

echo ""
echo "=== C: VERSION == skill.json == PRD §1 里程碑 == §4 Current（防版本脱节）==="
VER=$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")
[ -n "$VER" ] || fail "C: VERSION 空"
SKILL_VER=$(grep -oE '"version": *"[^"]+"' "$ROOT_DIR/skill.json" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
[ "$SKILL_VER" = "$VER" ] || fail "C: skill.json($SKILL_VER) != VERSION($VER)"
grep -q "当前里程碑.*v$VER" "$PRD" || fail "C: PRD §1 里程碑 != VERSION(v$VER)"
grep -q "Current version: v$VER" "$PRD" || fail "C: PRD §4 Current != VERSION(v$VER)"
echo "  PASS C（VERSION=$VER == skill.json == PRD §1 == §4）"

echo ""
echo "=== F: README/CLAUDE 架构段列的目录真实存在（防删文件后文档悬空）==="
for d in templates/system templates/project lib patches/superpowers config docs commands; do
  [ -d "$ROOT_DIR/$d" ] || fail "F: 架构段列的目录 $d 不存在（文档悬空）"
done
# templates/init 已删（v4.4.2 删孤儿 prompt.md），README/CLAUDE 不该再列
if grep -qE "templates/init|init/.*[Ii]nit prompt" README.md CLAUDE.md; then
  fail "F: README/CLAUDE 仍列已删的 templates/init/"
fi
echo "  PASS F（架构段目录存在 + 无悬空 init/）"

echo ""
echo "All consistency guards passed (A 引用存在 / B run_all 一致 / C 版本快照)."
