# Elegance 精简优化

> **日期**: 2026-04-30
> **状态**: Draft
> **范围**: SKILL.md 和 AGENTS.md 的优雅化精简

## 1. 问题

codesop 的核心哲学是"教 AI 判断力，不教 AI 机械化"。但两个最核心的文件存在密度过高、多层叠加、策略与细节混杂的问题：

### 1.1 SKILL.md：编排器比执行器复杂

SKILL.md 331 行，超过了它编排的任何一个下游 skill。问题不是内容错误，而是策略层和实现层混在一起：

- §3 Pipeline TaskCreate 规范（~20 行）：metadata 格式、subject 模板、☆/★ 标记规则——这些是 AI 执行时的机械细节，不是策略
- §4 Default Output（~100 行）：格式要求（NEVER add dividers、exactly 4 sections）+ 完整示例——UI 规则占了 skill 定义 1/3 的篇幅
- §4.3 Pipeline Dashboard 示例（30+ 行）：proposing 和 continuing 各一套完整示例，高度重复

**后果**：AI 每次触发 codesop 都要消化 331 行，其中大量是格式指令。编排器的认知负担超过了它编排的 skill。

### 1.2 AGENTS.md 文档判定：四层叠加做同一件事

文档判定 section 有四层机制：

1. 通用判定标准（CLAUDE.md 怎么造、PRD.md 造什么...）——**语义层**
2. 变更影响矩阵（11 行表格）——**查表层**
3. 自检清单（5 条）——**checklist 层**
4. 输出格式固定（3 行模板）——**格式层**

四层都正确，但叠在一起占 40+ 行。AI 执行时倾向于机械遍历四层，而不是真正理解"什么变了 → 该改什么文档"这个核心判断。

### 1.3 其他密度问题

- AGENTS.md Skill 纪律 section 有 11 条 bullet，部分有交叉（"默认工作流"和"默认调试流"与路由表重复）
- SKILL.md §4.4 Final Line 的"两种确认句式"+"三种场景适配"+"三条规则"——策略很清晰但表达密度过高

## 2. 设计原则

**原则 1：教原则，不教步骤**
告诉 AI "为什么"和"什么时候"，让它自己判断"怎么做"。铁律是好的例子（"无证据不完工"），自检清单是反面例子（5 条硬枚举）。

**原则 2：一层语义，一层机制，不叠三层**
一个概念在一个地方定义，其他地方引用。

**原则 3：给出口，不给死路**
每条规则都有"什么时候不适用"。没有出口的规则会让 AI 在边界情况下硬套。

**原则 4：密度控制——编排器 < 执行器**
SKILL.md 不应比它编排的下游 skill 更长。目标是 < 200 行。

**原则 5：机制代码化，判断 prompt 化**
能用代码保证的不交给 AI。需要语义理解的不硬编码。分界线：能不能写测试。

## 3. 方案

### 3.1 SKILL.md 精简

#### 3.1.1 §3 Pipeline TaskCreate 规范——从 20 行指令压缩为 3 行原则

当前问题：metadata 格式、subject 模板、☆/★ 规则、衔接任务规范，都是实现细节。

改为：

```markdown
**Pipeline TaskCreate 规范**：
- 链路中每个步骤创建一个 task，subject 用指令式，有 skill 的标注 Skill 调用
- 顺序创建，第 N+1 个 blockedBy 第 N 个
- 衔接任务（无 skill）：从上下文推断该做什么，完成后标记 completed
```

AI 不需要被告知 metadata 键名和 ☆/★ 标记规则——它能从示例和上下文推断。

#### 3.1.2 §3 衔接任务——创建分支——从 6 行压缩为 2 行

当前：subject 模板、metadata 格式、执行指令（推断分支名、git checkout）、worktree 覆盖。

改为：

```markdown
**衔接任务 — 创建分支**：
- 新功能链路且当前在 main/master 时，在 writing-plans 后、开发前插入
- 用户说"用 worktree"时改为 worktree
```

执行细节（推断分支名、git 命令）AI 自己知道。

#### 3.1.3 §4 Default Output——从 ~100 行压缩为 ~40 行

核心改动：
- 保留 4 section 结构和末行规则（这是 contracts）
- 删除所有 "NEVER" 格式禁令——AI 从示例推断格式
- 压缩示例：只保留一个 complete example，删除 proposing/continuing 分开示例
- §4.2 Skill Ecosystem 的三种分支输出用一句话覆盖

