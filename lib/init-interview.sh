#!/bin/bash
# init-interview.sh - Tool detection and system-level symlink management
#
# This module provides functions for:
# - Detecting installed AI coding tools
# - Setting up system-level symbolic links
# - Checking if user preferences already exist in templates
# - Detecting placeholder patterns in template files
#
# Usage: source this file from another bash script
#   source /path/to/lib/init-interview.sh

# Check if user preferences already exist
# Returns 0 if preferences exist (skip interview), 1 if interview is needed
check_user_preferences() {
  local template_file="$1"  # templates/system/AGENTS.md

  if [ -f "$template_file" ]; then
    if has_user_preferences "$template_file"; then
      echo "用户偏好已存在，跳过面试"
      return 0
    fi
  fi
  return 1  # Need interview
}

# Detect if template file contains user preferences (not placeholders)
# Placeholder format: {LANG}, {STYLE}, {FUNC_LENGTH}, {COMMENT_STYLE}
# Returns 0 if preferences exist (no placeholders found), 1 if placeholders exist
has_user_preferences() {
  local template_file="$1"

  # Validate input
  if [ -z "$template_file" ]; then
    return 1
  fi

  if [ ! -f "$template_file" ]; then
    return 1
  fi

  # If file contains {LANG} etc placeholders, user preferences not yet filled
  if grep -q '{LANG}\|{STYLE}\|{FUNC_LENGTH}\|{COMMENT_STYLE}' "$template_file"; then
    return 1  # Has placeholders, needs interview
  fi
  return 0  # Real preferences filled in
}

# ============================================================================
# Tool Detection
# ============================================================================

# Detect installed AI coding tools
# Returns: Space-separated list of installed tool names
# Example: "claude codex opencode"
detect_installed_tools() {
  local installed=""

  # Claude Code: check for ~/.claude directory
  if [ -d "$HOME/.claude" ]; then
    installed="${installed}claude "
  fi

  # Codex: check for ~/.codex directory
  if [ -d "$HOME/.codex" ]; then
    installed="${installed}codex "
  fi

  # OpenCode: check for ~/.config/opencode directory
  if [ -d "$HOME/.config/opencode" ]; then
    installed="${installed}opencode "
  fi

  # Trim trailing space and return
  echo "${installed%" "}"
}

# Check if a specific tool is installed
# Arguments:
#   $1 - Tool name (claude, codex, opencode)
# Returns: 0 if installed, 1 if not
is_tool_installed() {
  local tool="$1"

  case "$tool" in
    claude)
      [ -d "$HOME/.claude" ]
      return $?
      ;;
    codex)
      [ -d "$HOME/.codex" ]
      return $?
      ;;
    opencode)
      [ -d "$HOME/.config/opencode" ]
      return $?
      ;;
    *)
      return 1
      ;;
  esac
}

# Get list of all supported tools
# Returns: Space-separated list of all tool names
get_supported_tools() {
  echo "claude codex opencode"
}

# ============================================================================
# System-Level Symlink Management
# ============================================================================

# Create symbolic link with directory creation
# Arguments:
#   $1 - Source file path
#   $2 - Target symlink path
ensure_symlink() {
  local src="$1"
  local dst="$2"

  mkdir -p "$(dirname "$dst")"
  ln -sfn "$src" "$dst"
}

