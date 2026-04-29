# codesop 领域语言层 + 架构原则增强 Spec

> **Date**: 2026-04-29
> **Scope**: 在 codesop 现有 workflow 编排能力之上，增加领域语言层（CONTEXT.md + ADR），增强 brainstorming 提问质量，合成 Clean Architecture + 深模块原则
> **Inspiration**: Matt Pocock `mattpocock/skills` (grill-with-docs, CONTEXT-FORMAT, DOMAIN-AWARENESS, ADR-FORMAT, improve-codebase-architecture)
> **Principle**: 行为提取，不是文件搬用；独立小改动，不改现有 pipeline 流程

---

## 0. 问题陈述

codesop 管得了"按什么顺序用什么 skill"，管不了"AI 和人是否在说同一件事"。

三个具体症状：
1. **术语漂移**：每次对话 AI 重新猜词，用户心里叫 Order，AI 叫 Purchase，浪费 token、制造误解
2. **需求澄清不彻底**：brainstorming Step 3 问几个问题就进方案，决策依赖没追踪，模糊点没解决
3. **架构退化无感知**：Clean Architecture 管了分层方向，但不管"这个边界值不值得存在"——机械分层产生大量只有转发的浅模块

## 1. 改什么（7 件事）

### 1.1 新增 CONTEXT.md 模板

**文件**: `templates/project/CONTEXT.md`

**职责**: 领域词汇表——压缩人机沟通的语义噪声。不是 PRD 的领域实体（PRD 说数据模型），不是 CLAUDE.md 的技术规范（CLAUDE.md 说怎么造），是"这些词到底是什么意思"。

**与现有文档的区别**:
- PRD §5.5 领域实体 → 记录数据模型（字段、类型、关系）
- CONTEXT.md → 记录术语含义（定义、避免词、模糊点）
- 不重复：PRD 说"Order 有 status 字段"，CONTEXT 说"Order 指客户提交的购买请求，不是内部调拨"

**模板结构**:
```markdown
# {Context Name}

{1-2 句描述这个上下文是什么}

## Language

**Order**:
客户提交的购买请求，包含商品列表和配送地址。
_Avoid_: Purchase, transaction

**Invoice**:
发货后发给客户的付款请求。
_Avoid_: Bill, payment request

## Relationships

- 一个 **Order** 产生一个或多个 **Invoice**
- 一个 **Invoice** 属于一个 **Customer**

## Example Dialogue

> **Dev:** "当 **Customer** 下了一个 **Order**，我们立即创建 **Invoice** 吗？"
> **Domain expert:** "不——**Invoice** 只在 **Fulfillment** 确认后才生成。"

## Flagged Ambiguities

- "account" 曾同时指 **Customer** 和 **User** — 已解决：这是两个独立概念
```

**规则**:
- Opinionated：同义词只选一个最佳，其他列 Avoid
- Definitions tight：一句话定义是什么，不是做什么
- Only domain-specific terms：通用编程概念（timeout、error type）不属于此
- Relationships 用粗体术语名 + 表达基数

**创建时机**: 懒创建。init 时不自动生成。触发条件：
- brainstorming 中首次解决术语共识时，建议创建
- 用户主动要求
- 永远不强制——简单工具库项目可以不创建

**更新规则**: 新术语不立即写入。Delta 暂存在 brainstorming spec 文件的 `## Domain Language Delta` 小节中。Spec 批准时，delta 写入 CONTEXT.md。如果项目没有 brainstorming spec（简单改动），用户明确同意时直接写入。

### 1.2 新增 ADR 机制

**目录**: 项目 `docs/adr/`，懒创建

**模板文件**: `templates/project/adr-template.md`（新增，供 AI 写 ADR 时参照）

**文件格式**: `NNNN-kebab-case.md`，编号递增。编号策略：读现有最大编号 +1。不预期并发冲突（单 AI 会话串行写入）。

**内容格式**:
```markdown
# NNNN: {标题}

## 决策

{1-3 句话：选了什么}

## 上下文

{为什么需要做这个决策}

## 结果

{选这个的后果，不选那个的后果}
```

**触发条件**（三条件全满足才写）:
1. **不可逆** — 后期改主意成本高
2. **令人意外** — 未来读者会问"为什么这样做"
3. **有真实取舍** — 存在合理的替代方案，不是因为懒