改为的 §4 结构：

```markdown
## 4. Default Output

4 个 section，按顺序：
1. `## 工作台摘要` — 状态 + 分支，异常时加 **注意**
2. `## Skill 生态` — routing coverage 一行
3. `## 下一步建议` — pipeline dashboard（提议用编号列表，继续中用 ☑/☐）
4. **末行** — 确认句或继续执行

末行规则：首次确认时问"要...吗？"，pipeline 执行中不问，自动继续。
```

然后接一个精简的 complete example（~15 行）。

#### 3.1.4 §3 Pipeline Re-entry——保持不变

这 5 步是核心流程，密度合理，不改动。

### 3.2 AGENTS.md 文档判定精简

#### 3.2.1 四层合并为两层

保留：
1. **语义层**（每个文档管什么）——保留，这是原则
2. **格式层**（输出模板）——保留，这是 contract

合并：
3. **查表层**（变更影响矩阵）→ 降级为参考。AI 理解了语义层后，矩阵是查表辅助，不是必走流程
4. **checklist 层**（自检清单）→ 删除。5 条 checklist 是矩阵的子集——如果 AI 理解了"什么改动影响什么文档"，不需要枚举"新增文件→检查 CLAUDE.md 架构树"

改写后的文档判定 section：

```markdown
## 文档判定
任务结束前判定 CLAUDE.md / PRD.md / README.md 是否需要更新。

判定原则：
- `CLAUDE.md` 管技术：架构、命令、规范、目录、环境、交付
- `PRD.md` 管产品：目标、范围、验收标准、进度、决策
- `README.md` 管使用：安装、运行、配置、部署、接口
- 纯重构/测试/格式化且不改变上述信息时，三者均可标记"未更新"

输出：
- `CLAUDE.md: 已更新 / 未更新，原因：...`
- `PRD.md: 已更新 / 未更新，原因：...`
- `README.md: 已更新 / 未更新，原因：...`

若需更新，优先调用 claude-md-management skill。
```

从 ~40 行压缩到 ~12 行。删掉矩阵和 checklist，AI 用语义层的 3 个"管什么"定义 + 自己的判断力来决定。

### 3.3 AGENTS.md Skill 纪律精简

当前 11 条 bullet 有交叉。"默认工作流"和"默认调试流"与路由表重复。

改写：

```markdown
## Skill 纪律
- 新任务先输出任务对齐块：`理解` + `阶段` + `Skill`
- skill 有 ≥1% 适用可能时，先加载 skill 再行动
- 路由以路由表为准；pipeline task 指定的 skill 必须通过 Skill tool 调用
- 已确认的 pipeline task list 等于授权全程执行，完成后自动 re-entry
- 跳过了应走的 skill 时，用户指出后立即重走 pipeline
```

从 11 条压缩为 5 条。删掉与路由表重复的工作流/调试流描述，删掉 statusLine 细节（属于 SKILL.md 的机制层，不是全局纪律），删掉 /codesop 的内部实现细节（pipeline-to-todo）。

### 3.4 不改的文件

| 文件 | 理由 |
|------|------|
| `config/codesop-router.md` | 密度合理（72 行），链路完整性原则是好的元规则 |
| `patches/superpowers/brainstorming-SKILL.md` | 密度合理，grill mode 和 ADR trigger 都是原则性的 |
| `lib/init-interview.sh` | 代码文件，精简范围仅限 prompt/skill 层 |
| `setup` | 代码文件 |

## 4. 影响分析

- **向后兼容**：纯 prompt 层精简，不改代码、不改路由、不改 CLI 行为
- **测试影响**：`tests/detect-environment.sh` 可能检查 AGENTS.md 的特定字符串，精简后需验证
- **setup sync**：AGENTS.md 变更需要 `setup --host claude`
- **版本**：建议 v3.6.0（文档层架构调整）

## 5. 风险

- **精简过度**：删掉矩阵后，弱模型可能做不好文档判定。缓解：当前 codesop 主要跑在 Claude Opus/Sonnet 上，判断力足够
- **格式回归**：SKILL.md §4 精简后，AI 输出格式可能不稳定。缓解：保留一个 complete example 作为格式锚点
- **自检清单删除**：5 条 checklist 确实帮弱模型兜底。缓解：语义层的"管什么"定义本身就是 checklist 的上位替代
