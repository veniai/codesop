---
name: codesop
description: "Use when the user seems lost, asks what to do next, asks what skill to use, wants to continue an existing project, wants a status/progress summary, wants help choosing a workflow before implementation, or explicitly mentions codesop or /codesop for project orientation. Do not trigger this skill when the user is explicitly invoking a mechanical subcommand like `/codesop init`, `/codesop setup`, or `/codesop update`. This skill is the project workbench and workflow router: it restores context from AGENTS.md and PRD.md, summarizes current state, recommends the next skill, and explains what not to do yet."
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
- `/codesop setup`
- `/codesop update`

For these requests:

- run the command
- summarize the command output faithfully
- keep interpretation minimal and local to the command result
- do not output `## 工作台摘要`
- do not output `## Skill 建议`
- do not recommend downstream workflow skills unless the user separately asks what to do next

## 2. Read Order

Read project context in this order:

1. `AGENTS.md`
2. `PRD.md`
3. `README.md` only if needed

Why:

- `AGENTS.md` defines boundaries, rules, verification, and delivery format
- `PRD.md` defines long-term goal, current progress, recent decisions, blockers, and next step
- `README.md` is only relevant when the user request touches install, run, API, env, or operator-facing usage

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
office-hours (gstack)          ← Needs validation + design doc
  ↓
writing-plans (superpowers)    ← Implementation plan
  ↓
autoplan (gstack)              ← CEO + Design + Eng auto review
  ↓
using-git-worktrees (sp)       ← Isolated workspace
  ↓
subagent-driven-dev (sp)       ← Implement (TDD + per-task review)
  or executing-plans (sp)      ← Alternative: parallel session mode
  or dispatching-parallel-agents (sp) ← Alternative: 2+ independent tasks in parallel
  ↓
finishing-a-development-branch (sp) ← Clean up branch before review
  ↓
codex (gstack)                 ← Adversarial review
  ↓
qa (gstack)                    ← Browser testing
  ↓
review (gstack)                ← PR diff review
  ↓
ship (gstack)                  ← Create PR
  ↓
setup-deploy (gstack)          ← Configure deployment (first time)
  ↓
land-and-deploy (gstack)       ← Merge + production verify
  ↓
document-release (gstack)      ← Doc sync
```

### 6.2 Bug Fix / "XX is broken"

```
investigate (gstack)           ← 4-phase root cause investigation
  ↓
freeze (gstack)                ← Restrict edit scope
  ↓
systematic-debugging (sp)      ← Root cause → hypothesis → verify → fix
  ↓
TDD (sp)                       ← Write failing test first
  ↓
verification-before-comp (sp)  ← Verification evidence
  ↓
unfreeze (gstack)              ← Remove edit restriction
  ↓
review (gstack)                ← PR review (if needed)
  ↓
ship (gstack)                  ← Release (if needed)
```

### 6.3 Small Change / "Tweak XX"

```
Direct change + TDD (sp)       ← Write test, then change code
  ↓
verification-before-comp (sp)  ← Verification evidence
  ↓
review (gstack)                ← PR review (if multi-file)
  ↓
ship (gstack)                  ← Release (if needed)
```

### 6.4 Refactoring / "Clean up XX"

```
brainstorming (sp)             ← Design refactoring approach
  ↓
writing-plans (sp)             ← Step-by-step plan
  ↓
using-git-worktrees (sp)       ← Isolated workspace
  ↓
subagent-driven-dev (sp)       ← Implement (TDD preserves behavior)
  ↓
finishing-a-development-branch (sp) ← Clean up branch
  ↓
verification-before-comp (sp)  ← All tests pass
  ↓
review (gstack)                ← PR review
  ↓
ship (gstack)                  ← Release
```

### 6.5 Code Review Feedback

```
receiving-code-review (sp)     ← Evaluate feedback (verify > blind agree)
  ↓
requesting-code-review (sp)    ← Request re-review after fixes
  ↓
(if fix needed) TDD → modify → verification
  ↓
Reply in thread
```

### 6.6 Production Incident / "Production is down"

```
guard (gstack)                 ← Full safety: destructive warnings + scoped edits
  or careful (gstack)          ← Safety mode only
  ↓
investigate (gstack)           ← Locate problem
  ↓
systematic-debugging (sp)      ← Root cause analysis
  ↓
Fix → canary (gstack)          ← Post-fix monitoring
```

### 6.7 Security Audit / "Check security"

```
cso (gstack)                   ← OWASP + STRIDE + attack surface
  ↓
(if issues found) systematic-debugging → TDD fix → review
```

### 6.8 Performance / "Too slow"

```
benchmark (gstack)             ← Baseline test
  ↓
