# Changelog

## [1.1.1] - 2026-03-30

### Changed
- `/codesop` skill rewritten as English workbench/workflow router (was Chinese task-alignment format)
- Router skill now reads AGENTS.md + PRD.md for project orientation, recommends downstream skills
- Added CLI command bypass: mechanical subcommands (`/codesop init`, etc.) skip workbench mode
- Added 11 workflow scenarios with mandatory skill pipelines (new feature, bug fix, refactoring, etc.)

### Fixed
- `codesop update`: always fetch before comparing local/remote hashes (was fetch-on-demand)
- `codesop update`: swap inverted ahead/behind calculations
- `codesop update`: handle diverged branches (ahead + behind) with explicit message
- `codesop update`: attempt stash + pull + pop when `git pull --ff-only` fails with dirty tree
- Router consistency test updated to match new workbench format (was checking old task-alignment markers)
- Hook query test uses regex match instead of exact path (`~` vs `$HOME` mismatch)

## [1.1.0] - 2026-03-30

### Added
- Router card discipline layer: three-layer redundancy to fight AI context dilution
- SessionStart hook injects router card into every Claude Code conversation
- Task alignment mechanism: forced structured output before any new task
- `install_router_card()`, `configure_hooks()`, `check_discipline_deps()` in setup
- Skill discipline section in shared AGENTS.md template
- Task alignment checkpoint in codesop.md Decision Flow and Iron Law
- Consistency test suite (11 tests) for router card and setup integration
- Design spec and implementation plan documentation

### Fixed
- Harden `configure_hooks()` against malformed JSON and stale temp files
- Use `$HOME` instead of `~` in hook command for cross-shell compatibility
- Idempotency test no longer masks setup crashes

## [1.0.2] - 2026-03-29

### Fixed
- Detect superpowers from Claude Code plugin marketplace cache path (`~/.claude/plugins/cache/<marketplace>/superpowers/<version>/`)
- Add shared `find_superpowers_plugin_path()` to `lib/output.sh`, replacing inline duplicates
- Consistent plugin cache fallback across all host cases (claude, codex, opencode) in `updates.sh`
- `detect-environment.sh` reuses shared function instead of inline copy

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
