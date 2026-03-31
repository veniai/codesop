# Remove `codesop setup` User-Facing CLI Surface

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove `codesop setup` from the user-facing product contract, keeping `bash setup --host X` as an internal-only operation.

**Architecture:** The `setup` script remains as an internal tool called by `install.sh` and `run_update()`. The CLI entrypoint `codesop` drops the `setup` subcommand. The `run_setup()` function stays in `lib/commands.sh` as an internal helper. The `/codesop-setup` slash command is deleted. Product contract changes from "1 flow + 3 commands" to "1 flow + 2 commands".

**Tech Stack:** Bash, jq (for existing tests), git

---

## File Structure

| File | Action | Responsibility |
|------|--------|---------------|
| `codesop` | Modify | Remove `setup` case from subcommand dispatch |
| `lib/commands.sh` | Modify | Keep `run_setup()` as internal, remove from user-facing surface |
| `commands/codesop-setup.md` | Delete | Slash command no longer exposed |
| `SKILL.md` | Modify | Remove `/codesop setup` from sub-commands section, update product position |
| `config/codesop-router.md` | No change | Already does not reference setup |
| `PRD.md` | Modify | Update product contract from 3 to 2 commands |
| `README.md` | Modify | Remove `codesop setup` references, update product contract |
| `CLAUDE.md` | Modify | Remove `codesop setup` from commands section |
| `install.sh` | Modify | Remove "To resync" hint that references `codesop setup` |
| `tests/codesop-e2e.sh` | Modify | Remove `setup` from usage assertion, add `setup` to "unknown subcommand" tests |
| `setup` | No change | Internal script, stays as-is |

---

### Task 1: Remove `setup` subcommand from CLI entrypoint

**Files:**
- Modify: `codesop`

- [ ] **Step 1: Remove setup case from subcommand dispatch**

Current code at lines 22-54:

```bash
usage() {
  cat <<'EOF'
Usage:
  codesop init [path]
  codesop setup [--host X]
  codesop update

Hosts: claude, codex, opencode, openclaw, auto
EOF
}

subcommand="${1:-}"

case "$subcommand" in
  init)
    shift || true
    run_init_interview "${1:-.}"
    ;;
  setup)
    shift || true
    run_setup "${1:-auto}"
    ;;
  update)
    run_update
    ;;
  ""|-h|--help|help)
    usage
    ;;
  *)
    printf '%s\n' "未知子命令：$subcommand" >&2
    usage >&2
    exit 1
    ;;
esac
```

Replace with:

```bash
usage() {
  cat <<'EOF'
Usage:
  codesop init [path]
  codesop update
EOF
}

subcommand="${1:-}"

case "$subcommand" in
  init)
    shift || true
    run_init_interview "${1:-.}"
    ;;
  update)
    run_update
    ;;
  ""|-h|--help|help)
    usage
    ;;
  *)
    printf '%s\n' "未知子命令：$subcommand" >&2
    usage >&2
    exit 1
    ;;
esac
```

- [ ] **Step 2: Verify setup is rejected as unknown**

Run: `bash codesop setup --host claude 2>&1`
Expected: Output contains "未知子命令：setup"

- [ ] **Step 3: Commit**

```bash
git add codesop
git commit -m "refactor: remove setup from CLI subcommand dispatch"
```

---

### Task 2: Delete `/codesop-setup` slash command

**Files:**
- Delete: `commands/codesop-setup.md`

- [ ] **Step 1: Delete the file**

```bash
rm commands/codesop-setup.md
```

- [ ] **Step 2: Verify setup still works (it never installed this during `bash setup`)**

