# Spec-as-Goal v2（扎实版，待 codex 审 + 人 spec-gate）

**日期**：2026-06-29
**状态**：Draft v2（dogfood §6：本文每条变更点自带完成条件 + 边界 + 风险分级）
**定位**：spec 三次循环 v7/v8 的**方向演进**，覆盖 v7（不留两份真相源）。保留三层锚点 / 证据包 / spec 标杆 / AI 自证循环；新增：① 三 human-gate 降级 ② `/goal` 接管 spec 后执行 ③ 五条古德哈特防御 ④ pipeline/skill 角色转换 ⑤ spec 即目标文件。
**关联**：`2026-06-27-spec-as-truth-full-pipeline.md`（v7）、卡兹克《Loop Engineering》（mp.weixin.qq.com/s/omwt7d9BSFX7kotW9vo9bQ）

---

## 1. 背景

### 1.1 v7 现状
三次循环（spec / plan / 代码），三次等权 human-gate。plan T1/T2 已落地（SKILL 核心准则 + evidence-pack schema），T3-T7 待执行。

### 1.2 问题
- 三次人审过重，与卡兹克"定义好目标即放手"命题相悖。
- v7 §4.5 AI 自证循环 + §8「相信 AI」把"blocking 满足判定"签字权留在干活 AI 手里，压在古德哈特线上。
- v7 §4.3 允许 codex 不可用即降级跳过，跨模型锚点可被绕过。

### 1.3 命题
> 定义好目标（完成条件 + 边界），可放手交给 /goal 循环执行；目标定义好不好决定 /goal 成败。

推论：**spec 立住后，spec 本身就是可喂 /goal 的目标文件。** spec 质量是整条链天花板。

---

## 2. 核心：spec 即 `/goal` 目标文件

### 2.1 分水岭

```
模糊需求 ──[pipeline 主导：造目标]──▶ spec 立住 ──[/goal 主导：跑目标]──▶ 交付
            brainstorming→spec                    /goal 循环 + 外部锚点验证
```

spec 前 = 造目标（pipeline 主导，/goal 插不上手）；spec 后 = 跑目标（/goal 主导，pipeline 退为验证层）。

### 2.2 spec 之后按复杂度二分

| 复杂度 | spec 立住后路径 | 人审次数 |
|---|---|---|
| **simple** | spec → **spec-gate（硬审）** → /goal（deliver 自动过） | 1 |
| **moderate / complex** | spec → **spec-gate（硬审）** → plan（依赖拓扑编排）→ plan-gate（默认过+advisory）→ /goal → deliver-gate（high risk 人审） | 1 硬 + 1 可选 + 1 条件 |
| **trivial / 探索 / 调试** | 不进 spec-as-goal | — |

**complex 多走 plan 的本质**：不是流程教条，是复杂度管理——复杂任务依赖拓扑（先后/并行/风险点）若让 /goal 边跑边拆，AI 长链拓扑判断弱易拆错；plan 把拓扑**预先理清**，/goal 在清晰拓扑上才稳。simple 无复杂依赖，跳过。

### 2.3 复杂度判定标准（钉死，复用不另造）
复用 `writing-plans-SKILL.md` 现有 complexity assessment 阈值：
- **trivial**：不进 spec-as-goal → 直接干 / systematic-debugging
- **simple**：进，spec→goal（跳 plan 编排）
- **moderate**：进，spec→plan（轻量编排）→goal
- **complex**：进，spec→plan（完整编排）→goal，deliver-gate high risk 强制人审

### 2.4 spec-gate 铁律
无论 simple/complex，**spec-gate 是唯一不可省的人审**——审的是"目标定义够不够"。没审就 /goal = 放大没定义好的目标。

