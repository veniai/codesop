# Git Health Check Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add git health detection to the codesop workbench so orphaned branches are detected and offered for cleanup when starting a new task.

**Architecture:** Add `check_git_health()` to `lib/detection.sh` using `git -C` for all operations (no `cd`). Integrate into SKILL.md step 7 as an inline bash call. Results surface through the existing `**注意**` field in the workbench summary. No new skills, commands, or routes.

**Tech Stack:** Bash, git CLI, gh CLI (optional)

---

## File Structure

| File | Responsibility |
|------|---------------|
| `lib/detection.sh` | Add `check_git_health()` — detects orphaned branches, leftover current branch, closed-unmerged branches |
| `SKILL.md` | Add git health check call in step 7, add grading rules for `**注意**` output, add cleanup transition task behavior |
| `tests/detect-environment.sh` | Add test for `check_git_health` output format and SKILL.md contains health check reference |

---

### Task 1: Add `check_git_health()` to `lib/detection.sh`

**Files:**
- Modify: `lib/detection.sh` (append after `find_superpowers_plugin_path()`)

- [ ] **Step 1: Add the function at end of `lib/detection.sh`**

Append after line 178 (end of file):

```bash

# Check git branch health for the codesop workbench.
# Detects: orphaned local branches (merged into origin/main), leftover current branch,
# and branches with closed-but-unmerged PRs.
# Uses git -C throughout to avoid modifying caller's working directory.
# Outputs machine-readable KEY=VALUE lines.
check_git_health() {
  local root
  root="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "HEALTH_SKIP=no-git"; return 0; }

  # Precondition: origin remote must exist
  git -C "$root" remote get-url origin >/dev/null 2>&1 || { echo "HEALTH_SKIP=no-remote"; return 0; }

  # 1. Detect main branch (local operation, no network)
  local main_branch
  main_branch=$(git -C "$root" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
  : "${main_branch:=main}"

  # 2. Fetch latest to get accurate merge status (with timeout to prevent hanging)
  timeout 10 git -C "$root" fetch origin "$main_branch" --quiet --prune 2>/dev/null || true

  # 3. Find orphaned local branches (merged into origin/main)
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

  # Output machine-readable result
  echo "ORPHAN_COUNT=$orphan_count"
  echo "ORPHANS=$orphans"
  echo "CURRENT=$current"
  echo "IS_LEFTOVER=$is_leftover"
  echo "MAIN_BRANCH=$main_branch"
}
```

- [ ] **Step 2: Verify function loads without syntax errors**

Run: `bash -n ~/codesop/lib/detection.sh && echo "SYNTAX OK"`
Expected: `SYNTAX OK`

- [ ] **Step 3: Run a quick smoke test**

