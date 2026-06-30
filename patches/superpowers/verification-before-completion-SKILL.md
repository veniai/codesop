<!--
  codesop patch: verification-before-completion
  Based on: superpowers v6.0.3
  Changes vs upstream:
    1. Gate Function (5 steps) UNCHANGED — IDENTIFY/RUN/READ/VERIFY/CLAIM stays exactly as
       upstream. We do NOT touch the verification core.
    2. (v9 R8) diff 守护 step appended AFTER the Gate Function's 5 steps (a NEW step 6, an
       assertion — not a modification of the existing 5). Asserts: test deletion lines = 0 /
       skip/xfail surge / assert deletion / coverage threshold drop / lint config relaxed.
       ANY violation = immediate FAIL, halt /goal, do NOT proceed to evidence-pack. The Gate
       Function runs verification; the diff guard asserts verification was not weakened to
       manufacture a pass (anti-Goodhart).
    3. (v8 T5 + v9 R6) AI evidence-pack assembly AFTER the Gate Function runs: the working AI
       collates Gate Function output + spec cross-check into the evidence-pack schema (a)
       per-line verdict + (b) uncovered scan + (c) cross-model column. The Gate Function IS
       the verification; the evidence-pack IS the AI assembly — clear division of labor, no
       intrusion into the verification core. Evidence-pack schema fields reference the shared
       _evidence-pack-schema.md (sibling at runtime — patch_skills syncs both this main SKILL.md
       and the schema file next to it; fields cited by §-number, not duplicated here).
    4. (v9 R5) deliver-gate 风险分级: by spec-declared risk — low auto-pass (all four AND
       anchors true) / high FORCED human review (high-risk can NEVER auto-pass — codex review
       required, then human adjudicates; this mirrors T3 brainstorming high-risk enforcement).
    5. (v9 R6) 完成条件外部锚点 AND: completion requires EXTERNAL anchor signals only —
       tests pass AND lint clean AND independent subagent evidence-pack blocking cleared AND
       spec-coverage uncovered = empty (moderate/complex). AT LEAST ONE mechanical anchor
       (tests/lint/diff) — AI self-report is NOT an anchor. simple = tests + lint only.
    6. (v9 R9) codex high-risk 复核: when delivering a high-risk item, codex MUST re-check
       (consistent with T3 brainstorming high-risk enforcement); codex genuinely unavailable
       → degrade to advisory (human adjudicates), NEVER auto-judge 满足.
  Why: upstream Gate Function catches "claimed pass without running" but does NOT catch
    "ran pass then weakened the test to manufacture it" (test deletion / skip surge / coverage
    threshold drop / lint config relaxation). The diff guard (R8) closes that hole. The
    evidence-pack assembly + external-anchor AND (R6) ensure completion is judged against
    spec-declared completion conditions + machine signals, not AI self-report. deliver-gate
    risk grading (R5) + codex high-risk (R9) keep humans + cross-model on the high-risk path
    while letting low-risk work flow automatically. Consistent with T3 brainstorming / T4
    writing-plans gates (same schema, same AND anchors, same codex enforcement).
  Revert: delete this file and run `bash setup --host claude` to restore upstream version.
-->
---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always
---

# Verification Before Completion

## Overview

Claiming work is complete without verification is dishonesty, not efficiency.

**Core principle:** Evidence before claims, always.

**Violating the letter of this rule is violating the spirit of this rule.**

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command in this message, you cannot claim it passes.

## The Gate Function

```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```

### Step 6 (codesop patch, v9 R8) — Diff 守护 / Anti-Test-Weakening

**Run AFTER the Gate Function's 5 steps, BEFORE any completion claim or evidence-pack assembly.**
This is an assertion step, not a modification of the existing 5 steps — the Gate Function
proves "the verification passed"; this step asserts "the verification was not weakened to
manufacture that pass."

For each diff against the pre-change baseline (`git diff` vs the merge-base / pre-task
commit), check ALL FIVE sub-conditions. ANY violation = immediate FAIL, halt `/goal`, do NOT
proceed to the evidence-pack, do NOT claim completion:

| # | Sub-condition | Assertion (mechanical, zero AI judgment) | Violation = |
|---|---|---|---|
| **6.1** | 测试删行 = 0 | `git diff` on test files (`*.test.*` / `*_test.*` / `tests/` / `__tests__/`) — count of removed non-blank lines = 0 | immediate FAIL |
| **6.2** | skip/xfail 不激增 | count of `skip` / `xfail` / `.skip(`/`@skip` / `pytest.mark.skip` / `t.Skip` added in this diff ≥ count removed (net ≤ 0) | immediate FAIL |
| **6.3** | assert 不删 | count of removed `assert ` / `expect(` / `require.` assertion lines = 0 | immediate FAIL |
| **6.4** | 覆盖率阈值不降 | coverage threshold in config (`.coveragerc` / `jest.config` `coverageThreshold` / `go -coverprofile`) ≥ baseline | immediate FAIL |
| **6.5** | lint 配置不放宽 | lint rule count in config (eslint `.eslintrc` rules / ruff `select` / shellcheck directives) ≥ baseline; no rule downgraded `error`→`warn`→`off` | immediate FAIL |