**spec-gate rubric（审质量不只审字段齐）**：
- **可验证性**：每条完成条件有可执行验证命令或明确外部信号（不是"优化一下"）
- **反例/边界**：每条边界覆盖至少一条"缩减/钻空子"路径（防古德哈特）
- **不可缩减边界**：测试覆盖率不降 / 不删测试 / lint 规则数不减 等硬约束，与完成条件同定义
- **风险分级校准**：low/high 有理由（low=纯重构/无 public 行为变；high=改 public/跨模块/外部接口），不空分
- **traceability**：每条需求→完成条件可追溯（无悬空需求/完成条件）

"齐"防空字段；rubric 防空泛完成条件 / 伪机器验证 / 边界遗漏 / 风险错分。**spec 质量是 /goal 天花板，spec-gate 是天花板检查。**

---

## 3. 三 human-gate 降级规则

| gate | v7 | spec-as-goal |
|---|---|---|
| **spec-gate** | 人审 | **唯一硬审，做重**——审"完成条件+边界+风险分级是否齐" |
| **plan-gate** | 人审 | **降级**：AI 自证清零后默认通过；人只扫 advisory，不阻塞 |
| **deliver-gate** | 人审 | **风险分级**：low risk（simple/纯重构）自动过；high risk（改 public 行为/跨模块/外部接口）强制人审 |

减的是"人审 blocking"（纯浪费，机器能判），不是"人审语义偏离"（防 AI 脑补 spec 没写的，机器判不了）。**全程人随时可叫停**（非放飞）。

---

## 4. pipeline / skill 在 /goal 范式下的新角色

### 4.1 spec 前：skill = 必走步骤
brainstorming→spec 是 /goal 替代不了的（/goal 要已定义好的目标）。这一段 **强化**，不砍。

### 4.2 spec 后：skill = 完成条件引用的验证信号
朴素 /goal 完成条件：`测试全过 + lint 零违规`
spec-as-goal 完成条件：`测试全过 + lint 零违规 + verification 证据包 blocking 清零 + spec-coverage 未覆盖扫描=空`

后两项是 skill 的**输出**。AI 路径自由，但每轮必须让**独立 agent** 产出这些信号，AND 起来才算满足。

### 4.3 skill 命运分化
- `brainstorming` / `verification` → **强化**（前者造目标、后者是 /goal 完成条件核心验证器）
- `writing-plans` / `SDD` / `TDD` → **降级**为 /goal prompt 里的"优先路径"软偏好，非硬门

### 4.4 反直觉点
纯 /goal（不用 skill）能跑通，但慢、贵、易跑偏——无方法论会乱试。skill 提供"高效执行路径"，/goal 完成条件提供"正确性下限"，两个层次不替代。

### 4.5 codesop ↔ /goal 协同机制（落地 /goal 范式 + v8 认知沉淀）

> **/goal 范围声明**：`/goal` 是 Claude Code **v2.1.139+ 官方命令**（设完成条件、Claude 每轮循环跑 + 独立评估是否达标，类 `while` 循环）。codesop **依赖它、不另造**——§8 兜底 /goal 不可用（命令缺失 / 宿主不支持 / dispatch 失败）的降级。

spec-as-goal 的 /goal 不是孤立命令，是 codesop spec-gate 后衔接的执行引擎。

**协同四步**：
1. **启动**：spec-gate 硬审通过 → codesop SKILL 指示 AI 调 `/goal`，目标 = spec 文件（§6 三件齐：完成条件+边界+风险分级）
2. **完成条件**（spec 写明，/goal 每轮评估，外部锚点 AND）：测试全过 + lint 零违规 + 独立 subagent 证据包 blocking 清零（按 _evidence-pack-schema）+ spec-coverage 未覆盖扫描 = 空
3. **每轮信号产出**（codesop skill 作方法论，/goal 主循环执行）：改代码 → 跑测试/lint → 派独立 subagent 出证据包（dispatch，三块）→ spec-coverage 扫描（读 spec §需求 + 产物对照）→ 评估完成条件 AND，未达标继续循环
4. **退出 → deliver-gate**：/goal 达标退出 → codesop 指示 deliver-gate（spec §风险分级：low 自动过 / high 强制人审）

