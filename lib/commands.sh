#!/bin/bash
# commands.sh - Command implementations for codesop CLI
#
# This module provides all subcommand implementations for the codesop CLI:
# - run_update(): Update codesop to the latest version via git pull
# - run_version(): Display the current codesop version
# - run_setup(): Run the setup script for host integration
# - run_status(): Show project status (git state, config files, code stats)
# - run_diagnose(): Diagnose project stage and recommend next steps
#
# Dependencies (must be sourced before this module):
# - lib/output.sh: render_tech_stack(), infer_test_cmd(), infer_lint_cmd(),
#                  infer_type_cmd(), infer_smoke_cmd(), pick_host(),
#                  format_tool_state(), format_ecosystem_state()
# - lib/detection.sh: detect_environment()
# - lib/templates.sh: generate_templates(), print_agents_merge_suggestions()
# - lib/updates.sh: current_version(), print_install_suggestions()
#
# Expected caller-set global variables:
# - ROOT_DIR: Path to codesop installation directory
# - VERSION_FILE: Path to VERSION file (typically $ROOT_DIR/VERSION)
#
# Usage:
#   source /path/to/lib/output.sh
#   source /path/to/lib/detection.sh
#   source /path/to/lib/templates.sh
#   source /path/to/lib/updates.sh
#   source /path/to/lib/commands.sh
#
#   # Then call command functions as needed
#   run_status "/path/to/project"
#   run_version

run_update() {
  local repo_dir="$ROOT_DIR"
  local old_ver

  if [ ! -d "$repo_dir/.git" ]; then
    printf '%s\n' "codesop 不是 git 仓库，无法更新" >&2
    printf '%s\n' "请重新克隆：git clone https://github.com/veniai/codesop.git ~/codesop" >&2
    exit 1
  fi

  old_ver="$(current_version)"
  printf '%s\n' "当前版本：$old_ver"
  printf '%s\n' "检查更新..."

  cd "$repo_dir"

  # 始终先 fetch 确保远程状态最新
  printf '%s\n' "正在 fetch 远程..."
  local _remote
  _remote="$(git rev-parse --abbrev-ref '@{u}' 2>/dev/null | sed 's|/.*||' || echo "origin")"
  if command -v timeout >/dev/null 2>&1; then
    timeout 10 git fetch "$_remote" 2>/dev/null || {
      printf '%s\n' "fetch 失败，请检查网络" >&2
      exit 1
    }
  else
    git fetch "$_remote" 2>/dev/null || {
      printf '%s\n' "fetch 失败，请检查网络" >&2
      exit 1
    }
  fi

  local local_hash remote_hash
  local_hash="$(git rev-parse HEAD)"
  remote_hash="$(git rev-parse @{u} 2>/dev/null || echo "")"

  if [ -z "$remote_hash" ]; then
    remote_hash="$(git rev-parse origin/main 2>/dev/null || echo "")"
  fi

  if [ -z "$remote_hash" ]; then
    printf '%s\n' "无法获取远程版本" >&2
    exit 1
  fi

  if [ "$local_hash" = "$remote_hash" ]; then
    printf '%s\n' "已是最新版本。"
    printf '%s\n' "重新同步本机宿主集成..."
    bash "$ROOT_DIR/setup" --host auto
    return 0
  fi

  local ahead behind
  ahead="$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")"
  behind="$(git rev-list --count HEAD..@{u} 2>/dev/null || echo "0")"

  if [ "$behind" -gt 0 ] && [ "$ahead" -gt 0 ]; then
    printf '%s\n' "本地领先 $ahead 个提交，远程有 $behind 个新提交，存在分叉。"
    printf '%s\n' "请手动处理：cd $repo_dir && git rebase 或 git merge"
    printf '%s\n' "重新同步本机宿主集成..."
    bash "$ROOT_DIR/setup" --host auto
    return 0
  fi

  if [ "$ahead" -gt 0 ]; then
    printf '%s\n' "本地领先上游 $ahead 个提交，远程无新提交。"
    printf '%s\n' "重新同步本机宿主集成..."
    bash "$ROOT_DIR/setup" --host auto
    return 0
  fi

  printf '%s\n' "发现 $behind 个新提交，正在更新..."
  git pull --ff-only 2>/dev/null || {
    # ff-only 失败时尝试 stash + pull + pop
    if git diff --quiet && git diff --cached --quiet; then
      printf '%s\n' "更新失败，可能存在冲突。" >&2
      printf '%s\n' "请手动处理：cd $repo_dir && git pull" >&2
      exit 1
    fi
    printf '%s\n' "存在未提交改动，尝试 stash 后更新..."
    git stash push -m "codesop-update-$(date +%s)" 2>/dev/null || {
      printf '%s\n' "stash 失败，请手动处理：cd $repo_dir && git pull" >&2
      exit 1
    }
    if git pull --ff-only 2>/dev/null; then
      if ! git stash pop 2>/dev/null; then
        printf '%s\n' "更新成功但 stash pop 存在冲突，请手动解决：cd $repo_dir && git stash pop" >&2
        exit 1
      fi
    else
      git stash pop 2>/dev/null || true
      printf '%s\n' "更新失败，可能存在冲突。" >&2
      printf '%s\n' "请手动处理：cd $repo_dir && git pull" >&2
      exit 1
    fi
  }

  local new_ver
  new_ver="$(current_version)"
  printf '%s\n' "更新完成：$old_ver → $new_ver"
  printf '%s\n' "重新同步本机宿主集成..."
  bash "$ROOT_DIR/setup" --host auto

  local changes
  changes="$(git log --oneline "$old_ver".."$new_ver" 2>/dev/null || git log --oneline -5)"
  if [ -n "$changes" ]; then
    printf '\n%s\n' "最近变更："
    printf '%s\n' "$changes"
  fi
}

