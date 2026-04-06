#!/bin/bash
# updates.sh - Version checking and dependency utilities for codesop v2
#
# This module provides functions for:
# - Checking plugin completeness (CORE + OPTIONAL)
# - Checking independent skill completeness
# - Checking plugin versions
# - Checking routing coverage against the router table
# - Printing a unified dependency report
# - Checking git repository update status
# - Getting current version
#
# Dependencies:
# - lib/output.sh: format_tool_state(), format_ecosystem_state()
#
# Expected caller-set variables:
# - ROOT_DIR: Root directory of codesop installation
# - VERSION_FILE: Path to VERSION file (typically $ROOT_DIR/VERSION)
#
# Usage: source this file from another bash script
#   source /path/to/lib/updates.sh

current_version() {
  cat "$VERSION_FILE" 2>/dev/null || echo "unknown"
}

# Core plugins — missing = error
CORE_PLUGINS=(
  "superpowers@claude-plugins-official"
  "code-review@claude-plugins-official"
)

# Optional plugins — missing = warning
OPTIONAL_PLUGINS=(
  "skill-creator@claude-plugins-official"
  "frontend-design@claude-plugins-official"
  "context7@claude-plugins-official"
  "code-simplifier@claude-plugins-official"
  "playwright@claude-plugins-official"
  "claude-md-management@claude-plugins-official"
  "codex@openai-codex"
)

# Independent skills — missing = warning
OPTIONAL_SKILLS=(
  "codesop"
  "browser-use"
  "claude-to-im"
)

