# Domain Layer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add domain language layer (CONTEXT.md + ADR) and architecture principles (Clean Architecture + deep modules) to codesop, enhancing brainstorming with grill-mode questioning.

**Architecture:** 7 file changes + gate sync + version bump, split into 5 batches. Templates first, then skill patch, then system rules, then routing, then release. Each batch is independently verifiable.

**Tech Stack:** Bash (set -euo pipefail), Markdown templates, jq for settings.json, grep for assertions.

---

## Batch 1: Templates + Architecture Principles

### Task 1: Create CONTEXT.md template

**Files:**
- Create: `templates/project/CONTEXT.md`

- [ ] **Step 1: Create CONTEXT.md template file**

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

Write to `templates/project/CONTEXT.md`.

- [ ] **Step 2: Verify template structure**

Run: `grep -c '## Language\|## Relationships\|## Example Dialogue\|## Flagged Ambiguities' templates/project/CONTEXT.md`
Expected: 4

- [ ] **Step 3: Commit**

```bash
git add templates/project/CONTEXT.md
git commit -m "feat: add CONTEXT.md domain vocabulary template"
```

### Task 2: Create ADR template

**Files:**
- Create: `templates/project/adr-template.md`

- [ ] **Step 1: Create ADR template file**

```markdown
# NNNN: {标题}

## 决策

{1-3 句话：选了什么}

## 上下文

{为什么需要做这个决策}

## 结果

{选这个的后果，不选那个的后果}
```

Write to `templates/project/adr-template.md`.

- [ ] **Step 2: Verify template structure**

Run: `grep -c '## 决策\|## 上下文\|## 结果' templates/project/adr-template.md`
Expected: 3

- [ ] **Step 3: Commit**

```bash
git add templates/project/adr-template.md
git commit -m "feat: add ADR template for architecture decision records"
```

### Task 3: Add architecture principles to AGENTS.md

**Files:**
- Modify: `templates/system/AGENTS.md`

- [ ] **Step 1: Add architecture principles section**

Insert after the `## 冲突解决` section (after line 58) and before `## 文档职责`:

```markdown

## 架构原则
- Clean Architecture 定依赖方向，深模块定边界质量
- 每层暴露小而稳定的接口，隐藏实现复杂度
- 禁止为分层制造只有转发、贫血、接口比实现还复杂的浅模块
- 发现浅模块时标记（signal for 重构规划）
```

- [ ] **Step 2: Verify section exists**

Run: `grep -c '## 架构原则' templates/system/AGENTS.md`
Expected: 1

- [ ] **Step 3: Commit**

```bash
git add templates/system/AGENTS.md
git commit -m "feat: add Clean Architecture + deep modules principles to AGENTS.md"
```

---

## Batch 2: Brainstorming Patch + Setup Mapping

### Task 4: Create brainstorming skill patch

**Files:**
- Create: `patches/superpowers/brainstorming-SKILL.md`

- [ ] **Step 1: Create patch file**

This is a full-file replacement of the original brainstorming SKILL.md with grill-mode enhancements. The patch must:
1. Copy the entire original skill content from `~/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.7/skills/brainstorming/SKILL.md`
2. Add to Step 1 (~30 words): Read CONTEXT.md and docs/adr/ if they exist, silently skip if not
3. Add to Step 3 (~250 words): Three structural behaviors:
   - **Code-first answers**: Read code to answer questions when possible, verify user's claims against code
   - **Decision tree tracking**: Maintain implicit tree (resolved / pending / depends-on), exit when enough decisions support 2-3 approaches
   - **Domain vocabulary alignment**: Use CONTEXT.md terms, record new term consensus as delta in spec's `## Domain Language Delta` section
4. Add to Step 6 (~30 words): After spec approval, write Domain Language Delta to project CONTEXT.md if user agrees
5. Keep Steps 4-5 and 7-9 unchanged

Key additions to the original Step 3 "Ask clarifying questions" section:

