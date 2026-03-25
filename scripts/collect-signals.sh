#!/bin/bash

collect_signals() {
  local project_dir="${1:-.}"
  local cache_dir="/tmp/codesop-git-$$"
  local cache_file="$cache_dir/signals"
  local signals=""
  local git_status=""
  local branch="unknown"
  local untracked="0"
  local uncommitted="0"
  local last_commit="none"

  if [ -f "$cache_file" ]; then
    git_part="$(cat "$cache_file")"
  else
    mkdir -p "$cache_dir"

    if git -C "$project_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      branch="$(git -C "$project_dir" branch --show-current 2>/dev/null || echo "unknown")"
      git_status="$(git -C "$project_dir" status --porcelain 2>/dev/null || true)"
      untracked="$(printf '%s\n' "$git_status" | awk 'BEGIN{count=0} /^\?\? /{count++} END{print count}')"
      uncommitted="$(printf '%s\n' "$git_status" | awk 'BEGIN{count=0} NF && $0 !~ /^\?\? /{count++} END{print count}')"
      last_commit="$(git -C "$project_dir" log -1 --format="%ar" 2>/dev/null || echo "none")"
    fi

    git_part="GIT_BRANCH=$branch
GIT_UNTRACKED=$untracked
GIT_UNCOMMITTED=$uncommitted
GIT_LAST_COMMIT=$last_commit"
    printf '%s\n' "$git_part" >"$cache_file"
  fi

  signals+="$git_part"$'\n'

  for config in CLAUDE.md AGENTS.md PRD.md PLAN.md README.md; do
    if [ -f "$project_dir/$config" ]; then
      signals+="CONFIG_${config%.*}_MD=true"$'\n'
    else
      signals+="CONFIG_${config%.*}_MD=false"$'\n'
    fi
  done

  if [ -f "$project_dir/package.json" ]; then
    signals+="HAS_PACKAGE_JSON=true"$'\n'
  else
    signals+="HAS_PACKAGE_JSON=false"$'\n'
  fi

  printf '%s' "$signals"
}
