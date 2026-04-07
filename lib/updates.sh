#!/bin/bash
# updates.sh - Version checking and dependency utilities for codesop v2
#
# This module provides functions for:
# - Checking plugin completeness (CORE + OPTIONAL)
# - Checking independent skill completeness
# - Checking plugin versions
# - Checking routing coverage against the router table
# - Checking current-project document drift
# - Checking codesop's own document consistency
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

# Superpowers — backbone plugin, displayed separately with version
SUPERPOWERS_PLUGIN="superpowers@claude-plugins-official"

# Required plugins — all curated, missing = warning + install command
REQUIRED_PLUGINS=(
  "code-review@claude-plugins-official"
  "skill-creator@claude-plugins-official"
  "frontend-design@claude-plugins-official"
  "context7@claude-plugins-official"
  "code-simplifier@claude-plugins-official"
  "playwright@claude-plugins-official"
  "claude-md-management@claude-plugins-official"
  "codex@openai-codex"
)

# Legacy aliases for backward compatibility
CORE_PLUGINS=("$SUPERPOWERS_PLUGIN" "${REQUIRED_PLUGINS[@]}")
OPTIONAL_PLUGINS=()

# Independent skills — missing = warning
OPTIONAL_SKILLS=(
  "codesop"
  "browser-use"
  "claude-to-im"
)

# Stale terms — removed in v2.0, should not appear in active docs
STALE_TERMS=(
  "document-release"       # gstack skill, replaced by claude-md-management
  "gstack-upgrade"         # gstack command, removed
  "codesop-setup"          # removed command
  "/codesop-setup"         # removed slash command
  "codesop status"         # removed product surface
  "codesop diagnose"       # removed product surface
)

# Active docs — scanned for stale references (excludes CHANGELOG.md, PRD.md where historical refs are ok)
DOC_SCAN_TARGETS=(
  "README.md"
  "SKILL.md"
  "templates/system/AGENTS.md"
  "config/codesop-router.md"
  "commands/codesop-init.md"
  "commands/codesop-update.md"
)

# README workflow shorthand → routing table full skill name
README_SKILL_ALIASES=(
  "brainstorming:brainstorming"
  "writing-plans:writing-plans"
  "worktree:using-git-worktrees"
  "subagent-dev:subagent-driven-development"
  "verification:verification-before-completion"
  "finishing:finishing-a-development-branch"
)

PROJECT_DOC_TARGETS=(
  "AGENTS.md"
  "PRD.md"
  "README.md"
)

