#!/bin/bash
# output.sh - Output formatting and inference utilities for codesop
#
# This module provides functions for:
# - Rendering tech stack display strings
# - Inferring default commands based on language/framework
# - Formatting tool and ecosystem state for display
# - Finding first existing path from a list of candidates
#
# Usage: source this file from another bash script
#   source /path/to/lib/output.sh

render_tech_stack() {
  local project_language="$1"
  local project_framework="$2"

  if [ "$project_framework" != "None" ]; then
    echo "$project_language / $project_framework"
  else
    echo "$project_language"
  fi
}

infer_test_cmd() {
  local project_language="$1"
  local project_framework="$2"

  case "$project_language:$project_framework" in
    TypeScript/JavaScript:Next.js|TypeScript/JavaScript:React|TypeScript/JavaScript:None)
      echo "npm test"
      ;;
    Python:FastAPI|Python:Django|Python:None)
      echo "pytest"
      ;;
    *)
      echo "<TEST_CMD>"
      ;;
  esac
}

infer_lint_cmd() {
  local project_language="$1"

  case "$project_language" in
    TypeScript/JavaScript)
      echo "npm run lint"
      ;;
    Python)
      echo "ruff check ."
      ;;
    *)
      echo "<LINT_CMD>"
      ;;
  esac
}

infer_type_cmd() {
  local project_language="$1"

  case "$project_language" in
    TypeScript/JavaScript)
      echo "npm run typecheck"
      ;;
    Python)
      echo "mypy ."
      ;;
    *)
      echo "<TYPE_CMD>"
      ;;
  esac
}

infer_smoke_cmd() {
  local project_language="$1"
  local project_framework="$2"

  case "$project_language:$project_framework" in
    TypeScript/JavaScript:Next.js|TypeScript/JavaScript:React)
      echo "npm run dev"
      ;;
    Python:FastAPI|Python:Django)
      echo "uv run"
      ;;
    *)
      echo "<SMOKE_CMD>"
      ;;
  esac
}

pick_host() {
  local tool_claude="$1"
  local tool_codex="$2"
  local tool_opencode="$3"

  if [ "$tool_claude" = "installed" ]; then
    echo "claude"
    return
  fi

  if [ "$tool_codex" = "installed" ]; then
    echo "codex"
    return
  fi

  if [ "$tool_opencode" = "installed" ]; then
    echo "opencode"
    return
  fi

  echo "none"
}

format_tool_state() {
  local value="${1:-missing}"

  if [ "$value" = "installed" ]; then
    echo "已检测到"
  else
    echo "未检测到"
  fi
}

format_ecosystem_state() {
  local value="${1:-missing}"

  if [ "$value" = "installed" ]; then
    echo "已安装"
  elif [ "$value" = "partial" ]; then
    echo "部分安装"
  else
    echo "未安装"
  fi
}

find_first_existing_path() {
  local candidate

  for candidate in "$@"; do
    if [ -e "$candidate" ]; then
      printf '%s
' "$candidate"
      return 0
    fi
  done

  return 1
}

# Find superpowers installed via Claude Code plugin marketplace.
# The actual path is ~/.claude/plugins/cache/<marketplace>/superpowers/<version>/
# Returns the path to the latest version directory, or nothing if not found.
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