Run: `(source ~/codesop/lib/detection.sh && check_git_health)`
Expected: Output lines containing `ORPHAN_COUNT=`, `CURRENT=main`, `IS_LEFTOVER=false` (since we're on main in the codesop repo)

- [ ] **Step 4: Commit**

```bash
git add lib/detection.sh
git commit -m "feat: add check_git_health() to detection.sh"
```

---

### Task 2: Integrate git health check into SKILL.md step 7

**Files:**
- Modify: `SKILL.md` (step 7 and §4.1)

- [ ] **Step 1: Add git health check call to step 7**

In SKILL.md, find the step 7 block that currently ends at `When git status is dirty and the user did not explicitly say to ignore it, prefer a cleanup-first workflow before recommending roadmap-next work.`

Add after that paragraph:

```markdown
   Also run git health check:
   ```bash
   (source ~/codesop/lib/detection.sh && check_git_health) || echo "Git 健康检查跳过"
   ```
   Parse the output to detect:
   - `HEALTH_SKIP=*` → skip, no warning
   - `ORPHAN_COUNT > 0` → add to `**注意**`: `Git 有 N 个已 merge 的孤立分支（branch list），建议清理`
   - `IS_LEFTOVER=true` → add to `**注意**`: `当前在 feat/xxx 分支，无 open PR，疑似上次任务残留`
   - `IS_LEFTOVER=unknown` → add to `**注意**`: `当前在 feat/xxx 分支，无法确认 PR 状态（gh 不可用）`
```

- [ ] **Step 2: Add cleanup transition task behavior to step 10.5**

In SKILL.md, find the **衔接任务 — 创建分支** section. Add a new衔接任务 rule after it:

```markdown
**衔接任务 — Git 残留清理**：
- 条件：git 健康检查检测到 ORPHAN_COUNT > 0 或 IS_LEFTOVER=true
- 插入位置：pipeline 最前面（在创建分支之前）
- 执行时：先检查工作区是否干净，然后 git checkout main → git pull → 删除已 merge 的 feat/*/fix/*/chore/* 分支（排除当前分支） → git fetch --prune
- 如果工作区脏 → 中止清理，在 **注意** 中提示
```

- [ ] **Step 3: Verify SKILL.md contains the new content**

Run: `grep -c 'check_git_health' ~/codesop/SKILL.md`
Expected: `2` (step 7 call + step 7 description)

Run: `grep -c 'Git 残留清理' ~/codesop/SKILL.md`
Expected: `1`

- [ ] **Step 4: Run existing tests to ensure nothing broke**

Run: `bash tests/detect-environment.sh`
Expected: `PASS`

Run: `bash tests/codesop-router.sh`
Expected: `PASS`

- [ ] **Step 5: Commit**

```bash
git add SKILL.md
git commit -m "feat: integrate git health check into workbench step 7"
```

---

### Task 3: Add tests for git health check

**Files:**
- Modify: `tests/detect-environment.sh`

- [ ] **Step 1: Add test assertions to `tests/detect-environment.sh`**

Add before the `echo "PASS"` line at end of file:

```bash
# Git health check tests
health_output="$(source "$ROOT_DIR/lib/detection.sh" && check_git_health 2>/dev/null)" || health_output=""

# Function should produce output
assert_contains "$health_output" "ORPHAN_COUNT="
assert_contains "$health_output" "CURRENT="
assert_contains "$health_output" "IS_LEFTOVER="
assert_contains "$health_output" "MAIN_BRANCH="

# SKILL.md should reference git health check
assert_contains "$skill_full" "check_git_health"
assert_contains "$skill_full" "Git 健康检查跳过"
```

- [ ] **Step 2: Run the test**

Run: `bash tests/detect-environment.sh`
Expected: `PASS`

- [ ] **Step 3: Run full test suite**

Run: `bash tests/run_all.sh`
Expected: All suites PASS

- [ ] **Step 4: Commit**

```bash
git add tests/detect-environment.sh
git commit -m "test: add git health check assertions"
```

---

## Self-Review

### 1. Spec coverage

| Spec requirement | Task |
|-----------------|------|
| `check_git_health()` in `lib/detection.sh` | Task 1 |
| `git -C` instead of `cd` | Task 1 (code uses `git -C "$root"`) |
| Explicit origin check | Task 1 (first guard) |
| `symbolic-ref` for main branch detection | Task 1 |
| Pattern `feat/* fix/* chore/*` | Task 1 |
| Three-state leftover detection | Task 1 |
| Integration in SKILL.md step 7 | Task 2 Step 1 |
| Result grading rules | Task 2 Step 1 |
| Cleanup transition task | Task 2 Step 2 |
| Tests | Task 3 |
| `timeout` on `git fetch` | Task 1 (added per CLAUDE.md gotcha) |

### 2. Placeholder scan

No TBD, TODO, "implement later", "add appropriate error handling" found. All steps contain complete code.

### 3. Type consistency

- Function name `check_git_health` used consistently across all tasks.
- Output format `KEY=VALUE` consistent between Task 1 (implementation) and Task 3 (test assertions).
- SKILL.md references match the actual output keys: `ORPHAN_COUNT`, `IS_LEFTOVER`, `HEALTH_SKIP`.

No issues found.
