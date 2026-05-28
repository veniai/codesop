# execution-reviewer Step Compliance 增强 设计

## 1. 问题

subagent-driven-development 的执行环存在两层审查，但都无法阻止实现者用 stub/placeholder 绕过复杂 plan 步骤。

**实测案例**：
- Plan Task 7 Step 4 写了 6 个子步骤（AI 面板：流式、消息历史、输入处理、发送按钮、响应渲染、错误处理）
- 实现者交付 `<textarea disabled></textarea>`（3 行）
- Spec reviewer ✅ 通过（"有个 AI 面板"）
- Code quality reviewer ✅ 通过（"spec review 已过，代码干净"）

**根因**：两个 reviewer 都在查"功能有没有"，没人查"功能做到了什么深度"。

### 1.1 Spec Reviewer 的缺陷

- "Compare actual implementation to requirements line by line" 是**方向性指令**，不是**过程性指令**
- 没有要求先枚举 plan 的原子子步骤再逐一核对
- 没有要求检测 placeholder/stub（disabled 元素、TODO 注释、空函数体）
- 没有复杂度比例检查（6 个子步骤只产出 3 行代码 = 红旗）
- 输出只有 ✅/❌ 二元判定，没有中间态

### 1.2 Code Quality Reviewer 的缺陷

- "Plan alignment" 与 spec reviewer 重复但更弱
- 看到已通过评审后会在对齐问题上默认认同
- 没有验证"实现了实质性功能而不是空壳"
- 没有防 stub 指令

## 2. 方案

Patch subagent-driven-development 的两个 reviewer prompt，与 writing-plans 覆盖门 采用同构方案：**枚举 → 逐一验证 → matrix**。

### 2.1 增强 spec-reviewer-prompt

改动要点：

**a) 强制子步骤枚举**

在 "Your Job" section 前插入指令：
- 把 plan 任务 中的每个原子子步骤（step、bullet、sub-requirement）枚举为 S1, S2, S3...
- 把代码中的每个实现点也枚举出来
- 做交叉比对

**b) Anti-stub 检测**

新增显式检查项：
- disabled UI 元素
- TODO/FIXME/HACK 注释
- 空函数体或 `// implement later` 注释
- placeholder 文本（"Coming Soon"、"TBD"）
- 导入未使用的组件
- 组件渲染但无交互逻辑

**c) 复杂度比例检查**

新增指令：
- 如果 plan 有 N 个子步骤但代码只有几行，标红
- 如果 plan 描述了具体行为但代码只有结构声明（有组件但没逻辑），标红

**d) Step Compliance Matrix 输出**

输出格式从二元 ✅/❌ 改为：

```markdown
## Spec Compliance Review

**Status:** ✅ Compliant | ⚠️ Partial | ❌ Non-compliant

**Step Compliance Matrix:**

| Step | Plan Requirement | Implementation | Status |
|------|-----------------|---------------|--------|
| S1   | Streaming response display | Missing | ❌ |
| S2   | Message history scrollback | Empty array, no render | ❌ |
| S3   | Input handling + send | `<textarea disabled>` | ❌ Stub |
| S4   | Response rendering | Not present | ❌ |
| S5   | Error handling | Not present | ❌ |
| S6   | Loading states | Not present | ❌ |

**Stub/Placeholder Warnings (if any):**
- S3: `<textarea disabled>` — disabled element with no interactivity

**Complexity Flags (if any):**
- Plan has 6 sub-steps but implementation is 3 lines of JSX. Expected ~50-80 lines.

**Issues:**
- [具体描述]

**Extra/Unneeded Work (if any):**
- [具体描述]
```

**Status 判定**：
- ✅ Compliant：所有 S 至少 ⚠️，无 ❌，无 Stub 警告
- ⚠️ Partial：有 ⚠️ 但无 ❌（部分覆盖但功能骨架存在）
- ❌ Non-compliant：有任何 ❌ 或 Stub 警告

### 2.2 增强 code-quality-reviewer-prompt

改动要点：

**a) 去掉重复的 Plan alignment**

code-reviewer.md 的 "Plan alignment" section 与 spec reviewer 职责重叠。改为 **Implementation Depth** section：

```markdown
**Implementation depth (not just existence):**
- Spec review confirmed features exist. Your job is different.
- Are features substantively implemented, not just structurally present?
- Flag any feature that is a skeleton, stub, or placeholder despite passing spec review.
- Check: are there disabled components, empty event handlers, TODO comments, or
  functions that return hardcoded values where the plan expects real logic?
```

**b) 不要因为已通过评审就假设功能完整**

在 Calibration section 新增：

