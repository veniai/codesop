#!/bin/bash
# detection.sh - Project environment detection module
#
# This module provides a function to detect project language, shape, framework,
# and tool ecosystem state for a given target directory.
#
# Usage:
#   source /path/to/detection.sh
#
# Output:
#   Key=value pairs describing the project and tool state

# Detect the dominant programming language in a directory.
# Arguments:
#   $1 - Target directory
# Prints: nothing. Sets project_language and optionally project_shape.
detect_project_language() {
  local TARGET_DIR="${1:-.}"
  local project_language="Unknown"
  local project_shape="General Project"

  # Priority 1: Root-level marker files
  if [ -f "$TARGET_DIR/pyproject.toml" ] || [ -f "$TARGET_DIR/requirements.txt" ]; then
    project_language="Python"
  elif [ -f "$TARGET_DIR/go.mod" ]; then
    project_language="Go"
  elif [ -f "$TARGET_DIR/Cargo.toml" ]; then
    project_language="Rust"
  elif [ -f "$TARGET_DIR/package.json" ]; then
    project_language="TypeScript/JavaScript"

  # Priority 2: Subdirectory marker files (depth 1-2)
  elif find "$TARGET_DIR" -maxdepth 2 -name "package.json" -not -path "*/node_modules/*" 2>/dev/null | head -1 | grep -q .; then
    project_language="TypeScript/JavaScript"
  elif find "$TARGET_DIR" -maxdepth 2 -name "pyproject.toml" 2>/dev/null | head -1 | grep -q .; then
    project_language="Python"
  else
    # Priority 3: File extension heuristic (count files, pick dominant)
    local sh_count md_count py_count js_count config_count total

    sh_count=$(find "$TARGET_DIR" -maxdepth 3 -name "*.sh" -not -path "*/.git/*" 2>/dev/null | wc -l | tr -d ' ')
    md_count=$(find "$TARGET_DIR" -maxdepth 3 -name "*.md" -not -path "*/.git/*" 2>/dev/null | wc -l | tr -d ' ')
    py_count=$(find "$TARGET_DIR" -maxdepth 3 -name "*.py" -not -path "*/.git/*" 2>/dev/null | wc -l | tr -d ' ')
    js_count=$(find "$TARGET_DIR" -maxdepth 3 \( -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" \) -not -path "*/.git/*" -not -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
    config_count=$(find "$TARGET_DIR" -maxdepth 2 \( -name "*.json" -o -name "*.yaml" -o -name "*.yml" -o -name "*.toml" -o -name "*.conf" \) -not -path "*/.git/*" -not -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')

    total=$((sh_count + md_count + py_count + js_count + config_count))

    if [ "$total" -gt 0 ]; then
      if [ "$sh_count" -gt 0 ] && [ "$sh_count" -ge "$md_count" ] && [ "$py_count" -eq 0 ] && [ "$js_count" -eq 0 ]; then
        project_language="Shell"
        project_shape="脚本集合"
      elif [ "$py_count" -gt "$js_count" ] && [ "$py_count" -gt 0 ]; then
        project_language="Python"
      elif [ "$js_count" -gt 0 ]; then
        project_language="TypeScript/JavaScript"
      elif [ "$sh_count" -gt 0 ]; then
        project_language="Shell"
        project_shape="脚本集合"
      elif [ "$config_count" -gt "$md_count" ] && [ "$config_count" -gt 0 ]; then
        project_language="Config"
        project_shape="配置项目"
      elif [ "$md_count" -gt 0 ]; then
        project_language="Markdown"
        project_shape="文档项目"
      fi
    fi
  fi

  _DET_PROJECT_LANGUAGE="$project_language"
  _DET_PROJECT_SHAPE="$project_shape"
}

# Detect project shape and framework from package.json or pyproject.toml.
# Arguments:
#   $1 - Target directory
# Sets: _DET_PROJECT_SHAPE, _DET_PROJECT_FRAMEWORK
detect_project_shape_and_framework() {
  local TARGET_DIR="${1:-.}"
  local project_framework="None"

  # Preserve shape from language detection unless we find something more specific
  local project_shape="${_DET_PROJECT_SHAPE:-General Project}"

  if [ -f "$TARGET_DIR/package.json" ]; then
    if command -v jq >/dev/null 2>&1; then
      # Check workspaces
      if jq -e '.workspaces' "$TARGET_DIR/package.json" >/dev/null 2>&1; then
        project_shape="Monorepo"
      fi

      # Check Next.js (dependencies or devDependencies)
      if jq -e '.dependencies.next // .devDependencies.next' "$TARGET_DIR/package.json" >/dev/null 2>&1; then
        project_shape="Web App"
        project_framework="Next.js"
      elif jq -e '.dependencies.react // .devDependencies.react' "$TARGET_DIR/package.json" >/dev/null 2>&1; then
        project_shape="Web App"
        project_framework="React"
      elif jq -e '.dependencies.vue // .devDependencies.vue' "$TARGET_DIR/package.json" >/dev/null 2>&1; then
        project_shape="Web App"
        project_framework="Vue"
      elif jq -e '.dependencies.express // .devDependencies.express' "$TARGET_DIR/package.json" >/dev/null 2>&1; then
        project_shape="Backend Service"
        project_framework="Express"
      fi
    else
      # Fallback to grep if jq not available
      if grep -q '"workspaces"' "$TARGET_DIR/package.json"; then
        project_shape="Monorepo"
      fi

      if grep -q '"next"' "$TARGET_DIR/package.json"; then
        project_shape="Web App"
        project_framework="Next.js"
      elif grep -q '"react"' "$TARGET_DIR/package.json"; then
        project_shape="Web App"
        project_framework="React"
      fi
    fi

    # package.json present but no framework detected → Node Project
    if [ "$project_framework" = "None" ] && [ "$project_shape" = "General Project" ]; then
      project_shape="Node Project"
    fi
  fi

  if [ -f "$TARGET_DIR/pyproject.toml" ]; then
    if grep -qi 'fastapi' "$TARGET_DIR/pyproject.toml"; then
      project_shape="Backend Service"
      project_framework="FastAPI"
    elif grep -qi 'django' "$TARGET_DIR/pyproject.toml"; then
      project_shape="Backend Service"
      project_framework="Django"
    elif grep -qi 'flask' "$TARGET_DIR/pyproject.toml"; then
      project_shape="Backend Service"
      project_framework="Flask"
    elif [ "$project_shape" = "General Project" ]; then
      project_shape="Python Project"
    fi
  fi

  _DET_PROJECT_SHAPE="$project_shape"
  _DET_PROJECT_FRAMEWORK="$project_framework"
}

# Check if a specific MCP server is configured in Claude Code settings
# Arguments:
#   $1 - MCP server name (e.g. "browser-use")
# Returns: 0 if configured, 1 if not
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