Run: `bash tests/setup.sh 2>&1 | tail -3`
Expected: PASS (setup tests don't reference codesop-setup.md)

- [ ] **Step 3: Commit**

```bash
git add -u commands/codesop-setup.md
git commit -m "refactor: delete /codesop-setup slash command"
```

---

### Task 3: Update SKILL.md — remove setup from sub-commands section

**Files:**
- Modify: `SKILL.md`

- [ ] **Step 1: Remove setup references from sub-commands**

In section 8, there is no explicit `/codesop setup` subsection currently. But section 1.1 lists it:

```
- `/codesop init`
- `/codesop setup`
- `/codesop update`
```

Change to:

```
- `/codesop init`
- `/codesop update`
```

And section 8.2 lists update sub-commands only. No setup section exists in section 8. Good.

- [ ] **Step 2: Verify SKILL.md has no remaining `codesop setup` references**

Run: `grep -n 'codesop setup' SKILL.md`
Expected: No matches (or only historical/contextual mentions, not as a user-facing command)

- [ ] **Step 3: Commit**

```bash
git add SKILL.md
git commit -m "refactor: remove setup from SKILL.md CLI bypass list"
```

---

### Task 4: Update product contract documents (PRD, README, CLAUDE)

**Files:**
- Modify: `PRD.md`
- Modify: `README.md`
- Modify: `CLAUDE.md`

- [ ] **Step 1: Update PRD.md**

Change all occurrences of the product contract from "三个机械命令" to "两个机械命令", and from "3 个命令" to "2 个命令". Remove `codesop setup` from every list that enumerates the supported commands. Key locations:

1. Section 1 当前快照: "当前目标" line
2. Section 5.3 In Scope: "三个机械命令" → "两个机械命令", remove `codesop setup`
3. Section 5.4 核心功能: remove the `codesop setup` bullet
4. Section 5.5 对外只承诺这 4 个入口: remove `codesop setup`, change "4 个" to "3 个"
5. Section 5.8 收口矩阵 保留: remove `codesop setup`
6. Section 5.9 验收标准: remove `bash setup --host claude` if it references user-facing surface

- [ ] **Step 2: Update README.md**

1. Remove `codesop setup --host auto` from install instructions
2. Remove `codesop setup --host claude` from usage section
3. Change "机械命令只有三个" to "机械命令只有两个"
4. Remove `codesop setup` from product contract list
5. Remove "codesop setup" from the "What gets installed" table if it appears there

- [ ] **Step 3: Update CLAUDE.md**

1. Remove `bash codesop setup --host X` from Commands section
2. Change "Supported user-facing commands" from 3 to 2, remove `codesop setup`
3. Remove `bash codesop setup --host claude` from resync instruction (replace with `bash setup --host claude`)

- [ ] **Step 4: Run documentation consistency test**

Run: `bash tests/detect-environment.sh 2>&1`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add PRD.md README.md CLAUDE.md
git commit -m "docs: update product contract from 3 to 2 mechanical commands"
```

---

### Task 5: Update install.sh — remove `codesop setup` resync hint

**Files:**
- Modify: `install.sh`

- [ ] **Step 1: Replace the resync hint**

Current line 33:
```
echo "To resync after local edits: codesop setup auto"
```

Change to:
```
echo "To update: codesop update"
```

The `codesop update` command already calls `bash setup --host auto` internally, so this is the correct user-facing instruction.

- [ ] **Step 2: Commit**

```bash
git add install.sh
git commit -m "refactor: replace codesop setup hint with codesop update in installer"
```

---

### Task 6: Update tests

**Files:**
- Modify: `tests/codesop-e2e.sh`

- [ ] **Step 1: Remove setup from usage assertion and add it to rejected commands**

Current test (lines 23-26):
```bash
usage_output="$(bash "$CLI" 2>&1)"
assert_contains "$usage_output" "Usage:"
assert_contains "$usage_output" "codesop init [path]"
assert_contains "$usage_output" "codesop setup [--host X]"
assert_contains "$usage_output" "codesop update"
```

Change to:
```bash
usage_output="$(bash "$CLI" 2>&1)"
assert_contains "$usage_output" "Usage:"
assert_contains "$usage_output" "codesop init [path]"
assert_contains "$usage_output" "codesop update"

if setup_output="$(bash "$CLI" setup --host claude 2>&1)"; then
  fail "expected removed setup subcommand to fail"
fi

assert_contains "$setup_output" "未知子命令：setup"
assert_contains "$setup_output" "Usage:"
```

- [ ] **Step 2: Run e2e test**

Run: `bash tests/codesop-e2e.sh 2>&1`
Expected: PASS

- [ ] **Step 3: Run all tests**

Run:
```bash
bash tests/codesop-e2e.sh && bash tests/codesop-router.sh && bash tests/codesop-init-interview.sh && bash tests/codesop-init.sh && bash tests/codesop-symlink.sh && bash tests/detect-environment.sh && bash tests/setup.sh
```
Expected: All PASS

- [ ] **Step 4: Commit**

```bash
git add tests/codesop-e2e.sh
git commit -m "test: update e2e test for removal of setup subcommand"
```

---

## Self-Review

**Spec coverage:**
- CLI entrypoint removal: Task 1 ✓
- Slash command deletion: Task 2 ✓
- SKILL.md update: Task 3 ✓
- Product contract docs: Task 4 ✓
- Installer hint: Task 5 ✓
- Tests: Task 6 ✓

**Placeholder scan:** No TBD, TODO, or vague steps. All code changes specified with exact content.

**Type consistency:** `run_setup()` stays in `lib/commands.sh` as internal function. All callers (`run_update`, `install.sh`) continue to call `bash setup --host auto` directly. No naming conflicts.