**触发场景**:
- brainstorming 设计讨论中
- 架构审查中
- debugging 复盘中（"什么架构变化本可避免这个 bug"）
- 重大重构前
- 不限于 brainstorming 触发

**创建时机**: 懒创建。需要时才建 `docs/adr/` 目录。init 时不自动创建。

**ADR 读取策略**: 当 ADR 较多时（>5），按文件名关键词 grep 相关 ADR，不全部读取。数量少时全部读取。

### 1.3 改 brainstorming patch

**文件**: `patches/superpowers/brainstorming-SKILL.md`

**机制**: 全文件替换原 skill（和现有 writing-plans、finishing-branch patch 机制一致）

**适用范围**: 仅 Claude Code（patch 作用于 plugin cache）。Codex/OpenCode 通过 AGENTS.md 系统规则获得领域语言意识，不 patch skill 文件。

**改动点**:

**Step 1 增量**（~30 words）:
探索项目时，如果 CONTEXT.md 存在则读取。如果 docs/adr/ 存在，按 §1.2 读取策略获取相关 ADR。不存在则静默跳过。

**Step 3 增量**（~250 words）:

在现有 "Ask clarifying questions" 行为基础上增加三个结构性行为：

1. **代码优先回答**: 能通过读代码回答的问题，先读代码，不问用户猜测。用户描述现有行为时，先在代码中验证再接受。

2. **决策树追踪**: 维护隐式决策树（已解决 / 待解决 / 依赖其他决策）。每个问题对应树上节点。退出条件：当 purpose / constraints / success criteria / 主要决策依赖都足够支撑 2-3 个方案时，停止追问进入 Step 4。

3. **领域词汇对齐**: 使用 CONTEXT.md 术语提问（如存在）。发现新术语共识时记入 spec 的 `## Domain Language Delta` 小节。发现术语冲突时指出。

**Step 6 增量**（~30 words）:
Spec 批准后，将 `## Domain Language Delta` 小节中的术语变更写入项目 CONTEXT.md（如用户同意）。

不改变 Step 4-5、Step 7-9。

**估算**: 原 skill ~2500 words，增量 ~310 words（12%）。

### 1.4 改 AGENTS.md 跨 skill 规则

**文件**: `templates/system/AGENTS.md`

**位置**: 在现有"文档职责"段之后新增"领域语言"段。

**内容**:
```markdown
## 领域语言
当任务涉及需求讨论、领域术语、架构设计、跨模块改动、非平凡代码探索时：
- 先读 `CONTEXT.md`（如存在），使用词汇表术语命名
- 先读 `docs/adr/`（如存在），避免与已有架构决策矛盾
- 发现术语缺口时标记（signal for brainstorming 补充）
- 发现 ADR 冲突时显式指出
不存在则静默跳过，不提示创建。
```

**澄清**: "不提示创建"针对非 brainstorming 场景（调试、代码审查等日常 skill）。brainstorming 场景中允许建议创建 CONTEXT.md（§1.1 触发条件已定义）。

**关键**: 限定场景，不是一刀切。小修小补（改个 typo、修个 lint）不需要读 CONTEXT.md。

### 1.5 改路由卡

**文件**: `config/codesop-router.md`

**约束**: 当前路由卡 72 行，测试硬限 72 行。本节改动预估净增 1-2 行（铁律 +1 行，其余同行替换不增行）。压缩方案：合并铁律段相邻短行为单行（当前铁律 4 行可压缩为 3 行）。如仍超标，更新测试阈值为 75 行并注明理由。

**改动**:

1. **brainstorming 行描述更新**（同行替换，不增行）:
   从: `任何新功能/改动前：理解需求→澄清问题→出设计方案→写 spec→spec 自审→用户审阅`
   到: `任何新功能/改动前：理解需求→grill 式术语对齐→澄清问题→出设计方案→写 spec→spec 自审→用户审阅`

2. **铁律段新增一行通用规则**:
   ```
   - 领域语言：涉及需求/架构/跨模块改动时先读 CONTEXT.md 和 ADR（如存在），用术语，发现缺口标记，发现冲突指出
   ```

3. **调试路径追加条件步骤**（不换行，追加到现有调试路径行末）:
   ```
   ；修 bug 后追问架构反思，如有价值建议写 ADR
   ```

