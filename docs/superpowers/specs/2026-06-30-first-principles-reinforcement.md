# 第一性原理强化 v1（spec-as-goal，待 codex 审 + 人 spec-gate）

**日期**：2026-06-30
**状态**：spec-gate 过（人审 rubric 五项；codex 异步卡转人审，low risk simple）→ 实施中
**定位**：v9 之后的**视角强化小迭代**——内化"第一性原理"prompt 到 brainstorming（造方案）+ systematic-debugging（找根因），**不加 skill**。
**关联**：卡兹克《2 个 Vibe Coding 神级 Prompt》、PRD §2.2 候选、codesop v9（spec-as-goal 范式）

---

## 1. 背景

### 1.1 命题
AI 默认**类比推理**（照搬训练数据相似方案），跳过"这问题真该这么解吗"。第一性原理强制打断类比，回最基本事实/约束重新推导，再对比类比方案权衡。

### 1.2 codesop 现状
- `brainstorming`（codesop 已 patch，v9 改过）：造方案/spec，**无显式"第一性原理"步骤**
- `systematic-debugging`（codesop 无独立 patch，走 SKILL/路由卡排查路径）：有"无根因不修 bug"铁律，但未显式"第一性原理找根因"

### 1.3 定位
不加 skill，**内化 prompt 视角**：
- brainstorming 造方案时加"第一性原理推导"步骤（先从基本事实推，再对比类比）
- systematic-debugging 排查时强化"第一性原理找根因"（从基本事实推，不照搬"类似 bug 这样修"）

---

## 2. 变更点（R 列表，dogfood §6 三件）

| R | 变更 | 完成条件（机器可验证）| 边界 | 风险 | 落点 |
|---|---|---|---|---|---|
| **R1** | brainstorming patch 加第一性原理推导步骤 | `brainstorming-SKILL.md` 含"第一性原理"推导步骤（造方案前从基本事实/约束推，再对比类比方案权衡）；行为测试 prompt 触发推导（非直接类比照搬） | 不破坏 brainstorming 现有结构（v9 spec 三件 / codex high-risk / 内联 reviewer） | low | T1（brainstorming patch）|
| **R2** | systematic-debugging 强化第一性原理找根因 | SKILL.md / 路由卡排查路径含"第一性原理找根因"（从基本事实推根因，不照搬"类似 bug 这样修"）；强化"无根因不修 bug"铁律 | **不另造** systematic-debugging patch（走 SKILL/路由卡提示），除非落地证明需要 | low | T2（SKILL / 路由卡）|
| **R3** | 行为测试：第一性原理真触发 | `tests/` 加行为测试（brainstorming / debugging prompt 含第一性原理推导，golden-content 下限；dispatch 实测降级 dogfood） | golden-content grep 下限，dispatch 实测降级 dogfood | low | T3（tests）|

---

## 3. 边界（何时走第一性原理）
- **complex / moderate** 任务：造方案/排查复杂问题时走第一性原理推导
- **simple / trivial**：不强加（简单任务类比够快，第一性原理是负担）
- **探索 / 调试**：systematic-debugging 走第一性原理找根因（强化现有"无根因不修"铁律）

复杂度判定复用 writing-plans 现有 complexity assessment（不另造，对齐 v9 §2.3）。

---

## 4. 明确不做
- **不加新 skill**（内化 prompt 视角，brainstorming/debugging 已有骨架）
- **不强制每个任务走第一性原理**（按复杂度，simple/trivial 跳过）
- **不另造 systematic-debugging patch**（走 SKILL/路由卡提示，除非 R2 落地证明需要）
- **不上 hook 强制**（延续 v9：prompt 视角靠 skill 文本 + AI 遵守）

---

## 5. spec 自验收（dogfood §6）
- ☑ 每条 R 自带完成条件（§2，均可 grep/行为测试验证）
- ☑ 每条 R 自带边界（§2 边界列）
- ☑ 每条 R 自带风险分级（§2，全 low）
- ☑ 完成条件引用外部锚点（行为测试 grep + dispatch 实测）而非 AI 自述
- ☐ codex 跨模型审（待，下一步）
- ☐ 人 spec-gate（待，下一步）

---

## 6. 与 v9 的关系
v9 spec-as-goal 范式下，本 spec 是 spec-gate 后喂 `/goal` 的目标文件。**simple 路径**（3 R，prompt 视角强化，无复杂依赖拓扑）→ spec-gate 审 rubric 五项 → 直接 /goal 实施（跳 plan 编排）。

本 spec 同时是 **v9 首次真实 spec dogfood**——验证 v9 spec 阶段（brainstorming 造 spec 含三件 → spec-gate rubric → /goal 衔接）真工作。
