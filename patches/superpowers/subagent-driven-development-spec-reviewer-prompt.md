<!--
  codesop patch: subagent-driven-development spec-reviewer-prompt
  Based on: superpowers v5.1.0
  Changes vs upstream:
    1. Added mandatory step enumeration (S1..SN) before compliance check
    2. Added anti-stub detection (disabled UI, empty handlers, hardcoded returns, swallowed exceptions)
    3. Added complexity proportionality check (>3 sub-steps but <20 lines → flag)
    4. Added monolithic step self-decomposition instruction
    5. Replaced binary ✅/❌ output with Step Compliance Matrix (✅/⚠️/❌/Stub)
  Why: original "compare line by line" was directional not procedural — reviewer checked
  feature existence, not implementation depth. Stub implementations (disabled textarea,
  empty handlers) passed review because no one enumerated atomic sub-steps first.
  Revert: delete this file and run `bash setup --host claude` to restore upstream version.
-->
# Spec Compliance Reviewer Prompt Template

Use this template when dispatching a spec compliance reviewer subagent.

**Purpose:** Verify implementer built what was requested, at the right depth (not just structural presence).

```
Task tool (general-purpose):
  description: "Review spec compliance for Task N"
  prompt: |
    You are reviewing whether an implementation matches its specification.

    ## What Was Requested

    [FULL TEXT of task requirements]

    ## What Implementer Claims They Built

    [From implementer's report]

    ## Step 1: Enumerate Plan Sub-Steps

    Before checking compliance, enumerate every atomic requirement from the plan task:

    1. Read the plan task requirements above
    2. Break them down into discrete sub-steps (S1, S2, S3...)
       - Each checkbox step, bullet point, and sub-requirement is a separate S
       - If a plan step is monolithic (e.g., "implement AI panel with streaming,
         history, input, rendering, and error handling"), break it into 5+ separate S entries
       - Include behavioral requirements, not just structural ones
    3. List them as: S1: [requirement], S2: [requirement], ...

    ## Step 2: Verify Each Sub-Step Against Code

    **CRITICAL: Do Not Trust the Report**

    The implementer finished suspiciously quickly. Their report may be incomplete,
    inaccurate, or optimistic. You MUST verify everything independently.

    **DO NOT:**
    - Take their word for what they implemented
    - Trust their claims about completeness
    - Accept their interpretation of requirements
    - Accept placeholder, stub, or skeleton implementations as "done"

    **DO:**
    - Read the actual code they wrote
    - Compare actual implementation to EACH enumerated sub-step (S1..SN)
    - Check for missing pieces they claimed to implement
    - Look for extra features they didn't mention

    For each sub-step, assess coverage:
    - ✅ Fully implemented: real logic, real behavior, real tests
    - ⚠️ Partial: implementation exists and is not a stub, but covers only part of the requirement
    - ❌ Missing: no corresponding implementation at all
    - ❌ Stub: implementation is a placeholder (see anti-stub checklist below)

    **Anti-Stub Checklist — flag as ❌ Stub if you find any of:**
    - Frontend: disabled UI elements, placeholder text ("Coming Soon", "TBD"),
      components rendered with no interactivity, unused component imports
    - Backend: empty route handlers (return 200/empty body), hardcoded return values
      in production code, catch blocks that silently swallow exceptions, empty interface method bodies
    - General: TODO/FIXME/HACK comments, `// implement later`, empty function bodies

    **Complexity Proportionality Check:**
    If the plan has > 3 sub-steps but the implementation is fewer than 20 lines of effective code
    (excluding blank lines and comments), flag this as a Complexity Warning. A feature with 6
    sub-steps should not produce 3 lines of JSX.

    ## Your Job

    Read the implementation code and verify:

    **Missing requirements:**
    - Did they implement everything that was requested?
    - Are there sub-steps they skipped or missed?
    - Did they claim something works but didn't actually implement it?

    **Stub/placeholder implementations:**
    - Are there disabled components or elements?
    - Are there empty event handlers or function bodies?
    - Are there hardcoded values where real logic was expected?
    - Are there TODO/FIXME comments in production code?

    **Extra/unneeded work:**
    - Did they build things that weren't requested?
    - Did they over-engineer or add unnecessary features?

    **Misunderstandings:**
    - Did they interpret requirements differently than intended?
    - Did they solve the wrong problem?

    **Verify by reading code, not by trusting report.**

    ## Output Format

    ## Spec Compliance Review

    **Status:** ✅ Compliant | ⚠️ Partial | ❌ Non-compliant

    **Step Compliance Matrix:**

    | Step | Plan Requirement | Implementation | Status |
    |------|-----------------|---------------|--------|
    | S1   | [requirement]   | [what's in code] | ✅/⚠️/❌/❌ Stub |

    **Stub/Placeholder Warnings (if any):**
    - S?: [specific stub detected with file:line reference]

    **Complexity Flags (if any):**
    - [e.g., Plan has 6 sub-steps but implementation is 3 lines]

    **Issues (if any):**
    - [specific missing or incomplete items]

    **Extra/Unneeded Work (if any):**
    - [specific extra items]

    **Status Rules:**
    - ✅ Compliant: ALL sub-steps are ✅ (every step fully implemented)
    - ⚠️ Partial: Some ⚠️ but NO ❌ and NO Stub warnings
    - ❌ Non-compliant: ANY ❌ or Stub warning exists
```
