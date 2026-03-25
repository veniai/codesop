# codesop Live PRD Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Upgrade `codesop init` so it generates a live `PRD.md` template and shared PRD update rules in `AGENTS.md`, giving projects a stable product spec plus flowing work memory from day one.

**Architecture:** Keep the change local to the existing template generator in [`codesop`](/home/qb/codesop/codesop). Replace the current static PRD heredoc, extend the generated `AGENTS.md` document-sync section with reusable PRD update rules, and lock the behavior with shell tests in [`tests/codesop-init.sh`](/home/qb/codesop/tests/codesop-init.sh). Do not couple this work to the v2 diagnosis engine yet.

**Tech Stack:** Bash, Markdown

---

### Task 1: Lock the live PRD structure in the init test

**Files:**
- Modify: `tests/codesop-init.sh`
- Test: `tests/codesop-init.sh`

**Step 1: Write the failing test**

Extend the PRD assertions so the generated `PRD.md` must contain:

- `## 0. 使用说明`
- `## 1. 当前快照`
- `## 2. 当前进度`
- `## 3. 最近决策记录`
- `## 4. 版本历史`
- `## 5. 产品核心规范`
- `## 6. 当前风险与假设`
- `## 7. 工作日志`

Also add assertions that the PRD includes:

- a current stage placeholder
- a next step placeholder
- a work log entry template

**Step 2: Run test to verify it fails**

Run: `bash tests/codesop-init.sh`
Expected: FAIL because the current template only contains the old static PRD sections

**Step 3: Write minimal implementation**

Do not implement the generator yet. Only update the test so it expresses the approved live PRD contract.

**Step 4: Run test to verify it fails as expected**

Run: `bash tests/codesop-init.sh`
Expected: FAIL on missing live PRD section assertions

**Step 5: Commit**

```bash
git add tests/codesop-init.sh
git commit -m "test: define live PRD structure for codesop init"
```

### Task 2: Replace `write_prd_template()` with the live PRD template

**Files:**
- Modify: `codesop:220-361`
- Test: `tests/codesop-init.sh`

**Step 1: Write the failing test**

Use the failing test from Task 1.

**Step 2: Run test to verify it fails**

Run: `bash tests/codesop-init.sh`
Expected: FAIL because generated `PRD.md` still uses the old static template

**Step 3: Write minimal implementation**

Replace the heredoc in `write_prd_template()` so it generates the approved dual-zone PRD with these major sections:

- `## 0. 使用说明`
- `## 1. 当前快照`
- `## 2. 当前进度`
- `## 3. 最近决策记录`
- `## 4. 版本历史`
- `## 5. 产品核心规范`
- `## 6. 当前风险与假设`
- `## 7. 工作日志`
- `## 8. 可选扩展`

Preserve:

- top metadata header
- Chinese output
- existing project name / date / tech stack interpolation
- ASCII-safe formatting

Keep the static-spec content concise. Do not duplicate `AGENTS.md` behavior rules inside the PRD.

**Step 4: Run test to verify it passes**

Run: `bash tests/codesop-init.sh`
Expected: PASS for the new PRD structure assertions

**Step 5: Commit**

```bash
git add codesop tests/codesop-init.sh
git commit -m "feat: generate live PRD template in codesop init"
```

### Task 3: Add shared PRD update rules to generated `AGENTS.md`

**Files:**
- Modify: `codesop:121-206`
- Test: `tests/codesop-init.sh`

**Step 1: Write the failing test**

Extend `tests/codesop-init.sh` so generated `AGENTS.md` must include PRD-specific update guidance covering:

- requirement and business-rule changes
- milestone / acceptance-criteria changes
- stage changes
- blocker appearance or resolution
- stable spec updates vs flow-zone updates
- skip conditions for non-behavioral edits

**Step 2: Run test to verify it fails**

Run: `bash tests/codesop-init.sh`
Expected: FAIL because the current `AGENTS.md` only contains coarse PRD update triggers

**Step 3: Write minimal implementation**

Refine the `自动文档同步规则` section in `write_agents_template()` so it distinguishes:

- when to update the PRD stable zone
- when to update the PRD flow zone
- when PRD updates can usually be skipped

Keep the README rules intact unless they need wording alignment.

**Step 4: Run test to verify it passes**

Run: `bash tests/codesop-init.sh`
Expected: PASS for the new AGENTS assertions

**Step 5: Commit**

```bash
git add codesop tests/codesop-init.sh
git commit -m "feat: add shared PRD update rules to generated AGENTS"
```

### Task 4: Update user-facing docs to describe the live PRD

**Files:**
- Modify: `README.md`
- Modify: `QUICKSTART.md`
- Modify: `SKILL.md`
- Test: `tests/codesop-init.sh`

**Step 1: Write the failing test**

Extend `tests/codesop-init.sh` to assert the docs describe generated `PRD.md` as:

- a live product document
- a current progress memory
- paired with `AGENTS.md` rules

**Step 2: Run test to verify it fails**

Run: `bash tests/codesop-init.sh`
Expected: FAIL because the docs currently describe PRD as a static standalone template

**Step 3: Write minimal implementation**

Update the docs so they consistently describe:

- `AGENTS.md` as behavior boundary
- `PRD.md` as live product + work record
- `codesop init` as generating both together

Keep wording concise and consistent across files.

**Step 4: Run test to verify it passes**

Run: `bash tests/codesop-init.sh`
Expected: PASS

**Step 5: Commit**

```bash
git add README.md QUICKSTART.md SKILL.md tests/codesop-init.sh
git commit -m "docs: describe live PRD and shared AGENTS rules"
```

### Task 5: Verify shell and generated content integrity

**Files:**
- Verify: `codesop`
- Verify: `tests/codesop-init.sh`
- Verify: generated `AGENTS.md`
- Verify: generated `PRD.md`

**Step 1: Run shell verification**

Run: `bash -n codesop`
Run: `bash -n tests/codesop-init.sh`

Expected: both exit successfully

**Step 2: Run feature verification**

Run: `bash tests/codesop-init.sh`
Expected: PASS

**Step 3: Manually inspect generated files**

Confirm that:

- `PRD.md` is still readable as a product document
- the new flow sections are near the top for quick scanning
- `AGENTS.md` update rules are specific but not bloated

**Step 4: Commit**

```bash
git add codesop tests/codesop-init.sh README.md QUICKSTART.md SKILL.md
git commit -m "test: verify live PRD template integration"
```

---

## Success Criteria

- [ ] `codesop init` generates a dual-zone live `PRD.md`
- [ ] generated `PRD.md` contains stable spec sections and flowing work-memory sections
- [ ] generated `AGENTS.md` contains reusable PRD update rules shared with future skill behavior
- [ ] init documentation describes `PRD.md` as a live document
- [ ] `bash -n codesop` passes
- [ ] `bash tests/codesop-init.sh` passes
