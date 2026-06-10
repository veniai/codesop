<!--
  codesop patch: writing-plans
  Based on: superpowers v5.1.0
  Changes vs upstream:
    1. Removed Execution Handoff section (asked user to choose next skill manually)
    2. Added Pipeline Continuation — after self-review, auto-complete task and execute next
       pending pipeline task without pausing for user confirmation
    3. Added Requirement Extraction — enumerate all spec requirements (R1..RN) before review
    4. Replaced self-review with subagent-based spec coverage check using Traceability Matrix
    5. Added Acceptance Criteria phase — write verifiable G1..GN with Given/When/Then or
       simplified format, adversarial self-check, Coverage Matrix (Gn↔Rn M:N), Gap Scan,
       and Complexity Assessment
    6. Added Phase Split — simple/moderate tasks generate lightweight plan (unified schema,
       brief guidance, no step-level decomposition); complex tasks continue to full Phase B
    7. Enhanced Self-Review with Acceptance Coverage Matrix for complex tasks
  Why: spec→plan deviations (omission, deformation, granularity) stem from missing the
  "define what done looks like" step between spec and task decomposition. Acceptance criteria
  as intermediate artifact closes this gap. Adversarial self-check catches vacuous criteria
  at zero token cost. Phase split avoids over-planning simple tasks while keeping rigor for
  complex ones.
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

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans -- one per subsystem. Each plan should produce working, testable software on its own.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

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

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
```

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

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

Every step must contain the actual content an engineer needs. These are **plan failures** -- never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code -- the engineer may be reading tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps)
- References to types, functions, or methods not defined in any task

## Remember
- Exact file paths always
- Complete code in every step -- if a step changes code, show the code
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

**Two formats based on change type:**

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
For each criterion, answer honestly:
> "If I implemented this in the laziest way possible (hardcoded returns, happy-path-only,
> skipping boundary checks), would this criterion still catch me?"
If no → the criterion is too weak → rewrite it.

**Quality dimensions** — every Gn must satisfy all five:
- Specific: describes an observable behavior or verifiable state
- Verifiable: includes a concrete command or check method
- Non-vacuous: cannot be trivially satisfied (e.g. "code compiles" is vacuous)
- Complete: covers normal path + at least one boundary or error path (behavior changes only)
- Unambiguous: admits only one reasonable interpretation

Write all criteria into a `## Acceptance Criteria` section in the plan document, BEFORE `## Requirement Traceability`.

**Coverage Matrix** (required for all tasks):

| Gn | Covers Rn | Verification |
|----|-----------|-------------|
| G1 | R1, R3    | test        |
| G2 | R2        | command     |

Each Rn must be covered by at least one Gn. Each Gn must cover at least one Rn.

## Gap Scan

After the Coverage Matrix, scan for categories the matrix may miss. Check each category that applies (skip irrelevant ones):

- [ ] **Negative cases**: error paths, invalid input, permission denied
- [ ] **Boundary conditions**: empty values, extremes, concurrency
- [ ] **Regression risk**: does this change break existing functionality?
- [ ] **Config/environment**: env vars, config files, platform differences
- [ ] **Docs/API**: do public interface changes need doc updates?
- [ ] **Migration/compat**: do data format changes need migration?

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

Based on complexity assessment:

**simple / moderate:**
Generate a Lightweight Plan (next section). Then Pipeline Continuation.
Skip File Structure, Task Decomposition, and full Self-Review.

**complex:**
Continue to File Structure → Task Decomposition → Self-Review (enhanced).
Then Pipeline Continuation.

## Lightweight Plan

For simple/moderate tasks only. Uses the same schema as full plans, but with reduced depth.

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

| Field | Lightweight (simple/moderate) | Full (complex) |
|-------|------------------------------|----------------|
| Implementation guidance | `brief` — key direction, implementer decides | `detailed` — complete code blocks |
| Steps | None — implementer self-decomposes | Checkbox steps with code |
| Acceptance IDs | Required | Required |
| File paths | `Likely` — estimate | Exact with line numbers |

Write the lightweight plan into the plan document. Include Plan Document Header as usual.

## Self-Review

After writing the complete plan and extracting requirements.
Only complex tasks reach this section (simple/moderate skip to Pipeline Continuation).

**1. Spec Coverage (subagent dispatch):**

Dispatch a general-purpose subagent to review spec coverage. Use this prompt:

> You are a plan coverage reviewer. Your job is to verify that every requirement
> from the spec is covered by the plan.
>
> **Plan to review:** [PLAN_FILE_PATH]
> **Spec for reference:** [SPEC_FILE_PATH]
>
> ## What to Check
>
> Read the plan's `## Requirement Traceability` section to get the enumerated
> requirements (R1, R2, ...).
>
> For each requirement:
> 1. Find it in the spec to confirm the enumeration is accurate
> 2. Find which plan task/step covers it (use `+` for cross-task coverage)
> 3. Assess coverage: ✅ fully covered, ⚠️ partial, ❌ missing
>
> Additionally:
> - Scan the full spec independently for requirements NOT in the traceability list.
>   For any spec requirement you find that has no corresponding R-number, add a row
>   to the Traceability Matrix with Req marked "UNENUMERATED-§X.X" and Status ❌.
> - Scan the plan for placeholders (TBD, TODO, "implement later", vague descriptions)
>
> ## Calibration
>
> You are a thorough reviewer, not a rubber stamp. The plan author has cognitive
> bias toward their own work. Your job is to find what they missed.
>
> Flag as ❌ any requirement with no corresponding plan task.
> Flag as ⚠️ any requirement where the plan task exists but doesn't fully address
> the spec's detail.
>
> Do NOT approve if any ❌ exists.
>
> Example ❌: Spec says "output must include error code and message" but plan
> only has a task for "output error message" — error code is missing.
>
> Example ⚠️: Spec says "validate email, phone, and address" but plan task only
> shows validation code for email and phone — address validation is implied but
> not shown.
>
> ## Output Format
>
> ## Plan Coverage Review
>
> **Status:** Approved | Issues Found
>
> **Traceability Matrix:**
> | Req | Spec Section | Plan Task | Status |
> |-----|-------------|-----------|--------|
> | R1  | §X.X        | Task N Step M | ✅/⚠️/❌ |
>
> **Issues (if any):**
> - R? (§X.X): [what's missing]
>
> **Recommendations (advisory):**
> - [non-blocking suggestions]
>
> **Acceptance Coverage Matrix:**
> | Gn | Spec Req | Plan Task | Status |
> |----|----------|-----------|--------|
> | G1 | R1       | Task 2 Step 3 | ✅/⚠️/❌ |
>
> For each acceptance criterion, verify that the plan's implementation steps
> can actually achieve the criterion's Verify condition. If a plan task exists
> but cannot pass Gn's Verify → mark ⚠️.

- Agent description: "Review plan spec coverage"
- Inputs: replace [PLAN_FILE_PATH] and [SPEC_FILE_PATH] with actual paths

If the subagent finds ❌ issues: fix them inline by adding or modifying tasks, then
re-dispatch. Maximum 2 rounds. Fixing ⚠️ only does not require re-dispatch.

**2. Placeholder scan (self-check):**

Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.

**3. Type consistency (self-check):**

Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks?

If you find issues, fix them inline. No need to re-review.

## Pipeline Continuation

**Do not stop.** After the appropriate completion point:
1. TaskUpdate(current task, completed)
2. TaskList → find next pending task (source: codesop-pipeline) → execute immediately

Completion points by tier:
- simple/moderate: after Lightweight Plan is written
- complex: after Self-Review passes

The task list was already approved. Proceed without asking.
