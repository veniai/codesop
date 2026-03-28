# Superpowers vs gstack 技能框架对比

> 核心结论：**Superpowers 是工程纪律层，gstack 是交付执行层。** 把它们当成同一层的替代品本身就错位了。

## 技能总览

### Superpowers（14 个 — 开发流程纪律）

| 功能类别 | 技能 | 说明 |
|---------|------|------|
| 元技能 | `using-superpowers` | 技能路由入口，对话开始时检查，**1% 可能性就触发** |
| 创意/设计 | `brainstorming` | **强制门控** — 未经批准不得调用任何实现技能 |
| 计划 | `writing-plans` | 写零上下文工程师能执行的计划 |
| 执行 | `executing-plans` | 内联执行计划（**降级方案**，有 subagent 时不用） |
| | `subagent-driven-development` | 每任务一个**全新 subagent** + 两阶段 review（spec→code quality） |
| | `dispatching-parallel-agents` | 2+ **独立问题**并行派发（不同子系统/不同 bug） |
| 质量 | `test-driven-development` | 强制 RED-GREEN-REFACTOR，**没看到测试失败就不算测对** |
| | `systematic-debugging` | 铁律：**无根因不修**，含 defense-in-depth 参考 |
| | `verification-before-completion` | 铁律：**无证据不声称完成**，5 步门禁函数 |
| 代码审查 | `requesting-code-review` | 派发 code-reviewer 子 agent，**尽早审、频繁审** |
| | `receiving-code-review` | 收到反馈后**先验证再实施**，技术正确性优先 |
| Git/分支 | `using-git-worktrees` | 创建隔离 worktree，被 brainstorming/subagent-driven 调用 |
| | `finishing-a-development-branch` | 验证→展示选项（merge/PR/清理）→执行→收尾 worktree |
| 技能开发 | `writing-skills` | 用 TDD 方式写技能：设计压力测试→看基线失败→写技能→测试通过 |

### gstack（29 个 — 全栈交付工具箱）

| 功能类别 | 技能 | 说明 |
|---------|------|------|
| 浏览器/QA | `browse` | Playwright 持久 Chromium，首次 ~3s，后续 ~100ms |
| | `gstack` | browse 的别名入口 |
| | `setup-browser-cookies` | 从真实浏览器（Chrome/Arc/Brave/Edge）**解密** cookie 导入 |
| | `connect-chrome` | 启动真实 Chrome + **Side Panel 扩展**，可视化观察操作 |
| QA 测试 | `qa` | **4 种模式**：Diff-aware/Full/Quick/Regression，自动生成回归测试 |
| | `qa-only` | 同方法论但**只报告不修** |
| | `design-review` | **80 项视觉审计** + AI slop 检测 + 原子提交修复 |
| 发布/部署 | `ship` | 含**测试框架引导** + **覆盖率审计** + Review 门禁 |
| | `land-and-deploy` | 合并 PR → 等 CI/部署 → 金丝雀验证 |
| | `setup-deploy` | 检测部署平台，配置写入 CLAUDE.md |
| | `canary` | 部署后监控：定期截图、**与部署前基线对比**、异常告警 |
| | `benchmark` | Core Web Vitals 基线对比，**PR 维度 before/after** |
| 计划审查 | `autoplan` | 串行跑 CEO+设计+工程，用 **6 个决策原则自动决策** |
| | `plan-ceo-review` | **4 个模式**：Expansion/Selective Expansion/Hold/Reduction |
| | `plan-design-review` | **7 轮审查**：信息架构→交互状态→用户旅程→AI slop→设计系统→响应式→未解决决策 |
| | `plan-eng-review` | 架构+数据流+图表+边界+性能+测试，含 **Review Readiness Dashboard** |
| 安全 | `cso` | OWASP Top 10 + **STRIDE 威胁建模** |
| | `careful` | **白名单制**：构建清理（node_modules 等）免警告 |
| | `guard` | careful + freeze 一键组合 |
| 编辑范围 | `freeze` | 限制 Edit/Write 到指定目录（Bash sed 不受限） |
| | `unfreeze` | 解除 freeze 限制 |
| 代码审查 | `review` | **结构审计**：N+1/竞态/信任边界/遗忘枚举，含 **auto-fix** + **completeness gaps** |
| | `codex` | 调用 **OpenAI Codex CLI**，三种模式：review/challenge/consult，支持**跨模型交叉分析** |
| 调试 | `investigate` | 4 阶段：调查→分析→假设→修复，**3 次修复失败后停手质疑架构** |
| 设计 | `design-consultation` | 从零构建设计系统，**含 deliberate creative risks**，生成 HTML 预览 |
| 文档 | `document-release` | 交叉对比 diff 与文档，含 **CHANGELOG 语音润色** + **TODOS 清理** |
| 复盘 | `retro` | **团队感知**：每人独立分析、shipping streak、测试健康趋势 |
| 创业 | `office-hours` | **两种模式**：Startup（YC 6 问）/ Builder（设计思维），输出 design doc |
| 维护 | `gstack-upgrade` | 检测全局/项目双安装，同步升级 |

