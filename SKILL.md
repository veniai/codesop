---
name: codesop
description: |
  Project workbench and workflow router for AI-assisted coding across Claude Code, Codex, and OpenCode.
  Restores context from AGENTS.md and PRD.md, summarizes current state, recommends the next skill, and explains what not to do yet.
  Proactively invoke this skill (do NOT answer directly) when the user:
  - asks what to do next, what skill to use, or wants a status/progress summary
  - says "continue", returns to a project after a gap, or looks confused about what step comes next
  - explicitly mentions codesop, /codesop, workflow, project status, or next step
  - wants help deciding whether to plan, debug, implement, review, or ship
  - describes a new feature, bug, refactoring, or small change without specifying a workflow
  - 下一步做什么 / 继续做什么 / 看看项目状态 / 进度总结 / 不确定该怎么做 / 帮我看看 / 接着做
  - 看 PR / 审核意见 / code review / PR 反馈 / 检查代码
  Do not trigger when the user is explicitly invoking a mechanical subcommand like /codesop init or /codesop update.
  (codesop)
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
5. Run skill routing coverage check:
   ```bash
   (source ~/codesop/lib/output.sh && source ~/codesop/lib/updates.sh && ROOT_DIR=~/codesop VERSION_FILE=~/codesop/VERSION check_skill_routing_coverage) || echo "路由检查跳过: 模块不可用"
   ```
6. Produce a workbench summary (include routing coverage result under `## Skill 生态`)
7. Recommend the most relevant next skill or action

Default to orientation and routing first. Do not jump into implementation unless the user clearly asks to proceed.

When `/codesop` is used, treat it as a diagnosis/context layer:

- use `/codesop` for stage guess, health status, config facts, and recommendation context
- use `PRD.md` for long-term goal, current narrative, recent decisions, and next-step intent
- explain any mismatch between `PRD.md` and fresh CLI facts

## 4. Default Output

```md
## 工作台摘要
**长期目标**: ... **当前阶段**: ... **当前进度**: ...
**阻塞/风险**: ... **最近决策**: ... **下一步**: ...

## Skill 建议
- 推荐: ... (原因: ...)
- 备选: ... (原因: ...)
- 暂不建议: ... (原因: ...)

## Skill 生态
- 路由覆盖：（粘贴 check_skill_routing_coverage 输出）
  - "所有已安装 skill 均已收录"→ "✓ 路由覆盖完整"
  - 含缺失 skill → 显示原文
  - "无已安装 skill"→ "路由覆盖：未检测到已安装 skill"
```

Compress for quick answers, but keep the same mental model.

## 5. Trigger Guidance

Trigger aggressively. See frontmatter for the full trigger list.

Key rule: do not use explicit `codesop` mention alone as a trigger if the message is clearly just a CLI subcommand execution request.

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
  or executing-plans (sp)      ← Alternative: serial execution per task
  or dispatching-parallel-agents (sp) ← Alternative: 2+ independent tasks in parallel
  ↓
finishing-a-development-branch (sp) ← Clean up branch before review
  ↓
codex (gstack)                 ← Adversarial review
  ↓
qa (gstack)                    ← Browser testing
  ↓
ship (gstack)                  ← Create PR
  ↓
review (gstack)                ← PR diff review
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
verification-before-completion (sp)  ← Verification evidence
  ↓
unfreeze (gstack)              ← Remove edit restriction
  ↓
review (gstack)                ← PR review (if needed)
  ↓
ship (gstack)                  ← Release (if needed)
```

### 6.3 Small Change / "Tweak XX"

```
test-driven-development (sp)    ← Write failing test, then change code
  ↓
verification-before-completion (sp)  ← Verification evidence
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
verification-before-completion (sp)  ← All tests pass
  ↓
review (gstack)                ← PR review
  ↓
ship (gstack)                  ← Release
```

### 6.5 Code Review Feedback

```
receiving-code-review (sp)     ← Evaluate feedback (verify > blind agree)
  ↓
(if fix needed) test-driven-development (sp) → modify → verification-before-completion (sp)
  ↓
requesting-code-review (sp)    ← Request re-review after fixes
  ↓
Reply in thread
```

### 6.6 Production Incident / "Production is down"

`guard` or `careful` (gstack) → `investigate` (gstack) → `systematic-debugging` (sp) → fix → `canary` (gstack)

### 6.7 Security Audit / "Check security"

`cso` (gstack) → (if issues) `systematic-debugging` → `TDD` fix → `review`

### 6.8 Performance / "Too slow"

`benchmark` (gstack) → `systematic-debugging` (sp) → optimize → `benchmark` (gstack)

### 6.9 Design System / "Need DESIGN.md"

`office-hours` (gstack) → `design-consultation` or `design-shotgun` (gstack) → `design-review` (gstack)

### 6.10 Visual Review / "UI looks wrong"

`design-review` (gstack) ← 10-dimension audit + fix + screenshots

### 6.11 Weekly Retro / "What did I ship"

`retro` (gstack) ← Analyze commit history + work patterns

### 6.12 Learn / "What did we learn" / "Did we fix this before"

`learn` (gstack) ← Review, search, prune, export session learnings

### 6.13 Write a New Skill / "Create a skill"

`writing-skills` (superpowers) ← Create or edit skills with proper structure

### 6.14 Report Bug Only / "Just report this bug"

`qa-only` (gstack) ← Bug report without code changes

## 7. Routing Policy

Use these routing defaults:

- unclear feature request → `office-hours`
- approved design needing implementation plan → `writing-plans`
- active implementation with existing plan → `subagent-driven-dev`
- bug / broken behavior → `investigate` or `systematic-debugging`
- ready for release/review → `review`, `ship`
- performance / "too slow" → `benchmark`
- security / "check security" → `cso`
- design system / "need DESIGN.md" → `design-consultation` or `design-shotgun`
- visual review / "UI looks wrong" → `design-review`
- weekly retro / "what did I ship" → `retro`
- learn / "what did we learn" → `learn`
- create or edit a skill → `writing-skills`
- PR review / 审核意见 / "看看 PR" / code review feedback → `codex` or `review`
- report bug only / "just report this" → `qa-only`
- production incident / "prod is down" → `guard` or `careful`

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

| Command | Run | What it does |
|---------|-----|-------------|
| `/codesop init [path]` | `bash ~/codesop/codesop init <dir>` | Generate AGENTS.md (`@CLAUDE.md`), PRD.md (活文档), README.md (if missing). Defaults to 中文. |
| `/codesop update` | `bash ~/codesop/codesop update` | Check gstack/superpowers/SKILL.md versions → show diff → ask to update. |

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
