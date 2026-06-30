# Spec-as-Goal v9 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** 把 spec-as-goal v9（spec 即 /goal 目标文件 + 三 gate 降级 + 五条古德哈特防御 + codesop↔/goal 协同）落地成 codesop 对 superpowers 6.0.3 的补丁 + SKILL.md。复用 v8 已验证的认知（内联 reviewer / evidence-pack schema 三块 / emoji→文字口径 / AI 自证循环），不返工从零。

**Architecture:** 不重造，改 skill 文本 + patch 体系。spec 立住 = 分水岭：前造目标（codesop+brainstorming），后跑目标（Claude Code `/goal` 主导，codesop 退为验证/gate 层）。/goal 是 Claude Code v2.1.139+ 命令，codesop 依赖不造。

**Tech Stack:** bash（codesop CLI/patch）、skill markdown、superpowers subagent dispatch、visual companion（start-server + HTML）、codex:rescue、Claude Code `/goal` 命令。

## Global Constraints
- 只改 `patches/superpowers/` + `SKILL.md` + `setup` + `tests`，不动 superpowers upstream cache（setup 同步覆盖）
- **reviewer / schema 必须**内联进主 SKILL.md**——setup `patch_skills()` 只同步主 SKILL.md，不同步 skill 子文件（v8 踩坑：spec-document-reviewer-prompt.md 子文件 patch 不生效）。`_evidence-pack-schema.md` 是源码模板，安装时内联
- **/goal 是 Claude Code v2.1.139+ 命令**，codesop 依赖不另造（§8 兜底 /goal 不可用降级）；不扩 codesop 产品契约（仍 /codesop + init/update/uninstall）
- 完成条件认**外部锚点**（mechanical 下限：测试/lint/diff），不认 AI 自述
- 复用现有（spec-coverage / Gate Function / codex:rescue / visual companion / schema 模板），不另造
- patch 改完跑 `bash setup --host claude` 同步 + `bash tests/run_all.sh` 验证
- 相信 AI 能力：skill 文本约束，不上 PreToolUse hook 强制

## File Structure
- **Modify**: `SKILL.md` — /goal 范式准则 + gate 降级 + spec-gate rubric + spec 变更重走 + 抽样人审 + /goal 协同启动/退出
- **Modify**: `patches/superpowers/brainstorming-SKILL.md` — spec 产三件 + codex 强制 + 内联 reviewer
- **Modify**: `patches/superpowers/writing-plans-SKILL.md` — simple 跳 plan + 复杂度分流 + emoji→文字口径
- **Create**: `patches/superpowers/verification-before-completion-SKILL.md` — deliver-gate 风险分级 + 完成条件外部锚点 AND + diff 守护 + codex high-risk
- **Create**: `patches/superpowers/_evidence-pack-schema.md` — 三块 + 不可缩减边界 + 外部锚点（源码模板，安装时内联）
- **Modify**: `setup` — patch_skills 加 verification 同步 + schema 内联逻辑
- **Modify**: `tests/` — 行为测试（R1-R4 golden prompt/dispatch 实测）+ setup sync + run_all

