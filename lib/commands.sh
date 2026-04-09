#!/bin/bash
# commands.sh - Command implementations for the supported codesop CLI surface

# Resync host integration and run skill routing coverage check.
# Called after every update branch in run_update.
# Re-sources updates.sh so git-pulled code changes take effect immediately.
_resync_and_check() {
  printf '%s\n' "重新同步本机宿主集成..."
  bash "$ROOT_DIR/setup" --host auto

  # Re-source updates.sh so git-pulled changes take effect in this shell
  source "${ROOT_DIR}/lib/updates.sh"

  # Check plugin dependencies
  local host="unknown"
  [ -d "$HOME/.config/opencode" ] && host="opencode"
  [ -d "$HOME/.codex" ] && host="codex"
  [ -d "$HOME/.claude" ] && host="claude"
  print_dependency_report "$host"

  check_routing_coverage || true
}

run_update() {
  local repo_dir="$ROOT_DIR"
  local old_ver
  local old_hash

  if ! git -C "$repo_dir" rev-parse --git-dir >/dev/null 2>&1; then
    printf '%s\n' "codesop 不是 git 仓库，无法更新" >&2
    printf '%s\n' "请重新克隆：git clone https://github.com/veniai/codesop.git ~/codesop" >&2
    exit 1
  fi

  old_ver="$(current_version)"
  old_hash="$(git -C "$repo_dir" rev-parse HEAD 2>/dev/null || echo "")"
  printf '%s\n' "当前版本：$old_ver"
  printf '%s\n' "检查更新..."

  cd "$repo_dir"

  printf '%s\n' "正在 fetch 远程..."
  if command -v timeout >/dev/null 2>&1; then
    timeout 10 git fetch origin 2>/dev/null || {
      printf '%s\n' "fetch 失败，请检查网络" >&2
      exit 1
    }
  else
    git fetch origin 2>/dev/null || {
      printf '%s\n' "fetch 失败，请检查网络" >&2
      exit 1
    }
  fi

  # Always check origin/main, not current branch's upstream
  local local_hash remote_hash current_branch
  local_hash="$(git rev-parse HEAD)"
  current_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
  remote_hash="$(git rev-parse origin/main 2>/dev/null || echo "")"

  if [ -n "$current_branch" ] && [ "$current_branch" != "main" ]; then
    printf '%s\n' "当前在 $current_branch 分支，检查 origin/main..."
  fi

  if [ -z "$remote_hash" ]; then
    printf '%s\n' "无法获取 origin/main" >&2
    exit 1
  fi

  if [ "$local_hash" = "$remote_hash" ]; then
    printf '%s\n' "已是最新版本。"
    _resync_and_check
    return 0
  fi

  local ahead behind
  ahead="$(git rev-list --count origin/main..HEAD 2>/dev/null || echo "0")"
  behind="$(git rev-list --count HEAD..origin/main 2>/dev/null || echo "0")"

  if [ "$behind" -gt 0 ] && [ "$ahead" -gt 0 ]; then
    printf '%s\n' "本地领先 $ahead 个提交，origin/main 有 $behind 个新提交，存在分叉。"
    printf '%s\n' "请手动处理：cd $repo_dir && git rebase 或 git merge"
    _resync_and_check
    return 0
  fi

  if [ "$ahead" -gt 0 ]; then
    printf '%s\n' "本地领先 origin/main $ahead 个提交，远程无新提交。"
    _resync_and_check
    return 0
  fi

  printf '%s\n' "发现 $behind 个新提交，正在更新..."
  git pull --ff-only origin main 2>/dev/null || {
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

    if git pull --ff-only origin main 2>/dev/null; then
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
  local new_hash
  new_ver="$(current_version)"
  new_hash="$(git rev-parse HEAD 2>/dev/null || echo "")"
  printf '%s\n' "更新完成：$old_ver → $new_ver"
  _resync_and_check

  local changes
  if [ -n "$old_hash" ] && [ -n "$new_hash" ] && [ "$old_hash" != "$new_hash" ]; then
    changes="$(git log --oneline "$old_hash".."$new_hash" 2>/dev/null || true)"
  elif [ "$old_ver" != "$new_ver" ]; then
    changes="$(git log --oneline "$old_ver".."$new_ver" 2>/dev/null || true)"
  else
    changes=""
  fi

  if [ -z "$changes" ]; then
    changes="$(git log --oneline -5 2>/dev/null || true)"
  fi
  if [ -n "$changes" ]; then
    printf '\n%s\n' "最近变更："
    printf '%s\n' "$changes"
  fi

  # Check if templates changed — hint user to re-run init for adaptation
  if [ -n "$old_hash" ] && [ -n "$new_hash" ] && [ "$old_hash" != "$new_hash" ]; then
    if ! git diff --quiet "$old_hash".."$new_hash" -- templates/ 2>/dev/null; then
      printf '\n%s\n' "模板已更新，建议对已有项目运行 /codesop-init"
    fi
  fi
}

