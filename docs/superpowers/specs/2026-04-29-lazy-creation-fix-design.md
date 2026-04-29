# Lazy-Creation 死规则修复

> **日期**: 2026-04-29
> **状态**: Draft
> **范围**: CONTEXT.md 和 ADR 的懒创建触发机制修复

## 1. 问题

CONTEXT.md 和 ADR 采用懒创建策略（"不存在则静默跳过"），但分析发现存在死规则和触发缺口：

### 1.1 死信号

`AGENTS.md` 领域语言 section 中有两条信号没有接收方：

1. **"发现术语缺口时标记（signal for brainstorming 补充）"** — AI 跨会话无法持久"标记"状态，下次对话时标记丢失
2. **"发现 ADR 冲突时显式指出"** — "显式指出"后没有后续动作，AI 指出了也白指

### 1.2 ADR 触发缺口

ADR 的 `docs/adr/` 目录唯一触发点是 debug 路由的"修 bug 后追问架构反思，如有价值建议写 ADR"。但实际上 ADR 最主要的来源应该是 **brainstorming 设计阶段**（新功能、架构决策、重大权衡），这部分完全没有触发。

### 1.3 CONTEXT.md 闭环状态

CONTEXT.md 在 brainstorming 中有闭环：
- Step 3 (Grill Mode): Domain Language Delta 记录
- Step 6: spec 批准后提议写入 CONTEXT.md

闭环存在但信号端（"发现术语缺口时标记"）无效。闭环的入口已经正确：brainstorming 过程中实时记录 delta，不需要外部"标记"来触发。

## 2. 方案

**Plan B: ADR 半显式 + CONTEXT.md 保持懒创建 + 清理死信号**

### 2.1 ADR: 半显式创建

- `codesop init` 在 Phase 3 创建 `docs/adr/` 目录（含 `.gitkeep`）
- 目录存在后，AGENTS.md "先读 `docs/adr/`（如存在）" 不再是空操作
- ADR 文件本身仍懒创建（由 brainstorming 和 debug 路径触发写入）
- `templates/project/adr-template.md` 已存在，无需改动

### 2.2 Brainstorming 补充 ADR 触发

在 brainstorming patch 的 Step 5/6（设计呈现阶段）补充：
- 当设计涉及架构决策、重大权衡、多方案选择时，提示用户是否需要写 ADR
- 触发条件：设计过程中产生了非平凡的架构/技术选择

### 2.3 清理死信号

AGENTS.md 领域语言 section：
- **删除**: "发现术语缺口时标记（signal for brainstorming 补充）" — 无接收方的死信号
- **保留并改写**: "发现 ADR 冲突时显式指出" → "发现 ADR 冲突时显式指出，并建议在当前任务中解决冲突或更新 ADR"

### 2.4 CONTEXT.md: 不改

闭环已经完整（brainstorming Step 3→6），无死信号残留。

## 3. 改动清单

### 3.1 `lib/init-interview.sh` — `generate_project_files()`

在 Phase 3 文件生成末尾、`ADAPT_MODE` 输出之前，新增：

```bash
# 4. docs/adr/ — ADR directory with .gitkeep
if [ ! -d ./docs/adr ]; then
  mkdir -p ./docs/adr
  touch ./docs/adr/.gitkeep
  echo "✓ 创建 docs/adr/"
else
  echo "✓ docs/adr/ 已存在"
fi
```

位置：在 README.md 处理之后、ADAPT_MODE 判断之前（约 line 687 `# CLAUDE.md 由 Claude Code /init 生成` 注释之后、line 690 `if [ "$adapt_mode" = true ]` 之前）。

### 3.2 `patches/superpowers/brainstorming-SKILL.md`

在 Step 6 (Write design doc) 的指导文本中补充 ADR 触发。

当前 spec 批准后的流程是：写 spec → spec self-review → 用户审阅 spec。ADR 提示应在 spec 写入后、self-review 前加入，作为 spec 内容的一部分（如果适用的话）。

在 "**Documentation:**" 段落末尾（commit the design document 之后），补充：

> **ADR trigger:** When the design involved architectural decisions, significant trade-offs, or choosing between multiple approaches, check if `docs/adr/` exists in the project. If it does, suggest writing an ADR alongside the spec. Use the project's `docs/adr/` directory with format `NNNN-decision-title.md` (sections: 决策 / 上下文 / 结果). Commit the ADR with the spec.

触发条件：设计过程中产生了非平凡的架构/技术选择。简单改动不触发。

### 3.3 `templates/system/AGENTS.md`

#### 3.3.1 删除死信号

删除：
```
- 发现术语缺口时标记（signal for brainstorming 补充）
```

#### 3.3.2 改写 ADR 冲突信号

从：
```
- 发现 ADR 冲突时显式指出
```

改为：
```
- 发现 ADR 冲突时显式指出，并建议在当前任务中解决冲突或更新 ADR
```

改写后领域语言 section 完整内容：

```markdown
## 领域语言
当任务涉及需求讨论、领域术语、架构设计、跨模块改动、非平凡代码探索时：
- 先读 `CONTEXT.md`（如存在），使用词汇表术语命名
- 先读 `docs/adr/`（如存在），避免与已有架构决策矛盾
- 发现 ADR 冲突时显式指出，并建议在当前任务中解决冲突或更新 ADR
不存在则静默跳过，不提示创建。
```

### 3.4 不改的文件

| 文件 | 理由 |
|------|------|
| `templates/project/CONTEXT.md` | 闭环完整，无改动 |
| `templates/project/adr-template.md` | 已存在，格式正确 |
| `config/codesop-router.md` | 链路不需要变 |
| `SKILL.md` | 文档判定 section 不涉及 ADR 创建 |
| `lib/updates.sh` | CONTEXT.md 已从 drift 检查中移除 |

## 4. 验证

### 4.1 单元验证

- `tests/codesop-init.sh`: 确认 `docs/adr/` 目录创建测试通过
- `tests/codesop-router.sh`: 路由卡无变化，测试应保持通过
- `tests/detect-environment.sh`: AGENTS.md 内容变化后 drift 检查应通过
- `tests/run_all.sh`: 全量回归

### 4.2 集体验证

- 新项目 `codesop init` 后应有 `docs/adr/.gitkeep`
- 已有项目 `codesop init`（adapt mode）不应报错，应显示 "✓ docs/adr/ 已存在"

## 5. 影响分析

- **向后兼容**: 纯增量改动，不影响已有项目（`docs/adr/` 不存在时静默跳过）
- **setup sync**: AGENTS.md 变更需要 `setup --host claude` 重新同步
- **brainstorming patch**: 需要 `setup` 重新应用 patch
- **版本**: 变更较小，建议 v3.5.2

## 6. Scope Check

单一目标：修复 CONTEXT.md 和 ADR 的懒创建死规则。不引入新功能、不改链路结构、不改路由逻辑。
