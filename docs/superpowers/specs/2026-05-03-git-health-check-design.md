# Git Health Check — 工作台残留分支检测

> **For agentic workers:** This is a design spec for codesop workbench enhancement. Implementation will be dispatched separately.

**Goal:** When a user starts a new task via `/codesop`, automatically detect orphaned git branches and offer cleanup before proceeding.

**Architecture:** Add a git health check to the existing workbench step 7 (git context verification). Detection runs inline alongside the current branch/status/PR checks. Results surface through the existing `**注意**` field in the workbench summary — no new UI sections.

**Tech Stack:** Shell (bash), git CLI, gh CLI (optional, for PR state)

---

## Problem

codesop orchestrates development through feature branches. After a task completes, the finishing step (often handled by Codex, not superpowers) pushes the branch and creates a PR, but never:
- Switches back to main
- Deletes the local feature branch
- Prunes remote-tracking refs

Over multiple tasks, local branches accumulate. The user starts a new `/codesop` session and finds git in a messy state — wrong branch, orphaned branches everywhere.

## Current Flow (SKILL.md step 7)

```
Step 7: Verify git context
  git branch --show-current
  git log --oneline -5
  gh pr list --state open --head <branch>
  git status --short | head -10
```

This checks current state but has no concept of "git health" — it doesn't notice that 5 old feature branches are lying around.

## Design

### Detection Function

Add `check_git_health()` to `lib/detection.sh`. Called from SKILL.md step 7 alongside existing git commands.

**Design decisions** (from Codex + code-reviewer feedback):

1. **Use `git -C` instead of `cd`** — avoids modifying caller's working directory (H2)
2. **Explicit origin check first** — fail clearly if no remote configured (H3)
3. **Use `symbolic-ref` instead of `git remote show`** — no network access, no locale issues (M1)
4. **Detect branches with closed (unmerged) PRs** — warn but don't auto-delete (S8)
5. **Three-state leftover detection** — handle missing `gh` gracefully (M3)
6. **Exclude current branch from deletion** — even after checkout, double-check (H1)

```bash
# Git health check for codesop workbench
# Outputs machine-readable KEY=VALUE lines
check_git_health() {
    local root
    root="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "HEALTH_SKIP=no-git"; return 0; }

    # Precondition: origin remote must exist
    git -C "$root" remote get-url origin >/dev/null 2>&1 || { echo "HEALTH_SKIP=no-remote"; return 0; }

    # 1. Detect main branch (local, no network)
    local main_branch
    main_branch=$(git -C "$root" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
    : "${main_branch:=main}"

    # 2. Fetch latest to get accurate merge status
    git -C "$root" fetch origin "$main_branch" --quiet --prune 2>/dev/null || true

    # 3. Find orphaned local branches (merged into origin/main)
    #    Pattern: feat/*, fix/*, chore/* — common conventional branch prefixes
    local orphans
    orphans=$(git -C "$root" branch --merged "origin/$main_branch" \
        --list 'feat/*' 'fix/*' 'chore/*' --format='%(refname:short)' 2>/dev/null \
        | grep -v '^$' || true)

    # 4. Current branch state
    local current orphan_count=0
    current=$(git -C "$root" branch --show-current 2>/dev/null || echo "detached")

    if [[ -n "$orphans" ]]; then
        orphan_count=$(printf '%s\n' "$orphans" | grep -c .)
    fi

    # 5. Check if current branch is a leftover (not main, no open PR)
    #    Three-state: true / false / unknown (gh not available)
    local is_leftover=false
    if [[ "$current" != "$main_branch" && "$current" != "master" ]]; then
        if command -v gh >/dev/null 2>&1; then
            local has_open_pr
            has_open_pr=$(gh pr list --state open --head "$current" --json number --jq '.[0].number' 2>/dev/null || echo "")
            if [[ -z "$has_open_pr" ]]; then
                is_leftover=true
            fi
        else
            is_leftover=unknown
        fi
    fi

    # 6. Find branches with closed (unmerged) PRs — warn only, never auto-delete
    local closed_unmerged=""
    if command -v gh >/dev/null 2>&1; then
        local all_branches br pr_state
        all_branches=$(git -C "$root" branch --list 'feat/*' 'fix/*' 'chore/*' --format='%(refname:short)' 2>/dev/null)
        while IFS= read -r br; do
            [[ -z "$br" ]] && continue
            # Skip branches already in orphans (merged) or current branch
            if echo "$orphans" | grep -qxF "$br" 2>/dev/null; then continue; fi
            [[ "$br" == "$current" ]] && continue
            pr_state=$(gh pr list --state closed --head "$br" --json state,mergedAt --jq '.[0].mergedAt // empty' 2>/dev/null || true)
            if [[ -z "$pr_state" ]]; then
                # PR exists but was closed without merge
                local has_closed_pr
                has_closed_pr=$(gh pr list --state closed --head "$br" --json number --jq '.[0].number' 2>/dev/null || echo "")
                if [[ -n "$has_closed_pr" ]]; then
                    closed_unmerged="${closed_unmerged:+$closed_unmerged }$br"
                fi
            fi
        done <<< "$all_branches"
    fi

    # Output
    echo "ORPHAN_COUNT=$orphan_count"
    echo "ORPHANS=$orphans"
    echo "CURRENT=$current"
    echo "IS_LEFTOVER=$is_leftover"
    echo "MAIN_BRANCH=$main_branch"
    echo "CLOSED_UNMERGED=$closed_unmerged"
}
```

