# writing-plans Spec Coverage Gate 设计

## 1. 问题

writing-plans 的自审步骤无法有效拦截 spec 需求遗漏。实测两对 spec→plan（共 57 个需求）发现：

- 核心功能需求覆盖良好
- 二级规则（条件处理、跳过逻辑、边缘情况说明、设计理据）被系统性遗漏
- 自审"skim"只做 section 级匹配，不做 requirement 级匹配
- 自己审自己，认知偏差不可避免

## 2. 方案

Patch writing-plans 自审步骤，两处改动（reviewer prompt 内联到 SKILL.md，不新建独立文件）：

### 2.1 新增 Requirement Extraction 步骤

在 Self-Review 前插入 `## Requirement Extraction` section。

**指令要点**：
- 读 spec，枚举所有离散需求为编号列表（R1, R2, R3...）
- "离散需求"定义：任何可独立验证的行为、规则、约束、输出格式、边缘条件
- 一个 spec section 可能包含多个离散需求（如 10 个测试断言 = 10 个需求）
- 枚举结果写入 plan 文档的 `## Requirement Traceability` section（作为 plan 文档的最后一个 section）
- 显式忽略 "What NOT to change" 类负面需求（这些是约束，不需要 plan task 覆盖）

### 2.2 自审改为 subagent 派遣

将 "This is a checklist you run yourself -- not a subagent dispatch" 改为派遣 general-purpose subagent 做独立审查。

**原因**：写 plan 的 agent 自审自己写的 plan 有认知偏差。独立 subagent 读取 spec + plan + requirement list，不带"作者视角"。

**subagent 输入**：
- spec 文件路径
- plan 文件路径（包含 `## Requirement Traceability` section）

**subagent 职责**：
1. 需求覆盖检查：逐行验证 R1..RN 每个需求是否被 plan 的某个 task/step 覆盖
2. Placeholder 扫描：检查 plan 中是否有 TBD、TODO、"implement later"等占位符
3. 扫描 spec，发现 Requirement Traceability 中遗漏的需求（标记为 UNENUMERATED，按 ❌ 规则处理）
4. 输出 traceability matrix + issues list

**subagent 不负责**：类型一致性检查（需要上下文连续性，保留为 self-check）

**Re-dispatch 规则**：修复任何 ❌ 后必须 re-dispatch，最多 2 轮。仅修复 ⚠️ 不需要 re-dispatch。

### 2.3 覆盖检查输出 Traceability Matrix

Subagent 输出格式：

```markdown
## Plan Coverage Review

**Status:** Approved | Issues Found

**Traceability Matrix:**

| Req | Spec Section | Plan Task | Status |
|-----|-------------|-----------|--------|
| R1  | §1.1        | Task 2 Step 3 | ✅   |
| R2  | §1.2        | Task 3 Step 2 + Task 5 Step 1 | ⚠️ |
| R3  | §1.3        | MISSING        | ❌   |

**Issues (if any):**
- R2 (§1.2): [具体描述覆盖不足的部分]
- R3 (§1.3): [具体描述缺失了什么]

**Recommendations (advisory):**
- [不阻塞 approval 的改进建议]
```

**Status 判定**：
- Approved：所有需求至少 ⚠️，无 ❌
- Issues Found：有任何 ❌（需求完全无覆盖）
- ⚠️（需求被部分覆盖但细节不足）不阻塞 approval，但必须在 Issues 中列出
- Plan Task 列允许跨 task 映射，用 `+` 连接（如 `Task 3 Step 2 + Task 5 Step 1`）

### 2.4 保留的自检查项

类型一致性检查保留为 plan 作者的 self-check，因为需要跨 task 的上下文连续性（function name/signature 在 Task 3 和 Task 7 必须一致）。

## 3. 改动范围

| 文件 | 操作 | 改什么 |
|------|------|--------|
| `patches/superpowers/writing-plans-SKILL.md` | 修改 | 新增 Requirement Extraction section；改写 Self-Review section（含内联 reviewer prompt） |
| `config/codesop-router.md` | 不改 | 不是新 skill，不新增路由条目 |
| `SKILL.md` | 不改 | 不是新 pipeline 步骤 |
| `setup` | 不改 | Reviewer prompt 内联到 SKILL.md，不需要扩展 patch_skills() |

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
3. Write the enumeration into a `## Requirement Traceability` section at the end of the plan document, as its final section
```

**改写** Self-Review section：

```markdown
## Self-Review

After writing the complete plan and extracting requirements:

**1. Spec Coverage (subagent dispatch):**

Dispatch a general-purpose subagent to review spec coverage. Use this prompt:

