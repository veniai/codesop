## codesop 路由卡

新任务必须先输出任务对齐块（理解 + 阶段 + Skill）。
完整 pipeline 定义见 /codesop。

### 必走路径（不可跳过）
| 用户信号 | Pipeline 阶段 | 必走 Skill 序列 |
|---------|--------------|----------------|
| 做功能 / 加东西 / 重构 | 探索→计划→执行→验证→review | office-hours (direction unclear) or brainstorming (direction clear) → writing-plans → autoplan → using-git-worktrees → subagent-driven-development (or executing-plans / dispatching-parallel-agents) → test-driven-development → verification-before-completion → review |
| 修 bug / 测试挂了 | 调试→验证→review | investigate (system-level) or systematic-debugging (single-file) → verification-before-completion → review |
| 做完了 / 修好了 | 验证→review | verification-before-completion → qa(web) → review |
| 发布 / ship | 发布→清理 | ship → setup-deploy (首次) → land-and-deploy → document-release |

### 可选路径
| 用户信号 | Skill |
|---------|-------|
| 方向不明确 | office-hours |
| 测一下 (web) | qa |
| 只报 bug 不改代码 | qa-only |
| 小心点 / 生产环境 | careful |
| 最大安全模式 | guard (= careful + freeze) |
| 只改这个目录 | freeze |
| 看看学到了什么 | learn |
| 回顾这周做了什么 | retro |
| 查安全 | cso |
| 测性能 | benchmark |
| 做设计 | design-consultation / design-shotgun → design-review |
| 写新 skill | writing-skills |
| 收 code review | requesting-code-review |
| 处理 code review 反馈 | receiving-code-review |

### 铁律
- 跳过必走 Skill = 先输出对齐块说明原因
- 不确定 → 先调用 /codesop