4. **brainstorming 触发范围扩展**（同行扩展，不增行）:
   在 brainstorming 行的"什么时候用"列追加: `；架构审查/重构/模块边界`

### 1.6 改 setup patch_skills()

**文件**: `setup`

**改动**: 在 `patch_skills()` 函数中增加 brainstorming 映射：

```bash
# brainstorming: grill enhancement
local bs="$plugin_dir/skills/brainstorming/SKILL.md"
local bs_patch="$patches_dir/brainstorming-SKILL.md"
if [ -f "$bs" ] && [ -f "$bs_patch" ]; then
  if ! diff -q "$bs" "$bs_patch" >/dev/null 2>&1; then
    cp "$bs_patch" "$bs"
    patched=$((patched + 1))
  fi
fi
```

**长期方向**: 重构为扫描 `patches/superpowers/*-SKILL.md` 自动应用。本次先加一行。

### 1.7 架构原则合成

**涉及文件**: `templates/system/AGENTS.md`

**不做**: 不改 `templates/init/prompt.md`。该文件不被 init 流程消费（CLAUDE.md 由 Claude Code `/init` 生成，codesop 不介入），改动无效。

**Clean Architecture + 深模块合成原则**:

Clean Architecture 定依赖方向（什么能依赖什么）。深模块定边界质量（这个边界值不值得存在）。

合成规则:
> 每一层暴露小而稳定的接口，隐藏实现复杂度。禁止为分层制造只有转发、贫血、接口比实现还复杂的浅模块。

**AGENTS.md 新增架构原则**（和领域语言段平级）:
```markdown
## 架构原则
- Clean Architecture 定依赖方向，深模块定边界质量
- 每层暴露小而稳定的接口，隐藏实现复杂度
- 禁止为分层制造只有转发、贫血、接口比实现还复杂的浅模块
- 发现浅模块时标记（signal for 重构规划）
```

**路由卡触发场景**（§1.5 已包含，不另加行）:
brainstorming 行扩展触发范围至"架构审查/重构/模块边界"。

## 2. 执行顺序

分 5 批，每批可独立验证。关键修正：brainstorming patch（1.3）和 setup 映射（1.6）必须同一批，否则 patch 无法被应用和验证。

| 批次 | 包含 | 验证 |
|------|------|------|
| 1 | 1.1 CONTEXT.md 模板 + 1.2 ADR 模板文件 + 1.7 AGENTS.md 架构原则 | 模板文件存在、结构正确；AGENTS.md 含架构原则段 |
| 2 | 1.3 brainstorming patch 文件 + 1.6 setup patch_skills() 映射 | `bash setup --host claude` 成功应用 patch；构造 fake plugin 目录断言 patch 后文件一致 |
| 3 | 1.4 AGENTS.md 领域语言规则 + 1.7 AGENTS.md 架构原则 + §3 文档 gate 同步（SKILL.md + updates.sh） | setup 同步后新规则出现在 ~/.claude/CLAUDE.md；SKILL.md/updates.sh gate 包含 CONTEXT.md |
| 4 | 1.5 路由卡（压缩至 ≤72 行或更新测试阈值） | 路由覆盖测试通过、新触发场景可匹配、行数测试通过 |
| 5 | 版本收尾 + 全量测试 | VERSION/skill.json/PRD 版本号更新；`bash tests/run_all.sh` 全通过 |

## 3. 文档判定 gate 扩展

现有 gate 判定 CLAUDE.md / PRD.md / README.md，写死在三个地方：
- `SKILL.md` §5 completion gate 输出格式
- `templates/system/AGENTS.md` 文档判定段
- `lib/updates.sh` 的项目文档集合

**需要同步改的文件**:

| 文件 | 改什么 |
|------|--------|
| `SKILL.md` | §5 completion gate 输出格式新增可选行: `- CONTEXT.md: 领域术语、关系、模糊点变化时更新（如存在，可选）` |
| `templates/system/AGENTS.md` | 文档判定段新增 CONTEXT.md 可选判定标准 |
| `lib/updates.sh` | 项目文档集合新增 CONTEXT.md（可选检测：存在时纳入 drift scan，不存在时跳过） |

ADR（docs/adr/）不纳入 gate——它是按需创建的轻量记录，不需要每次判定。