# Set up system-level symbolic links for all detected tools
# Arguments:
#   $1 - codesop source directory (absolute path)
# Returns: 0 on success, non-zero on failure
setup_system_links() {
  local source_dir="$1"
  local template_file="templates/system/AGENTS.md"
  local template_path="$source_dir/$template_file"
  local errors=0

  # Validate source directory
  if [ ! -d "$source_dir" ]; then
    echo "Error: Source directory does not exist: $source_dir" >&2
    return 1
  fi

  # Check if template file exists
  if [ ! -f "$template_path" ]; then
    echo "Warning: Template file not found: $template_path" >&2
    echo "Using root AGENTS.md as fallback" >&2
    template_path="$source_dir/AGENTS.md"
  fi

  # Detect which tools are installed
  local tools
  tools=$(detect_installed_tools)

  if [ -z "$tools" ]; then
    echo "No AI tools detected. Skipping system link setup."
    return 0
  fi

  echo "Detected tools: $tools"
  echo "Setting up system-level links..."

  # Claude Code: ~/.claude/CLAUDE.md
  if echo "$tools" | grep -q "claude"; then
    local claude_target="$HOME/.claude/CLAUDE.md"
    if ensure_symlink "$template_path" "$claude_target"; then
      echo "  ✓ Claude Code: $claude_target"
    else
      echo "  ✗ Failed to link for Claude Code" >&2
      errors=$((errors + 1))
    fi
  fi

  # Codex: ~/.codex/AGENTS.md
  if echo "$tools" | grep -q "codex"; then
    local codex_target="$HOME/.codex/AGENTS.md"
    if ensure_symlink "$template_path" "$codex_target"; then
      echo "  ✓ Codex: $codex_target"
    else
      echo "  ✗ Failed to link for Codex" >&2
      errors=$((errors + 1))
    fi
  fi

  # OpenCode: ~/.config/opencode/AGENTS.md
  if echo "$tools" | grep -q "opencode"; then
    local opencode_target="$HOME/.config/opencode/AGENTS.md"
    if ensure_symlink "$template_path" "$opencode_target"; then
      echo "  ✓ OpenCode: $opencode_target"
    else
      echo "  ✗ Failed to link for OpenCode" >&2
      errors=$((errors + 1))
    fi
  fi

  if [ $errors -gt 0 ]; then
    return 1
  fi

  return 0
}

# ============================================================================
# Skill Dependency Checking
# ============================================================================

# Skill/ECOSYSTEM registry for detection
# Format: "name:path1,path2,..."
SKILL_REGISTRY=(
  "superpowers:$HOME/.claude/skills/superpowers,$HOME/.agents/skills/superpowers,$HOME/.claude/plugins/superpowers,$HOME/.codex/superpowers,$HOME/.codex/skills/.system,$HOME/.config/opencode/plugins/superpowers"
  "gstack:$HOME/.claude/skills/gstack,$HOME/.agents/skills/gstack,$HOME/.config/opencode/skills/gstack,$HOME/.codex/skills/gstack"
)

# Detect if superpowers is installed
# Returns: 0 if installed, 1 if not
has_superpowers() {
  local entry="${SKILL_REGISTRY[0]}"
  local paths="${entry#*:}"

  local IFS=','
  for path in $paths; do
    if [ -d "$path" ]; then
      return 0
    fi
  done

  # Additional check for command-based installation
  [ -f "$HOME/.claude/commands/brainstorming.md" ]
}

# Detect if gstack is installed
# Returns: 0 if installed, 1 if not
has_gstack() {
  local entry="${SKILL_REGISTRY[1]}"
  local paths="${entry#*:}"

  local IFS=','
  for path in $paths; do
    if [ -d "$path" ]; then
      return 0
    fi
  done

  # Check for gstack command
  command -v gstack &>/dev/null
}

# Check skill dependencies and print status
# Checks multiple installation locations (Claude Code + Codex)
check_skill_dependencies() {
  echo ""
  echo "=== 技能依赖检查 ==="

  if declare -f git_update_check &>/dev/null; then
    _check_skills_all
  else
    echo "⚠ 更新检查不可用（lib/updates.sh 未加载）"
    if ! has_superpowers; then
      echo "⚠ superpowers 未安装"
    else
      echo "✓ superpowers 已安装"
    fi
    if ! has_gstack; then
      echo "⚠ gstack 未安装"
    else
      echo "✓ gstack 已安装"
    fi
  fi
}