**If baseline has no prior commit (greenfield)**: 6.1/6.3 trivially pass (nothing removed); 6.2
holds (net ≤ 0 from zero); 6.4/6.5 hold against the project's configured thresholds as-is.

**Why step 6 is appended, not folded into the 5 steps:** the upstream 5 steps answer "did the
command pass?"; step 6 answers "was the command made to pass by weakening it?" These are
different questions — folding them would muddy the verification core. Keep them separate.

## Common Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified | Test passes once |
| Agent completed | VCS diff shows changes | Agent reports "success" |
| Requirements met | Line-by-line checklist | Tests passing |

## Red Flags - STOP

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!", etc.)
- About to commit/push/PR without verification
- Trusting agent success reports
- Relying on partial verification
- Thinking "just this once"
- Tired and wanting work over
- **ANY wording implying success without having run verification**

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence ≠ evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter ≠ compiler |
| "Agent said success" | Verify independently |
| "I'm tired" | Exhaustion ≠ excuse |
| "Partial check is enough" | Partial proves nothing |
| "Different words so rule doesn't apply" | Spirit over letter |

## Key Patterns

**Tests:**
```
✅ [Run test command] [See: 34/34 pass] "All tests pass"
❌ "Should pass now" / "Looks correct"
```

**Regression tests (TDD Red-Green):**
```
✅ Write → Run (pass) → Revert fix → Run (MUST FAIL) → Restore → Run (pass)
❌ "I've written a regression test" (without red-green verification)
```

**Build:**
```
✅ [Run build] [See: exit 0] "Build passes"
❌ "Linter passed" (linter doesn't check compilation)
```

**Requirements:**
```
✅ Re-read plan → Create checklist → Verify each → Report gaps or completion
❌ "Tests pass, phase complete"
```

**Agent delegation:**
```
✅ Agent reports success → Check VCS diff → Verify changes → Report actual state
❌ Trust agent report
```

## Why This Matters

From 24 failure memories:
- your human partner said "I don't believe you" - trust broken
- Undefined functions shipped - would crash
- Missing requirements shipped - incomplete features
- Time wasted on false completion → redirect → rework
- Violates: "Honesty is a core value. If you lie, you'll be replaced."

## When To Apply

**ALWAYS before:**
- ANY variation of success/completion claims
- ANY expression of satisfaction
- ANY positive statement about work state
- Committing, PR creation, task completion
- Moving to next task
- Delegating to agents

**Rule applies to:**
- Exact phrases
- Paraphrases and synonyms
- Implications of success
- ANY communication suggesting completion/correctness

---

# codesop 代码阶段验证扩展（v9 R5/R6/R8/R9）

> 以下为 codesop patch 在 Gate Function 之上增加的代码阶段流程。Gate Function 五步（含
> Step 6 diff 守护）跑完后，AI 基于「验证结果 + spec 对照」整理证据包，再走 deliver-gate
> 风险分级。Gate Function = 验证流程；证据包 = AI 整理；职责清楚，不侵入验证核心。

## A. AI 证据包组装（Gate Function 跑完后）

Gate Function 五步 + Step 6 diff 守护**全过后**，工作 AI 把验证结果与 spec 对照，整理成
证据包。证据包 schema 字段引用共享 `_evidence-pack-schema.md`（sibling 文件，setup 同步到
skill 目录；不在此重复定义，字段以 §-号引用）。

### A.1 证据包三块（schema §1，逐字照搬 spec §4.1）

| 块 | 名称 | 内容 |
|---|---|---|
| **(a)** | 逐条判定 | spec §引用 + spec 原文摘录（直接复制不改写）+ 产物位置（`<file>:<line>`）+ 判定（`满足`/`没满足`/`顾虑`）+ 顾虑（advisory，仅当判定=`顾虑`） |
| **(b)** | 未覆盖扫描 | 扫全 spec，列没出现在代码产物的需求（表：§引用 / 未覆盖原文 / 性质） |
| **(c)** | 跨模型审查栏 | codex 审查结果（见 §C R9） |

**判定口径统一**：`满足` / `没满足` / `顾虑`（替 ✅/⚠️/❌）。

### A.2 不可缩减边界字段（schema §5，与完成条件同定义）

