# Lazy-Creation 死规则修复 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix dead rules in AGENTS.md domain language section, add ADR directory creation to `codesop init`, and add ADR trigger to brainstorming patch.

**Architecture:** Three independent changes: (1) init creates `docs/adr/` directory, (2) brainstorming patch adds ADR trigger after spec writing, (3) AGENTS.md removes dead signal and rewrites ADR conflict rule.

**Tech Stack:** Bash (init-interview.sh), Markdown (AGENTS.md, brainstorming patch)

---

### Task 1: Add `docs/adr/` directory creation to `codesop init`

**Files:**
- Modify: `lib/init-interview.sh:687-692`
- Test: `tests/codesop-init.sh:48-49,56`

- [ ] **Step 1: Add test assertion for `docs/adr/` creation**

In `tests/codesop-init.sh`, after line 48 (`assert_contains "$claude_output" "✓ 创建 README.md"`), add:

```bash
assert_contains "$claude_output" "✓ 创建 docs/adr/"
```

After line 56 (`[ ! -f "$project_dir/CLAUDE.md" ] || fail "did not expect init to generate CLAUDE.md directly"`), add:

```bash
[ -d "$project_dir/docs/adr" ] || fail "expected docs/adr/ directory to be created"
[ -f "$project_dir/docs/adr/.gitkeep" ] || fail "expected docs/adr/.gitkeep to be created"
```

Also add adapt mode assertion. After line 133 (`assert_contains "$adapt_output" "README.md 已存在"`), add:

```bash
assert_contains "$adapt_output" "✓ docs/adr/ 已存在"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/codesop-init.sh 2>&1 | tail -5`
Expected: FAIL — "✓ 创建 docs/adr/" not found in output

- [ ] **Step 3: Add `docs/adr/` creation to `generate_project_files()`**

In `lib/init-interview.sh`, after line 685 (`fi` closing the README.md block) and before line 687 (`# CLAUDE.md 由 Claude Code /init 生成`), insert:

```bash

  # 4. docs/adr/ — ADR directory with .gitkeep
  if [ ! -d ./docs/adr ]; then
    mkdir -p ./docs/adr
    touch ./docs/adr/.gitkeep
    echo "✓ 创建 docs/adr/"
  else
    echo "✓ docs/adr/ 已存在"
  fi
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/codesop-init.sh 2>&1 | tail -5`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/init-interview.sh tests/codesop-init.sh
git commit -m "feat: init creates docs/adr/ directory for ADR support"
```

---

### Task 2: Clean up dead signals in AGENTS.md 领域语言 section

**Files:**
- Modify: `templates/system/AGENTS.md:70-71`

- [ ] **Step 1: Remove dead signal line**

In `templates/system/AGENTS.md`, remove line 70:

```
- 发现术语缺口时标记（signal for brainstorming 补充）
```

- [ ] **Step 2: Rewrite ADR conflict signal**

In `templates/system/AGENTS.md`, change line 71 from:

```
- 发现 ADR 冲突时显式指出
```

to:

```
- 发现 ADR 冲突时显式指出，并建议在当前任务中解决冲突或更新 ADR
```

- [ ] **Step 3: Verify the section reads correctly**

Read `templates/system/AGENTS.md` lines 66-72 and confirm:

```markdown
## 领域语言
当任务涉及需求讨论、领域术语、架构设计、跨模块改动、非平凡代码探索时：
- 先读 `CONTEXT.md`（如存在），使用词汇表术语命名
- 先读 `docs/adr/`（如存在），避免与已有架构决策矛盾
- 发现 ADR 冲突时显式指出，并建议在当前任务中解决冲突或更新 ADR
不存在则静默跳过，不提示创建。
```

- [ ] **Step 4: Run environment detection test**

Run: `bash tests/detect-environment.sh 2>&1 | tail -5`
Expected: PASS (AGENTS.md content change should not break drift detection — drift checks only look for version mismatches, not content)

- [ ] **Step 5: Commit**

```bash
git add templates/system/AGENTS.md
git commit -m "fix: remove dead signal and rewrite ADR conflict rule in AGENTS.md"
```

---

### Task 3: Add ADR trigger to brainstorming patch

**Files:**
- Modify: `patches/superpowers/brainstorming-SKILL.md:123-125`

- [ ] **Step 1: Add ADR trigger paragraph after Documentation section**

In `patches/superpowers/brainstorming-SKILL.md`, after line 123 (`- Commit the design document to git`), add:

```markdown

**ADR trigger:** When the design involved architectural decisions, significant trade-offs, or choosing between multiple approaches, check if `docs/adr/` exists in the project. If it does, suggest writing an ADR alongside the spec. Use format `NNNN-decision-title.md` with sections: 决策 / 上下文 / 结果. Commit the ADR with the spec. Simple changes with no meaningful decisions do not trigger this.
```

- [ ] **Step 2: Verify patch file reads correctly**

Read `patches/superpowers/brainstorming-SKILL.md` lines 116-130 and confirm the ADR trigger paragraph is between the Documentation section and the Domain Language Delta section (which starts at "After spec approval...").

- [ ] **Step 3: Commit**

```bash
git add patches/superpowers/brainstorming-SKILL.md
git commit -m "feat: add ADR trigger to brainstorming patch for design decisions"
```

---

### Task 4: Sync setup and run full regression

**Files:**
- Run: `setup --host claude`
- Run: `tests/run_all.sh`

- [ ] **Step 1: Sync setup to apply AGENTS.md and patch changes**

Run: `bash setup --host claude 2>&1 | tail -20`
Expected: setup completes with AGENTS.md symlink updated and brainstorming patch applied.

- [ ] **Step 2: Run full test suite**

Run: `bash tests/run_all.sh 2>&1 | tail -30`
Expected: All 9 test suites PASS.

- [ ] **Step 3: Verify AGENTS.md synced correctly**

Run: `diff templates/system/AGENTS.md ~/.claude/CLAUDE.md`
Expected: No diff (symlink should reflect changes)

- [ ] **Step 4: Commit if any sync artifacts**

(Only if setup produced changes not yet committed.)

```bash
git status --short
# If clean, skip commit
```
