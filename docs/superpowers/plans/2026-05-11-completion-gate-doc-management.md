# Completion Gate 文档管理增强 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 增强 SKILL.md §5 Completion Gate，为 PRD.md、README.md、CONTEXT.md、docs/adr/ 各加结构化审计维度，补全 ADR 模板，使 AI 在任务完成时能主动发现并更新所有项目文档。

**Architecture:** 在 SKILL.md §5 中定义 13 个审计维度（P1-P5, R1-R4, C1-C2, A1-A2），按文档性质分三种处理方式（委托 skill / 直接更新 / 建议）。ADR 的格式和生命周期规则由模板自描述，不塞进 Gate。改动限于 4 个文件，全部是 markdown 内容变更 + bash 测试断言。

**Tech Stack:** Markdown, bash test assertions

---

### Task 1: Update ADR template

**Files:**
- Replace: `templates/project/adr-template.md`

- [ ] **Step 1: Replace ADR template with enhanced version**

Replace entire file content of `templates/project/adr-template.md` with:

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

<!-- 可变性规则：
- Decision + Context + Consequences：不可变（决策时的历史事实）
- Status：可变（生命周期：Proposed → Accepted → Deprecated / Superseded）
- Notes：可追加（后续发现的新信息），不修改已有段落
- 被 supersede 时：旧 ADR 只改 Status 行，新 ADR 正文注明 Supersedes ADR-XXXX
-->

- [ ] **Step 2: Verify file was written correctly**

Run: `head -5 templates/project/adr-template.md`
Expected: Shows `# NNNN: {标题}` and `Status:` line

- [ ] **Step 3: Commit**

```bash
git add templates/project/adr-template.md
git commit -m "feat: enhance ADR template with Status, Notes, and mutability rules"
```

### Task 2: Add test assertions (TDD red phase)

**Files:**
- Modify: `tests/detect-environment.sh:41-45`

- [ ] **Step 1: Add dimension identifier assertions**

After the existing line `assert_contains "$skill_full" "☑ CLAUDE.md — 已更新"` (line 41), add these 7 assertions:

```bash
assert_contains "$skill_full" "P1"
assert_contains "$skill_full" "P5"
assert_contains "$skill_full" "R1"
assert_contains "$skill_full" "R4"
assert_contains "$skill_full" "C1"
assert_contains "$skill_full" "A1"
assert_contains "$skill_full" "A2"
```

- [ ] **Step 2: Run test to verify it fails (red phase)**

Run: `bash tests/detect-environment.sh 2>&1 | tail -5`
Expected: FAIL — `P1`, `R1`, `C1`, `A1` not yet in SKILL.md

- [ ] **Step 3: Do NOT commit yet — will commit with Task 3**

### Task 3: Replace SKILL.md §5 Completion Gate (TDD green phase)

**Files:**
- Modify: `SKILL.md:256-281` (§5 Completion Gate section)

- [ ] **Step 1: Replace §5 section**

Replace everything from `## 5. Completion Gate` (line 256) up to but not including `## 6. Conflict Resolution` (line 282) with:

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

PRD.md 检查清单（P1-P5）：

| # | 维度 | 触发信号 | 更新目标 |
|---|------|---------|---------|
| P1 | 进度对齐 | 新的完成项/阻塞项/下一步变化 | PRD §2：移动/新增条目 |
| P2 | 决策记录 | 技术选型/范围变更/优先级调整 | PRD §3：追加决策行 |
| P3 | 范围准确 | 功能或接口增删改 | PRD §5：同步功能描述 |
| P4 | 风险更新 | 新风险/风险缓解/假设打破（低频） | PRD §6：增删改条目 |
| P5 | 里程碑 | 版本号/里程碑/阶段变化（低频） | PRD §1 + §4 |

README.md 检查清单（R1-R4）：

| # | 维度 | 触发信号 | 更新目标 |
|---|------|---------|---------|
| R1 | 安装命令 | 安装步骤/依赖变化 | 安装段落 |
| R2 | 运行命令 | dev/build/test 命令变化 | 运行段落 |
| R3 | 配置说明 | 环境变量/配置路径增减 | 配置段落 |
| R4 | 接口文档 | API/CLI 接口变化 | 接口段落 |

CONTEXT.md 检查清单（C1-C2）：

| # | 维度 | 触发信号 | 更新目标 |
|---|------|---------|---------|
| C1 | 术语变化 | 新领域术语引入，或已有术语含义变化 | 新增/更新术语定义 |
| C2 | 定义冲突 | 代码实际用法与定义矛盾 | 确认方向后更新定义或建议修正代码 |

ADR 检查清单（A1-A2）：

| # | 维度 | 触发信号 | 处理 |
|---|------|---------|------|
| A1 | 新增 ADR | 产生了架构决策（选型/边界/依赖方向/权衡） | 建议写 ADR |
| A2 | 影响现有 ADR | 与已有 ADR 矛盾或约束条件实质性变化 | 建议写新 ADR 标记 supersedes |

Notes:

- do not list `AGENTS.md` as a separate document decision target; project `AGENTS.md` should stay a thin wrapper to `CLAUDE.md`
- `CHANGELOG.md` is not part of the default document gate
- for pure refactors, test-only changes, or formatting-only changes, it is valid to mark all as "未更新" with a concrete reason
- in a worktree, PRD edits are restricted to the current branch's subsection under "并行开发记录"; global PRD changes require switching to main
- ADR suggestions are advisory; the user decides whether to write the ADR
- P4/P5 marked low-frequency: skip when change type clearly does not involve risk or milestone
```

Note: The code block inside the markdown section (` ```md ... ``` `) creates a nested fence. Ensure the inner fence uses consistent backtick count. In the actual file, the output format block uses triple backticks and the PRD/README/CONTEXT/ADR tables are outside the code fence.

- [ ] **Step 2: Run test to verify it passes (green phase)**

Run: `bash tests/detect-environment.sh 2>&1 | tail -5`
Expected: PASS — all dimension assertions find their identifiers in SKILL.md

- [ ] **Step 3: Commit SKILL.md and test together**

```bash
git add SKILL.md tests/detect-environment.sh
git commit -m "feat: enhance Completion Gate with P1-P5/R1-R4/C1-C2/A1-A2 audit dimensions"
```

### Task 4: Update AGENTS.md template

**Files:**
- Modify: `templates/system/AGENTS.md:98-109` (文档判定 output section)

- [ ] **Step 1: Replace document judgment output section**

Replace from `输出：` through `若需更新，优先调用 claude-md-management skill。` (lines 98-109) with:

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

- [ ] **Step 2: Commit**

```bash
git add templates/system/AGENTS.md
git commit -m "feat: add dimension reference paragraph to AGENTS.md template"
```

### Task 5: Resync and verify

**Files:** None (verification only)

- [ ] **Step 1: Run setup to resync host**

Run: `bash setup --host claude 2>&1`
Expected: All steps succeed, no errors

- [ ] **Step 2: Run full test suite**

Run: `bash tests/run_all.sh 2>&1 | tail -15`
Expected: All tests pass (0 failures)

- [ ] **Step 3: Verify SKILL.md installed correctly**

Run: `grep -c "P1" ~/.claude/skills/codesop/SKILL.md`
Expected: Count > 0 (dimension identifiers present in installed skill)

- [ ] **Step 4: Final commit if any resync artifacts**

Check `git status`. If `setup --host claude` left no uncommitted changes, no commit needed.
