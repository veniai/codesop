# writing-plans Acceptance Criteria Phase 设计

## 1. 问题

当前 writing-plans skill 从 spec 直接跳到任务拆解。实测发现三类偏差：

1. **遗漏**：spec 的条件规则、边界情况被跳过（Requirement Traceability 已部分缓解，但仍然只检查"plan 覆盖了 spec"，不检查"plan 的产出是否可验证"）
2. **变形**：plan 覆盖了 spec 需求，但实现方式偏离设计意图——因为没人提前定义"什么叫正确实现"
3. **粒度不当**：plan 的 task 太粗（一个 step 包一整块功能）或太细（每个 grep 一个 step），因为缺乏"每个任务必须可验证"的约束

实测证据（来自两个历史 spec→plan 对照）：
- Pair 1（execution-reviewer）：spec 5 个需求（2.1a-e）被塞进 1 个 130 行的 Step 1，Partial 状态定义被缩窄（丢掉 1-49% 和"functional skeleton exists"），monolithic step 自分解被吞入 Step 1 无独立验证
- Pair 2（writing-plans coverage gate）：UNENUMERATED scan 从 mandatory 降级为 Optional，7 个 spec section 只有 1 个 implementation task

根因：**从 spec 到 task 之间缺少"定义什么叫做完"这个环节。** Goal Coding 的核心洞察——AI 能力已经足够自治执行，瓶颈在于验收标准的清晰度。

## 2. 方案

改造 writing-plans 内部流程，在 Requirement Extraction 之后、Self-Review 之前插入 Acceptance Criteria + Gap Scan + Complexity Assessment + Phase Split + Lightweight Plan 五个 section。

**不新增 skill、不改路由表、不改链路组装规则。只改一个文件。**

### 2.1 新流程

```
Phase A（所有任务必走）:
  1. Scope Check（不变）
  2. Requirement Extraction R1..RN（不变）
  3. Acceptance Criteria G1..GN（新增）
     - 行为变更：Given/When/Then 完整格式
     - 机械编辑：简化格式（Criterion + Verify + Failure prevented）
     - Adversarial self-check（零 token）
     - Coverage Matrix（Gn ↔ Rn M:N + Verification 列）
  4. Gap Scan（新增）
     - 负面用例、边界条件、回归风险、配置/环境、文档/API、迁移/兼容
  5. Complexity Assessment（新增）
     - 可观测指标：文件数 + 模块数
     - Override 规则：public API / 数据迁移 / 安全 / 构建 → 自动 complex
     - 回退触发：组合判断（不仅看文件数）

  ┌ simple/moderate:
  │   6. Lightweight Plan（统一 schema，brief guidance，M:N acceptance_ids）
  │   7. Pipeline Continuation
  │
  └ complex:
      6. File Structure → Task Decomposition（不变）
      7. Self-Review（改造：增加 Acceptance Coverage Matrix）
      8. Pipeline Continuation
```

### 2.2 Acceptance Criteria 格式

**行为变更**（新功能、接口变化、用户可观测行为）：

```markdown
G{n}: [一句话描述可验证行为]
    Given: [前置条件]
    When: [触发动作]
    Then: [预期结果]
    Verify: [具体验证命令]
    Boundary: [边界/错误路径]
    Covers: R{n}, R{n}...
```

**机械编辑**（bug fix、配置调整、文本替换）：

```markdown
G{n}: [描述变更内容]
    Verify: [验证命令]
    Failure prevented: [防止什么错误]
    Covers: R{n}
```

**Adversarial self-check**：
> "偷懒实现能通过吗？如果我用 hardcode/只走 happy path/跳过边界检查，这个 Gn 还能抓住我吗？"
> 不能 → 重写。

**Coverage Matrix**：

| Gn | Covers Rn | Verification |
|----|-----------|-------------|
| G1 | R1, R3    | test        |
| G2 | R2        | command     |

每个 Rn 至少被一个 Gn 覆盖，每个 Gn 至少关联一个 Rn。

### 2.3 Gap Scan

Coverage Matrix 之后，逐项检查（仅包含相关类别）：

- [ ] 负面用例：错误路径、无效输入、权限不足
- [ ] 边界条件：空值、极值、并发
- [ ] 回归风险：改动是否破坏现有功能
- [ ] 配置/环境：环境变量、配置文件、平台差异
- [ ] 文档/API：公开接口变更是否同步文档
- [ ] 迁移/兼容：数据格式变更是否需要迁移

