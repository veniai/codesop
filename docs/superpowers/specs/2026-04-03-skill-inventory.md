# codesop 全工具盘点总表

> 基准日期：2026-04-03
> 这是 codesop v2.0 路由、更新检查、init 的唯一参考源

| 大类 | 优选 | 来源 | Skill / 工具 | 什么时候用 |
|------|------|------|-------------|-----------|
| **1. 需求分析与设计** | | | | |
| | ★ | sp | brainstorming | 任何新功能/改动前：理解需求→澄清问题→出设计方案→写 spec→spec 自审→用户审阅 |
| | ★ | plugin | frontend-design | 做前端 UI 时：强制设计思维阶段，拒绝通用 AI 审美，独特的排版/配色/动效 |
| **2. 生成执行文档** | | | | |
| | ★ | sp | writing-plans | spec 已批准，拆成可执行的分步任务 |
| **3. 开发与执行** | | | | |
| | ★ | sp | using-git-worktrees | 开发前创建隔离工作区 |
| | ★ | sp | subagent-driven-development | 日常首选，内含 TDD + 两阶段 review + 自动 finishing |
| | | sp | dispatching-parallel-agents | 2+ 个完全独立任务并行加速时 |
| | | sp | executing-plans | 自己串行执行计划（不用子 agent） |
| | | sp | requesting-code-review | 开发中完成一个功能后提前让 AI 审一遍 |
| **4. 测试与验证** | | | | |
| | ★ | sp | verification-before-completion | 声明完成前必须运行验证命令确认输出 |
| | | plugin | code-simplifier | 功能验证通过后，自动优化代码可读性和结构 |
| | | sp | test-driven-development | 单独使用 TDD 红绿重构（subagent-driven-development 已内置） |
| **5. 提交 PR** | | | | |
| | ★ | sp | finishing-a-development-branch | 测试通过后提交 PR 或合并 |
| **6. 代码审查** | | | | |
| | ★ | plugin | code-review | PR 提交后自动审查：5 agent 并行 + 置信度评分 + 自动发评论 |
| | | plugin | codex:review | 需要 OpenAI 第二意见审查代码 diff 时（独立视角） |
| | | plugin | codex:adversarial-review | 高风险操作需要挑战设计假设和实现选择时 |
| | | sp | receiving-code-review | 收到 code-review 评论后，先技术评估再执行 |
| **7. 前端测试与自动化** | | | | |
| | | plugin | playwright | 日常页面操作：导航/截图/填表/点击/JS 执行 |
| | | skill | browser-use | 需要登录态/云浏览器/tunnel 时的补充 |
| **8. 文档管理** | | | | |
| | | plugin | claude-md-management | CLAUDE.md 质量审计：6 维度评分→出报告→定向修复 |
| | | plugin | context7 | 查询第三方库/框架的最新文档和代码示例 |
| **9. Skill 开发** | | | | |
| | ★ | plugin | skill-creator | Skill 全生命周期：创建→测试→基准评估→盲测 A/B→描述优化 |
| | | sp | writing-skills | 轻量备选：创建/编辑 skill 的流程指导 |
| **10. 项目编排** | | | | |
| | ★ | skill | codesop | 项目工作台：上下文恢复→路由推荐→fit 验证→完成关卡 |
| **11. 通讯桥梁** | | | | |
| | | skill | claude-to-im | Claude Code 桥接到 Telegram/Discord/飞书/QQ/微信 |
| **12. 应急接管** | | | | |
| | | plugin | codex:rescue | 线程卡住或需要换个智能体重新来过时，把任务交给 Codex 接管 |

## 依赖清单

### 官方插件（Plugin）
- superpowers@claude-plugins-official (5.0.7)
- skill-creator@claude-plugins-official
- frontend-design@claude-plugins-official
- context7@claude-plugins-official
- code-review@claude-plugins-official
- code-simplifier@claude-plugins-official
- playwright@claude-plugins-official
- claude-md-management@claude-plugins-official
- codex@openai-codex (1.0.2)

### 独立 Skill
- codesop (~/.claude/skills/codesop/)
- browser-use (~/.claude/skills/browser-use/)
- claude-to-im (~/.claude/skills/claude-to-im/)

### MCP Server（独立于插件的）
- filesystem
- fetch
- zread

## 已移除
- gstack — 2026-04-03 彻底卸载
