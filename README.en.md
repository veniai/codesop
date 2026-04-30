**English** | [中文](README.md)

<p align="center">
  <img src="docs/assets/codesop-readme-hero.png" alt="codesop — AI Coding SOP" width="100%">
</p>

<p align="center">
  <strong>Skill-first workflow OS for AI-assisted coding</strong><br>
  Context restore · Skill routing · Pipeline task list · Verification and document gates
</p>

<p align="center">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License">
  <img src="https://img.shields.io/badge/Claude_Code-Plugin-blue.svg" alt="Claude Code">
  <img src="https://img.shields.io/badge/version-3.5.2-blue.svg" alt="Version">
</p>

---

> Give AI assistants unified workflow discipline in any project —<br>
> knowing which skill to use, what order to execute, and when to stop and verify.

## Quick Start

Send this to your AI coding assistant:

> Install codesop for me: https://github.com/veniai/codesop

The AI handles cloning and configuration. Then:

```bash
/codesop init .    # Initialize current project
/codesop           # Open the workbench
```

<details>
<summary>Manual install</summary>

```bash
git clone https://github.com/veniai/codesop.git ~/codesop
cd ~/codesop && bash install.sh
```

Make sure `~/.local/bin` is on your `PATH`.

</details>

## What it does

`/codesop` is your AI coding workbench. Every time you enter a project:

1. **Restore context** — reads AGENTS.md and PRD.md to understand project state
2. **Route** — assembles the best skill chain for your intent
3. **Pipeline execution** — converts the chain into a task list, auto-executes step by step
4. **Verification gate** — every step must pass verification before completion, no skipping

Cross-tool support: Claude Code (primary) · Codex · OpenCode

## Scenarios

| What you want | /codesop chain |
|--------------|----------------|
| New feature | brainstorming → design review → plan → dev → verify → submit PR |
| Bug fix | root cause → verify → submit PR |
| Small change | dev → verify → submit PR |
| PR feedback | evaluate → fix → full test → submit |

## Initialize a project

```bash
/codesop init .
```

Auto-scans project shape and generates the files your AI assistant needs:

- `AGENTS.md` → `@CLAUDE.md` (AI entry point)
- `PRD.md` → product spec + progress + work log
- `README.md` → install/run/test commands (if missing)
- `docs/adr/` → architecture decision records

## Skill Ecosystem

codesop orchestrates these skills:

- **[superpowers](https://github.com/obra/superpowers)** — brainstorming, writing-plans, TDD, systematic-debugging, subagent-dev, verification
- **code-review** — 5-agent parallel PR review + confidence scoring
- **codex** — dual-AI review (design + code review phases)
- **claude-md-management** — document drift detection
- **code-simplifier** — code polish

```bash
/plugin install superpowers                      # Claude Code
/plugin install code-review
/plugin marketplace add openai/codex-plugin-cc
```

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

<details>
<summary>Testing</summary>

```bash
bash tests/run_all.sh
```

</details>

## License

MIT
