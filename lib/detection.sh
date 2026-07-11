#!/bin/bash
# Guard: HOME may be unset when sourced by hooks/IDE
export HOME="${HOME:-$(echo ~)}"
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
#   $1 - MCP server name
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

# Check git branch health for the codesop workbench.
# Detects orphaned local branches (merged into main) and leftover feature branches.
# Outputs machine-readable KEY=VALUE lines; exits cleanly on skip conditions.
check_git_health() {
  local root
  root="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "HEALTH_SKIP=no-git"; return 0; }

  git -C "$root" remote get-url origin >/dev/null 2>&1 || { echo "HEALTH_SKIP=no-remote"; return 0; }

  local main_branch
  main_branch=$(git -C "$root" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
  : "${main_branch:=main}"

  # Fetch latest merge status (timeout prevents hanging on unreachable remotes)
  # Inline timeout guard — same pattern as _run_with_timeout() in updates.sh;
  # can't reuse it because detection.sh loads before updates.sh
  if command -v timeout >/dev/null 2>&1; then
    timeout 10 git -C "$root" fetch origin "$main_branch" --quiet --prune 2>/dev/null || true
  else
    git -C "$root" fetch origin "$main_branch" --quiet --prune 2>/dev/null || true
  fi

  local orphans
  orphans=$(git -C "$root" branch --merged "origin/$main_branch" \
    --list 'feat/*' 'fix/*' 'chore/*' --format='%(refname:short)' 2>/dev/null || true)

  local current
  current=$(git -C "$root" branch --show-current 2>/dev/null)
  [ -z "$current" ] && current="detached"

  local orphan_count=0
  if [ -n "$orphans" ]; then
    orphan_count=$(printf '%s\n' "$orphans" | wc -l | tr -d ' ')
  fi

  # Three-state: true / false / unknown (gh unavailable)
  local is_leftover=false
  if [ "$current" != "$main_branch" ] && [ "$current" != "master" ]; then
    if command -v gh >/dev/null 2>&1; then
      local has_open_pr
      has_open_pr=$(gh pr list --state open --head "$current" --json number --jq '.[0].number' 2>/dev/null || echo "_GH_FAIL_")
      if [ "$has_open_pr" = "_GH_FAIL_" ]; then
        is_leftover=unknown
      elif [ -z "$has_open_pr" ]; then
        is_leftover=true
      fi
    else
      is_leftover=unknown
    fi
  fi

  # Flatten orphans to single line (space-separated) for reliable machine parsing
  local orphans_flat=""
  if [ -n "$orphans" ]; then
    orphans_flat=$(printf '%s' "$orphans" | tr '\n' ' ' | sed 's/ $//')
  fi

  echo "ORPHAN_COUNT=$orphan_count"
  echo "ORPHANS=$orphans_flat"
  echo "CURRENT=$current"
  echo "IS_LEFTOVER=$is_leftover"
  echo "MAIN_BRANCH=$main_branch"
}

# Check understand-anything knowledge graph usability (7 states).
# Output: UA_STATE=<state>
# States: absent / corrupt / unknown_head / stale_on / stale_off / fresh_on / fresh_degraded
check_understand_usability() {
  # root 定位：优先 git 仓库根（支持从子目录跑 /codesop），再 worktree 重定向（图谱在主 repo root），非 git 回退 pwd
  local root common_dir git_dir common_abs git_abs
  root=$(git rev-parse --show-toplevel 2>/dev/null)
  common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
  git_dir=$(git rev-parse --git-dir 2>/dev/null)
  if [ -n "$common_dir" ] && [ -n "$git_dir" ]; then
    common_abs=$(cd "$common_dir" 2>/dev/null && pwd -P)
    git_abs=$(cd "$git_dir" 2>/dev/null && pwd -P)
    if [ -n "$common_abs" ] && [ "$common_abs" != "$git_abs" ]; then
      root="$(dirname "$common_abs")"   # linked worktree → 主 repo root
    fi
  fi
  [ -n "$root" ] || root="$(pwd)"   # 非 git 回退
  local graph="$root/.understand-anything/knowledge-graph.json"
  local meta="$root/.understand-anything/meta.json"
  local cfg="$root/.understand-anything/config.json"
  local fp="$root/.understand-anything/fingerprints.json"

  # 1. 存在性
  [ -f "$graph" ] && [ -f "$meta" ] || { echo "UA_STATE=absent"; return; }
  # node 兜底：无 node 无法 JSON 解析（M1），归 unknown_head（无法判定新鲜度），不误判 corrupt
  command -v node >/dev/null 2>&1 || { echo "UA_STATE=unknown_head"; return; }
  # node 调用 timeout 前缀（防 NFS/大文件 require 挂起，仿 check_git_health；macOS 无 timeout 则不包）
  local _ua_to=""
  command -v timeout >/dev/null 2>&1 && _ua_to="timeout 10"

  # 2. 完整性：graph 必须可解析且含 nodes 数组
  if ! $_ua_to node -e "const g=require(process.argv[1]); if(!Array.isArray(g.nodes))process.exit(1)" "$graph" 2>/dev/null; then
    echo "UA_STATE=corrupt"; return
  fi

  # 3. 完整性：meta 必须可解析且 gitCommitHash 是有效字符串（拒绝 undefined/空/<8字符）
  local meta_hash
  meta_hash=$($_ua_to node -e "const m=require(process.argv[1]); const h=m.gitCommitHash; if(typeof h!=='string'||h==='undefined'||h.length<8)process.exit(1)" "$meta" 2>/dev/null \
    && $_ua_to node -p "require(process.argv[1]).gitCommitHash" "$meta" 2>/dev/null) || meta_hash=""
  [ -n "$meta_hash" ] || { echo "UA_STATE=corrupt"; return; }

  # 4. HEAD 可读
  local head_hash; head_hash=$(git rev-parse HEAD 2>/dev/null)
  [ -n "$head_hash" ] || { echo "UA_STATE=unknown_head"; return; }

  # 5. config：用 JSON parser 严格判 autoUpdate===true（拒绝字符串 "true" / missing / corrupt）
  local cfg_on="false"
  if $_ua_to node -e "const c=require(process.argv[1]); if(c.autoUpdate!==true)process.exit(1)" "$cfg" 2>/dev/null; then
    cfg_on="true"
  fi

  # 6. fingerprints：autoUpdate=true 时必须存在且可解析（缺失则下次增量会 FULL_UPDATE 爆炸）
  local fp_ok="yes"
  if [ "$cfg_on" = "true" ]; then
    if ! { [ -f "$fp" ] && $_ua_to node -e "require(process.argv[1])" "$fp" 2>/dev/null; }; then fp_ok="no"; fi
  fi

  # 7. 新鲜度 + 配置 + fingerprints 组合
  if [ "$meta_hash" != "$head_hash" ]; then
    if [ "$cfg_on" = "true" ]; then echo "UA_STATE=stale_on"; else echo "UA_STATE=stale_off"; fi
  else
    if [ "$cfg_on" = "true" ] && [ "$fp_ok" = "yes" ]; then echo "UA_STATE=fresh_on"; else echo "UA_STATE=fresh_degraded"; fi
  fi
}

# ============================================================================
# v5 Phase 0 事实完整性（spec §8 待实施 4 项）
# 4 函数：runtime_version_superpowers / codesop_manifest_hash /
# capability_state（healthy/stale/absent/unknown）/ family_aggregate（取最差）
# 复用 find_superpowers_plugin_path（定位）+ 仿 check_understand_usability（多态）
# ============================================================================

# superpowers runtime version + upstream gitCommitSha（Claude family）
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

# codesop manifest hash（sha256 安装的关键文件：SKILL.md + router）
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

# capability state（healthy/stale/absent/unknown）— 综合 runtime + fingerprint + manifest
# healthy: superpowers 装了 + gitCommitSha 一致 + manifest hash 一致
# stale:   gitCommitSha 或 manifest hash 与基线 stamp 不符
# absent:  superpowers 未装
# unknown: 无法探测（无 installed_plugins.json / 无 jq / 无 sha）
# Output: CAPABILITY_STATE=<state>
capability_state() {
  local rv ver sha
  rv=$(runtime_version_superpowers)
  ver=$(printf '%s\n' "$rv" | sed -n 's/^RUNTIME_VERSION=//p')
  sha=$(printf '%s\n' "$rv" | sed -n 's/^RUNTIME_SHA=//p')

  [ "$ver" = "absent" ] && { echo "CAPABILITY_STATE=absent"; return; }
  [ "$ver" = "unknown" ] && { echo "CAPABILITY_STATE=unknown"; return; }

  local state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/codesop"

  # Gate 1: fingerprint（gitCommitSha）vs stamp
  local sha_stamp="$state_dir/patch-upstream-sha"
  if [ -f "$sha_stamp" ] && [ "$sha" != "unknown" ]; then
    local baseline_sha
    baseline_sha=$(tr -d '[:space:]' < "$sha_stamp" 2>/dev/null)
    if [ -n "$baseline_sha" ] && [ "$baseline_sha" != "$sha" ]; then
      echo "CAPABILITY_STATE=stale"; return
    fi
  fi

  # Gate 2: manifest hash vs stamp（codesop 安装文件完整性）
  local manifest_stamp="$state_dir/manifest-hash"
  if [ -f "$manifest_stamp" ]; then
    local cur_hash baseline_hash
    cur_hash=$(codesop_manifest_hash)
    baseline_hash=$(tr -d '[:space:]' < "$manifest_stamp" 2>/dev/null)
    if [ "$cur_hash" != "absent" ] && [ "$cur_hash" != "unknown" ] && \
       [ -n "$baseline_hash" ] && [ "$baseline_hash" != "$cur_hash" ]; then
      echo "CAPABILITY_STATE=stale"; return
    fi
  fi

  echo "CAPABILITY_STATE=healthy"
}

# family aggregate（claude/codex/opencode，已安装目标取最差）
# claude: capability_state（healthy/stale/absent/unknown）
# codex/opencode: AGENTS.md 存在 → present（无 version 漂移概念，不参与 stale）
# Output: FAMILY_CLAUDE=<state> FAMILY_CODEX=<present|absent> FAMILY_OPENCODE=<present|absent> FAMILY=<worst>
# family 取最差：claude stale/unknown 上浮（任一已安装 stale/unknown → family stale/unknown）
family_aggregate() {
  local claude_state codex_state opencode_state
  claude_state=$(capability_state | sed -n 's/^CAPABILITY_STATE=//p')
  [ -f "$HOME/.codex/AGENTS.md" ] && codex_state=present || codex_state=absent
  [ -f "$HOME/.config/opencode/AGENTS.md" ] && opencode_state=present || opencode_state=absent

  printf '%s\n' "FAMILY_CLAUDE=$claude_state" "FAMILY_CODEX=$codex_state" "FAMILY_OPENCODE=$opencode_state"

  case "$claude_state" in
    stale|unknown) echo "FAMILY=$claude_state" ;;
    *) echo "FAMILY=healthy" ;;
  esac
}