---

## 触发信号 → 技能路由表

### 需求探索阶段

| 用户信号 | 推荐技能 | 强制? |
|---------|---------|-------|
| "不知道做什么" / "方向不明确" | gstack:office-hours | 否 |
| "要做 X 功能" / "加个 Y" | superpowers:brainstorming | **是** |
| "重构 Z" / "改进 W" | superpowers:brainstorming | **是** |

### 计划阶段

| 用户信号 | 推荐技能 | 强制? |
|---------|---------|-------|
| "写计划" / "怎么做" | superpowers:writing-plans | **是** |
| "审一下计划" | gstack:autoplan | **是** |
| "CEO 视角审计划" | gstack:plan-ceo-review | 否 |
| "设计视角审计划" | gstack:plan-design-review | 否 |
| "工程视角审计划" | gstack:plan-eng-review | 否 |

### 执行阶段

| 用户信号 | 推荐技能 | 强制? |
|---------|---------|-------|
| "开始做" / "执行" | superpowers:subagent-driven-development | **是** |
| "多个独立问题" | superpowers:dispatching-parallel-agents | 否 |
| "写代码"（直接） | superpowers:test-driven-development | **是** |

### 调试阶段

| 用户信号 | 推荐技能 | 强制? |
|---------|---------|-------|
| "不知道 bug 住哪" / "排查一下" | gstack:investigate | 否 |
| "知道问题但怕修错" | superpowers:systematic-debugging | **是** |
| "测试挂了" | superpowers:systematic-debugging | **是** |

### 验证阶段

| 用户信号 | 推荐技能 | 强制? |
|---------|---------|-------|
| "做完了" / "修好了" | superpowers:verification-before-completion | **是** |
| "跑一下看看" / "测一下" | gstack:qa | **是**（Web） |
| "只看报告不改" | gstack:qa-only | 否 |
| "性能问题" | gstack:benchmark | 否 |

### 审查阶段

| 用户信号 | 推荐技能 | 强制? |
|---------|---------|-------|
| "review 一下" / "合并前看看" | gstack:review | **是** |
| "外部意见" / "对抗测试" | gstack:codex | 否 |
| "收到 review 反馈" | superpowers:receiving-code-review | **是** |

### 发布阶段

| 用户信号 | 推荐技能 | 强制? |
|---------|---------|-------|
| "发布" / "ship" / "推 PR" | gstack:ship | **是** |
| "合并" / "部署" | gstack:land-and-deploy | **是** |
| "配置部署" | gstack:setup-deploy | 否 |
| "部署后监控" | gstack:canary | **是** |

### 清理阶段

| 用户信号 | 推荐技能 | 强制? |
|---------|---------|-------|
| "更新文档" / "同步文档" | gstack:document-release | **是** |
| "周报" / "复盘" | gstack:retro | 否 |

### 安全与工具

| 用户信号 | 推荐技能 | 强制? |
|---------|---------|-------|
| "小心点" / "别搞坏" | gstack:careful | 否 |
| "只改这个目录" | gstack:freeze | 否 |
| "最大安全模式" | gstack:guard | 否 |
| "解冻" | gstack:unfreeze | 否 |
| "浏览器里看看" | gstack:browse | 否 |
| "导入 cookie" | gstack:setup-browser-cookies | 否 |
| "安全审计" | gstack:cso | 否 |
| "设计系统" / "从零设计" | gstack:design-consultation | 否 |
| "视觉审计" / "UI 问题" | gstack:design-review | 否 |

