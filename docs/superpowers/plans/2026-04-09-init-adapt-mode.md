# Init Adapt Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let `codesop init` detect existing projects and offer template synchronization instead of overwrite, plus update linkage to notify when templates change.

**Architecture:** CLI layer (`lib/init-interview.sh`) outputs an `ADAPT_MODE:YES` signal when all three core files exist. Skill layer (`commands/codesop-init.md`) reads this signal and branches into adaptation flow: compare templates vs project files, list differences, user confirms each change. Update command (`lib/commands.sh`) checks templates/ diff after pulling new commits and prints a hint.

**Tech Stack:** Bash, jq (existing dependencies only)

---

## File Structure

| File | Change | Responsibility |
|------|--------|---------------|
| `lib/commands.sh` | Modify | Add templates/ diff check in `run_update()` |
| `lib/init-interview.sh` | Modify | Add `ADAPT_MODE:YES` signal in `generate_project_files()` |
| `commands/codesop-init.md` | Modify | Update Step 5 prompt + add full adaptation mode flow |
| `CLAUDE.md` | Modify | Update Init Flow table |
| `tests/codesop-init.sh` | Modify | Add adaptation mode tests |
| `tests/codesop-init-interview.sh` | Modify | Add signal output tests |

---

### Task 1: Add ADAPT_MODE signal to CLI

**Files:**
- Modify: `lib/init-interview.sh:650-725` (generate_project_files)
- Test: `tests/codesop-init-interview.sh`

- [ ] **Step 1: Write the failing test**

Add at the end of `tests/codesop-init-interview.sh`, before the `run_tests` function:

```bash
# ============================================================================
# Test 23: generate_project_files() outputs ADAPT_MODE:YES when all files exist
# ============================================================================
test_generate_project_files_adapt_signal() {
  local tmpdir
  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' RETURN

  # Create a project with all three files
  echo "@CLAUDE.md" > "$tmpdir/AGENTS.md"
  echo "## 当前快照" > "$tmpdir/PRD.md"
  echo "# test-project" > "$tmpdir/README.md"

  local output
  output=$(generate_project_files "$tmpdir" 2>&1)

  if echo "$output" | grep -q "ADAPT_MODE:YES"; then
    pass "generate_project_files adapt mode - outputs ADAPT_MODE:YES when all files exist"
  else
    fail "generate_project_files adapt mode - should output ADAPT_MODE:YES, got: $output"
  fi
}

# ============================================================================
# Test 24: generate_project_files() does NOT output ADAPT_MODE:YES for new project
# ============================================================================
test_generate_project_files_new_mode() {
  local tmpdir
  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' RETURN

  # Empty project - no core files
  local output
  output=$(generate_project_files "$tmpdir" 2>&1)

  if echo "$output" | grep -q "ADAPT_MODE:YES"; then
    fail "generate_project_files new mode - should NOT output ADAPT_MODE:YES for new project"
  else
    pass "generate_project_files new mode - correctly omits ADAPT_MODE:YES"
  fi
}

# ============================================================================
# Test 25: generate_project_files() ADAPT_MODE only when all 3 files exist
# ============================================================================
test_generate_project_files_partial_files() {
  local tmpdir
  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' RETURN

  # Only AGENTS.md and PRD.md, missing README.md
  echo "@CLAUDE.md" > "$tmpdir/AGENTS.md"
  echo "## 当前快照" > "$tmpdir/PRD.md"

  local output
  output=$(generate_project_files "$tmpdir" 2>&1)

  if echo "$output" | grep -q "ADAPT_MODE:YES"; then
    fail "generate_project_files partial - should NOT output ADAPT_MODE:YES when README.md missing"
  else
    pass "generate_project_files partial - correctly omits ADAPT_MODE:YES when files incomplete"
  fi
}
```

Register the new tests in the `run_tests` function. Add after the existing "Template generation tests" section:

```bash
  # Adapt mode signal tests
  echo "--- Adapt mode signal tests ---"
  test_generate_project_files_adapt_signal
  test_generate_project_files_new_mode
  test_generate_project_files_partial_files
  echo ""
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/codesop-init-interview.sh 2>&1 | tail -20`
Expected: The 3 new tests FAIL because `generate_project_files` does not output `ADAPT_MODE:YES` yet.