### Integration into SKILL.md

Add to step 7, after existing git status check:

```bash
(source ~/codesop/lib/detection.sh && check_git_health) || echo "Git 健康检查跳过"
```

### Result Grading

| State | Condition | Workbench Output |
|-------|-----------|-----------------|
| Healthy | `orphan_count == 0` AND `is_leftover != true` AND no closed-unmerged | No `**注意**` line for git health |
| Orphans | `orphan_count > 0` | `**注意**: Git 有 N 个已 merge 的孤立分支（feat/a, feat/b），建议清理` |
| Leftover | `is_leftover == true` | `**注意**: 当前在 feat/xxx 分支，无 open PR，疑似上次任务残留` |
| Leftover-unknown | `is_leftover == unknown` | `**注意**: 当前在 feat/xxx 分支，无法确认 PR 状态（gh 不可用）` |
| Closed-unmerged | Branches with closed but unmerged PRs | Append to `**注意**`: `另有 N 个分支 PR 已关闭未合并（fix/xxx），请注意` |

When multiple states coexist, combine into one `**注意**` line.

### Cleanup Action

When git health is not "Healthy", the final-line workflow instruction changes:

**Proposing new pipeline:**
```
要先清理 Git 残留（N 个孤立分支）再开始 {intent} 吗？
```

**User confirms → execute cleanup, then proceed with pipeline:**

```bash
# Pre-check: abort if dirty working tree
if git status --short | grep -q .; then
    echo "工作区有未提交改动，跳过清理"
    return 1
fi

# Switch to main
git checkout "$main_branch" || { echo "切换到 $main_branch 失败"; return 1; }
git pull

# Delete orphaned branches, excluding current branch as safety net
local_branches=$(git branch --merged "origin/$main_branch" \
    --list 'feat/*' 'fix/*' 'chore/*' --format='%(refname:short)' 2>/dev/null)
current_now=$(git branch --show-current)
echo "$local_branches" | while IFS= read -r br; do
    [[ -z "$br" ]] && continue
    [[ "$br" == "$current_now" ]] && continue  # Never delete current branch
    git branch -d "$br"
done
git fetch --prune
```

Cleanup is a **transition task** in the pipeline (衔接任务, no skill key), inserted before the first skill task.

### Example Workbench Output

**Before (orphaned branches detected):**
```md
## 工作台摘要
**状态**: feat/old-task — 上次任务已完成，有 3 个孤立分支未清理
**分支**: feat/old-task（无 open PR）
**注意**: Git 有 3 个已 merge 的孤立分支（feat/p1-ui, feat/p2-api, feat/bugfix-auth），建议清理

## Skill 生态
- 路由覆盖：✓ 路由覆盖完整

## 下一步建议
提议 Pipeline：
1. 清理 Git 残留（3 个孤立分支 + 切回 main）
2. 使用 superpowers:brainstorming Skill 做需求澄清

要先清理 Git 残留再开始新功能开发吗？
```

**After cleanup:**
```md
## 工作台摘要
**状态**: main — 已清理 3 个孤立分支，准备开始新任务
**分支**: main（无 open PR）

## Skill 生态
- 路由覆盖：✓ 路由覆盖完整

## 下一步建议
提议 Pipeline：
1. 使用 superpowers:brainstorming Skill 做需求澄清
...
```

## What We Do NOT Do

- **No remote branch deletion** — Let GitHub's "auto-delete branch" setting handle remote cleanup
- **No new Skill** — This is workbook detection + transition task, not an independent workflow
- **No new routing table entry** — Orphan detection is a precondition check, not a user scenario
- **No forced cleanup** — User can decline and proceed with new task on current branch
- **No auto-delete closed-unmerged branches** — These may contain work the user wants to keep; only warn

## Review Log

**Reviewer: code-reviewer agent**

| Issue | Severity | Resolution |
|-------|----------|------------|
| `git branch --merged` includes current branch; checkout failure causes detached HEAD | High | Added current branch exclusion in cleanup loop; checkout failure aborts cleanup |
| `cd "$root"` modifies caller's working directory | High | Switched to `git -C "$root"` throughout |
| No origin remote → silent false "healthy" | High | Added explicit origin check with clear output `HEALTH_SKIP=no-remote` |
| `git remote show origin` is slow + locale-dependent | Medium | Replaced with `git symbolic-ref refs/remotes/origin/HEAD` |
| Only `feat/*` pattern misses `fix/*`, `chore/*` | Medium | Expanded to `'feat/*' 'fix/*' 'chore/*'` |
| `gh` not installed causes false leftover detection | Medium | Three-state output: true/false/unknown |
| Dirty working tree blocks checkout during cleanup | Medium | Added pre-check, abort if dirty |
| Branch names with spaces break single-line output | Medium | ORPHANS uses newline-separated format, parsed with `IFS= read -r` |
| Closed (unmerged) PR branches treated as orphans | Suggestion | Added `CLOSED_UNMERGED` detection, warn-only |

## File Changes

| File | Change |
|------|--------|
| `lib/detection.sh` | Add `check_git_health()` function |
| `SKILL.md` | Step 7: call `check_git_health`, use result for `**注意**` line and final-line instruction |
| `tests/detect-environment.sh` | Add test for `check_git_health` output format |

Total: 3 files, no new commands, no new skills, no new routes.