发现遗漏 → 补充 Gn。

### 2.4 Complexity Assessment

**Primary 分类**：
- simple: 1-2 文件，无跨模块
- moderate: 3-5 文件，或 2 个模块
- complex: >5 文件，或 3+ 模块

**Override 规则**：public API / 数据迁移 / 安全 / 构建 → 自动 complex

**回退触发**（Phase B 时组合判断）：
- 文件数跨阈值
- 跨层、跨包、跨 skill 修改
- 新增公共接口或 pipeline 行为
- AC 无法映射到文件结构

**AC 处理**：回退时默认冻结。仅当 Phase B 发现 AC 基于错误假设时允许修订，记录原因。

### 2.5 Lightweight Plan

simple/moderate 任务的精简 plan。统一 schema（和 full plan 同结构）：

```markdown
### Task N: [description]
**Scope:** [做什么]
**Acceptance IDs:** G1, G3
**Likely files:** `path/to/file.sh`
**Implementation guidance:** brief
**Key direction:** [一句话方向]
**Validation:** [Gn Verify 命令]
**Out of scope:** [不做什么]
```

Task 边界遵循实现内聚性，Gn 和 Task 是 M:N 关系。

### 2.6 Self-Review 改造（仅 complex）

subagent reviewer prompt 的 Output Format 增加第二张表：

```markdown
**Acceptance Coverage Matrix:**
| Gn | Spec Req | Plan Task | Status |
|----|----------|-----------|--------|
| G1 | R1       | Task 2 Step 3 | ✅/⚠️/❌ |
```

## 3. 改动范围

| 文件 | 操作 | 改什么 |
|------|------|--------|
| `patches/superpowers/writing-plans-SKILL.md` | 修改 | 更新 patch header + 新增 5 个 section + 改造 Self-Review + Pipeline Continuation 触发点 |
| `config/codesop-router.md` | 不改 | 不是新 skill |
| `SKILL.md` | 不改 | 不是新 pipeline 步骤 |
| `setup` | 不改 | 改动内联到 SKILL.md |

## 4. 不改什么

- 路由表、SKILL.md pipeline、链路组装规则
- setup 的 patch_skills()
- Scope Check、File Structure、Task Structure、No Placeholders、Bite-Sized Task Granularity、Plan Document Header、Remember

## 5. 测试

| 测试 | 结果 |
|------|------|
| Patch 正确应用 | ✅ `bash setup --host claude` 成功，1 file patched |
| 全量测试 | ✅ 10/10 passed |
| Patched SKILL.md 包含所有新 section | ✅ Acceptance Criteria + Gap Scan + Complexity Assessment + Phase Split + Lightweight Plan + Acceptance Coverage Matrix |
| 用新流程重写 execution-reviewer plan | ✅ 产出 v2 plan，11 条 Gn，4 个 lightweight task |
| Question 2 有效性验证 | ✅ 第一轮 7/11 验证命令有假阳性，加 Q2 后第二轮 3/3 命令下意识用 sed 跳注释 |

## 5.1 迭代优化（实测后第 2 轮）

用新流程写 plan 时发现的问题及修正：

| 问题 | 证据 | 修正 |
|------|------|------|
| Coverage Matrix 冗余 | 每个 Gn 已有 `Covers: Rn` 字段，矩阵只是重排成表，实测 11 行全部 1:1，0 新信息 | 删除强制表格，改为一句覆盖检查规则 |
| Gap Scan 6 项 0 产出 | 测试 plan 扫描 6 项，4 项"已覆盖"2 项"不涉及"，0 个新 Gn | 合并为 3 项（边缘情况、回归风险、集成） |
| 行为/机械分类模糊 | G4（monolithic step 自拆分）是新功能行为但用了机械编辑格式，丢失 Boundary 信息 | 加"When in doubt, use full format"指导 |
| Lightweight plan 无 rollback | rollback triggers 写"Phase B 检查"，但 simple/moderate 跳过 Phase B | 加实现者 escalate 机制 |
| 验证命令假阳性 | adversarial self-check 只问"偷懒能过吗"，7/11 条 grep 命中 HTML 注释 | 加 Question 2：验证命令会骗人吗？ |

## 6. 权衡

