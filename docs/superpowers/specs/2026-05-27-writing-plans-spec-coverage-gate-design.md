# writing-plans Spec Coverage Gate 设计

## 1. 问题

writing-plans 的自审步骤无法有效拦截 spec 需求遗漏。实测两对 spec→plan（共 57 个需求）发现：

- 核心功能需求覆盖良好
- 二级规则（条件处理、跳过逻辑、边缘情况说明、设计理据）被系统性遗漏
- 自审"skim"只做 section 级匹配，不做 requirement 级匹配
- 自己审自己，认知偏差不可避免

## 2. 方案

Patch writing-plans 自审步骤，三处改动：

### 2.1 新增 Requirement Extraction 步骤

在 Self-Review 前插入 `## Requirement Extraction` section。

**指令要点**：
- 读 spec，枚举所有离散需求为编号列表（R1, R2, R3...）
- "离散需求"定义：任何可独立验证的行为、规则、约束、输出格式、边缘条件
- 一个 spec section 可能包含多个离散需求（如 10 个测试断言 = 10 个需求）
- 枚举结果写入 plan 文档的 `## Requirement Traceability` section
- 显式忽略 "What NOT to change" 类负面需求（这些是约束，不需要 plan task 覆盖）

### 2.2 自审改为 subagent 派遣

将 "This is a checklist you run yourself -- not a subagent dispatch" 改为派遣 general-purpose subagent 做独立审查。

**原因**：写 plan 的 agent 自审自己写的 plan 有认知偏差。独立 subagent 读取 spec + plan + requirement list，不带"作者视角"。

**subagent 输入**：
- spec 文件路径
- plan 文件路径
- requirement traceability list（plan 内的 `## Requirement Traceability` section）

**subagent 职责**：
1. 需求覆盖检查：逐行验证 R1..RN 每个需求是否被 plan 某个 task 的某个 step 覆盖
2. Placeholder 扫描：检查 plan 中是否有 TBD、TODO、"implement later"等占位符
3. 输出 traceability matrix + issues list

**subagent 不负责**：类型一致性检查（需要上下文连续性，保留为 self-check）

### 2.3 覆盖检查输出 Traceability Matrix

Subagent 输出格式：

```markdown
## Plan Coverage Review

**Status:** Approved | Issues Found

**Traceability Matrix:**

| Req | Spec Section | Plan Task | Status |
|-----|-------------|-----------|--------|
| R1  | §1.1        | Task 2 Step 3 | ✅   |
| R2  | §1.2        | MISSING        | ❌   |

**Issues (if any):**
- R2 (§1.2): [具体描述缺失了什么]

**Recommendations (advisory):**
- [不阻塞 approval 的改进建议]
```

**Status 判定**：
- Approved：所有需求至少 PARTIAL，无 ❌
- Issues Found：有任何 ❌（需求完全无覆盖）
- PARTIAL（需求被部分覆盖但细节不足）不阻塞 approval，但必须在 Issues 中列出

### 2.4 保留的自检查项

类型一致性检查保留为 plan 作者的 self-check，因为需要跨 task 的上下文连续性（function name/signature 在 Task 3 和 Task 7 必须一致）。

## 3. 改动范围

| 文件 | 操作 | 改什么 |
|------|------|--------|
| `patches/superpowers/writing-plans-SKILL.md` | 修改 | 新增 Requirement Extraction section；改写 Self-Review section |
| `patches/superpowers/writing-plans-plan-coverage-reviewer-prompt.md` | 新增 | Subagent 审查 prompt 模板 |
| `config/codesop-router.md` | 不改 | 不是新 skill，不新增路由条目 |
| `SKILL.md` | 不改 | 不是新 pipeline 步骤 |
| `setup` | 实现时验证 | 检查 `patch_skills()` 是否只同步 `SKILL.md`；如果是，需扩展为同步 patch 目录下所有 `.md` 文件 |

### 3.1 writing-plans-SKILL.md 改动详情

**删除** Self-Review section 的第 1 段（"This is a checklist you run yourself -- not a subagent dispatch"）

**插入**（在 Self-Review 前）：

