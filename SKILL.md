---
name: codesop
description: Use when the user seems lost, asks what to do next, asks what skill to use, wants to continue an existing project, wants a status/progress summary, wants help choosing a workflow before implementation, or explicitly mentions codesop or /codesop. This skill is the project workbench and workflow router: it restores context from AGENTS.md and PRD.md, summarizes current state, recommends the next skill, and explains what not to do yet.
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
  ↓
codex (gstack)                 ← Adversarial review
  ↓
qa (gstack)                    ← Browser testing
  ↓
review (gstack)                ← PR diff review
  ↓
ship (gstack)                  ← Create PR
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
(if fix needed) TDD → modify → verification
  ↓
Reply in thread
```

### 6.6 Production Incident / "Production is down"

```
careful (gstack)               ← Safety mode
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

## 8. Sub-commands

### 8.1 /codesop init [path]

Three-layer project initialization with parallel execution.

#### Execution Overview

```text
并行启动:
  Track A (bash):    Phase 1+2 → Phase 3
  Track B (sub-agent):          Phase 4
                     ↓ 合并 ↓
  主 Agent:                      Phase 5 → 输出总结
```

**并行规则：Track A 和 Track B 同时启动，谁先完成谁等。全部完成后再做 Phase 5。**

#### Layer 1: Mechanical (rule-driven, verifiable)

**Phase 1+2: Environment Setup + Project Classification (Track A, bash)**

启动方式：直接执行 bash 命令，不派 sub-agent。

```bash
bash ~/codesop/codesop init <target-dir>
```

Phase 1 输出：

```text
环境识别：
  ✓ Claude Code: 已检测到
  ✓ Codex: 已检测到
  ⚠ superpowers: 未安装 → 建议命令: ...
  ✓ gstack: 已安装
  ✓ AGENTS.md symlink: 3/3 有效且可读
  ✓ SKILL.md symlink: 3/3 有效且可读
```

Phase 2 输出：

```text
项目识别：
  主语言：TypeScript/JavaScript
  项目形态：Web App
  框架：Next.js
  成熟度：开发中 (47 commits)
```

如果缺失插件：按宿主工具给出安装命令，等用户确认后再执行。

**Phase 3: Scaffold Generation (Track A, bash)**

Phase 1+2 完成后立即执行，不等 Phase 4。

默认生成（不问用户）：

- `AGENTS.md` — 填充技术栈、命令、架构规则
- `CLAUDE.md` — 轻量包装：`@AGENTS.md`
- `PRD.md` — 活文档：同时记录产品规范、当前进度、最近决策、风险与工作日志

条件生成（不存在时）：

- `README.md` — 填充安装/运行/测试命令

`AGENTS.md` 已存在 → 保留，输出 diff 建议。

全部默认中文。根据检测到的技术栈推断 test/lint/typecheck/smoke 命令。

#### Layer 2: Diagnosis (lightweight analysis, parallel sub-agent)

**Phase 4: 轻量现状分析 (Track B, sub-agent)**

启动方式：在 Track A 启动的同时，派一个 sub-agent 执行。

sub-agent 任务提示词：

```text
你是 codesop init 的现状分析助手。请分析项目 <target-dir>，完成以下 6 项检查，
每项给评分 0-10，最后输出综合评分。

检查项：
1. git 活跃度 — 运行 git log --oneline -20，判断最近提交频率
2. 目录结构 — 扫描目录，判断分层是否清晰
3. 文档存在性 — 检查 AGENTS.md / CLAUDE.md / PRD.md / README.md / ARCHITECTURE.md
4. 测试命令 — 检查 package.json scripts 或 Makefile 中的 test 命令
5. 架构边界 — 检查是否有 domain / usecases / infra / app 目录
6. TODO/FIXME 散落 — grep -rn "TODO\|FIXME" 统计数量和位置

请严格按以下格式输出（中文）：

## 现状分析

| 检查项         | 状态    | 评分  | 说明                 |
|----------------|---------|-------|----------------------|
| git 活跃度     |         |       |                      |
| 目录结构       |         |       |                      |
| 文档存在性     |         |       |                      |
| 测试命令       |         |       |                      |
| 架构边界       |         |       |                      |
| TODO/FIXME     |         |       |                      |

综合评分: X/10
```

#### 合并：等 Track A + Track B 都完成

主 Agent 等两个 Track 都完成后，收集结果：

- Track A 输出：环境识别 + 项目识别 + 已生成的文件
- Track B 输出：现状分析表格 + 综合评分

然后继续 Phase 5。

#### Layer 3: Decision (AI judgment, fixed output format)

**Phase 5: Skill 路由 + 项目状态总结**

综合 Phase 2 和 Phase 4，输出工作台摘要，并补一个 3 档 skill 路由：

```text
## Skill 路由

推荐: /office-hours
原因: 架构边界模糊，需要先理清需求和方向

备选: /writing-plans
原因: 如果已有明确需求，可直接进入计划阶段

暂不建议: /subagent-driven-dev
原因: 架构未定，直接实现会导致返工
```

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
