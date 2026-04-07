# Changelog

## [Unreleased]

### Changed
- `/codesop` final line now uses a natural-language workflow instruction instead of a single slash command
- `/codesop` recommendations now emphasize workflow reasoning over repeating the same action
- Dirty worktrees now bias `/codesop` toward cleanup-first workflows before roadmap-next work
- `/codesop` now frames itself as a workflow-chain composer instead of a single-skill recommender
- `/codesop` now performs a document drift scan so PRD/README/CLAUDE updates can be woven into the next workflow chain
- `/codesop` now teaches output style through complete dirty/clean worktree examples instead of relying only on scattered formatting rules

## [2.0.0] - 2026-04-03

### Breaking Changes
- Remove GStack dependency entirely (173 code references cleaned)
- Rewrite routing table from pipeline model to lifecycle model
- Plugin system replaces dual-engine architecture

### Added
- Single lifecycle routing table covering all 9 plugins + 3 skills
- CORE_PLUGINS / OPTIONAL_PLUGINS / OPTIONAL_SKILLS dependency tiers
- has_plugin() function for plugin detection
- check_plugin_completeness() for dependency validation
- check_plugin_versions() with superpowers GitHub tags comparison
- check_routing_coverage() reading new router table format
- print_dependency_report() as unified dependency output
- Debugging lifecycle path (systematic-debugging → verification → finishing)

### Changed
- codesop-router.md: unified lifecycle table replaces pipeline routing
- SKILL.md: 409→226 lines, section 6 (Workflow Mapping) removed
- lib/updates.sh: 525→~477 lines, new dependency system
- lib/detection.sh: removed gstack, added has_plugin()
- lib/init-interview.sh: removed 31 gstack references
- lib/commands.sh: simplified to print_dependency_report()
- setup: core plugin check replaces gstack warning

### Removed
- All GStack/gstack references from runtime files
- scan_installed_skills(), scan_routed_skills() (old format parsers)
- check_skill_routing_coverage() (old sp/gstack coverage)
- _resolve_tool_path() (gstack path resolution)
- print_dependency_update_checks() (gstack+sp update checks)
- print_install_suggestions() (gstack install/repair suggestions)

## [1.1.6] - 2026-04-02

### Added

- Fit validation: codesop now reads the recommended skill's full content and assesses fit (✅/⚠️/❌/❓) alongside the routing table recommendation
- Compression rule: ✅ results merge into one line; ⚠️/❌ show two lines with backup reference
- "文档更新 / 更新文档 / sync docs" now routes to `document-release`

### Fixed

- Unified routing rules between `SKILL.md` section 7 and `config/codesop-router.md` (bug 路由 now includes investigate; 做功能 now includes office-hours)

## [1.1.5] - 2026-03-31

### Fixed

- `scan_routed_skills()` regex updated to handle three formats: code block, backtick+tag, and routing policy arrow styles
- `verification-before-comp` → `verification-before-completion` alias restored (was dropped in v1.2 cleanup but still needed for test fixtures)
- `check_skill_routing_coverage()` skip list updated to include `design-html` gstack skill
- SKILL.md coverage check command now passes `ROOT_DIR=~/codesop` — was causing `scan_routed_skills` to look for `/SKILL.md`
- `tests/detect-environment.sh` assertions updated to match v1.2 Section 8 table format (was expecting old `### 8.1` subsection format)
- Fixed backtick execution bug in `detect-environment.sh` test assertions

## [1.1.4] - 2026-03-31

### Changed
- Unified skill detection: `has_superpowers()` and `has_gstack()` in `lib/init-interview.sh` now use centralized candidate arrays (`_SP_CANDIDATES`, `_GS_CANDIDATES`) instead of ad-hoc sentinel files
- `has_superpowers()` now checks `find_superpowers_plugin_path()` first, then candidate directories — consistent with `lib/updates.sh`
- `_check_skills_all()` uses `find_superpowers_plugin_path()` for primary detection, with glob-based orphaned plugin scanning
- `detect_project_language()` and `detect_project_shape_and_framework()` promoted to top-level functions with explicit parameters and global variable results (`_DET_PROJECT_LANGUAGE`, `_DET_PROJECT_SHAPE`, `_DET_PROJECT_FRAMEWORK`)
- `_resolve_tool_path()` in `lib/updates.sh` centralizes host-to-path resolution, replacing duplicated case statements in `print_dependency_update_checks()`
- Extracted `_resync_and_check()` helper in `lib/commands.sh`, replacing 4x repeated setup + coverage check calls
- `setup` uses glob `rm -f codesop*.md` before reinstall — handles any future stale command cleanup without per-file lines
- `ensure_new_init_env()` uses `jq -e` for JSON key existence instead of fragile `grep`
- Removed `SKILL_REGISTRY` array — replaced with focused `_SP_CANDIDATES` / `_GS_CANDIDATES`

### Removed
- Nested function definitions inside `detect_environment()` — promoted to top level for clarity
- `brainstorming.md` sentinel file check in `has_superpowers()`
- Hardcoded individual `rm -f` lines for stale commands in `setup`

## [1.1.3] - 2026-03-30

### Added
- Skill routing coverage for new gstack/superpowers skills (design-consultation, design-shotgun, design-review, cso, benchmark, retro, learn, writing-skills, qa-only, freeze/unfreeze, guard, careful, setup-deploy, land-and-deploy, dispatching-parallel-agents, codex review, canary)
- Skill routing coverage check in `codesop update`: warns when installed skills differ from routed skills

### Changed
- Product contract narrowed from 3 mechanical commands to 2: `init` + `update` only
- `setup` is now internal-only, called by `install.sh` and `run_update()`, not exposed as a CLI subcommand
- Removed `/codesop-setup` slash command

### Removed
- `codesop setup` CLI subcommand and `/codesop-setup` slash command
- `commands/codesop-setup.md`

## [1.1.2] - 2026-03-30

### Changed
- Product contract narrowed to one workflow entry (`/codesop`) plus three mechanical commands (`init`, `update`, `setup`)
- `SKILL.md` is now the single source of truth for `/codesop`; `setup` installs it into `~/.claude/commands/codesop.md`
- Router integration test now provisions a temporary Claude home instead of depending on the real `~/.claude`
- Release versioning now uses `VERSION` as the single source of truth; `CHANGELOG.md` stays `Unreleased` until ship
- Skill runtime `skill.json` is now synchronized from `VERSION` during `setup`

### Fixed
- `codesop init` no longer exits early during best-effort skill dependency checks
- Setup integration test now matches the actual system AGENTS/CLAUDE symlink model
- `codesop update` no longer reports "已是最新" when upstream has new commits but `VERSION` has not been bumped yet

### Removed
- `status` / `diagnose` CLI surface and the supporting scripts/tests
- Repo-local `commands/codesop.md` duplicate
- Repo-local `agents/openai.yaml` runtime residue
- Outdated design/spec docs that still described the old dual-source router model
- Redundant `QUICKSTART.md` document

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
- `/codesop-init`, `/codesop-setup`, `/codesop-update` slash commands
