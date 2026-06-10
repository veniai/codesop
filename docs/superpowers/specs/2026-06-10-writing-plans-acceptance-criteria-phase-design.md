# writing-plans Acceptance Criteria Phase 设计

## 1. 问题

当前 writing-plans skill 从 spec 直接跳到任务拆解。实测发现三类偏差：

1. **遗漏**：spec 的条件规则、边界情况被跳过（Requirement Traceability 已部分缓解，但仍然只检查"plan 覆盖了 spec"，不检查"plan 的产出是否可验证"）
2. **变形**：plan 盖了 spec 需求，但实现方式偏离设计意图——因为没人提前定义"什么叫正确实现"
3. **粒度不当**：plan 的 task 太粗（一个 step 包一整块功能）或太细（每个 grep 一 个 step），因为缺乏"每个任务必须可验证"的约束

根因：**从 spec 到 task 之间缺少"定义什么叫做完"这个环节。** Goal Coding 的核心洞察——AI 能力已经足够自治执行，瓶颈在于验收标准的清晰度。

## 2. 方案

改造 writing-plans 内部流程，拆成 Phase A（acceptance criteria + 复杂度评估）和 Phase B（task decomposition）。simple/moderate 任务只走 Phase A，complex 走完整 A+B。

**不新增 skill、不改路由表、不改链路组装规则。**

### 2.1 新流程

```
Phase A（所有任务必走）:
  1. Scope Check（原有，不变）
  2. Requirement Extraction R1..RN（原有，不变）
  3. Acceptance Criteria 编写（新增）
     - 对每条 Rn，用 Given/When/Then 模板写验收标准
     - 每条必须附带验证命令和 pass/fail 判定
  4. 复杂度评估（新增）
     - 基于可观测指标：文件数、模块数
     - 输出 simple / moderate / complex + 判定证据
     - override 规则：public API 变更 / 数据迁移 / 安全 → 自动 complex

Phase B（仅 complex 任务走）:
  5. File Structure（原有）
  6. Task Decomposition（原有）
  7. Self-Review（原有，用 acceptance criteria 做覆盖检查）

Phase B 跳过时（simple/moderate）:
  - 产出 acceptance criteria 文档 + 复杂度标签
  - 保留轻量 Scope Check（已在 Step 1 完成）
  - 直接进入执行环节（subagent-driven-development 或 /goal）
```

### 2.2 Acceptance Criteria 模板

每条验收标准必须包含以下字段，缺一不可：

```markdown
G{n}: [一句话描述可验证行为]
    Given: [前置条件 / 输入状态]
    When: [触发动作]
    Then: [预期结果]
    Verify: [具体验证命令或检查方法]
    Boundary: [至少一个边界/错误路径的验证点]
```

**质量门**：

| 维度 | 要求 | 反模式 |
|------|------|--------|
| 具体性 | 精确到可观测的行为 | "系统应该稳定" |
| 可验证 | 给出验证命令或检查方法 | "确保代码质量" |
| 非空虚 | 不能被 trivially satisfiable（如"代码能编译"） | "无运行时错误" |
| 完备性 | 覆盖正常路径 + 至少一个边界/错误路径 | 只测 happy path |
| 无歧义 | 只有一种合理解释 | "性能要好" |

**Adversarial check（内置自检，不 dispatch subagent）**：
对每条 criterion，plan 作者必须回答：
> "如果我用最偷懒的方式实现这个功能（hardcode 返回值、只处理 happy path、跳过边界检查），这个 criterion 还能抓住我吗？"
如果答案是否 → criterion 太弱 → 回炉重写。

这个自检替代了原方案中的 subagent adversarial validation，成本为零 token。

### 2.3 复杂度评估

**Primary 分类（可观测指标）**：

| 等级 | 条件 |
|------|------|
| simple | 1-2 个文件，无跨模块依赖 |
| moderate | 3-5 个文件，或涉及 2 个模块 |
| complex | >5 个文件，或涉及 3+ 模块 |

**Override 规则**（任一命中即升级为 complex）：
- 涉及 public API 变更
- 涉及数据迁移或数据格式变更
- 涉及安全性相关逻辑（认证、授权、加密）
- 涉及构建/部署流程变更

**输出格式**：

```markdown
## 复杂度评估

**等级:** simple | moderate | complex
**文件数:** N
**模块:** [列出涉及模块]
**判定依据:** [一句话说明为什么是这个等级]
**Override:** [如有，列出触发项]
```

### 2.4 Acceptance Criteria 产出格式

Phase A 的产出写入 plan 文档的 `## Acceptance Criteria` section（位于 `## Requirement Traceability` 之前）：

```markdown
## Acceptance Criteria

G1: [描述]
    Given: ...
    When: ...
    Then: ...
    Verify: `具体命令`
    Boundary: [边界/错误路径]

G2: ...

## 复杂度评估
**等级:** moderate
**文件数:** 3
**模块:** patches/superpowers
**判定依据:** 3 files in 1 module, no API change

## Requirement Traceability
（原有内容不变）

---

## /goal 导出（可选）

"spec reviewer 能检测空函数体和 hardcode 返回值，
code quality reviewer 校准包含 Implementation Depth 验证，
bash tests/run_all.sh 全绿"
```

