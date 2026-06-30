# Spec 三次循环 Implementation Plan

> ⚠️ **SUPERSEDED** —— v8 实施暂停于 T4（T1-T4 commit 在 `feat/spec-three-cycles` 分支留参考）。转向 v9 spec-as-goal。v8 认知沉淀进 v9 spec + plan。不继续 T5-T7（v9 要按 /goal + 风险分级重设计这部分）。

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 spec v7（三次循环 + 三层外部锚点 + human-gate）落地成 codesop 对 superpowers 6.0.3 的补丁。

**Architecture:** 不重造，改 skill 文本 + patch 体系。三次循环（spec/plan/代码）各插入「独立 subagent 出证据包 → 可视化给人 → human-gate 确认」；证据包 subagent 复用升级现有 reviewer；gate 靠 skill 文本约束（同 superpowers user review gate），不上 hook。

**Tech Stack:** bash（codesop CLI/patch）、skill markdown、superpowers subagent dispatch、visual companion（start-server.sh + HTML）、codex:rescue。

## Global Constraints
- 只改 patches/superpowers/ + SKILL.md + setup + tests，不动 superpowers upstream cache（setup 同步覆盖）
- 相信 AI 能力：skill 文本约束，不上 PreToolUse hook 强制
- 不另造：复用现有 spec-coverage / spec-document-reviewer / verification Gate Function / codex:rescue / visual companion
- 产品契约不变（/codesop + init/update/uninstall）
- patch 改完跑 `bash setup --host claude` 同步 + `bash tests/run_all.sh` 验证

---

## File Structure
- **Modify**: `SKILL.md` — 核心准则（spec 标杆 + 三次循环 + 相信 AI）+ human-gate 机制 + 边界 + 明确不做
- **Modify**: `patches/superpowers/brainstorming-SKILL.md` — spec 阶段：替换 spec-document-reviewer 成证据包 schema（保留维度）+ codex:rescue 必走接入 + spec-gate
- **Modify**: `patches/superpowers/writing-plans-SKILL.md` — plan 阶段：spec-coverage 扩 moderate + 判定口径统一 + plan-gate
- **Create**: `patches/superpowers/verification-before-completion-SKILL.md` — 代码阶段：Gate Function 输出证据包 + deliver-gate
- **Modify**: `setup` — patch_skills 加 verification patch 同步
- **Create**: `patches/superpowers/_evidence-pack-schema.md` — 证据包 schema 共用模板（§4.1 三块 + visual companion HTML 片段模板）
- **Create/Modify**: `tests/` — 验证三阶段 dispatch + gate + 口径

---