---

## 五大重叠区域详解

### 1. 调试 — systematic-debugging vs investigate

**核心差异**：`systematic-debugging` 是**认知纪律**（约束修复方法）；`investigate` 是**故障处理流程**（先摸清战场）。

| 场景 | 选谁 | 原因 |
|------|------|------|
| 单元测试失败、边界条件错误 | **Superpowers** | 问题在代码层，需要约束修复方法 |
| 状态机错乱、重构后行为漂移 | **Superpowers** | 已知大致范围，怕修错 |
| 涉及浏览器、集成链路、线上环境 | **gstack** | 还不知道问题在哪，需要先定位战场 |
| 权限、部署、第三方依赖问题 | **gstack** | 需要环境层面的排查 |

**叠加用法**：先 `gstack:investigate`（缩小战场） → 再 `superpowers:systematic-debugging`（约束修复）

> **决策规则**：不知道问题住哪 → gstack；知道大概住哪但怕修错 → Superpowers

---

### 2. 代码审查 — requesting/receiving-code-review vs review + codex

**核心差异**：Superpowers 管**评审行为本身**；gstack 管 **diff 的结构性风险** + **外部模型交叉验证**。

| 场景 | 选谁 | 原因 |
|------|------|------|
| 处理 review feedback，怀疑 reviewer 不对 | **Superpowers** | 需要 receiving-code-review 做技术评估 |
| 合并前扫 diff 的硬风险 | **gstack:review** | 自动扫描 N+1/SQL/安全/遗忘枚举 |
| 需要另一个模型唱反调 | **gstack:codex challenge** | 调用 OpenAI 做对抗性审查 |
| 争议时需要跨模型交叉分析 | **gstack:codex** | 与 Claude review 结果对比 |

**叠加用法**：

```
gstack:review（扫硬风险 + auto-fix 机械问题）
  → superpowers:requesting-code-review（看可维护性）
    → 收到评论后 superpowers:receiving-code-review（决定采纳与否）
      → 遇到争议拉 gstack:codex challenge（外部二判）
```

> **决策规则**：Superpowers 管"怎么审、怎么回"，gstack 管"这份改动危险不危险" + "另一个模型怎么看"

---

### 3. 验证 — verification-before-completion vs qa / qa-only

**核心差异**：`verification-before-completion` 是**证据门禁铁律**；`qa/qa-only` 是**浏览器实测**。

| 场景 | 选谁 | 原因 |
|------|------|------|
| 库、后端、CLI、重构、非 UI 任务 | **Superpowers** | 跑测试命令即可证明 |
| Web app、用户流程、页面交互 | **gstack:qa** | 需要浏览器真实操作验证 |
| 响应式布局、登录态、浏览器行为 | **gstack:qa** | 超越测试命令的范畴 |
| 只看报告不改代码 | **gstack:qa-only** | 报告模式 |

**叠加用法**：先 `verification-before-completion`（跑项目验证） → 再 `gstack:qa`（浏览器和流程层验收）。**顺序反了是浪费时间。**

> **决策规则**：Superpowers 证明"工程上没胡说"，gstack 证明"用户侧真能用"

---

### 4. 分支/发布 — worktrees + finishing-branch vs ship + land-and-deploy

**核心差异**：Superpowers 管**开发拓扑和收尾决策**；gstack 管**把东西送上去并确认没炸**。

| 场景 | 选谁 | 原因 |
|------|------|------|
| 高风险功能、并行实验 | **Superpowers** | worktree 隔离工作区 |
| 复杂 refactor、长生命周期分支 | **Superpowers** | 分支策略和收口决策 |
| 代码已准备好，要跑测试/开 PR | **gstack:ship** | 统一发布流水线（含测试框架引导） |
| 等 CI、合并、部署、验 canary | **gstack:land-and-deploy** | 端到端发布 + 金丝雀验证 |

**叠加用法**：

```
superpowers:using-git-worktrees（开始隔离开发）
  → superpowers:finishing-a-development-branch（决定收口方式）
    → gstack:ship（跑测试、审 diff、推 PR）
      → gstack:land-and-deploy（合并 + canary 验证）
```

