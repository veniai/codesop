<!--
  codesop patch: subagent-driven-development code-quality-reviewer-prompt
  Based on: superpowers v5.1.0
  Changes vs upstream:
    1. Added Implementation Depth section replacing redundant Plan alignment
    2. Added mandatory implementation depth verification in Calibration
    3. Explicitly instructs not to defer to spec reviewer on implementation substance
  Why: code quality reviewer's "Plan alignment" duplicated spec reviewer but was weaker.
    When spec review passed, quality reviewer assumed features were complete and focused
    only on code quality. A disabled textarea has no code quality issues but is not a
    real implementation. The reviewer needs to check substance, not just structure.
  Revert: delete this file and run `bash setup --host claude` to restore upstream version.
-->
# Code Quality Reviewer Prompt Template

Use this template when dispatching a code quality reviewer subagent.

**Purpose:** Verify implementation is well-built AND substantively implemented (not just structurally present)

**Only dispatch after spec compliance review passes.**

```
Task tool (general-purpose):
  Use template at requesting-code-review/code-reviewer.md

  DESCRIPTION: [task summary, from implementer's report]
  PLAN_OR_REQUIREMENTS: Task N from [plan-file]
  BASE_SHA: [commit before task]
  HEAD_SHA: [current commit]
```

**In addition to standard code quality concerns, the reviewer MUST check:**

**File structure and responsibility:**
- Does each file have one clear responsibility with a well-defined interface?
- Are units decomposed so they can be understood and tested independently?
- Is the implementation following the file structure from the plan?
- Did this implementation create new files that are already large, or significantly grow existing files?

**Implementation depth (not just existence):**
- Spec review confirmed features exist. Your job is different.
- Are features substantively implemented, not just structurally present?
- Flag any feature that is a skeleton, stub, or placeholder despite passing spec review.
- Check: are there disabled components, empty event handlers, TODO comments, or
  functions that return hardcoded values where the plan expects real logic?

**Code reviewer returns:** Strengths, Issues (Critical/Important/Minor), Assessment

## Calibration Addition

Add this to the calibration section of the code-reviewer.md prompt:

```
**Implementation depth verification (mandatory):**
You were dispatched because spec review passed. This does NOT mean implementation
is complete — spec review checks feature existence, not depth.

For each plan step that describes interactive or complex behavior:
1. Verify the implementation has real logic, not just structural declarations
2. If plan expects user interaction but code has no event handlers → flag as Important
3. If plan expects data processing but code returns hardcoded values → flag as Important
4. If a component exists but is disabled/empty/skeleton → flag as Important

A disabled textarea has no code quality issues, but it is not a real implementation.
```