check_plugin_completeness() {
  local plugins_file="$HOME/.claude/plugins/installed_plugins.json"
  local missing_required=()

  if [ ! -f "$plugins_file" ]; then
    printf '%s\n' "❌ 插件配置文件不存在: $plugins_file"
    return 1
  fi

  if ! command -v jq >/dev/null 2>&1; then
    printf '%s\n' "⚠️ jq 未安装，无法检查插件状态"
    return 1
  fi

  # --- Superpowers (backbone, displayed separately) ---
  local sp_installed=false
  local sp_version=""
  if jq -e --arg id "$SUPERPOWERS_PLUGIN" '.plugins | has($id)' "$plugins_file" 2>/dev/null | grep -q true; then
    sp_installed=true
    sp_version=$(jq -r --arg id "$SUPERPOWERS_PLUGIN" '.plugins[$id][0].version // "unknown"' "$plugins_file" 2>/dev/null) || sp_version="unknown"
  fi

  if [ "$sp_installed" = true ]; then
    printf '  ✓ superpowers: %s\n' "$sp_version"
  else
    printf '  ❌ superpowers: 未安装 — 安装: /plugin install %s\n' "$SUPERPOWERS_PLUGIN"
  fi

  # --- Required curated plugins ---
  for plugin in "${REQUIRED_PLUGINS[@]}"; do
    if ! jq -e --arg id "$plugin" '.plugins | has($id)' "$plugins_file" 2>/dev/null | grep -q true; then
      missing_required+=("$plugin")
    fi
  done

  if [ ${#missing_required[@]} -eq 0 ]; then
    printf '  ✓ 必选插件: %d/%d 已安装\n' "${#REQUIRED_PLUGINS[@]}" "${#REQUIRED_PLUGINS[@]}"
  else
    local installed_count=$(( ${#REQUIRED_PLUGINS[@]} - ${#missing_required[@]} ))
    printf '  ❌ 必选插件: %d/%d 已安装\n' "$installed_count" "${#REQUIRED_PLUGINS[@]}"

    # Split into official vs third-party
    local missing_official=() missing_thirdparty=()
    for p in "${missing_required[@]}"; do
      if [[ "$p" == *@claude-plugins-official ]]; then
        missing_official+=("$p")
      else
        missing_thirdparty+=("$p")
      fi
    done

    # Official marketplace plugins
    if [ ${#missing_official[@]} -gt 0 ]; then
      printf '%s\n' "  官方仓库:"
      for p in "${missing_official[@]}"; do
        local short_name="${p%@claude-plugins-official}"
        printf '    %-30s /plugin install %s\n' "$short_name" "$p"
      done
      printf '%s\n' "  一键安装官方插件:"
      printf '    '
      local first=true
      for p in "${missing_official[@]}"; do
        if [ "$first" = true ]; then first=false; else printf ' && '; fi
        printf '/plugin install %s' "$p"
      done
      printf '\n'
    fi

    # Third-party plugins with repo URLs
    if [ ${#missing_thirdparty[@]} -gt 0 ]; then
      printf '%s\n' "  第三方仓库:"
      for p in "${missing_thirdparty[@]}"; do
        case "$p" in
          codex@openai-codex)
            printf '    codex              https://github.com/openai/codex-plugin-cc\n'
            printf '    安装               /plugin marketplace add openai/codex-plugin-cc\n'
            printf '                       /plugin install codex@openai-codex\n'
            printf '    注意               安装后如有重复 MCP server（如 codex），检查 ~/.claude/settings.json 移除重复项\n'
            ;;
          *)
            printf '    %-20s 未知来源，请搜索官方仓库\n' "$p"
            ;;
        esac
      done
    fi
  fi

  [ "$sp_installed" = true ] && [ ${#missing_required[@]} -eq 0 ]
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
    printf '%s\n' "  安装来源:"
    for s in "${missing[@]}"; do
      case "$s" in
        codesop)
          printf '    %-20s https://github.com/veniai/codesop\n' "codesop"
          printf '    %-20s git clone https://github.com/veniai/codesop.git ~/codesop && bash ~/codesop/setup --host auto\n' "安装:"
          ;;
        browser-use)
          printf '    %-20s https://github.com/browser-use/browser-use\n' "browser-use"
          printf '    %-20s pip install browser-use && browser-use doctor\n' "安装:"
          printf '    %-20s 安装后如有重复 MCP server，检查 ~/.claude/settings.json 移除重复项\n' "注意:"
          ;;
        claude-to-im)
          printf '    %-20s 搜索 claude-to-im 获取最新安装方式\n' "claude-to-im"
          ;;
        *)
          printf '    %-20s 请手动安装到 ~/.claude/skills/%s/\n' "$s" "$s"
          ;;
      esac
    done
    printf '%s\n' "  提示: 将以上命令发送给 AI 助手即可自动安装"
  else
    printf '%s\n' "✓ 所有独立 Skill 已安装"
  fi

  return 0
}

check_plugin_versions() {
  local plugins_file="$HOME/.claude/plugins/installed_plugins.json"
  [ -f "$plugins_file" ] || return 1

  # List installed plugin versions (informational)
  local plugin_id version
  while IFS=$'\t' read -r plugin_id version; do
    [ -z "$plugin_id" ] && continue
    printf '  %s: %s\n' "$plugin_id" "${version:-unknown}"
  done < <(jq -r '.plugins | to_entries[] | "\(.key)\t\(.value[0].version // "")"' "$plugins_file" 2>/dev/null)

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
  local plugins_checkable=true

  # If plugins file is missing, we can only check skills, not plugins
  if [ ! -f "$plugins_file" ]; then
    plugins_checkable=false
  fi

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
      if [ "$plugins_checkable" = false ]; then
        missing+=("$skill_name (无法检查: 插件文件缺失)")
      elif ! jq -e --arg id "$SUPERPOWERS_PLUGIN" '.plugins | has($id)' "$plugins_file" 2>/dev/null | grep -q true; then
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
      if [ "$plugins_checkable" = false ]; then
        missing+=("$skill_name (无法检查: 插件文件缺失)")
      elif ! jq -e --arg id "$plugin_id" '.plugins | has($id)' "$plugins_file" 2>/dev/null | grep -q true; then
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
    printf '%s\n' "⚠️ 路由覆盖不完整 (${#missing[@]} 个条目缺失):"
    for m in "${missing[@]}"; do
      printf '  - %s\n' "$m"
    done
  else
    printf '%s\n' "✓ 路由覆盖完整"
  fi

  return 0
}

check_project_document_drift() {
  local project_root="${PROJECT_ROOT:-$(pwd)}"
  local doc_path doc missing=() present=()

  for doc in "${PROJECT_DOC_TARGETS[@]}"; do
    doc_path="$project_root/$doc"
    if [ -f "$doc_path" ]; then
      present+=("$doc")
    else
      missing+=("$doc")
    fi
  done

  if [ ${#missing[@]} -gt 0 ]; then
    printf '%s\n' "⚠️ 当前项目文档缺失: $(IFS=', '; echo "${missing[*]}")"
  else
    printf '%s\n' "✓ 当前项目核心文档存在: $(IFS=', '; echo "${present[*]}")"
  fi

  if [ -f "$project_root/AGENTS.md" ]; then
    local ref_line ref_target
    ref_line="$(sed -n '1p' "$project_root/AGENTS.md" 2>/dev/null || true)"
    if [[ "$ref_line" =~ ^@(.+) ]]; then
      ref_target="${BASH_REMATCH[1]}"
      ref_target="${ref_target#./}"
      if [ ! -f "$project_root/$ref_target" ]; then
        printf '%s\n' "⚠️ AGENTS.md 引用了 $ref_target，但目标文件不存在"
      fi
    fi
  fi

  if [ ! -d "$project_root/.git" ]; then
    printf '%s\n' "⚠️ 当前项目不是 git 仓库，无法判断文档漂移"
    return 0
  fi

  local changed_doc_count=0 changed_non_doc_count=0
  local changed_docs=()
  local line path
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    path="$(printf '%s' "$line" | sed 's/^...//')"
    [[ "$path" == *" -> "* ]] && path="${path##* -> }"
    case "$path" in
      AGENTS.md|CLAUDE.md|PRD.md|README.md)
        changed_doc_count=$((changed_doc_count + 1))
        changed_docs+=("$path")
        ;;
      *)
        changed_non_doc_count=$((changed_non_doc_count + 1))
        ;;
    esac
  done < <(git -C "$project_root" status --short 2>/dev/null || true)

  if [ "$changed_non_doc_count" -gt 0 ] && [ "$changed_doc_count" -eq 0 ]; then
    printf '%s\n' "⚠️ 当前项目可能存在文档漂移: ${changed_non_doc_count} 个非文档文件已变更，但核心文档未更新"
  elif [ "$changed_doc_count" -gt 0 ]; then
    printf '%s\n' "✓ 当前修改已包含文档更新: $(IFS=', '; echo "${changed_docs[*]}")"
  else
    printf '%s\n' "✓ 当前项目未见文档漂移信号"
  fi

  return 0
}

check_codesop_document_consistency() {
  local root="${ROOT_DIR:-$HOME/codesop}"
  local version_file="${VERSION_FILE:-$root/VERSION}"

  # --- A: Version alignment ---
  local ver_file="" ver_json="" ver_prd=""

  if [ -f "$version_file" ]; then
    ver_file="$(tr -d '[:space:]' < "$version_file")" || true
  fi

  if [ -f "$root/skill.json" ]; then
    if command -v jq >/dev/null 2>&1; then
      ver_json="$(jq -r '.version // ""' "$root/skill.json" 2>/dev/null)" || ver_json=""
    else
      # Fallback: parse version with grep when jq unavailable
      ver_json="$(grep -m1 '"version"' "$root/skill.json" 2>/dev/null | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' | tr -d '[:space:]')" || ver_json=""
    fi
  fi

  if [ -f "$root/PRD.md" ]; then
    ver_prd="$(grep -m1 '^# Current Version:' "$root/PRD.md" 2>/dev/null | sed 's/^# Current Version: //' | tr -d '[:space:]')" || ver_prd=""
  fi

  if [ -n "$ver_file" ] && [ "$ver_file" = "$ver_json" ] && [ "$ver_file" = "$ver_prd" ]; then
    printf '%s\n' "✓ 版本对齐: VERSION=$ver_file skill.json=$ver_json PRD.md=$ver_prd"
  else
    printf '%s\n' "⚠️ 版本不一致: VERSION=${ver_file:-<missing>} skill.json=${ver_json:-<missing>} PRD.md=${ver_prd:-<missing>}"
  fi

  # --- B: Stale reference scan ---
  local stale_hits=()
  local target term file_path
  for target in "${DOC_SCAN_TARGETS[@]}"; do
    file_path="$root/$target"
    [ -f "$file_path" ] || continue
    for term in "${STALE_TERMS[@]}"; do
      if grep -q "$term" "$file_path" 2>/dev/null; then
        stale_hits+=("$target: '$term'")
      fi
    done
  done

  if [ ${#stale_hits[@]} -gt 0 ]; then
    printf '%s\n' "⚠️ 过时引用:"
    for hit in "${stale_hits[@]}"; do printf '  - %s\n' "$hit"; done
  else
    printf '%s\n' "✓ 无过时引用"
  fi

  # --- C: Contract consistency (README aliases → routing table) ---
  local router_file="$root/config/codesop-router.md"
  local readme_file="$root/README.md"
  local contract_issues=()

  if [ ! -f "$router_file" ]; then
    contract_issues+=("路由表缺失: $router_file")
  elif [ ! -f "$readme_file" ]; then
    contract_issues+=("README 缺失: $readme_file")
  else
    # Build set of routing table skill names
    local -a router_skills=()
    local line skill_name
    while IFS= read -r line; do
      skill_name="$(echo "$line" | awk -F'|' '{gsub(/^ +| +$/, "", $5); print $5}')"
      [ -z "$skill_name" ] && continue
      [[ "$skill_name" =~ ^[A-Z] ]] && continue
      [[ "$skill_name" =~ ^\* ]] && continue
      router_skills+=("$skill_name")
    done < <(grep -E '^\|.*\|.*\|.*\|.*\|.*\|$' "$router_file" | grep -v '^|.*---')

    # For each README alias, verify the resolved full name exists in routing table
    local mapping alias full found rs
    for mapping in "${README_SKILL_ALIASES[@]}"; do
      alias="${mapping%%:*}"
      full="${mapping#*:}"
      found=false
      for rs in "${router_skills[@]}"; do
        if [ "$full" = "$rs" ]; then
          found=true
          break
        fi
      done
      if [ "$found" = false ]; then
        contract_issues+=("别名 '$alias' → '$full' 不在路由表中")
      fi
    done

    # Check README mentions each alias at least once
    for mapping in "${README_SKILL_ALIASES[@]}"; do
      alias="${mapping%%:*}"
      if ! grep -q "$alias" "$readme_file" 2>/dev/null; then
        contract_issues+=("README 未提及别名 '$alias'")
      fi
    done
  fi

  if [ ${#contract_issues[@]} -gt 0 ]; then
    printf '%s\n' "⚠️ 契约不一致:"
    for ci in "${contract_issues[@]}"; do printf '  - %s\n' "$ci"; done
  else
    printf '%s\n' "✓ 契约一致"
  fi

  return 0
}

check_document_consistency() {
  check_codesop_document_consistency "$@"
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

  printf '\n%s\n' "路由覆盖："
  check_routing_coverage

  printf '\n%s\n' "文档一致性："
  check_document_consistency

  # Superpowers update check
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
  fi
}
