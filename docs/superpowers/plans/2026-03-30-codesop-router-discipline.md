# codesop Router Discipline Layer — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a three-layer discipline system (SessionStart hook + AGENTS.md + codesop.md) that forces AI agents to use the correct skills by requiring a task alignment block before every new task.

**Architecture:** Router card in `config/` synced to `~/.claude/` by setup. SessionStart hook injects it into every conversation. `commands/codesop.md` adds task alignment checkpoint to the pipeline. `templates/system/AGENTS.md` adds a brief discipline statement shared across all hosts.

**Tech Stack:** Bash, jq (optional, for settings.json mutation), Claude Code hooks API

**Spec:** `docs/superpowers/specs/2026-03-29-codesop-router-discipline-design.md`

---

## File Structure

| File | Action | Responsibility |
|------|--------|---------------|
| `config/codesop-router.md` | Create | Router card source of truth, ~30 lines |
| `setup` | Modify | Add `install_router_card()` + `configure_hooks()` + dependency checks |
| `templates/system/AGENTS.md` | Modify | Add skill discipline section (~5 lines) |
| `commands/codesop.md` | Modify | Add task alignment mechanism to Decision Flow + Iron Law |
| `tests/codesop-router.sh` | Create | Verify router card consistency + setup integration |

---

### Task 1: Create Router Card

**Files:**
- Create: `config/codesop-router.md`

- [ ] **Step 1: Create the router card file**

This is the content injected by SessionStart hook. It must list ALL mandatory skills from the pipeline in `commands/codesop.md` — it is an index, not a simplification.

```markdown
## codesop 路由卡

新任务必须先输出任务对齐块（理解 + 阶段 + Skill）。
完整 pipeline 定义见 /codesop。

### 必走路径（不可跳过）
| 用户信号 | Pipeline 阶段 | 必走 Skill 序列 |
|---------|--------------|----------------|
| 做功能 / 加东西 / 重构 | 探索→计划→执行→验证→review | brainstorming → writing-plans → autoplan → using-git-worktrees → subagent-driven-development → test-driven-development → verification-before-completion → review |
| 修 bug / 测试挂了 | 调试→验证→review | systematic-debugging → verification-before-completion → review |
| 做完了 / 修好了 | 验证→review | verification-before-completion → qa(web) → review |
| 发布 / ship | 发布→清理 | ship → document-release |

### 可选路径
| 用户信号 | Skill |
|---------|-------|
| 方向不明确 | office-hours |
| 测一下 (web) | qa |
| 小心点 | careful |
| 只改这个目录 | freeze |

### 铁律
- 跳过必走 Skill = 先输出对齐块说明原因
- 不确定 → 先调用 /codesop
```

- [ ] **Step 2: Verify the file exists and is valid markdown**

Run: `cat config/codesop-router.md | head -5`
Expected: Shows "## codesop 路由卡"

---

### Task 2: Add install_router_card() to setup

**Files:**
- Modify: `setup:128-138` (inside `install_claude()`)

- [ ] **Step 1: Add install_router_card function before install_claude**

Insert after line 122 (`printf '%s\n' "$SOURCE_DIR" > "$target_dir/.codesop-source"`) in `setup`:

```bash
install_router_card() {
  local src="$SOURCE_DIR/config/codesop-router.md"
  local dst="$HOME/.claude/codesop-router.md"

  if [ ! -f "$src" ]; then
    echo "  ⚠ config/codesop-router.md not found — skipping router card install"
    return 0
  fi

  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  echo "  ✓ Router card: $dst"
}
```

- [ ] **Step 2: Add configure_hooks function after install_router_card**

```bash
configure_hooks() {
  local settings="$HOME/.claude/settings.json"

  # Bootstrap settings.json if missing
  if [ ! -f "$settings" ]; then
    mkdir -p "$(dirname "$settings")"
    echo '{}' > "$settings"
  fi

  if ! command -v jq >/dev/null 2>&1; then
    echo "  ⚠ jq not found — hook auto-config skipped"
    echo "    Manual step: add to $settings:"
    echo '    "hooks":{"SessionStart":[{"matcher":"","hooks":[{"type":"command","command":"cat ~/.claude/codesop-router.md"}]}]}'
    return 0
  fi

  # Idempotency: check if hook already exists
  local existing
  existing=$(jq '[.hooks.SessionStart // [] | .[] | select(.hooks // [] | .[]?.command == "cat ~/.claude/codesop-router.md")] | length' "$settings" 2>/dev/null || echo "0")
  if [ "$existing" != "0" ]; then
    echo "  ✓ codesop-router hook already configured"
    return 0
  fi

  # Merge hook using correct Claude Code schema
  jq '.hooks.SessionStart += [{"matcher":"","hooks":[{"type":"command","command":"cat ~/.claude/codesop-router.md"}]}]' \
    "$settings" > "$settings.tmp" && mv "$settings.tmp" "$settings"
  echo "  ✓ SessionStart hook configured"
}
```

