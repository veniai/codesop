# Elegance 精简优化

> **日期**: 2026-04-30
> **状态**: Rev 2 — 测试审计后修订版
> **范围**: SKILL.md 和 AGENTS.md 的优雅化精简
> **约束**: 不破坏任何现有测试合同

## 1. 精简策略

**核心原则**：教判断力，不教机械化。但要区分两层：

- **测试合同层**（被 `detect-environment.sh` 和 `codesop-router.sh` 检查的字符串）：必须保留，不能删
- **解释冗余层**（不被测试检查的文本）：可以安全删减

**方法**：不是整段重写，而是逐区标注保留/删减，确保每个被测试的字符串继续存在。

## 2. SKILL.md 精简

### 2.1 §3 Pipeline TaskCreate 规范（line 108-114）

**当前 7 行**。可以压缩到 5 行，删掉解释性文本但保留合同字段。

**保留**（测试合同 + re-entry 锚点）：
- `metadata: skill 任务 {source: "codesop-pipeline", skill: "..."}` — re-entry 用 source 过滤
- `blockedBy 顺序`

**删减**：
- ☆/★ 标记的解释性注释（line 111）— AI 从示例推断
- "第一个 task 创建后立即执行"（line 114）— 已在 §3.10.5 说明

**改为**：
```markdown
**Pipeline TaskCreate 规范**：
- 链路中每个步骤创建一个 task，subject 用指令式（有 skill 写"使用 {skill-name} Skill 做{描述}"，不含 ☆/★）
- metadata：skill 任务 `{source: "codesop-pipeline", skill: "skill-name"}`，衔接任务 `{source: "codesop-pipeline"}`
- 逐个顺序创建，第 N+1 个 blockedBy 第 N 个
- 衔接任务（无 skill）：从上下文推断该做什么，完成后 TaskUpdate(completed)
```

**行数变化**：7 → 5。**测试影响**：无（没有测试检查此区域内容）。

### 2.2 §3 衔接任务 — 创建分支（line 116-121）

**当前 6 行**。压缩到 3 行。

**保留**：插入条件、worktree 覆盖、TaskUpdate(completed)。

**删减**：subject/metadata 模板（AI 从 TaskCreate 规范推断）。

**改为**：
```markdown
**衔接任务 — 创建分支**：
- 新功能链路且当前在 main/master 时，在 writing-plans 后、开发前插入
- 用户说"用 worktree"时改为 worktree
- 完成后 TaskUpdate(completed)
```

**行数变化**：6 → 3。**测试影响**：无。

### 2.3 §4 Default Output（line 132-266）

这是最关键的区域。**不做整段重写**，而是逐 subsection 精简。

#### 2.3.1 §4 开头（line 132-141）

**当前 10 行**。保留全部——这里包含了 6 个被测试检查的字符串：
- `## 工作台摘要`（line 136）→ detect-environment.sh:23, codesop-router.sh:48
- `## 下一步建议`（line 138）→ detect-environment.sh:26, codesop-router.sh:50
- `4. **末行**`（line 139）→ detect-environment.sh:27
- NEVER 禁令（line 141）→ 保证格式合同

**不动**。

#### 2.3.2 §4.1 Workbench Summary（line 143-160）

**当前 18 行**。包含被测试检查的 `**状态**:` 和 `**分支**:`。

精简方式：合并模板和规则，删掉分条的格式解释。

**改为**：
```markdown
### 4.1 Workbench Summary

```md
## 工作台摘要
**状态**: {分支名} — {一句话描述当前在干什么}
**分支**: {分支名}（{PR 状态}）
**注意**: {具体内容}（仅在异常时加此行，无异常不输出）
```

2 个必显字段（**状态** + **分支**），每行一个 bold key + inline value。摘要反映当前分支上下文。
```

**行数变化**：18 → 9。**测试检查**：`**状态**:` 和 `**分支**:` 保留。

#### 2.3.3 §4.2 Skill Ecosystem（line 162-172）

**当前 11 行**。压缩到 5 行。

