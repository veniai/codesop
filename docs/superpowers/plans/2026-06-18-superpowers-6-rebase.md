# superpowers 6.0 Re-baseline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Re-base codesop's superpowers patches onto v6.0.2 so they apply again, drop 2 absorbed reviewer patches, absorb 6.0's improvements, and add drift hardening — without changing the whole-file-overwrite delivery mechanism.

**Architecture:** Keep `patch_skills()` whole-file overwrite. Rewrite 3 surviving patch files against 6.0.2 upstream (splice codesop additions into 6.0.2 base, don't regress 6.0 improvements), delete 2 reviewer patches + their setup mapping, bump min_version 5.1.0→6.0.2, fix the one version-asserting test, add a re-base checklist doc, verify the existing drift warning, bump release artifacts.

**Tech Stack:** Bash (setup, dependencies.sh), Markdown (skill patches, checklist doc), shell test suite (tests/run_all.sh).

## Global Constraints

- Target upstream: superpowers **6.0.2**, installed at `~/.claude/plugins/cache/claude-plugins-official/superpowers/6.0.2/skills/`
- Branch: **`feat/superpowers-6-rebase`** (already created; spec committed at `docs/superpowers/specs/2026-06-18-superpowers-6-rebase-design.md`)
- Delivery mechanism stays **whole-file overwrite** (`patch_skills()` `cp` on diff) — do NOT switch to overlay/external injection
- **Do not regress any 6.0 improvement**: per-session-key visual companion, per-task Interfaces block, Global Constraints, Task Right-Sizing, worktree provenance cleanup. Each re-base task's verification step diffs the new patch against 6.0.2 upstream and must show ONLY intended codesop additions
- Every patch file MUST end with the standard header: `Based on: superpowers v6.0.2` + accurate `Changes vs upstream` list + `Why` + `Revert: delete this file and run \`bash setup --host claude\` to restore upstream version.`
- `dep_patch_compat` gates on **major.minor**; `min_version=6.0.2` means "based on 6.0.2, compatible with 6.0.x"
- Don't bump `min_version` to 6.0.2 until the 3 patch files are re-based (else `setup` would apply stale 5.1-based content over 6.0.2) — Task 5 is the version flip + apply gate
- Commit only task-relevant files; commit message prefix follows repo convention (`feat:`/`fix:`/`chore:`/`docs:`/`refactor:`)

---

## File Structure

- `patches/superpowers/brainstorming-SKILL.md` — re-based (6.0.2 base + Grill Mode/ADR/Domain-Delta/CONTEXT-check)
- `patches/superpowers/writing-plans-SKILL.md` — re-based (6.0.2 base + 9 codesop sections, heaviest)
- `patches/superpowers/finishing-a-development-branch-SKILL.md` — re-based (6.0.2 base + skip-menu/forge-neutral/PR-check/prune, keep worktree after PR)
- `patches/superpowers/subagent-driven-development-spec-reviewer-prompt.md` — **delete**
- `patches/superpowers/subagent-driven-development-code-quality-reviewer-prompt.md` — **delete**
- `setup` — remove 2 reviewer mapping blocks in `patch_skills()` + fix stale finishing comment
- `config/dependencies.sh` — `min_version` 5.1.0 → 6.0.2
- `tests/dep-upgrade.sh` — line 14 version assertion 5.1.0 → 6.0.2
- `docs/superpowers/playbooks/rebase-superpowers-patches.md` — new checklist doc
- `VERSION`, `skill.json`, `CHANGELOG.md` — release artifacts

---

### Task 1: Delete reviewer patches + remove setup mapping blocks + fix stale comment

**Files:**
- Delete: `patches/superpowers/subagent-driven-development-spec-reviewer-prompt.md`
- Delete: `patches/superpowers/subagent-driven-development-code-quality-reviewer-prompt.md`
- Modify: `setup` (remove 2 mapping blocks in `patch_skills()`; fix stale finishing comment)

**Interfaces:**
- Consumes: superpowers 6.0.2 has no `spec-reviewer-prompt.md` / `code-quality-reviewer-prompt.md` (merged into `task-reviewer-prompt.md`)
- Produces: `setup` `patch_skills()` references only 3 patches (writing-plans, finishing, brainstorming); no stale "not found, skipping patch" warnings on 6.0

- [ ] **Step 1: Delete the 2 reviewer patch files**

```bash
cd /home/claw/codesop
git rm patches/superpowers/subagent-driven-development-spec-reviewer-prompt.md
git rm patches/superpowers/subagent-driven-development-code-quality-reviewer-prompt.md
```

- [ ] **Step 2: Remove the sdd_spec mapping block in `setup` `patch_skills()`**

Locate the block starting `local sdd_spec="$plugin_dir/skills/subagent-driven-development/spec-reviewer-prompt.md"` (through its closing `fi`, including the `elif [ ! -f "$sdd_spec" ]` warning branch). Delete the entire block (assignment + if/then/elif/fi). The next surviving line after deletion should be the `if [ "$patched" -gt 0 ]` summary.

- [ ] **Step 3: Remove the sdd_cq mapping block in `setup` `patch_skills()`**

Locate the block starting `local sdd_cq="$plugin_dir/skills/subagent-driven-development/code-quality-reviewer-prompt.md"` (through its closing `fi`, including the `elif [ ! -f "$sdd_cq" ]` warning branch). Delete the entire block.

- [ ] **Step 4: Fix the stale finishing comment in `setup`**

Locate the comment `# finishing-a-development-branch: v5.1.0 options menu + PR existence check` immediately above `local fb=`. Replace with:

```bash
  # finishing-a-development-branch: skip menu, direct push + PR, forge-neutral, keep worktree
```

- [ ] **Step 5: Verify setup is syntactically valid and references 0 reviewer files**

Run: `bash -n setup`
Expected: no output (syntax OK).

Run: `grep -c 'spec-reviewer\|code-quality-reviewer' setup`
Expected: `0`

- [ ] **Step 6: Commit**

```bash
git add setup
git commit -m "refactor: drop absorbed reviewer patches + clean setup mapping (6.0 re-base)"
```

---

### Task 2: Re-base brainstorming patch onto 6.0.2

**Files:**
- Modify: `patches/superpowers/brainstorming-SKILL.md` (rewrite against 6.0.2 base)

**Interfaces:**
- Consumes: 6.0.2 upstream at `~/.claude/plugins/cache/claude-plugins-official/superpowers/6.0.2/skills/brainstorming/SKILL.md`; current codesop additions in `patches/superpowers/brainstorming-SKILL.md` (pre-rebase)
- Produces: re-based patch whose diff vs 6.0.2 shows ONLY: Grill Mode block, ADR trigger, Domain Language Delta, CONTEXT.md check (plus header)

- [ ] **Step 1: Copy 6.0.2 upstream as the new base**

```bash
cp ~/.claude/plugins/cache/claude-plugins-official/superpowers/6.0.2/skills/brainstorming/SKILL.md \
   patches/superpowers/brainstorming-SKILL.md
```

This gives the 6.0.2 base (just-in-time visual companion, simplified digraph without "Visual questions ahead?", em-dash typography).

- [ ] **Step 2: Splice in the CONTEXT.md/ADR check bullet**

In the "Understanding the idea" bullet list (after the "Check out the current project state first" bullet), insert (verbatim from current pre-rebase patch):

```markdown
- Also check for: `CONTEXT.md` at the project root (domain vocabulary), and `docs/adr/` directory (architecture decision records). Read them if they exist. If they don't exist, proceed silently — don't suggest creating them.
```

- [ ] **Step 3: Splice in the Grill Mode block**

After the "Understanding the idea" block, before "**Exploring approaches:**", insert (verbatim from current pre-rebase patch):

```markdown
**Grill Mode** — structural enhancements to Step 3:

1. **Code-first answers**: When a question can be answered by reading code, read the code first instead of asking the user to guess. When the user describes existing behavior, verify against the codebase before accepting the claim.

2. **Decision tree tracking**: Maintain an implicit decision tree: resolved / pending / depends-on-other-decision. Each question maps to a node. **Exit condition**: stop grilling when purpose, constraints, success criteria, and major decision dependencies are clear enough to support 2-3 concrete approaches. Then proceed to Step 4.

3. **Domain vocabulary alignment**: If CONTEXT.md exists in the project, use its terms when framing questions. When new terminology reaches consensus, record it in the spec's `## Domain Language Delta` section (create this section if it doesn't exist). When the user's language conflicts with CONTEXT.md, call it out: "Your glossary defines X as A, but you seem to mean B — which is it?"
```

- [ ] **Step 4: Splice in the ADR trigger + Domain Language Delta→CONTEXT.md paragraphs**

After the "**Documentation:**" block (the "Write the validated design to..." paragraph + commit line), before "**Spec Self-Review:**", insert (verbatim from current pre-rebase patch):

```markdown
**ADR trigger:** When the design involved architectural decisions, significant trade-offs, or choosing between multiple approaches, check if `docs/adr/` exists in the project. If it does, suggest writing an ADR alongside the spec. Use format `NNNN-decision-title.md` with sections: 决策 / 上下文 / 结果. Commit the ADR with the spec. Simple changes with no meaningful decisions do not trigger this.

After spec approval, if the spec contains a `## Domain Language Delta` section, ask the user whether to write these terms into the project's CONTEXT.md (creating the file if needed). If the user agrees, update CONTEXT.md with the delta terms following the format: term definition + Avoid list.
```

- [ ] **Step 5: Prepend the codesop header**

Insert the codesop header comment as the **first line** of the file, before the `---name: brainstorming---` YAML frontmatter:

```markdown
<!--
  codesop patch: brainstorming
  Based on: superpowers v6.0.2
  Changes vs upstream:
    1. Added Grill Mode (code-first answers, decision tree tracking, domain vocabulary alignment)
    2. Added ADR trigger — suggests writing ADR when design involves architectural decisions
    3. Added Domain Language Delta — records new terminology, offers to write into CONTEXT.md
    4. Added CONTEXT.md / docs/adr/ check during context exploration
  Why: upstream brainstorming assumes single-pass Q&A; grill mode ensures deeper requirement
    exploration before design. ADR trigger and domain-language delta prevent underspecified
    specs from reaching implementation — the #1 cause of rework in codesop pipelines.
  Revert: delete this file and run `bash setup --host claude` to restore upstream version.
-->
```

- [ ] **Step 6: Verify — diff vs 6.0.2 shows ONLY intended additions**

Run: `diff patches/superpowers/brainstorming-SKILL.md ~/.claude/plugins/cache/claude-plugins-official/superpowers/6.0.2/skills/brainstorming/SKILL.md`
Expected: only the header comment block + the 4 spliced additions appear as differences. **No** removal of the just-in-time visual companion, simplified digraph, or em-dash typography. If any 6.0.2 content shows as removed, fix the splice.

Run: `grep -c 'Offer visual companion\|Visual questions ahead' patches/superpowers/brainstorming-SKILL.md`
Expected: `0` (old upfront-consent wording must be gone).

- [ ] **Step 7: Commit**

```bash
git add patches/superpowers/brainstorming-SKILL.md
git commit -m "feat: re-base brainstorming patch onto superpowers v6.0.2"
```

---

### Task 3: Re-base finishing patch onto 6.0.2 (forge-neutral + keep worktree after PR)

**Files:**
- Modify: `patches/superpowers/finishing-a-development-branch-SKILL.md` (rewrite against 6.0.2 base)

**Interfaces:**
- Consumes: 6.0.2 upstream at `~/.claude/plugins/cache/claude-plugins-official/superpowers/6.0.2/skills/finishing-a-development-branch/SKILL.md`; current codesop finishing patch (pre-rebase)
- Produces: re-based patch = 6.0.2 finishing structure, with menu auto-resolved to push+PR (no presentation), forge-neutral PR ops, PR-exists check, fetch-prune, worktree kept after PR (6.0 default)

- [ ] **Step 1: Copy 6.0.2 upstream as the new base**

```bash
cp ~/.claude/plugins/cache/claude-plugins-official/superpowers/6.0.2/skills/finishing-a-development-branch/SKILL.md \
   patches/superpowers/finishing-a-development-branch-SKILL.md
```

- [ ] **Step 2: Collapse the menu — go straight to push + PR (Option 2 behavior)**

Remove "Step 2: Detect Environment" menu-routing and "Step 4: Present Options" entirely. The flow becomes: Step 1 verify tests → Step 2 determine base branch → Step 3 push + create PR → Step 4 post-PR fetch-prune. Keep the environment-detection variables (`GIT_DIR`/`GIT_COMMON`) ONLY where the provenance cleanup guidance (Step 5) needs them.

Rewrite "The Process" so it reads (replace the menu-bearing Steps 2/4/5 with):

```markdown
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

Then create the PR with your forge tooling (e.g. `gh pr create --title "<title>" --body "..."`). Skip creation if a PR already exists for this branch.

**Do NOT clean up the worktree** — it stays alive for PR review iteration. Worktree lifecycle is managed elsewhere: EnterWorktree-managed worktrees exit via the platform's exit tool; merged/orphan branches are detected by the codesop git-health check.

### Step 4: Post-PR Remote Ref Cleanup

```bash
# Prune stale remote tracking refs (origin/feat/xxx after GitHub deletes the branch)
git fetch --prune 2>/dev/null || true
```
```

- [ ] **Step 3: Add provenance cleanup GUIDANCE (for future merge/discard; PR path does not trigger)**

Add a "## Worktree Cleanup Guidance (non-PR paths)" section near the end, distilled from 6.0.2 Step 6:

```markdown
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
```

- [ ] **Step 4: Replace the file header**

Prepend the codesop header before the `---name:` frontmatter:

```markdown
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
```

- [ ] **Step 5: Verify — diff vs 6.0.2 shows intended changes only**

Run: `diff patches/superpowers/finishing-a-development-branch-SKILL.md ~/.claude/plugins/cache/claude-plugins-official/superpowers/6.0.2/skills/finishing-a-development-branch/SKILL.md`
Expected: menu removal, forge-neutral PR step, PR-exists check, fetch-prune, provenance-guidance section, header. The worktree-keep is upstream default so no regression there.

Run: `grep -c 'gh pr create\|gh pr list' patches/superpowers/finishing-a-development-branch-SKILL.md`
Expected: `0` (no hardcoded gh). The example may mention `gh`/`glab` as forge examples, but not as the mandatory command.

- [ ] **Step 6: Commit**

```bash
git add patches/superpowers/finishing-a-development-branch-SKILL.md
git commit -m "feat: re-base finishing patch onto v6.0.2 (forge-neutral, keep worktree after PR)"
```

---

### Task 4: Re-base writing-plans patch onto 6.0.2 (heaviest)

**Files:**
- Modify: `patches/superpowers/writing-plans-SKILL.md` (rewrite against 6.0.2 base; 9 codesop sections spliced + 3 upstream sections retained)

**Interfaces:**
- Consumes: 6.0.2 upstream at `~/.claude/plugins/cache/claude-plugins-official/superpowers/6.0.2/skills/writing-plans/SKILL.md`; current codesop writing-plans patch (pre-rebase, holds the 9 section bodies to copy)
- Produces: re-based patch retaining 6.0.2's Global Constraints + per-task Interfaces + Task Right-Sizing, plus codesop's Requirement Extraction / Acceptance Criteria / Gap Scan / Complexity Assessment / Phase Split / Lightweight Plan / Staged Output / Stage-3 Self-Review / Pipeline Continuation, with Execution Handoff menu removed

- [ ] **Step 1: Copy 6.0.2 upstream as the new base**

```bash
cp ~/.claude/plugins/cache/claude-plugins-official/superpowers/6.0.2/skills/writing-plans/SKILL.md \
   patches/superpowers/writing-plans-SKILL.md
```

Base now has: `## Task Right-Sizing`, `## Global Constraints` (in header), per-task `**Interfaces:**` block in Task Structure, `## Execution Handoff` (to be removed).

- [ ] **Step 2: Modify the Plan Document Header — adopt 6.0.2 Global Constraints, add codesop REQUIRED SUB-SKILL nuance**

Keep 6.0.2's header including the `## Global Constraints` block. The 6.0.2 header already references subagent-driven-development — leave it.

- [ ] **Step 3: Modify Task Structure — keep 6.0.2 Interfaces block, switch complex tasks to implementation-brief**

Keep 6.0.2's Task Structure including the `**Interfaces:**` (Consumes/Produces) block. Add codesop's brief note. After the Task Structure code fence, insert:

```markdown
This is the reference step format. Complex tasks use **implementation briefs** instead of full code blocks (see Staged Output). Lightweight tasks use the Lightweight Plan schema. Each task ends with an independently testable deliverable; prefer interface signatures + design constraints + edge cases + test obligations over pasting full code for complex work.
```

- [ ] **Step 4: Modify "Remember" — switch from complete-code to brief guidance**

Replace 6.0.2's `## Remember` bullet `Complete code in every step — if a step changes code, show the code` with codesop's:

```markdown
- Exact file paths always
- Complex tasks: implementation briefs (interface signatures, constraints, edge cases, test obligations) — NOT full code blocks
- Lightweight tasks: brief guidance, implementer decides details
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits
```

- [ ] **Step 5: Splice in the 9 codesop sections after `## Remember`**

Copy verbatim from the current pre-rebase `patches/superpowers/writing-plans-SKILL.md`, in this order, after `## Remember`:

1. `## Requirement Extraction` (R1..RN enumeration + `## Requirement Traceability` placement)
2. `## Acceptance Criteria` (G1..GN Given/When/Then + adversarial self-check + Coverage Matrix + Gap Scan — note: Gap Scan is a separate `## Gap Scan` section, copy both)
3. `## Complexity Assessment` (simple/moderate/complex tiers + override rules + rollback triggers)
4. `## Phase Split` (routes simple/moderate → Lightweight Plan, complex → Staged Output)
5. `## Lightweight Plan` (schema for simple/moderate)
6. `## Staged Output for Complex Tasks` (Stage 1 skeleton → Stage 2 expansion with per-task save → Stage 3 + Resume Protocol)
7. `## Self-Review (Stage 3 for Complex Tasks)` (subagent spec-coverage dispatch + placeholder scan + type consistency)

Keep 6.0.2's `## Task Right-Sizing`, `## Global Constraints`, per-task `**Interfaces:**` — do NOT delete them.

- [ ] **Step 6: Replace `## Execution Handoff` with `## Pipeline Continuation`**

Remove 6.0.2's `## Execution Handoff` (the 2-option menu) entirely. Copy codesop's `## Pipeline Continuation` section verbatim from the pre-rebase patch:

```markdown
## Pipeline Continuation

**Do not stop.** After the appropriate completion point:
1. TaskUpdate(current task, completed)
2. TaskList → find next pending task (source: codesop-pipeline) → execute immediately

Completion points by tier:
- simple/moderate: after Lightweight Plan is written
- complex: after all three stages complete (skeleton → expansion → self-review)

The task list was already approved. Proceed without asking.
```

- [ ] **Step 7: Replace the file header**

Prepend before `---name:`:

```markdown
<!--
  codesop patch: writing-plans
  Based on: superpowers v6.0.2
  Changes vs upstream:
    1. Removed Execution Handoff menu (Pipeline Continuation replaces — autonomous re-entry)
    2. Added Requirement Extraction (R1..RN) before review
    3. Added Acceptance Criteria phase (G1..GN Given/When/Then, adversarial self-check, Coverage Matrix, Gap Scan)
    4. Added Complexity Assessment (simple/moderate/complex → plan-depth routing)
    5. Added Phase Split + Lightweight Plan (simple/moderate avoid over-planning)
    6. Added Staged checkpoint flow + Resume Protocol (skeleton → per-task save → self-review)
    7. Replaced self-checklist Self-Review with subagent spec-coverage review (complex path)
    8. Switched complex tasks from complete-code to implementation-brief
  Retained from upstream v6.0.2: Global Constraints block, per-task Interfaces block, Task Right-Sizing.
  Why: spec→plan deviations (omission, deformation, granularity) stem from missing the
    "define what done looks like" step. Acceptance criteria + traceability close it; staged
    checkpoints prevent truncation on long plans. Phase split keeps rigor for complex, light for simple.
  Revert: delete this file and run `bash setup --host claude` to restore upstream version.
-->
```

- [ ] **Step 8: Verify — diff vs 6.0.2 shows codesop additions + menu removal, upstream sections retained**

Run: `diff patches/superpowers/writing-plans-SKILL.md ~/.claude/plugins/cache/claude-plugins-official/superpowers/6.0.2/skills/writing-plans/SKILL.md`
Expected: 9 codesop sections added, `## Execution Handoff` removed, Remember/Task-Structure modified. **Must retain** `## Global Constraints`, `## Task Right-Sizing`, and the `**Interfaces:**` block (they should NOT appear as removed in the diff).

Run: `grep -c '## Global Constraints\|## Task Right-Sizing\|Consumes:\|Produces:' patches/superpowers/writing-plans-SKILL.md`
Expected: `>= 4` (all upstream additions present).

Run: `grep -c '## Execution Handoff' patches/superpowers/writing-plans-SKILL.md`
Expected: `0` (menu removed).

- [ ] **Step 9: Commit**

```bash
git add patches/superpowers/writing-plans-SKILL.md
git commit -m "feat: re-base writing-plans patch onto v6.0.2 (keep Constraints/Interfaces/Right-Sizing)"
```

---

### Task 5: Bump min_version to 6.0.2, fix version-asserting test, apply + verify

**Files:**
- Modify: `config/dependencies.sh` (superpowers min_version 5.1.0 → 6.0.2)
- Modify: `tests/dep-upgrade.sh:14` (assertion 5.1.0 → 6.0.2)

**Interfaces:**
- Consumes: Tasks 1-4 done (3 re-based patches + reviewer deletion + setup cleanup)
- Produces: `bash setup --host claude` applies all 3 patches over 6.0.2; full test suite passes

- [ ] **Step 1 (red): bump min_version first, confirm dep-upgrade.sh fails**

In `config/dependencies.sh`, change the superpowers line:

```bash
  "plugin|superpowers@claude-plugins-official|core|yes|6.0.2"
```

Run: `bash tests/dep-upgrade.sh`
Expected: **FAIL** — `assert_contains` for `core|yes|5.1.0` no longer matches (manifest now has 6.0.2). This confirms the test gates the version.

- [ ] **Step 2 (green): fix the test assertion**

In `tests/dep-upgrade.sh` line 14, change:

```bash
assert_contains "$manifest_output" "core|yes|6.0.2"
```

Run: `bash tests/dep-upgrade.sh`
Expected: PASS.

- [ ] **Step 3: Apply patches via setup**

Run: `bash setup --host claude`
Expected: output includes `✓ Skill patches applied (3 files)`. **No** `⚠ ... skipping patches` (compat now passes: installed 6.0.2 vs min 6.0.2). **No** stale `spec-reviewer-prompt.md not found` warnings.

- [ ] **Step 4: Verify each installed skill equals its patch (apply confirmed)**

Run:
```bash
SP=~/.claude/plugins/cache/claude-plugins-official/superpowers/6.0.2/skills
for s in brainstorming writing-plans finishing-a-development-branch; do
  diff -q "patches/superpowers/${s}-SKILL.md" "$SP/$s/SKILL.md" && echo "$s OK" || echo "$s MISMATCH"
done
```
Expected: three `OK` lines (installed skill files == patch files).

- [ ] **Step 5: Run full test suite**

Run: `bash tests/run_all.sh`
Expected: all suites pass (router, init-interview, detect-environment, e2e, init, uninstall, setup, symlink, update, skill-routing-coverage, dep-upgrade).

- [ ] **Step 6: Commit**

```bash
git add config/dependencies.sh tests/dep-upgrade.sh
git commit -m "feat: pin superpowers min_version 6.0.2 + sync version test (patches re-apply)"
```

---

### Task 6: Hardening — re-base checklist doc + verify drift warning

**Files:**
- Create: `docs/superpowers/playbooks/rebase-superpowers-patches.md`

**Interfaces:**
- Consumes: the re-base procedure just performed (Tasks 1-5)
- Produces: a checklist future maintainers follow on the next superpowers major; documented "re-run setup after upgrade" note

- [ ] **Step 1: Create the checklist doc**

Write `docs/superpowers/playbooks/rebase-superpowers-patches.md` with:

```markdown
# Re-base superpowers Patches Checklist

Run this when superpowers ships a major or minor release that changes skill files codesop patches.

## 1. Detect drift
- List installed superpowers versions: `ls ~/.claude/plugins/cache/claude-plugins-official/superpowers/` (orphans show a `.orphaned_at` marker).
- Compare installed major.minor vs `config/dependencies.sh` superpowers `min_version`. If different, `patch_skills()` prints `⚠ superpowers X.Y (patches target A.B.x) — skipping patches` at setup time.

## 2. Per-patch re-base (for each patched skill)
1. Read the new upstream: `~/.claude/plugins/cache/claude-plugins-official/superpowers/<NEW>/skills/<skill>/SKILL.md`
2. Diff current codesop patch vs the upstream baseline it was forked from (the `Based on:` version) to see exactly what codesop changed.
3. Diff the NEW upstream vs the baseline to see what upstream changed.
4. Take the NEW upstream as base; splice codesop's changes back in; adopt upstream's structural changes (don't clobber).
5. Update the patch header `Based on: superpowers v<NEW>` + accurate `Changes vs upstream` list.

## 3. Don't-clobber-upstream-improvements check
Confirm each upstream improvement is inherited (not regressed) by diffing the new patch vs the NEW upstream:
- [ ] Visual companion: per-session key auth + just-in-time offering (brainstorming)
- [ ] Global Constraints block (writing-plans header)
- [ ] per-task Interfaces block (writing-plans Task Structure)
- [ ] Task Right-Sizing section (writing-plans)
- [ ] worktree provenance cleanup guidance (finishing)
- [ ] task-reviewer single-prompt (subagent-driven-development — codesop does NOT patch this)

## 4. Sync setup + manifest + tests
- [ ] If a patch file was added/removed, sync `patch_skills()` mapping blocks in `setup` (else stale "not found, skipping patch" warnings)
- [ ] Bump `config/dependencies.sh` superpowers `min_version` to the new version
- [ ] Update `tests/dep-upgrade.sh` version assertion to match
- [ ] Fix any stale setup comments

## 5. Apply + verify
- [ ] `bash setup --host claude` — expect `✓ Skill patches applied (N files)`, no skip warning
- [ ] `diff` each installed skill vs its patch — must be identical
- [ ] `bash tests/run_all.sh` — all pass

## 6. Remind users
After any superpowers upgrade (via Claude Code plugin manager, not via codesop), users MUST re-run `bash setup --host claude` so patches re-evaluate against the new version. The drift warning only fires at setup time.
```

- [ ] **Step 2: Verify the existing drift warning still fires correctly**

Run: `bash tests/dep-upgrade.sh`
Expected: PASS (asserts `patch_mm` and `skipping patches` strings exist in setup — the warning mechanism is intact).

- [ ] **Step 3: Commit**

```bash
git add docs/superpowers/playbooks/rebase-superpowers-patches.md
git commit -m "docs: re-base checklist for superpowers patches (anti-regression + drift)"
```

---

### Task 7: Release artifacts + final verification

**Files:**
- Modify: `VERSION`, `skill.json`, `CHANGELOG.md`

**Interfaces:**
- Consumes: Tasks 1-6 complete
- Produces: version bump reflecting the feat; CHANGELOG entry

- [ ] **Step 1: Bump VERSION**

Determine next version: current `3.14.2` → this is a feat (re-base + behavior change in finishing) → minor bump → `3.15.0`.

```bash
echo "3.15.0" > VERSION
```

- [ ] **Step 2: Sync skill.json version**

In `skill.json`, set `"version": "3.15.0"`.

- [ ] **Step 3: Add CHANGELOG entry**

In `CHANGELOG.md`, under `[Unreleased]` add a `## [3.15.0] - 2026-06-18` section:

```markdown
## [3.15.0] - 2026-06-18
### Changed
- Re-based superpowers patches onto v6.0.2 (brainstorming, writing-plans, finishing); preserves whole-file-overwrite delivery.
- finishing: PR operations now forge-neutral (no hardcoded `gh`); worktree kept after PR for review iteration (adopts upstream Option 2 behavior).
- writing-plans: retains upstream Global Constraints / per-task Interfaces / Task Right-Sizing alongside codesop acceptance-criteria + staged-checkpoint flow.

### Removed
- subagent-driven-development reviewer patches (`spec-reviewer-prompt.md`, `code-quality-reviewer-prompt.md`) — absorbed by superpowers 6.0's merged `task-reviewer-prompt.md`.

### Added
- Re-base checklist doc (docs/superpowers/playbooks/rebase-superpowers-patches.md) — anti-regression + drift handling.

### Fixed
- superpowers `min_version` 5.1.0 → 6.0.2; patches re-apply on 6.0 installs (were silently skipped).
```

- [ ] **Step 4: Final full verification**

Run: `bash tests/run_all.sh`
Expected: all pass.

Run: `bash setup --host claude` once more
Expected: `✓ Skill patches applied (3 files)`, no warnings.

- [ ] **Step 5: Commit**

```bash
git add VERSION skill.json CHANGELOG.md
git commit -m "chore: bump v3.15.0 (superpowers 6.0 re-base)"
```

- [ ] **Step 6: Manual finishing smoke test**

In a throwaway branch/worktree, run the finishing flow end-to-end once: verify it skips the menu, pushes, creates/notes a PR via the model's forge tooling, runs `git fetch --prune`, and does NOT remove the worktree. (This validates the forge-neutral wording + keep-worktree behavior in practice.)
