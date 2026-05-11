# Completion Gate 文档管理增强

> **Status**: Draft (v4 — 瘦身重写)
> **Date**: 2026-05-11
> **Scope**: SKILL.md §5 + AGENTS.md template + ADR template + test

## 1. 问题

SKILL.md §5 Completion Gate 要求任务完成时检查项目文档，但审计能力不对等：

- **CLAUDE.md**：有 claude-md-management skill，全流程覆盖
- **PRD.md / README.md**：无审计标准，只有"管产品""管使用"四个字
- **CONTEXT.md**：出现在 ☑/☐ 输出中，但无审计标准
- **docs/adr/**：brainstorming 阶段有触发，但跳过 brainstorming 的任务和实施中的意外决策无检查点

## 2. 方案

Completion Gate 的职责是 **检查→更新→报告**，不是文档管理体系。按文档性质分三种处理：

| 文档 | Gate 处理 | 原因 |
|------|----------|------|
| CLAUDE.md | 委托 claude-md-management | 已有成熟工具 |
| PRD.md / README.md / CONTEXT.md | 检查清单→命中则直接更新→报告 | 轻量 |
| docs/adr/ | 检查→建议（不执行）→报告 | ADR 规范由模板承载，Gate 只触发 |

ADR 的格式、生命周期、可变性规则不属于 Completion Gate 的职责 — 它们由 `templates/project/adr-template.md` 自描述（本次一并补全）。

不 patch claude-md-management，不新建 skill，不改产品合同。

## 3. PRD.md 检查清单（P1-P5）

| # | 维度 | 触发信号 | 更新目标 |
|---|------|---------|---------|
| P1 | 进度对齐 | 新的完成项/阻塞项/下一步变化 | PRD §2：移动/新增条目 |
| P2 | 决策记录 | 技术选型/范围变更/优先级调整 | PRD §3：追加决策行 |
| P3 | 范围准确 | 功能或接口增删改 | PRD §5：同步功能描述 |
| P4 | 风险更新 | 新风险/风险缓解/假设打破（低频） | PRD §6：增删改条目 |
| P5 | 里程碑 | 版本号/里程碑/阶段变化（低频） | PRD §1 + §4 |

规则：
- 任一命中则更新，仅改目标章节，不重写全文
- 纯重构/测试/格式化不影响上述维度 → 标记"未更新"
- 文件不存在 → 跳过
- P4/P5 低频：明显不涉及时快速跳过
- **Worktree 中 PRD 仅限改当前分支的局部子段落，全局变更需切 main**

## 4. README.md 检查清单（R1-R4）

| # | 维度 | 触发信号 | 更新目标 |
|---|------|---------|---------|
| R1 | 安装命令 | 安装步骤/依赖变化 | 安装段落 |
| R2 | 运行命令 | dev/build/test 命令变化 | 运行段落 |
| R3 | 配置说明 | 环境变量/配置路径增减 | 配置段落 |
| R4 | 接口文档 | API/CLI 接口变化 | 接口段落 |

规则：
- 逐维度独立判断：对应内容存在时检查，不存在时标记"不适用"
- 文件不存在 → 跳过

## 5. CONTEXT.md 检查清单（C1-C2）

| # | 维度 | 触发信号 | 更新目标 |
|---|------|---------|---------|
| C1 | 术语变化 | 新领域术语引入，或已有术语含义变化 | 新增/更新术语定义 |
| C2 | 定义冲突 | 代码实际用法与定义矛盾 | 确认方向后更新定义或建议修正代码 |

规则：
- 仅文件存在时检查；不存在时不输出
- C2 命中时先判断：定义过时→更新定义；代码有误→不改定义，标注冲突建议改代码

## 6. ADR 检查清单（A1-A2）

| # | 维度 | 触发信号 | 处理 |
|---|------|---------|------|
| A1 | 新增 ADR | 产生了架构决策（选型/边界/依赖方向/权衡） | 建议写 ADR |
| A2 | 影响现有 ADR | 与已有 ADR 矛盾或约束条件实质性变化 | 建议写新 ADR 标记 supersedes |

规则：
- 仅 `docs/adr/` 存在时检查；不存在时跳过
- ADR 为建议非强制，由用户决定是否执行
- ADR 格式和规则见 `templates/project/adr-template.md`（本次补全）
- brainstorming 已有 ADR 触发，Gate 补的是跳过 brainstorming 的任务和实施中的意外决策

## 7. ADR 模板补全

当前 `templates/project/adr-template.md` 只有骨架（决策/上下文/结果），缺少 Status 字段和可变性说明。补全为：

```markdown
# NNNN: {标题}

Status: {Proposed | Accepted | Deprecated | Superseded by ADR-XXXX}

## 决策

{1-3 句话：选了什么}

## 上下文

{为什么需要做这个决策，当时的约束和假设}

## 结果

{选这个的后果，不选那个的后果}

## Notes（可选，后续追加）

{实施后发现的新信息，不修改上方已有内容}
```

可变性规则（写入模板注释）：
- Decision + Context + Consequences：不可变（决策时的历史事实）
- Status：可变（生命周期：Proposed → Accepted → Deprecated / Superseded）
- Notes：可追加（后续发现的新信息），不修改已有段落
- 被 supersede 时：旧 ADR 只改 Status 行，新 ADR 正文注明 `Supersedes ADR-XXXX`

## 8. 精确替换文本

### 8.1 SKILL.md §5 替换

将 SKILL.md 从 `## 5. Completion Gate` 到 `## 6. Conflict Resolution` 之间的全部内容替换为：

```markdown
## 5. Completion Gate

Before the final answer on any routed implementation task:

1. identify the change types from this task (consult the change impact matrix in AGENTS.md)
2. for each document, check against its audit dimensions — no skipping or batch marking:
   - CLAUDE.md: invoke `claude-md-management` skill to audit and revise
   - PRD.md: check P1-P5 (progress/decision/scope/risk/milestone); if any triggered, update the target PRD section
   - README.md: check R1-R4 (install/run/config/interface); if any triggered, update the target README section
   - CONTEXT.md: if exists, check C1-C2 (term change/definition conflict); if any triggered, update
   - docs/adr/: if exists, check A1-A2 (new decision/existing ADR conflict); if any triggered, suggest ADR creation
3. self-check: confirm step 2 covered all documents and no dimension was skipped
4. include this exact block in the final answer:

```md
## 文档判定
☐ CLAUDE.md — 未更新：{原因}
☑ PRD.md — 已更新：{命中维度：一句话}
☐ README.md — 未更新：{原因}
☐ CONTEXT.md — 未更新：{原因}
☐ ADR — 未更新：无架构决策
```

☐/☑ 规则：☑ = 已更新（附改了什么），☐ = 未更新（附原因）。每行必须出现（条件行见下方）。

**条件行**：
- `CONTEXT.md`：仅项目存在该文件时输出，不存在时省略该行
- `ADR`：仅项目存在 `docs/adr/` 时输出，不存在时省略该行
- ADR 触发但未写：`☐ ADR — 建议写 ADR：{一句话决策内容}`
- ADR 已写：`☑ ADR — 已更新：新增 ADR-XXXX`

Notes:

- do not list `AGENTS.md` as a separate document decision target; project `AGENTS.md` should stay a thin wrapper to `CLAUDE.md`
- `CHANGELOG.md` is not part of the default document gate
- for pure refactors, test-only changes, or formatting-only changes, it is valid to mark all as "未更新" with a concrete reason
- in a worktree, PRD edits are restricted to the current branch's subsection under "并行开发记录"; global PRD changes require switching to main
- ADR suggestions are advisory; the user decides whether to write the ADR
```

### 8.2 AGENTS.md 文档判定部分替换

将 `templates/system/AGENTS.md` 从 `输出：` 到 `若需更新，优先调用 claude-md-management skill。` 替换为：

```markdown
输出：
```
## 文档判定
☑ CLAUDE.md — 已更新：{一句话改了什么}
☐ PRD.md — 未更新：{原因}
☐ README.md — 未更新：{原因}
```
- ☑ = 已更新，必须跟一句话说明改了什么
- ☐ = 未更新，必须跟原因
- 至少一项 ☑ 时，说明文档跟上代码了；全 ☐ 时要有明确理由

检查维度（完整定义见 SKILL.md §5）：
- PRD.md（P1-P5）：进度对齐 / 决策记录 / 范围准确 / 风险更新 / 里程碑
- README.md（R1-R4）：安装命令 / 运行命令 / 配置说明 / 接口文档
- CONTEXT.md（C1-C2，如存在）：术语变化 / 定义冲突
- docs/adr/（A1-A2，如存在）：新增 ADR / 影响现有 ADR

若需更新，优先调用 claude-md-management skill。
```

### 8.3 测试断言

在 `tests/detect-environment.sh` 的现有 Completion Gate 断言之后，新增：

```bash
assert_contains "$skill_full" "P1"
assert_contains "$skill_full" "P5"
assert_contains "$skill_full" "R1"
assert_contains "$skill_full" "R4"
assert_contains "$skill_full" "C1"
assert_contains "$skill_full" "A1"
assert_contains "$skill_full" "A2"
```

每个维度组只断言首尾两个（P1+P5, R1+R4），足以验证维度标识存在且表格完整，不需要逐个断言 13 个。

## 9. 改动文件

| 文件 | 改动 | 替换文本 |
|------|------|---------|
| `SKILL.md` §5 | 整节替换 | §8.1 |
| `templates/system/AGENTS.md` | 文档判定输出块+维度引用替换 | §8.2 |
| `templates/project/adr-template.md` | 全文替换（补 Status/Notes/可变性规则） | §7 |
| `tests/detect-environment.sh` | 新增 7 条断言 | §8.3 |

## 10. 不改

- claude-md-management skill
- 产品合同（3+1 入口）
- config/codesop-router.md
- CLI 代码（lib/、setup）

## 11. 权衡

| 决策 | 取舍 |
|------|------|
| PRD/README/CONTEXT 直接更新 | 简洁流程，风险用"仅改目标章节 + git diff 审查"缓解 |
| ADR 建议非强制 | 强制会产出无价值 ADR |
| 不 patch claude-md-management | 避免上游 rebase 负担 |
| ADR 可变性规则放模板而非 Gate | 关注点分离：Gate 管"什么时候"，模板管"怎么写" |

## 12. 验收标准

1. SKILL.md §5 含 P1-P5、R1-R4、C1-C2、A1-A2，每个维度有触发信号和更新目标
2. SKILL.md §5 步骤 1-4 重写为五条路径
3. AGENTS.md 模板含维度引用段落
4. adr-template.md 含 Status、Notes、可变性规则
5. detect-environment.sh 断言验证所有维度标识
6. `bash tests/run_all.sh` 全部通过
7. `bash setup --host claude` 成功同步
