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

## 安装了什么？/ What gets installed?

| File | Target | Tool |
|------|--------|------|
| `AGENTS.md` | `~/.claude/CLAUDE.md` | Claude Code |
| `AGENTS.md` | `~/.codex/AGENTS.md` | Codex CLI |
| `AGENTS.md` | `~/.config/opencode/AGENTS.md` | OpenCode |
| `SKILL.md` | `~/.claude/skills/codesop/SKILL.md` | Claude Code |
| `SKILL.md` | `~/.agents/skills/codesop/SKILL.md` | OpenClaw |
| `SKILL.md` | `~/.codex/skills/codesop/SKILL.md` | Codex CLI |

All via symlinks — edit once, sync everywhere.

## 使用方法 / Usage

**编辑和提交：**
```bash
cd ~/codesop
vim SKILL.md
git add . && git commit -m "update" && git push
```

**其他电脑同步：**
```bash
cd ~/codesop && git pull
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
├── install.sh     # 一键安装 / One-click installer
├── README.md
└── LICENSE
```

## License

MIT
