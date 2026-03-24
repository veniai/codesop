# codesop init Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Update `/codesop init` so it defaults to Chinese, classifies the current project, detects local tool/plugin state, and suggests `superpowers`/`gstack` installation only after user confirmation.

**Architecture:** Keep `codesop` lightweight. Store behavior in `SKILL.md`, add one shell-based detector script for stable environment and project inspection, and document the new flow in the user docs. Avoid coupling these checks to `install.sh`, which should remain the global bootstrap script for `codesop` itself.

**Tech Stack:** Markdown, Bash

---

### Task 1: Add the failing detector tests

**Files:**
- Create: `tests/detect-environment.sh`
- Test: `tests/detect-environment.sh`

**Step 1: Write the failing test**

Create a shell test harness that:

- Builds temporary fixture directories for Node/Web, Python/Backend, and monorepo cases
- Invokes `scripts/detect-environment.sh`
- Asserts expected keys appear in the output

**Step 2: Run test to verify it fails**

Run: `bash tests/detect-environment.sh`
Expected: FAIL because `scripts/detect-environment.sh` does not exist yet

**Step 3: Write minimal implementation**

Create the detector script with enough logic to satisfy the initial project classification and environment detection assertions.

**Step 4: Run test to verify it passes**

Run: `bash tests/detect-environment.sh`
Expected: PASS

### Task 2: Update `/codesop init` SOP

**Files:**
- Modify: `SKILL.md`
- Test: `tests/detect-environment.sh`

**Step 1: Write the failing test**

Extend the shell test harness to assert the updated `SKILL.md` text includes:

- default Chinese output behavior
- project detection fields
- tool and ecosystem detection
- install-after-confirmation behavior

**Step 2: Run test to verify it fails**

Run: `bash tests/detect-environment.sh`
Expected: FAIL because `SKILL.md` still reflects the old generic init flow

**Step 3: Write minimal implementation**

Update the `/codesop init` section in `SKILL.md` to match the approved behavior.

**Step 4: Run test to verify it passes**

Run: `bash tests/detect-environment.sh`
Expected: PASS

### Task 3: Document the new behavior

**Files:**
- Modify: `README.md`
- Modify: `QUICKSTART.md`
- Test: `tests/detect-environment.sh`

**Step 1: Write the failing test**

Extend the test harness to assert the documentation mentions:

- default Chinese init behavior
- project/environment detection
- confirm-before-install behavior

**Step 2: Run test to verify it fails**

Run: `bash tests/detect-environment.sh`
Expected: FAIL because the docs do not mention the new flow yet

**Step 3: Write minimal implementation**

Update the user docs with the new `init` description.

**Step 4: Run test to verify it passes**

Run: `bash tests/detect-environment.sh`
Expected: PASS

### Task 4: Verify shell integrity

**Files:**
- Verify: `scripts/detect-environment.sh`
- Verify: `install.sh`
- Verify: `tests/detect-environment.sh`

**Step 1: Run shell verification**

Run: `bash -n scripts/detect-environment.sh`
Run: `bash -n install.sh`
Run: `bash -n tests/detect-environment.sh`

Expected: all exit successfully

**Step 2: Run feature verification**

Run: `bash tests/detect-environment.sh`
Expected: PASS