## Acceptance Criteria

    G1: SKILL.md 写入 /goal 范式准则
        Given: SKILL.md 是 /codesop 真相源
        When: 读 SKILL.md
        Then: 含「spec 立住=分水岭（前造目标/后跑目标）」「/goal 主导执行」「codesop 退为验证层」
        Verify: `grep -c "分水岭\|/goal\|验证层" SKILL.md` ≥ 3
        Covers: R2(部分), R11

    G2: spec-gate rubric（审质量不只字段齐）
        Given: spec-gate 是唯一硬人审
        When: 读 SKILL.md spec-gate 段
        Then: 含 rubric 五项——可验证性/反例边界/不可缩减边界/风险分级校准/traceability
        Verify: `grep -c "可验证性\|反例\|不可缩减\|traceability" SKILL.md` ≥ 3
        Covers: R2

    G3: evidence-pack schema 三块 + 边界 + 外部锚点 + 内联
        Given: _evidence-pack-schema.md 存在
        When: 读该文件
        Then: 含 (a)逐条判定 (b)未覆盖扫描 (c)跨模型栏 + 不可缩减边界字段 + 外部锚点 AND + 内联声明
        Verify: `grep -c "原文摘录\|未覆盖扫描\|跨模型\|不可缩减\|外部锚点\|内联" patches/superpowers/_evidence-pack-schema.md` ≥ 5
        Covers: R6, R7

    G4: brainstorming spec 产三件 + codex 强制 + 内联 reviewer
        Given: brainstorming patch 应用后
        When: spec 自审阶段
        Then: spec 产出含完成条件+边界+风险分级；high-risk codex 必复核不跳过；reviewer 内联主 SKILL.md
        Verify: `grep -c "完成条件\|边界\|风险分级" patches/superpowers/brainstorming-SKILL.md` ≥ 3 + 含 codex high-risk 强制 + 无新建子文件 patch
        Covers: R1, R9

    G5: writing-plans simple 跳 plan + 复杂度分流 + emoji 口径
        Given: writing-plans patch 应用后
        When: 按 complexity 路由
        Then: simple 跳 plan 编排直接 /goal；moderate/complex 走 plan；判定口径 满足/没满足/顾虑
        Verify: `grep -c "满足\|没满足\|顾虑" patches/superpowers/writing-plans-SKILL.md` 出现 + simple 路径无 spec-coverage
        Covers: R3

    G6: verification deliver-gate 风险分级
        Given: verification patch 应用后
        When: 交付前
        Then: deliver-gate 按 spec 风险分级（low 自动过 / high 强制人审）
        Verify: verification patch 含风险分级分流 + high risk 不可自动过
        Covers: R5

    G7: 完成条件外部锚点 AND
        Given: /goal 完成条件
        When: 评估达标
        Then: =测试全过 + lint 零违规 + 独立 subagent 证据包 blocking 清零 + spec-coverage 未覆盖=空（moderate/complex）；至少一项 mechanical
        Verify: verification patch 含完成条件 AND + mechanical 下限
        Covers: R6

    G8: diff 守护 + test weakening
        Given: verification Gate Function
        When: 每轮跑
        Then: 断言——测试删行 / skip-xfail 激增 / assert 删 / 覆盖率阈值降 / lint 配置放宽 = 立即失败
        Verify: verification patch 含 diff 守护 + test weakening 5 子项
        Covers: R8

    G9: /goal 协同（启动/完成条件/退出/deliver-gate 衔接）
        Given: spec-gate 通过
        When: codesop 指示调 /goal
        Then: 调用模板 + 每轮 dispatch 证据包 + 退出读最后证据包→deliver-gate + 失败码不静默
        Verify: SKILL.md 含 /goal 协同四步（§4.5/4.6）
        Covers: §4.5/4.6

    G10: /goal 不可用降级
        Given: /goal 命令缺失/宿主不支持/dispatch 失败
        When: /goal 不可用
        Then: 回退 v8-style pipeline 或停止升级人，不静默改走普通执行
        Verify: SKILL.md 含 /goal 不可用降级（§8）
        Covers: §8

    G11: 抽样人审（soft）
        Given: deliver 多次
        When: 第 N 次（默认 5）
        Then: 随机抽 1 次强制人扫证据包，记 audit-log
        Verify: SKILL.md 含 1/N 抽样规则 + audit-log
        Covers: R10

    G12: 行为测试 + setup sync + 全绿
        Given: patch 改完
        When: 跑 setup --host claude + tests/run_all.sh
        Then: patch 同步到 cache（含 verification + schema 内联）+ 所有测试通过 + R1-R4 行为测试（golden prompt/dispatch 实测，不只 grep）
        Verify: `bash setup --host claude && bash tests/run_all.sh` exit 0 + R1-R4 行为测试在 tests/
        Covers: R1-R4 行为测试, 验证

## Complexity Assessment
**Level:** complex
**File estimate:** 7（SKILL.md + 3 patch + setup + schema 模板 + tests）
**Modules:** brainstorming / writing-plans / verification / codesop SKILL / setup
**Override:** 改多 skill 行为（/goal 范式转换）+ 跨 skill patch + 新 verification patch

## Task Outline

- **Task 1: SKILL.md /goal 范式准则 + gate 降级 + spec 变更重走**
  - AC: G1, G2, G10
  - Deps: none
  - Files: `SKILL.md`

- **Task 2: evidence-pack schema（三块 + 边界 + 外部锚点 + 内联）**
  - AC: G3
  - Deps: none
  - Files: `patches/superpowers/_evidence-pack-schema.md`

- **Task 3: brainstorming patch（spec 产三件 + codex 强制 + 内联 reviewer）**
  - AC: G4
  - Deps: Task 2
  - Files: `patches/superpowers/brainstorming-SKILL.md`

- **Task 4: writing-plans patch（simple 跳 plan + 复杂度分流 + emoji 口径）**
  - AC: G5
  - Deps: Task 2
  - Files: `patches/superpowers/writing-plans-SKILL.md`

- **Task 5: verification patch（deliver-gate 风险分级 + 外部锚点 + diff 守护 + codex）**
  - AC: G6, G7, G8
  - Deps: Task 2
  - Files: `patches/superpowers/verification-before-completion-SKILL.md` + `setup`

