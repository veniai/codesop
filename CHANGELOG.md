# Changelog

## [Unreleased]

## [3.16.1] - 2026-06-23

### Fixed
- `check_understand_usability` 5 处 `node` 调用包 `_ua_to` timeout 前缀（仿 `check_git_health`，`command -v timeout` macOS fallback）——防 NFS/大文件 `require()` 挂起（CLAUDE.md Key Gotcha #113/#127 + 历史 `ada2445`）。code-review（5-agent）B1 发现。
- `meta_hash` 加 `|| meta_hash=""` 兜底——防 `set -euo pipefail` 下命令替换失败终止进程（latent）。code-review I2。
- `SKILL.md` §3 step 7 注释更正——M1 fix 后"无 node 误判 corrupt"已不成立（函数自兜底 `unknown_head`）+ 提 node timeout。code-review 3-agent 交叉确认。

## [3.16.0] - 2026-06-23

### Added
- 路由表新增「0. 项目理解与导航」大类（understand-chat/diff/explain/onboard）+ 链路组装条件插入规则——接入 [understand-anything](https://github.com/Egonex-AI/Understand-Anything) 作为项目理解/架构认知环节（spec `docs/superpowers/specs/2026-06-22-understand-anything-integration-design.md`）。
- `lib/detection.sh` `check_understand_usability`——7 状态图谱可用性检测（absent/corrupt/unknown_head/stale_on/stale_off/fresh_on/fresh_degraded），含 worktree 重定向、子目录 `show-toplevel`、JSON parser（`autoUpdate===true` 严格）、fingerprints 检查、node 兜底。
- `SKILL.md` §2 Read Order 第 5 条（图谱可用作上下文）+ §3 step 7 detection 调用 + §4.1 7 状态分级提示（stale_on 事实性文案，不断言 hook 坏了）。
- `tests/detect-understand.sh`——21+ 断言真跑（7 状态 + corrupt 变体 + config 字符串 + worktree + 子目录 + 无 node）。
- README 中英「兼容生态：understand-anything」段。
- `lib/updates.sh` `check_routing_coverage` understand-anything marketplace 特判（修路由覆盖误报）。

### Fixed
- 无 node 环境 `check_understand_usability` 不再误判 `corrupt`（node 兜底 → `unknown_head`）。

## [3.15.0] - 2026-06-18

### Changed
- Re-based superpowers patches onto v6.0.3 (brainstorming, writing-plans, finishing); preserves whole-file-overwrite delivery.
- finishing: PR operations now forge-neutral (no hardcoded `gh`); worktree kept after PR for review iteration (adopts upstream Option 2 behavior).
- writing-plans: retains upstream Global Constraints / per-task Interfaces / Task Right-Sizing alongside codesop acceptance-criteria + staged-checkpoint flow.

### Removed
- subagent-driven-development reviewer patches (`spec-reviewer-prompt.md`, `code-quality-reviewer-prompt.md`) — absorbed by superpowers 6.0's merged `task-reviewer-prompt.md`.

### Added
- Re-base checklist doc (docs/superpowers/playbooks/rebase-superpowers-patches.md) — anti-regression + drift handling.

### Fixed
- superpowers `min_version` 5.1.0 → 6.0.3; patches re-apply on 6.0 installs (were silently skipped). v6.0.3 verified compatible — the 3 patched skills are unchanged 6.0.2→6.0.3.

## [3.14.2] - 2026-06-15

### Fixed
- 文档判定 gate 减法纪律自洽性修订（dogfood 自检发现 v3.14.1 的问题）：
  - 去冗余：事故复盘从 3 处收敛到反膨胀清单 1 处（修复规则违反自身"合并优于追加"原则）
  - 补存量红线：加总尺寸警戒（`CLAUDE.md` >300 行/15KB 优先精简），补 neat-freak 第零步（v3.14.1 漏提取）
  - 可执行性：净涨幅改"相对 HEAD 的净增（`git diff --numstat -- <file>`）"，明确边界
- detect-environment.sh 加"总尺寸警戒"断言

## [3.14.1] - 2026-06-15

### Added
- 文档判定 gate 减法纪律（防膨胀）：AGENTS.md 文档职责段加判断标准"看不到会犯错吗" + 三原则（减优于加 / 合并优于追加 / 删除优于保留）；文档判定段加净涨幅红线（CLAUDE.md 净改 >30 行回头审）+ 反膨胀清理清单（5 类该删内容）
- detect-environment.sh 断言 AGENTS.md 模板含减法关键词（减法纪律 / 净涨幅警戒 / 反膨胀清理清单）
- 补全 neat-freak 的减法方向（2026-04-29 doc-gate-enhancement 当年只提取了正向补漏）

## [3.14.0] - 2026-06-12

### Added
- Staged checkpoint flow for complex plans: three-stage output (skeleton → task expansion → self-review)
- Stage 1 writes plan skeleton (AC + task outline, NO code) and saves to file
- Stage 2 expands tasks one at a time with implementation briefs (not full code blocks)
- Stage 3 runs traceability + self-review as a separate re-read operation
- Resume protocol: interrupted sessions can detect last completed stage and continue
- Implementation brief format: design constraints, interface signatures, edge cases, test obligations, critical snippets
- Checkpoint announcements between stages (Stage 1/3, Stage 2/3)
- Implementation briefs are explicitly distinguished from placeholders in No Placeholders section

### Changed
- Complex tasks no longer use full code blocks in plans — replaced with implementation briefs
- Task Structure section labeled as reference format (not used by either complex or lightweight paths)
- Self-Review subagent prompt updated to reference implementation briefs instead of steps
- Lightweight plan comparison table updated to reflect implementation brief format
- Remember section updated: complex tasks use briefs, not complete code
- Pipeline Continuation completion points updated for staged flow

## [3.13.0] - 2026-06-11

### Added
- writing-plans acceptance criteria phase: write verifiable G1..GN before task decomposition
- Two AC formats: full Given/When/Then (behavior changes) and simplified (mechanical edits)
- Adversarial self-check with two questions: implementation laziness + verify command reliability
- Complexity assessment with file/module metrics and override rules (public API, security, etc.)
- Phase split: simple/moderate → lightweight plan (brief guidance); complex → full plan with self-review
- Lightweight plan schema (unified with full plan, implementation_guidance depth field)
- Enhanced self-review with acceptance coverage matrix for complex tasks
- Gap scan (edge cases, regression risk, integration)
- Lightweight plan escalate mechanism for underestimated complexity
- Format classification guidance ("when in doubt, use full format")

### Changed
- Coverage Matrix simplified from mandatory table to one-sentence coverage check rule
- Gap Scan reduced from 6 items to 3 (merged related categories)
- Pipeline Continuation now has tiered completion points by complexity level

## [3.12.2] - 2026-05-31

### Changed
- Router: using-git-worktrees re-enabled as default (was "仅用户明确要求时插入")
- System AGENTS.md: git discipline simplified to branch cleanup + rebase rules (worktree lifecycle managed by Claude Code)

## [3.12.1] - 2026-05-31

### Added
- Git worktree discipline rules in system AGENTS.md: no auto-deleting worktree-bound branches, sync main before rebase, force-with-lease after rebase

## [3.12.0] - 2026-05-29

### Added
- Spec reviewer step compliance: mandatory sub-step enumeration (S1..SN) + Step Compliance Matrix
- Anti-stub detection: disabled UI, empty handlers, hardcoded returns, swallowed exceptions (frontend + backend)
- Complexity proportionality check: >3 sub-steps but <20 lines → flag
- Monolithic step self-decomposition: reviewer breaks complex steps into atomic requirements
- Code quality reviewer implementation depth check: verifies substance not just structure
- setup patch_skills() extended to sync subagent-driven-development reviewer prompt files

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
