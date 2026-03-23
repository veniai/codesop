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

Three-layer project initialization: mechanical setup → lightweight analysis → skill routing.

#### Layer 1: Mechanical (rule-driven, verifiable)

**Phase 1: Environment Setup**

Run `bash <codesop-root>/scripts/detect-environment.sh <target-dir>` to detect:
- Installed tools: Claude Code, Codex, OpenCode/OpenClaw
- Installed ecosystems: superpowers, gstack
- Symlink validity: verify `AGENTS.md` and `SKILL.md` symlinks point to `~/codesop/` and are readable (`cat` each symlink to confirm content)

Output format:
```
环境识别：
  ✓ Claude Code: 已检测到
  ✓ Codex: 已检测到
  ⚠ superpowers: 未安装 → 建议命令: ...
  ✓ gstack: 已安装
  ✓ AGENTS.md symlink: 3/3 有效且可读
  ✓ SKILL.md symlink: 3/3 有效且可读
```

If missing ecosystems: show install command per host tool, wait for user confirmation before executing.

**Phase 2: Project Classification**

Run the same detector script. Classify:
- Language (Python / TypeScript/JavaScript / Go / Rust / Unknown)
- Shape (Web App / Backend Service / CLI / Library / Monorepo / General)
- Framework (Next.js / React / FastAPI / Django / None)
- Maturity level:
  - Empty directory: 0 source files
  - New skeleton: < 10 source files, no git commits
  - In development: has git commits, < 100 commits
  - Established: > 100 commits

Output format:
```
项目识别：
  主语言：TypeScript/JavaScript
  项目形态：Web App
  框架：Next.js
  成熟度：开发中 (47 commits)
```

**Phase 3: Scaffold Generation**

Default generate (no user prompt):
- `AGENTS.md` — filled with detected stack, commands, architecture rules
- `CLAUDE.md` — lightweight wrapper: `@AGENTS.md`
- `PRD.md` — product template with detected stack pre-filled

Condition generate (only if doesn't exist):
- `README.md` — filled with install/run/test commands

If `AGENTS.md` already exists: keep it, output diff-like merge suggestions in terminal.

All templates default to Chinese. Infer test/lint/typecheck/smoke commands from detected stack.

#### Layer 2: Diagnosis (lightweight analysis, fixed template output)

**Phase 4: Lightweight Status Analysis**

AI reads the project and evaluates 6 dimensions. Each scored 0-10:

| # | Check | Method | Output |
|---|-------|--------|--------|
| 1 | Git activity | `git log --oneline -20` | Recent commits summary + score |
| 2 | Directory structure | `ls -R` + depth check | Structure score + suggestions |
| 3 | Documentation | Check AGENTS/PRD/README/ARCHITECTURE | Missing list + score |
| 4 | Test commands | Check package.json scripts / Makefile | Available/missing + score |
| 5 | Architecture boundaries | Check domain/usecases/infra/app dirs | Clear/fuzzy/none + score |
| 6 | TODO/FIXME scatter | `grep -rn TODO/FIXME` | Count + locations + score |

Fixed output format:
```
## 现状分析

| 检查项         | 状态    | 评分  | 说明                 |
|----------------|---------|-------|----------------------|
| git 活跃度     | 活跃    | 8/10  | 最近 7 天有 3 次提交  |
| 目录结构       | 清晰    | 7/10  | src/ 分层合理         |
| 文档存在性     | 不完整  | 4/10  | 缺 AGENTS.md, PRD.md |
| 测试命令       | 有      | 6/10  | npm test 存在         |
| 架构边界       | 模糊    | 3/10  | 无明确分层            |
| TODO/FIXME     | 散落    | 5/10  | 12 处散落             |

综合评分: 5.5/10
```

#### Layer 3: Decision (AI judgment, fixed output format)

**Phase 5: Skill Routing**

Combine Phase 2 (maturity) + Phase 4 (status) to recommend skills. Fixed 3-tier output:

```
## Skill 路由

推荐: /office-hours
原因: 架构边界模糊，需要先理清需求和方向

备选: /plan-eng-review
原因: 如果已有明确计划，直接做工程审查

暂不建议: /subagent-driven-dev
原因: 架构未定，直接实现会导致返工
```

Routing rules (not exhaustive, AI adapts):
- Empty directory / idea stage → /office-hours
- Has design but no implementation → /writing-plans
- Has plan, ready to execute → /subagent-driven-dev
- Has bugs → /investigate
- Ready to ship → /review → /ship
- Security concern → /cso
- Performance issue → /benchmark

**Phase 6: Write PROJECT_STATUS.md**

Generate a separate `PROJECT_STATUS.md` in the project root. NOT written to `AGENTS.md`.

```markdown
# Project Status

Last init: YYYY-MM-DD

## Current Phase
[Description from Phase 4 analysis]

## Recommended Next Step
/[skill-name] — [one-line reason]

## Why
- [Key finding 1 from Phase 4]
- [Key finding 2 from Phase 4]

## Do NOT Do Now
/[skill-name] — [reason from Phase 5]
```

This file is read by future AI sessions to understand "what should I do next with this project."
`AGENTS.md` stays clean — it only contains long-term rules.

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