降级接 §8（/goal 死循环 N 轮未收敛 / R8 diff 守护触发 / R9 codex 不可用 high-risk → 停 + 升级人）。

**关键分工**：/goal 主循环的 Claude = 执行者；codesop skill（verification Gate Function / brainstorming reviewer / _evidence-pack-schema）= 它每轮调用的方法论。完成条件 AND 保证正确性下限，skill 保证高效路径。

**v8 认知沉淀**（v8 §4.5 AI 自证循环的演进）：
- v8 的「AI 自证循环」（codesop 内 blocking 清零才升级人）→ v9 演进为 **/goal 完成条件**（外部锚点 AND，不认 AI 自述）——从「AI 自证」升级到「外部信号证」，更抗古德哈特（§5 #3 独立验证 agent / #4 跨模型强制）
- **实施约束（v8 踩坑）**：reviewer / 证据包 prompt 必须**内联进主 SKILL.md**——setup `patch_skills()` 只同步主 SKILL.md，不同步 skill 子文件（如 spec-document-reviewer-prompt.md）。v9 plan 遵守此约束。

### 4.6 /goal 可执行契约 + 完成条件分级 + 信号分级（codex 审 Critical 补）

**调用模板**：codesop SKILL 指示 AI 调 `/goal "<spec §完成条件的 AND 表达>"`，condition 必须含外部锚点（见信号分级）。/goal 每轮自评 condition。

**每轮协议**：/goal 评估 condition → dispatch 独立 subagent 出证据包（按 _evidence-pack-schema，**内联进主 SKILL.md**）→ 写 `.superpowers/goal-evidence/round-N.md` → 评估 AND，未达标继续循环。

**退出协议**：condition AND 全真 → /goal 退出 → codesop SKILL 接管，读最后一轮证据包 → deliver-gate（按风险分级）。/goal 连续 N 轮（默认 10）未收敛 → 停 + 升级人。

**失败码**：dispatch 失败 / condition 不可评估 → 停 + 升级人（**不静默改走普通执行**）。

**完成条件按复杂度分级**（修 simple vs spec-coverage 冲突，codex Critical 2）：
- **simple**：测试全过 + lint 零违规（spec 短，spec-coverage 无意义）
- **moderate / complex**：测试全过 + lint 零违规 + 独立 subagent 证据包 blocking 清零 + spec-coverage 未覆盖 = 空

**信号分级**（修"外部锚点混入 AI 判断"，codex Important）：
- **mechanical**（机器跑，零 AI 判断）：测试 / lint / diff
- **independent-AI**：独立 subagent 证据包（挡同类脑补，不绝对）
- **human**：deliver-gate 人审（语义偏离最后防线）
完成条件 AND 里，**至少一项 mechanical**（测试或 lint），不能全靠 independent-AI。

**schema 内联约束**（修 v8 同步风险，codex Critical 4）：`_evidence-pack-schema.md` 是**源码模板**，安装时（setup patch_skills）**内联进主 SKILL.md**——避 patch_skills 只同步主 SKILL.md 的子文件盲区。R7 落点含此内联。

---

## 5. 五条古德哈特防御（落到改点）

**核心原则：完成条件只认外部锚点信号，不认 AI 自述。**

| # | 防御 | 落点（文件/章节） | 验证 |
|---|---|---|---|
| 1 | **不可缩减边界** | evidence-pack schema（§6 三件之一）+ verification patch | schema 含「测试覆盖率不降/不删测试/lint 规则数不减」边界字段 |
| 2 | **diff 守护** | verification patch（Gate Function 增一步） | 每轮 `git diff` 断言：测试文件删除行 = 立即判失败 |
| 3 | **独立验证 agent** | evidence-pack schema（§4.1 已有）+ 三阶段 dispatch | 证据包由独立 subagent 出，干活 AI 不写结论（patch 文本约束） |
| 4 | **跨模型强制** | brainstorming patch codex 入口 + verification patch | high-risk「满足」条目 codex 必复核，**不得标"跳过"**（修 v7 §4.3） |
| 5 | **抽样人审** | SKILL.md（可选，先 soft） | 1/N 随机让人扫，审计式威慑 |

