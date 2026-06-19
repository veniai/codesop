# Fix: Host-Aware Dependency Check + Branch Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix two bugs: (1) `_check_skills_all()` reports "superpowers 未安装于: Codex" for users who don't use Codex; (2) finishing skill patch doesn't prune remote tracking refs after branch operations.

**Architecture:** Bug 1: Add host presence detection (`~/.codex/` exists?) before reporting per-host superpowers gaps. Bug 2: Add `git fetch --prune` to finishing patch after push+PR step. Both changes are surgical — no new functions, no refactoring.

**Tech Stack:** Bash, markdown

---

### Task 1: Fix `_check_skills_all()` host-aware filtering

**Files:**
- Modify: `lib/init-interview.sh:244-258`

- [ ] **Step 1: Replace per-host missing check with host-presence guard**

Replace lines 244-258 in `lib/init-interview.sh` (from `if [ $sp_found -eq 0 ]; then` through the closing `fi` of the else block) with:

```bash
  if [ $sp_found -eq 0 ]; then
    echo "⚠ superpowers 未安装"
    echo "  Claude Code：/plugin install superpowers"
    [ -d "$HOME/.codex" ] && echo "  Codex：按官方文档安装 https://raw.githubusercontent.com/obra/superpowers/refs/heads/main/.codex/INSTALL.md"
  else
    # Suggest missing per-host installations — only for hosts that are actually present
    local sp_missing=""
    [ $sp_cc_found -eq 0 ] && [ -d "$HOME/.claude" ] && sp_missing="$sp_missing Claude Code"
    [ $sp_codex_found -eq 0 ] && [ -d "$HOME/.codex" ] && sp_missing="$sp_missing Codex"
    if [ -n "$sp_missing" ]; then
      echo "  ⚠ superpowers 未安装于：$sp_missing"
      [ $sp_cc_found -eq 0 ] && [ -d "$HOME/.claude" ] && echo "    Claude Code：/plugin install superpowers"
      [ $sp_codex_found -eq 0 ] && [ -d "$HOME/.codex" ] && echo "    Codex：按官方文档安装 https://raw.githubusercontent.com/obra/superpowers/refs/heads/main/.codex/INSTALL.md"
    fi
  fi
```

Key change: every `[ $sp_cc_found -eq 0 ]` and `[ $sp_codex_found -eq 0 ]` now also checks `[ -d "$HOME/.claude" ]` or `[ -d "$HOME/.codex" ]` before adding to the missing list. Same for the "fully missing" branch — Codex install instructions only show if `~/.codex/` exists.

- [ ] **Step 2: Verify existing tests still pass**

Run: `bash tests/codesop-init-interview.sh 2>&1 | tail -5`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add lib/init-interview.sh
git commit -m "fix: skip superpowers per-host gap for inactive hosts"
```

### Task 2: Add test for host-aware filtering

**Files:**
- Modify: `tests/codesop-init-interview.sh` (append new test)

- [ ] **Step 1: Add test function that verifies Codex gap is NOT reported when ~/.codex absent**

Append the following test function to `tests/codesop-init-interview.sh`, before the final `run_tests` call:

```bash
# ============================================================================
# Test N: _check_skills_all does not warn about Codex when ~/.codex absent
# ============================================================================
test_check_skills_no_codex_env() {
  local tmpdir
  tmpdir=$(mktemp -d)

  # Set up a minimal Claude Code superpowers in the temp home
  mkdir -p "$tmpdir/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.0"
  echo "5.0.0" > "$tmpdir/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.0/VERSION"
  mkdir -p "$tmpdir/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.0/.git"

  # Ensure NO ~/.codex directory exists
  [ -d "$tmpdir/.codex" ] && rm -rf "$tmpdir/.codex"

  local output
  output=$(HOME="$tmpdir" _check_skills_all 2>&1) || true

  # Should NOT mention Codex in missing/warning
  if echo "$output" | grep -q "未安装.*Codex\|Codex.*未安装\|未安装于.*Codex"; then
    fail "_check_skills_all should not warn about Codex when ~/.codex is absent. Output: $output"
  else
    pass "_check_skills_all correctly omits Codex gap when ~/.codex absent"
  fi

  rm -rf "$tmpdir"
}
```

Also add `test_check_skills_no_codex_env` to the test runner function at the bottom of the file. Find the function that calls all the `test_*` functions and add the new one.

- [ ] **Step 2: Run test to verify it passes**

Run: `bash tests/codesop-init-interview.sh 2>&1 | tail -10`
Expected: PASS — new test passes (no Codex warning when `~/.codex` absent)

Note: If the test fails initially because `_check_skills_all` doesn't find superpowers in the fake home (since it also needs `find_superpowers_plugin_path` which looks at the real home), adjust the test to source the function directly and mock the detection. If that's too complex, skip the unit test and rely on manual verification.

- [ ] **Step 3: Commit with Task 1 if still uncommitted, otherwise separate commit**

```bash
git add tests/codesop-init-interview.sh
git commit -m "test: verify _check_skills_all skips Codex warning when host absent"
```

### Task 3: Add `git fetch --prune` to finishing patch

**Files:**
- Modify: `patches/superpowers/finishing-a-development-branch-SKILL.md:82-94`

- [ ] **Step 1: Add post-PR cleanup section to the finishing patch**

Replace lines 82-94 in `patches/superpowers/finishing-a-development-branch-SKILL.md` (from `Then: Cleanup Worktree (Step 4)` through the end of Step 4) with:

```markdown
Then: Post-PR Cleanup (Step 4)

