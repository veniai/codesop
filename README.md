# codesop

**AI 编码标准操作流程 / AI Coding Standard Operating Procedure**

A skill-first operating system for AI-assisted coding work. The current core keeps one main flow, `/codesop`, plus two mechanical commands: `init` and `update`.

---

## 这是什么？ / What is this?

**[中文]** 跨工具的 AI 编码工作流操作系统。当前内核只保留 1 套主流程 `/codesop`，以及 2 个机械命令 `init / update`。CLI 负责项目初始化和版本更新。

**[English]** A cross-tool AI coding workflow OS. The current core keeps one main flow, `/codesop`, plus two mechanical commands: `init` and `update`. The CLI handles project initialization and updates.

## 安装 / Install

```bash
git clone https://github.com/veniai/codesop.git ~/codesop
cd ~/codesop && bash install.sh
```

Then make sure `~/.local/bin` is on your `PATH`.

## 安装了什么？ / What gets installed?

| Component | Target | Purpose |
|-----------|--------|---------|
| Router card | `~/.claude/codesop-router.md` | SessionStart hook 注入纪律表 |
| Slash commands | `~/.claude/commands/` | `/codesop` workflow + `/codesop-init` + `/codesop-update` |
| System AGENTS.md | `~/.claude/CLAUDE.md` → `templates/system/AGENTS.md` | 全局 AI 契约 + skill 纪律 |
| Skill runtime | `~/.claude/skills/codesop/` | Skill 文件运行时 |
| CLI | `~/.local/bin/codesop` | 命令行工具 |

## 使用方法 / Usage

**初始化新项目：**
```bash
# 在 Claude Code 中
/codesop init .
```

**进入工作台：**
```bash
/codesop
```

`/codesop` 会在摘要和推荐之后，把真正的下一步动作放在最后一行，输出为一条自然语言工作流指令。它可以串 1 到 3 个 skill，尽量让 Claude Code 把它识别成输入框里的灰色默认建议，便于直接回车继续。

**更新 codesop：**
```bash
codesop update
# 或
/codesop-update
```

## `/codesop init` 会做什么？

1. 扫描项目：判断主语言、项目形态、框架
2. 检测环境：Claude Code / Codex / OpenCode / superpowers
3. 生成项目文件：
   - `AGENTS.md` → `@CLAUDE.md`（轻量引用）
   - `PRD.md` → 活文档（产品规范 + 进度 + 工作日志）
   - `README.md` → 安装/运行/测试命令（如不存在）
4. CLAUDE.md 由 Claude Code 的 `/init` 生成，codesop 不覆盖

其中：
- `AGENTS.md` 是宿主工具的入口，指向 `CLAUDE.md`
- `PRD.md` 同时承担产品规范和当前工作记录
- 默认中文，自动推断 test/lint/typecheck/smoke 命令

## 文档收尾规则 / Document Gate

- `/codesop` 路由后的实现任务，在最终回复前必须判定 `CLAUDE.md`、`PRD.md`、`README.md` 是否需要更新
- 如果任一文档需要更新，优先调用 `claude-md-management`
- `AGENTS.md` 不进入默认判定集合，因为它应始终保持为 `@CLAUDE.md` 的薄包装
- `CHANGELOG.md` 不属于默认强制集合

## 版本规则 / Versioning

- `VERSION` 是发布版本的唯一真相源
- `skill.json` 和 `PRD.md` 中的版本号必须与 `VERSION` 一致
- `CHANGELOG.md` 顶部默认使用 `Unreleased`，真正进入发布流程时再切成具体版本
- git tag 只在 ship 阶段创建，例如 `v1.1.2`

## 产品边界 / Product Contract

- 主流程只有一个：`/codesop`
- 机械命令只有两个：`codesop init`、`codesop update`
- `status` / `diagnose` 已从产品合同中移除
- 本仓库正在做架构收口，与上面合同无关的能力不会优先扩展
- `/codesop` 收尾必须以一条自然语言工作流指令结束；允许串联多个 skill，不再强制 slash command 形式

## 覆盖场景 / Workflow Scenarios

| 场景 | Pipeline |
|------|----------|
| 新功能 | brainstorming → writing-plans → worktree → subagent-dev → verification → finishing |
| Bug 修复 | systematic-debugging → verification → finishing |
| 小改动 | subagent-dev → verification → finishing (if multi-file) |
| 重构 | brainstorming → writing-plans → worktree → subagent-dev → verification → finishing |
| Code Review 反馈 | receiving-code-review → fix → verification → reply |

## 依赖 / Dependencies

codesop 编排以下 skill 生态：

- **[superpowers](https://github.com/obra/superpowers)** — brainstorming, writing-plans, TDD, systematic-debugging, subagent-driven-dev, verification-before-completion, office-hours, review, dispatching-parallel-agents

安装方式：
- superpowers: `/plugin install superpowers` (Claude Code)

## 架构 / Architecture

```
codesop                     # CLI entrypoint
setup                       # Host integration sync
├── lib/                    # Core shell modules
├── SKILL.md                # /codesop definition
├── commands/               # Mechanical slash command files
├── config/
│   └── codesop-router.md   # Router card
├── templates/
│   ├── system/             # System-level AGENTS.md template
│   ├── project/            # PRD.md, README.md templates
│   └── init/               # Init prompt templates
├── tests/                  # Contract-aligned tests
├── AGENTS.md               # → @CLAUDE.md
├── CLAUDE.md               # Claude Code 项目指南
├── PRD.md                  # 活文档
```

说明：
- 这是当前稳定内核，不再包含 `status/diagnose` 这类历史入口
- `/codesop` 的唯一真相源是 `SKILL.md`

## License

MIT