## Acceptance Criteria

    G1: SKILL.md 写入核心准则（spec 标杆贯穿、三次循环、相信 AI 前提）
        Given: SKILL.md 是 /codesop 真相源
        When: 读 SKILL.md
        Then: 含「spec 标杆」「三次循环」「相信 AI 能力（skill 文本约束，不上 hook）」三条
        Verify: `grep -c "spec 标杆\|三次循环\|相信 AI" SKILL.md` ≥ 3
        Boundary: 明确写「不上 PreToolUse hook 强制」
        Covers: R1

    G2: 证据包 schema 共用模板定义三块 + 字段
        Given: patches/superpowers/_evidence-pack-schema.md 存在
        When: 读该文件
        Then: 含 (a) 逐条判定（§引用+原文摘录+产物位置+判定+顾虑[advisory]）(b) 未覆盖扫描 (c) 跨模型审查栏
        Verify: `grep -c "原文摘录\|未覆盖扫描\|跨模型审查栏\|advisory" patches/superpowers/_evidence-pack-schema.md` ≥ 4
        Boundary: 顾虑标 advisory（人决定阻塞）
        Covers: R3, R4

    G3: 证据包可视化走 visual companion（start-server + HTML 片段模板）
        Given: 证据包 subagent 要可视化
        When: 调用证据包机制
        Then: 调 brainstorming/scripts/start-server.sh --project-dir --open + 写 HTML content fragment 到 screen_dir
        Verify: schema 模板含 start-server.sh 调用 + HTML 片段示例
        Covers: R7

    G4: brainstorming spec-document-reviewer 替换成证据包 schema（保留原有检查维度）
        Given: brainstorming 现有 spec-document-reviewer-prompt.md（completeness/consistency/clarity/scope/YAGNI）
        When: patch 应用后
        Then: reviewer prompt 输出 §4.1 证据包 schema，且保留 completeness/consistency/clarity/scope/YAGNI 检查
        Verify: `grep -c "completeness\|consistency\|clarity\|scope\|YAGNI" patches/superpowers/brainstorming-*.md` 不减少 + 含证据包字段
        Boundary: 不丢原有检查维度
        Covers: R5(spec)

    G5: brainstorming ① codex:rescue 必走接入（spec 自审后、user review gate 前）
        Given: spec 阶段
        When: spec 自审完成
        Then: 调 codex:rescue 跨模型审，结果并入证据包 (c) 跨模型审查栏；codex 不可用时标「跳过」不阻塞
        Verify: brainstorming patch 含 codex:rescue 调用步骤 + 降级说明
        Boundary: codex 不可用降级
        Covers: R6

    G6: writing-plans spec-coverage 扩到 moderate（现只 complex）
        Given: writing-plans 现状 spec-coverage 只 complex（行 403 "Only complex tasks reach this section"）
        When: patch 应用后
        Then: moderate 也走 spec-coverage（tier 路由行 280/403 改）
        Verify: `grep -c "Only complex" patches/superpowers/writing-plans-SKILL.md` 减少 / moderate 路径含 spec-coverage
        Covers: R5(plan)

    G7: 判定口径统一（满足/没满足/顾虑）替 ✅/⚠️/❌，改三处 prompt
        Given: 现有 spec-coverage / spec-document-reviewer / plan-document-reviewer 用 ✅/⚠️/❌
        When: patch 应用后
        Then: 三处 prompt 判定口径统一为 满足/没满足/顾虑
        Verify: writing-plans-SKILL.md 内联的 ✅/⚠️/❌ 判定语义替成「满足/没满足/顾虑」（实测：emoji 原在 writing-plans-SKILL.md 内联，改这些；`grep -c "满足\|没满足\|顾虑" patches/superpowers/writing-plans-SKILL.md` 出现）
        Covers: R5(口径), D

    G8: verification Gate Function 输出证据包（复用现有 gate，不新造 subagent）
        Given: verification-before-completion 现有 Gate Function 五步
        When: patch 应用后
        Then: Gate Function 输出按 §4.1 证据包 schema（不新增执行单元/subagent）
        Verify: verification patch 含证据包输出 + 不新增 subagent dispatch
        Boundary: 不违反 §8「不另造」
        Covers: R5(代码)

    G9: 三个 human-gate 接 TaskList/re-entry（spec-gate/plan-gate/deliver-gate）
        Given: codesop pipeline 是 TaskList 自动 re-entry
        When: re-entry 到 gate task
        Then: skill 指示 AI 停下、出证据包、问人确认；人确认后才 re-entry 下一个（同 brainstorming user review gate 模式）
        Verify: SKILL.md 含三 gate 的 task 创建规则 + 「AI 不得自动 complete gate，人确认才走」
        Boundary: gate task 阻塞 re-entry（skill 文本约束）
        Covers: R9

    G10: spec 变更重走循环（spec 改 → 回 ① 重走 ②③）
        Given: spec 立住后改
        When: 人改 spec
        Then: 回到 ① 重走 ②③（不搞失效标记）
        Verify: `grep "重走\|回到" SKILL.md` 含 spec 变更规则
        Covers: R8

    G11: 边界（moderate/complex 走、simple 短审批、trivial/探索/调试 不走）
        Given: 任务分级
        When: 判定是否走三次循环
        Then: moderate/complex 走完整；simple 短设计审批（spec 仍人确认）；trivial/探索/调试 不走
        Verify: SKILL.md 含边界规则
        Covers: R10

    G12: 明确不做清单（SCR/硬合同/分级/强制gate/另造workflow/另造subagent/四列对照/hook/失效标记）
        Given: §8
        When: 读 SKILL.md
        Then: 含「明确不做」清单
        Verify: `grep -c "SCR\|硬合同\|hook 强制\|失效标记" SKILL.md` ≥ 1（在「不做」语境）
        Covers: R11

    G13: tests 覆盖 + setup sync + 全绿
        Given: patch 改完
        When: 跑 bash setup --host claude + bash tests/run_all.sh
        Then: patch 同步到 cache + 所有测试通过
        Verify: `bash setup --host claude && bash tests/run_all.sh` exit 0
        Boundary: 路由卡一致性测试（codesop-router.sh）仍绿
        Covers: 验证

## Complexity Assessment
**Level:** complex
**File estimate:** 7（SKILL.md + 3 patch + setup + schema 模板 + tests）
**Modules:** brainstorming / writing-plans / verification / codesop SKILL / setup
**Override:** 改多 skill 行为（public 行为变化）+ 跨 skill patch

## Task Outline

- **T1: SKILL.md 核心准则 + 边界 + 不做**
  - AC: G1, G10, G11, G12
  - Deps: none
  - Reqs: R1, R8, R10, R11
  - Files: `SKILL.md`

- **T2: 证据包 schema + visual companion 共用模板**
  - AC: G2, G3
  - Deps: none
  - Reqs: R3, R4, R7
  - Files: `patches/superpowers/_evidence-pack-schema.md`