- **Task 6: SKILL human-gate + /goal 协同（spec-gate rubric + plan-gate 降级 + deliver 分级 + 抽样 + /goal 启动/退出）**
  - AC: G9, G11（+ G2 spec-gate rubric 落地 + plan-gate 降级 R4）
  - Deps: Task 3, 4, 5（三 gate 都要接 + /goal 协同）
  - Files: `SKILL.md`

- **Task 7: tests + setup sync + 验证**
  - AC: G12
  - Deps: Task 1-6
  - Files: `tests/` + `setup`

## Task Details

### Task 1: SKILL.md /goal 范式准则 + gate 降级 + spec 变更重走
**Goal:** 把 v9 /goal 范式（分水岭 + gate 降级 + spec 变更重走）写成 codesop 核心准则
**Files:** `SKILL.md`
**Implementation brief:**
- §1 加 /goal 分水岭：spec 立住前=造目标（codesop+brainstorming），后=跑目标（/goal 主导，codesop 退为验证/gate 层）
- gate 降级规则：spec-gate 唯一硬审 / plan-gate 自证清零后默认过（只扫 advisory）/ deliver-gate 风险分级（low 自动/high 人审）
- spec 变更重走（R11）：人改 spec → 回 ① 重走，不搞失效标记
- /goal 不可用降级（G10/§8）：命令缺失/宿主不支持 → 回退 v8-style pipeline 或停止升级人，不静默
- 直接写机制名，不引用 spec 章节号（避免和 SKILL.md 现有章节混）
**Validation:** G1 (`grep "分水岭\|/goal\|验证层" SKILL.md` ≥3), G2(rubric), G10(降级)

### Task 2: evidence-pack schema（三块 + 边界 + 外部锚点 + 内联）
**Goal:** 定义证据包三块 + 不可缩减边界 + 外部锚点 AND，供 T3/T5 复用
**Files:** `patches/superpowers/_evidence-pack-schema.md`（新建，源码模板）
**Implementation brief:**
- (a) 逐条判定：§引用 + 原文摘录 + 产物位置 + 判定（满足/没满足/顾虑）+ 顾虑（advisory）
- (b) 未覆盖扫描：扫 spec 列没出现在产物的需求
- (c) 跨模型审查栏：codex 输出归位
- **不可缩减边界字段**（R7）：测试覆盖率不降 / 不删测试 / lint 规则数不减
- **外部锚点 AND**（R6）：完成条件 = 测试+lint+证据包+spec-coverage，至少一项 mechanical
- visual companion 调用模板 + HTML 片段（mermaid script 原样：CDN + mermaid.run()）
- 文件头声明：源码模板，**安装时 setup 内联进主 SKILL.md**（避 patch_skills 子文件盲区）
**Validation:** G3 (三块+边界+锚点+内联声明)

### Task 3: brainstorming patch（spec 产三件 + codex 强制 + 内联 reviewer）
**Goal:** spec 阶段产自带三件 + codex high-risk 强制 + 内联证据包 reviewer
**Files:** `patches/superpowers/brainstorming-SKILL.md`
**Implementation brief:**
- spec 产出**自带三件**（R1）：完成条件（可机器验证）+ 边界（防古德哈特）+ 风险分级（low/high）
- codex:rescue **high-risk 强制**（R9）：high-risk「满足」条目 codex 必复核，不得标"跳过"；codex 真不可用→该条目降级 advisory（人定夺），不自动判满足
- 证据包 reviewer prompt **内联进主 brainstorming-SKILL.md**（v8 踩坑：不新建 spec-document-reviewer-prompt 子文件 patch）；五维度+校准+Output Format 从 upstream 完整复制（不只裸标签）
- 引用 Task 2 _evidence-pack-schema（不重复定义）
**Validation:** G4 (三件 + codex 强制 + 内联 + 无新建子文件)

### Task 4: writing-plans patch（simple 跳 plan + 复杂度分流 + emoji 口径）
**Goal:** plan 阶段按复杂度分流 + 判定口径统一
**Files:** `patches/superpowers/writing-plans-SKILL.md`
**Implementation brief:**
- **simple 跳 plan**（R3）：simple 直接 /goal（无 spec-coverage 编排）；moderate/complex 走 plan 编排依赖拓扑
- 判定口径统一：✅⚠️❌ → 满足/没满足/顾虑（v8 认知，判定语义处全替）
- 复杂度判定复用 writing-plans 现有 complexity assessment（不另造）
**Validation:** G5 (simple 跳 plan + 分流 + 口径)

