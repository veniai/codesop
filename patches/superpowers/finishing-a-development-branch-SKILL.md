<!--
  codesop patch: finishing-a-development-branch
  Based on: superpowers v6.0.2
  Changes vs upstream:
    1. Removed 4-option interactive menu — goes straight to push + PR (autonomous flow)
    2. forge-neutral PR operations — no hardcoded `gh`; model uses its forge tooling
    3. Added PR existence check — skip creation if a PR already exists for the branch
    4. Added git fetch --prune after PR to clean stale remote tracking refs
    5. Keeps worktree after PR (adopts upstream Option 2 behavior) for review iteration
    6. Retains upstream worktree provenance cleanup guidance for merge/discard paths
  Why: codesop pipelines have already decided the finishing strategy; the menu breaks
    autonomous execution. forge-neutrality avoids locking to GitHub. Keeping the worktree
    after PR lets the user iterate on review feedback in the same workspace. PR-exists
    check prevents duplicate PRs on retry; ref pruning prevents stale origin refs.
  Revert: delete this file and run `bash setup --host claude` to restore upstream version.
-->
---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to push and create a PR - guides branch push, forge-neutral PR creation, and post-PR ref cleanup; keeps worktree for review iteration
---

# Finishing a Development Branch

## Overview

Complete development work by pushing the branch and creating a PR directly. Worktree is intentionally kept alive for review iteration.

**Core principle:** Verify tests → Determine base → Push + create PR → Prune remote refs.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## The Process

### Step 1: Verify Tests

**Before pushing, verify tests pass:**

```bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

**If tests fail:**
```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with push/PR until tests pass.
```

Stop. Don't proceed to Step 2.

**If tests pass:** Continue to Step 2.

### Step 2: Determine Base Branch

```bash
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

Or ask: "This branch split from main - is that correct?"

### Step 3: Push and Create PR

Check whether a PR already exists for this branch using your forge's tooling (e.g. `gh`, `glab`). If one exists, skip creation; otherwise push and create a PR via the same tooling.

```bash
# Push branch
git push -u origin <feature-branch>
```

Then create the PR with your forge tooling — e.g. the GitHub CLI (`gh`), the GitLab CLI (`glab`), or the equivalent for your platform. Skip creation if a PR already exists for this branch.

**Do NOT clean up the worktree** — it stays alive for PR review iteration. Worktree lifecycle is managed elsewhere: EnterWorktree-managed worktrees exit via the platform's exit tool; merged/orphan branches are detected by the codesop git-health check.

### Step 4: Post-PR Remote Ref Cleanup

```bash
# Prune stale remote tracking refs (origin/feat/xxx after GitHub deletes the branch)
git fetch --prune 2>/dev/null || true
```

## Worktree Cleanup Guidance (merge / discard paths only)

The PR path above intentionally keeps the worktree. If a future flow merges or discards locally, clean up only worktrees you created:

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
WORKTREE_PATH=$(git rev-parse --show-toplevel)
```

- If `GIT_DIR == GIT_COMMON`: normal repo, no worktree to clean.
- If the worktree path is under `.worktrees/` or `worktrees/`: codesop/superpowers created it — `cd` to the main repo root, then `git worktree remove "$WORKTREE_PATH"` and `git worktree prune`.
- Otherwise: the harness owns this workspace. Do NOT remove it; use the platform's workspace-exit tool.

## Common Mistakes

**Skipping test verification**
- **Problem:** Push broken code, create a failing PR
- **Fix:** Always verify tests before pushing

**Hardcoding `gh` as the forge CLI**
- **Problem:** Breaks for GitLab / Bitbucket / Gitea forges
- **Fix:** Use whatever forge tooling the user's environment provides (e.g. `gh`, `glab`); treat `gh` as an example, not a requirement

**Creating a duplicate PR on retry**
- **Problem:** Finishing is re-run after a push failure; a second PR opens
- **Fix:** Check for an existing PR on this branch before creating one

**Cleaning up worktree for the PR path**
- **Problem:** Removing the worktree the user needs to iterate on review feedback
- **Fix:** Keep the worktree after PR; only the merge/discard guidance paths ever remove it

**Deleting branch before removing worktree**
- **Problem:** `git branch -d` fails because a worktree still references the branch
- **Fix:** Remove the worktree first, then delete the branch

**Running git worktree remove from inside the worktree**
- **Problem:** Command fails silently when CWD is inside the worktree being removed
- **Fix:** Always `cd` to the main repo root before `git worktree remove`

**Cleaning up harness-owned worktrees**
- **Problem:** Removing a worktree the harness created causes phantom state
- **Fix:** Only clean up worktrees under `.worktrees/` or `worktrees/`

## Red Flags

**Never:**
- Proceed with failing tests
- Hardcode `gh` as the only forge CLI
- Create a PR without first checking for an existing one
- Delete work without confirmation
- Force-push without explicit request
- Remove a worktree before confirming merge success
- Clean up worktrees you didn't create (provenance check)
- Run `git worktree remove` from inside the worktree

**Always:**
- Verify tests before pushing
- Determine base branch before pushing
- Check for an existing PR before creating one
- Keep the worktree after PR
- Run `git fetch --prune` after PR
- `cd` to main repo root before any worktree removal