## 4. 测试覆盖

| 测试 | 断言 |
|------|------|
| setup patch 测试 | 构造 fake plugin 目录 + brainstorming patch 文件，运行 patch_skills()，断言目标文件与 patch 一致 |
| setup 幂等测试 | 连续两次 `setup --host claude`，patch 不重复应用、patched count 稳定 |
| setup 无 plugin 测试 | 无 plugin cache 时 patch_skills() 静默跳过不报错 |
| 路由覆盖测试 | brainstorming 触发范围包含架构审查/重构/模块边界 |
| 路由行数测试 | 路由卡 ≤72 行（或更新阈值后通过） |
| 模板测试 | CONTEXT.md 模板含 Language/Relationships/Example Dialogue/Flagged Ambiguities |
| 模板测试 | ADR 模板文件存在、含决策/上下文/结果三段 |
| AGENTS.md 测试 | 领域语言段 + 架构原则段存在 |
| gate 测试 | SKILL.md/AGENTS.md/updates.sh 的文档集合包含 CONTEXT.md（可选） |
| 全量测试 | `bash tests/run_all.sh` 全部通过 |

## 5. 版本收尾

| 文件 | 改什么 |
|------|--------|
| `VERSION` | bump 至 v3.5.0（新增认知层能力） |
| `skill.json` | version 字段同步 |
| `PRD.md` | §1 当前快照更新、§2 新增 v3.5.0 版本历史、§3 决策记录 |
| `CLAUDE.md` | 架构树新增 `templates/project/CONTEXT.md`、`patches/superpowers/brainstorming-SKILL.md` |
| `README.md` | 覆盖场景新增 CONTEXT.md/ADR 说明 |

## 6. 升级维护

| 依赖 | 影响 | 处理 |
|------|------|------|
| superpowers 更新 brainstorming | brainstorming patch 需重新合并 | 和现有 writing-plans/finishing-branch 维护方式一致。合并时检查上游 security/behavior 修复不被覆盖 |
| Matt 更新 skills | 不直接依赖（行为提取不是文件搬用） | 偶尔检查是否有新行为模式值得吸收 |
| CONTEXT.md 模板变化 | init 模板更新 | 通过 codesop update 的模板 diff 检测通知 |

## 7. 风险

| 风险 | 缓解 |
|------|------|
| brainstorming patch 维护负担 | 和现有两个 patch 一致；superpowers 不频繁更新 brainstorming |
| CONTEXT.md 膨胀 | 规则限定"only domain-specific terms"，通用概念不属于此 |
| 深模块原则过于抽象 | AGENTS.md 给具体指导（"禁止只有转发的浅模块"），不是纯理论 |
| AGENTS.md 跨 skill 规则被忽略 | 规则写入系统模板（每次会话注入），不依赖 AI 记忆 |
| CONTEXT.md 与 PRD §领域实体 / PRD 决策记录 / ADR 之间真相源漂移 | CONTEXT.md 只管术语含义（是什么），PRD 管模型（有什么字段），ADR 管决策（为什么选 A 不选 B）。职责边界已明确 |
| 路由卡新增内容超 72 行测试限制 | §1.5 要求同时压缩现有内容，或更新测试阈值并注明理由 |
| 全文件替换 brainstorming 覆盖上游修复 | 合并时必须 diff 检查上游变更，手动集成 |

## 8. 不做什么

| 不做 | 为什么 |
|------|--------|
| 新增独立 grill skill | grill 行为是 brainstorming 的增强，不是新入口 |
| 搬 Matt 的 improve-codebase-architecture 为独立 skill | 太重，先以原则形式融入现有体系。等 CONTEXT/ADR 就位后再考虑完整 skill |
| 搬 caveman | 中文环境收益低，codesop 已有沟通纪律 |
| 搬 to-issues/to-prd | writing-plans + PRD.md 已覆盖 |
| CONTEXT-MAP.md（多上下文） | 过度设计，单上下文够绝大多数项目 |
| ADR 纳入文档 gate | 太重，按需轻量记录不需要每次判定 |
| 改 `templates/init/prompt.md` | 该文件不被 init 流程消费（CLAUDE.md 由 Claude Code `/init` 生成），改动无效。架构原则只走 AGENTS.md |