```markdown

**Grill Mode** — structural enhancements to Step 3:

1. **Code-first answers**: When a question can be answered by reading code, read the code first instead of asking the user to guess. When the user describes existing behavior, verify against the codebase before accepting the claim.

2. **Decision tree tracking**: Maintain an implicit decision tree: resolved / pending / depends-on-other-decision. Each question maps to a node. **Exit condition**: stop grilling when purpose, constraints, success criteria, and major decision dependencies are clear enough to support 2-3 concrete approaches. Then proceed to Step 4.

3. **Domain vocabulary alignment**: If CONTEXT.md exists in the project, use its terms when framing questions. When new terminology reaches consensus, record it in the spec's `## Domain Language Delta` section (create this section if it doesn't exist). When the user's language conflicts with CONTEXT.md, call it out: "Your glossary defines X as A, but you seem to mean B — which is it?"
```

Key addition to Step 6 "Write design doc":

```markdown

After spec approval, if the spec contains a `## Domain Language Delta` section, ask the user whether to write these terms into the project's CONTEXT.md (creating the file if needed). If the user agrees, update CONTEXT.md with the delta terms following the format: term definition + Avoid list.
```

Key addition to Step 1 "Explore project context":

```markdown

Also check for: `CONTEXT.md` at the project root (domain vocabulary), and `docs/adr/` directory (architecture decision records). Read them if they exist. If they don't exist, proceed silently — don't suggest creating them.
```

Write the complete patched file to `patches/superpowers/brainstorming-SKILL.md`.

- [ ] **Step 2: Verify patch file exists and has grill content**

Run: `grep -c 'Grill Mode\|Decision tree tracking\|Domain Language Delta\|CONTEXT.md' patches/superpowers/brainstorming-SKILL.md`
Expected: ≥4

- [ ] **Step 3: Commit**

```bash
git add patches/superpowers/brainstorming-SKILL.md
git commit -m "feat: add brainstorming patch with grill-mode enhancement"
```

### Task 5: Add brainstorming mapping to setup patch_skills()

**Files:**
- Modify: `setup`

- [ ] **Step 1: Add brainstorming patch mapping**

Insert after the finishing-a-development-branch block (after line 194, before the `if [ "$patched" -gt 0 ]` check):

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

- [ ] **Step 2: Verify setup contains new mapping**

Run: `grep -c 'brainstorming.*grill' setup`
Expected: 1

- [ ] **Step 3: Commit**

```bash
git add setup
git commit -m "feat: add brainstorming patch mapping to setup patch_skills()"
```

---

## Batch 3: AGENTS.md Rules + Gate Sync

### Task 6: Add domain language rules to AGENTS.md

**Files:**
- Modify: `templates/system/AGENTS.md`

- [ ] **Step 1: Add domain language section**

Insert after `## 架构原则` section (added in Task 3), before `## 文档职责`:

```markdown

## 领域语言
当任务涉及需求讨论、领域术语、架构设计、跨模块改动、非平凡代码探索时：
- 先读 `CONTEXT.md`（如存在），使用词汇表术语命名
- 先读 `docs/adr/`（如存在），避免与已有架构决策矛盾
- 发现术语缺口时标记（signal for brainstorming 补充）
- 发现 ADR 冲突时显式指出
不存在则静默跳过，不提示创建。
```

- [ ] **Step 2: Verify section exists**

Run: `grep -c '## 领域语言' templates/system/AGENTS.md`
Expected: 1

- [ ] **Step 3: Commit**

```bash
git add templates/system/AGENTS.md
git commit -m "feat: add cross-skill domain language rules to AGENTS.md"
```

### Task 7: Extend document gate to include CONTEXT.md (optional)

**Files:**
- Modify: `SKILL.md`
- Modify: `templates/system/AGENTS.md`
- Modify: `lib/updates.sh`

- [ ] **Step 1: Add CONTEXT.md to SKILL.md completion gate**

In `SKILL.md` §5, after the README.md line in the gate output format, add:

```markdown
- CONTEXT.md: 已更新 / 未更新，原因：...（如存在，可选）
```

Also update the Notes section to add:
```markdown
- `CONTEXT.md` is optional — only include in the gate output if the file exists in the project
```

- [ ] **Step 2: Add CONTEXT.md to AGENTS.md document gate**