`/goal 导出` 段落是可选的。如果任务后续会用 /goal 执行，从 G1..GN 压缩成一段自然语言。格式不约束主文档的设计质量。

### 2.5 Phase B 跳过时的轻量检查

simple/moderate 任务跳过 Phase B 时，Scope Check（Step 1）已在前完成。额外做三条 checklist 问题：

1. **文件职责明确？** 每个涉及文件的职责能一句话说清。不能 → 考虑升级 moderate。
2. **无隐性依赖？** 不存在"改 A 必须先改 B"的非显而易见的依赖。存在 → 考虑升级 moderate。
3. **测试策略清晰？** 每条 Gn 都有对应的 Verify 命令。缺失 → 补充。

三条全通过 → 跳过 Phase B，进入执行。任一不通过 → 升级复杂度，走 Phase B。

### 2.6 Self-Review 改造（仅 complex 任务）

complex 任务走 Phase B 时，Self-Review 的覆盖检查改为以 acceptance criteria 为主参照：

**变更点**：subagent reviewer prompt 中，除了现有 Traceability Matrix（plan task ↔ spec requirement），增加第二张表：

```markdown
**Acceptance Coverage Matrix:**
| AC | Spec Requirement | Plan Task | Status |
|----|-----------------|-----------|--------|
| G1 | R1              | Task 2 Step 3 | ✅/⚠️/❌ |
```

Reviewer 同时验证：
1. Plan task 覆盖了 spec requirement（原有）
2. Plan task 的实现能达到 acceptance criteria 的 Verify 条件（新增）

如果 plan task 存在但无法通过 G{n} 的 Verify → 标记 ⚠️（plan 需要补强验证步骤）。

## 3. 改动范围

| 文件 | 操作 | 改什么 |
|------|------|--------|
| `patches/superpowers/writing-plans-SKILL.md` | 修改 | 新增 Acceptance Criteria section + 复杂度评估 section + Phase A/B 分流逻辑 + Self-Review 增加覆盖矩阵 |
| `config/codesop-router.md` | 不改 | 不是新 skill |
| `SKILL.md` | 不改 | 不是新 pipeline 步骤 |
| `setup` | 不改 | 改动内联到 SKILL.md，不需要扩展 patch_skills() |

### 3.1 writing-plans-SKILL.md 具体改动

**Patch header 更新**：在 Changes vs upstream 列表中追加第 5、6 条。

**新增 section（在 Requirement Extraction 和 Self-Review 之间插入）**：

```markdown
## Acceptance Criteria

After extracting requirements (R1..RN), write acceptance criteria for each.

For each requirement, write one acceptance criterion using this template:

    G{n}: [one sentence describing verifiable behavior]
        Given: [precondition / input state]
        When: [trigger action]
        Then: [expected result]
        Verify: [specific verification command or check method]
        Boundary: [at least one boundary/error path check]

**Quality gate** — every criterion MUST pass all five dimensions:
- Specific: describes an observable behavior, not a vague quality
- Verifiable: includes a concrete command or check method
- Non-vacuous: cannot be trivially satisfied (e.g. "code compiles" is vacuous)
- Complete: covers normal path + at least one boundary or error path
- Unambiguous: admits only one reasonable interpretation

**Adversarial self-check** (built-in, no subagent dispatch):
For each criterion, answer honestly:
> "If I implemented this in the laziest way possible (hardcoded returns,
> happy-path-only, skipping boundary checks), would this criterion still
> catch me?"
If no → the criterion is too weak → rewrite it.

Write all criteria into a `## Acceptance Criteria` section in the plan document,
BEFORE the `## Requirement Traceability` section.

## Complexity Assessment

After writing acceptance criteria, assess task complexity.

**Primary classification (observable metrics):**
- simple: 1-2 files, no cross-module dependency
- moderate: 3-5 files, or involves 2 modules
- complex: >5 files, or involves 3+ modules

**Override rules** (any hit upgrades to complex):
- Public API change
- Data migration or format change
- Security-related logic (auth, encryption)
- Build/deploy pipeline change

Output:

    ## Complexity Assessment
    **Level:** simple | moderate | complex
    **Files:** N
    **Modules:** [list modules]
    **Evidence:** [one sentence justifying the level]
    **Override:** [if any, list triggered items]

## Phase Split

Based on complexity assessment:

**simple / moderate:**
Run a 3-question checklist:
1. Is each file's responsibility clear in one sentence? If not → consider upgrading.
2. Are there no hidden dependencies ("must change B before A")? If yes → consider upgrading.
3. Does every G{n} have a corresponding Verify command? If missing → add it.