证据包 (a) 逐条判定**必须含不可缩减边界字段**（当 spec 条目涉及边界时）。判定口径
mechanical、零 AI 判断（与 Step 6 diff 守护同落点）：

| 边界字段 | mechanical 判定 |
|---|---|
| **测试覆盖率不降** | `coverage_after >= coverage_before` |
| **不删测试** | 测试文件删除行计数 = 0（Step 6.1 diff 守护） |
| **lint 规则数不减** | lint 配置规则数 ≥ baseline（Step 6.5） |

**防古德哈特**：完成条件判满足但边界违反 → 整条判失败（防 AI 满足表面完成条件但偷删测试/降覆盖率/放宽 lint）。

### A.3 independent vs 工作谁出（schema §6.3）

证据包 (a)(b) 喂 **independent-AI** 锚点——独立 subagent 出（挡同类脑补，非干活 AI）；
测试/lint/diff 由 /goal 每轮机械跑（mechanical 锚点）。工作 AI 整理证据包用于
deliver，但 (a)(b) 判定结论由独立 subagent 出（spec §5 #3，工作 AI 不写结论）。

## B. 完成条件外部锚点 AND（v9 R6）

**核心原则**：完成条件只认**外部锚点信号**，**不认 AI 自述**。

### B.1 四项 AND

```
完成条件 = 测试全过 AND lint 零违规 AND 独立 subagent 证据包 blocking 清零 AND spec-coverage 未覆盖扫描 = 空
```

| 分级 | 信号 | AI 判断成分 |
|---|---|---|
| **mechanical**（机器跑） | 测试 / lint / diff（Step 6） | 零 AI 判断 |
| **independent-AI** | 独立 subagent 证据包 (a)(b) | 独立 AI（非干活 AI） |
| **human** | deliver-gate 人审（语义偏离最后防线，见 §C） | 人 |

### B.2 mechanical 下限（spec §4.6）

完成条件 AND 里，**至少一项 mechanical**（测试或 lint）——不能全靠 independent-AI。证据包
(a)(b) = independent-AI；测试/lint = mechanical；两者 AND 才算满足。

### B.3 复杂度分级（spec §4.6）

| 复杂度 | 完成条件 AND |
|---|---|
| **simple** | 测试全过 + lint 零违规（spec 短，spec-coverage 无意义，跳过证据包） |
| **moderate / complex** | 测试全过 + lint 零违规 + 独立 subagent 证据包 blocking 清零 + spec-coverage 未覆盖 = 空（**全四项 AND**） |

四项全真 = 满足；任一假 = `/goal` 继续循环修，不判满足（spec §8 降级表：spec-coverage 非空 → /goal 继续修）。

## C. deliver-gate 风险分级（v9 R5）

按 spec 声明的风险分级（v9 R1 三件之一：每条 spec 需求必带风险分级 low/high）：

| 风险 | deliver-gate | codex 复核 |
|---|---|---|
| **low** | 四项 AND 全真 → **自动过**（deliver-gate 不拦） | 可选（非强制） |
| **high** | **强制人审**——四项 AND 全真也**不可自动过** | **强制**（见 R9 §C.1） |

### C.1 codex high-risk 强制（v9 R9，与 T3 brainstorming 一致）

deliver **high-risk** codex 必复核：

- high-risk「满足」条目 codex **必复核**，**不得标"跳过"**
- codex 真不可用 → high-risk「满足」条目**降级 advisory**（人定夺），**不自动判满足**
- codex 可用时**顺带跨模型扫未覆盖**（补同模型盲点；结果并入 (b) 复核）
- 非高-risk：codex 不可用 → 本栏标「codex 不可用，降级 advisory」(c)，advisory 给人可见，**不静默丢锚点**

**与 T3 brainstorming 一致**（spec 阶段 high-risk 强制）；与 T4 writing-plans spec-coverage
同 schema、同 AND 锚点。三阶段 high-risk 路径统一：codex 强制 + 人审，不可静默跳过。

## D. advisory 语义（防漂移）

- 判定=`顾虑` ≠ 阻塞。**advisory = 标给人看，人决定阻不阻塞**（spec §4.1 / §6）
- `/goal` 完成条件 AND（§B）只清 **blocker / major**（independent-AI 锚点为真）；advisory
  顾虑**保留**进 deliver-gate
- 人收到的永远是「blocking 已清、AND 全真」的证据包——**人不审 blocking（那是 AI 的活），
  只做最终定夺 + high-risk 强制人审**（deliver-gate 风险分级 §C）

## The Bottom Line

**No shortcuts for verification.**

Run the command. Read the output. Run Step 6 diff 守护. THEN assemble the evidence-pack.
THEN check the four-anchor AND. THEN route deliver-gate by risk grade.

This is non-negotiable.
