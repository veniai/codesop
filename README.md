# codesop

**AI 编码标准操作流程 / AI Coding Standard Operating Procedure**

A skill-first operating system for AI-assisted coding work. One `/codesop` command routes every task to the right skill pipeline across Claude Code, Codex CLI, and OpenCode.

---

## 这是什么？ / What is this?

**[中文]** 跨工具的 AI 编码工作流操作系统。`/codesop` skill 读取项目上下文，推荐下一步 workflow，路由到 superpowers + gstack 的 skill pipeline。CLI 提供项目初始化、环境检测、版本管理。

**[English]** A cross-tool AI coding workflow OS. The `/codesop` skill reads project context, recommends next workflows, and routes to superpowers + gstack skill pipelines. The CLI handles project init, environment detection, and version management.

## 安装 / Install

```bash
git clone https://github.com/veniai/codesop.git ~/codesop
cd ~/codesop && bash install.sh
```

Then make sure `~/.local/bin` is on your `PATH`, and run:

```bash
codesop setup --host auto
```

## 安装了什么？ / What gets installed?

| Component | Target | Purpose |
|-----------|--------|---------|
| Router card | `~/.claude/codesop-router.md` | SessionStart hook 注入纪律表 |
| Slash commands | `~/.claude/commands/` | `/codesop`, `/codesop-init`, `/codesop-setup`, `/codesop-update` |
| System AGENTS.md | `~/.claude/CLAUDE.md` → `templates/system/AGENTS.md` | 全局 AI 契约 + skill 纪律 |
| Skill runtime | `~/.claude/skills/codesop/` | Skill 文件运行时 |
| CLI | `~/.local/bin/codesop` | 命令行工具 |

## 使用方法 / Usage

**初始化新项目：**
```bash
# 在 Claude Code 中
/codesop init .
```

**查看项目状态：**
```bash
/codesop
```

**同步宿主（本地改完后）：**
```bash
codesop setup --host claude
```

**更新 codesop：**
```bash
codesop update
# 或
/codesop-update
```

## `/codesop init` 会做什么？

1. 扫描项目：判断主语言、项目形态、框架
2. 检测环境：Claude Code / Codex / OpenCode / superpowers / gstack
3. 生成项目文件：
   - `AGENTS.md` → `@CLAUDE.md`（轻量引用）
   - `PRD.md` → 活文档（产品规范 + 进度 + 工作日志）
   - `README.md` → 安装/运行/测试命令（如不存在）
4. CLAUDE.md 由 Claude Code 的 `/init` 生成，codesop 不覆盖

其中：
- `AGENTS.md` 是宿主工具的入口，指向 `CLAUDE.md`
- `PRD.md` 同时承担产品规范和当前工作记录
- 默认中文，自动推断 test/lint/typecheck/smoke 命令

## 覆盖场景 / Workflow Scenarios

| 场景 | Pipeline |
|------|----------|
| 新功能 | office-hours → writing-plans → autoplan → worktree → subagent-dev → TDD → verification → review → ship |
| Bug 修复 | investigate → systematic-debugging → TDD → verification → review |
| 小改动 | TDD → verification → review (if multi-file) |
| 重构 | brainstorming → writing-plans → worktree → subagent-dev → verification → review → ship |
| Code Review 反馈 | receiving-code-review → TDD fix → verification → reply |
| 生产事故 | careful → investigate → systematic-debugging → fix → canary |

## 依赖 / Dependencies

codesop 编排以下 skill 生态：

- **[superpowers](https://github.com/obra/superpowers)** — brainstorming, writing-plans, TDD, systematic-debugging, subagent-driven-dev, verification-before-completion
- **[gstack](https://github.com/garryslist/gstack)** — office-hours, autoplan, review, ship, qa, investigate, codex

安装方式：
- superpowers: `/plugin install superpowers` (Claude Code)
- gstack: `git clone https://github.com/garryslist/gstack.git ~/.claude/skills/gstack`

## 架构 / Architecture

```
codesop                     # CLI entrypoint
├── lib/                    # Shell modules (output, detection, templates, updates, commands, init-interview)
├── commands/               # Slash command skill files
├── config/
│   └── codesop-router.md   # Router card source of truth
├── templates/
│   ├── system/             # System-level AGENTS.md template
│   ├── project/            # PRD.md, README.md templates
│   └── init/               # Init prompt templates
├── scripts/                # Diagnose pipeline scripts
├── tests/                  # Test suite (12 files)
├── AGENTS.md               # → @CLAUDE.md (项目级引用)
├── CLAUDE.md               # Claude Code 项目指南
├── PRD.md                  # 活文档
└── setup                   # Host-aware installation script
```

## License

MIT
