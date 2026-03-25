# codesop Skill-CLI Integration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Connect the `codesop` skill and `/codesop` CLI diagnosis layer so the skill can reliably consume fresh project-state facts while still using `AGENTS.md` and `PRD.md` as the main context sources.

**Architecture:** Keep the skill primary. Update [`SKILL.md`](/home/qb/codesop/SKILL.md) so it explicitly decides when to call `/codesop`, and refine the CLI output wording only where needed to better support workbench-summary synthesis. Do not introduce new diagnosis dimensions yet; this phase is about interface clarity, not feature growth.

**Tech Stack:** Markdown, Bash

---

### Task 1: Lock the integration contract in tests

**Files:**
- Modify: `tests/detect-environment.sh`
- Test: `tests/detect-environment.sh`

**Step 1: Write the failing test**

Extend the `SKILL.md` assertions so they require wording that makes the integration explicit:

- the skill should call `/codesop` when fresh project-state facts are needed
- the skill still reads `AGENTS.md` then `PRD.md` first
- the CLI is described as diagnosis/context support, not the final reasoning layer

**Step 2: Run test to verify it fails**

Run: `bash tests/detect-environment.sh`
Expected: FAIL because current wording does not yet explicitly define the integration contract

**Step 3: Write minimal implementation**

Only update the test expectations for the approved contract.

**Step 4: Run test to verify it fails as expected**

Run: `bash tests/detect-environment.sh`
Expected: FAIL on the new integration assertions

### Task 2: Update `SKILL.md` with explicit CLI integration behavior

**Files:**
- Modify: `SKILL.md`
- Test: `tests/detect-environment.sh`

**Step 1: Write the failing test**

Use the failing assertions from Task 1.

**Step 2: Run test to verify it fails**

Run: `bash tests/detect-environment.sh`
Expected: FAIL

**Step 3: Write minimal implementation**

Update `SKILL.md` to explicitly state:

- when the skill should call `/codesop`
- when it should not
- how CLI facts map into the workbench summary
- that PRD/AGENTS remain primary context sources

Keep the current routing content. Do not expand workflow coverage.

**Step 4: Run test to verify it passes**

Run: `bash tests/detect-environment.sh`
Expected: PASS

### Task 3: Tighten `/codesop` wording for skill consumption

**Files:**
- Modify: `codesop`
- Test: `tests/codesop-diagnose.sh`
- Test: `tests/codesop-e2e.sh`

**Step 1: Write the failing test**

Extend diagnosis tests to assert the CLI output contains stable section wording the skill can consume reliably:

- `## 项目诊断`
- `**当前阶段**`
- `**置信度**`
- `**健康状态**`
- `## 技能推荐`

**Step 2: Run test to verify it fails**

Run: `bash tests/codesop-diagnose.sh`
Run: `bash tests/codesop-e2e.sh`
Expected: FAIL if any wording does not match the integration contract

**Step 3: Write minimal implementation**

Adjust wording only as needed. Do not add new behavior.

**Step 4: Run test to verify it passes**

Run: `bash tests/codesop-diagnose.sh`
Run: `bash tests/codesop-e2e.sh`
Expected: PASS

### Task 4: Add integrated eval prompts for the skill

**Files:**
- Create: `evals/evals.json`
- Modify: `SKILL.md`

**Step 1: Write eval prompts**

Add at least 3 realistic prompts:

- “继续这个项目，告诉我现在做到哪了”
- “我有点乱，先帮我整理状态和下一步”
- “这个仓库下一步应该用什么 skill”

**Step 2: Document expected behavior**

For each prompt, record the expected shape:

- reads AGENTS first
- reads PRD next
- uses `/codesop` when fresh facts matter
- outputs workbench summary + skill routing

**Step 3: Save the eval file**

Save as `evals/evals.json`

### Task 5: Verify the integrated contract

**Files:**
- Verify: `SKILL.md`
- Verify: `codesop`
- Verify: `tests/detect-environment.sh`
- Verify: `tests/codesop-diagnose.sh`
- Verify: `tests/codesop-e2e.sh`

**Step 1: Run verification**

Run: `bash tests/detect-environment.sh`
Run: `bash tests/codesop-diagnose.sh`
Run: `bash tests/codesop-e2e.sh`
Run: `bash -n codesop`

Expected: all pass

**Step 2: Inspect final behavior**

Confirm the system now reads as one coherent story:

- skill owns orientation
- CLI owns facts
- documents own memory

---

## Success Criteria

- [ ] `SKILL.md` explicitly defines when to call `/codesop`
- [ ] `SKILL.md` still treats `AGENTS.md` and `PRD.md` as primary context
- [ ] `/codesop` output wording is stable enough for skill consumption
- [ ] integrated prompts are recorded for later eval work
- [ ] all relevant tests pass