- [ ] **Step 3: Implement ADAPT_MODE signal**

In `lib/init-interview.sh`, modify `generate_project_files()` to detect adaptation mode. Add at the end of the function, just before `cd "$original_dir"`:

Replace the section from line 720 to 725:

```bash
  # CLAUDE.md 由 Claude Code /init 生成，此处不处理

  # Signal adapt mode if all three core files existed before this function ran
  if [ -f ./AGENTS.md ] && [ -f ./PRD.md ] && [ -f ./README.md ]; then
    echo "ADAPT_MODE:YES"
  fi

  # Return to original directory
  cd "$original_dir" || return 1

  return 0
```

Wait — there's a subtlety. `generate_project_files` creates files that don't exist. So checking at the end would always be true for new projects too (it just created them). We need to check **before** any creation.

Better approach: check at the **start** of the function, store a flag, output at the end.

At the beginning of `generate_project_files()`, after `cd "$target_dir"`, add:

```bash
  # Detect adapt mode: all three core files already exist
  local adapt_mode=false
  if [ -f ./AGENTS.md ] && [ -f ./PRD.md ] && [ -f ./README.md ]; then
    adapt_mode=true
  fi
```

At the end, before `cd "$original_dir"`, add:

```bash
  # Output adapt mode signal for skill layer
  if [ "$adapt_mode" = true ]; then
    echo "ADAPT_MODE:YES"
  fi
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/codesop-init-interview.sh`
Expected: ALL TESTS PASSED (including the 3 new ones)

Run: `bash tests/codesop-init.sh`
Expected: PASS (existing tests still pass)

- [ ] **Step 5: Commit**

```bash
git add lib/init-interview.sh tests/codesop-init-interview.sh
git commit -m "feat: add ADAPT_MODE:YES signal when init detects existing project files"
```

---

### Task 2: Add templates/ diff check to update command

**Files:**
- Modify: `lib/commands.sh:120-142` (run_update, "有新提交" branch)
- Test: `tests/codesop-init.sh` (existing test file, add update-specific test)

- [ ] **Step 1: Write the failing test**

Add at the end of `tests/codesop-init.sh`, before the final `echo "PASS"`:

```bash
# --- Test: update command templates diff hint ---
echo "--- codesop update templates diff hint ---"

# Create a fake codesop repo with git history
fake_repo="$tmpdir/codesop-repo"
mkdir -p "$fake_repo/templates/project"
cd "$fake_repo"
git init -q
git config user.email "test@test.com"
git config user.name "Test"

# Initial commit with templates
echo "old template" > templates/project/PRD.md
echo "old readme" > templates/project/README.md
git add -A
git commit -qm "initial"

old_hash="$(git rev-parse HEAD)"

# Update templates
echo "new template content" > templates/project/PRD.md
git add -A
git commit -qm "update templates"

new_hash="$(git rev-parse HEAD)"

# Test: templates changed → diff should be non-empty
if git diff "$old_hash".."$new_hash" -- templates/ --quiet 2>/dev/null; then
  fail "expected templates diff to be non-empty after template change"
else
  assert_contains "$(git diff "$old_hash".."$new_hash" -- templates/)" "new template content"
fi

# Test: no templates changed → diff should be empty
echo "other change" > unrelated.txt
git add -A
git commit -qm "non-template change"

mid_hash="$(git rev-parse HEAD)"
if git diff "$new_hash".."$mid_hash" -- templates/ --quiet 2>/dev/null; then
  :
else
  fail "expected templates diff to be empty when only non-template files changed"
fi
```

- [ ] **Step 2: Run test to verify git diff logic works**

Run: `bash tests/codesop-init.sh 2>&1 | tail -10`
Expected: PASS (this test verifies git diff semantics, not run_update behavior)

- [ ] **Step 3: Implement templates diff check in run_update()**

In `lib/commands.sh`, in `run_update()`, after the "最近变更" output block (after line 142), add:

