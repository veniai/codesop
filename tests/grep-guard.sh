#!/bin/bash
# v5 Phase 1 grep 守卫（spec §6）：core 中立函数库不含 Claude 路径词。
# Claude 专属函数在 lib/adapter/；命令层（updates/init-interview）调 adapter 装 Claude，
# 是集成层不是 core，不在守卫范围。守卫只查 core 函数库代码（排除注释）。
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$(dirname "$0")/test_helpers.sh"

CORE_FILES="$ROOT_DIR/lib/detection.sh $ROOT_DIR/lib/commands.sh"
# 守卫词：Claude 专属路径/概念，core 不应出现
PATROL="installed_plugins\.json|\.claude/|SessionStart|find_superpowers_plugin_path|/goal"

violations=0
for f in $CORE_FILES; do
  [ -f "$f" ] || continue
  # 排除注释行（core 函数注释里提及概念允许，代码不可用）
  hits=$(grep -vE '^\s*#' "$f" 2>/dev/null | grep -nE "$PATROL" || true)
  if [ -n "$hits" ]; then
    echo "FAIL: $(basename "$f") core 代码含 Claude 路径词（应挪 lib/adapter/）："
    echo "$hits"
    violations=$((violations + 1))
  fi
done

[ "$violations" = 0 ] || fail "core 函数库含 Claude 路径词（spec §6：core 中立，Claude 专属归 adapter）"
echo "  PASS grep-guard（core detection+commands 无 Claude 路径词；Claude 专属在 lib/adapter/，命令层调 adapter）"
