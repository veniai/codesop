#!/bin/bash
# codesop patch health check — run from SessionStart hook.
#
# Silent (no stdout) when superpowers installed version matches the patch
# baseline; prints a loud banner ONLY when incompatible (patches would be
# skipped by dep_patch_compat). Companion to setup's _patch_stale_warn:
# that warns at setup time, this warns at every session start — so a stale
# patch is caught without re-running setup (see the 6.0.3→6.1.1 incident
# where patches were silently skipped for 9 days).
#
# SessionStart injects stdout into session context, so absolute silence when
# healthy is mandatory — never echo diagnostics here.

stamp="$HOME/.claude/.codesop-patch-baseline"
[ -f "$stamp" ] || exit 0
baseline=$(tr -d '[:space:]' < "$stamp" 2>/dev/null)
[ -n "$baseline" ] || exit 0

plugins_json="$HOME/.claude/plugins/installed_plugins.json"
[ -f "$plugins_json" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

inst=$(jq -r '.plugins["superpowers@claude-plugins-official"][0].version // empty' "$plugins_json" 2>/dev/null)
[ -n "$inst" ] || exit 0

inst_mm="${inst%%.*}.$(echo "$inst" | cut -d. -f2)"
if [ "$inst_mm" != "$baseline" ]; then
  printf '%s\n' "" \
    "  ------------------------------------------------------------" \
    "  ⚠⚠  codesop 核心 patch 未生效（superpowers $inst ≠ 补丁基线 $baseline.x） ⚠⚠" \
    "  spec 三件套 / grill / deliver-gate / simple 出口 / 对抗审查 等行为将不可用" \
    "  修复：跑 \`bash setup --host claude\` 适配，或手动适配 patches/superpowers/ + bump 基线" \
    "  ------------------------------------------------------------" ""
fi
exit 0
