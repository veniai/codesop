# Changelog

## [1.0.1] - 2026-03-27

### Added
- Init interview mode: `run_init_interview` replaces `run_init` for interactive project setup
- System-level AGENTS.md template (`templates/system/AGENTS.md`) with user preference placeholders
- Init prompt template (`templates/init/prompt.md`)
- Per-host skill detection: report missing gstack/superpowers per host with install commands
- Orphaned Claude Code plugin detection and cleanup suggestions

### Changed
- CLI entrypoint: `init` subcommand routes to `run_init_interview`
- Setup: symlink system AGENTS.md template instead of root AGENTS.md
- AGENTS.md skip message: constructive suggestion instead of "跳过更新"

### Fixed
- `pipefail` crashes in init-interview.sh (cat|tr, bare return)
- `git fetch` hanging: wrapped with `timeout 10`
- Graceful handling of unpushed commits in `codesop update`
- Version comparison using `sort -V` for correct ordering
- Update commands: `/plugin update superpowers`, `/gstack-upgrade` instead of raw `git pull`

## [1.0.0] - 2026-03-20

### Added
- Initial release of codesop CLI
- Project initialization with AGENTS.md, PRD.md, README.md scaffolding
- Environment detection for Claude Code, Codex, OpenCode
- Host integration via `setup` script
- Skill dependency checking (superpowers, gstack)
- `/codesop-init`, `/codesop-status`, `/codesop-setup`, `/codesop-update` slash commands
