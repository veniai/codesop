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

`/codesop` 会在摘要和推荐之后，把真正的下一步动作放在最后一行，输出为一条自然语言工作流指令。它可以串 1 到 3 个 skill，尽量让 Claude Code 把它识别成输入框里的灰色默认建议，便于直接回车继续。好的输出重点不在”推荐一个 skill”，而在”把下一步工作流链组织清楚”。前台默认应围绕当前项目，而不是 `codesop` 自己的仓库自检。

**Pipeline-to-todo**: `/codesop` 会将推荐的链路转为 TaskCreate 任务列表（☐/☑ 可视化进度），防止 AI 遗忘链路中间步骤。再次调用 `/codesop` 时会检测链路是否过期（分支切换、git 状态变化、意图变化），过期则重新路由。每个 skill 完成后会回看 TaskList 提示下一步。

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
- 但文档不应只在收尾时才想起。`/codesop` 应先做一次文档漂移判断，再决定是否把 `PRD.md/README.md/CLAUDE.md` 编进下一步工作流链
- `/codesop` 前台展示的文档状态应来自当前项目；`codesop` 自身仓库的一致性检查只适合内部维护，不应抢占当前项目工作台

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
- 主要围绕 Claude Code 设计和测试，Codex/OpenCode 可部分适配
- `/codesop` 收尾必须以一条自然语言工作流指令结束；允许串联多个 skill，不再强制 slash command 形式
- `/codesop` 的核心职责是组织“下一步工作流链”，不是停在“推荐一个 skill”

## 覆盖场景 / Workflow Scenarios

链路的唯一真相源是路由表（`config/codesop-router.md`）的 **链路组装** 规则。以下为典型场景的链路示意（非穷举）：

| 场景 | 链路示意 |
|------|----------|
| 新功能 | brainstorming → codex:rescue → writing-plans → worktree → subagent-dev → ☆simplifier → verification → ☆claude-md → finishing → code-review → codex:rescue → receiving-code-review |
| Bug 修复 | systematic-debugging → verification → ☆claude-md → finishing |
| 小改动 | subagent-dev → ☆simplifier → verification → finishing |
| Code Review 反馈 | receiving-code-review → fix → verification → reply |

☆ = 有插件时走。完整插入规则见路由表链路组装段。

## 依赖 / Dependencies

codesop 编排以下 skill 生态：

- **[superpowers](https://github.com/obra/superpowers)** — brainstorming, writing-plans, TDD, systematic-debugging, subagent-driven-dev, verification-before-completion, receiving-code-review
- **code-review** — PR 审查：5 agent 并行 + 置信度评分
- **codex** — codex:rescue 双 AI 审查（设计阶段 + 代码审查阶段必走）
- **claude-md-management** — 文档漂移检查（验证后、提交前必走）
- **code-simplifier** — 代码润色（开发后、验证前）

安装方式：
- superpowers: `/plugin install superpowers` (Claude Code)
- code-review: `/plugin install code-review`
- codex: `/plugin marketplace add openai/codex-plugin-cc`

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
