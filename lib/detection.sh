#!/bin/bash
# detection.sh - Project environment detection module
#
# This module provides a function to detect project language, shape, framework,
# and tool ecosystem state for a given target directory.
#
# Usage:
#   source /path/to/detection.sh
#   detect_environment "/path/to/project"
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

  # Export results via global variables used by caller
  _DET_PROJECT_LANGUAGE="$project_language"
  _DET_PROJECT_SHAPE="$project_shape"
}

# Detect project shape and framework from package.json or pyproject.toml.
# Arguments:
#   $1 - Target directory
#   $2 - Reference to project_shape variable (updated in place)
#   $3 - Reference to project_framework variable (updated in place)
# Sets: _DET_PROJECT_SHAPE, _DET_PROJECT_FRAMEWORK
detect_project_shape_and_framework() {
  local TARGET_DIR="${1:-.}"
  local project_shape="General Project"
  local project_framework="None"

  if [ -f "$TARGET_DIR/package.json" ]; then
      # Use jq for accurate JSON parsing (supports both dependencies and devDependencies)
      if command -v jq >/dev/null 2>&1; then
        # Check workspaces
        if jq -e '.workspaces' "$TARGET_DIR/package.json" >/dev/null 2>&1; then
          project_shape="Monorepo"
        fi

        # Check Next.js (dependencies or devDependencies)
        if jq -e '.dependencies.next // .devDependencies.next' "$TARGET_DIR/package.json" >/dev/null 2>&1; then
          project_shape="Web App"
          project_framework="Next.js"
          return
        fi

        # Check React
        if jq -e '.dependencies.react // .devDependencies.react' "$TARGET_DIR/package.json" >/dev/null 2>&1; then
          project_shape="Web App"
          project_framework="React"
          return
        fi

        # Check Vue
        if jq -e '.dependencies.vue // .devDependencies.vue' "$TARGET_DIR/package.json" >/dev/null 2>&1; then
          project_shape="Web App"
          project_framework="Vue"
          return
        fi

        # Check Express
        if jq -e '.dependencies.express // .devDependencies.express' "$TARGET_DIR/package.json" >/dev/null 2>&1; then
          project_shape="Backend Service"
          project_framework="Express"
          return
        fi
      else
        # Fallback to grep if jq not available
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

      if grep -qi 'flask' "$TARGET_DIR/pyproject.toml"; then
        project_shape="Backend Service"
        project_framework="Flask"
        return
      fi

      if [ "$project_shape" = "General Project" ]; then
        project_shape="Python Project"
      fi
    fi
  fi

  # Export results
  _DET_PROJECT_SHAPE="$project_shape"
  _DET_PROJECT_FRAMEWORK="$project_framework"
}

# ============================================================================
# 工具注册表 (Tool Registry)
  # 格式: "名称:检测路径1,检测路径2,..."
  # 新增工具只需在此添加一行
  # ============================================================================
  AI_TOOLS=(
    "claude:$HOME/.claude"
    "codex:$HOME/.codex"
    "opencode:$HOME/.config/opencode"
    "cursor:$HOME/.cursor"
    "aider:$(command -v aider 2>/dev/null || echo '')"
    "windsurf:$HOME/.windsurf"
  )

  # 技能/生态系统注册表
  ECOSYSTEM_REGISTRY=(
    "superpowers:$HOME/.codex/superpowers,$HOME/.codex/skills/.system,$HOME/.claude/plugins/superpowers,$HOME/.claude/skills/superpowers,$HOME/.config/opencode/plugins/superpowers,$HOME/.agents/skills/superpowers"
    "gstack:$HOME/.claude/skills/gstack,$HOME/.agents/skills/gstack,$HOME/.config/opencode/skills/gstack,$HOME/.codex/skills/gstack"
  )

  detect_tool_by_registry() {
    local entry="$1"
    local name="${entry%%:*}"
    local paths="${entry#*:}"

    # 处理空路径（如 command -v 结果为空）
    if [ -z "$paths" ]; then
      echo "tool.$name=missing"
      return
    fi

    # 逗号分隔的多个路径
    local IFS=','
    for path in $paths; do
      if [ -e "$path" ]; then
        echo "tool.$name=installed"
        return
      fi
    done

    echo "tool.$name=missing"
  }

  detect_ecosystem_by_registry() {
    local entry="$1"
    local name="${entry%%:*}"
    local paths="${entry#*:}"

    local IFS=','
    for path in $paths; do
      if [ -e "$path" ]; then
        echo "ecosystem.$name=installed"
        return
      fi
    done

    # superpowers 特殊处理：Claude Code 插件市场缓存路径
    if [ "$name" = "superpowers" ]; then
      if type find_superpowers_plugin_path >/dev/null 2>&1 && find_superpowers_plugin_path >/dev/null 2>&1; then
        echo "ecosystem.$name=installed"
        return
      fi
    fi

    # gstack 特殊处理：检查命令和备用路径
    if [ "$name" = "gstack" ]; then
      if command -v gstack >/dev/null 2>&1; then
        echo "ecosystem.$name=partial"
        return
      fi
      if [ -e "$HOME/.gstack" ] || [ -e "$HOME/gstack" ]; then
        echo "ecosystem.$name=partial"
        return
      fi
    fi

    echo "ecosystem.$name=missing"
  }

  detect_all_tools() {
    for entry in "${AI_TOOLS[@]}"; do
      detect_tool_by_registry "$entry"
    done
  }

  detect_all_ecosystems() {
    for entry in "${ECOSYSTEM_REGISTRY[@]}"; do
      detect_ecosystem_by_registry "$entry"
    done
  }
fi

# ============================================================================
# detect_environment() — main entry point
# Calls top-level detection functions and prints results.
# ============================================================================
detect_environment() {
  local TARGET_DIR="${1:-.}"

  # Run detection (results in global vars)
  detect_project_language "$TARGET_DIR"
  detect_project_shape_and_framework "$TARGET_DIR"

  local project_language="${_DET_PROJECT_LANGUAGE:-Unknown}"
  local project_shape="${_DET_PROJECT_SHAPE:-General Project}"
  local project_framework="${_DET_PROJECT_FRAMEWORK:-None}"

  echo "project.language=$project_language"
  echo "project.shape=$project_shape"
  echo "project.framework=$project_framework"
  echo "output.language=zh-CN"

  # 使用注册表检测所有工具和生态系统
  detect_all_tools
  detect_all_ecosystems
}