All three pass → SKIP Phase B (File Structure, Task Decomposition, full Self-Review).
Proceed directly to execution. The acceptance criteria document IS the plan.

Any fail → upgrade complexity, proceed to Phase B.

**complex:**
Proceed to File Structure → Task Decomposition → Self-Review (enhanced with
Acceptance Coverage Matrix).

## /goal Export (Optional)

If the task will be executed via /goal, append a summary paragraph after the
Acceptance Criteria section:

    ## /goal Export
    "[Compressed natural-language summary of G1..GN, suitable for /goal input]"

This is an export adapter — it does not constrain the design quality of the
acceptance criteria themselves.
```

**修改 Self-Review section**（仅 complex 任务触达此处）：

在 subagent reviewer prompt 的 `## Output Format` 中，Traceability Matrix 之后追加：

```markdown
**Acceptance Coverage Matrix:**
| AC | Spec Req | Plan Task | Status |
|----|----------|-----------|--------|
| G1 | R1       | Task 2 Step 3 | ✅/⚠️/❌ |

For each acceptance criterion, verify that the plan's implementation
steps can actually achieve the criterion's Verify condition.
If a plan task exists but cannot pass G{n}'s Verify → mark ⚠️.
```

## 4. 不改什么

- 路由表、SKILL.md pipeline、链路组装规则
- setup 的 patch_skills()
- Scope Check、File Structure、Task Structure、No Placeholders、Pipeline Continuation
- 不新增独立 skill，不新增 pipeline 步骤

## 5. 测试

| 测试 | 验证方式 |
|------|---------|
| Patch 正确应用 | `bash setup --host claude` 成功，patched SKILL.md 包含 Acceptance Criteria + Complexity Assessment + Phase Split |
| Phase A 行为变更 | 下一个 writing-plans 任务：plan 文档包含 `## Acceptance Criteria` section（G1..GN 格式）和 `## Complexity Assessment` section |
| Phase B 跳过 | simple/moderate 任务不生成 File Structure / Task Decomposition，直接输出 acceptance criteria 进入执行 |
| Phase B 执行 | complex 任务走完整流程，Self-Review 包含 Acceptance Coverage Matrix |
| 自检有效性 | acceptance criteria 的 Adversarial self-check 能识别空虚标准（如"代码能编译"）并触发重写 |
| 复杂度判定一致性 | 同一任务在不同 session 中得到相同复杂度等级（基于可观测指标） |

## 6. 权衡

| 决策 | 理由 |
|------|------|
| 内嵌 phase 而非新 skill | 避免跨 skill 传递 R1..RN 的协调成本；R1..RN 枚举结果在同一 skill 内共享，不需要跨 skill 传递；复杂度评估结果直接决定内部流程分支 |
| Given/When/Then 模板替代 adversarial subagent | 结构化模板成本为零 token，且强制覆盖 5 个质量维度；adversarial subagent 对 15 个 criterion 可能消耗 75k-300k token，边际收益不值得 |
| 内置 adversarial 自检 | "偷懒实现能通过吗？"这个问题是自省式检查，不需要 subagent，但能抓住大部分空虚标准。complex 任务可选增强为 codex:rescue review |
| 可观测指标做 primary 分类 | 文件数和模块数客观可数，避免 AI 倾向于高估复杂度 |
| Override 规则自动升级 | public API / 数据迁移 / 安全是高风险标记，不管文件数多少都应走完整流程 |
| simple/moderate 保留轻量 checklist | 跳过 Phase B 不等于跳过所有检查；三条问题做兜底 |
| /goal 导出为可选 adapter | 不让 /goal 的格式约束倒逼 acceptance criteria 的设计质量 |
| Self-Review 增加覆盖矩阵 | complex 任务的覆盖检查同时验证 spec↔plan 和 criteria↔plan，双重保险 |

## 7. Codex 审查记录

审查意见 6 方面，核心分歧和采纳情况：

| # | Codex 意见 | 判定 | 理由 |
|---|-----------|------|------|
| 1 | 不要新增 skill，改嵌入 writing-plans | **采纳** | 跨 skill 协调成本高于收益，R1..RN 共享在同一 skill 内更自然 |
| 2 | Given/When/Then 模板替代 adversarial subagent | **采纳** | 零 token 成本，结构化强制覆盖比 subagent 偷懒测试更可靠 |
| 3 | 复杂度用可观测指标做 primary | **采纳** | 文件数 + 模块数客观可数，避免主观偏差 |
| 4 | /goal 兼容作为导出 adapter | **采纳** | 不让格式约束倒逼 criterion 设计 |
| 5 | 跳过 writing-plans 时保留轻量检查 | **采纳** | Scope Check + 3 条 checklist 兜底，防止 moderate 任务漏检查 |
| 6 | spec→criterion 信息损耗风险 | **记录** | 执行者（subagent-driven-development）应读 acceptance criteria + spec，不只读 criteria。这是执行 skill 的约束，不在本次 writing-plans 改动范围内 |