- **T3: brainstorming patch（spec 阶段：reviewer 替换 + codex 必走 + spec-gate）**
  - AC: G4, G5
  - Deps: T2
  - Reqs: R5(spec), R6, R9(spec-gate)
  - Files: `patches/superpowers/brainstorming-SKILL.md`（+ 可能新建 reviewer prompt patch）

- **T4: writing-plans patch（plan 阶段：spec-coverage 扩 moderate + 口径统一 + plan-gate）**
  - AC: G6, G7
  - Deps: T2
  - Reqs: R5(plan), R5(口径), R9(plan-gate)
  - Files: `patches/superpowers/writing-plans-SKILL.md`

- **T5: verification patch（代码阶段：Gate Function 证据包 + deliver-gate）**
  - AC: G8
  - Deps: T2
  - Reqs: R5(代码), R9(deliver-gate)
  - Files: `patches/superpowers/verification-before-completion-SKILL.md`（新建 patch）+ `setup`（patch_skills 加同步）

- **T6: human-gate 接 TaskList/re-entry（三 gate 共用机制）**
  - AC: G9
  - Deps: T3, T4, T5（三 gate 都要接）
  - Reqs: R9
  - Files: `SKILL.md`（Pipeline Re-entry 段加 gate 规则）

- **T7: tests + setup sync + 验证**
  - AC: G13
  - Deps: T1-T6
  - Reqs: 验证
  - Files: `tests/` + `setup`

## Requirement Traceability
| Req | Spec § | Task | Status |
|-----|--------|------|--------|
| R1 核心准则 | §1.3,§2,§3 | T1 | ✅ |
| R2 三次循环 | §2 | T1,T3,T4,T5 | ✅ |
| R3 证据包三块 | §4.1 | T2 | ✅ |
| R4 逐条判定字段 | §4.1 | T2 | ✅ |
| R5 三阶段 dispatch | §4.2 | T3(spec),T4(plan),T5(代码) | ✅ |
| R6 codex 入口 | §4.3 | T3 | ✅ |
| R7 visual companion 复用 | §4.4 | T2 | ✅ |
| R8 spec 变更重走 | §5 | T1 | ✅ |
| R9 三个 human-gate | §6 | T3,T4,T5,T6 | ✅ |
| R10 边界 | §7 | T1 | ✅ |
| R11 明确不做 | §8 | T1 | ✅ |

---

## Task Details (Stage 2 expansion)

### Task 1: SKILL.md 核心准则 + 边界 + 不做
**Goal:** 把 spec 标杆 / 三次循环 / 相信 AI 写成 codesop 核心准则
**Files:** `SKILL.md`
**Implementation brief:**
- §1/§9 Iron Laws 加四条：① spec 标杆贯穿全程 ② 三次循环（AI 自证→可视化→人确认）③ 相信 AI（skill 文本约束，不上 hook 强制）④ **AI 自证循环**（证据包 blocking 必修完才升级 gate，原则 0 机制闭环）—— 直接写机制名「AI 自证循环」，**不引用 spec §4.5 编号**（避免和 SKILL.md 现有 §4.5「Complete Example」混）
- §3 加 spec 变更规则：spec 改了（人主动）→ 回 ① 重走 ②③，不搞失效标记
- §7 边界：moderate/complex 走完整循环；simple 短设计审批（spec 仍人确认）；trivial/探索/调试 不走
- §8 加「明确不做」清单：SCR/硬合同/分级/强制gate/另造workflow/另造证据包subagent/四列对照/hook强制/失效标记
**Validation:** G1 (`grep "spec 标杆\|三次循环\|相信 AI" SKILL.md` ≥3), G10, G11, G12

### Task 2: 证据包 schema + visual companion 共用模板
**Goal:** 定义证据包三块 + 可视化调用模板，供 T3/T4/T5 复用
**Files:** `patches/superpowers/_evidence-pack-schema.md`（新建）
**Implementation brief:**
- (a) 逐条判定字段：§引用 + spec 原文摘录（直接复制不改写）+ 产物位置（plan task / 代码 file:行 / spec 阶段=§自身）+ 判定（满足/没满足/顾虑）+ 顾虑（advisory，人决定阻塞）
- (b) 未覆盖扫描：扫全 spec 列没出现在产物的需求
- (c) 跨模型审查栏：codex 输出归位
- visual companion 调用模板：`bash brainstorming/scripts/start-server.sh --project-dir <proj> --open` → 拿 screen_dir → 写 HTML content fragment（mermaid 全链路 + 判定卡片 + 未覆盖 + 跨模型栏）→ 浏览器 serve
- HTML 片段示例 + mermaid 加载 script（`<script src="mermaid CDN">` + `mermaid.run()`）
**Validation:** G2 (schema 含三块+advisory), G3 (含 start-server 调用 + HTML 模板)

