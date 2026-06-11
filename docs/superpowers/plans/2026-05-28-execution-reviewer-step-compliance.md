# Execution Reviewer Step Compliance Implementation Plan (v2)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Patch subagent-driven-development's spec reviewer and code quality reviewer to detect stub/placeholder implementations and enforce step-level compliance.

**Architecture:** Replace two reviewer prompt templates with enhanced versions. Extend setup's patch_skills() to sync them. No controller or implementer changes.

**Tech Stack:** Markdown (prompt templates), Bash (setup script)

---

## Acceptance Criteria

G1: spec-reviewer-prompt 强制先枚举子步骤 S1..SN 再逐一比对
    Given: reviewer 收到一个包含 6 个子步骤的 plan task
    When: reviewer 执行分析
    Then: 输出 Step Compliance Matrix 中有 6 行（S1-S6）
    Verify: `sed -n '/^-->/,$ p' patches/superpowers/subagent-driven-development-spec-reviewer-prompt.md | grep -c 'S[0-9]'` >= 3
    Boundary: plan step 没有子步骤时跳过枚举
    Covers: R1

G2: spec-reviewer-prompt 对 7 种 stub 模式逐一检测
    Given: 被审代码包含 stub 模式
    When: reviewer 执行 anti-stub 检查
    Then: 输出 Stub/Placeholder Warnings 段
    Verify: `sed -n '/^-->/,$ p' patches/superpowers/subagent-driven-development-spec-reviewer-prompt.md | grep -c 'disabled\|TODO\|FIXME\|empty.*function\|hardcoded\|swallowed'` >= 4
    Covers: R2

G3: spec-reviewer-prompt 包含复杂度比例检查（>3 子步骤 <20 行 → 标红）
    Verify: `sed -n '/^-->/,$ p' patches/superpowers/subagent-driven-development-spec-reviewer-prompt.md | grep -c 'complexity\|20.*line\|sub.step.*line'` >= 1
    Covers: R3

G4: spec-reviewer-prompt 对 monolithic step 自行拆分后独立检查
    Verify: `sed -n '/^-->/,$ p' patches/superpowers/subagent-driven-development-spec-reviewer-prompt.md | grep -c 'monolithic\|compound\|multipl.*requirement\|split.*step\|decompos'` >= 1
    Covers: R4

G5: code-quality-reviewer-prompt 包含 Implementation Depth section，prompt 正文不含 Plan alignment section
    Verify: `sed -n '/^-->/,$ p' patches/superpowers/subagent-driven-development-code-quality-reviewer-prompt.md | grep -c 'Implementation.depth\|Implementation Depth'` >= 1 且 `sed -n '/^-->/,$ p' patches/superpowers/subagent-driven-development-code-quality-reviewer-prompt.md | grep -c 'Plan.alignment\|Plan Alignment'` = 0
    Covers: R7

G6: code-quality-reviewer-prompt Calibration 包含 4 条强制 depth 验证步骤
    Verify: `sed -n '/^-->/,$ p' patches/superpowers/subagent-driven-development-code-quality-reviewer-prompt.md | grep -c 'event.handler\|hardcoded\|disabled.*empty\|real.logic'` >= 3
    Covers: R8

G7: setup patch_skills() 同步 2 个 reviewer prompt 文件
    Verify: `grep -c 'spec-reviewer-prompt\|code-quality-reviewer-prompt' setup` >= 4
    Covers: R9

G8: bash tests/run_all.sh 退出码 0
    Verify: 直接执行
    Covers: R11

G9: 2 个新 patch 文件有 HTML 头注释（含 "Revert:" 字样）
    Verify: `grep -c 'Revert:' patches/superpowers/subagent-driven-development-spec-reviewer-prompt.md` >= 1 且 `grep -c 'Revert:' patches/superpowers/subagent-driven-development-code-quality-reviewer-prompt.md` >= 1
    Covers: R10

G10: spec-reviewer-prompt 输出格式包含全部 6 个段落
    Verify: `sed -n '/^-->/,$ p' patches/superpowers/subagent-driven-development-spec-reviewer-prompt.md | grep -c 'Step Compliance Matrix\|Stub.*Warning\|Complexity.*Flag\|Extra.*Unneeded\|Issues'` >= 5
    Covers: R5

G11: spec-reviewer-prompt 包含三级 Status 精确定义
    Verify: `sed -n '/^-->/,$ p' patches/superpowers/subagent-driven-development-spec-reviewer-prompt.md | grep -c 'Compliant\|Partial.*⚠\|Non.compliant.*❌'` >= 2
    Covers: R6

**Coverage Matrix:**

| Gn | Covers Rn | Verification |
|----|-----------|-------------|
| G1 | R1 | command |
| G2 | R2 | command |
| G3 | R3 | command |
| G4 | R4 | command |
| G5 | R7 | command |
| G6 | R8 | command |
| G7 | R9 | command |
| G8 | R11 | test |
| G9 | R10 | command |
| G10 | R5 | command |
| G11 | R6 | command |

**Gap Scan:**
- [x] 负面用例: G2 boundary 覆盖（合理 TODO vs stub TODO 的区分是已知限制）
- [x] 边界条件: G1 boundary 覆盖（plan step 没有子步骤）
- [x] 回归风险: G8
- [x] 配置/环境: G7
- [ ] 文档/API: 不涉及
- [ ] 迁移/兼容: 不涉及

R12 (Manual test) 不在 plan 验证范围内，需部署后观察。

## Complexity Assessment

**Level:** moderate
**File estimate:** 4 (2 new patches + setup + verification)
**Modules:** patches/superpowers, setup
**Override:** none

---