```markdown
Do NOT assume spec review caught everything. Spec review checks feature existence;
you check implementation substance. A disabled textarea has no code quality issues,
but it is not a real implementation. If the plan expects a complex feature and the
code shows a trivial implementation, flag it as Important regardless of code quality.
```

## 3. 改动范围

| 文件 | 操作 | 改什么 |
|------|------|--------|
| `patches/superpowers/subagent-driven-development-spec-reviewer-prompt.md` | 新增 | 替换 spec-reviewer-prompt，增加子步骤枚举 + anti-stub + 复杂度检查 + matrix 输出 |
| `patches/superpowers/subagent-driven-development-code-quality-reviewer-prompt.md` | 新增 | 替换 code-quality-reviewer-prompt，Plan alignment 改为 Implementation Depth |
| `patches/superpowers/subagent-driven-development-SKILL.md` | 不改 | 控制流程不变 |
| `setup` | 需扩展 | `patch_skills()` 需要支持同步 reviewer prompt 文件（不只 SKILL.md） |
| `config/codesop-router.md` | 不改 | 不是新 skill |
| `SKILL.md` | 不改 | 不是新 pipeline 步骤 |

### 3.1 setup 扩展

当前 `patch_skills()` 对每个 skill 只同步 `SKILL.md`。subagent-driven-development 的 reviewer prompt 文件在 `skills/subagent-driven-development/` 目录下，需要扩展同步逻辑。

**方案**：在 `patch_skills()` 中，对 `subagent-driven-development` 额外同步 2 个 reviewer prompt 文件：

```bash
# subagent-driven-development: spec reviewer + code quality reviewer
local sdd_spec="$plugin_dir/skills/subagent-driven-development/spec-reviewer-prompt.md"
local sdd_spec_patch="$patches_dir/subagent-driven-development-spec-reviewer-prompt.md"
if [ -f "$sdd_spec" ] && [ -f "$sdd_spec_patch" ]; then
  if ! diff -q "$sdd_spec" "$sdd_spec_patch" >/dev/null 2>&1; then
    cp "$sdd_spec_patch" "$sdd_spec"
    patched=$((patched + 1))
  fi
fi

local sdd_cq="$plugin_dir/skills/subagent-driven-development/code-quality-reviewer-prompt.md"
local sdd_cq_patch="$patches_dir/subagent-driven-development-code-quality-reviewer-prompt.md"
if [ -f "$sdd_cq" ] && [ -f "$sdd_cq_patch" ]; then
  if ! diff -q "$sdd_cq" "$sdd_cq_patch" >/dev/null 2>&1; then
    cp "$sdd_cq_patch" "$sdd_cq"
    patched=$((patched + 1))
  fi
fi
```

遵循现有的硬编码 pattern（和 writing-plans/brainstorming/finishing 同风格），不引入循环或 manifest。

### 3.2 Patch 头注释

新增的两个 patch 文件都需要 HTML 头注释说明变更原因和 revert 方式。

### 3.3 不新建 patch 给 SKILL.md

subagent-driven-development 的 SKILL.md（控制器）不需要改——它引用 `./spec-reviewer-prompt.md` 和 `./code-quality-reviewer-prompt.md` 作为模板，patch 覆盖这两个模板文件即可。

## 4. 不改什么

- 控制器流程（implementer → spec reviewer → code quality reviewer → done）
- implementer-prompt.md（实现者指令不改）
- 路由卡、SKILL.md pipeline
- 不新增独立 skill

## 5. 测试

| 测试 | 验证方式 |
|------|---------|
| Patch 同步 | `bash setup --host claude` 成功，输出包含 patched N files（N >= 3） |
| spec-reviewer-prompt 内容 | grep "Step Compliance Matrix" + "stub" + "Complexity" |
| code-quality-reviewer-prompt 内容 | grep "Implementation depth" + "NOT assume spec review" |
| 全量测试 | `bash tests/run_all.sh` 通过 |

## 6. 权衡

| 决策 | 理由 |
|------|------|
| 增强 reviewer 而非改 controller | 控制器只负责 dispatch，reviewer 负责 quality gate；改 reviewer 更精准 |
| 硬编码 patch 同步而非通用循环 | 与现有 3 个 skill patch 同风格，不过度工程化 |
| 不改 implementer-prompt | 实现者的问题不是指令不够，而是遇到复杂任务选择绕路；reviewer 才是兜底 |
| Spec reviewer 做 step 枚举 | 和 writing-plans 的 requirement extraction 同构； reviewer 比 controller 更适合做细粒度检查 |
| Code quality 做 depth 检查 | 与 spec reviewer 互补：spec reviewer 查广度（每个 step 有没有），code quality 查深度（每个 step 实现是不是真的） |