In `templates/system/AGENTS.md`, in the 文档判定 section, add to the 判定标准:
```markdown
- `CONTEXT.md`：领域术语、关系、模糊点变化时更新（可选，如存在时判定）
```

- [ ] **Step 3: Add CONTEXT.md to updates.sh project doc targets**

In `lib/updates.sh`, after `PROJECT_DOC_TARGETS` array (line 78-82), add optional CONTEXT.md detection. Append `"CONTEXT.md"` to the drift check when the file exists:

```bash
PROJECT_DOC_TARGETS=(
  "AGENTS.md"
  "PRD.md"
  "README.md"
  "CONTEXT.md"
)
```

Note: The drift scan function already skips non-existent files gracefully, so adding CONTEXT.md to the array is safe — it will be checked only when present.

- [ ] **Step 4: Verify all three files updated**

Run: `grep -l 'CONTEXT.md' SKILL.md templates/system/AGENTS.md lib/updates.sh | wc -l`
Expected: 3

- [ ] **Step 5: Commit**

```bash
git add SKILL.md templates/system/AGENTS.md lib/updates.sh
git commit -m "feat: extend document gate to include optional CONTEXT.md"
```

---

## Batch 4: Router Card

### Task 8: Update router card (4 changes, stay ≤75 lines)

**Files:**
- Modify: `config/codesop-router.md`
- Modify: `tests/codesop-router.sh`

- [ ] **Step 1: Update brainstorming description (same-line replacement)**

In `config/codesop-router.md`, find the line:
```
| | ★ | sp | superpowers:brainstorming | 任何新功能/改动前：理解需求→澄清问题→出设计方案→写 spec→spec 自审→用户审阅 |
```

Replace with:
```
| | ★ | sp | superpowers:brainstorming | 任何新功能/改动前：理解需求→grill 式术语对齐→澄清问题→出设计方案→写 spec→spec 自审→用户审阅；架构审查/重构/模块边界 |
```

- [ ] **Step 2: Add domain language rule to iron laws**

In the `### 铁律` section, append a new line:
```
- 领域语言：涉及需求/架构/跨模块改动时先读 CONTEXT.md 和 ADR（如存在），用术语，发现缺口标记，发现冲突指出
```

- [ ] **Step 3: Append architecture reflection to debug path**

Find the debug path line:
```
调试路径（"修 bug"/"测试挂了"）：跳过需求和计划，直接 superpowers:systematic-debugging → superpowers:verification-before-completion → ☆claude-md-management → superpowers:finishing-a-development-branch
```

Append to the end of that line:
```
；修 bug 后追问架构反思，如有价值建议写 ADR
```

- [ ] **Step 4: Compress iron laws to stay under line limit**

Merge two existing short iron law lines if needed. The current iron laws are 4 lines. Adding 1 new line makes 5. Merge the first two lines:

From:
```
- 跳过必走 Skill = 先输出对齐块说明原因
- Task 指定了 skill 就必须调用，不能 inline 替代
```

To:
```
- 跳过必走 Skill = 先输出对齐块说明原因；Task 指定了 skill 就必须调用，不能 inline 替代
```

This saves 1 line, net result: +1 (new rule) -1 (compression) = 0 line change.

- [ ] **Step 5: Verify line count**

Run: `wc -l < config/codesop-router.md | tr -d ' '`
Expected: ≤73

- [ ] **Step 6: Update test threshold if needed**

If line count > 72, update `tests/codesop-router.sh` line 29:

From:
```bash
[ "$lines" -le 72 ] || fail "Router card is $lines lines (max 72 for v2 lifecycle table)"
```

To:
```bash
[ "$lines" -le 75 ] || fail "Router card is $lines lines (max 75 for v3 domain layer table)"
```

- [ ] **Step 7: Verify all new content present**

Run: `grep -c 'grill 式术语对齐\|领域语言.*CONTEXT\|架构反思.*ADR\|架构审查/重构/模块边界' config/codesop-router.md`
Expected: ≥3

- [ ] **Step 8: Commit**

```bash
git add config/codesop-router.md tests/codesop-router.sh
git commit -m "feat: update router card with domain language rules and grill-mode routing"
```

---

## Batch 5: Version Wrap-up

### Task 9: Bump version and update docs