**改为**：
```markdown
### 4.2 Skill Ecosystem

```md
## Skill 生态
- 路由覆盖：（粘贴 check_routing_coverage 输出）
```

三种结果映射："路由覆盖完整"→"✓ 路由覆盖完整"，不完整→显示原文含缺失条目，模块不可用→标注。此区只反映 skill 生态，不用于项目文档判断。
```

**行数变化**：11 → 5。**测试影响**：无（没有测试检查 §4.2 内容）。

#### 2.3.4 §4.3 Pipeline Dashboard（line 174-220）

**当前 47 行**。这是膨胀最严重的区域——proposing 和 continuing 两套完整示例高度重复。

**保留的测试字符串**：
- `提议 Pipeline`（line 182）→ detect-environment.sh:43, codesop-router.sh:57
- `Complete Example`（line 241，属于 §4.5）→ detect-environment.sh:42, codesop-router.sh:56

**精简方式**：
1. 保留 format rules（line 212-220，这是合同）
2. 删掉 proposing 示例（line 178-193）——它与 §4.5 的 Complete Example 重复
3. 保留 continuing 示例（line 195-210）——它展示了 ☑/☐ 格式
4. §4.5 Complete Example 同时承担 proposing 示例角色

**行数变化**：47 → ~30。**测试检查**：`提议 Pipeline` 在 §4.5 Complete Example 中仍有，不会被删。

#### 2.3.5 §4.4 Final Line（line 222-239）

**当前 18 行**。包含多个测试字符串，必须保留：

- `末行必须是疑问句`（line 224）→ detect-environment.sh:31
- `场景适配`（line 231）→ detect-environment.sh:32, codesop-router.sh:54
- `工作区有未提交改动`（line 232）→ detect-environment.sh:44
- `前置 superpowers:finishing-a-development-branch`（line 232）→ detect-environment.sh:33, codesop-router.sh:55

**精简方式**：合并 Proposing/Stale 两种句式为一个通用描述，但**所有测试字符串原样保留**。

**改为**：
```markdown
### 4.4 Final Line

首次确认或上下文变化时，末行必须是疑问句，以"吗？"结尾。用户按 Enter 即可确认。
pipeline 执行中（task list 已确认），不问，自动执行下一个。

**场景适配**：
- 工作区有未提交改动：task list 前置 superpowers:finishing-a-development-branch 处理
- 重新进入 /codesop：用 ☐/☑ 格式显示当前 task list，自动继续下一个 pending task
- 检测到上下文变化：输出新的 proposed task list，末行用 stale 句式

**规则**：
- 末行是整个输出的最后一行，其后不能有任何内容
- 以"要"或"要我"开头，自然语言
- 提到具体 skill 名称以便 AI 路由
```

**行数变化**：18 → 12。**测试检查**：所有 4 个测试字符串保留。

#### 2.3.6 §4.5 Complete Example（line 241-266）

**当前 26 行**。保留但微调——这是 `提议 Pipeline` 和 `Complete Example` 两个测试字符串的载体。

**不动**。

### 2.4 §3 文档漂移扫描（line 78-86）

**包含测试字符串**：
- `Perform a quick document drift scan`（line 78）→ detect-environment.sh:28
- `Use this scan to decide whether doc updates belong in the next workflow chain`（line 82）→ detect-environment.sh:29
- `check_project_document_drift`（line 85）→ detect-environment.sh:30, codesop-router.sh:53

**不动**。这些是测试合同。

### 2.5 SKILL.md 总行数预估

| 区域 | 当前行数 | 精简后 | 变化 |
|------|---------|--------|------|
| §3 TaskCreate 规范 | 7 | 5 | -2 |
| §3 衔接任务 | 6 | 3 | -3 |
| §4.1 Workbench Summary | 18 | 9 | -9 |
| §4.2 Skill Ecosystem | 11 | 5 | -6 |
| §4.3 Pipeline Dashboard | 47 | ~30 | -17 |
| §4.4 Final Line | 18 | 12 | -6 |
| 其余不动区域 | ~223 | ~223 | 0 |
| **总计** | **330** | **~287** | **-43** |