---

## 6. spec 格式升级（spec 即目标文件）

spec 每条需求必须自带三件：
- **完成条件**：可机器验证（不是"优化一下"，是"test/auth 全过 + tsc 零报错"）
- **边界**：防古德哈特，与完成条件同时定义
- **风险分级**：low / high，决定 deliver-gate 是否人审

证据包 (a) 逐条判定升级：判定口径 + **引用 spec 写明的完成条件**（不再凭 spec 原文主观判）。

---

## 7. 变更点清单（R 列表）—— 本 spec dogfood §6

> 每条可直接喂 plan 拆 task，每条完成条件机器可验证。`落点` 指向执行中 plan 的 Task。
>
> **验证强度**：R1/R2/R4 的完成条件不止 grep 文本存在——需**行为测试**（brainstorming 真产三件 / spec-gate 真硬审 / plan-gate 真不阻塞 re-entry），用 golden prompt 输出测试或 dispatch 实测。grep 是下限，行为是实质。

| R | 变更 | 完成条件（机器可验证） | 边界 | 风险 | 落点 |
|---|---|---|---|---|---|
| **R1** | spec 产出自带三件（完成条件+边界+风险分级） | brainstorming patch 产出含三件字段；`grep` 三件关键字 ≥ 阈值 | 不破坏 spec 现有结构 | high | T3 |
| **R2** | spec-gate 硬审做重 | SKILL.md 含"spec-gate 审三件是否齐"规则 | spec-gate 不可省（§2.4） | medium | T1/T6 |
| **R3** | simple 跳 plan / moderate+complex 走 plan | writing-plans patch 按 complexity 分流；simple 路径无 spec-coverage 编排（对齐 §4.6 simple 完成条件无 spec-coverage） | simple 仍过 spec-gate | high | T4 + SKILL/router（simple 跳 plan 是 codesop 路由逻辑，不止 writing-plans） |
| **R4** | plan-gate 降级（默认过+advisory） | SKILL.md plan-gate 规则=自证清零后默认过、只扫 advisory | 不阻塞 re-entry | medium | T6 |
| **R5** | deliver-gate 风险分级 | verification patch deliver-gate 按 spec 风险分级分流（low 自动/high 人审） | high risk 不可自动过 | high | T5 |
| **R6** | 完成条件引用外部锚点信号 | verification patch 证据包完成条件=测试+lint+独立subagent证据包+spec-coverage未覆盖=空，AND | 独立 subagent 出证据包，干活 AI 不写结论 | high | T5/T2 |
| **R7** | 不可缩减边界 | evidence-pack schema + verification patch 含边界字段（测试覆盖率不降等） | 作为 /goal 边界条件与完成条件同定义 | medium | T2/T5 |
| **R8** | diff 守护 | verification patch Gate Function 含 diff 断言：测试删除行 + **test weakening**（skip/xfail 激增 / assert 删除 / 覆盖率阈值下降 / lint 配置放宽 / fixture 瘦身）= 立即判失败 | 断言失败立即停 /goal | medium | T5 |
| **R9** | 跨模型强制（修 v7 §4.3 漏洞） | brainstorming/verification patch：high-risk「满足」条目 codex 必复核，不得跳过 | codex 真不可用→该条目降级 advisory（人定夺），不自动判满足 | medium | T3/T5（T3 spec 阶段 codex + T5 deliver-gate high-risk codex 复核） |
| **R10** | 抽样人审（soft） | SKILL.md 含 1/N 抽样人审规则：默认 N=5，每 5 次 deliver 随机抽 1 次强制人扫证据包，记 `.superpowers/audit-log.md` | 先 advisory，不强制，但 N 可配 | low | T6（可选） |
| **R11** | spec 变更重走（保留 v7 §5） | SKILL.md 含"人改 spec→回 ① 重走"规则 | 不搞失效标记 | low | T1 |

