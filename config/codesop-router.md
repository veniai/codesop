## codesop 路由卡 (v2)

新任务必须先输出任务对齐块（理解 + 阶段 + Skill）。
完整 pipeline 定义见 /codesop。

### 技能总表（按项目生命周期排序）

| 大类 | 优选 | 来源 | Skill | 什么时候用 |
|------|------|------|-------|-----------|
| **1. 需求分析与设计** | | | | |
| | ★ | sp | superpowers:brainstorming | 任何新功能/改动前：理解需求→澄清问题→出设计方案→写 spec→spec 自审→用户审阅 |
| | ★ | plugin | codex:rescue | spec 完成后的独立设计审查（双 AI 设计审查，必走） |
| | ★ | plugin | frontend-design:frontend-design | 做前端 UI 时：强制设计思维阶段，拒绝通用 AI 审美，独特的排版/配色/动效 |
| **2. 生成执行文档** | | | | |
| | ★ | sp | superpowers:writing-plans | spec 已批准，拆成可执行的分步任务 |
| **3. 开发与执行** | | | | |
| | ★ | sp | superpowers:using-git-worktrees | 开发前创建隔离工作区 |
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
| **7. 前端测试与自动化** | | | | |
| | | plugin | playwright | 日常页面操作：导航/截图/填表/点击/JS 执行 |
| | | skill | browser-use | 需要登录态/云浏览器/tunnel 时的补充 |
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
| **12. 通讯桥梁** | | | | |
| | | skill | claude-to-im | Claude Code 桥接到 Telegram/Discord/飞书/QQ/微信 |
| **13. 应急接管** | | | | |
| | | plugin | codex:rescue | 用户说"让 codex 看看/交给 codex/第二意见"、线程卡住、需要换个智能体时——AI 可自动调用的唯一 codex 执行命令 |
| | | plugin | codex:review | 需要 OpenAI 第二意见审查代码 diff 时（独立视角）⚠️ 需用户手动输入 |
| | | plugin | codex:adversarial-review | 高风险操作需要挑战设计假设和实现选择时 ⚠️ 需用户手动输入 |

### 链路组装（路由表是链路唯一真相源）
所有链路必须应用以下插入规则（☆=有插件时走）：
开发后 → ☆code-simplifier:code-simplifier | 验证后 → ☆claude-md-management:claude-md-improver | 设计后 → ★codex:rescue

链路完整性：组装链路后检查相邻 skill 之间是否存在逻辑断层（如 code-review 后未走 receiving-code-review、反馈后未修复验证），有则自动补充过渡步骤，不盲目前进。

调试路径（"修 bug"/"测试挂了"）：跳过需求和计划，直接 superpowers:systematic-debugging → superpowers:verification-before-completion → ☆claude-md-management → superpowers:finishing-a-development-branch

### Codex 路由
用户提到 codex（"让 codex 看看"、"交给 codex"、"codex 审查"、"第二意见"）时：
→ codex:rescue（AI 唯一可自动调用的 codex 执行命令，万能任务转发）
codex:review 和 codex:adversarial-review 需用户手动输入，AI 不可自动调用。需要审查功能时，用 rescue 并在 prompt 中指定审查意图。

### 铁律
- 跳过必走 Skill = 先输出对齐块说明原因
- 不确定 → 先调用 /codesop
- 任务完成后及时标记，过期/废弃任务及时清理，不堆积