```markdown
## Requirement Extraction

Before self-review, extract all discrete requirements from the spec:

1. Read the spec document
2. Enumerate every discrete requirement as a numbered list (R1, R2, R3...)
   - A "discrete requirement" is any independently verifiable behavior, rule, constraint, output format, or edge case
   - One spec section may contain multiple discrete requirements
   - Exclude "What NOT to change" / negative constraints — these are boundaries, not tasks
3. Write the enumeration into a `## Requirement Traceability` section at the end of the plan document, before Self-Review
```

**改写** Self-Review section：

```markdown
## Self-Review

After writing the complete plan and extracting requirements:

**1. Spec Coverage (subagent dispatch):**

Dispatch a general-purpose subagent using the plan-coverage-reviewer-prompt template:
- Agent description: "Review plan spec coverage"
- Inputs: spec file path, plan file path (which contains the Requirement Traceability section)
- The subagent produces a traceability matrix and flags any ❌ gaps

If the subagent finds issues (❌), fix them inline by adding or modifying tasks. Re-dispatch if changes are significant.

**2. Placeholder scan (self-check):**

Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.

**3. Type consistency (self-check):**

Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks?

If you find issues, fix them inline. No need to re-review.
```

### 3.2 plan-coverage-reviewer-prompt.md

新建文件，内容为 subagent prompt 模板，核心指令：

```markdown
You are a plan coverage reviewer. Your job is to verify that every requirement from the spec is covered by the plan.

**Plan to review:** [PLAN_FILE_PATH]
**Spec for reference:** [SPEC_FILE_PATH]

## What to Check

Read the plan's `## Requirement Traceability` section to get the enumerated requirements (R1, R2, ...).

For each requirement:
1. Find it in the spec to confirm the enumeration is accurate and complete
2. Find which plan task/step covers it
3. Assess coverage: ✅ fully covered, ⚠️ partial, ❌ missing

Additionally:
- Check the spec for any requirements NOT in the traceability list (the author may have missed some)
- Scan the plan for placeholders (TBD, TODO, "implement later", vague descriptions)

## Calibration

You are a thorough reviewer, not a rubber stamp. The plan author has cognitive bias toward their own work. Your job is to find what they missed.

Flag as ❌ any requirement with no corresponding plan task.
Flag as ⚠️ any requirement where the plan task exists but doesn't fully address the spec's detail.

Do NOT approve if any ❌ exists.

## Output Format

[上面 2.3 的 Traceability Matrix 格式]
```

### 3.3 setup 微调

`patch_skills()` 需要同步新的 reviewer prompt 文件。实现时确认：如果当前只同步 `SKILL.md`，需扩展为同步 patch 目录下所有 `writing-plans-*.md` 文件到目标 skill 目录。

## 4. 不改什么

- 路由卡、SKILL.md pipeline、writing-plans 的其他 section（File Structure, Task Structure, No Placeholders, Pipeline Continuation）
- setup 的 patch 机制本身不变，只是 patch 内容变化
- 不新增独立 skill，不新增 pipeline 步骤

## 5. 测试

| 测试 | 验证方式 |
|------|---------|
| Patch 正确应用 | `bash setup --host claude` 成功，patched SKILL.md 包含新 section |
| Reviewer prompt 同步 | patched 目录下存在 plan-coverage-reviewer-prompt.md |
| 自审行为变更 | 下一个使用 writing-plans 的任务：计划文档包含 Requirement Traceability section，且 subagent 被派遣做覆盖审查 |

## 6. 权衡

| 决策 | 理由 |
|------|------|
| Subagent 而非增强 plan-document-reviewer | 现有 reviewer 是"approve unless serious gaps"，校准方向不对；新建专用 prompt 更可控 |
| 不阻塞 ⚠️ | 部分覆盖是正常的（plan 可能合并非核心需求），强制阻塞会产生大量 false positive |
| 保留类型一致性为 self-check | 跨 task 签名一致性需要完整的 plan 上下文，subagent 不持有 |
| 不改路由卡 | 不是新 skill，只是增强已有 skill 的内部行为 |