### Task 3: brainstorming patch（spec 阶段）
**Goal:** spec 自审 → codex 必走 → 证据包 → spec-gate
**Files:** `patches/superpowers/brainstorming-SKILL.md`（**内联** reviewer prompt，不新建子文件 patch）
**Implementation brief:**
- 在 spec self-review 后、user review gate 前插入：① 调 codex:rescue 跨模型审（必走，不可用降级）② 派证据包 subagent，prompt **内联在 brainstorming-SKILL.md**（含 §4.1 schema + 五维度 completeness/consistency/clarity/scope/YAGNI **及其校准段 + Output Format，完整内容从 upstream `brainstorming/spec-document-reviewer-prompt.md` 行 19-34 复制**——不只写五个裸标签），**不新建子文件 patch**（避开 patch_skills 只同步主 SKILL.md 的盲区）③ 证据包走 visual companion ④ AI 自证循环：blocking 先修完才 spec-gate
- Edge: reviewer 内联进主 SKILL.md（patch_skills 同步主文件，跨项目可用）；不丢原有检查维度
**Validation:** G4 (brainstorming-SKILL.md 内联证据包 reviewer + 保留维度), G5 (含 codex:rescue + 降级)

### Task 4: writing-plans patch（plan 阶段）
**Goal:** spec-coverage 扩 moderate + 口径统一 + plan-gate
**Files:** `patches/superpowers/writing-plans-SKILL.md`
**Implementation brief:**
- spec-coverage review 从 complex 扩到 moderate：改 tier 路由（行 280 Lightweight Plan 分流 + 行 403 "Only complex tasks reach this section"），让 moderate 也走 spec-coverage
- 判定口径统一：spec-coverage prompt 的 ✅/⚠️/❌ → 满足/没满足/顾虑（引用 T2 schema）
- plan-gate：spec-coverage 后出证据包（走 visual companion）问人确认
- Edge: moderate 走 spec-coverage 但用轻量版（不强制 implementation brief 全展开）
**Validation:** G6 (moderate 含 spec-coverage), G7 (三处 prompt 口径统一)

### Task 5: verification patch（代码阶段）
**Goal:** AI 基于 Gate Function 结果 + spec 整理证据包 → deliver-gate
**Files:** `patches/superpowers/verification-before-completion-SKILL.md`（新建 patch）+ `setup`（patch_skills 加同步）
**Implementation brief:**
- **Gate Function 不改**（现有五步验证：测试/lint/build，照跑）
- Gate Function 跑完后，**AI 基于「验证结果 + spec 对照」整理成 §4.1 证据包**（证据包是 AI 输出，不是 Gate Function 输出——Gate Function = 验证流程，证据包 = AI 整理，职责清楚，不侵入验证核心）
- deliver-gate：交付前出证据包 + 浏览器（UI）→ §4.5 自证循环 blocking 清零 → 问人确认
- setup patch_skills() 加 verification patch 同步
- Edge: 不改 Gate Function 核心；证据包是独立 subagent 整理（符 §4 三层锚点）
**Validation:** G8 (Gate Function 不变 + AI 整理证据包)

### Task 6: human-gate 接 TaskList/re-entry
**Goal:** 三 gate 接 codesop 现有 pipeline，靠 skill 文本约束停
**Files:** `SKILL.md`（§3 Pipeline Re-entry 段）
**Implementation brief:**
- 三 gate（spec-gate/plan-gate/deliver-gate）的 task 创建规则：产出 task → gate task → 下阶段 task（下阶段 blockedBy gate）
- skill 文本约束：re-entry 到 gate task 时，AI 停下、出证据包、问人确认；**人确认才 TaskUpdate(completed)**（同 brainstorming user review gate 模式，靠 AI 遵守 skill 文本，不上 hook）
- Edge: gate 是 skill 文本约束（§1.3 相信 AI），不声称技术强制
**Validation:** G9 (SKILL.md 含三 gate 创建规则 + 人确认才走)

### Task 7: tests + setup sync + 验证
**Goal:** 验证三阶段 dispatch + gate + 口径 + 全绿
**Files:** `tests/`（新测试）+ `setup`
**Implementation brief:**
- 加测试：三阶段 dispatch（spec/plan/代码 各出证据包）、gate task 创建、口径统一、schema 模板存在
- `bash setup --host claude` 同步所有 patch 到 cache
- `bash tests/run_all.sh` 全绿（含 codesop-router.sh 路由卡一致性）
- Edge: patch 同步后 cache 文件 = patch 源（diff 零差异）
**Validation:** G13 (`bash setup --host claude && bash tests/run_all.sh` exit 0)
