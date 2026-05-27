# Changelog

## [Unreleased]

## [3.11.0] - 2026-05-27

### Added
- writing-plans spec coverage gate: requirement extraction (R1..RN enumeration) before plan review
- Subagent-based spec coverage check with Traceability Matrix, replacing subjective self-review "skim"
- Calibration examples for ❌/⚠️ coverage assessment in reviewer prompt
- Bounded re-dispatch (max 2 rounds) when coverage gaps are found

## [3.10.2] - 2026-05-11

### Fixed
- Sed injection vulnerability: escape `&`, `\`, `/` in project name during template substitution (`_escape_sed_replacement` helper)
- `codesop update` stash now includes untracked files (`-u` flag)
- Remove dead `executing-plans` reference from writing-plans patch
- Extract `_escape_sed_replacement()` using pure bash parameter expansion (zero forks)
- Document drift fixes: SKILL.md, PRD.md, CLAUDE.md, README.en.md synced

## [3.10.1] - 2026-05-11

### Fixed
- Dependency check: skip superpowers per-host gap for inactive hosts (no more "Codex: 未安装" for Claude-only users)
- Finishing skill patch: add `git fetch --prune` after PR creation to clean stale remote tracking refs

## [3.10.0] - 2026-05-11

### Added
- Completion Gate 文档管理增强：SKILL.md §5 从 3 文档扩展为 5 文档审计（CLAUDE.md / PRD.md / README.md / CONTEXT.md / docs/adr/）
- 结构化审计维度：P1-P5（进度/决策/范围/风险/里程碑）、R1-R4（安装/运行/配置/接口）、C1-C2（术语/冲突）、A1-A2（新增/影响 ADR）
- ADR 模板补全 Status 生命周期字段、Notes 追加段、可变性规则注释
- AGENTS.md 模板输出格式改为 ☐/☑ 可视化 + 维度交叉引用
- `codesop uninstall` 子命令：移除 codesop 集成（保留已安装插件）

### Changed
- AGENTS.md 文档判定输出块去重，改为交叉引用 SKILL.md §5

### Fixed
- 测试断言用表格行格式精确匹配维度标识符，防止裸字符串误匹配
- CLAUDE.md 合并重复的 dependencies.sh 说明行

## [3.9.7] - 2026-05-07

### Fixed
- `upgrade_managed_deps` timeout false-positive: non-patched plugins that are already at latest no longer reported as "failed"
- Patched plugin (superpowers) upgrade gate: skip `claude plugin update` when installed version is already compatible with manifest, preventing accidental major.minor jumps that break patches
- Clarify superpowers version incompatibility warning message

### Changed
- `upgrade_managed_deps` reporting now uses 4 categories: 已升级 / 已是最新 / 超时未变 / 失败
- New `_dep_installed_version()` helper reads plugin version from `installed_plugins.json`
- `_dep_upgrade_one()` uses before/after version comparison to detect successful upgrades despite non-zero exit codes

## [3.9.6] - 2026-05-06

### Fixed
- Restore finishing-branch patch to direct push+PR (skip 4-option menu)
- Fix PR existence check: `grep -qE '^[0-9]+$'` prevents `null` false positive

## [3.9.5] - 2026-05-06

### Fixed
- Write update cache in all `codesop update` exit paths (fork, local-ahead) to prevent stale notifications
- Add `worktree` and `finishing` mentions to README contract check

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
