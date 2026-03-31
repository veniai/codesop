#!/bin/bash
# updates.sh - Version checking and update utilities for codesop
#
# This module provides functions for:
# - Checking git repository update status
# - Printing dependency update information
# - Displaying installation suggestions
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

# Scan installed skill names from gstack and superpowers
# Outputs one skill name per line: "gstack:skillname" or "superpowers:skillname"
scan_installed_skills() {
  local skill_dir skill_name

  # gstack skills
  for skill_dir in "$HOME/.claude/skills/gstack"/*/SKILL.md "$HOME/.agents/skills/gstack"/*/SKILL.md; do
    [ -f "$skill_dir" ] || continue
    skill_name="$(basename "$(dirname "$skill_dir")")"
    printf 'gstack:%s\n' "$skill_name"
  done 2>/dev/null || true

  # superpowers skills (plugin cache)
  local sp_path
  sp_path="$(find_superpowers_plugin_path 2>/dev/null)" || true
  if [ -n "$sp_path" ] && [ -d "$sp_path/skills" ]; then
    for skill_dir in "$sp_path/skills"/*/SKILL.md; do
      [ -f "$skill_dir" ] || continue
      skill_name="$(basename "$(dirname "$skill_dir")")"
      printf 'superpowers:%s\n' "$skill_name"
    done 2>/dev/null || true
  fi
}

# Extract skill names referenced in SKILL.md routing (section 6)
# Outputs one name per line (normalized to match directory names)
scan_routed_skills() {
  local skill_file="$ROOT_DIR/SKILL.md"
  [ -f "$skill_file" ] || return 0
  # Extract skill names from section 6 workflow mappings
  # Matches patterns like "skill-name (gstack)" or "skill-name (sp)"
  sed -n '/^## 6\. Workflow Mapping/,/^## 7\. Routing Policy/p' "$skill_file" \
    | { grep -oE '[a-zA-Z][a-zA-Z0-9-]+ \((gstack|sp|superpowers)\)' || true; } \
    | sed 's/ *([^)]*)$//' \
    | sort -u \
    | sed \
      -e 's/^subagent-driven-dev$/subagent-driven-development/' \
      -e 's/^verification-before-comp$/verification-before-completion/' \
      -e 's/^TDD$/test-driven-development/'
}

# Compare installed skills against routed skills, report gaps
# Returns 0 if all installed skills are routed, 1 if gaps found
check_skill_routing_coverage() {
  local installed routed missing_gstack=() missing_sp=()

  installed="$(scan_installed_skills)" || true
  routed="$(scan_routed_skills)" || true

  [ -z "$installed" ] && return 0

  while IFS= read -r line; do
    local source="${line%%:*}"
    local name="${line#*:}"
    # Skip internal/infrastructure skills that don't need routing
    case "$name" in
      gstack-upgrade|using-superpowers|connect-chrome|setup-browser-cookies| \
      plan-ceo-review|plan-design-review|plan-eng-review|browse) continue ;;
    esac
    if ! printf '%s\n' "$routed" | grep -qxF "$name"; then
      case "$source" in
        gstack) missing_gstack+=("$name") ;;
        superpowers) missing_sp+=("$name") ;;
      esac
    fi
  done <<< "$installed"

  if [ ${#missing_gstack[@]} -eq 0 ] && [ ${#missing_sp[@]} -eq 0 ]; then
    printf '%s\n' "路由覆盖：所有已安装 skill 均已收录"
    return 0
  fi

  printf '%s\n' "⚠ 路由覆盖检查：以下 skill 已安装但未收录到路由"
  if [ ${#missing_gstack[@]} -gt 0 ]; then
    printf '  gstack: %s\n' "${missing_gstack[*]}"
  fi
  if [ ${#missing_sp[@]} -gt 0 ]; then
    printf '  superpowers: %s\n' "${missing_sp[*]}"
  fi
  printf '%s\n' "  建议：更新 SKILL.md 第 6 节和 config/codesop-router.md，然后运行 bash setup --host auto"
  return 1
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

print_dependency_update_checks() {
  local host="$1"
  local superpowers_state="$2"
  local gstack_state="$3"
  local superpowers_path=""
  local gstack_path=""
  local superpowers_update_cmd=""
  local gstack_update_cmd="/gstack-upgrade"

  case "$host" in
    claude)
      superpowers_path="$(find_superpowers_plugin_path 2>/dev/null || find_first_existing_path "$HOME/.claude/plugins/superpowers" "$HOME/.codex/superpowers")" || true
      superpowers_update_cmd="/plugin update superpowers"
      gstack_path="$(find_first_existing_path "$HOME/.claude/skills/gstack" "$HOME/gstack")" || true
      ;;
    codex)
      superpowers_path="$(find_superpowers_plugin_path 2>/dev/null || find_first_existing_path "$HOME/.codex/superpowers" "$HOME/.codex/skills/.system")" || true
      superpowers_update_cmd="按 Codex 官方 superpowers 安装文档重新执行更新"
      gstack_path="$(find_first_existing_path "$HOME/.agents/skills/gstack" "$HOME/gstack" "$HOME/.claude/skills/gstack")" || true
      ;;
    opencode)
      superpowers_path="$(find_superpowers_plugin_path 2>/dev/null || find_first_existing_path "$HOME/.config/opencode/plugins/superpowers" "$HOME/.agents/skills/superpowers")" || true
      superpowers_update_cmd="按 OpenCode/OpenClaw 官方 superpowers 安装文档重新执行更新"
      gstack_path="$(find_first_existing_path "$HOME/.agents/skills/gstack" "$HOME/gstack" "$HOME/.claude/skills/gstack")" || true
      ;;
    *)
      superpowers_path="$(find_superpowers_plugin_path 2>/dev/null || find_first_existing_path "$HOME/.claude/plugins/superpowers" "$HOME/.codex/superpowers" "$HOME/.config/opencode/plugins/superpowers")" || true
      superpowers_update_cmd="按当前宿主的 superpowers 官方更新方式执行"
      gstack_path="$(find_first_existing_path "$HOME/.claude/skills/gstack" "$HOME/.agents/skills/gstack" "$HOME/gstack")" || true
      ;;
  esac

  printf '
%s
' "更新检查："

  if [ "$superpowers_state" = "installed" ] && [ -n "$superpowers_path" ]; then
    git_update_check "$superpowers_path" "superpowers"
    printf '%s\n' "  更新命令：$superpowers_update_cmd"
  elif [ "$superpowers_state" = "installed" ]; then
    printf '%s\n' "- superpowers：已安装，但当前无法定位安装目录，无法检查更新"
    printf '%s\n' "  更新命令：$superpowers_update_cmd"
  else
    printf '%s\n' "- superpowers：未安装，跳过更新检查"
  fi

  if [ "$gstack_state" = "installed" ] && [ -n "$gstack_path" ]; then
    git_update_check "$gstack_path" "gstack"
    printf '%s\n' "  更新命令：$gstack_update_cmd"
  elif [ "$gstack_state" = "partial" ]; then
    printf '%s
' "- gstack：仅检测到残留安装，先修复宿主接入，再检查更新"
  else
    printf '%s
' "- gstack：未安装，跳过更新检查"
  fi
}

print_install_suggestions() {
  local host="$1"
  local superpowers_state="$2"
  local gstack_state="$3"
  local superpowers_install=""
  local superpowers_update=""
  local gstack_install=""
  local gstack_update=""
  local gstack_repair=""

  case "$host" in
    claude)
      superpowers_install="在 Claude Code 中执行：/plugin install superpowers@claude-plugins-official"
      superpowers_update="/plugin update superpowers"
      gstack_install="git clone https://github.com/garrytan/gstack.git ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup"
      gstack_update="/gstack-upgrade"
      gstack_repair="检测到 gstack 残留，但 Claude Code 宿主接入不完整。建议执行：$gstack_install"
      ;;
    codex)
      superpowers_install="在 Codex 中执行：Fetch and follow instructions from https://raw.githubusercontent.com/obra/superpowers/refs/heads/main/.codex/INSTALL.md"
      superpowers_update="按 Codex 官方 superpowers 安装文档重新执行更新"
      gstack_install="git clone https://github.com/garrytan/gstack.git ~/gstack && cd ~/gstack && ./setup --host codex"
      gstack_update="/gstack-upgrade"
      gstack_repair="检测到 gstack 仓库或命令，但 Codex 宿主接入不完整。建议重新执行：$gstack_install"
      ;;
    opencode)
      superpowers_install="在 OpenCode/OpenClaw 中执行：Fetch and follow instructions from https://raw.githubusercontent.com/obra/superpowers/refs/heads/main/.opencode/INSTALL.md"
      superpowers_update="按 OpenCode/OpenClaw 官方 superpowers 安装文档重新执行更新"
      gstack_install="git clone https://github.com/garrytan/gstack.git ~/gstack && cd ~/gstack && ./setup --host auto"
      gstack_update="/gstack-upgrade"
      gstack_repair="检测到 gstack 仓库或命令，但 OpenCode/OpenClaw 宿主接入不完整。建议重新执行：$gstack_install"
      ;;
    *)
      superpowers_install="先安装 Claude Code、Codex 或 OpenCode/OpenClaw 之后再按对应宿主安装"
      superpowers_update="按当前宿主的 superpowers 官方更新方式执行"
      gstack_install="git clone https://github.com/garrytan/gstack.git ~/gstack && cd ~/gstack && ./setup --host auto"
      gstack_update="/gstack-upgrade"
      gstack_repair="检测到 gstack 仓库或命令，但未确认当前宿主已完成接入。建议执行：$gstack_install"
      ;;
  esac

  print_dependency_update_checks "$host" "$superpowers_state" "$gstack_state"

  printf '
%s
' "安装/修复建议："

  if [ "$superpowers_state" = "missing" ]; then
    printf '%s
' "- superpowers：$superpowers_install"
  else
    printf '%s
' "- superpowers：如需更新，执行：$superpowers_update"
  fi

  if [ "$gstack_state" = "missing" ]; then
    printf '%s
' "- gstack：$gstack_install"
  elif [ "$gstack_state" = "partial" ]; then
    printf '%s
' "- gstack：$gstack_repair"
  else
    printf '%s
' "- gstack：如需更新，执行：$gstack_update"
  fi

  printf '
%s
' "下一步："
  printf '%s
' "- 如需我继续执行安装、修复或更新，请明确指定依赖。"

  # Skill routing coverage check
  printf '
%s
' "路由覆盖："
  check_skill_routing_coverage || true
}