```bash
  # Check if templates changed — hint user to re-run init for adaptation
  if [ -n "$old_hash" ] && [ -n "$new_hash" ] && [ "$old_hash" != "$new_hash" ]; then
    if ! git diff "$old_hash".."$new_hash" -- templates/ --quiet 2>/dev/null; then
      printf '\n%s\n' "模板已更新，建议对已有项目运行 /codesop-init"
    fi
  fi
```

- [ ] **Step 4: Run all tests**

Run: `bash tests/codesop-init.sh`
Expected: PASS

Run: `bash tests/codesop-init-interview.sh`
Expected: ALL TESTS PASSED

- [ ] **Step 5: Commit**

```bash
git add lib/commands.sh tests/codesop-init.sh
git commit -m "feat: update command hints when templates change between versions"
```

---

### Task 3: Update codesop-init.md skill — Step 5 prompt + adaptation mode

**Files:**
- Modify: `commands/codesop-init.md`
- Test: manual (skill content, tested via `bash tests/codesop-router.sh`)

- [ ] **Step 1: Read current skill content**

Read `commands/codesop-init.md` to confirm current Step 5 text.

- [ ] **Step 2: Update Step 5 prompt for new-mode**

In `commands/codesop-init.md`, find the Step 5 section. Replace the current Step 5 prompt text. Change from the old text about "运行 /init 生成项目级 CLAUDE.md" to:

```
初始化完成。请在当前会话中运行 `/init` 生成项目级 CLAUDE.md。参考系统级 CLAUDE.md 中对项目文档的要求。
```

- [ ] **Step 3: Add adaptation mode flow after Step 4**

In `commands/codesop-init.md`, after the Step 4 CLI execution block and before Step 5, add a new conditional block:

```markdown
#### 适配模式检测

Step 4 的 CLI 输出中包含 `ADAPT_MODE:YES` 信号时，进入适配模式。

**适配模式行为：**

1. **读取模板文件**（codesop 仓库内）：
   - `templates/project/PRD.md`
   - `templates/project/README.md`
   - `templates/system/AGENTS.md`

2. **读取项目文件**（当前项目目录）：
   - `PRD.md`
   - `README.md`
   - `CLAUDE.md`

3. **对比并生成建议清单**：
   - PRD.md：对比项目文件和模板，列出新增章节、结构调整建议
   - README.md：对比项目文件和模板，列出缺失章节建议
   - CLAUDE.md：对比项目 CLAUDE.md 和系统级 AGENTS.md 模板，找出重复内容，建议清理

4. **用户逐项确认**：
   - 展示每条建议，用户选择采纳或跳过
   - 只执行用户确认的变更

**原则：AI 建议，用户确认，改什么用户说了算。**

没有 `ADAPT_MODE:YES` 信号时，走现有新建模式流程。
```

- [ ] **Step 4: Run router consistency test**

Run: `bash tests/codesop-router.sh`
Expected: PASS (skill file is valid)

- [ ] **Step 5: Commit**

```bash
git add commands/codesop-init.md
git commit -m "feat: add adaptation mode instructions to codesop-init skill"
```

---

### Task 4: Update CLAUDE.md Init Flow table

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Update Init Flow table**

In `CLAUDE.md`, find the Init Flow table. Add a row for adaptation mode:

Replace the current table:

```markdown
## Init Flow

`/codesop-init` skill handles project initialization in coordination with Claude Code's `/init`:

| Phase | Owner | What it does |
|-------|-------|-------------|
| 0 | Skill Step 0 | Self-heal: `codesop update` + re-read fresh skill |
| 0 | CLI | Tool detection, system links, `CLAUDE_CODE_NEW_INIT` |
| 1 | Skill Step 2-3 | User preference interview (language, style, etc.) |
| 1 | CLI | Skip if preferences already set |
| 2 | — | **User runs `/init`** to generate project CLAUDE.md |
| 3 | CLI | AGENTS.md (`@CLAUDE.md`), PRD.md, README.md |
| 4 | CLI | Plugin dependency checks (superpowers + optional plugins) |
```