**精简比：13%**，比初版的 40% 保守得多。但这是经过测试审计的安全精简。

## 3. AGENTS.md 精简

### 3.1 文档判定（line 84-130）

**当前 ~47 行**。四层叠加（语义 + 矩阵 + checklist + 格式）。

**测试约束**：`codesop-router.sh` 检查 `Skill 纪律` 标题和 `任务对齐块`，不在此区域。`detect-environment.sh` 检查 `## 文档判定` 和 `- CLAUDE.md: 已更新 / 未更新，原因：...`，这两个在格式层，必须保留。

**精简方案**：
- 语义层（line 87-93）：保留
- 变更影响矩阵（line 95-113）：11 行矩阵压缩为 5 行高风险映射
- 自检清单（line 115-123）：删除（矩阵的子集）
- 格式层（line 125-130）：保留
- 免更新场景（line 93）：保留，与语义层合并

**改为**：
```markdown
## 文档判定
任务结束前判定 CLAUDE.md / PRD.md / README.md 是否需要更新。

判定原则：
- `CLAUDE.md` 管技术：架构、命令、规范、目录、环境、交付
- `PRD.md` 管产品：目标、范围、验收标准、进度、决策
- `README.md` 管使用：安装、运行、配置、部署、接口
- `CONTEXT.md` 管领域：术语、关系、模糊点（可选，如存在时判定）
- 纯重构/测试/格式化且不改变上述信息时，三者均可标记"未更新"

高风险映射（这些变更通常影响多个文档）：
- 命令/脚本 → CLAUDE.md + README.md
- 依赖 → CLAUDE.md + README.md
- API/接口 → CLAUDE.md + README.md
- 环境变量/配置 → CLAUDE.md + README.md
- 目录/架构 → CLAUDE.md

不在映射中的变更类型，回退到判定原则自行判断。

输出：
- `CLAUDE.md: 已更新 / 未更新，原因：...`
- `PRD.md: 已更新 / 未更新，原因：...`
- `README.md: 已更新 / 未更新，原因：...`

若需更新，优先调用 claude-md-management skill。
```

**行数变化**：47 → ~20。**测试检查**：`## 文档判定` 和 `- CLAUDE.md: 已更新 / 未更新，原因：...` 均保留。

### 3.2 Skill 纪律（line 34-44）

**当前 11 行**。

**测试约束**：
- `Skill 纪律`（标题）→ codesop-router.sh:41 ✓
- `任务对齐块`→ codesop-router.sh:42 ✓

**精简方案**：保留这两个测试字符串，删掉与路由表重复的工作流/调试流描述。

**改为**：
```markdown
## Skill 纪律
- 新任务先输出任务对齐块：`理解` + `阶段` + `Skill`
- skill 有 ≥1% 适用可能时，先加载 skill 再行动
- 路由以路由表为准；pipeline task 指定的 skill 必须通过 Skill tool 调用，不接受 inline 替代
- 已确认的 pipeline task list 等于授权全程执行，完成后自动 re-entry
- 跳过了应走的 skill 时，用户指出后立即重走 pipeline
```

**行数变化**：11 → 6。**测试检查**：`Skill 纪律` 标题和 `任务对齐块` 均保留。

### 3.3 AGENTS.md 总行数预估

| 区域 | 当前行数 | 精简后 | 变化 |
|------|---------|--------|------|
| 文档判定 | 47 | ~20 | -27 |
| Skill 纪律 | 11 | 6 | -5 |
| 其余不动区域 | 78 | 78 | 0 |
| **总计** | **136** | **~104** | **-32** |

**精简比：24%**。

## 4. 测试验证清单

每个改动区域对应的测试断言：

