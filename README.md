# codesop — AI Coding Standard Operating Procedure

A unified SOP for AI coding tools: Claude Code, OpenClaw, and Codex CLI.

## What is this?

A single skill file + universal instructions that work across all three major AI coding tools. One `git pull` updates everything everywhere.

## Features

- **15 scenario → workflow mappings** — from new features to production incidents
- **3 sub-commands** — init, status, update
- **Cross-tool sync** — one file, 6 symlinks, 3 tools
- **Conflict resolution** — clear rules when skills overlap
- **Iron laws** — non-negotiable coding principles

## Quick Install

```bash
curl -sSL https://raw.githubusercontent.com/veniai/codesop/main/install.sh | bash
```

Or clone manually:

```bash
git clone https://github.com/veniai/codesop.git ~/codesop
cd ~/codesop && bash install.sh
```

## What gets installed

| File | Target | Tool |
|------|--------|------|
| `AGENTS.md` | `~/.claude/CLAUDE.md` | Claude Code |
| `AGENTS.md` | `~/.codex/AGENTS.md` | Codex CLI |
| `AGENTS.md` | `~/.config/opencode/AGENTS.md` | OpenCode |
| `SKILL.md` | `~/.claude/skills/codesop/SKILL.md` | Claude Code |
| `SKILL.md` | `~/.agents/skills/codesop/SKILL.md` | OpenClaw |
| `SKILL.md` | `~/.codex/skills/codesop/SKILL.md` | Codex CLI |

All via symlinks — edit once, sync everywhere.

## Usage

Edit and commit from `~/codesop`:

```bash
cd ~/codesop
vim SKILL.md           # or AGENTS.md
git add . && git commit -m "update" && git push
```

Other machines:

```bash
cd ~/codesop && git pull
```

## Scenarios Covered

| Scenario | Trigger Words |
|----------|--------------|
| New Feature | "build", "add", "create" |
| Bug Fix | "fix", "bug", "broken" |
| Small Change | "tweak", "change", "update" |
| Refactoring | "refactor", "clean up" |
| Code Review Feedback | "PR feedback", "review comment" |
| Production Incident | "production down", "incident" |
| Security Audit | "security", "OWASP" |
| Performance | "slow", "benchmark" |
| Design System | "DESIGN.md", "design system" |
| Visual Review | "looks wrong", "visual QA" |
| Weekly Retro | "retro", "what did I ship" |

## Dependencies

This skill orchestrates existing skills from:

- **[Superpowers](https://github.com/obra/superpowers)** — brainstorming, writing-plans, TDD, subagent-driven-dev, etc.
- **[Gstack](https://github.com/garryslist/gstack)** — office-hours, autoplan, review, ship, qa, etc.

Install them first if you haven't.

## License

MIT