### Task 5: verification patch（deliver-gate 风险分级 + 外部锚点 + diff 守护 + codex）
**Goal:** 代码阶段 deliver-gate 风险分级 + /goal 完成条件外部锚点 + diff 守护
**Files:** `patches/superpowers/verification-before-completion-SKILL.md`（新建）+ `setup`（patch_skills 加同步）
**Implementation brief:**
- **Gate Function 不改核心**（v8 认知），跑完 AI 基于「验证结果 + spec 对照」整理证据包
- **deliver-gate 风险分级**（R5）：按 spec 风险——low 自动过 / high 强制人审（high 不可自动过）
- **完成条件外部锚点 AND**（R6）：测试+lint+独立 subagent 证据包 blocking 清零+spec-coverage 未覆盖=空；至少一项 mechanical
- **diff 守护 + test weakening**（R8）：测试删行 / skip-xfail 激增 / assert 删 / 覆盖率阈值降 / lint 配置放宽 = 立即判失败
- **codex high-risk 复核**（R9）：deliver high-risk codex 必复核
- setup patch_skills() 加 verification patch 同步
**Validation:** G6 (分级), G7 (外部锚点 AND), G8 (diff 守护)

### Task 6: SKILL human-gate + /goal 协同
**Goal:** 三 gate 机制 + /goal 协同四步落地
**Files:** `SKILL.md`
**Implementation brief:**
- **spec-gate rubric 落地**（R2/G2）：审五项——可验证性/反例边界/不可缩减边界/风险分级校准/traceability
- **plan-gate 降级**（R4）：自证清零后默认过，人只扫 advisory 不阻塞 re-entry
- **/goal 协同四步**（§4.5/4.6/G9）：① spec-gate 通过→指示调 /goal（condition=spec 完成条件 AND）② 每轮 dispatch 独立 subagent 出证据包→写 .superpowers/goal-evidence/round-N.md ③ 达标退出→读最后证据包→deliver-gate ④ N 轮未收敛/dispatch 失败→停+升级人（失败码不静默）
- **deliver-gate 分级**（R5）：接 Task 5 verification
- **抽样人审**（R10/G11）：1/N（默认 5）随机抽 deliver 强制人扫，记 .superpowers/audit-log.md
**Validation:** G9 (/goal 协同), G11 (抽样), G2 (rubric 落地)

### Task 7: tests + setup sync + 验证
**Goal:** 行为测试 + setup sync + 全绿
**Files:** `tests/` + `setup`
**Implementation brief:**
- **R1-R4 行为测试**（不只 grep）：golden prompt 输出测试（brainstorming 真产三件 / spec-gate 真硬审 / plan-gate 真不阻塞 / simple 真跳 plan）+ dispatch 实测
- setup patch_skills 加 verification 同步 + schema 内联逻辑（_evidence-pack-schema.md 安装时内联进主 SKILL.md）
- `bash setup --host claude` + `bash tests/run_all.sh` 全绿
- 路由卡一致性测试（codesop-router.sh）仍绿
**Validation:** G12 (行为测试 + sync + run_all exit 0)

## Requirement Traceability

| 需求 | R | AC | Task |
|---|---|---|---|
| spec 即目标文件（自带三件） | R1 | G4 | T3 |
| spec-gate 硬审做重（rubric） | R2 | G1,G2 | T1/T6 |
| simple 跳 plan / 复杂度分流 | R3 | G5 | T4 |
| plan-gate 降级 | R4 | G6(Task6 plan-gate) | T6 |
| deliver-gate 风险分级 | R5 | G6 | T5/T6 |
| 完成条件外部锚点 AND | R6 | G3,G7 | T2/T5 |
| 不可缩减边界 | R7 | G3 | T2/T5 |
| diff 守护 + test weakening | R8 | G8 | T5 |
| 跨模型强制（high-risk codex） | R9 | G4 | T3/T5 |
| 抽样人审 | R10 | G11 | T6 |
| spec 变更重走 | R11 | G1 | T1 |
| /goal 协同 | §4.5/4.6 | G9 | T6 |
| /goal 不可用降级 | §8 | G10 | T1 |

## v8 认知复用（不返工）
- **内联 reviewer**（v8 T3 踩坑）：reviewer/schema 必须**内联进主 SKILL.md**，patch_skills 只同步主文件——T3/T2 遵守
- **schema 三块结构**（v8 T2 验证）：_evidence-pack-schema.md (a)(b)(c) + visual companion + mermaid script——T2 复用，加边界/锚点字段
- **emoji→文字口径**（v8 T4 验证）：满足/没满足/顾虑——T4 复用
- **§4.5 AI 自证循环演进**（v8）：codesop 内 blocking 清零→v9 升级为 /goal 完成条件外部锚点 AND（更抗古德哈特）——T5/T6