---

## 8. 失败降级（卡兹克框架③）

| 场景 | 降级方案 |
|---|---|
| codex 不可用 | (c) 栏标"跳过"；但 **R9**：high-risk「满足」条目降级 advisory，**不自动判满足**，升级人定夺 |
| /goal 死循环（N 轮未收敛） | 停，升级人，附最近一轮证据包 + 已尝试路径 |
| 人不在场、deliver-gate high-risk 卡住 | **暂停，不自动合并**，等人回（high-risk 不允许无人交付） |
| diff 守护检测到测试删减（R8） | 立即停 /goal，按不可缩减边界判失败 |
| spec-coverage 未覆盖扫描非空（R6） | /goal 继续修，不判满足 |
| **/goal 不可用**（命令不存在 / 宿主不支持 / dispatch subagent 失败） | 回退 v8-style pipeline（codesop 主导逐步执行 + 三 gate）**或**停止升级人——**不静默改走普通执行**（§4.6 失败码） |

---

## 9. 边界（何时走 spec-as-goal）
见 §2.3 复杂度判定。核心：trivial/探索/调试 不走；simple 走轻量（跳 plan）；moderate/complex 走完整。

---

## 10. 明确不做

| 不做 | 为什么 |
|---|---|
| 完全无人交付（取消 deliver-gate） | spec 没覆盖的 AI 会脑补，语义锚必须留 |
| 纯 /goal 不用任何 skill | 慢/贵/易跑偏（§4.4） |
| spec 后仍把 skill 当必走步骤 | 范式转换：spec 后 skill=验证信号，非指令 |
| 加 PreToolUse hook 强制 | 延续 v7 §8：外部锚点信号已够，hook 是死规则、不抗钻空子 |
| 删 brainstorming / verification | 两者 spec-as-goal 下强化 |
| 另造 complexity assessment | 复用 writing-plans 现有（§2.3） |

---

## 11. spec 自验收（dogfood §6）

本 spec 合格的判定（spec 即目标文件，目标即含完成条件）：
- ☑ 每条 R 自带完成条件（§7）——是，均可 grep/命令验证
- ☑ 每条 R 自带边界（§7）——是
- ☑ 每条 R 自带风险分级（§7）——是
- ☑ 完成条件引用外部锚点信号而非 AI 自述（§5/R6）——是
- ☑ 含失败降级（§8）——是
- ☐ codex 跨模型审（待，R9 必走）——未做，下一步
- ☐ 人 spec-gate（待）——未做，下一步

---

## 12. 与 v7 及执行中 plan 的关系

**保留**：三层锚点、证据包、spec 标杆、AI 自证循环。
**覆盖 v7**：spec-as-goal 为新真相源，v7 标记 superseded（不删，留追溯）。
**对 plan T1-T7 影响**：见 §7 `落点` 列。T1/T2 不返工（兼容）；T3-T6 按 R1-R10 调整；T7 加验证项。

---

## 13. Domain Language
- **spec 即目标文件**：spec 自带完成条件+边界+风险分级，可喂 /goal
- **分水岭**：spec 立住——前=造目标（pipeline），后=跑目标（/goal）
- **验证信号**：skill 输出嵌入 /goal 完成条件的外部锚点
- **不可缩减边界**：防古德哈特硬约束，与完成条件同定义
- **风险分级 gate**：deliver-gate 按 low/high 决定是否人审
- **抽样人审**：1/N 随机审计，威慑式非阻断式