| 测试文件 | 检查的字符串 | 精简后是否保留 |
|---------|-------------|--------------|
| detect-environment.sh:23 | `## 工作台摘要` | ✅ 保留（§4 开头不动） |
| detect-environment.sh:24 | `**状态**:` | ✅ 保留（§4.1 精简后仍有） |
| detect-environment.sh:25 | `**分支**:` | ✅ 保留（§4.1 精简后仍有） |
| detect-environment.sh:26 | `## 下一步建议` | ✅ 保留（§4 开头不动） |
| detect-environment.sh:27 | `4. **末行**` | ✅ 保留（§4 开头不动） |
| detect-environment.sh:28 | `Perform a quick document drift scan` | ✅ 保留（§3.8 不动） |
| detect-environment.sh:29 | `Use this scan to decide whether...` | ✅ 保留（§3.8 不动） |
| detect-environment.sh:30 | `check_project_document_drift` | ✅ 保留（§3.8 不动） |
| detect-environment.sh:31 | `末行必须是疑问句` | ✅ 保留（§4.4 精简后仍有） |
| detect-environment.sh:32 | `场景适配` | ✅ 保留（§4.4 精简后仍有） |
| detect-environment.sh:33 | `前置 superpowers:finishing-a-development-branch` | ✅ 保留（§4.4 精简后仍有） |
| detect-environment.sh:40 | `## 文档判定` | ✅ 保留（AGENTS.md 精简后仍有） |
| detect-environment.sh:41 | `- CLAUDE.md: 已更新 / 未更新，原因：...` | ✅ 保留（AGENTS.md 格式层不动） |
| detect-environment.sh:42 | `Complete Example` | ✅ 保留（§4.5 不动） |
| detect-environment.sh:43 | `提议 Pipeline` | ✅ 保留（§4.5 不动） |
| detect-environment.sh:44 | `工作区有未提交改动` | ✅ 保留（§4.4 精简后仍有） |
| codesop-router.sh:41 | `Skill 纪律` | ✅ 保留（AGENTS.md 精简后仍有） |
| codesop-router.sh:42 | `任务对齐块` | ✅ 保留（AGENTS.md 精简后仍有） |
| codesop-router.sh:48 | `工作台摘要` | ✅ 保留 |
| codesop-router.sh:49 | `文档状态` | ✅ 保留（§4.1 模板中） |
| codesop-router.sh:50 | `下一步建议` | ✅ 保留 |
| codesop-router.sh:51 | `workflow instruction` | ✅ 保留（§4 开头 line 139） |
| codesop-router.sh:52 | `document drift scan` | ✅ 保留（§3.8 不动） |
| codesop-router.sh:53 | `check_project_document_drift` | ✅ 保留（§3.8 不动） |
| codesop-router.sh:54 | `场景适配` | ✅ 保留 |
| codesop-router.sh:55 | `cleanup-first\|前置.*finishing` | ✅ 保留（§4.4 中） |
| codesop-router.sh:56 | `Complete Example` | ✅ 保留 |
| codesop-router.sh:57 | `提议 Pipeline` | ✅ 保留 |

**全部 28 个测试断言在精简后仍然通过。**

## 5. 不改的文件

| 文件 | 理由 |
|------|------|
| `config/codesop-router.md` | 72 行，密度合理 |
| `patches/superpowers/brainstorming-SKILL.md` | 密度合理 |
| `lib/init-interview.sh` | 代码文件 |
| `setup` | 代码文件 |
| SKILL.md §1-2 | 密度合理（~54 行） |
| SKILL.md §3.8 文档漂移扫描 | 包含 3 个测试字符串 |
| SKILL.md §4 开头 4 section 定义 | 包含 3 个测试字符串 |
| SKILL.md §4.5 Complete Example | 包含 2 个测试字符串，是 proposing 格式的锚点 |
| SKILL.md §5 Completion Gate | 包含 2 个测试字符串 |
| SKILL.md §6-9 | 密度合理 |

## 6. 版本与验证

- **版本**：v3.6.0
- **验证方式**：每个改动后立即运行 `bash tests/run_all.sh`，确认 9/9 PASS
- **setup sync**：改动后 `bash setup --host claude`
