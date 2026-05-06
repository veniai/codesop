# Changelog

## [Unreleased]

## [3.9.4] - 2026-05-06

### Added
- New version notification: `/codesop` workbench shows update prompt when a newer version is available (`check_update_notification()`)
- 24h throttled check via `git fetch origin main` + remote VERSION comparison, cached in `~/.cache/codesop/update-cache`
- `CODESOP_NO_UPDATE_CHECK=1` environment variable to skip the check

## [3.9.3] - 2026-05-06

### Fixed
- Added `_ensure_superpowers_version()` guard after `upgrade_managed_deps` — verifies superpowers reached required version before applying patches; retries once with 60s timeout if not

### Changed
- Cleaned up orphan git branches (local + remote)
- Removed stale design artifacts from working tree

## [3.9.2] - 2026-05-05

### Changed
- Removed dead `pip`/`git` code paths from `install_managed_deps()` and `_dep_upgrade_one()` — all 10 deps are plugin type
- Simplified tier failure logic: unconditional `has_required_fail` since all tiers are core/required
- Added `*)` fallback to dep type case blocks to catch future manifest errors
- Fixed `test_helpers.sh` SIGPIPE bug: `printf | grep` under `pipefail` caused flaky test failures on large files
- Compressed PRD Done Recently history (v3.3.2–v3.8.0 → one summary line)
- Updated `dependencies.sh` header to reflect current schema (`type: plugin`, no `optional` tier)

## [3.9.1] - 2026-05-05

### Changed
- README.md major update: added auto-install highlights, removed manual `/plugin install` instructions, added Skill ecosystem table
- Removed `browser-use` and `claude-to-im` from managed dependency manifest — they remain in routing table as optional user-installed skills
- Cleaned `OPTIONAL_SKILLS` and routing coverage report to match manifest scope

## [3.9.0] - 2026-05-05

### Added
- First-time install auto-dependencies: `setup` now auto-installs missing plugins and pip packages
- `install_managed_deps()` in `lib/updates.sh`: idempotent install using same manifest as upgrades

### Changed
- `install_claude()` in setup: sources `lib/updates.sh` and calls `install_managed_deps()` before `patch_skills()`

## [3.8.0] - 2026-05-05

### Added
- Unified dependency upgrade: `codesop update` now auto-upgrades all managed dependencies
- `config/dependencies.sh`: dependency manifest defining type, tier, patch status, min version

## [3.7.1] - 2026-05-05

### Changed
- Rebase superpowers patches onto v5.1.0 upstream

## [3.7.0] - 2026-05-03

### Added
- Git health check in workbench: detect orphan branches and leftover feature branches

## [3.6.0] - 2026-04-30 — README redesign

## [3.5.0] - 2026-04-29 — CONTEXT.md / ADR / architecture principles / domain language

## [3.4.0] - 2026-04-25 — Pipeline branch transition, dead module cleanup (templates.sh, output.sh)

## [3.3.1] - 2026-04-24 — Skill patch mechanism, worktree conditional, pipeline auto re-entry

## [3.0.0] - 2026-04-20 — Sub-agent execution architecture

## [2.6.0] - 2026-04-16 — Task list terminology, pipeline dashboard

## [2.4.0] - 2026-04-12 — Pipeline-to-todo conversion

## [2.2.0] - 2026-04-08 — Git worktree fix, qualified skill names

## [2.0.0] - 2026-04-03 — Remove GStack dependency, rewrite routing table

[1.0.0]: https://github.com/veniai/codesop/releases/tag/v1.0.0
