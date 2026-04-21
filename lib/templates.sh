#!/bin/bash
# templates.sh - Template generation functions for codesop
#
# This module provides functions for generating project templates:
# - AGENTS.md wrapper template
# - PRD.md template from external file
# - Template generation orchestration
# - Merge suggestions for existing AGENTS.md files
#
# Dependencies:
# - lib/output.sh (for render_tech_stack, infer_*_cmd functions)
#
# Usage: source this file from another bash script
#   source /path/to/lib/templates.sh

contains_text() {
  local file_path="$1"
  local needle="$2"

  if [ ! -f "$file_path" ]; then
    return 1
  fi

  grep -Fq "$needle" "$file_path"
}

write_agents_template() {
  local target_dir="$1"
  local agents_file="$target_dir/AGENTS.md"

  cat >"$agents_file" <<'EOF'
@CLAUDE.md
EOF
}

write_prd_template() {
  local target_dir="$1"
  local project_name="$2"
  local date_today="$3"
  local _tech_stack="$4"
  local prd_file="$target_dir/PRD.md"
  local template_file="$SOURCE_DIR/templates/project/PRD.md"

  if [ ! -f "$template_file" ]; then
    echo "Error: PRD template not found: $template_file" >&2
    return 1
  fi

  local escaped_name
  escaped_name=$(printf '%s\n' "$project_name" | sed 's/[&/\]/\\&/g')
  sed -e "s/{PROJECT_NAME}/$escaped_name/g" -e "s/{DATE}/$date_today/g" "$template_file" > "$prd_file"
}

generate_templates() {
  local target_dir="$1"
  local project_name="$2"
  local tech_stack="$3"
  local test_cmd="$4"
  local lint_cmd="$5"
  local type_cmd="$6"
  local smoke_cmd="$7"
  local date_today
  local agents_status=""
  local claude_status=""
  local prd_status=""
  local prd_file="$target_dir/PRD.md"

  # SECURITY FIX: Sanitize project_name to prevent template injection
  # Only allow alphanumeric characters, underscores, and hyphens
  project_name="$(basename "$target_dir" | sed 's/[^a-zA-Z0-9_-]//g')"

  date_today="$(date +%F)"

  if [ -f "$target_dir/AGENTS.md" ]; then
    if grep -Fxq "@CLAUDE.md" "$target_dir/AGENTS.md" || grep -Fxq "@./CLAUDE.md" "$target_dir/AGENTS.md"; then
      agents_status="已保留（已是 @CLAUDE.md 引用包装）"
    else
      agents_status="已保留（非引用包装，建议收敛为 @CLAUDE.md）"
    fi
  else
    write_agents_template "$target_dir" "$project_name" "$tech_stack" "$test_cmd" "$lint_cmd" "$type_cmd" "$smoke_cmd"
    agents_status="已生成（@CLAUDE.md 引用包装）"
  fi

  claude_status="由 Claude Code 的 /init 生成，codesop 不覆盖"

  if [ -f "$prd_file" ]; then
    if grep -Fq "## 0. 使用说明" "$prd_file" && grep -Fq "## 1. 当前快照" "$prd_file"; then
      prd_status="已保留（已是活文档格式）"
    else
      cp "$prd_file" "$prd_file.codesop.legacy.bak"
      write_prd_template "$target_dir" "$project_name" "$date_today" "$tech_stack"
      prd_status="已迁移为活文档格式（备份: PRD.md.codesop.legacy.bak）"
    fi
  else
    write_prd_template "$target_dir" "$project_name" "$date_today" "$tech_stack"
    prd_status="已生成（活文档格式）"
  fi

  printf '
%s
' "已生成文件："
  printf '%s
' "- AGENTS.md：$agents_status"
  printf '%s
' "- CLAUDE.md：$claude_status"
  printf '%s
' "- PRD.md：$prd_status"

  # 检测系统级别的配置文件
  printf '
%s
' "系统级别配置："

  # 检测 ~/.claude/CLAUDE.md
  local system_claude_status=""
  if [ -L "$HOME/.claude/CLAUDE.md" ]; then
    local claude_target=$(readlink "$HOME/.claude/CLAUDE.md")
    if [ "$claude_target" = "$target_dir/CLAUDE.md" ]; then
      system_claude_status="符号链接 → 当前项目（应改为独立文件）"
    else
      system_claude_status="符号链接 → $claude_target"
    fi
  elif [ -f "$HOME/.claude/CLAUDE.md" ]; then
    # 检查是否包含 AI 编码契约
    if grep -q "AI 编码契约" "$HOME/.claude/CLAUDE.md" 2>/dev/null; then
      system_claude_status="已存在（独立文件，包含 AI 编码契约）"
    else
      system_claude_status="已存在（独立文件，但未包含 AI 编码契约）"
    fi
  else
    system_claude_status="不存在（建议创建，包含 AI 编码契约）"
  fi
  printf '%s
' "- ~/.claude/CLAUDE.md：$system_claude_status"

  # 检测 ~/.claude/AGENTS.md
  local system_agents_status=""
  if [ -L "$HOME/.claude/AGENTS.md" ]; then
    local agents_target=$(readlink "$HOME/.claude/AGENTS.md")
    system_agents_status="符号链接 → $agents_target"
  elif [ -f "$HOME/.claude/AGENTS.md" ]; then
    system_agents_status="已存在（独立文件）"
  else
    system_agents_status="不存在"
  fi
  printf '%s
' "- ~/.claude/AGENTS.md：$system_agents_status"

  # 检测 ~/.config/opencode/CLAUDE.md（OpenCode）
  if [ -f "$HOME/.config/opencode/CLAUDE.md" ]; then
    printf '%s
' "- ~/.config/opencode/CLAUDE.md：已存在"
  fi
}

print_agents_merge_suggestions() {
  local target_dir="$1"
  local agents_file="$target_dir/AGENTS.md"

  if [ ! -f "$agents_file" ]; then
    return
  fi

  printf '\n%s\n' "AGENTS.md 合并优化建议："
  printf '%s\n' "--- current/AGENTS.md"
  printf '%s\n' "+++ suggested/AGENTS.md"

  if grep -Fxq "@CLAUDE.md" "$agents_file" || grep -Fxq "@./CLAUDE.md" "$agents_file"; then
    printf '%s\n' "  (当前 AGENTS.md 已覆盖 codesop 关注的核心骨架，无额外建议)"
  else
    printf '%s\n' "- 建议把项目级 AGENTS.md 收敛成轻量包装，正文只保留在 CLAUDE.md"
    printf '%s\n' "+@CLAUDE.md"
  fi
}
