**English** | [中文](README.md)

<p align="center">
  <img src="docs/assets/codesop-readme-hero.png" alt="codesop — AI Coding SOP" width="100%">
</p>

<p align="center">
  <strong>One install, full AI coding toolkit</strong><br>
  10 curated Skills auto-installed · AI gains SOP discipline · Covers the entire coding workflow
</p>

<p align="center">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License">
  <img src="https://img.shields.io/badge/Claude_Code-Plugin-blue.svg" alt="Claude Code">
  <img src="https://img.shields.io/badge/version-3.9.3-blue.svg" alt="Version">
</p>

---

> Overwhelmed by Claude Code plugins, not sure which to install? AI writes code without discipline? Long tasks spin out of control?
>
> **codesop solves this.** One command installs 10 battle-tested core Skills. Ready to use immediately.

## Quick Start

**Copy and paste** this prompt to your AI coding assistant:

```text
Install codesop — an AI coding workflow OS. Follow these steps:
1. git clone https://github.com/veniai/codesop.git ~/codesop
2. cd ~/codesop && bash install.sh    # Auto-installs codesop + all dependency plugins
3. Verify ~/.local/bin/codesop is executable (add ~/.local/bin to PATH in ~/.bashrc or ~/.zshrc if needed)
4. Run codesop init in the current project directory to initialize
After installation, explain how to use the /codesop workbench.
```

Once installed (in Claude Code):

```
/codesop init      # Initialize current project
/codesop           # Open the workbench
/codesop update    # Update codesop and auto-upgrade all dependency plugins
```

<details>
<summary>Manual install</summary>

```bash
git clone https://github.com/veniai/codesop.git ~/codesop
cd ~/codesop && bash install.sh    # Auto-installs codesop + all dependency plugins
```

Make sure `~/.local/bin` is on your `PATH`.

</details>

## Why codesop

**Curated toolkit, no guessing** — 10 core Skills auto-installed: requirements analysis, design review, TDD, debugging, code review, doc management, frontend design, browser testing... Full workflow coverage, battle-tested, no pitfalls

**AI stays disciplined** — Four SOP iron laws enforced: design before coding, fail before producing, no fix without root cause, no completion without evidence. AI can't just write code freely

**Automatic routing** — Don't know which Skill to use? The routing table picks for you. New features → brainstorming → plan → dev → verify. Bugs → debugging → verify. No guessing required

**Long tasks stay on track** — Pipeline task list with auto-split, sequential execution, ☐/☑ visual progress. Long development sessions stay under control

**Context never lost** — Every time you enter a project, AI auto-restores full context. No more "AI forgot what it did last time"

## Scenarios

| What you want | /codesop chain |
|--------------|----------------|
| New feature | brainstorming → design review → plan → dev → verify → submit PR |
| Bug fix | root cause → verify → submit PR |
| Small change | dev → verify → submit PR |
| PR feedback | evaluate → fix → full test → submit |

## Skill Toolkit

All Skills are auto-configured during install — no manual setup needed:

| Skill | Capabilities |
|-------|-------------|
| superpowers | brainstorming, writing-plans, TDD, systematic-debugging, subagent-dev, verification |
| code-review | 5-agent parallel PR review + confidence scoring |
| codex | Dual-AI review (design + code review) |
| frontend-design | Enforced design thinking, unique layouts and aesthetics |
| context7 | Real-time docs and code examples for third-party libraries |
| code-simplifier | Code polish (readability + structure optimization) |
| playwright | Page interaction and automated testing |
| chrome-devtools-mcp | Browser diagnostics: performance / a11y audits |
| claude-md-management | CLAUDE.md quality audit and document drift detection |
| skill-creator | Full skill lifecycle management |

Run `/codesop update` to upgrade all installed Skills in one command.

<details>
<summary>Initialize a project</summary>

```bash
/codesop init
```

Auto-scans project shape and generates the files your AI assistant needs:

- `AGENTS.md` → `@CLAUDE.md` (AI entry point)
- `PRD.md` → product spec + progress + work log
- `README.md` → install/run/test commands (if missing)
- `docs/adr/` → architecture decision records

</details>

<details>
<summary>Architecture</summary>

```
codesop                     # CLI entrypoint
setup                       # Host integration sync
├── lib/                    # Core shell modules
├── SKILL.md                # /codesop definition
├── commands/               # Slash command files
├── config/
│   └── codesop-router.md   # Router card
├── templates/
│   ├── system/             # System-level AGENTS.md template
│   ├── project/            # PRD.md, README.md templates
│   └── init/               # Init prompt templates
├── tests/                  # Contract tests
├── AGENTS.md               # → @CLAUDE.md
├── CLAUDE.md               # Project guide
├── PRD.md                  # Living document
```

</details>

## Related Projects

- **[cc-monitor](https://github.com/veniai/cc-monitor)** — Remote monitoring and control for Claude Code. Get notified on WeChat/DingTalk/Feishu when tasks complete, auto-recover stuck sessions, send commands from your phone

## License

MIT