# Check all skill installations across Claude Code and Codex
_check_skills_all() {
  local sp_found=0

  # superpowers: Claude Code plugin cache (check all marketplaces, skip orphaned)
  local cc_plugin cc_marketplace
  for cc_marketplace in "$HOME/.claude/plugins/cache/claude-plugins-official/superpowers" \
                       "$HOME/.claude/plugins/cache/superpowers-marketplace/superpowers"; do
    cc_plugin=$(find "$cc_marketplace" -maxdepth 1 -type d 2>/dev/null | sort -V | tail -1)
    if [ -n "$cc_plugin" ] && [ "$cc_plugin" != "$cc_marketplace" ]; then
      # Skip orphaned plugins
      if [ -f "$cc_plugin/.orphaned_at" ]; then continue; fi
      printf '  %-14s %s（Claude Code 插件）\n' "superpowers:" "$(basename "$cc_plugin")"
      _check_changelog "$cc_plugin" "$(basename "$cc_plugin")" "/plugin update superpowers"
      sp_found=1
      break  # Only report the first non-orphaned plugin
    fi
  done

  # superpowers: Codex git repos
  for codex_sp in "$HOME/.codex/superpowers" "$HOME/.agents/skills/superpowers"; do
    if [ -d "$codex_sp/.git" ]; then
      local codex_ver codex_label
      codex_ver=$(cat "$codex_sp/VERSION" 2>/dev/null | tr -d '[:space:]') || codex_ver=""
      [ -z "$codex_ver" ] && codex_ver=$(git -C "$codex_sp" describe --tags --always 2>/dev/null || echo "unknown")
      codex_label="Codex"
      [ "$codex_sp" = "$HOME/.agents/skills/superpowers" ] && codex_label="Codex (agents)"
      printf '  %-14s %s（%s）\n' "superpowers:" "$codex_ver" "$codex_label"
      git_update_check "$codex_sp" "superpowers ($codex_label)" "cd $codex_sp && git pull"
      sp_found=1
    fi
  done

  if [ $sp_found -eq 0 ]; then
    echo "⚠ superpowers 未安装"
    echo "  安装命令：/plugin install superpowers"
  fi

  # gstack: shared across tools
  local gs_found=0
  for gs_path in "$HOME/.claude/skills/gstack" "$HOME/.agents/skills/gstack" "$HOME/.codex/skills/gstack"; do
    if [ -d "$gs_path" ]; then
      gs_found=1
      local gs_ver gs_label
      gs_ver="unknown"
      [ -f "$gs_path/VERSION" ] && gs_ver=$(cat "$gs_path/VERSION" | tr -d '[:space:]') || true
      gs_label="Claude Code"
      [ "$gs_path" = "$HOME/.agents/skills/gstack" ] && gs_label="Codex (agents)"
      [ "$gs_path" = "$HOME/.codex/skills/gstack" ] && gs_label="Codex"
      printf '  %-14s %s（%s）\n' "gstack:" "$gs_ver" "$gs_label"
      if [ -d "$gs_path/.git" ]; then
        git_update_check "$gs_path" "gstack ($gs_label)" "/gstack-upgrade"
      else
        _check_changelog "$gs_path" "$gs_ver" "/gstack-upgrade"
      fi
    fi
  done

  if [ $gs_found -eq 0 ]; then
    echo "⚠ gstack 未安装"
    echo "  安装：git clone https://github.com/garrytan/gstack.git ~/.claude/skills/gstack"
  fi
}

# Print CHANGELOG update for non-git installations (plugin cache)
_check_changelog() {
  local tool_dir="$1"
  local current_ver="$2"
  local update_cmd="$3"

  if [ -z "$current_ver" ] || [ "$current_ver" = "unknown" ]; then
    return
  fi

  local latest_ver
  latest_ver=$(grep -oP '\[\K[0-9]+\.[0-9]+\.[0-9]+' "$tool_dir/CHANGELOG.md" 2>/dev/null | head -1)
  [ -z "$latest_ver" ] && return

  if [ "$current_ver" = "$latest_ver" ]; then
    echo "  已是最新"
    return
  fi

  # Compare versions: if current >= latest, it's up to date
  local higher_ver
  higher_ver=$(printf '%s\n%s\n' "$current_ver" "$latest_ver" | sort -V | tail -1)
  if [ "$higher_ver" = "$current_ver" ]; then
    echo "  已是最新"
    return
  fi

  echo "  → 发现新版本: $latest_ver"
  local excerpt
  excerpt=$(extract_changelog_entries "$tool_dir" "$current_ver")
  if [ -n "$excerpt" ]; then
    echo "  更新内容："
    echo "$excerpt" | head -n 20 | sed 's/^/    /' | sed 's/    $//'
  fi
  echo "  更新命令：$update_cmd"
}

