# Doc Gate Enhancement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add change impact matrix + self-check checklist to the document gate, reducing missed doc updates.

**Architecture:** Append structured table and checklist to existing AGENTS.md 文档判定 section. Update SKILL.md §5 flow from 3 to 4 steps. Version bump to 3.5.1.

**Tech Stack:** Markdown editing, grep for verification.

---

## Batch 1: AGENTS.md Gate Enhancement

### Task 1: Add change impact matrix to AGENTS.md

**Files:**
- Modify: `templates/system/AGENTS.md`

- [ ] **Step 1: Insert change impact matrix after 免更新场景**

Insert after line 94 (`**免更新场景：** ...`) and before line 96 (`**输出格式固定为：**`):

```markdown

**变更影响矩阵**（判定时按变更类型查表）：

| 变更类型 | CLAUDE.md | PRD.md | README.md | CONTEXT.md |
|---------|-----------|--------|-----------|------------|
| 新增/改/删命令或脚本 | 命令段 | - | 安装/运行段 | - |
| 新增/改/删目录或文件 | 架构树 | - | - | - |
| 新增/改/删环境变量 | 环境段 | - | 配置段 | - |
| 新增/改/删配置文件 | 架构段 | - | 配置/安装段 | - |
| 新增/改/删依赖 | 依赖段 | - | 安装/兼容段 | - |
| 新增/改/删 API/接口 | 接口段 | - | 接口段 | - |
| 新增/改/删架构决策 | 架构段 | 决策记录 | - | - |
| 新增/改/删产品功能 | - | 功能/范围/进度 | - | - |
| 新增/改/删领域术语 | - | - | - | 术语表 |
| 新增/改/删安装/部署 | 命令段 | - | 安装/部署段 | - |
| 新增/改/删测试 | 命令段 | - | 测试段 | - |

"-" = 该变更类型通常不影响该文档。多行匹配时，所有标记的文档都要检查。
CONTEXT.md 仅在文件存在时判定，不在表中出现的变更类型默认不影响。
不在表中的变更类型，回退到通用判定标准。
```

- [ ] **Step 2: Insert self-check checklist after matrix, before 输出格式**

Insert after the matrix explanation lines and before `**输出格式固定为：**`:

```markdown

**自检清单**（判定输出前逐条确认，任一项不通过则补检）：

- 本次新增/改/删的文件/目录 → CLAUDE.md 架构树是否已同步？
- 本次新增/改/删的环境变量 → README.md 配置段是否已提及？
- 本次新增/改/删的命令/脚本 → CLAUDE.md 命令段 + README.md 安装段是否已同步？
- 本次新增/改/删的依赖 → CLAUDE.md + README.md 是否都已更新？
- 本次新增/改/删的 API/接口 → CLAUDE.md 接口段 + README.md 接口段是否已同步？

全部通过 → 判定完成。不通过 → 回到判定步骤补检。
```

- [ ] **Step 3: Verify matrix and checklist exist**

Run: `grep -c '变更影响矩阵\|自检清单' templates/system/AGENTS.md`
Expected: 2

- [ ] **Step 4: Verify table structure**

Run: `grep -c '新增/改/删' templates/system/AGENTS.md`
Expected: ≥14 (11 table rows + 3 self-check mentions + explanation)

- [ ] **Step 5: Commit**

```bash
git add templates/system/AGENTS.md
git commit -m "feat: add change impact matrix and self-check to doc gate"
```

---

## Batch 2: SKILL.md Flow Update

### Task 2: Update SKILL.md §5 completion gate flow

**Files:**
- Modify: `SKILL.md`

- [ ] **Step 1: Update gate flow from 3 steps to 4 steps**

Find the current 3-step list (around lines 270-274):

```markdown
1. decide whether `CLAUDE.md`, `PRD.md`, and `README.md` need updates
2. if any document needs updates, invoke `claude-md-management` skill to audit and revise
3. include this exact block in the final answer:
```

Replace with 4-step flow:

```markdown
1. identify the change types from this task (consult the change impact matrix in AGENTS.md)
2. for each document, judge individually — no skipping or batch marking — whether it needs updating (use matrix for scope, general criteria for threshold)
3. run the self-check checklist to confirm no misses
4. if any document needs updates, invoke `claude-md-management` skill to audit and revise; then include this exact block in the final answer:
```

- [ ] **Step 2: Verify updated flow**

Run: `grep -c 'change impact matrix\|self-check checklist\|judge individually' SKILL.md`
Expected: 3

- [ ] **Step 3: Commit**

```bash
git add SKILL.md
git commit -m "feat: update completion gate to 4-step flow with matrix + self-check"
```

---

## Batch 3: Version Bump

### Task 3: Bump version to 3.5.1

**Files:**
- Modify: `VERSION`
- Modify: `skill.json`

- [ ] **Step 1: Bump VERSION**

Write `3.5.1` to `VERSION` (overwrite entire file).

- [ ] **Step 2: Update skill.json version**

In `skill.json`, change `"version": "3.5.0"` to `"version": "3.5.1"`.

- [ ] **Step 3: Verify**

Run: `cat VERSION && grep '"version"' skill.json`
Expected: `3.5.1` and `"version": "3.5.1",`

- [ ] **Step 4: Run tests**

Run: `bash tests/run_all.sh`
Expected: 9 passed, 0 failed

- [ ] **Step 5: Commit**

```bash
git add VERSION skill.json
git commit -m "chore: bump to v3.5.1 with doc gate enhancement"
```

---

## Self-Review

### Spec Coverage Check

| Spec §1 Item | Task |
|---|---|
| §1.1 变更影响矩阵 (11行表格 + 3行说明) | Task 1 Step 1 |
| §1.2 自检清单 (5条 + 1行结论) | Task 1 Step 2 |
| §1.3 SKILL.md §5 流程更新 (3步→4步) | Task 2 Step 1 |
| §2 版本 bump v3.5.1 | Task 3 |

All spec items covered.

### Placeholder Scan

No TBD/TODO found. All steps contain exact content.

### Type Consistency

- "新增/改/删" used consistently in matrix and self-check
- "变更影响矩阵" and "自检清单" referenced consistently across AGENTS.md and SKILL.md
