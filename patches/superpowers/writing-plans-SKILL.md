<!--
  codesop patch: writing-plans
  Based on: superpowers v6.0.3
  Changes vs upstream:
    1. Removed Execution Handoff menu (Pipeline Continuation replaces — autonomous re-entry)
    2. Added Requirement Extraction (R1..RN) before review
    3. Added Acceptance Criteria phase (G1..GN Given/When/Then, adversarial self-check, Coverage Matrix, Gap Scan)
    4. Added Complexity Assessment (simple/moderate/complex → plan-depth routing)
    5. Added Phase Split + Lightweight Plan (moderate avoids over-planning; simple skips plan entirely — see #9)
    6. Added Staged checkpoint flow + Resume Protocol (skeleton → per-task save → self-review)
    7. Replaced self-checklist Self-Review with subagent spec-coverage review (complex path)
    8. Switched complex tasks from complete-code to implementation-brief
    9. v9 R3 + v8 plan-stage spec-coverage:
       - **simple 跳 plan** (R3 / spec §2.2-2.3): simple skips ALL plan orchestration and proceeds
         directly to /goal (no Lightweight Plan, no spec-coverage — simple spec is short,
         spec-coverage is meaningless per spec §4.6 simple 完成条件). moderate/complex keep plan
         orchestration (dependency topology).
       - **spec-coverage 扩 moderate** (v8): spec-coverage runs for moderate AND complex. Moderate
         uses a lightweight variant (Requirement Traceability + Acceptance IDs only — does NOT force
         implementation-brief expansion); complex runs the full variant (also verifies briefs achieve
         each Gn's Verify). simple has NO spec-coverage.
       - **judgment vocabulary unified** from ✅/⚠️/❌ to 满足/没满足/顾虑 (referencing
         _evidence-pack-schema.md, NOT duplicated here) — verdict-semantic emojis fully replaced.
       - spec-coverage reviewer prompt stays INLINE in this main SKILL.md (patch_skills only syncs
         this file). plan-gate (human, advisory) is OUT of this patch's scope — lives in SKILL.md
         (T6), so Pipeline Continuation here has NO plan-gate blocking.
  Retained from upstream v6.0.3: Global Constraints block, per-task Interfaces block, Task Right-Sizing.
  Why: spec→plan deviations (omission, deformation, granularity) stem from missing the
    "define what done looks like" step. Acceptance criteria + traceability close it; staged
    checkpoints prevent truncation on long plans. Phase split keeps rigor for complex, light for simple.
  Revert: delete this file and run `bash setup --host claude` to restore upstream version.
-->
---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** If working in an isolated worktree, it should have been created via the `superpowers:using-git-worktrees` skill at execution time.

**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
- (User preferences for plan location override this default)

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Task Right-Sizing

A task is the smallest unit that carries its own test cycle and is worth a
fresh reviewer's gate. When drawing task boundaries: fold setup,
configuration, scaffolding, and documentation steps into the task whose
deliverable needs them; split only where a reviewer could meaningfully
reject one task while approving its neighbor. Each task ends with an
independently testable deliverable.

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

## Global Constraints

[The spec's project-wide requirements — version floors, dependency limits,
naming and copy rules, platform requirements — one line each, with exact
values copied verbatim from the spec. Every task's requirements implicitly
include this section.]

---
```

## Task Structure

This is the reference step format. Complex tasks use **implementation briefs** instead of full code blocks (see Staged Output). Lightweight tasks use the Lightweight Plan schema. Each task ends with an independently testable deliverable; prefer interface signatures + design constraints + edge cases + test obligations over pasting full code for complex work.

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Interfaces:**
- Consumes: [what this task uses from earlier tasks — exact signatures]
- Produces: [what later tasks rely on — exact function names, parameter
  and return types. A task's implementer sees only their own task; this
  block is how they learn the names and types neighboring tasks use.]

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## No Placeholders

Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — the engineer may be reading tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps)
- References to types, functions, or methods not defined in any task

**Implementation briefs** (used in complex task staged output) are not placeholders. They specify:
interface signatures, design constraints, edge cases to handle, and test obligations.
"Edge cases: handle empty input, null return from X" is specific guidance.
"Handle edge cases" without specifics is a placeholder.

## Remember
- Exact file paths always
- Complex tasks: implementation briefs (interface signatures, constraints, edge cases, test obligations) — NOT full code blocks
- Lightweight tasks: brief guidance, implementer decides details
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits

## Requirement Extraction

Before self-review, extract all discrete requirements from the spec:

1. Read the spec document
2. Enumerate every discrete requirement as a numbered list (R1, R2, R3...)
   - A "discrete requirement" is any independently verifiable behavior, rule, constraint, output format, or edge case
   - One spec section may contain multiple discrete requirements
   - Exclude "What NOT to change" / negative constraints — these are boundaries, not tasks
3. Write the enumeration into a `## Requirement Traceability` section at the end of the plan document, as its final section

## Acceptance Criteria

After extracting requirements (R1..RN), write acceptance criteria before writing any tasks.

**Two formats based on change type.** When in doubt, use the full format. The simplified format is only for changes
where Given/When/Then adds no information (e.g., replacing a string, changing a config value, updating a version number).

**Behavior changes** (new features, interface changes, user-observable behavior) — full format:

    G{n}: [one sentence describing verifiable behavior]
        Given: [precondition / input state]
        When: [trigger action]
        Then: [expected result]
        Verify: [specific verification command or check method]
        Boundary: [at least one boundary or error path]
        Covers: R{n}, R{n}...

**Mechanical edits** (bug fixes, config tweaks, text replacements, static content) — simplified format:

    G{n}: [what changes]
        Verify: [verification command]
        Failure prevented: [what error this prevents]
        Covers: R{n}

**Adversarial self-check** (apply to every Gn, no subagent needed):
For each criterion, answer TWO questions honestly:

Question 1 — implementation laziness:
> "If I implemented this in the laziest way possible (hardcoded returns, happy-path-only,
> skipping boundary checks), would this criterion still catch me?"

Question 2 — verify command reliability:
> "Can this verify command give a wrong answer? Can it pass when it shouldn't (false positive)
> or fail when it shouldn't (false negative)?"
Common traps: grep hits comments/docs instead of code; `head -N` cuts too short; pattern matches
unrelated content in the same file; command checks file exists but not content correctness.

If answer to either question is "yes" → rewrite the criterion or its verify command.

**Quality dimensions** — every Gn must satisfy all five:
- Specific: describes an observable behavior or verifiable state
- Verifiable: includes a concrete command or check method
- Non-vacuous: cannot be trivially satisfied (e.g. "code compiles" is vacuous)
- Complete: covers normal path + at least one boundary or error path (behavior changes only)
- Unambiguous: admits only one reasonable interpretation

**Coverage check** (required for all tasks):
After writing all Gn, verify: each Rn from the Requirement Extraction appears in at least one Gn's Covers field.
If any Rn is uncovered → write additional Gn.

Write all criteria into a `## Acceptance Criteria` section in the plan document, BEFORE `## Requirement Traceability`.

## Gap Scan

After the coverage check, scan for categories the Gn list may miss. Check each that applies (skip irrelevant ones):

- [ ] **Edge cases**: error paths, invalid input, empty values, extremes, concurrency
- [ ] **Regression risk**: does this change break existing functionality?
- [ ] **Integration**: env vars, config files, public API changes, data format changes

Found gaps → add new Gn to cover them.

## Complexity Assessment

After acceptance criteria and gap scan, assess task complexity.

**Primary classification (observable metrics):**
- simple: 1-2 files, no cross-module dependency
- moderate: 3-5 files, or involves 2 modules
- complex: >5 files, or involves 3+ modules

**Override rules** (any hit → upgrade to complex regardless of file count):
- Public API change
- Data migration or format change
- Security-related logic (auth, encryption)
- Build/deploy pipeline change

Output:

    ## Complexity Assessment
    **Level:** simple | moderate | complex
    **File estimate:** N (basis: [what in the spec tells you this])
    **Modules:** [list]
    **Override:** [if any, list triggered items; otherwise "none"]

**Rollback triggers** (checked during Phase B if applicable):
- Actual file count exceeds estimate and crosses tier threshold
- Cross-layer, cross-package, or cross-skill changes discovered
- New public interfaces or pipeline behavior changes discovered
- AC cannot map directly to discovered file structure

On rollback: AC is frozen by default. Phase B only adds decomposition.
Exception: Phase B discovers AC was based on wrong assumptions → AC may be revised,
recorded as "AC revision: [reason]".

## Phase Split

Based on complexity assessment (spec §2.2-2.3 — three-way routing by dependency topology):

**simple:**
**Skip ALL plan orchestration.** No Lightweight Plan, no spec-coverage review, no File Structure
mapping. Proceed directly to Pipeline Continuation → /goal. The spec is short enough that
spec-coverage is meaningless (spec §4.6 simple 完成条件 = test + lint only). The implementer
self-decomposes inside /goal from the spec directly.

**moderate:**
Generate a Lightweight Plan (next section), then run the **lightweight spec-coverage review**
(see Self-Review section — moderate variant: does NOT require implementation-brief expansion,
verifies Requirement Traceability + Acceptance IDs only). Then Pipeline Continuation.
If implementation discovers actual scope significantly exceeds the estimate (e.g., file count
crosses the complex threshold), the implementer should flag this and escalate to full planning.

**complex:**
Continue to Staged Output for Complex Tasks (Stage 1 → Stage 2 → Stage 3).
Then full Self-Review (spec-coverage full variant). Then Pipeline Continuation.

## Lightweight Plan

For moderate tasks only (simple skips plan entirely — see Phase Split). Uses the same schema as
full plans, but with reduced depth.

Each task follows **implementation cohesion**, not one-task-per-Gn. A task may reference multiple Gn via `Acceptance IDs`.

Schema (shared with full plans — execution skill sees the same structure):

    ### Task N: [description]

    **Scope:** [what this task does]
    **Acceptance IDs:** G1, G3
    **Likely files:** `path/to/file.sh`
    **Implementation guidance:** brief
    **Key direction:** [one sentence on approach — implementer decides details]
    **Validation:** [Gn Verify commands for this task's acceptance IDs]
    **Out of scope:** [what this task does NOT do]

Difference from full plan:

| Field | Lightweight (moderate) | Full (complex) |
|-------|------------------------------|----------------|
| Implementation guidance | `brief` — key direction, implementer decides | `implementation brief` — constraints, interfaces, edge cases |
| Steps | None — implementer self-decomposes | Implementation briefs (no checkbox steps) |
| Acceptance IDs | Required | Required |
| File paths | `Likely` — estimate | Exact with line numbers |

Write the lightweight plan into the plan document. Include Plan Document Header as usual.

## Staged Output for Complex Tasks

Complex plans use three stages with explicit checkpoints. Each stage saves the plan file
before proceeding, enabling resume if the session is interrupted.

### Stage 1: Plan Skeleton

Write the initial plan file with structure but NO implementation details.

**Include:**
1. Plan Document Header (goal, architecture, tech stack)
2. File Structure (files to create/modify, one-line responsibility each)
3. Acceptance Criteria (G1..GN — copy from Phase A output)
4. Complexity Assessment (copy from Phase A output)
5. Task Outline — for each task T1..TN, ONLY:
   - Title and one-line goal
   - Acceptance IDs (Gn references)
   - Dependencies (other T-IDs, or "none")
   - Linked requirements (Rn references)
   - Files involved
6. Requirement Traceability table

**Do NOT include:** implementation code, interface sketches, test code, edge case details, step-level decomposition.

**Checkpoint 1:** Write the file.
Announce: "Stage 1/3 complete: plan skeleton saved to [path]."

**Moderate tier follows up with the lightweight spec-coverage review** (see Self-Review section):
the reviewer verifies the plan's Requirement Traceability + Acceptance IDs against the spec, but
does NOT require implementation-brief expansion — the lightweight plan's `Implementation guidance: brief`
is sufficient evidence for moderate. This catches moderate-tier drift (the most common tier)
without forcing full Stage 2 expansion overhead.

### Stage 2: Task Expansion

Re-read the skeleton from file. Expand each task ONE AT A TIME with implementation briefs.
Save after each task expansion — this prevents loss if the session times out.

**Implementation brief format** (replaces complete code blocks):

    ### Task N: [Title]

    **Goal:** [what this task achieves]
    **Acceptance IDs:** G1, G3
    **Dependencies:** [T-IDs that must complete first, or "none"]
    **Files:**
    - Create: `exact/path/to/file.py`
    - Modify: `exact/path/to/existing.py:123-145`
    - Test: `tests/exact/path/to/test.py`

    **Implementation brief:**
    - **Design constraint:** [key constraint from spec or architecture]
    - **Interface:** function_name(param: Type) -> ReturnType
    - **Edge cases:** [specific cases to handle]
    - **Test obligations:** [behaviors to test — what, not how]
    - **Critical snippet:** [only the tricky/ambiguous part — skip for straightforward logic]

    **Validation:** [Gn Verify commands for this task's acceptance IDs]

**Rules:**
- Expand tasks sequentially (T1 first, then T2)
- Each task expansion is a separate Edit operation — save progress incrementally
- Interface sketches show signatures only, not implementations
- Critical snippets are for tricky parts only — skip for straightforward logic
- Test obligations describe WHAT to test, not the test code itself
- If expansion reveals new files/dependencies: update the skeleton's File Structure inline
- Stable IDs (R1/G1/T1): append only, never renumber. Update by ID reference

**Checkpoint 2:** After all tasks expanded. File saved.
Announce: "Stage 2/3 complete: all tasks expanded."

### Stage 3: Traceability + Self-Review

Re-read the expanded plan from file. Run Self-Review (next section) as a SEPARATE operation —
do not attempt review from memory alone.

### Resume Protocol

If the session is interrupted at any point:
1. Read the plan file from disk
2. Determine the last completed stage:
   - Task outline present with title + IDs → Stage 1 done
   - All tasks have Implementation brief sections → Stage 2 done
   - Self-Review output present → Stage 3 done
3. Resume from the first incomplete stage
4. Announce: "Resuming plan from Stage N: [description]"

## Self-Review (Stage 3 for Complex Tasks; lightweight pass for Moderate)

Re-read the expanded plan from file before starting this section.
Complex and moderate tasks reach this section (simple skips to Pipeline Continuation — no plan
to review). Moderate runs the **lightweight variant** (Requirement Traceability + Acceptance IDs
only — does NOT require implementation-brief expansion). Complex runs the **full variant** (also
verifies implementation briefs can achieve each Gn's Verify condition).

**1. Spec Coverage (evidence-pack subagent dispatch, INLINE reviewer prompt):**

Dispatch a `general-purpose` subagent to review spec coverage and produce the plan-stage evidence
pack. The reviewer prompt is **inlined below** (not loaded from a sibling file) because `setup`'s
`patch_skills()` only syncs this main SKILL.md. The evidence pack has three columns whose field
definitions live in the shared template `patches/superpowers/_evidence-pack-schema.md` (referenced,
not duplicated here):
- **(a) Per-requirement verdict** — `§ref` + verbatim spec excerpt + artifact location (`task-N` /
  `task-N.M` / `task-N 步骤K` for the plan stage) + verdict (`满足`/`没满足`/`顾虑`) + concern
  (advisory, for human).
- **(b) Uncovered scan** — scan the whole spec, list requirements with no corresponding plan task.
- **(c) Cross-model review column** — codex output if `codex:rescue` was invoked for this plan
  (optional for the plan stage; if not invoked, mark `codex 未调用（plan 阶段可选）`).

Use the dispatch prompt below. **Verdict vocabulary is unified to 满足/没满足/顾虑** (replaces the
prior ✅/⚠️/❌) so the plan-stage evidence pack uses the same judgment vocabulary as the spec stage:

```
Subagent (general-purpose):
  description: "Review plan spec coverage"
  prompt: |
    You are a plan coverage reviewer. Your job is to verify that every requirement
    from the spec is covered by the plan, and to produce the plan-stage evidence pack.

    **Plan to review:** [PLAN_FILE_PATH]
    **Spec for reference:** [SPEC_FILE_PATH]
    **Plan tier:** [moderate | complex]  (moderate = lightweight plan; complex = staged plan)

    ## What to Check

    Read the plan's `## Requirement Traceability` section to get the enumerated
    requirements (R1, R2, ...).

    For each requirement:
    1. Find it in the spec to confirm the enumeration is accurate
    2. Find which plan task/step covers it (use `+` for cross-task coverage)
    3. Assess coverage: 满足 (fully covered) / 没满足 (missing) / 顾虑 (partial or advisory concern)

    Additionally:
    - Scan the full spec independently for requirements NOT in the traceability list.
      For any spec requirement you find that has no corresponding R-number, add a row
      to the Traceability Matrix with Req marked "UNENUMERATED-§X.X" and verdict 没满足.
    - Scan the plan for placeholders (TBD, TODO, "implement later", vague descriptions)

    ## Calibration

    You are a thorough reviewer, not a rubber stamp. The plan author has cognitive
    bias toward their own work. Your job is to find what they missed.

    Flag as 没满足 any requirement with no corresponding plan task.
    Flag as 顾虑 any requirement where the plan task exists but doesn't fully address
    the spec's detail.

    Do NOT approve if any 没满足 exists.

    Example 没满足: Spec says "output must include error code and message" but plan
    only has a task for "output error message" — error code is missing.

    Example 顾虑: Spec says "validate email, phone, and address" but plan task only
    shows validation code for email and phone — address validation is implied but
    not shown.

    ## Tier-specific scope

    - **moderate** (lightweight plan): verify Requirement Traceability + Acceptance IDs only.
      Do NOT require implementation-brief expansion — the lightweight plan's brief guidance
      is sufficient evidence for moderate.
    - **complex** (staged plan): additionally verify each acceptance criterion — confirm the
      plan's implementation briefs can actually achieve each Gn's Verify condition. If a plan
      task exists but cannot pass Gn's Verify → mark 顾虑.

    ## Output Format

    Produce the evidence pack per `patches/superpowers/_evidence-pack-schema.md`:

    ### (a) Per-requirement verdict
    One row per spec requirement. Fields (fixed, in order): §ref | verbatim spec excerpt
    (copy directly, do not rewrite) | artifact location (task-N / task-N.M / task-N 步骤K) |
    verdict (满足 / 没满足 / 顾虑) | concern (only if verdict=顾虑; advisory, human decides
    whether it blocks).

    ### (b) Uncovered scan
    Table: §ref | uncovered requirement (verbatim excerpt) | nature (必做 / 边界 / 明确不做).
    Empty table = full coverage.

    ### (c) Cross-model review column
    - codex status: invoked / not invoked (plan stage optional)
    - codex conclusion: [verbatim if invoked, or "codex 未调用（plan 阶段可选）"]
    - cross-model uncovered supplement: merged into (b) for re-check, or "无补充"

    ## Status
    **Status:** Approved | Issues Found

    **Issues (if any):**
    - R? (§X.X): [what's missing]

    **Recommendations (advisory, do not block approval):**
    - [non-blocking suggestions]
```

- Agent description: "Review plan spec coverage"
- Inputs: replace [PLAN_FILE_PATH], [SPEC_FILE_PATH], and [moderate | complex] with actual values

If the subagent finds 没满足 issues: fix them inline by adding or modifying tasks, then
re-dispatch. Maximum 2 rounds. Fixing 顾虑 only does not require re-dispatch.

**2. Placeholder scan (self-check):**

Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.

**3. Type consistency (self-check, complex only — lightweight plans have no implementation briefs):**

Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks?

If you find issues, fix them inline. No need to re-review.

## Pipeline Continuation

**Do not stop.** After the appropriate completion point:
1. TaskUpdate(current task, completed)
2. TaskList → find next pending task (source: codesop-pipeline) → execute immediately

Completion points by tier (spec §2.2-2.3 three-way routing):
- **simple**: NO plan stage — proceed directly to /goal (spec is the goal file; implementer
  self-decomposes inside /goal). The plan-writing skill is not invoked for simple.
- **moderate**: after Lightweight Plan is written + lightweight spec-coverage review produces the
  evidence pack (Requirement Traceability + Acceptance IDs verified).
- **complex**: after all three stages complete (skeleton → expansion → self-review) + full
  spec-coverage review produces the evidence pack (implementation briefs verified against Gn).

**Note on plan-gate:** the human plan-gate (advisory, default-pass after AI self-proof) is owned
by `SKILL.md` (codesop main skill), NOT this writing-plans patch. writing-plans produces the plan
and the evidence pack; the codesop-level gate adjudicates advisory concerns. Do not block here.

The task list was already approved. Proceed without asking.