# ============================================================================
# Project-Level File Processing
# ============================================================================

# Detect if AGENTS.md is a simple reference (only contains @CLAUDE.md)
# Arguments:
#   $1 - File path to check
# Returns: 0 if simple reference, 1 otherwise
is_simple_reference() {
  local file="$1"

  # Validate input
  if [ -z "$file" ]; then
    return 1
  fi

  if [ ! -f "$file" ]; then
    return 1
  fi

  local content
  content=$(cat "$file" | tr -d '[:space:]')

  # Check if content is exactly @CLAUDE.md or @./CLAUDE.md
  [ "$content" = "@CLAUDE.md" ] || [ "$content" = "@./CLAUDE.md" ]
}

# Detect if PRD.md is a living document format
# Living documents have sections like "当前快照", "Current Snapshot", "工作日志", "Work Log"
# Arguments:
#   $1 - File path to check
# Returns: 0 if living PRD, 1 otherwise
is_living_prd() {
  local file="$1"

  # Validate input
  if [ -z "$file" ]; then
    return 1
  fi

  if [ ! -f "$file" ]; then
    return 1
  fi

  # Living document features: has "当前快照" or "Current Snapshot" or "工作日志" sections
  grep -qi "当前快照\|current snapshot\|工作日志\|work log" "$file"
}

# Detect if CLAUDE.md has system-level references
# System references: @~/.claude/CLAUDE.md, @~/.codex/AGENTS.md
# Arguments:
#   $1 - File path to check
# Returns: 0 if has system reference, 1 otherwise
has_system_reference() {
  local file="$1"

  if [ -z "$file" ] || [ ! -f "$file" ]; then
    return 1
  fi

  grep -q "@~/.claude/CLAUDE.md\|@~/.codex/AGENTS.md" "$file"
}

