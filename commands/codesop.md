---
name: codesop
description: "Use when the user seems lost, asks what to do next, asks what skill to use, wants to continue an existing project, wants a status/progress summary, wants help choosing a workflow before implementation, or explicitly mentions codesop or /codesop for project orientation. Do not trigger this skill when the user is explicitly invoking a mechanical subcommand like `/codesop init`, `/codesop status`, `/codesop setup`, `/codesop update`, or `/codesop version`. This skill is the project workbench and workflow router: it restores context from AGENTS.md and PRD.md, summarizes current state, recommends the next skill, and explains what not to do yet."
---

# codesop: Project Workbench and Workflow Router

Announce: "Using codesop to restore project context and route the next workflow."

## 1. System Position

`codesop` is a skill-first operating system for AI-assisted coding work.

The skill is the orchestrator. The CLI is infrastructure.

Use this skill to:

- restore project orientation
- summarize current state
- recommend the next workflow
- route into specialized downstream skills

Do not use this skill as a replacement for specialist execution skills.

## 1.1 CLI Command Bypass

If the user is explicitly asking to run a mechanical `codesop` subcommand, do not switch into workbench-summary mode.

Treat these as command execution requests first:

- `/codesop init`
- `/codesop status`
- `/codesop setup`
- `/codesop update`
- `/codesop version`

For these requests:

- run the command
- summarize the command output faithfully
- keep interpretation minimal and local to the command result
- do not output `## 工作台摘要`
- do not output `## Skill 建议`
- do not recommend downstream workflow skills unless the user separately asks what to do next

## 2. Read Order

Read project context in this order:

1. `AGENTS.md` — **required** (defines boundaries, rules, verification, and delivery format)
2. `PRD.md` — **required** (defines long-term goal, current progress, recent decisions, blockers, and next step)
3. `README.md` — **optional** (only for install/run/API/env/operator-facing questions)

If `AGENTS.md` or `PRD.md` is missing, say so explicitly and continue with the best available context.

The `/codesop` CLI is an optional but preferred mechanical context source.

Call `/codesop` when you need fresh project-state facts from the repo.

Do not call `/codesop` for abstract workflow questions that do not depend on repo state.

Use `PRD.md` for long-term orientation and `/codesop` for fresh mechanical facts.

## 3. Default Behavior

When this skill triggers:

1. Read `AGENTS.md`
2. Read `PRD.md`
3. Decide whether fresh repo facts are needed and call `/codesop` if they are
4. Decide whether `README.md` is needed
5. Produce a workbench summary
6. Recommend the most relevant next skill or action

Default to orientation and routing first. Do not jump into implementation unless the user clearly asks to proceed.

When `/codesop` is used, treat it as a diagnosis/context layer:

- use `/codesop` for stage guess, health status, config facts, and recommendation context
- use `PRD.md` for long-term goal, current narrative, recent decisions, and next-step intent
- explain any mismatch between `PRD.md` and fresh CLI facts

## 4. Default Output

Always prefer this shape when the user needs orientation:

```md
## 工作台摘要

**长期目标**: ...
**当前阶段**: ...
**当前进度**: ...
**阻塞/风险**: ...
**最近决策**: ...
**下一步**: ...

## Skill 建议
- 推荐: ...
  - 原因: ...
- 备选: ...
  - 原因: ...
- 暂不建议: ...
  - 原因: ...
```

If the user only wants a quick answer, compress it, but keep the same mental model.

## 5. Trigger Guidance

Use this skill aggressively, not conservatively.

Trigger when the user:

- asks what to do next
- asks what skill to use
- says "continue"
- returns to an existing project after a gap
- wants a status or progress summary
- looks confused or unstructured
- wants to resume work
- wants help deciding whether to plan, debug, implement, review, or ship

Also trigger when the user explicitly mentions:

- `codesop`
- `/codesop`
- workflow
- project status
- next step
- progress summary

Do not use explicit `codesop` mention alone as a trigger if the message is clearly just a CLI subcommand execution request.

## 6. Workflow Mapping

Use the workbench summary to choose the downstream skill.

### 6.1 New Feature / "I want to build X"