> You are a plan coverage reviewer. Your job is to verify that every requirement
> from the spec is covered by the plan.
>
> **Plan to review:** [PLAN_FILE_PATH]
> **Spec for reference:** [SPEC_FILE_PATH]
>
> ## What to Check
>
> Read the plan's `## Requirement Traceability` section to get the enumerated
> requirements (R1, R2, ...).
>
> For each requirement:
> 1. Find it in the spec to confirm the enumeration is accurate
> 2. Find which plan task/step covers it (use `+` for cross-task coverage)
> 3. Assess coverage: ✅ fully covered, ⚠️ partial, ❌ missing
>
> Additionally:
> - Optionally scan the spec for requirements NOT in the traceability list
> - Scan the plan for placeholders (TBD, TODO, "implement later", vague descriptions)
>
> ## Calibration
>
> You are a thorough reviewer, not a rubber stamp. The plan author has cognitive
> bias toward their own work. Your job is to find what they missed.
>
> Flag as ❌ any requirement with no corresponding plan task.
> Flag as ⚠️ any requirement where the plan task exists but doesn't fully address
> the spec's detail.
>
> Do NOT approve if any ❌ exists.
>
> Example ❌: Spec says "output must include error code and message" but plan
> only has a task for "output error message" — error code is missing.
>
> Example ⚠️: Spec says "validate email, phone, and address" but plan task only
> shows validation code for email and phone — address validation is implied but
> not shown.
>
> ## Output Format
>
> ## Plan Coverage Review
>
> **Status:** Approved | Issues Found
>
> **Traceability Matrix:**
> | Req | Spec Section | Plan Task | Status |
> |-----|-------------|-----------|--------|
> | R1  | §X.X        | Task N Step M | ✅/⚠️/❌ |
>
> **Issues (if any):**
> - R? (§X.X): [what's missing]
>
> **Recommendations (advisory):**
> - [non-blocking suggestions]

- Agent description: "Review plan spec coverage"
- Inputs: replace [PLAN_FILE_PATH] and [SPEC_FILE_PATH] with actual paths

If the subagent finds ❌ issues: fix them inline by adding or modifying tasks, then
re-dispatch. Maximum 2 rounds. Fixing ⚠️ only does not require re-dispatch.

**2. Placeholder scan (self-check):**

Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.

**3. Type consistency (self-check):**

Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks?

If you find issues, fix them inline. No need to re-review.
```

## 4. 不改什么

- 路由卡、SKILL.md pipeline、writing-plans 的其他 section（File Structure, Task Structure, No Placeholders, Pipeline Continuation）
- setup 的 patch_skills() 不变（reviewer prompt 内联，不需要扩展同步逻辑）
- 不新增独立 skill，不新增 pipeline 步骤，不新增独立 prompt 文件

## 5. 测试

| 测试 | 验证方式 |
|------|---------|
| Patch 正确应用 | `bash setup --host claude` 成功，patched SKILL.md 包含 Requirement Extraction 和改写后的 Self-Review |
| 自审行为变更 | 下一个使用 writing-plans 的任务：plan 文档包含 Requirement Traceability section，且 subagent 被派遣做覆盖审查 |
| Re-dispatch 收敛 | 覆盖审查最多 2 轮，不会无限循环 |

## 6. 权衡

| 决策 | 理由 |
|------|------|
| Subagent 而非增强 plan-document-reviewer | 现有 reviewer 是"approve unless serious gaps"，校准方向不对；新建专用 prompt 更可控 |
| Reviewer prompt 内联到 SKILL.md | patch_skills() 只同步 SKILL.md，不扩展 setup；prompt 内容小（约 30 行），内联不膨胀 |
| 不阻塞 ⚠️ | 部分覆盖是正常的（plan 可能合并非核心需求），强制阻塞会产生大量 false positive |
| 保留类型一致性为 self-check | 跨 task 签名一致性需要完整的 plan 上下文，subagent 不持有 |
| Re-dispatch 上限 2 轮 | 有界收敛；实际中 1 轮修复后 re-dispatch 确认即可，2 轮是安全上限 |
| Spec 二次枚举为必需步骤 | reviewer 必须独立扫描 spec，发现的遗漏需求标记 UNENUMERATED 并按 ❌ 规则处理。主要枚举仍由 plan 作者完成，reviewer 扫描是兜底 |
| 不做"约束合规性检查" | 覆盖检查和约束验证是不同关注点，本次不改 reviewer 职责范围 |

## 7. Codex 审查记录

审查意见 7 条，采纳 6 条，拒绝 1 条：

| # | Codex 意见 | 判定 | 理由 |
|---|-----------|------|------|
| 1 | Reviewer prompt 加载机制未定义 | 采纳（改方案） | 改为内联到 SKILL.md，避免改 setup |
| 2 | Re-dispatch 缺判定标准 | 采纳 | 定义为"修复 ❌ 后 re-dispatch，最多 2 轮" |
| 3 | 跨 task 需求映射格式 | 采纳 | Plan Task 列允许 `+` 连接 |
| 4 | Spec 二次枚举降级为 advisory | 采纳 | Reviewer prompt 中标为 "Optionally scan" |
| 5 | Traceability section 位置描述修正 | 采纳 | 改为"plan 文档最后一个 section" |
| 6 | "What NOT to change" 约束合规检查 | 不采纳 | 职责膨胀，超出覆盖检查范围 |
| 7 | Reviewer prompt 加 calibration 示例 | 采纳 | 新增 2 个 ❌/⚠️ 判定示例 |