**Files:**
- Modify: `VERSION`
- Modify: `PRD.md`
- Modify: `CLAUDE.md`
- Modify: `README.md`

- [ ] **Step 1: Bump VERSION**

Write `3.5.0` to `VERSION`.

- [ ] **Step 2: Update PRD.md**

Add to §1 当前快照:
- 当前版本: 3.5.0
- 当前里程碑: v3.5.0 领域语言层 + 架构原则增强

Add to §3 最近决策记录:
| 2026-04-29 | 新增领域语言层 + 架构原则增强 | Matt Pocock skills 研究后提取行为，不搬文件 | CONTEXT.md + ADR + grill patch + 深模块原则 |

Add to §4 版本历史:
```markdown
### **V3.5.0 - 2026-04-29 - (Domain Language Layer + Architecture Principles)**
- **目标**: 增加领域语言层，增强 brainstorming 提问质量，合成 Clean Architecture + 深模块原则
- **变更摘要**:
  - 新增 CONTEXT.md 领域词汇表模板（懒创建）
  - 新增 ADR 架构决策记录机制（懒创建）
  - brainstorming patch：grill 模式（代码优先、决策树追踪、术语对齐）
  - AGENTS.md：跨 skill 领域语言规则 + 架构原则
  - 路由卡：grill 式术语对齐 + 领域语言铁律 + 调试路径架构反思
  - 文档 gate 扩展至三文档 + 可选 CONTEXT.md
```

- [ ] **Step 3: Update CLAUDE.md**

Add to architecture tree under `templates/`:
```
│   ├── project/             # Project-level templates (PRD.md, README.md, CONTEXT.md, adr-template.md)
```

Add to `patches/` description:
```
├── patches/                # Skill patches applied by setup on sync
│   └── superpowers/        # Modified superpowers skill files (writing-plans, finishing-branch, brainstorming)
```

- [ ] **Step 4: Update README.md**

Add CONTEXT.md and ADR to the workflow documentation section describing the document system.

- [ ] **Step 5: Verify version**

Run: `cat VERSION`
Expected: 3.5.0

- [ ] **Step 6: Commit**

```bash
git add VERSION PRD.md CLAUDE.md README.md
git commit -m "chore: bump to v3.5.0 with domain language layer"
```

### Task 10: Run full test suite

**Files:**
- No file changes

- [ ] **Step 1: Run all tests**

Run: `bash tests/run_all.sh`
Expected: All tests pass

- [ ] **Step 2: Fix any failures**

If any test fails, investigate the root cause. Common expected issues:
- Router card line count test: should be fixed by Task 8 Step 6
- AGENTS.md section test: should be fixed by Task 3 and Task 6
- Setup function test: should be fixed by Task 5

- [ ] **Step 3: Commit any fixes**

```bash
git add -A
git commit -m "fix: test adjustments for domain layer v3.5.0"
```

---

## Self-Review

### Spec Coverage Check

| Spec §1 Item | Task |
|---|---|
| 1.1 CONTEXT.md template | Task 1 |
| 1.2 ADR mechanism | Task 2 |
| 1.3 Brainstorming patch | Task 4 |
| 1.4 AGENTS.md domain language rules | Task 6 |
| 1.5 Router card | Task 8 |
| 1.6 Setup patch_skills() | Task 5 |
| 1.7 Architecture principles | Task 3 |
| §3 Gate sync (SKILL.md) | Task 7 Step 1 |
| §3 Gate sync (AGENTS.md) | Task 7 Step 2 |
| §3 Gate sync (updates.sh) | Task 7 Step 3 |
| §5 Version wrap-up | Task 9 |
| §4 Tests | Task 10 |

All spec items covered.

### Placeholder Scan

No TBD/TODO found. All steps contain actual code or exact commands.

### Type Consistency

- `patches/superpowers/brainstorming-SKILL.md` referenced consistently in Task 4 (create) and Task 5 (setup mapping)
- `templates/project/CONTEXT.md` referenced consistently in Task 1 (create) and Task 7 (gate)
- `CONTEXT.md` in PROJECT_DOC_TARGETS array matches actual filename
- `grep` patterns use consistent skill names matching routing table