> **决策规则**：开发阶段的秩序用 Superpowers，发布阶段的流水线用 gstack

---

### 5. 头脑风暴 — brainstorming vs office-hours

**核心差异**：`brainstorming` 是**实现前设计**（**强制门控**，未经批准不得实现）；`office-hours` 是**产品前置思考**（用户、痛点、切入点）。

| 场景 | 选谁 | 原因 |
|------|------|------|
| 方向已定，要变成可实现方案 | **Superpowers** | 组件怎么拆、数据流怎么走 |
| 还在问"该不该做、给谁做" | **gstack** | 产品方向验证 |
| 新产品、新 feature 方向不稳 | **gstack** | 需求探索优先于技术设计 |
| 风险怎么控、边界怎么定 | **Superpowers** | 技术层面的约束分析 |

**叠加用法**：先 `gstack:office-hours`（定做什么） → 再 `superpowers:brainstorming`（定怎么做）

> **决策规则**：office-hours 解决"做什么"，brainstorming 解决"怎么做"

---

## Superpowers 三种执行模式对比

### 速览

| | executing-plans | subagent-driven | parallel-agents |
|--|----------------|-----------------|-----------------|
| **比喻** | 自己干 | 包工头模式 | 救火模式 |
| **需要计划？** | 是 | 是 | 否 |
| **执行者** | 自己（当前 session） | 每 task 派新 subagent | 同时派多个 agent |
| **并行/串行** | 串行 | 串行 | 并行 |
| **上下文隔离** | 否（共享，会污染） | 是（每 task 全新） | 是（每 agent 全新） |
| **自动 review** | 无 | 两级（spec + quality） | 无 |
| **任务关系** | 可有依赖 | 基本独立 | 必须完全独立 |
| **定位** | **降级方案** | **推荐默认** | 特殊场景 |

### 决策流程

```
有计划 + 支持 subagent？
├── 是 → subagent-driven-development（质量最高，默认）
└── 否 → executing-plans（降级方案）

没有计划，但有多个独立问题？
└── dispatching-parallel-agents
```

---

## 总规则

> **Superpowers 作为默认内核，gstack 作为 web 交付外壳。**
> 只选一个时，**写代码选 Superpowers，发产品选 gstack。**

---

## 互补关系图

```
                    需求探索
                       │
                  gstack:office-hours
                  (方向未定时)
                       │
                       ▼
                   做什么？
                       │
                       ▼
              superpowers:brainstorming
                   (强制门控)
                       │
                   怎么做？
                       │
                       ▼
              superpowers:writing-plans
                       │
                    实现计划
                       │
                       ▼
                  gstack:autoplan
              (CEO+设计+工程 三审)
                       │
                       ▼
            superpowers:using-git-worktrees
                       │
                       ▼
        superpowers:subagent-driven-development
              (每 task 带 TDD + 两级 review)
                       │ 遇到 bug
                       ├─ 不知道在哪 → gstack:investigate
                       └─ 知道在哪 → superpowers:systematic-debugging
                       │
                       ▼
        superpowers:verification-before-completion
                   (铁律：没证据别说 done)
                       │
                       ▼
              gstack:review + codex
                  (代码审查 + 跨模型验证)
                       │
                       ▼
               gstack:qa (Web 项目)
                  (浏览器实测)
                       │
                       ▼
                 gstack:ship
                  (统一发布流水线)
                       │
                       ▼
             gstack:land-and-deploy
                  (发布 + canary)
                       │
                       ▼
              gstack:document-release
                  (文档同步)
                       │
                       ▼
                gstack:retro (每周)
```

---

## 按开发者类型推荐

| 开发者类型 | 推荐主框架 | 原因 |
|-----------|-----------|------|
| **单人开发者，发 web app** | **gstack** 为主 | 覆盖 QA、视觉、ship、deploy、canary、benchmark，单人最容易漏掉的环节 |
| **3-5 人工程团队** | **Superpowers** 主框架 + gstack 外挂 | SP 是团队工程纪律，不会把所有人绑进过重的交付脚本；gstack 挂在发布和 QA 环节 |
| **资深工程师做复杂重构** | **Superpowers** 为主 | 重构最怕思维失控、假设没证据、行为漂移、review 走过场，SP 正好管这些 |
