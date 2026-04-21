# Sub-agent Execution Architecture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement sub-agent dispatch for A-class skills, session state persistence, and compact reminder to solve context bloat in long pipeline sessions.

**Architecture:** Three-layer injection (AGENTS.md principles → router classification → SKILL.md execution). A-class skills dispatched as sub-agents via Agent tool. Session state written to 5-line markdown file. Compact detection via statusLine tee to temp file.

**Tech Stack:** Bash (setup script), jq (settings.json manipulation), Markdown (SKILL.md, router card, AGENTS.md template)

---

## File Structure

| File | Action | Responsibility |
|------|--------|---------------|
| `config/codesop-router.md` | Modify | Add "执行方式" column to skill table, add iron law |
| `SKILL.md` | Modify | Add sub-agent dispatch logic, session-state read/write, retry strategy |
| `templates/system/AGENTS.md` | Modify | Add high-level sub-agent principles, session-state rule |
| `setup` | Modify | Add statusLine tee to `configure_hooks()` |
| `.gitignore` | Modify | Add `.codesop/session-state.md` |
| `tests/detect-environment.sh` | Modify | Add assertions for new features |
| `VERSION` | Modify | Bump to 3.0.0 |
| `skill.json` | Modify | Bump version to 3.0.0 |

---

### Task 1: Router card — add 执行方式 column and iron law

**Files:**
- Modify: `config/codesop-router.md:8-51` (skill table)
- Modify: `config/codesop-router.md:66-70` (铁律 section)

- [ ] **Step 1: Add 执行方式 column to skill table header**

Change line 8 from:
```
| 大类 | 优选 | 来源 | Skill | 什么时候用 |
|------|------|------|-------|-----------|
```
to:
```
| 大类 | 优选 | 来源 | Skill | 执行方式 | 什么时候用 |
|------|------|------|-------|----------|-----------|
```

- [ ] **Step 2: Add 执行方式 value to each skill row**

Add a column to every skill row. Values based on spec §3 classification:

| Skill | Value |
|-------|-------|
| superpowers:brainstorming | C |
| codex:rescue (§1, §6, §13) | A |
| frontend-design:frontend-design | C |
| superpowers:writing-plans | A |
| superpowers:using-git-worktrees | C |
| superpowers:subagent-driven-development | B |
| code-simplifier:code-simplifier | A |
| superpowers:dispatching-parallel-agents | B |
| superpowers:requesting-code-review | B |
| superpowers:verification-before-completion | A |
| claude-md-management:claude-md-improver (§4, §9) | A |
| superpowers:test-driven-development | A |
| superpowers:finishing-a-development-branch | A |
| code-review:code-review | A |
| superpowers:receiving-code-review | A |
| playwright | A |
| chrome-devtools-mcp | A |
| browser-use | A |
| superpowers:systematic-debugging | C |
| context7 | A |
| skill-creator:skill-creator | A |
| superpowers:writing-skills | A |
| codesop | C |
| claude-to-im | C |
| codex:review | A |
| codex:adversarial-review | A |

Example row change (brainstorming):
```
| | ★ | sp | superpowers:brainstorming | C | 任何新功能/改动前：...
```
Empty category header rows remain unchanged.

- [ ] **Step 3: Add iron law for sub-agent dispatch**

After the existing last iron law (line 70: "任务完成后及时标记..."), add:
```
- A 类 skill 必须派子 agent，完成后更新 `.codesop/session-state.md`
```

- [ ] **Step 4: Run router test to verify structure is valid**

Run: `bash tests/codesop-router.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add config/codesop-router.md
git commit -m "feat(router): add 执行方式 column for sub-agent classification (P1)"
```

---

### Task 2: SKILL.md — add sub-agent dispatch logic

**Files:**
- Modify: `SKILL.md:95-123` (step 10.5 and pipeline re-entry)
- Modify: `SKILL.md:260-282` (completion gate §5)

- [ ] **Step 1: Add session-state.md read to step 3**

In section "3. Default Behavior", after step 2 (Read PRD.md), add a new step:

```markdown
3. **Read session state** if `.codesop/session-state.md` exists. Use Last/Next/Note fields to orient routing decisions. If the file doesn't exist, proceed normally.
```

Renumber subsequent steps (current 3→4, 4→5, etc.)

- [ ] **Step 2: Add sub-agent dispatch logic to Pipeline Re-entry**

After the existing Pipeline Re-entry block (lines 117-123), add sub-agent dispatch logic:

```markdown
**Sub-agent Dispatch**: When executing a pipeline task with a skill:
1. Check the routing table's "执行方式" column for the skill
2. If **A-class**: dispatch via Agent tool with the prompt template below
3. If **B/C-class**: execute in main session via Skill tool directly
4. After sub-agent returns: update session-state.md, then proceed to re-entry step 1

**Sub-agent Prompt Template**:
```
项目根目录: {project_root}
分支: {branch}
任务: {task_subject}
请先读取 CLAUDE.md 了解项目规范，然后通过 Skill tool 调用 {skill_name}。
执行完成后，简要报告结果（成功/失败 + 关键发现）。
```

**Retry Template** (for fixable error retry):
```
项目根目录: {project_root}
分支: {branch}
任务: {task_subject}
上次执行失败: {error_summary}
请先读取 CLAUDE.md 了解项目规范，然后通过 Skill tool 调用 {skill_name}。
注意上述失败信息，避免重复相同错误。执行完成后，简要报告结果。
```

**Failure Strategy**:
| Failure type | Response |
|---|---|
| Fixable error | Update session-state.md Note, dispatch retry sub-agent with Retry Template |
| Wrong direction | Dispatch new sub-agent with different approach |
| Repeated failure (≥2 retries) | Report to user, ask for guidance |
| Dirty worktree (sub-agent modified files) | `git status` check before retry; report to user if unexpected changes |
| Sub-agent timeout | Treat as "wrong direction" |
| Branch changed between retry | Verify current branch matches session-state.md Branch field |
```

- [ ] **Step 3: Add session-state update to completion gate §5**

In section "5. Completion Gate", add a new step between current steps 2 and 3:

```markdown
3. update `.codesop/session-state.md` (5-line overwrite):
```markdown
# Session State
Last: {current task + result}
Next: {next step or "无"}
Branch: {current branch}
Note: {exceptions, if any, or "无"}
```
```

Renumber subsequent step.

- [ ] **Step 4: Run detect-environment test**

