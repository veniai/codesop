#!/bin/bash

set -euo pipefail

TARGET_DIR="${1:-.}"

project_language="Unknown"
project_shape="General Project"
project_framework="None"
output_language="zh-CN"

detect_project_language() {
  # Priority 1: Root-level marker files
  if [ -f "$TARGET_DIR/pyproject.toml" ] || [ -f "$TARGET_DIR/requirements.txt" ]; then
    project_language="Python"
    return
  fi

  if [ -f "$TARGET_DIR/go.mod" ]; then
    project_language="Go"
    return
  fi

  if [ -f "$TARGET_DIR/Cargo.toml" ]; then
    project_language="Rust"
    return
  fi

  if [ -f "$TARGET_DIR/package.json" ]; then
    project_language="TypeScript/JavaScript"
    return
  fi

  # Priority 2: Subdirectory marker files (depth 1-2)
  if find "$TARGET_DIR" -maxdepth 2 -name "package.json" -not -path "*/node_modules/*" 2>/dev/null | head -1 | grep -q .; then
    project_language="TypeScript/JavaScript"
    return
  fi

  if find "$TARGET_DIR" -maxdepth 2 -name "pyproject.toml" 2>/dev/null | head -1 | grep -q .; then
    project_language="Python"
    return
  fi

  # Priority 3: File extension heuristic (count files, pick dominant)
  local sh_count md_count py_count js_count config_count total

  sh_count=$(find "$TARGET_DIR" -maxdepth 3 -name "*.sh" -not -path "*/.git/*" 2>/dev/null | wc -l | tr -d ' ')
  md_count=$(find "$TARGET_DIR" -maxdepth 3 -name "*.md" -not -path "*/.git/*" 2>/dev/null | wc -l | tr -d ' ')
  py_count=$(find "$TARGET_DIR" -maxdepth 3 -name "*.py" -not -path "*/.git/*" 2>/dev/null | wc -l | tr -d ' ')
  js_count=$(find "$TARGET_DIR" -maxdepth 3 \( -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" \) -not -path "*/.git/*" -not -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
  config_count=$(find "$TARGET_DIR" -maxdepth 2 \( -name "*.json" -o -name "*.yaml" -o -name "*.yml" -o -name "*.toml" -o -name "*.conf" \) -not -path "*/.git/*" -not -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')

  total=$((sh_count + md_count + py_count + js_count + config_count))

  if [ "$total" -eq 0 ]; then
    project_language="Unknown"
    return
  fi

  # Pick the dominant type
  if [ "$sh_count" -gt 0 ] && [ "$sh_count" -ge "$md_count" ] && [ "$py_count" -eq 0 ] && [ "$js_count" -eq 0 ]; then
    project_language="Shell"
    project_shape="脚本集合"
    return
  fi

  if [ "$py_count" -gt "$js_count" ] && [ "$py_count" -gt 0 ]; then
    project_language="Python"
    return
  fi

  if [ "$js_count" -gt 0 ]; then
    project_language="TypeScript/JavaScript"
    return
  fi

  if [ "$sh_count" -gt 0 ]; then
    project_language="Shell"
    project_shape="脚本集合"
    return
  fi

  if [ "$config_count" -gt "$md_count" ] && [ "$config_count" -gt 0 ]; then
    project_language="Config"
    project_shape="配置项目"
    return
  fi

  if [ "$md_count" -gt 0 ]; then
    project_language="Markdown"
    project_shape="文档项目"
    return
  fi
}

detect_project_shape_and_framework() {
  if [ -f "$TARGET_DIR/package.json" ]; then
    if grep -q '"workspaces"' "$TARGET_DIR/package.json"; then
      project_shape="Monorepo"
    fi

    if grep -q '"next"' "$TARGET_DIR/package.json"; then
      project_shape="Web App"
      project_framework="Next.js"
      return
    fi

    if grep -q '"react"' "$TARGET_DIR/package.json"; then
      project_shape="Web App"
      project_framework="React"
      return
    fi

    if [ "$project_shape" = "General Project" ]; then
      project_shape="Node Project"
    fi
  fi

  if [ -f "$TARGET_DIR/pyproject.toml" ]; then
    if grep -qi 'fastapi' "$TARGET_DIR/pyproject.toml"; then
      project_shape="Backend Service"
      project_framework="FastAPI"
      return
    fi

    if grep -qi 'django' "$TARGET_DIR/pyproject.toml"; then
      project_shape="Backend Service"
      project_framework="Django"
      return
    fi

    if [ "$project_shape" = "General Project" ]; then
      project_shape="Python Project"
    fi
  fi
}

detect_tool_state() {
  local label="$1"
  local path="$2"

  if [ -e "$path" ]; then
    echo "tool.$label=installed"
  else
    echo "tool.$label=missing"
  fi
}

detect_path_state() {
  local key="$1"
  shift

  for candidate in "$@"; do
    if [ -e "$candidate" ]; then
      echo "$key=installed"
      return
    fi
  done

  echo "$key=missing"
}

detect_superpowers_state() {
  detect_path_state \
    "ecosystem.superpowers" \
    "$HOME/.codex/superpowers" \
    "$HOME/.codex/skills/.system" \
    "$HOME/.claude/plugins/superpowers" \
    "$HOME/.claude/skills/superpowers" \
    "$HOME/.config/opencode/plugins/superpowers" \
    "$HOME/.agents/skills/superpowers" \
    "$TARGET_DIR/.claude/plugins/superpowers" \
    "$TARGET_DIR/.claude/skills/superpowers" \
    "$TARGET_DIR/.codex/skills/.system" \
    "$TARGET_DIR/.agents/skills/superpowers"
}

detect_gstack_state() {
  if detect_path_state \
    "ecosystem.gstack" \
    "$HOME/.claude/skills/gstack" \
    "$HOME/.agents/skills/gstack" \
    "$HOME/.config/opencode/skills/gstack" \
    "$HOME/.codex/skills/gstack" \
    "$TARGET_DIR/.claude/skills/gstack" \
    "$TARGET_DIR/.agents/skills/gstack" \
    "$TARGET_DIR/.config/opencode/skills/gstack" \
    "$TARGET_DIR/.codex/skills/gstack" | grep -q 'installed$'; then
    echo "ecosystem.gstack=installed"
    return
  fi

  if command -v gstack >/dev/null 2>&1; then
    echo "ecosystem.gstack=partial"
    return
  fi

  if detect_path_state \
    "ecosystem.gstack" \
    "$HOME/.gstack" \
    "$HOME/gstack" \
    "$TARGET_DIR/.gstack" \
    "$TARGET_DIR/gstack" | grep -q 'installed$'; then
    echo "ecosystem.gstack=partial"
    return
  fi

  echo "ecosystem.gstack=missing"
}

detect_project_language
detect_project_shape_and_framework

echo "project.language=$project_language"
echo "project.shape=$project_shape"
echo "project.framework=$project_framework"
echo "output.language=$output_language"
detect_tool_state "claude" "$HOME/.claude"
detect_tool_state "codex" "$HOME/.codex"
detect_tool_state "opencode" "$HOME/.config/opencode"
detect_superpowers_state
detect_gstack_state
