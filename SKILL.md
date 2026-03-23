---
name: codesop
version: 1.0.0
description: |
  AI coding SOP — maps scenarios to workflows, initializes projects,
  checks skill health, checks for updates.
  Use when: "what skill should I use", "help me start this", "init project",
  "check status", "check for updates", "what workflow for bug/feature/refactor",
  "I don't know what to do next".
  Covers 15 scenarios: new features, bug fixes, small changes, refactoring,
  PR review, code review feedback, production incidents, security audits,
  design work, performance, weekly retro, and more.
benefits-from: [office-hours, brainstorming]
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - WebSearch
  - AskUserQuestion
---

# AI-SOP: Complete Workflow Guide

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

Initialize project configuration files.

1. Scan target directory: file structure, tech stack, existing config
2. Output analysis summary
3. Recommend 2-3 configuration options (including architecture choice), let user pick
4. Ask: "Need PRD.md?"
5. Generate based on user selection:
   - `<project>/CLAUDE.md` or `<project>/AGENTS.md` (project config)
   - `<project>/PRD.md` (product template, if user needs and doesn't exist)
   - `<project>/README.md` (if doesn't exist)

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
