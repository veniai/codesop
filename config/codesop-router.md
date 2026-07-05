## codesop 路由卡 (v4)

新任务必须先输出任务对齐块（理解 + 阶段 + Skill）。
完整 pipeline 定义见 /codesop。

### 技能总表（按项目生命周期排序）

| 大类 | 优选 | 来源 | Skill | 什么时候用 |
|------|------|------|-------|-----------|
| **0. 项目理解与导航** | | | understand-anything | |
| | ★ | plugin | understand-anything:understand-chat | 跨模块改动 / 大仓库 / 陌生项目动手前：若图谱可用（§1.5 状态 ∈ {fresh_on, fresh_degraded, stale_on, stale_off}），基于图谱建立全局架构认知（brainstorming 前置输入）。图谱不可用（absent/corrupt/unknown_head）则跳过回退读 CONTEXT.md/ADR；**stale（过期）降级使用——AI 须警惕结构滞后**，工作台注意行同步提示更新 |
| | ★ | plugin | understand-anything:understand-diff | 跨模块改动开发完成后、验证前：若图谱可用，基于图谱**辅助**复核影响面（定位为辅助非权威——机制有盲区，见 §4）。不可用则跳过；stale 同样降级使用（AI 警惕）。触发锚点：改动涉及 ≥2 个路由模块 / 跨 client-server / 改公共接口 |
| | | plugin | understand-anything:understand-explain | 需深度理解某文件/函数的上下游或在架构中的位置时（调试、接手陌生模块） |
| | | plugin | understand-anything:understand-onboard | 新会话接手陌生项目 / 新人 onboarding：生成架构学习路径 |
| **1. 需求分析与设计** | | | | |
| | ★ | sp | superpowers:brainstorming | 任何新功能/改动前：理解需求→grill 式术语对齐→澄清问题→出设计方案→写 spec→spec 自审→用户审阅；架构审查/重构/模块边界 |
| | ★ | plugin | codex:rescue | spec 完成后的独立设计审查（双 AI 设计审查，必走） |
| | ★ | plugin | frontend-design:frontend-design | 做前端 UI 时：强制设计思维阶段，拒绝通用 AI 审美，独特的排版/配色/动效 |
| **2. 生成执行文档** | | | | |
| | ★ | sp | superpowers:writing-plans | spec 已批准，拆成可执行的分步任务 |
| **3. 开发与执行** | | | | |
| | ★ | sp | superpowers:using-git-worktrees | 开发前自动创建隔离 worktree（优先使用 Claude Code EnterWorktree） |
| | ★ | sp | superpowers:subagent-driven-development | 日常首选，内含 TDD + 两阶段 review + 自动 finishing |
| | | plugin | code-simplifier:code-simplifier | 开发完成后、验证前：自动检查最近修改的代码，优化可读性和结构（dev → simplifier → verification 链路） |
| | | sp | superpowers:dispatching-parallel-agents | 2+ 个完全独立任务并行加速时（仅 plan 已拆出独立任务后触发） |
| | | sp | superpowers:requesting-code-review | 开发中完成一个功能后提前让 AI 审一遍 |
| **4. 测试与验证** | | | | |
| | ★ | sp | superpowers:verification-before-completion | 声明完成前必须运行验证命令确认输出 |
| | ★ | plugin | claude-md-management:claude-md-improver | 验证通过后、提交前：审计 CLAUDE.md/PRD.md/README.md 是否需要更新（防止文档落后于代码） |
| | | sp | superpowers:test-driven-development | 单独使用 TDD 红绿重构（subagent-driven-development 已内置） |
| **5. 提交 PR** | | | | |
| | ★ | sp | superpowers:finishing-a-development-branch | 测试通过后提交 PR 或合并 |
| **6. 代码审查** | | | | |
| | ★ | plugin | code-review:code-review | PR 提交后自动审查：5 agent 并行 + 置信度评分 + 自动发评论 |
| | ★ | plugin | codex:rescue | code-review 之后的独立第二意见（双 AI 审查，必走） |
| | | sp | superpowers:receiving-code-review | 收到 code-review 评论后，先技术评估再执行 |
| **7. 浏览器工具** | | | | |
| | | plugin | playwright | 页面交互与自动化测试：导航/截图/填表/点击/E2E 流程 |
| | | plugin | chrome-devtools-mcp | 浏览器诊断：性能分析(LCP)/a11y 审计/CDP 调试/渲染排查 |
| **8. 调试与调查** | | | | |
| | ★ | sp | superpowers:systematic-debugging | 遇到 bug/测试失败/异常行为时，假设驱动逐步排查（修 bug 必走） |
| **9. 文档管理** | | | | |
| | | plugin | claude-md-management:claude-md-improver | CLAUDE.md 质量审计：6 维度评分→出报告→定向修复 |
| | | plugin | context7 | 查询第三方库/框架的最新文档和代码示例 |
| **10. Skill 开发** | | | | |
| | ★ | plugin | skill-creator:skill-creator | Skill 全生命周期：创建→测试→基准评估→盲测 A/B→描述优化 |
| | | sp | superpowers:writing-skills | 轻量备选：创建/编辑 skill 的流程指导 |
| **11. 项目编排** | | | | |
| | ★ | skill | codesop | 项目工作台：上下文恢复→路由推荐→fit 验证→完成关卡 |
| **12. 应急接管** | | | | |
| | | plugin | codex:rescue | 用户说"让 codex 看看/交给 codex/第二意见"、线程卡住、需要换个智能体时——AI 可自动调用的唯一 codex 执行命令 |
| | | plugin | codex:review | 需要 OpenAI 第二意见审查代码 diff 时（独立视角）⚠️ 需用户手动输入 |
| | | plugin | codex:adversarial-review | 高风险操作需要挑战设计假设和实现选择时 ⚠️ 需用户手动输入 |