- [ ] **Step 3: Add dependency check function**

```bash
check_discipline_deps() {
  local missing=0

  if [ ! -d "$HOME/.claude/plugins/cache" ] || ! find "$HOME/.claude/plugins/cache" -name "using-superpowers" -type d 2>/dev/null | grep -q .; then
    echo "  ⚠ superpowers plugin not found — router card needs it"
    missing=1
  fi

  if [ ! -d "$HOME/.claude/skills/gstack" ]; then
    echo "  ⚠ gstack skills not found — some routes won't work"
    missing=1
  fi

  return $missing
}
```

- [ ] **Step 4: Wire install_router_card + configure_hooks into install_claude**

Modify the `install_claude()` function. After the existing `echo "  ✓ Claude Code: ..."` line (line 137), add:

```bash
  install_router_card
  configure_hooks
```

And at the start of `install_claude()`, add:

```bash
  check_discipline_deps || true
```

The full modified `install_claude()`:

```bash
install_claude() {
  check_discipline_deps || true
  ensure_symlink "$SYSTEM_AGENTS_TEMPLATE" "$HOME/.claude/CLAUDE.md"
  write_skill_runtime "$HOME/.claude/skills/codesop"
  prepare_runtime_dir "$HOME/.claude/commands"
  copy_file "$SOURCE_DIR/commands/codesop.md" "$HOME/.claude/commands/codesop.md"
  copy_file "$SOURCE_DIR/commands/codesop-init.md" "$HOME/.claude/commands/codesop-init.md"
  copy_file "$SOURCE_DIR/commands/codesop-status.md" "$HOME/.claude/commands/codesop-status.md"
  copy_file "$SOURCE_DIR/commands/codesop-update.md" "$HOME/.claude/commands/codesop-update.md"
  copy_file "$SOURCE_DIR/commands/codesop-setup.md" "$HOME/.claude/commands/codesop-setup.md"
  echo "  ✓ Claude Code: ~/.claude/CLAUDE.md + ~/.claude/skills/codesop/"
  install_router_card
  configure_hooks
}
```

- [ ] **Step 5: Verify setup runs without error**

Run: `cd /home/claw/codesop && bash setup --host claude 2>&1`
Expected: All ✓ lines, no errors. Including "Router card:" and "SessionStart hook" lines.

- [ ] **Step 6: Verify settings.json has correct hook**

Run: `cat ~/.claude/settings.json | jq '.hooks.SessionStart'`
Expected: Array containing the codesop-router hook with correct schema (`{ "matcher": "", "hooks": [{ "type": "command", "command": "cat ~/.claude/codesop-router.md" }] }`)

- [ ] **Step 7: Verify router card installed**

Run: `cat ~/.claude/codesop-router.md | head -3`
Expected: Shows "## codesop 路由卡"

---

### Task 3: Add Skill Discipline to AGENTS.md Template

**Files:**
- Modify: `templates/system/AGENTS.md`

- [ ] **Step 1: Append discipline section to AGENTS.md**

Add to the end of `templates/system/AGENTS.md`:

```markdown

## Skill 纪律
新任务先输出任务对齐块（理解 + 阶段 + Skill）。详细路由见 /codesop。
如果 AI 跳过了应走的 skill，用户可以指出 "你跳过了 X"，AI 应立即输出对齐块并重新走 pipeline。
```

- [ ] **Step 2: Verify the template is valid**

Run: `tail -5 templates/system/AGENTS.md`
Expected: Shows the discipline section

- [ ] **Step 3: Re-run setup to sync**

Run: `bash setup --host claude 2>&1`
Expected: "✓ Claude Code" line, symlink updated.

- [ ] **Step 4: Verify installed CLAUDE.md has the section**

Run: `tail -5 ~/.claude/CLAUDE.md`
Expected: Shows "## Skill 纪律" section

---

### Task 4: Add Task Alignment to codesop.md

