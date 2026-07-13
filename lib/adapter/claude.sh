#!/bin/bash
# lib/adapter/claude.sh — Claude Code 专属函数（v5 Phase 1 §6 解耦）
# 含 ~/.claude 路径的函数归 adapter；core（lib/ 除 lib/adapter/）不含 Claude 路径（grep 守卫）。
# 从 lib/detection.sh（has_mcp_server / find_superpowers_plugin_path /
# runtime_version_superpowers / codesop_manifest_hash）+ lib/updates.sh（_dep_installed_version）挪入。
# Guard: HOME may be unset when sourced by hooks/IDE
export HOME="${HOME:-$(echo ~)}"

# Check if a specific MCP server is configured in Claude Code settings.
# Arguments: $1 - MCP server name. Returns 0 if configured, 1 if not.
has_mcp_server() {
  local server_name="$1"
  local settings_file="$HOME/.claude/settings.json"
  [ -f "$settings_file" ] || return 1
  # Check exact name and common hyphen/underscore variation
  local name_alt="${server_name//-/_}"
  jq -e --arg name "$server_name" --arg alt "$name_alt" \
    '.mcpServers | if . then (has($name) or has($alt)) else false end' \
    "$settings_file" 2>/dev/null | grep -q true
}

# Find superpowers installed via Claude Code plugin marketplace.
# Returns path to the latest version directory, or nothing if not found.
find_superpowers_plugin_path() {
  local marketplace_dir version_dir
  for marketplace_dir in "$HOME/.claude/plugins/cache/"*"/superpowers"; do
    [ -d "$marketplace_dir" ] || continue
    # Find the latest version directory (sorted by version, pick last)
    version_dir=$(find "$marketplace_dir" -maxdepth 1 -type d 2>/dev/null | sort -V | tail -1)
    if [ -n "$version_dir" ] && [ "$version_dir" != "$marketplace_dir" ]; then
      # Skip orphaned installations
      [ -f "$version_dir/.orphaned_at" ] && continue
      printf '%s\n' "$version_dir"
      return 0
    fi
  done
  return 1
}

# superpowers runtime version + upstream gitCommitSha (Claude family).
# Output: RUNTIME_VERSION=<ver|absent|unknown>  RUNTIME_SHA=<sha|absent|unknown>
runtime_version_superpowers() {
  local plugins_json="$HOME/.claude/plugins/installed_plugins.json"
  if [ -z "$(find_superpowers_plugin_path 2>/dev/null || true)" ]; then
    printf '%s\n' "RUNTIME_VERSION=absent" "RUNTIME_SHA=absent"
    return
  fi
  if [ ! -f "$plugins_json" ] || ! command -v jq >/dev/null 2>&1; then
    printf '%s\n' "RUNTIME_VERSION=unknown" "RUNTIME_SHA=unknown"
    return
  fi
  local ver sha
  ver=$(jq -r '.plugins["superpowers@claude-plugins-official"][0].version // empty' "$plugins_json" 2>/dev/null)
  sha=$(jq -r '.plugins["superpowers@claude-plugins-official"][0].gitCommitSha // empty' "$plugins_json" 2>/dev/null)
  [ -n "$ver" ] && echo "RUNTIME_VERSION=$ver" || echo "RUNTIME_VERSION=unknown"
  [ -n "$sha" ] && echo "RUNTIME_SHA=$sha" || echo "RUNTIME_SHA=unknown"
}

# codesop manifest hash (sha256 of installed SKILL.md + router).
# Output: 16-char hash | absent | unknown
codesop_manifest_hash() {
  local skill="$HOME/.claude/skills/codesop/SKILL.md"
  local router="$HOME/.claude/codesop-router.md"
  command -v sha256sum >/dev/null 2>&1 || { echo "unknown"; return; }
  [ -f "$skill" ] || { echo "absent"; return; }
  local files="$skill"
  [ -f "$router" ] && files="$skill $router"
  sha256sum $files 2>/dev/null | sha256sum | cut -c1-16
}

# Read installed plugin version from Claude installed_plugins.json.
# Arguments: $1 - plugin qualified id. Prints version (empty if unavailable).
_dep_installed_version() {
  local id="$1"
  local plugins_json="$HOME/.claude/plugins/installed_plugins.json"
  if [ -f "$plugins_json" ] && command -v jq >/dev/null 2>&1; then
    jq -r --arg id "$id" '.plugins[$id][0].version // ""' "$plugins_json" 2>/dev/null || true
  fi
}