### Step 4: Post-PR Cleanup

After the PR is created (or already exists), clean up local refs:

```bash
# Prune stale remote tracking refs (origin/feat/xxx after GitHub deletes the branch)
git fetch --prune 2>/dev/null || true

# If in a worktree, remove it
git worktree list | grep "$(git branch --show-current)" || true
```

If in a worktree:
```bash
git worktree remove <worktree-path>
```

Note: `git fetch --prune` cleans up remote tracking branches that no longer exist on the remote (e.g., after `gh pr merge --delete-branch` or GitHub auto-delete). This is a lightweight operation and safe to run even when no pruning is needed.
```

Also update the patch header comment (lines 3-11) to document the new change. Replace the existing `Changes vs upstream:` block (lines 5-8) with:

```markdown
  Changes vs upstream:
    1. Removed 4-option interactive menu (direct push / draft PR / squash merge / manual)
    2. Goes straight to push + PR creation
    3. Added PR existence check — skips `gh pr create` if one already exists for the branch
    4. Added `git fetch --prune` after PR creation to clean stale remote tracking refs
```

And update the `Why:` line to include the reason:

```markdown
  Why: codesop pipelines have already decided the finishing strategy; the menu adds a decision
  point that breaks autonomous execution. PR existence check prevents duplicate PRs when
  finishing is retried after a push failure. Remote ref pruning prevents stale origin/feat/xxx
  refs from accumulating after GitHub deletes merged branches.
```

- [ ] **Step 2: Run setup to resync the patch**

Run: `bash setup --host claude 2>&1 | tail -10`
Expected: All steps succeed

- [ ] **Step 3: Verify the installed skill has the new step**

Run: `grep -c "fetch --prune" ~/.claude/plugins/cache/claude-plugins-official/superpowers/*/skills/finishing-a-development-branch/SKILL.md`
Expected: Count >= 1 (the patched version includes the new step)

- [ ] **Step 4: Commit**

```bash
git add patches/superpowers/finishing-a-development-branch-SKILL.md
git commit -m "fix: add git fetch --prune to finishing patch for stale remote ref cleanup"
```

### Task 4: Full test suite + resync verification

**Files:** None (verification only)

- [ ] **Step 1: Run full test suite**

Run: `bash tests/run_all.sh 2>&1`
Expected: 10 passed, 0 failed

- [ ] **Step 2: Run setup resync**

Run: `bash setup --host claude 2>&1`
Expected: All steps succeed, no errors

- [ ] **Step 3: Verify both fixes**

Run these checks:
```bash
# Bug 1: Confirm the per-host guard is in place
grep -A2 'sp_codex_found.*-eq 0' lib/init-interview.sh | head -6
# Expected: should show `[ -d "$HOME/.codex" ]` guard

# Bug 2: Confirm fetch --prune is in the installed finishing skill
grep "fetch --prune" ~/.claude/plugins/cache/claude-plugins-official/superpowers/*/skills/finishing-a-development-branch/SKILL.md
# Expected: at least one match
```
