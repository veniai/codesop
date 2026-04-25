---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to push and create a PR - handles branch push, PR creation, and worktree cleanup
---

# Finishing a Development Branch

## Overview

Complete development work by pushing the branch and creating a PR directly, then cleaning up the worktree.

**Core principle:** Verify tests → Push + PR → Clean up worktree.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## The Process

### Step 1: Verify Tests

**Before presenting options, verify tests pass:**

```bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

**If tests fail:**
```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

Stop. Don't proceed to Step 2.

**If tests pass:** Continue to Step 2.

### Step 2: Determine Base Branch

```bash
# Try common base branches
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

Or ask: "This branch split from main - is that correct?"

### Step 3: Push and Create PR

```bash
# Push branch
git push -u origin <feature-branch>

# Create PR (skip if one already exists for this branch)
if gh pr list --state open --head "$(git branch --show-current)" --json number --jq '.[0].number' 2>/dev/null | grep -q .; then
  echo "PR already exists, skipping creation."
else
  gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
<2-3 bullets of what changed>

## Test Plan
- [ ] <verification steps>
EOF
)"
fi
```

Then: Cleanup worktree (Step 4)

### Step 4: Cleanup Worktree

Check if in worktree:
```bash
git worktree list | grep $(git branch --show-current)
```

If yes:
```bash
git worktree remove <worktree-path>
```

## Common Mistakes

**Skipping test verification**
- **Problem:** Push broken code, create failing PR
- **Fix:** Always verify tests before pushing

## Red Flags

**Never:**
- Proceed with failing tests
- Force-push without explicit request

**Always:**
- Verify tests before pushing

## Integration

**Called by:**
- **subagent-driven-development** (Step 7) - After all tasks complete
- **executing-plans** (Step 4) - After all batches complete

**Pairs with:**
- **using-git-worktrees** - Cleans up worktree created by that skill