```
gstack:office-hours              ← Needs validation + design doc
  ↓
superpowers:brainstorming        ← Implementation design (MANDATORY)
  ↓
superpowers:writing-plans        ← Implementation plan (MANDATORY)
  ↓
gstack:autoplan                  ← CEO + Design + Eng auto review (MANDATORY)
  ↓
superpowers:using-git-worktrees  ← Isolated workspace (MANDATORY)
  ↓
superpowers:subagent-driven-development ← Implement with TDD + per-task review (MANDATORY)
  ↓
gstack:codex                     ← Adversarial review (optional)
  ↓
gstack:qa                        ← Browser testing (MANDATORY for web)
  ↓
gstack:review                    ← PR diff review (MANDATORY)
  ↓
gstack:ship                      ← Create PR (MANDATORY)
  ↓
gstack:land-and-deploy           ← Merge + production verify
  ↓
gstack:canary                    ← Post-deploy monitoring (MANDATORY after deploy)
  ↓
gstack:document-release          ← Doc sync (MANDATORY)
```

### 6.2 Bug Fix / "XX is broken"

```
gstack:investigate               ← 4-phase root cause investigation
  ↓
gstack:freeze                    ← Restrict edit scope
  ↓
superpowers:systematic-debugging ← Root cause → hypothesis → verify → fix (MANDATORY)
  ↓
superpowers:test-driven-development ← Write failing test first (MANDATORY)
  ↓
superpowers:verification-before-completion ← Verification evidence (MANDATORY)
  ↓
gstack:unfreeze                  ← Remove edit restriction
  ↓
gstack:review                    ← PR review (if needed)
  ↓
gstack:ship                      ← Release (if needed)
```

### 6.3 Small Change / "Tweak XX"

```
superpowers:test-driven-development ← Write test, then change code (MANDATORY)
  ↓
superpowers:verification-before-completion ← Verification evidence (MANDATORY)
  ↓
gstack:review                    ← PR review (if multi-file)
  ↓
gstack:ship                      ← Release (if needed)
```

### 6.4 Refactoring / "Clean up XX"

```
superpowers:brainstorming        ← Design refactoring approach (MANDATORY)
  ↓
superpowers:writing-plans        ← Step-by-step plan (MANDATORY)
  ↓
superpowers:using-git-worktrees  ← Isolated workspace (MANDATORY)
  ↓
superpowers:subagent-driven-development ← Implement (TDD preserves behavior)
  ↓
superpowers:verification-before-completion ← All tests pass (MANDATORY)
  ↓
gstack:review                    ← PR review (MANDATORY)
  ↓
gstack:ship                      ← Release
```

### 6.5 Code Review Feedback

```
superpowers:receiving-code-review ← Evaluate feedback: verify > blind agree (MANDATORY)
  ↓
(if fix needed) superpowers:test-driven-development → modify → verification
  ↓
Reply in thread
```

### 6.6 Production Incident / "Production is down"

```
gstack:careful                   ← Safety mode
  ↓
gstack:investigate               ← Locate problem
  ↓
superpowers:systematic-debugging ← Root cause analysis (MANDATORY)
  ↓
Fix → gstack:canary              ← Post-fix monitoring
```

### 6.7 Security Audit / "Check security"

```
gstack:cso                       ← OWASP + STRIDE + attack surface
  ↓
(if issues found) superpowers:systematic-debugging → superpowers:test-driven-development fix → gstack:review
```

### 6.8 Performance / "Too slow"

```
gstack:benchmark                 ← Baseline test
  ↓
Locate bottleneck → optimize → gstack:benchmark verify
```

### 6.9 Design System / "Need DESIGN.md"

```
gstack:office-hours              ← Product context
  ↓
gstack:design-consultation       ← Create DESIGN.md + preview
  ↓
gstack:design-review             ← Visual audit (if existing site)
```

### 6.10 Visual Review / "UI looks wrong"

```
gstack:design-review             ← 80-dimension audit + fix + screenshots
```

### 6.11 Weekly Retro / "What did I ship"

```
gstack:retro                     ← Analyze commit history + work patterns
```

## 7. Routing Policy

Use these routing defaults:

- unclear feature request → `gstack:office-hours`
- approved design needing implementation plan → `superpowers:writing-plans`
- active implementation with existing plan → `superpowers:subagent-driven-development`
- bug / broken behavior → `gstack:investigate` or `superpowers:systematic-debugging`
- ready for release/review → `gstack:review`, `gstack:ship`

