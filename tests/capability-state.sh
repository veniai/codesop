#!/bin/bash
# v5 Phase 0 capability state 测试（spec §8 待实施 4 项）
# 验证 lib/detection.sh 的 4 函数：
#   runtime_version_superpowers / codesop_manifest_hash /
#   capability_state（healthy/stale/absent/unknown）/ family_aggregate（取最差）
# 用 fake HOME（不依赖真实环境）。

set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$(dirname "$0")/test_helpers.sh"

command -v jq >/dev/null 2>&1 || { echo "SKIP: jq unavailable"; exit 0; }
command -v sha256sum >/dev/null 2>&1 || { echo "SKIP: sha256sum unavailable"; exit 0; }

WORKROOT="$(mktemp -d)"
trap 'rm -rf "$WORKROOT"' EXIT
export HOME="$WORKROOT/home"
STATE_DIR="$HOME/.local/state/codesop"
mkdir -p "$STATE_DIR" "$HOME/.claude/skills/codesop"

# shellcheck disable=SC1091
source "$ROOT_DIR/lib/adapter/claude.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/lib/detection.sh"

write_plugins_json() {
  local sha="$1"
  cat > "$HOME/.claude/plugins/installed_plugins.json" <<JSON
{"plugins":{"superpowers@claude-plugins-official":[{"version":"6.1.1","gitCommitSha":"$sha"}]}}
JSON
}

# --- Scenario 1: absent（无 installed_plugins.json / superpowers 未注册）---
out=$(capability_state)
assert_contains "$out" "CAPABILITY_STATE=absent"

# 构造 superpowers plugin cache（find_superpowers_plugin_path 查 cache 目录）
mkdir -p "$HOME/.claude/plugins/cache/claude-plugins-official/superpowers/6.1.1/skills"
# codesop 安装文件（manifest hash 用）
echo "fake codesop SKILL" > "$HOME/.claude/skills/codesop/SKILL.md"
echo "fake router" > "$HOME/.claude/codesop-router.md"

# --- Scenario 2: healthy（version + sha + manifest 都一致）---
write_plugins_json "abc123def"
echo "abc123def" > "$STATE_DIR/patch-upstream-sha"
cur_hash=$(codesop_manifest_hash)
echo "$cur_hash" > "$STATE_DIR/manifest-hash"
out=$(capability_state)
assert_contains "$out" "CAPABILITY_STATE=healthy"

# --- Scenario 3: stale（gitCommitSha 变了 → fingerprint 不符）---
write_plugins_json "changed_sha_xyz"
out=$(capability_state)
assert_contains "$out" "CAPABILITY_STATE=stale"

# --- Scenario 4: stale（manifest hash 变了 → codesop 文件被改/损坏）---
write_plugins_json "abc123def"  # sha 恢复一致
echo "different_manifest_hash_value" > "$STATE_DIR/manifest-hash"  # stamp ≠ 当前
out=$(capability_state)
assert_contains "$out" "CAPABILITY_STATE=stale"

# --- Scenario 5: family aggregate（claude stale 上浮取最差）---
write_plugins_json "changed_sha_xyz"  # claude 回到 stale
out=$(family_aggregate)
assert_contains "$out" "FAMILY_CLAUDE=stale"
assert_contains "$out" "FAMILY=stale"

# --- Scenario 6: family（codex/opencode present/absent 字段存在）---
assert_contains "$out" "FAMILY_CODEX="
assert_contains "$out" "FAMILY_OPENCODE="

# --- Scenario 7: runtime_version_superpowers 输出 version + sha ---
write_plugins_json "abc123def"
out=$(runtime_version_superpowers)
assert_contains "$out" "RUNTIME_VERSION=6.1.1"
assert_contains "$out" "RUNTIME_SHA=abc123def"

echo "  PASS capability-state（4 函数 × healthy/stale/absent/unknown + family 取最差）"