Locate bottleneck → optimize → benchmark verify
```

### 6.9 Design System / "Need DESIGN.md"

```
office-hours (gstack)          ← Product context
  ↓
design-consultation (gstack)   ← Create DESIGN.md + preview
  or design-shotgun (gstack)   ← Generate multiple AI design variants
  ↓
design-review (gstack)         ← Visual audit (if existing site)
```

### 6.10 Visual Review / "UI looks wrong"

```
design-review (gstack)         ← 10-dimension audit + fix + screenshots
```

### 6.11 Weekly Retro / "What did I ship"

```
retro (gstack)                 ← Analyze commit history + work patterns
```

### 6.12 Learn / "What did we learn" / "Did we fix this before"

```
learn (gstack)                 ← Review, search, prune, export session learnings
```

### 6.13 Write a New Skill / "Create a skill"

```
writing-skills (superpowers)   ← Create or edit skills with proper structure
```

### 6.14 Report Bug Only / "Just report this bug"

```
qa-only (gstack)               ← Bug report without code changes
```

## 7. Routing Policy

Use these routing defaults:

- unclear feature request → `office-hours`
- approved design needing implementation plan → `writing-plans`
- active implementation with existing plan → `subagent-driven-dev`
- bug / broken behavior → `investigate` or `systematic-debugging`
- ready for release/review → `review`, `ship`

When recommending, always include:

- the best next skill
- one backup option
- one thing not to do yet

## 7.1 Completion Gate

Before the final answer on any routed implementation task:

1. decide whether `CLAUDE.md`, `PRD.md`, and `README.md` need updates
2. if any one needs updates, prefer `document-release (gstack)` as the executor
3. if `document-release` is unavailable, update the docs manually instead of skipping the check
4. include this exact block in the final answer:

```md
## 文档判定

- CLAUDE.md: 已更新 / 未更新，原因：...
- PRD.md: 已更新 / 未更新，原因：...
- README.md: 已更新 / 未更新，原因：...
```

Notes:

- do not list `AGENTS.md` as a separate document decision target; project `AGENTS.md` should stay a thin wrapper to `CLAUDE.md`
- `CHANGELOG.md` is not part of the default document gate
- for pure refactors, test-only changes, or formatting-only changes, it is valid to mark all three as "未更新" with a concrete reason

## 8. Sub-commands

### 8.1 /codesop init [path]

Initialize project scaffolding and environment guidance.

This is a mechanical command, not a workbench-summary command.

Run:

```bash
bash ~/codesop/codesop init <target-dir>
```

Expected command responsibilities:

- `AGENTS.md` — 轻量包装：`@CLAUDE.md`
- `PRD.md` — 活文档：同时记录产品规范、当前进度、最近决策、风险与工作日志

条件生成（不存在时）：

- `README.md` — 填充安装/运行/测试命令
- `CLAUDE.md` — 由 Claude Code 的 `/init` 生成，codesop 不覆盖

`AGENTS.md` 已存在 → 保留，输出 diff 建议。

全部默认中文。根据检测到的技术栈推断 test/lint/typecheck/smoke 命令。

When reporting back after `init`:

- keep the response centered on the command output
- say which files were generated or preserved
- say whether ecosystem dependencies are installed, partially installed, or missing
- do not add a separate project scorecard
- do not add workbench routing unless the user explicitly asks for next-step advice

### 8.2 /codesop update

Check and apply updates.

1. Check gstack version → show diff
2. Check superpowers version → show diff
3. Check this file's version number
4. Ask user if they want to update

## 9. Conflict Resolution

| Conflict | Rule |
|----------|------|
| brainstorming vs office-hours | New feature → office-hours; small change → brainstorming |
| requesting-code-review vs /review | Task-level → requesting-code-review; PR-level → /review |
| systematic-debugging vs /investigate | Single file → systematic-debugging; system-level → /investigate |
| subagent vs executing-plans | Independent tasks → subagent (parallel); serial → executing-plans |
| User says "just fix it" vs skill workflow | User instruction wins, but still obey verification and delivery rules from `AGENTS.md` |

## 10. Fallback

When no scenario matches:

1. Produce the workbench summary anyway
2. Scan all skill descriptions if available
3. Rank the top 3 workflow options
4. Recommend the least-risk next step
5. If still unclear, ask one focused question

## 11. Iron Laws

| Iron Law | Source |
|----------|--------|
| No code without design approval | brainstorming / office-hours |
| No production code without failing test first | TDD |
| No fix without root cause investigation | systematic-debugging |
| No completion claim without verification evidence | verification-before-completion |
| Load skill if 1% chance it applies | using-superpowers |
| User instruction > project rules > default behavior | instruction priority |
