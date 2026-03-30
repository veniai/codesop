#!/bin/bash
# commands.sh - Command implementations for the supported codesop CLI surface

run_update() {
  local repo_dir="$ROOT_DIR"
  local old_ver
  local old_hash

  if [ ! -d "$repo_dir/.git" ]; then
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
  local remote_name
  remote_name="$(git rev-parse --abbrev-ref '@{u}' 2>/dev/null | sed 's|/.*||' || echo "origin")"
  if command -v timeout >/dev/null 2>&1; then
    timeout 10 git fetch "$remote_name" 2>/dev/null || {
      printf '%s\n' "fetch 失败，请检查网络" >&2
      exit 1
    }
  else
    git fetch "$remote_name" 2>/dev/null || {
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
  local new_hash
  new_ver="$(current_version)"
  new_hash="$(git rev-parse HEAD 2>/dev/null || echo "")"
  printf '%s\n' "更新完成：$old_ver → $new_ver"
  printf '%s\n' "重新同步本机宿主集成..."
  bash "$ROOT_DIR/setup" --host auto

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
}

run_setup() {
  local host="${1:-auto}"
  bash "$ROOT_DIR/setup" --host "$host"
}