### 链路组装（路由表是链路唯一真相源）
**pre-/goal preparation segment**：链路组装到 **spec-gate + plan-gate + branch setup + /goal handoff 为止**（codesop 编排，auto-proceed 覆盖整段）；/goal handoff 时 AI 生成 exact /goal 命令交用户手动发（/goal 是 built-in，AI 不能自触发），用户发后 /goal 接管 dev/verify/finishing。
**造目标段**（codesop 编排，☆=有插件时走）：设计后 → ★codex:rescue | 跨模块（锚点：≥2 路由模块 / 跨 client-server / 改公共接口）→ brainstorming 前条件插入 understand-anything:understand-chat（不可用跳过回退 CONTEXT.md/ADR；stale 降级提示）
**跑目标段**（/goal handoff 后，嵌 `/goal` 完成条件）：/goal handoff 前 → main 上建分支 / using-git-worktrees | /goal dev 后 → ☆code-simplifier | /goal verify 后 → ☆claude-md-management | 跨模块同锚点 /goal dev 后 → understand-anything:understand-diff（辅助；不可用跳过；stale 降级）

链路完整性：组装链路后检查相邻 skill 之间是否存在逻辑断层（如 code-review 后未走 receiving-code-review、反馈后未修复验证），有则自动补充过渡步骤，不盲目前进。

PR review 反馈路径：receiving-code-review → superpowers:finishing-a-development-branch（receiving-code-review 内含逐项测试验证，finishing Step 1 自带全量测试门禁，无需额外插入 verification-before-completion）

调试路径（"修 bug"/"测试挂了"）：跳过需求和计划，直接 superpowers:systematic-debugging（第一性原理找根因：从基本事实/约束推根因，不照搬"类似 bug 这样修"——强化"无根因不修 bug"铁律）→ superpowers:verification-before-completion → ☆claude-md-management → superpowers:finishing-a-development-branch；修 bug 后追问架构反思，如有价值建议写 ADR

### Codex 路由
用户提到 codex（"让 codex 看看"、"交给 codex"、"codex 审查"、"第二意见"）时：
→ codex:rescue（AI 唯一可自动调用的 codex 执行命令，万能任务转发）
codex:review 和 codex:adversarial-review 需用户手动输入，AI 不可自动调用。需要审查功能时，用 rescue 并在 prompt 中指定审查意图。

### 铁律
- 跳过必走 Skill = 先输出对齐块说明原因；Task 指定了 skill 就必须调用，不能 inline 替代
- 不确定 → 先调用 /codesop
- 任务完成后及时标记，过期/废弃任务及时清理，不堆积
- 领域语言：涉及需求/架构/跨模块改动时先读 CONTEXT.md 和 ADR（如存在），用术语，发现缺口标记，发现冲突指出
