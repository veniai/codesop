[English](README.en.md) | **中文**

# codesop

**AI 编码标准操作流程 / AI Coding SOP**

skill-first 的 AI 编码工作流操作系统。当前内核只保留 1 套主流程 `/codesop`，以及 2 个机械命令 `init` 和 `update`。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-3.3.3-blue.svg)](VERSION)

---

## 这是什么？

跨工具的 AI 编码工作流操作系统，面向 Claude Code、Codex、OpenCode 等 AI 编码助手。

核心价值：让 AI 助手在任意项目中拥有统一的 workflow 纪律——知道用什么 skill、按什么顺序执行、什么时候该停下来验证。

## 安装

```bash
git clone https://github.com/veniai/codesop.git ~/codesop
cd ~/codesop && bash install.sh
```

确保 `~/.local/bin` 在你的 `PATH` 中。

## 安装了什么？

| 组件 | 目标路径 | 作用 |
|------|---------|------|
| 路由卡 | `~/.claude/codesop-router.md` | SessionStart hook 注入纪律表 |
| Slash 命令 | `~/.claude/commands/` | `/codesop` + `/codesop-init` + `/codesop-update` |
| 系统 AGENTS.md | `~/.claude/CLAUDE.md` → `templates/system/AGENTS.md` | 全局 AI 契约 + skill 纪律 |
| Skill 运行时 | `~/.claude/skills/codesop/` | Skill 文件运行时 |
| CLI | `~/.local/bin/codesop` | 命令行工具 |

## 使用方法

### 初始化新项目

```bash
/codesop init .
```

### 进入工作台

```bash
/codesop
```

`/codesop` 会输出工作台摘要和下一步建议，最后一行是自然语言工作流指令（1-3 个 skill 串联），按回车即可确认执行。

### Pipeline-to-todo

`/codesop` 会将推荐的链路转为 TaskCreate 任务列表（☐/☑ 可视化进度），防止 AI 遗忘链路中间步骤。再次调用 `/codesop` 时会检测链路是否过期，过期则重新路由。

### 更新

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

## 文档收尾规则

- `/codesop` 路由后的实现任务，在最终回复前必须判定 `CLAUDE.md`、`PRD.md`、`README.md` 是否需要更新
- 如果任一文档需要更新，优先调用 `claude-md-management`
- `AGENTS.md` 不进入默认判定集合，因为它应始终保持为 `@CLAUDE.md` 的薄包装
- `CHANGELOG.md` 不属于默认强制集合
- `/codesop` 会先做一次文档漂移判断，再决定是否把文档更新编进工作流链

## 版本规则

- `VERSION` 是发布版本的唯一真相源
- `skill.json` 和 `PRD.md` 中的版本号必须与 `VERSION` 一致
- `CHANGELOG.md` 顶部默认使用 `Unreleased`，真正进入发布流程时再切成具体版本
- git tag 只在 ship 阶段创建，例如 `v3.0.1`

## 产品边界

- 主流程只有一个：`/codesop`
- 机械命令只有两个：`codesop init`、`codesop update`
- `status` / `diagnose` 已从产品合同中移除
- 主要围绕 Claude Code 设计和测试，Codex / OpenCode 可部分适配

## 覆盖场景

链路的唯一真相源是路由表（`config/codesop-router.md`）的 **链路组装** 规则。以下为典型场景的链路示意（非穷举）：

| 场景 | 链路示意 |
|------|----------|
| 新功能 | brainstorming → codex:rescue → writing-plans → subagent-dev → ☆simplifier → verification → ☆claude-md → finishing → code-review → codex:rescue → receiving-code-review |
| Bug 修复 | systematic-debugging → verification → ☆claude-md → finishing |
| 小改动 | subagent-dev → ☆simplifier → verification → finishing |
| Code Review 反馈 | receiving-code-review → fix → verification → reply |

☆ = 有插件时走。完整插入规则见路由表链路组装段。

## 依赖

codesop 编排以下 skill 生态：

- **[superpowers](https://github.com/obra/superpowers)** — brainstorming, writing-plans, TDD, systematic-debugging, subagent-driven-dev, verification-before-completion, receiving-code-review
- **code-review** — PR 审查：5 agent 并行 + 置信度评分
- **codex** — codex:rescue 双 AI 审查（设计阶段 + 代码审查阶段必走）
- **claude-md-management** — 文档漂移检查（验证后、提交前必走）
- **code-simplifier** — 代码润色（开发后、验证前）

安装方式：
- superpowers: `/plugin install superpowers`（Claude Code）
- code-review: `/plugin install code-review`
- codex: `/plugin marketplace add openai/codex-plugin-cc`

## 架构

```
codesop                     # CLI 入口
setup                       # 宿主安装与同步
├── lib/                    # 核心 shell 模块
├── SKILL.md                # /codesop 定义
├── commands/               # Slash 命令文件
├── config/
│   └── codesop-router.md   # 路由卡
├── templates/
│   ├── system/             # 系统级 AGENTS.md 模板
│   ├── project/            # PRD.md, README.md 模板
│   └── init/               # Init prompt 模板
├── tests/                  # 合同测试
│   └── run_all.sh          # 统一测试入口
├── AGENTS.md               # → @CLAUDE.md
├── CLAUDE.md               # 项目指南
├── PRD.md                  # 活文档
```

## 测试

```bash
# 统一入口
bash tests/run_all.sh

# 或逐个运行
bash tests/codesop-router.sh
bash tests/detect-environment.sh
```

## License

MIT
