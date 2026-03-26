# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

codesop is a cross-tool AI coding SOP (Standard Operating Procedure) that provides unified workflow guidance for Claude Code, OpenClaw, and Codex CLI. It consists of a skill (SKILL.md) for workflow routing and a modular CLI for project initialization and environment detection.

## Commands

```bash
# Run the CLI
bash codesop                    # Diagnose current project
bash codesop init [path]        # Initialize AGENTS.md, CLAUDE.md, PRD.md
bash codesop status [path]      # Show project health status
bash codesop setup [--host X]   # Configure host integration (claude|codex|opencode|auto)
bash codesop update             # Update via git pull
bash codesop version            # Show current version

# Run tests
bash tests/codesop-e2e.sh       # End-to-end test
bash tests/codesop-init.sh      # Init command tests
bash tests/codesop-diagnose.sh  # Diagnose command tests
bash tests/detect-environment.sh # Environment detection tests

# Resync after local edits
bash codesop setup auto
```

## Architecture

```
codesop                 # CLI entrypoint, sources lib modules in order
├── lib/
│   ├── output.sh       # Formatting utilities, tech stack rendering
│   ├── detection.sh    # Project language/framework/tool detection
│   ├── templates.sh    # AGENTS.md, CLAUDE.md, PRD.md template generation
│   ├── updates.sh      # Version checking, install suggestions
│   └── commands.sh     # Subcommand implementations (run_init, run_status, etc.)
├── scripts/
│   ├── collect-signals.sh  # Git state, config file signals
│   ├── diagnose.sh         # Project stage classification
│   └── recommend.sh        # Skill recommendation based on diagnosis
├── setup                # Host-aware installation script
├── SKILL.md             # Workflow routing skill (installed to host skill dirs)
└── AGENTS.md            # Universal AI instructions (symlinked to host config dirs)
```

**Module loading order** (in codesop entrypoint):
1. `lib/output.sh`
2. `lib/detection.sh`
3. `lib/templates.sh`
4. `lib/updates.sh`
5. `lib/commands.sh`

## Host Integration

The `setup` script handles host-specific installations:

| Host | AGENTS.md Target | Skill Runtime |
|------|------------------|---------------|
| Claude Code | `~/.claude/CLAUDE.md` | `~/.claude/skills/codesop/` |
| Codex | `~/.codex/AGENTS.md` | `~/.agents/skills/codesop/` |
| OpenCode/OpenClaw | `~/.config/opencode/AGENTS.md` | `~/.agents/skills/codesop/` |

The CLI is symlinked to `~/.local/bin/codesop`.

## Dependencies

codesop orchestrates skills from:
- **superpowers**: brainstorming, writing-plans, TDD, systematic-debugging, subagent-driven-dev
- **gstack**: office-hours, autoplan, review, ship, qa, investigate

These are detected via `ECOSYSTEM_REGISTRY` in `lib/detection.sh`.

## Key Functions

- `detect_environment()`: Returns key=value pairs for project language, shape, framework, and tool states
- `run_init()`: Generates AGENTS.md, CLAUDE.md, PRD.md with inferred test/lint/smoke commands
- `run_diagnose()`: Collects signals → diagnoses project stage → recommends skills
- `generate_templates()`: Creates project scaffolding with language-appropriate defaults

## File References

When modifying skill content (SKILL.md), run `codesop setup auto` to sync to all host runtimes. The setup copies SKILL.md, skill.json, VERSION and symlinks the agents/ directory.
