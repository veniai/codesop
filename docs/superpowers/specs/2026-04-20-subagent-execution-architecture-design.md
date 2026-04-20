# Design: Sub-agent Execution Architecture (v3.0)

**Date**: 2026-04-20
**Status**: Draft
**Version**: v3.0.0
**Affects**: SKILL.md, config/codesop-router.md, templates/system/AGENTS.md, settings.json

---

## 1. Problem

AI assistant in a single Claude Code session suffers from context bloat:
- After ~80k tokens, auto-compact compresses conversation history
- Post-compact, the model loses specific details (file paths, decisions, error outputs)
- Long pipeline execution (7-9 steps) or repeated daily skill usage fills context quickly
- After compact, the AI may repeat already-completed work or skip critical steps

## 2. Solution Overview

Three-pronged approach:

1. **Sub-agent dispatch** (primary) — Keep main session lightweight by dispatching autonomous skills as sub-agents via Agent tool
2. **File system persistence** (backup) — Write session state to `.codesop/session-state.md` for recovery after compact or session disconnect
3. **Compact reminder** (auxiliary) — Proactively remind user to compact when context usage is high and work is incomplete

## 3. Skill Execution Classification

All skills listed in the routing table (config/codesop-router.md) are classified into three execution modes. Skills not in the routing table — including deprecated aliases, internal plugin helpers, and Claude Code built-in skills — are out of scope for this classification.

### A: Sub-agent (default for autonomous skills)

Dispatched via Agent tool with self-contained prompt. Sub-agent has independent context, fast in/fast out.

| Skill | Why sub-agent |
|---|---|
| superpowers:verification-before-completion | Runs commands, checks output |
| code-simplifier:code-simplifier | Reviews and modifies code |
| claude-md-management:claude-md-improver | Audits documentation |
| superpowers:finishing-a-development-branch | Creates PR |
| codex:rescue | Dispatches to Codex CLI |
| superpowers:writing-plans | Writes plan file (note: internally dispatches plan reviewer sub-agent — 1 level nesting, acceptable) |
| superpowers:receiving-code-review | Processes review feedback |
| superpowers:test-driven-development | TDD cycle |
| superpowers:writing-skills | Creates/edits skills |
| code-review:code-review | PR review with 5 parallel agents |
| skill-creator:skill-creator | Skill lifecycle management |
| codex:review | Diff review via Codex |
| codex:adversarial-review | Challenge design assumptions |
| context7 | Documentation lookup |
| playwright | Browser automation |
| chrome-devtools-mcp | Browser diagnostics |
| browser-use | Browser operations |

### B: Main session (internally dispatches sub-agents)

Stays in main session because the skill itself already uses Agent tool internally. Wrapping in another sub-agent would create multi-level nesting.

| Skill | Internal sub-agent usage |
|---|---|
| superpowers:subagent-driven-development | 3 sub-agents per task (implementer + spec-reviewer + code-quality-reviewer) |
| superpowers:dispatching-parallel-agents | Parallel Task() calls |
| superpowers:requesting-code-review | Dispatches code-reviewer agent |

### C: Main session (interactive)

Requires user back-and-forth conversation. Cannot be delegated to sub-agent.

| Skill | Why main session |
|---|---|
| superpowers:brainstorming | One question at a time with user |
| superpowers:systematic-debugging | Hypothesis-driven, may need user input |
| superpowers:using-git-worktrees | Main session needs worktree path for subsequent steps |
| frontend-design:frontend-design | Design iteration with user feedback |
| claude-to-im | Interactive messaging bridge |
| codesop | Workbench router, owns pipeline orchestration |

### Rules

- A-class skills are ALWAYS dispatched as sub-agents, whether triggered by pipeline or daily usage
- B/C-class skills execute in main session
- Classification is defined in the routing table's skill list (new column: "执行方式")
- Applies universally — not just for /codesop pipeline execution

## 4. Sub-agent Dispatch

### Prompt Template

Main session dispatches A-class skills via Agent tool:

```
项目根目录: {project_root}
分支: {branch}
任务: {task_subject}
请先读取 CLAUDE.md 了解项目规范，然后通过 Skill tool 调用 {skill_name}。
执行完成后，简要报告结果（成功/失败 + 关键发现）。
```

**Retry template** (for fixable error retry):
```
项目根目录: {project_root}
分支: {branch}
任务: {task_subject}
上次执行失败: {error_summary}
请先读取 CLAUDE.md 了解项目规范，然后通过 Skill tool 调用 {skill_name}。
注意上述失败信息，避免重复相同错误。执行完成后，简要报告结果。
```

### Result Handling

Sub-agent returns a summary. Main session:
1. Reads the result
2. Updates session-state.md (Last + Note fields)
3. Updates TaskList if running a pipeline (TaskUpdate completed)
4. Proceeds to next step

### Failure Strategy