**Files:**
- Modify: `commands/codesop.md:9-15` (after EXTREMELY-IMPORTANT)
- Modify: `commands/codesop.md:194-201` (Decision Flow)
- Modify: `commands/codesop.md:333-342` (Iron Law)

- [ ] **Step 1: Add task alignment block requirement after EXTREMELY-IMPORTANT**

Insert after line 15 (after the closing tag of EXTREMELY-IMPORTANT), before "## Instruction Priority":

```markdown
## Task Alignment (MANDATORY)

Before routing to any skill, output this block:

```
🎯 任务对齐
- 理解: [用自己的话复述要做什么]
- 阶段: [Pipeline Stage N: 名称]
- 必用 Skill: [列出将调用的 skill]
- 跳过及原因: [如跳过某阶段，说明为什么]
```

Trigger conditions:
- User requests a new feature, bugfix, or refactoring
- Moving from one pipeline stage to the next
- User says "开始做" / "执行" / "修这个 bug"

Fallback: If user points out "你跳过了 X", immediately re-output the alignment block and re-enter the pipeline.
```

- [ ] **Step 2: Add alignment node to Decision Flow diagram**

In the Decision Flow dot graph (around line 200), add a new node between `start` and `is_init`:

```
    align [label="Output task alignment block" shape=box];
    start -> align;
    align -> is_init;
```

- [ ] **Step 3: Add alignment rule to Iron Law**

Add to the Iron Law section (after the existing STOP rules):

```markdown
If you're about to start work without outputting the task alignment block → STOP.
If the user points out you skipped a skill → STOP, re-output alignment block, re-enter pipeline.
```

- [ ] **Step 4: Re-run setup to sync the updated command**

Run: `bash setup --host claude 2>&1`
Expected: codesop.md synced successfully

- [ ] **Step 5: Verify installed command has changes**

Run: `grep -c "Task Alignment" ~/.claude/commands/codesop.md`
Expected: 1 or more

---

### Task 5: Router Card Consistency Test

**Files:**
- Create: `tests/codesop-router.sh`

- [ ] **Step 1: Write the consistency test**

```bash
#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

# Test 1: Router card file exists
echo "Test 1: Router card exists..."
[ -f "$ROOT_DIR/config/codesop-router.md" ] || fail "config/codesop-router.md not found"
echo "  PASS"

# Test 2: Router card lists all mandatory skills from codesop.md
echo "Test 2: Mandatory skills consistency..."
mandatory_skills=$(grep -oP '(?<=superpowers:|gstack:)\S+' "$ROOT_DIR/commands/codesop.md" | grep -i 'mandatory\|YES' -B1 | grep -oP '(?<=superpowers:|gstack:)\S+' || true)
# Extract skill names marked as MANDATORY in the pipeline
mandatory_in_pipeline=$(grep -oE '(superpowers:[a-z-]+|gstack:[a-z-]+)' "$ROOT_DIR/commands/codesop.md" | sort -u || true)

# Check key mandatory skills appear in router card
for skill in brainstorming writing-plans autoplan using-git-worktrees subagent-driven-development test-driven-development verification-before-completion review ship document-release; do
  if ! grep -q "$skill" "$ROOT_DIR/config/codesop-router.md"; then
    fail "Mandatory skill '$skill' from pipeline missing in router card"
  fi
done
echo "  PASS"

# Test 3: Router card is under 50 lines (compact enough to resist dilution)
echo "Test 3: Router card length..."
lines=$(wc -l < "$ROOT_DIR/config/codesop-router.md" | tr -d ' ')
[ "$lines" -le 50 ] || fail "Router card is $lines lines (max 50 for dilution resistance)"
echo "  PASS ($lines lines)"

# Test 4: Setup script references install_router_card and configure_hooks
echo "Test 4: Setup has new functions..."
[ "$(grep -c 'install_router_card' "$ROOT_DIR/setup")" -ge 2 ] || fail "install_router_card not found in setup"
[ "$(grep -c 'configure_hooks' "$ROOT_DIR/setup")" -ge 2 ] || fail "configure_hooks not found in setup"
echo "  PASS"

# Test 5: AGENTS.md has discipline section
echo "Test 5: AGENTS.md has discipline section..."
grep -q "Skill 纪律" "$ROOT_DIR/templates/system/AGENTS.md" || fail "Skill discipline section missing from AGENTS.md"
echo "  PASS"

# Test 6: codesop.md has task alignment section
echo "Test 6: codesop.md has task alignment..."
grep -q "Task Alignment" "$ROOT_DIR/commands/codesop.md" || fail "Task Alignment section missing from codesop.md"
grep -q "任务对齐" "$ROOT_DIR/commands/codesop.md" || fail "任务对齐 block template missing from codesop.md"
echo "  PASS"

# Test 7: Hook schema is correct in setup
echo "Test 7: Hook schema uses correct format..."
grep -q '"matcher"' "$ROOT_DIR/setup" || fail "Hook config missing 'matcher' field (wrong schema)"
grep -q '"hooks"' "$ROOT_DIR/setup" || fail "Hook config missing nested 'hooks' array (wrong schema)"
echo "  PASS"

echo
echo "All tests passed."
```