With:

```markdown
## Init Flow

`/codesop-init` skill handles project initialization in coordination with Claude Code's `/init`:

| Phase | Owner | What it does |
|-------|-------|-------------|
| 0 | Skill Step 0 | Self-heal: `codesop update` + re-read fresh skill |
| 0 | CLI | Tool detection, system links, `CLAUDE_CODE_NEW_INIT` |
| 1 | Skill Step 2-3 | User preference interview (language, style, etc.) |
| 1 | CLI | Skip if preferences already set |
| 2 | — | **User runs `/init`** to generate project CLAUDE.md |
| 3 | CLI | AGENTS.md (`@CLAUDE.md`), PRD.md, README.md |
| 4 | CLI | Plugin dependency checks (superpowers + optional plugins) |
| 4a | Skill | If `ADAPT_MODE:YES`: template adaptation (PRD/README diff + CLAUDE.md dedup) |
| 5 | Skill | Prompt user to run `/init` (new mode) or confirm adaptation (adapt mode) |

**Adaptation mode** triggers when all three core files (AGENTS.md, PRD.md, README.md) already exist. CLI outputs `ADAPT_MODE:YES` signal; skill compares templates vs project files and suggests changes for user confirmation.
```

- [ ] **Step 2: Run detect-environment test (checks CLAUDE.md consistency)**

Run: `bash tests/detect-environment.sh`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update Init Flow table with adaptation mode phases"
```

---

### Task 5: Add init command tests for adaptation mode

**Files:**
- Modify: `tests/codesop-init.sh`

- [ ] **Step 1: Write test for adapt mode CLI output**

Add before the final `echo "PASS"` in `tests/codesop-init.sh`:

```bash
# --- Test: ADAPT_MODE:YES signal in CLI output for existing project ---
echo "--- init adapt mode signal ---"

adapt_project="$tmpdir/adapt-project"
mkdir -p "$adapt_project"
echo "@CLAUDE.md" > "$adapt_project/AGENTS.md"
echo "## 当前快照" > "$adapt_project/PRD.md"
echo "# adapt-project" > "$adapt_project/README.md"
cat >"$adapt_project/package.json" <<'PKGEOF'
{
  "name": "adapt-web",
  "dependencies": { "next": "15.0.0" }
}
PKGEOF

adapt_output="$(HOME="$claude_home" bash "$CLI" init "$adapt_project" 2>&1)"

assert_contains "$adapt_output" "ADAPT_MODE:YES"
assert_contains "$adapt_output" "AGENTS.md 已是简单引用格式"
assert_contains "$adapt_output" "PRD.md 已是活文档格式"
assert_contains "$adapt_output" "README.md 已存在"

# Verify files were NOT overwritten
agents_check="$(cat "$adapt_project/AGENTS.md")"
[ "$agents_check" = "@CLAUDE.md" ] || fail "AGENTS.md should not be overwritten in adapt mode"
```

- [ ] **Step 2: Run the test**

Run: `bash tests/codesop-init.sh`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add tests/codesop-init.sh
git commit -m "test: add adapt mode signal verification for init command"
```

---

### Task 6: Resync and final verification

**Files:**
- No new changes

- [ ] **Step 1: Run all test suites**

```bash
bash tests/codesop-init.sh && \
bash tests/codesop-init-interview.sh && \
bash tests/codesop-router.sh && \
bash tests/detect-environment.sh && \
bash tests/setup.sh
```

Expected: All pass.

- [ ] **Step 2: Resync host integration**

```bash
bash setup --host claude
```

Expected: Successful sync.

- [ ] **Step 3: Verify setup installed updated skill**

Check that `~/.claude/commands/codesop-init.md` contains the adaptation mode instructions.

Run: `grep -c "ADAPT_MODE" "$HOME/.claude/commands/codesop-init.md" || echo "NOT FOUND"`

Expected: Count > 0 (adaptation mode text is present).

- [ ] **Step 4: Final commit if any sync artifacts**

```bash
git status
```

If clean, no commit needed. If any changes from sync, commit them.
