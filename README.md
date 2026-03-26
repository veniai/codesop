# codesop

**AI 编码标准操作流程 / AI Coding Standard Operating Procedure**

A unified SOP for Claude Code, OpenClaw, and Codex CLI. One skill, three tools, one `git pull` to sync everything.

---

## 这是什么？/ What is this?

**[中文]** 一个跨工具的 AI 编码工作流指南。包含 15 个场景的工作流映射、3 个子命令，通过符号链接同步到 Claude Code、OpenClaw、Codex CLI 三个工具。

**[English]** A cross-tool AI coding workflow guide. 15 scenario-to-workflow mappings, 3 sub-commands, synced to Claude Code, OpenClaw, and Codex CLI via symlinks.

## 安装 / Install

```bash
curl -sSL https://raw.githubusercontent.com/veniai/codesop/main/install.sh | bash
```

Or clone manually:

```bash
git clone https://github.com/veniai/codesop.git ~/codesop
cd ~/codesop && bash install.sh
```

Then make sure `~/.local/bin` is on your `PATH`, and run:

```bash
codesop init .
```

## 安装了什么？/ What gets installed?

| File | Target | Tool |
|------|--------|------|
| `AGENTS.md` | `~/.claude/CLAUDE.md` | Claude Code |
| `AGENTS.md` | `~/.codex/AGENTS.md` | Codex CLI |
| `AGENTS.md` | `~/.config/opencode/AGENTS.md` | OpenCode |
| `codesop setup --host claude` | `~/.claude/skills/codesop/` | Claude Code runtime |
| `codesop setup --host codex` | `~/.agents/skills/codesop/` | Codex skill runtime |
| `codesop setup --host opencode` | `~/.agents/skills/codesop/` | OpenCode / OpenClaw runtime |
| `codesop` | `~/.local/bin/codesop` | CLI |

The installer is still a single entrypoint, but runtime layout is now host-aware. Claude Code, Codex, and OpenCode/OpenClaw do not all consume raw skill directories the same way, so `install.sh` delegates to `setup --host auto`.

## 使用方法 / Usage

**编辑和提交：**
```bash
cd ~/codesop
vim SKILL.md
git add . && git commit -m "update" && git push
```

**本地改完后重新同步宿主：**
```bash
codesop setup auto
```

**其他电脑同步：**
```bash
codesop update
```

**查看版本：**
```bash
codesop version
```

## `/codesop init` 会做什么？

`/codesop init [path]` now follows a detection-first flow:

- 扫描当前项目，判断主语言、项目形态、可识别框架
- 默认中文生成项目级配置
- 检测当前机器上的 Claude Code、Codex、OpenCode/OpenClaw
- 检测 `superpowers` 和 `gstack` 是否已安装
- 生成完整 `AGENTS.md`、导入型 `CLAUDE.md`、活文档 `PRD.md`
- 如果已有 `AGENTS.md`，保留原文件，并输出终端合并优化建议
- 自动推断测试、lint、类型检查、smoke 命令并写入模板
- 如果缺失，会按当前宿主工具给出安装命令，确认后由当前大模型继续执行
- 如果已安装，会给出对应的更新命令或更新路径，确认后也由当前大模型继续执行

其中：

- `AGENTS.md` 定义 AI 工作边界、交付约束和文档同步规则
- `PRD.md` 同时承担产品规范和当前工作记录，默认包含长期目标、当前进度、最近决策、风险与工作日志

The CLI output is organized into stable blocks:

- 项目识别
- 环境识别
- 配置计划
- 建议安装命令 / 更新建议
- 下一步

This keeps `init` simple: classify the project, inspect the local AI environment, then generate the right project-level guidance.

## Host-Aware Setup

`codesop` keeps one source repo, but setup is host-aware:

- Claude Code uses `~/.claude/skills/codesop`
- OpenCode / OpenClaw use `~/.agents/skills/codesop`
- Codex uses the shared `~/.agents/skills/codesop` skill directory

For `codesop` specifically, duplicating the same skill under both `~/.agents/skills` and `~/.codex/skills` causes Codex to list it twice. The setup script now keeps only one discoverable Codex skill entry.

Manual repair commands:

```bash
codesop setup auto
codesop setup codex
codesop setup claude
codesop setup opencode
```

## 覆盖场景 / Scenarios Covered

| 场景 / Scenario | 触发词 / Trigger Words |
|-----------------|----------------------|
| 新功能 / New Feature | "build", "add", "create" |
| Bug 修复 / Bug Fix | "fix", "bug", "broken" |
| 小改动 / Small Change | "tweak", "change", "update" |
| 重构 / Refactoring | "refactor", "clean up" |
| Code Review 反馈 | "PR feedback", "review comment" |
| 生产事故 / Production Incident | "production down", "incident" |
| 安全审计 / Security Audit | "security", "OWASP" |
| 性能问题 / Performance | "slow", "benchmark" |
| 设计系统 / Design System | "DESIGN.md", "design system" |
| 视觉审查 / Visual Review | "looks wrong", "visual QA" |
| 周回顾 / Weekly Retro | "retro", "what did I ship" |

## 依赖 / Dependencies

This skill orchestrates existing skills from:

- **[Superpowers](https://github.com/obra/superpowers)** — brainstorming, writing-plans, TDD, subagent-driven-dev
- **[Gstack](https://github.com/garryslist/gstack)** — office-hours, autoplan, review, ship, qa

## 文件结构 / Structure

```
~/codesop/
├── AGENTS.md      # 全局指引 / Universal instructions
├── SKILL.md       # 完整 SOP / Complete workflow guide
├── codesop        # CLI 入口 / CLI entrypoint
├── VERSION        # 版本号 / Version tracking
├── install.sh     # 一键安装 / One-click installer
├── README.md
└── LICENSE
```

## License

MIT
