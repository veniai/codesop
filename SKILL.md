---
name: codesop
description: |
  Use when the user asks "what skill should I use", "help me start this",
  "what workflow for bug/feature/refactor", "I don't know what to do next",
  or wants to init a project, check skill status, or check for updates.
  Covers new features, bug fixes, small changes, refactoring, PR review,
  code review feedback, production incidents, security audits, design work,
  performance, and weekly retro.
---

# codesop: Complete Workflow Guide

Announce: "Using /codesop to map your scenario to the right workflow."

## 1. Scenario → Workflow Mapping

### 1.1 New Feature / "I want to build X"

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

### 1.2 Bug Fix / "XX is broken"

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

### 1.3 Small Change / "Tweak XX"

```
Direct change + TDD (sp)       ← Write test, then change code
  ↓
verification-before-comp (sp)  ← Verification evidence
  ↓
review (gstack)                ← PR review (if multi-file)
  ↓
ship (gstack)                  ← Release (if needed)
```

### 1.4 Refactoring / "Clean up XX"

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

### 1.5 Code Review Feedback

```
receiving-code-review (sp)     ← Evaluate feedback (verify > blind agree)
  ↓
(if fix needed) TDD → modify → verification
  ↓
Reply in thread
```

### 1.6 Production Incident / "Production is down"

```
careful (gstack)               ← Safety mode
  ↓
investigate (gstack)           ← Locate problem
  ↓
systematic-debugging (sp)      ← Root cause analysis
  ↓
Fix → canary (gstack)          ← Post-fix monitoring
```

### 1.7 Security Audit / "Check security"

```
cso (gstack)                   ← OWASP + STRIDE + attack surface
  ↓
(if issues found) systematic-debugging → TDD fix → review
```

### 1.8 Performance / "Too slow"

```
benchmark (gstack)             ← Baseline test
  ↓
Locate bottleneck → optimize → benchmark verify
```

### 1.9 Design System / "Need DESIGN.md"

```
office-hours (gstack)          ← Product context
  ↓
design-consultation (gstack)   ← Create DESIGN.md + preview
  ↓
design-review (gstack)         ← Visual audit (if existing site)
```

### 1.10 Visual Review / "UI looks wrong"

```
design-review (gstack)         ← 10-dimension audit + fix + screenshots
```

### 1.11 Weekly Retro / "What did I ship"

```
retro (gstack)                 ← Analyze commit history + work patterns
```

---

## 2. Sub-commands

### 2.1 /codesop init [path]

Three-layer project initialization with parallel execution.

#### Execution Overview

```
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
```
环境识别：
  ✓ Claude Code: 已检测到
  ✓ Codex: 已检测到
  ⚠ superpowers: 未安装 → 建议命令: ...
  ✓ gstack: 已安装
  ✓ AGENTS.md symlink: 3/3 有效且可读
  ✓ SKILL.md symlink: 3/3 有效且可读
```

Phase 2 输出：
```
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
- `PRD.md` — 产品模板，技术栈预填

条件生成（不存在时）：
- `README.md` — 填充安装/运行/测试命令

`AGENTS.md` 已存在 → 保留，输出 diff 建议。

全部默认中文。根据检测到的技术栈推断 test/lint/typecheck/smoke 命令。

#### Layer 2: Diagnosis (lightweight analysis, parallel sub-agent)

**Phase 4: 轻量现状分析 (Track B, sub-agent)**

启动方式：在 Track A 启动的同时，派一个 sub-agent 执行。

sub-agent 任务提示词：
```
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

然后继续 Phase 5+6。

#### Layer 3: Decision (AI judgment, fixed output format)

**Phase 5: Skill 路由 + 项目状态总结**

综合 Phase 2（成熟度）+ Phase 4（现状分析），推荐 skill。固定 3 档输出：

```
## Skill 路由

推荐: /office-hours
原因: 架构边界模糊，需要先理清需求和方向

备选: /plan-eng-review
原因: 如果已有明确计划，直接做工程审查

暂不建议: /subagent-driven-dev
原因: 架构未定，直接实现会导致返工
```

路由参考（AI 可灵活判断）：
- 空目录 / 想法阶段 → /office-hours
- 有设计但没实现 → /writing-plans
- 有计划要执行 → /subagent-driven-dev
- 代码有问题 → /investigate
- 要发布 → /review → /ship
- 安全问题 → /cso
- 性能问题 → /benchmark

最后输出项目状态总结（终端输出，不生成文件）：

```
## 项目状态总结

当前阶段: [Phase 4 分析得出的描述]
推荐下一步: /office-hours — [一句话原因]
原因:
  - [Phase 4 关键发现 1]
  - [Phase 4 关键发现 2]
暂不建议: /subagent-driven-dev — [Phase 5 的原因]
```

### 2.2 /codesop status

Show skill health dashboard.

1. Scan superpowers + gstack skill directories
2. Check versions (gstack-update-check + npm outdated)
3. Read usage stats (~/.gstack/analytics/)
4. Output dashboard + recommendations

### 2.3 /codesop update

Check and apply updates.

1. Check gstack version → show diff
2. Check superpowers version → show diff
3. Check this file's version number
4. Ask user if they want to update

---

## 3. Conflict Resolution

| Conflict | Rule |
|----------|------|
| brainstorming vs office-hours | New feature → office-hours; small change → brainstorming |
| requesting-code-review vs /review | Task-level → requesting-code-review; PR-level → /review |
| systematic-debugging vs /investigate | Single file → systematic-debugging; system-level → /investigate |
| subagent vs executing-plans | Independent tasks → subagent (parallel); serial → executing-plans |
| User says "just fix it" vs skill workflow | User instruction wins, but must run verification before claiming done |

---

## 4. Fallback

When no scenario matches:

1. Scan all skill descriptions (use skill-manager)
2. Rank by keyword match
3. Show Top 3 recommendations, let user choose
4. Still unsure → suggest "run /office-hours first to clarify"
5. Nothing fits → ask user directly

---

## 5. Iron Laws

| Iron Law | Source |
|----------|--------|
| No code without design approval | brainstorming / office-hours |
| No production code without failing test first | TDD |
| No fix without root cause investigation | systematic-debugging |
| No completion claim without verification evidence | verification-before-completion |
| Load skill if 1% chance it applies | using-superpowers |
| User instruction > skill > default | instruction priority |