| 决策 | 理由 |
|------|------|
| 内嵌 phase 而非新 skill | 避免跨 skill 协调成本；R1..RN 在同一 skill 内共享 |
| 两种 AC 格式（行为/机械） | 行为变更需要 Given/When/Then 的强制思维结构；bug fix 不需要，强行套用是噪音 |
| Adversarial self-check 替代 subagent | 零 token 成本，抓住大部分空虚标准 |
| Gn↔Rn M:N 关系 | 一个 Gn 可覆盖多个 Rn，一个 Rn 可被多个 Gn 覆盖。1:1 在实测中被推翻（Pair 1 的 5 个需求被 1 个 Step 覆盖，或拆成 5 个 task 都改同一段代码——两种都不合理） |
| Gap Scan 补充覆盖检查 | 覆盖检查证明可追溯性，不证明正确性。Pair 1 全部 ✅ 但实际有缩窄/吞没。Gap Scan 从维度角度抓遗漏 |
| 统一 plan schema + `implementation_guidance: brief \| detailed` | execution skill 不需要两套解析逻辑。区别只在填充深度 |
| Task 按实现内聚性拆，不按 Gn 拆 | "每个 Gn 一个 task" 在实测中不合理（一个文件改动满足 3 个 Gn，不应拆成 3 个 task） |
| 回退时 AC 默认冻结 | AC 是稳定契约，decomposition 是执行策略。策略可变，契约不变 |
| Coverage Matrix → 覆盖检查规则 | 原设计要求强制表格，实测发现每个 Gn 已有 Covers 字段，矩阵纯冗余。改为一句规则：每个 Rn 至少被一个 Gn 覆盖 |
| Adversarial self-check Question 2 | 实测 7/11 验证命令有假阳性（grep 命中 HTML 注释、head -5 截太短）。Q1 只查"偷懒能过吗"，不查"命令本身对吗"。Q2 补上验证命令自检 |
| Gap Scan 6→3 项 | 实测 6 项扫描 0 产出。合并为 3 项（边缘情况、回归风险、集成），减少形式负担 |
| Lightweight plan 加 escalate | rollback triggers 只在 Phase B 生效，但 simple/moderate 跳过 Phase B。加实现者主动 escalate 机制 |

## 7. 审查记录

### Codex 审查第 1 轮（方案方向）

| # | Codex 意见 | 判定 | 理由 |
|---|-----------|------|------|
| 1 | 不要新增 skill，改嵌入 writing-plans | 采纳 | 跨 skill 协调成本高于收益 |
| 2 | Given/When/Then 替代 adversarial subagent | 采纳 | 零 token，结构化强制更可靠 |
| 3 | 复杂度用可观测指标做 primary | 采纳 | 避免主观偏差 |
| 4 | /goal 兼容作为导出 adapter | 采纳 | 不让格式约束倒逼设计 |
| 5 | 跳过 writing-plans 时保留轻量检查 | 采纳 | 防止 moderate 任务漏检查 |

### Codex 审查第 2 轮（4 个自审问题）

| # | Codex 意见 | 判定 | 理由 |
|---|-----------|------|------|
| 1 | 同意方案 A（轻量 plan 而非改 execution skill） | 采纳 | planning 职责不应下放到执行方 |
| 2 | 回退触发应是组合判断，不仅看文件数 | 采纳 | 单一指标不可靠 |
| 3 | AC 冻结 + 允许错误假设修订 | 采纳 | 平衡稳定性和正确性 |
| 4 | Pipeline Continuation 在 lightweight plan + self-review 后触发 | 采纳 | simple 也需要自检 |

### Codex 审查第 3 轮（最终方案 + 证据）

| # | Codex 意见 | 判定 | 理由 |
|---|-----------|------|------|
| 1 | Phase A 不应强制所有任务走完整 AC | **采纳** | 改为行为变更/机械编辑分流 |
| 2 | Gn→Task 不应是 1:1 | **采纳** | 改为 M:N，task 按实现内聚性拆 |
| 3 | Given/When/Then 不应强制所有 criterion | **采纳** | 机械编辑用简化格式 |
| 4 | Coverage Matrix 制造虚假信心 | **采纳** | 增加 Gap Scan 补充 |
| 5 | impl notes 的 depth 需显式区分 | **采纳** | 加 `implementation_guidance: brief \| detailed` |
| 6 | "tests all green"不是 AC，是 validation | **采纳** | 回归检查不进入 G 编号 |
