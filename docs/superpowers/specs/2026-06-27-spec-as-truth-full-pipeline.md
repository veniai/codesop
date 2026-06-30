# Spec 三次循环 v7（定稿）

> ⚠️ **SUPERSEDED by [2026-06-29-spec-as-goal.md](2026-06-29-spec-as-goal.md) (v9)** —— v8 的认知（内联 reviewer 避 patch_skills 盲区 / evidence-pack schema 三块 / §4.5 AI 自证循环 / emoji→文字口径）已沉淀进 v9。v8 编排模式（pipeline 全程 + 三 gate 人审）被 v9 /goal 范式取代。本文件留追溯，不再实施。v8 已落地的 T1-T4 在 `feat/spec-three-cycles` 分支留参考。

**日期**：2026-06-29
**状态**：Draft v7（定稿）
**版本**：v8 —— v7 + AI 自证循环（§4.5，原则 0 的机制闭环：blocking 必修完才升级人）
**关联**：superpowers brainstorming / writing-plans / SDD / verification，codesop patch

---

## 1. 背景

### 1.1 痛点
- spec 质量不满意（高杠杆点）。
- plan 漂移：调研后降级（AC phase 治大部分，没现行）。

### 1.2 定位
superpowers 已是完整 spec 驱动链。codesop 打补丁，不重造。

### 1.3 设计前提
**相信 AI 能力**：superpowers 现有 skill 文本 gate 已证明 AI 会遵守。不上技术强制，靠 skill 文本 + AI 遵守。

---

## 2. 核心：一个循环，重复三次

```
AI 用工具干到自认没问题 → 可视化给人定夺 → 人确认 → 定稿
```

| 阶段 | AI 自证 | 人定夺 |
|---|---|---|
| **① spec** | workflow 多视角 + codex 跨模型审 | 可视化 → 确认 → **spec 立住** |
| **② plan** | 对照 spec（轻量，AC phase 已治大部分） | 可视化 → 确认 → **plan 立住** |
| **③ 代码** | 测试 + 对照 spec（一致性） | 可视化（UI 浏览器 / 后端 mermaid + 证据包）→ 确认 → **交付** |

**spec 改了（人主动发起）→ 回到 ① 重走 ②③。**

---

## 3. 贯穿主线
spec 是标杆：plan / 代码必须满足 spec。

---

## 4. AI 自证 + 证据包
三层外部锚点：干活 AI → 独立 subagent 出证据包 → codex 跨模型审 → 人定夺。

### 4.1 证据包内容（三块）
- **(a) 逐条判定**：§引用 + spec 原文摘录 + 产物位置 + 判定（满足 / 没满足 / 顾虑）+ 顾虑（顾虑 = advisory，标给人看，人决定阻不阻塞，同 §6）
- **(b) 未覆盖扫描**：扫全 spec，列没出现在产物的需求
- **(c) 跨模型审查栏**：codex 审查结果

### 4.2 三阶段 dispatch（复用升级，不另造）
证据包 subagent **复用 writing-plans 现有 spec-coverage subagent**，prompt 升级成 §4.1 schema：
- **spec 阶段**：**替换** brainstorming 现有 spec-document-reviewer prompt 成证据包 schema（**保留原有检查维度** placeholder / ambiguity / consistency / scope / YAGNI，仅改输出格式；user review gate 前）
- **plan 阶段**：writing-plans spec-coverage subagent（升级版，扩到 moderate）
- **代码阶段**：verification-before-completion 的 **Gate Function 输出证据包**（Gate Function = 复用现有完成前 gate，仅改输出格式为证据包，不新增函数 / 执行单元；符合 §8）
- **统一判定口径**（满足 / 没满足 / 顾虑，替 ✅/⚠️/❌）

### 4.3 codex 入口
- **① spec 必走 codex:rescue**；**②③ 可选**（risk:high）；**adversarial 不自动**（用户手动）。
- **codex 不可用** → (c) 栏标「codex 不可用，跳过」，(a)(b) 照出，不阻塞。
- codex 可用时 **(c) 栏顺带跨模型扫未覆盖**（补同模型盲点）。
- 输出并入 (c) 跨模型审查栏。

### 4.4 可视化（复用 brainstorming visual companion）
证据包 subagent 走 brainstorming 的 visual companion 路线：调 `brainstorming/scripts/start-server.sh --project-dir --open`，拿 screen_dir，写 HTML content fragment（证据包可视化：mermaid 全链路 + 判定卡片 + 未覆盖扫描 + 跨模型栏）到 screen_dir，浏览器 serve 给人定夺。

### 4.5 AI 自证循环（原则 0 的机制闭环）
证据包 subagent 出证据包后，**AI 先自己消化**：
- 有 **blocker / major** → AI 回对应阶段修产物（spec 改 spec / plan 改 plan / 代码改代码）→ 重出证据包 → 重审
- 循环直到 blocker / major **清零**（只剩 advisory 顾虑）
- **才升级 human-gate 给人**

人收到的永远是「blocking 已清」的证据包——**人不审 blocking（那是 AI 的活），只做最终定夺**。这是原则 0 的机制落地：不把半成品扔给人找 bug。

---

## 5. spec 变更
spec 改了（**人主动发起**）→ 回到 ① 重走 ②③。不搞失效标记机制（常识：人改了 spec 自然让 AI 重做下游）。

---

## 6. 三个 human-gate
**spec-gate / plan-gate / deliver-gate**。re-entry 到 gate 时 skill 指示 AI 停下、出证据包（§4）、问人确认（同 brainstorming user review gate）。AI 遵守 skill 文本，人确认后才 re-entry 下一个。

**gate 收到的是 §4.5 AI 自证循环后、blocking 已清的证据包**——人只看 advisory 顾虑做定夺，不审 blocking。

---

## 7. 边界
- **走三次循环**：moderate / complex 有设计任务。
- **simple**：短设计审批（不是完整三次循环，但 spec 仍要人确认）。
- **不走**：trivial / 探索 / 调试。

---

## 8. 明确不做
| 不做 | 为什么 |
|---|---|
| SCR 系统 | git diff + 重走循环 |
| 硬合同体系 | 相信 AI 如实出证据包 |
| 分级系统 | 复用 writing-plans 现有 complexity assessment |
| 三次强制 visual companion gate | 按需：UI 开 companion、后端 mermaid |
| 另造 spec 审查 workflow | 用现有 codex:rescue |
| 另造证据包 subagent | 复用升级 spec-coverage subagent |
| plan 四列重型对照 | 降级：AC phase 已治漂移 |
| PreToolUse hook 强制 gate / 防作假硬约束 | 相信 AI 能力 |
| spec 变更失效标记机制 | 人改 spec 自然重走 |

---

## 9. Domain Language
- **三次循环**：spec / plan / 代码，每轮 AI 自证 + 人定夺。
- **spec 标杆**：plan / 代码必须满足。
- **三层外部锚点**：独立 subagent / codex / 人。
- **证据包**：(a) 逐条判定 + (b) 未覆盖扫描 + (c) 跨模型审查栏。
- **human-gate**：三次定稿点，skill 文本约束（同 superpowers user review gate）。