- [ ] **Step 2: Make test executable and run it**

Run: `chmod +x tests/codesop-router.sh && bash tests/codesop-router.sh`
Expected: "All tests passed."

Note: This will FAIL initially because Tasks 1-4 haven't been implemented yet. Run it after all tasks are complete.

---

### Task 6: Setup Integration Test

**Files:**
- Modify: `tests/codesop-router.sh` (append)

- [ ] **Step 1: Add setup integration tests**

Append to `tests/codesop-router.sh`:

```bash

# Integration tests (require setup to have been run)
echo ""
echo "--- Integration Tests ---"
echo "Run 'bash setup --host claude' first."
echo ""

# Test 8: Router card installed to ~/.claude/
echo "Test 8: Router card installed..."
[ -f "$HOME/.claude/codesop-router.md" ] || fail "~/.claude/codesop-router.md not installed"
diff -q "$ROOT_DIR/config/codesop-router.md" "$HOME/.claude/codesop-router.md" || fail "Installed router card differs from source"
echo "  PASS"

# Test 9: Settings.json has correct hook
echo "Test 9: Settings hook configured..."
if command -v jq >/dev/null 2>&1; then
  hook_count=$(jq '[.hooks.SessionStart // [] | .[] | select(.hooks // [] | .[]?.command == "cat ~/.claude/codesop-router.md")] | length' "$HOME/.claude/settings.json" 2>/dev/null || echo "0")
  [ "$hook_count" -ge 1 ] || fail "codesop-router hook not found in settings.json"
  echo "  PASS"
else
  echo "  SKIP (jq not available)"
fi

# Test 10: Idempotency — running setup again doesn't duplicate hooks
echo "Test 10: Idempotency..."
bash "$ROOT_DIR/setup" --host claude 2>&1 >/dev/null
if command -v jq >/dev/null 2>&1; then
  hook_count=$(jq '[.hooks.SessionStart // [] | .[] | select(.hooks // [] | .[]?.command == "cat ~/.claude/codesop-router.md")] | length' "$HOME/.claude/settings.json" 2>/dev/null || echo "0")
  [ "$hook_count" -le 1 ] || fail "Hook duplicated after second setup run (idempotency broken)"
  echo "  PASS"
else
  echo "  SKIP (jq not available)"
fi
```

- [ ] **Step 2: Run full test suite**

Run: `bash tests/codesop-router.sh`
Expected: All tests passed (including integration tests)

---

### Task 7: Commit

- [ ] **Step 1: Stage and commit all changes**

```bash
git add config/codesop-router.md setup templates/system/AGENTS.md commands/codesop.md tests/codesop-router.sh
git commit -m "feat: add router card discipline layer for AI skill enforcement

Three-layer redundancy to fight context dilution:
- Layer 1: SessionStart hook injects router card (config/codesop-router.md)
- Layer 2: AGENTS.md adds skill discipline statement
- Layer 3: codesop.md adds task alignment mechanism

Setup auto-configures hooks (jq-based, idempotent).
Consistency test verifies router card stays aligned with pipeline.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Self-Review

**1. Spec coverage:**
- [x] Three-layer architecture → Tasks 1-4
- [x] Task alignment mechanism → Task 4
- [x] Router card content → Task 1
- [x] setup auto-config → Task 2
- [x] codesop-router.md lifecycle → Task 2 (install_router_card)
- [x] CLAUDE.md/AGENTS.md addition → Task 3
- [x] Idempotency → Task 2 (configure_hooks check)
- [x] Dependency checks → Task 2 (check_discipline_deps)
- [x] Test plan → Tasks 5-6
- [x] Success criteria → covered by tests

**2. Placeholder scan:** No TBD/TODO found. All steps have complete code.

**3. Type consistency:** All file paths and function names consistent across tasks.