| Failure type | Response | Why |
|---|---|---|
| Fixable error (e.g., test failure) | Update session-state.md Note with error details, dispatch new sub-agent with error context in prompt | Preserves error context without main session bloat |
| Wrong direction | Dispatch new sub-agent with different approach | Avoid anchoring on failed path |
| Repeated failure (≥2 retries) | Report to user, ask for guidance | Don't burn tokens on infinite retries |
| Sub-agent modified files but returned incomplete summary | Check `git status` before retry; if unexpected changes exist, report to user with diff | Avoid stacking modifications on dirty state |
| Sub-agent timeout | Treat as "wrong direction" — dispatch new sub-agent | Timeout = stuck, don't retry identical approach |
| Branch/worktree changed between retry | Verify current branch matches expected before dispatching retry; if mismatched, report to user | Prevent operating on wrong branch |

## 5. Session State File

### Location

`.codesop/session-state.md` in project root.

### Format

5 lines, overwrite mode (never append, never grow):

```markdown
# Session State
Last: {last completed task + result}
Next: {what to do next}
Branch: {current git branch}
Note: {exceptions: failure details, key decisions, context to remember}
```

### Write Triggers

- After each pipeline step completes
- After each A-class skill sub-agent returns
- Before dispatching a retry (write failure details to Note)
- After each major task completes (daily usage)

### Read Triggers

- `/codesop` triggers (SKILL.md step 3, after reading AGENTS.md/PRD.md)
- Before sub-agent failure retry
- When main session is uncertain about context

### Guarantees

- File is always exactly 5 lines
- Each write overwrites the entire file (no append)
- File does not accumulate history
- Note field is the only variable-length field; keep it concise (one line)

### .gitignore

`.codesop/session-state.md` should be gitignored — it's session-local, not project state.

## 6. Compact Reminder

### Detection

Modify `settings.json` statusLine command to write context usage to a readable file:

```json
"statusLine": {
    "type": "command",
    "command": "cat | tee /tmp/claude-context.json | jq -r '\"\\(.model.display_name) 已用 \\(.context_window.used_percentage // 0)%\"'"
}
```

AI reads `/tmp/claude-context.json` to get exact `used_percentage`.

### Trigger Conditions

Remind user to compact when BOTH conditions are met:
1. `used_percentage > 80%`
2. Current task is incomplete (pending pipeline steps or multi-step user request)

### Do NOT Trigger

- Casual conversation, simple Q&A
- All tasks completed
- User just compacted

### Reminder Format

> "Context 已用 {X}%，建议 /compact 释放空间后再继续。"

One line, no explanation. User decides.

## 7. Three-Layer Injection

### AGENTS.md (system template)

Only high-level principles. No schema definitions, no execution algorithms.
- "A 类 skill（纯过程型）默认通过 Agent tool 派子 agent 执行，B/C 类在主 session 执行"
- "完成主要任务后更新 `.codesop/session-state.md`（5 行覆盖模式）"

### Router Card (codesop-router.md)

Only classification data. No execution logic, no retry rules.
- Skill table: add "执行方式" column with A/B/C values
- 铁律: add "A 类 skill 必须派子 agent，完成后更新 session state 文件"

### SKILL.md

Only execution algorithms. No classification definitions (reads from router).
- Step 10.5 re-entry: read session-state.md before routing
- A-class pipeline steps: dispatch via Agent tool instead of direct Skill invocation
- Sub-agent failure retry strategy (including git status check before retry)
- Completion gate (§5): add "update session-state.md" as mandatory step

## 8. Implementation Phases

| Phase | Content | Deliverable |
|---|---|---|
| P1 | Router card: add 执行方式 column to skill table | codesop-router.md update |
| P2 | SKILL.md: sub-agent dispatch logic + failure strategy + session-state read/write | SKILL.md update |
| P3 | AGENTS.md: general rules for sub-agent + session state | templates/system/AGENTS.md update |
| P4 | Compact reminder: statusLine file output + trigger logic in AGENTS.md/SKILL.md | settings.json + instruction updates |
| P5 | .gitignore entry for .codesop/session-state.md | .gitignore update |
| P6 | Tests: verify routing table has 执行方式 column, verify SKILL.md references sub-agent dispatch | test updates |

## 9. What This Does NOT Change

- CLI layer (bash scripts) — untouched
- Routing table structure — only adds one column
- Metadata format (source: codesop-pipeline) — unchanged
- Pipeline TaskCreate spec — unchanged (subject format, blockedBy, etc.)
- Skill names — unchanged

## 10. Risks

| Risk | Mitigation |
|---|---|
| AI forgets to update session-state.md | Three-layer injection reinforces the behavior; completion gate mandates it |
| Sub-agent prompt lacks sufficient context | Template includes project root + branch + CLAUDE.md instruction; skills read project files |
| Multi-level nesting (B-class in sub-agent) | B-class skills stay in main session by design; A-class max nesting is 2 levels (only writing-plans, which dispatches a subordinate reviewer — all others are 1 level) |
| /tmp/claude-context.json not available on all platforms | Fallback: no compact reminder, sub-agent dispatch still works |
| Session state file conflicts in worktrees | Each worktree has its own .codesop/session-state.md (already isolated) |