check_plugin_completeness() {
  local plugins_file="$HOME/.claude/plugins/installed_plugins.json"
  local missing_core=() missing_optional=()

  if [ ! -f "$plugins_file" ]; then
    printf '%s\n' "❌ 插件配置文件不存在: $plugins_file"
    return 1
  fi

  for plugin in "${CORE_PLUGINS[@]}"; do
    if ! jq -e --arg id "$plugin" '.plugins | has($id)' "$plugins_file" 2>/dev/null | grep -q true; then
      missing_core+=("$plugin")
    fi
  done

  for plugin in "${OPTIONAL_PLUGINS[@]}"; do
    if ! jq -e --arg id "$plugin" '.plugins | has($id)' "$plugins_file" 2>/dev/null | grep -q true; then
      missing_optional+=("$plugin")
    fi
  done

  if [ ${#missing_core[@]} -gt 0 ]; then
    printf '%s\n' "❌ 核心插件缺失:"
    for p in "${missing_core[@]}"; do printf '  - %s\n' "$p"; done
  fi

  if [ ${#missing_optional[@]} -gt 0 ]; then
    printf '%s\n' "⚠️ 可选插件缺失:"
    for p in "${missing_optional[@]}"; do printf '  - %s\n' "$p"; done
  fi

  if [ ${#missing_core[@]} -eq 0 ] && [ ${#missing_optional[@]} -eq 0 ]; then
    printf '%s\n' "✓ 所有插件已安装"
  fi

  [ ${#missing_core[@]} -eq 0 ]
}

check_skill_completeness() {
  local missing=()
  local skill_dirs=(
    "$HOME/.claude/skills"
    "$HOME/.agents/skills"
  )

  for skill in "${OPTIONAL_SKILLS[@]}"; do
    local found=false
    for dir in "${skill_dirs[@]}"; do
      if [ -d "$dir/$skill" ]; then
        found=true
        break
      fi
    done
    if [ "$found" = false ]; then
      missing+=("$skill")
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    printf '%s\n' "⚠️ 独立 Skill 缺失:"
    for s in "${missing[@]}"; do printf '  - %s\n' "$s"; done
  else
    printf '%s\n' "✓ 所有独立 Skill 已安装"
  fi

  return 0
}

check_plugin_versions() {
  local plugins_file="$HOME/.claude/plugins/installed_plugins.json"
  [ -f "$plugins_file" ] || return 1

  # Superpowers: GitHub tags version comparison
  local sp_current
  sp_current=$(jq -r '.plugins."superpowers@claude-plugins-official"[0].version // "unknown"' "$plugins_file" 2>/dev/null)
  if [ "$sp_current" != "unknown" ]; then
    local sp_latest
    sp_latest=$(timeout 10 git ls-remote --tags --sort=-v:refname https://github.com/anthropics/claude-plugins-official.git 2>/dev/null \
      | grep -oP 'refs/tags/superpowers/\K[0-9.]+' | head -1) || true
    if [ -n "$sp_latest" ] && [ "$sp_current" != "$sp_latest" ]; then
      printf '⬆ superpowers: %s → %s 可用\n' "$sp_current" "$sp_latest"
    elif [ -n "$sp_latest" ]; then
      printf '✓ superpowers: %s（最新）\n' "$sp_current"
    fi
  fi

  return 0
}

check_routing_coverage() {
  local router_file="${ROOT_DIR:-$HOME/codesop}/config/codesop-router.md"
  if [ ! -f "$router_file" ]; then
    printf '%s\n' "⚠️ 路由表不存在: $router_file"
    return 0
  fi

  local plugins_file="$HOME/.claude/plugins/installed_plugins.json"
  local missing=()

  # Extract skill names from the table's 4th column (Skill)
  # Table format: | 大类 | 优选 | 来源 | Skill | 什么时候用 |
  # With | delimiters: $1=empty, $2=大类, $3=优选, $4=来源, $5=Skill, $6=什么时候用
  while IFS= read -r line; do
    local source skill_name
    source=$(echo "$line" | awk -F'|' '{gsub(/^ +| +$/, "", $4); print $4}')
    skill_name=$(echo "$line" | awk -F'|' '{gsub(/^ +| +$/, "", $5); print $5}')

    [ -z "$skill_name" ] && continue
    # Skip headers and separators
    [[ "$skill_name" =~ ^[A-Z] ]] && continue
    [[ "$skill_name" =~ ^Skill$ ]] && continue

    # Strip codex: prefix for plugin lookup
    local lookup_name="$skill_name"
    [[ "$lookup_name" =~ ^codex: ]] && lookup_name="codex@openai-codex"

    if [ "$source" = "sp" ]; then
      # Superpowers skills — check superpowers plugin
      if [ -f "$plugins_file" ] && ! jq -e --arg id "superpowers@claude-plugins-official" '.plugins | has($id)' "$plugins_file" 2>/dev/null | grep -q true; then
        missing+=("$skill_name (需要 superpowers)")
      fi
    elif [ "$source" = "plugin" ]; then
      # Named plugin — check specific plugin
      local plugin_id
      if [[ "$lookup_name" == *@* ]]; then
        plugin_id="$lookup_name"
      else
        plugin_id="${lookup_name}@claude-plugins-official"
      fi
      if [ -f "$plugins_file" ] && ! jq -e --arg id "$plugin_id" '.plugins | has($id)' "$plugins_file" 2>/dev/null | grep -q true; then
        missing+=("$skill_name (需要 $plugin_id)")
      fi
    elif [ "$source" = "skill" ]; then
      # Independent skill — check directory
      if [ ! -d "$HOME/.claude/skills/$skill_name" ] && [ ! -d "$HOME/.agents/skills/$skill_name" ]; then
        missing+=("$skill_name (独立 Skill)")
      fi
    fi
  done < <(grep -E '^\|.*\|.*\|.*\|.*\|.*\|$' "$router_file" | grep -v '^|.*---')

  if [ ${#missing[@]} -gt 0 ]; then
    printf '%s\n' "⚠️ 路由表引用但未安装:"
    for m in "${missing[@]}"; do printf '  - %s\n' "$m"; done
  else
    printf '%s\n' "✓ 路由覆盖完整"
  fi

  return 0
}

# Extract CHANGELOG entries between two versions
# Reads CHANGELOG.md from the repo and returns entries for versions > local_version
# Arguments:
#   $1 - repo_dir or directory containing CHANGELOG.md
#   $2 - local_version (e.g. "5.0.5")
# Returns: Changelog excerpt on stdout, empty if no changelog or no entries
extract_changelog_entries() {
  local target="$1"
  local local_version="$2"
  local changelog

  # Accept either a directory (append CHANGELOG.md) or a direct file path
  if [ -f "$target" ]; then
    changelog="$target"
  elif [ -f "$target/CHANGELOG.md" ]; then
    changelog="$target/CHANGELOG.md"
  else
    return 0
  fi

  if [ "$local_version" = "unknown" ]; then
    return
  fi

  # Find the line number of the current version heading
  # Supports both "## [5.0.5]" and "## 5.0.5" and "## [5.0.5] - 2026-03-17" formats
  # Also handles git describe output like "v4.3.1-2-ge4a2375" by extracting "4.3.1"
  local clean_version
  clean_version=$(echo "$local_version" | sed 's/^v//; s/-[0-9]*-g[0-9a-f]*$//')
  local version_pattern
  version_pattern=$(echo "$clean_version" | sed 's/\./\\./g')

  local start_line
  start_line=$(grep -n "^## \[$version_pattern\]\|^## $version_pattern " "$changelog" 2>/dev/null | head -1 | cut -d: -f1) || true

  if [ -z "$start_line" ]; then
    # Current version not found in CHANGELOG — all entries are newer
    start_line=$(wc -l < "$changelog" | tr -d ' ')
  fi

  # Extract everything before the current version (i.e., newer entries)
  # Changelogs list newest first, so entries above our version are newer
  local entry
  entry=$(head -n $((start_line - 1)) "$changelog" 2>/dev/null)

  if [ -z "$entry" ]; then
    return
  fi

  # Remove top-level title line (e.g. "# Changelog") and trim trailing empty lines
  echo "$entry" | sed '1{/^# /d}' | sed -e :a -e '/^\n*$/{$d;N;};/\n$/ba'
}

# Check update status for plugin-marketplace-installed tools (e.g. superpowers).
# These lack .git directories; version is read from installed_plugins.json.
# Arguments:
#   $1 - tool name (e.g. "superpowers")
# Prints a human-readable status line with latest CHANGELOG entry.
plugin_update_check() {
  local tool="$1"
  local plugins_json="$HOME/.claude/plugins/installed_plugins.json"

  if [ ! -f "$plugins_json" ]; then
    printf '%s\n' "- $tool：无法检查（未找到插件注册信息）"
    return
  fi

  # Find the version and install path from the JSON
  local version install_path
  read -r version install_path <<< "$(jq -r --arg tool "$tool" '
    .plugins | to_entries[]
    | select(.key | contains($tool))
    | .value[0] | "\(.version // "") \(.installPath // "")"
  ' "$plugins_json" 2>/dev/null)" || true

  if [ -z "$version" ]; then
    printf '%s\n' "- $tool：无法检查（未找到版本信息）"
    return
  fi

  # Extract latest CHANGELOG entry and compare version
  local changelog
  if [ -n "$install_path" ] && [ -f "$install_path/CHANGELOG.md" ]; then
    changelog="$install_path/CHANGELOG.md"
  else
    printf '%s\n' "- $tool：$version（插件安装，已是最新）"
    return
  fi

  # Get version from latest CHANGELOG heading
  # Supports: "## [5.0.5]", "## [5.0.5] - 2026-03-17", "## 5.0.5"
  local changelog_version
  changelog_version=$(grep -m1 '^## ' "$changelog" 2>/dev/null \
    | sed -e 's/^## \[\([^]\]*\)\].*/\1/' -e 's/^## \([0-9][0-9.]*\).*/\1/' \
    | grep -E '^[0-9]+(\.[0-9]+)+$') || true

  # Compare installed version against CHANGELOG's latest heading
  # Plugin installs have no remote — CHANGELOG IS the installed copy.
  # If installed >= changelog version, user is already up to date.
  if [ -n "$changelog_version" ]; then
    local sorted
    sorted=$(printf '%s\n%s' "$version" "$changelog_version" | sort -V | tail -1)
    if [ "$sorted" = "$version" ]; then
      printf '%s\n' "- $tool：$version（插件安装，已是最新）"
      return 0
    fi
    # Installed < changelog version — shouldn't happen for plugin installs,
    # but handle gracefully: suggest update.
    printf '%s\n' "- $tool：$version → $changelog_version（插件安装，发现新版本）"
    return 1
  fi

  # No parseable version heading — assume up to date
  printf '%s\n' "- $tool：$version（插件安装，已是最新）"
  return 0
}

git_update_check() {
  local repo_dir="$1"
  local tool_name="${2:-tool}"
  local update_cmd="${3:-}"
  local ahead="0"
  local behind="0"

  if [ ! -d "$repo_dir/.git" ]; then
    printf '%s\n' "无法检查（非 git 安装）"
    return
  fi

  # Fetch latest from remote (quiet, with timeout to avoid hanging)
  timeout 10 git -C "$repo_dir" fetch --quiet 2>/dev/null || true

  # 读取本地版本
  local local_version="unknown"
  if [ -f "$repo_dir/VERSION" ]; then
    local_version=$(cat "$repo_dir/VERSION" 2>/dev/null | tr -d '[:space:]') || local_version=""
    if [ -z "$local_version" ]; then
      local_version="unknown"
    fi
  fi

  # 如果没有 VERSION 文件，尝试从 git tag 获取版本号
  if [ "$local_version" = "unknown" ]; then
    local_version=$(git -C "$repo_dir" describe --tags --always 2>/dev/null || echo "unknown")
  fi

  # 读取远程版本
  local remote_version="unknown"
  local branch upstream
  branch="$(git -C "$repo_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
  upstream="$(git -C "$repo_dir" rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || true)"

  if [ -n "$upstream" ]; then
    # 从远程分支获取 VERSION 文件（注意：pipefail 下需要 || true 避免 git show 失败导致脚本退出）
    remote_version=$(git -C "$repo_dir" show "$upstream:VERSION" 2>/dev/null | tr -d '[:space:]') || remote_version=""

    # 如果 VERSION 文件不存在或为空，尝试从 git tag 获取版本号
    if [ -z "$remote_version" ]; then
      remote_version=$(git -C "$repo_dir" describe --tags --always "$upstream" 2>/dev/null || echo "unknown")
    fi
  fi

  if [ -n "$upstream" ]; then
    read -r ahead behind <<EOF
$(git -C "$repo_dir" rev-list --left-right --count HEAD...@{u} 2>/dev/null || echo "0 0")
EOF
  fi

  if [ "${ahead:-0}" = "0" ] && [ "${behind:-0}" = "0" ]; then
    printf '%s\n' "- $tool_name：$local_version（已是最新）"
    return
  fi

  # 远端领先时，优先展示版本变化；若版本未变，则退化为“待更新提交”
  if [ "${behind:-0}" != "0" ] && [ "${ahead:-0}" = "0" ]; then
    if [ "$local_version" != "unknown" ] && [ "$remote_version" != "unknown" ] && [ "$local_version" != "$remote_version" ]; then
      printf '%s\n' "- $tool_name：$local_version → $remote_version（发现新版本）"

      # 优先从 CHANGELOG.md 提取更新内容
      local changelog_excerpt
      changelog_excerpt=$(extract_changelog_entries "$repo_dir" "$local_version")

      # 如果本地 CHANGELOG 没有更新的条目，尝试从远程获取
      if [ -z "$changelog_excerpt" ] && [ -n "$upstream" ]; then
        local remote_changelog
        remote_changelog=$(git -C "$repo_dir" show "$upstream:CHANGELOG.md" 2>/dev/null)
        if [ -n "$remote_changelog" ]; then
          local tmp_changelog
          tmp_changelog=$(mktemp)
          echo "$remote_changelog" > "$tmp_changelog"
          changelog_excerpt=$(extract_changelog_entries "$tmp_changelog" "$local_version")
          rm -f "$tmp_changelog"
        fi
      fi

      if [ -n "$changelog_excerpt" ]; then
        printf '%s\n' "  更新内容："
        echo "$changelog_excerpt" | head -n 20 | sed 's/^/    /' | sed 's/    $//'
      else
        printf '%s\n' "  更新内容（最近 3 条）："
        git -C "$repo_dir" log --oneline HEAD..@{u} 2>/dev/null | head -n 3 | sed 's/^/    - /' || true
      fi
    else
      printf '%s\n' "- $tool_name：发现 ${behind} 个待更新提交"
      git -C "$repo_dir" log --oneline HEAD..@{u} 2>/dev/null | head -n 3 | sed 's/^/    - /' || true
    fi

    if [ -n "$update_cmd" ]; then
      printf '\n  更新命令：%s\n' "$update_cmd"
    else
      printf '\n  更新命令：cd %s && git pull\n' "$repo_dir"
    fi
    return
  fi

  if [ "${ahead:-0}" != "0" ] && [ "${behind:-0}" = "0" ]; then
    printf '%s\n' "- $tool_name：本地领先上游 ${ahead} 个提交，暂不建议自动更新"
    return
  fi

  # 兜底：分叉状态
  if [ "${ahead:-0}" != "0" ] || [ "${behind:-0}" != "0" ]; then
    printf '%s\n' "- $tool_name：本地与上游已分叉（ahead=${ahead}, behind=${behind}），需人工处理"
    return
  fi

  # 无法读取 upstream 提交差异时，最后再退回到版本判断
  if [ "$local_version" != "unknown" ] && [ "$remote_version" != "unknown" ] && [ "$local_version" != "$remote_version" ]; then
    printf '%s\n' "- $tool_name：$local_version → $remote_version（发现新版本）"
    if [ -n "$update_cmd" ]; then
      printf '\n  更新命令：%s\n' "$update_cmd"
    else
      printf '\n  更新命令：cd %s && git pull\n' "$repo_dir"
    fi
    return
  fi

  if [ "$local_version" = "$remote_version" ] && [ "$local_version" != "unknown" ]; then
    printf '%s\n' "- $tool_name：发现 ${behind} 个待更新提交"
    if [ -n "$update_cmd" ]; then
      printf '\n  更新命令：%s\n' "$update_cmd"
    else
      printf '\n  更新命令：cd %s && git pull\n' "$repo_dir"
    fi
    return
  fi

  printf '%s\n' "- $tool_name：无法确认更新状态"
}

print_dependency_report() {
  local host="$1"

  printf '\n%s\n' "=== 依赖检查 ==="

  printf '%s\n' "插件完整性："
  check_plugin_completeness || true

  printf '\n%s\n' "独立 Skill："
  check_skill_completeness

  printf '\n%s\n' "版本检查："
  check_plugin_versions

  printf '\n%s\n' "路由覆盖："
  check_routing_coverage

  # Superpowers update check (keep existing git-based logic for git installs)
  if [ "$host" = "claude" ]; then
    printf '\n%s\n' "更新建议："
    local sp_path
    sp_path="$(find_superpowers_plugin_path 2>/dev/null)" || true
    if [ -n "$sp_path" ] && [ -d "$sp_path/.git" ]; then
      git_update_check "$sp_path" "superpowers" "/plugin update superpowers"
    else
      plugin_update_check "superpowers"
      printf '%s\n' "  更新命令：/plugin update superpowers"
    fi
  else
    printf '%s\n' "  插件检查仅支持 Claude Code 宿主"
  fi
}
