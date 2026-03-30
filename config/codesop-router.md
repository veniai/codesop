## codesop 路由卡

新任务必须先输出任务对齐块（理解 + 阶段 + Skill）。
完整 pipeline 定义见 /codesop。

### 必走路径（不可跳过）
| 用户信号 | Pipeline 阶段 | 必走 Skill 序列 |
|---------|--------------|----------------|
| 做功能 / 加东西 / 重构 | 探索→计划→执行→验证→review | brainstorming → writing-plans → autoplan → using-git-worktrees → subagent-driven-development → test-driven-development → verification-before-completion → review |
| 修 bug / 测试挂了 | 调试→验证→review | systematic-debugging → verification-before-completion → review |
| 做完了 / 修好了 | 验证→review | verification-before-completion → qa(web) → review |
| 发布 / ship | 发布→清理 | ship → document-release |

### 可选路径
| 用户信号 | Skill |
|---------|-------|
| 方向不明确 | office-hours |
| 测一下 (web) | qa |
| 小心点 | careful |
| 只改这个目录 | freeze |

### 铁律
- 跳过必走 Skill = 先输出对齐块说明原因
- 不确定 → 先调用 /codesop