Run: `bash tests/detect-environment.sh`
Expected: PASS (existing assertions should still pass since we only added content, didn't remove)

- [ ] **Step 5: Commit**

```bash
git add SKILL.md
git commit -m "feat(skill): add sub-agent dispatch logic, session-state, retry strategy (P2)"
```

---

### Task 3: AGENTS.md template — add sub-agent principles

**Files:**
- Modify: `templates/system/AGENTS.md:34-42` (Skill 纪律 section)

- [ ] **Step 1: Add sub-agent and session-state rules to Skill 纪律**

After the existing iron law "pipeline task 指定了 skill 时..." (line 41), add:

```markdown
- A 类 skill（纯过程型）默认通过 Agent tool 派子 agent 执行，B/C 类在主 session 执行（具体分类见路由表"执行方式"列）
- 完成主要任务后更新 `.codesop/session-state.md`（5 行覆盖模式：Last/Next/Branch/Note）
```

- [ ] **Step 2: Add compact reminder rule**

After the new rules, add:

```markdown
- 读取 `/tmp/claude-context.json` 的 `used_percentage`，超过 80% 且任务未完成时，提醒用户 `/compact`
```

- [ ] **Step 3: Run setup to verify template is valid**

Run: `bash setup --host claude`
Expected: setup completes without errors, AGENTS.md template synced

- [ ] **Step 4: Commit**

```bash
git add templates/system/AGENTS.md
git commit -m "feat(agents): add sub-agent dispatch principles and compact reminder (P3)"
```

---

### Task 4: Setup script — add statusLine tee

**Files:**
- Modify: `setup:151-192` (configure_hooks function)

- [ ] **Step 1: Add statusLine configuration to configure_hooks**

After the existing hook configuration block (after line 191 `fi`), add a new block to configure statusLine:

```bash
  # Configure statusLine for compact detection
  # Check if statusLine already has the tee command
  local statusline_existing
  statusline_existing=$(jq -r '.statusLine.command // ""' "$settings" 2>/dev/null || echo "")
  if [[ "$statusline_existing" == *"tee /tmp/claude-context.json"* ]]; then
    echo "  ✓ statusLine already configured for context tracking"
  else
    if jq '. + {"statusLine":{"type":"command","command":"cat | tee /tmp/claude-context.json | jq -r '\"'\"'\\(.model.display_name) 已用 \\(.context_window.used_percentage // 0)%'\"'\"'"}}' \
      "$settings" > "$settings.tmp"; then
      mv "$settings.tmp" "$settings"
      echo "  ✓ statusLine configured for context tracking"
    else
      rm -f "$settings.tmp"
      echo "  ⚠ Failed to configure statusLine"
    fi
  fi
```

Note: the jq quoting is tricky. The command value should be:
```
cat | tee /tmp/claude-context.json | jq -r '"\(.model.display_name) 已用 \(.context_window.used_percentage // 0)%"'
```

- [ ] **Step 2: Test setup runs without errors**

Run: `bash setup --host claude`
Expected: "✓ statusLine configured for context tracking" or "already configured" message

- [ ] **Step 3: Verify settings.json has the statusLine field**

Run: `jq '.statusLine' ~/.claude/settings.json`
Expected: JSON object with `type` and `command` fields

- [ ] **Step 4: Commit**

```bash
git add setup
git commit -m "feat(setup): add statusLine tee for compact detection (P4)"
```

---

### Task 5: .gitignore — add session-state.md

**Files:**
- Modify: `.gitignore`

- [ ] **Step 1: Add session-state.md to .gitignore**

Append to `.gitignore`:
```
# Session state (local, never committed)
.codesop/session-state.md
```

- [ ] **Step 2: Verify .codesop/session-state.md is ignored**

Run: `git status .codesop/session-state.md`
Expected: file not listed (or "nothing to commit" if no other changes)

- [ ] **Step 3: Commit**

```bash
git add .gitignore
git commit -m "chore: gitignore session-state.md (P5)"
```

---

### Task 6: Tests — add assertions for new features

**Files:**
- Modify: `tests/detect-environment.sh:30-67` (SKILL.md assertions)

- [ ] **Step 1: Add assertion for sub-agent dispatch in SKILL.md**

After the existing assertion for "前置 superpowers:finishing-a-development-branch" (line 54), add:

```bash
assert_contains "$skill_full" "Sub-agent Dispatch"
assert_contains "$skill_full" "执行方式"
assert_contains "$skill_full" "session-state.md"
assert_contains "$skill_full" "Retry Template"
```

- [ ] **Step 2: Add assertion for router card 执行方式 column**

After the existing router card tests (if any in `tests/codesop-router.sh`), or add a new block at the end of `detect-environment.sh`:

```bash
# Verify router card has 执行方式 column
router_output="$(cat "$ROOT_DIR/config/codesop-router.md")"
assert_contains "$router_output" "| 大类 | 优选 | 来源 | Skill | 执行方式 |"
assert_contains "$router_output" "A 类 skill 必须派子 agent"
```

- [ ] **Step 3: Run all tests**

Run: `bash tests/detect-environment.sh && bash tests/codesop-router.sh`
Expected: both PASS

- [ ] **Step 4: Commit**

```bash
git add tests/detect-environment.sh
git commit -m "test: add assertions for sub-agent dispatch and 执行方式 column (P6)"
```

---

### Task 7: Version bump and sync

**Files:**
- Modify: `VERSION`
- Modify: `skill.json`

- [ ] **Step 1: Update VERSION to 3.0.0**

Write `3.0.0` to `VERSION`.

- [ ] **Step 2: Update skill.json version to 3.0.0**

Change line 4 from `"version": "2.6.1"` to `"version": "3.0.0"`.

- [ ] **Step 3: Run version consistency test**

Run: `bash tests/detect-environment.sh`
Expected: PASS (version assertions should pass)

- [ ] **Step 4: Sync to host**

Run: `bash setup --host claude`
Expected: all files synced

- [ ] **Step 5: Commit**

```bash
git add VERSION skill.json
git commit -m "chore: bump version to 3.0.0"
```

---

## Spec Coverage Check

| Spec Section | Plan Task |
|---|---|
| §3 A/B/C Classification | Task 1 (router column) |
| §4 Prompt Template | Task 2 (SKILL.md dispatch logic) |
| §4 Retry Template | Task 2 (SKILL.md retry) |
| §4 Failure Strategy | Task 2 (SKILL.md failure table) |
| §5 Session State File | Task 2 (completion gate), Task 5 (gitignore) |
| §6 Compact Reminder | Task 3 (AGENTS.md), Task 4 (setup statusLine) |
| §7 Three-Layer Injection | Task 1 (router), Task 2 (SKILL.md), Task 3 (AGENTS.md) |
| §8 P1-P6 | Tasks 1-6 map 1:1 |
