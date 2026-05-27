# writing-plans Spec Coverage Gate 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Patch writing-plans SKILL.md to add requirement extraction and subagent-based spec coverage review, replacing the current self-review.

**Architecture:** Single file change — rewrite the Self-Review section in `patches/superpowers/writing-plans-SKILL.md` to insert a Requirement Extraction step before it and replace subjective self-review with structured subagent dispatch. No changes to setup, routing, or pipeline.

**Tech Stack:** Bash (setup --host claude for verification), skill patch

---

### Task 1: Replace Self-Review section with Requirement Extraction + Subagent Review

**Files:**
- Modify: `patches/superpowers/writing-plans-SKILL.md:133-152`

- [ ] **Step 1: Replace the Self-Review and everything after it (lines 133-152)**

Open `patches/superpowers/writing-plans-SKILL.md` and replace lines 133 through end-of-file with the following content. This removes the old Self-Review and Pipeline Continuation sections, and replaces them with Requirement Extraction, the new Self-Review (with inline reviewer prompt), and Pipeline Continuation (unchanged).

Old content (lines 133-152):
```markdown
## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself -- not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Placeholder scan:** Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.

**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

If you find issues, fix them inline. No need to re-review -- just fix and move on. If you find a spec requirement with no task, add the task.

## Pipeline Continuation

**Do not stop.** After self-review:
1. TaskUpdate(current task, completed)
2. TaskList → find next pending task (source: codesop-pipeline) → execute immediately

The task list was already approved. Proceed without asking.
```

New content:
```markdown
## Requirement Extraction

Before self-review, extract all discrete requirements from the spec:

1. Read the spec document
2. Enumerate every discrete requirement as a numbered list (R1, R2, R3...)
   - A "discrete requirement" is any independently verifiable behavior, rule, constraint, output format, or edge case
   - One spec section may contain multiple discrete requirements
   - Exclude "What NOT to change" / negative constraints — these are boundaries, not tasks
3. Write the enumeration into a `## Requirement Traceability` section at the end of the plan document, as its final section

## Self-Review

After writing the complete plan and extracting requirements:

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
> - Optionally scan the spec for requirements NOT in the traceability list
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

**Do not stop.** After self-review:
1. TaskUpdate(current task, completed)
2. TaskList → find next pending task (source: codesop-pipeline) → execute immediately

The task list was already approved. Proceed without asking.
```

- [ ] **Step 2: Update the patch header comment**

Update the HTML comment at the top of the file (lines 2-10) to document the new change. Replace:

```markdown
<!--
  codesop patch: writing-plans
  Based on: superpowers v5.1.0
  Changes vs upstream:
    1. Removed Execution Handoff section (asked user to choose next skill manually)
    2. Added Pipeline Continuation — after self-review, auto-complete task and execute next
       pending pipeline task without pausing for user confirmation
  Why: codesop pipelines are pre-approved task lists; stopping to ask "what's next" after each
  plan breaks the autonomous execution flow. Pipeline re-entry in SKILL.md §3 handles routing.
  Revert: delete this file and run `bash setup --host claude` to restore upstream version.
-->
```

With:

```markdown
<!--
  codesop patch: writing-plans
  Based on: superpowers v5.1.0
  Changes vs upstream:
    1. Removed Execution Handoff section (asked user to choose next skill manually)
    2. Added Pipeline Continuation — after self-review, auto-complete task and execute next
       pending pipeline task without pausing for user confirmation
    3. Added Requirement Extraction — enumerate all spec requirements (R1..RN) before review
    4. Replaced self-review with subagent-based spec coverage check using Traceability Matrix
  Why: self-review's "skim" missed secondary requirements (conditional rules, edge cases,
  test specs) because it was section-level not requirement-level, and self-assessment has
  cognitive bias. Independent subagent + structured enumeration closes the gap.
  Revert: delete this file and run `bash setup --host claude` to restore upstream version.
-->
```

- [ ] **Step 3: Verify the patched file is valid**

Run: `bash -c 'source patches/superpowers/writing-plans-SKILL.md 2>&1 || echo "Not shell — expected"'`
Expected: "Not shell — expected" or a syntax error (it's markdown, not shell — just confirming the file exists and is readable)

- [ ] **Step 4: Apply patch and verify**

Run: `bash setup --host claude 2>&1 | grep -E "(Skill patches|writing-plans|Error|error)"`
Expected: Output containing "✓ Skill patches applied" with at least 1 file (writing-plans changed)

- [ ] **Step 5: Verify patched skill contains new sections**

Run: `grep -c "Requirement Extraction" ~/.claude/plugins/cache/*/superpowers/*/skills/writing-plans/SKILL.md`
Expected: 1

Run: `grep -c "Traceability Matrix" ~/.claude/plugins/cache/*/superpowers/*/skills/writing-plans/SKILL.md`
Expected: 2 (one in Self-Review instructions, one in the output format example)

Run: `grep -c "subagent dispatch" ~/.claude/plugins/cache/*/superpowers/*/skills/writing-plans/SKILL.md`
Expected: 1

Run: `grep -c "skim" ~/.claude/plugins/cache/*/superpowers/*/skills/writing-plans/SKILL.md`
Expected: 0 (the old "skim" approach should be completely removed)

- [ ] **Step 6: Run full test suite**

Run: `bash tests/run_all.sh`
Expected: All tests pass (this change only affects skill patch content, no CLI or test logic changed)

- [ ] **Step 7: Commit**

```bash
git add patches/superpowers/writing-plans-SKILL.md
git commit -m "feat: add spec coverage gate to writing-plans skill

Replace subjective self-review with structured requirement extraction
(R1..RN enumeration) and independent subagent coverage check using
Traceability Matrix. Fixes systematic gaps in secondary requirements."
```