# Ensure CLAUDE_CODE_NEW_INIT is set in ~/.claude/settings.json under env key
# This enables the new interview-based /init in Claude Code
# Returns: 0 on success (or already set), 1 on failure
ensure_new_init_env() {
  local settings_file="$HOME/.claude/settings.json"

  if [ ! -f "$settings_file" ]; then
    echo '{"env":{"CLAUDE_CODE_NEW_INIT":"1"}}' > "$settings_file"
    echo "  ✓ 创建 settings.json 并启用 NEW_INIT"
    return 0
  fi

  # Check if env.CLAUDE_CODE_NEW_INIT already exists
  if grep -q '"env"' "$settings_file" && grep -q '"CLAUDE_CODE_NEW_INIT"' "$settings_file"; then
    echo "  ✓ CLAUDE_CODE_NEW_INIT 已设置"
    return 0
  fi

  # Use python3 to safely add env key
  if command -v python3 &>/dev/null; then
    python3 -c "
import json, sys
with open('$settings_file') as f:
    data = json.load(f)
if 'env' not in data:
    data['env'] = {}
data['env']['CLAUDE_CODE_NEW_INIT'] = '1'
with open('$settings_file', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
" 2>/dev/null
    if [ $? -eq 0 ]; then
      echo "  ✓ 已启用 CLAUDE_CODE_NEW_INIT"
      return 0
    fi
  fi

  echo "  ⚠ 无法自动设置 CLAUDE_CODE_NEW_INIT，请手动添加到 $settings_file" >&2
  return 1
}

# Confirm with user and backup file before overwriting
# Arguments:
#   $1 - File path to backup
# Returns: 0 if confirmed and backed up, 1 if user declined
confirm_and_backup() {
  local file="$1"

  # Validate input
  if [ -z "$file" ]; then
    echo "Error: No file path provided" >&2
    return 1
  fi

  if [ ! -f "$file" ]; then
    echo "Error: File does not exist: $file" >&2
    return 1
  fi

  local backup="${file}.bak.$(date +%Y%m%d%H%M%S)"

  echo "文件 $file 已存在"
  read -p "是否备份并继续？[y/N]: " confirm

  if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
    if cp "$file" "$backup"; then
      echo "✓ 已备份到 $backup"
      return 0
    else
      echo "Error: Failed to create backup" >&2
      return 1
    fi
  fi

  return 1
}

# Generate PRD template content from external template file
# Arguments:
#   $1 - Project name (optional, defaults to "项目")
# Returns: PRD template content on stdout
generate_prd_template() {
  local project_name="${1:-项目}"
  local date_today
  date_today=$(date +%F)
  local template_file="${source_dir:-.}/templates/project/PRD.md"

  if [ -f "$template_file" ]; then
    sed "s/{PROJECT_NAME}/$project_name/g; s/{DATE}/$date_today/g" "$template_file"
  else
    echo "Error: PRD template not found: $template_file" >&2
    return 1
  fi
}

# Generate README template content from external template file
# Arguments:
#   $1 - Project name (optional, defaults to "项目")
# Returns: README template content on stdout
generate_readme_template() {
  local project_name="${1:-项目}"
  local template_file="${source_dir:-.}/templates/project/README.md"

  if [ -f "$template_file" ]; then
    sed "s/{PROJECT_NAME}/$project_name/g" "$template_file"
  else
    echo "Error: README template not found: $template_file" >&2
    return 1
  fi
}

# ============================================================================
# User Preference Interview
# ============================================================================

# Check if running in interactive terminal
# Returns: 0 if interactive, 1 if not
is_interactive() {
  [ -t 0 ]
}

# Interview user for coding preferences
# Arguments:
#   $1 - Template file path (templates/system/AGENTS.md)
# Returns: 0 on success, 1 on failure
interview_user_preferences() {
  local template_file="$1"

  # Validate template file exists
  if [ -z "$template_file" ]; then
    echo "Error: Template file path is required" >&2
    return 1
  fi

  if [ ! -f "$template_file" ]; then
    echo "Error: Template file not found: $template_file" >&2
    return 1
  fi

  # Check if file is writable
  if [ ! -w "$template_file" ]; then
    echo "Error: Template file is not writable: $template_file" >&2
    return 1
  fi

  # Check if running interactively
  if ! is_interactive; then
    echo "⚠ 非交互式终端，跳过面试（使用默认偏好）"
    echo "  提示：在终端中运行 'codesop init' 进行偏好设置"
    # Use default values
    local lang="中文"
    local style="标准"
    local func_length="建议 <= 50 行"
    local comment_style="必要才注释"

    # Replace template variables
    local temp_file
    temp_file=$(mktemp)
    sed -e "s/{LANG}/$lang/g" \
        -e "s/{STYLE}/$style/g" \
        -e "s/{FUNC_LENGTH}/$func_length/g" \
        -e "s/{COMMENT_STYLE}/$comment_style/g" \
        "$template_file" > "$temp_file"
    mv "$temp_file" "$template_file"

    echo "✓ 已使用默认偏好"
    return 0
  fi

  echo "=== 用户偏好面试 ==="
  echo "这将帮助我生成适合你的系统级 AI 编码契约"
  echo ""

  # Question 1: Default language
  echo "1. 你希望 AI 默认使用什么语言？"
  echo "   [1] 中文"
  echo "   [2] English"
  read -p "选择 [1-2]: " lang_choice
  local lang="中文"
  [ "$lang_choice" = "2" ] && lang="English"

  # Question 2: Code style
  echo ""
  echo "2. 你的代码风格偏好？"
  echo "   [1] 简洁 - 最少代码完成功能"
  echo "   [2] 标准 - 平衡可读性和简洁性"
  echo "   [3] 详细 - 充分注释和类型"
  read -p "选择 [1-3]: " style_choice
  local style="标准"
  [ "$style_choice" = "1" ] && style="简洁"
  [ "$style_choice" = "3" ] && style="详细"

  # Question 3: Function length preference
  echo ""
  echo "3. 函数长度偏好？"
  echo "   [1] 无限制"
  echo "   [2] 建议 <= 50 行"
  echo "   [3] 建议 <= 25 行"
  read -p "选择 [1-3]: " func_choice
  local func_length="无限制"
  [ "$func_choice" = "2" ] && func_length="建议 <= 50 行"
  [ "$func_choice" = "3" ] && func_length="建议 <= 25 行"

  # Question 4: Comment style
  echo ""
  echo "4. 代码注释风格？"
  echo "   [1] 必要才注释"
  echo "   [2] 标准注释"
  echo "   [3] 详细注释"
  read -p "选择 [1-3]: " comment_choice
  local comment_style="必要才注释"
  [ "$comment_choice" = "2" ] && comment_style="标准注释"
  [ "$comment_choice" = "3" ] && comment_style="详细注释"

  # Replace template variables using sed
  # Use temporary file for safe in-place editing (compatible with BSD and GNU sed)
  local temp_file
  temp_file=$(mktemp)
  if [ $? -ne 0 ]; then
    echo "Error: Failed to create temporary file" >&2
    return 1
  fi

  # Perform variable replacements
  sed -e "s/{LANG}/$lang/g" \
      -e "s/{STYLE}/$style/g" \
      -e "s/{FUNC_LENGTH}/$func_length/g" \
      -e "s/{COMMENT_STYLE}/$comment_style/g" \
      "$template_file" > "$temp_file"

  if [ $? -ne 0 ]; then
    echo "Error: Failed to replace template variables" >&2
    rm -f "$temp_file"
    return 1
  fi

  # Move temp file to replace original
  mv "$temp_file" "$template_file"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to update template file" >&2
    rm -f "$temp_file"
    return 1
  fi

  echo ""
  echo "✓ 用户偏好已保存到 $template_file"

  return 0
}

# ============================================================================
# Main Entry Functions
# ============================================================================

# Global variable to track cleanup state
_INIT_INTERVIEW_INTERRUPTED=0

# Cleanup handler for user interruption
_init_interview_cleanup() {
  if [ $_INIT_INTERVIEW_INTERRUPTED -eq 1 ]; then
    echo ""
    echo "=== 初始化被用户中断 ==="
    echo "你可以稍后重新运行初始化流程"
  fi
}

# Generate project-level files
# Arguments:
#   $1 - Target directory (defaults to current directory)
# Returns: 0 on success, non-zero on failure
generate_project_files() {
  local target_dir="${1:-.}"
  local original_dir
  original_dir=$(pwd)

  # Validate target directory
  if [ ! -d "$target_dir" ]; then
    echo "Error: Target directory does not exist: $target_dir" >&2
    return 1
  fi

  # Change to target directory
  cd "$target_dir" || {
    echo "Error: Cannot change to directory: $target_dir" >&2
    return 1
  }

  # 1. AGENTS.md - should be a simple reference to CLAUDE.md
  if [ -f ./AGENTS.md ]; then
    if ! is_simple_reference ./AGENTS.md; then
      echo "AGENTS.md 已存在且不是简单引用"
      if confirm_and_backup ./AGENTS.md; then
        echo "@CLAUDE.md" > ./AGENTS.md
        echo "✓ 更新 AGENTS.md"
      else
        echo "跳过 AGENTS.md 更新（运行 /init 生成 CLAUDE.md 后，可将 AGENTS.md 改为 @CLAUDE.md）"
      fi
    else
      echo "✓ AGENTS.md 已是简单引用格式"
    fi
  else
    echo "@CLAUDE.md" > ./AGENTS.md
    echo "✓ 创建 AGENTS.md"
  fi

  # 2. PRD.md - living document format
  if [ -f ./PRD.md ]; then
    if ! is_living_prd ./PRD.md; then
      echo "PRD.md 已存在但不是活文档格式"
      if confirm_and_backup ./PRD.md; then
        # Extract project name from directory
        local project_name
        project_name=$(basename "$(pwd)")
        generate_prd_template "$project_name" > ./PRD.md
        echo "✓ 更新 PRD.md"
      else
        echo "跳过 PRD.md 更新"
      fi
    else
      echo "✓ PRD.md 已是活文档格式"
    fi
  else
    # Extract project name from directory
    local project_name
    project_name=$(basename "$(pwd)")
    generate_prd_template "$project_name" > ./PRD.md
    echo "✓ 创建 PRD.md"
  fi

  # 3. README.md - basic template if not exists
  if [ ! -f ./README.md ]; then
    # Extract project name from directory
    local readme_project_name
    readme_project_name=$(basename "$(pwd)")
    generate_readme_template "$readme_project_name" > ./README.md
    echo "✓ 创建 README.md"
  else
    echo "✓ README.md 已存在"
  fi

  # CLAUDE.md 由 Claude Code /init 生成，此处不处理

  # Return to original directory
  cd "$original_dir" || return 1

  return 0
}

# Main entry function for init interview workflow
# Arguments:
#   $1 - Target directory (defaults to current directory)
# Returns: 0 on success, non-zero on failure
run_init_interview() {
  local target_dir="${1:-.}"
  local source_dir="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

  # Set up cleanup trap for Ctrl+C
  trap '_INIT_INTERVIEW_INTERRUPTED=1; _init_interview_cleanup; exit 130' INT TERM

  # Resolve target directory to absolute path
  if [ ! -d "$target_dir" ]; then
    echo "Error: Target directory does not exist: $target_dir" >&2
    return 1
  fi

  target_dir=$(cd "$target_dir" && pwd)

  # 检测是否在 Claude Code 环境中运行
  if [ ! -d "$HOME/.claude" ] && [ -z "${CLAUDE_CODE:-}" ]; then
    echo "⚠ codesop init 需要 Claude Code 环境"
    echo ""
    echo "请先安装 Claude Code，然后在项目目录中运行："
    echo "  claude"
    echo "  /codesop-init"
    echo ""
    return 1
  fi

  echo "========================================"
  echo "  codesop 初始化面试流程"
  echo "========================================"
  echo ""

  # Phase 0: 检测工具 + 设置系统级符号链接 + 启用 NEW_INIT
  echo "=== Phase 0: 工具检测与环境配置 ==="
  local tools
  tools=$(detect_installed_tools)
  if [ -n "$tools" ]; then
    echo "检测到工具: $tools"
  else
    echo "检测到工具: 无"
    echo "提示: 请先安装 Claude Code、Codex 或 OpenCode"
  fi

  if ! setup_system_links "$source_dir"; then
    echo "Warning: 系统级链接设置部分失败" >&2
  fi

  ensure_new_init_env

  # Phase 1: 检查/生成用户偏好
  echo ""
  echo "=== Phase 1: 用户偏好 ==="
  local template_file="$source_dir/templates/system/AGENTS.md"

  if [ ! -f "$template_file" ]; then
    echo "Warning: 系统模板文件不存在: $template_file" >&2
    echo "跳过用户偏好设置"
  else
    if ! check_user_preferences "$template_file"; then
      interview_user_preferences "$template_file"
    fi
  fi

  # Phase 2: 由用户在 Claude Code 中运行 /init 生成 CLAUDE.md
  # 此处不处理，由 skill 或用户手动执行

  # Phase 3: 生成/补充项目级文件
  echo ""
  echo "=== Phase 3: 项目级文件 ==="
  if ! generate_project_files "$target_dir"; then
    echo "Error: 项目级文件生成失败" >&2
    return 1
  fi

  # Phase 4: 检查技能安装状态
  echo ""
  echo "=== Phase 4: 技能检查 ==="
  check_skill_dependencies

  # Cleanup
  trap - INT TERM

  echo ""
  echo "========================================"
  echo "  初始化完成"
  echo "========================================"
  echo ""
  echo "下一步："
  echo "  1. 在 Claude Code 中运行 /init 生成 CLAUDE.md"
  echo "  2. 编辑 PRD.md 定义产品需求"
  echo "  3. 运行 'codesop status' 检查项目状态"
  echo ""

  return 0
}