run_version() {
  printf '%s\n' "codesop $(current_version)"
}

run_setup() {
  local host="${1:-auto}"
  bash "$ROOT_DIR/setup" --host "$host"
}

run_status() {
  local target_dir="${1:-.}"
  local branch="unknown"
  local untracked="0"
  local uncommitted="0"
  local last_commit="none"
  local file_count="0"
  local todo_count="0"
  local fixme_count="0"

  if git -C "$target_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch="$(git -C "$target_dir" branch --show-current 2>/dev/null || echo "unknown")"
    local git_status
    git_status="$(git -C "$target_dir" status --porcelain 2>/dev/null || true)"
    untracked="$(printf '%s\n' "$git_status" | awk 'BEGIN{count=0} /^\?\? /{count++} END{print count}')"
    uncommitted="$(printf '%s\n' "$git_status" | awk 'BEGIN{count=0} NF && $0 !~ /^\?\? /{count++} END{print count}')"
    last_commit="$(git -C "$target_dir" log -1 --format="%ar" 2>/dev/null || echo "none")"
  fi

  file_count="$(find "$target_dir" -type f -not -path "$target_dir/.git/*" 2>/dev/null | wc -l | tr -d ' ')"
  todo_count="$( (grep -r "TODO" --include="*.md" --include="*.sh" --include="*.js" --include="*.ts" "$target_dir" 2>/dev/null || true) | wc -l | tr -d ' ' )"
  fixme_count="$( (grep -r "FIXME" --include="*.md" --include="*.sh" --include="*.js" --include="*.ts" "$target_dir" 2>/dev/null || true) | wc -l | tr -d ' ' )"

  printf '%s\n' "## 项目状态（纯事实）"
  printf '\n%s\n' "**版本信息**:"
  printf '%s\n' "- codesop: $(current_version)"
  printf '\n%s\n' "**Git 状态**:"
  printf '%s\n' "- 分支: $branch"
  printf '%s\n' "- 未跟踪: $untracked 文件"
  printf '%s\n' "- 未提交: $uncommitted 文件"
  printf '%s\n' "- 最近提交: $last_commit"
  printf '\n%s\n' "**配置文件**:"
  for config in CLAUDE.md AGENTS.md PRD.md PLAN.md; do
    if [ -f "$target_dir/$config" ]; then
      printf '%s\n' "- $config: ✓ 存在"
    else
      printf '%s\n' "- $config: ✗ 不存在"
    fi
  done
  printf '\n%s\n' "**代码统计**:"
  printf '%s\n' "- 文件数: $file_count"
  printf '%s\n' "- TODO: $todo_count"
  printf '%s\n' "- FIXME: $fixme_count"
}

run_diagnose() {
  local target_dir="${1:-.}"
  local signals=""
  local diagnosis=""
  local stage=""
  local confidence=""
  local branch=""
  local uncommitted=""

  source "$ROOT_DIR/scripts/collect-signals.sh"
  source "$ROOT_DIR/scripts/diagnose.sh"
  source "$ROOT_DIR/scripts/recommend.sh"

  signals="$(collect_signals "$target_dir")"
  diagnosis="$(diagnose_project "$signals")"
  stage="$(printf '%s\n' "$diagnosis" | awk -F= '/^CURRENT_STAGE=/{print $2; exit}')"
  confidence="$(printf '%s\n' "$diagnosis" | awk -F= '/^STAGE_CONFIDENCE=/{print $2; exit}')"
  branch="$(printf '%s\n' "$signals" | awk -F= '/^GIT_BRANCH=/{print $2; exit}')"
  uncommitted="$(printf '%s\n' "$signals" | awk -F= '/^GIT_UNCOMMITTED=/{print $2; exit}')"

  printf '%s\n' "## 项目诊断"
  printf '\n%s\n' "**当前阶段**: $stage"
  printf '%s\n' "**置信度**: $confidence"
  printf '\n%s\n' "**健康状态**:"
  printf '%s\n' "- Git: $branch 分支，$uncommitted 个未提交文件"
  if printf '%s\n' "$diagnosis" | grep -q '^HEALTH_ISSUES='; then
    printf '%s\n' "- 问题: $(printf '%s\n' "$diagnosis" | awk -F= '/^HEALTH_ISSUES=/{print $2; exit}')"
  fi
  printf '\n'
  recommend_skills "$diagnosis"
  rm -rf "/tmp/codesop-git-$$"
}