### Task 1: Create spec-reviewer-prompt patch

**Scope:** Write the enhanced spec-reviewer-prompt.md with step enumeration, anti-stub detection, complexity check, monolithic step decomposition, and Step Compliance Matrix output format.
**Acceptance IDs:** G1, G2, G3, G4, G10, G11
**Likely files:** `patches/superpowers/subagent-driven-development-spec-reviewer-prompt.md`
**Implementation guidance:** brief
**Key direction:** Full replacement prompt incorporating all 5 enhancement areas from spec §2.1. Include HTML header comment with revert instructions. Prompt must be self-contained.
**Validation:**
```bash
grep -c 'Revert:' patches/superpowers/subagent-driven-development-spec-reviewer-prompt.md
sed -n '/^-->/,$ p' patches/superpowers/subagent-driven-development-spec-reviewer-prompt.md | grep -c 'S[0-9]'
sed -n '/^-->/,$ p' patches/superpowers/subagent-driven-development-spec-reviewer-prompt.md | grep -c 'disabled\|TODO\|FIXME\|empty.*function\|hardcoded\|swallowed'
sed -n '/^-->/,$ p' patches/superpowers/subagent-driven-development-spec-reviewer-prompt.md | grep -c 'complexity\|20.*line\|sub.step.*line'
sed -n '/^-->/,$ p' patches/superpowers/subagent-driven-development-spec-reviewer-prompt.md | grep -c 'monolithic\|compound\|multipl.*requirement\|split.*step\|decompos'
sed -n '/^-->/,$ p' patches/superpowers/subagent-driven-development-spec-reviewer-prompt.md | grep -c 'Step Compliance Matrix\|Stub.*Warning\|Complexity.*Flag\|Extra.*Unneeded\|Issues'
sed -n '/^-->/,$ p' patches/superpowers/subagent-driven-development-spec-reviewer-prompt.md | grep -c 'Compliant\|Partial.*⚠\|Non.compliant.*❌'
```
**Out of scope:** Controller flow changes, implementer prompt changes

### Task 2: Create code-quality-reviewer-prompt patch

**Scope:** Write the enhanced code-quality-reviewer-prompt.md replacing Plan alignment with Implementation Depth section and adding mandatory depth verification in Calibration.
**Acceptance IDs:** G5, G6, G9
**Likely files:** `patches/superpowers/subagent-driven-development-code-quality-reviewer-prompt.md`
**Implementation guidance:** brief
**Key direction:** Full replacement prompt. Remove Plan alignment entirely. Add Implementation Depth section with 4-point checklist. Add Calibration mandatory verification. Include HTML header comment.
**Validation:**
```bash
grep -c 'Revert:' patches/superpowers/subagent-driven-development-code-quality-reviewer-prompt.md
sed -n '/^-->/,$ p' patches/superpowers/subagent-driven-development-code-quality-reviewer-prompt.md | grep -c 'Implementation.depth\|Implementation Depth'
sed -n '/^-->/,$ p' patches/superpowers/subagent-driven-development-code-quality-reviewer-prompt.md | grep -c 'Plan.alignment\|Plan Alignment'
sed -n '/^-->/,$ p' patches/superpowers/subagent-driven-development-code-quality-reviewer-prompt.md | grep -c 'event.handler\|hardcoded\|disabled.*empty\|real.logic'
```
**Out of scope:** Spec reviewer concerns, controller flow

### Task 3: Extend setup patch_skills()

**Scope:** Add sync logic for the 2 new reviewer prompt patch files in setup's patch_skills() function.
**Acceptance IDs:** G7
**Likely files:** `setup`
**Implementation guidance:** brief
**Key direction:** Follow existing pattern (hardcoded per-file sync with diff check), insert after the brainstorming patch block. Same style as writing-plans/finishing patches.
**Validation:**
```bash
grep -c 'spec-reviewer-prompt\|code-quality-reviewer-prompt' setup
bash setup --host claude 2>&1 | grep -i 'patch'
```
**Out of scope:** Generalizing patch_skills(), new manifest system

### Task 4: Verify and commit

**Scope:** Apply patches, run all tests, verify all acceptance criteria.
**Acceptance IDs:** G1-G11
**Likely files:** (verification only)
**Implementation guidance:** brief
**Key direction:** Run setup, run tests, grep all verification commands from G1-G11.
**Validation:**
```bash
bash setup --host claude
bash tests/run_all.sh
```
**Out of scope:** Version bump (spec excludes), manual test (R12)

## Requirement Traceability

| Req | Spec Section | Discrete Requirement |
|-----|-------------|---------------------|
| R1 | §2.1(a) | spec-reviewer-prompt 强制子步骤枚举 S1..SN |
| R2 | §2.1(b) | spec-reviewer-prompt anti-stub 检测（7 种模式） |
| R3 | §2.1(c) | spec-reviewer-prompt 复杂度比例检查 |
| R4 | §2.1(e) | spec-reviewer-prompt monolithic step 自拆分 |
| R5 | §2.1(d) | spec-reviewer-prompt Step Compliance Matrix 完整输出格式 |
| R6 | §2.1(d) | spec-reviewer-prompt 三级 Status 精确判定 |
| R7 | §2.2(a) | code-quality-reviewer-prompt Plan alignment → Implementation Depth |
| R8 | §2.2(b) | code-quality-reviewer-prompt Calibration 强制 depth 验证 |
| R9 | §3.1 | setup patch_skills() 扩展 |
| R10 | §3.2 | patch 文件 HTML 头注释 |
| R11 | §5 | bash tests/run_all.sh 全绿 |
| R12 | §5 | Manual test（不在 plan 验证范围内） |