When recommending, always include:

- the best next skill
- one backup option
- one thing not to do yet

## 8. Sub-commands

### 8.1 /codesop init [path]

Initialize project scaffolding and environment guidance.

This is a mechanical command, not a workbench-summary command.

Run:

```bash
bash ~/codesop/codesop init <target-dir>
```

Expected command responsibilities:

- `AGENTS.md` — 填充技术栈、命令、架构规则
- `CLAUDE.md` — 轻量包装：`@AGENTS.md`
- `PRD.md` — 活文档：同时记录产品规范、当前进度、最近决策、风险与工作日志

条件生成（不存在时）：

- `README.md` — 填充安装/运行/测试命令

`AGENTS.md` 已存在 → 保留，输出 diff 建议。

全部默认中文。根据检测到的技术栈推断 test/lint/typecheck/smoke 命令。

When reporting back after `init`:

- keep the response centered on the command output
- say which files were generated or preserved
- say whether ecosystem dependencies are installed, partially installed, or missing
- do not add a separate project scorecard
- do not add workbench routing unless the user explicitly asks for next-step advice

### 8.2 /codesop status

Show skill and project health facts without recommendations.

1. Scan superpowers + gstack skill directories
2. Check versions
3. Read usage stats if available
4. Output dashboard + facts only

### 8.3 /codesop update

Check and apply updates.

1. Check gstack version → show diff
2. Check superpowers version → show diff
3. Check this file's version number
4. Ask user if they want to update

## 9. Conflict Resolution

| Conflict | Rule |
|----------|------|
| `superpowers:brainstorming` vs `gstack:office-hours` | New feature direction unclear → office-hours; technical design → brainstorming |
| `superpowers:requesting-code-review` vs `gstack:review` | Task-level quality check → requesting-code-review; PR-level structural risk → review |
| `superpowers:systematic-debugging` vs `gstack:investigate` | Single file / known scope → systematic-debugging; system-level / unknown scope → investigate |
| `superpowers:subagent-driven-development` vs `superpowers:executing-plans` | Independent tasks → subagent-driven (preferred); serial / no subagent support → executing-plans |
| User says "just fix it" vs skill workflow | User instruction wins, but still obey verification and delivery rules from `AGENTS.md` |

## 10. Red Flags

These thoughts mean STOP—you're rationalizing:

| Thought | Reality |
|---------|---------|
| "This is a simple feature, no need for brainstorming" | `superpowers:brainstorming` is **mandatory** before any creative work. |
| "I'll just write the code directly" | `superpowers:test-driven-development` is **mandatory** during implementation. |
| "Tests pass, we're done" | `superpowers:verification-before-completion` requires **fresh evidence**, not memory. |
| "The code looks fine, let's merge" | `gstack:review` is **mandatory** before merge. |
| "I don't need QA for this" | Web apps **must** go through `gstack:qa`. |
| "Docs can wait" | `gstack:document-release` is **mandatory** after ship. |
| "This doesn't need a formal plan" | `superpowers:writing-plans` + `gstack:autoplan` are **mandatory** for multi-step work. |
| "I remember what the skill says" | Skills evolve. Invoke the current version. |
| "Let me just try this fix" | No root cause = no fix. Use `superpowers:systematic-debugging`. |
| "The user just wants me to code" | Discipline exists to protect the user. Use the pipeline. |

## 11. Fallback

When no scenario matches:

1. Produce the workbench summary anyway
2. Scan all skill descriptions if available
3. Rank the top 3 workflow options
4. Recommend the least-risk next step
5. If still unclear, ask one focused question

## 12. Iron Laws

| Iron Law | Source Skill |
|----------|--------------|
| No code without design approval | `superpowers:brainstorming` / `gstack:office-hours` |
| No production code without failing test first | `superpowers:test-driven-development` |
| No fix without root cause investigation | `superpowers:systematic-debugging` / `gstack:investigate` |
| No completion claim without verification evidence | `superpowers:verification-before-completion` |
| Load skill if 1% chance it applies | `superpowers:using-superpowers` |
| User instruction > project rules > default behavior | Instruction priority |
