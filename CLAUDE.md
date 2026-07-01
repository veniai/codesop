# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

codesop is a skill-first operating system for AI-assisted coding work. The current product contract keeps one main flow, `/codesop`, plus three mechanical commands: `init`, `update`, and `uninstall`.

## Commands

```bash
# Core contract
bash codesop init [path]        # Initialize project: AGENTS.md + PRD.md + README.md
bash codesop update             # Update via git pull + setup sync
bash codesop uninstall          # Remove codesop artifacts (keeps installed plugins)

# Core tests
bash tests/run_all.sh                 # All tests (unified runner)
bash tests/codesop-router.sh          # Router card consistency + setup integration
bash tests/init-deadcode-removed.sh  # init 死代码防再犯（v4.4 P0-1）
bash tests/detect-environment.sh      # Documentation consistency tests
bash tests/detect-understand.sh       # understand-anything 可用性检测（7 状态）
bash tests/codesop-e2e.sh             # End-to-end test
bash tests/codesop-init.sh            # Init command tests
bash tests/codesop-uninstall.sh       # Uninstall command tests
bash tests/setup.sh                   # Host setup tests
bash tests/codesop-symlink.sh         # Symlink tests
bash tests/codesop-update.sh          # Update command tests
bash tests/skill-routing-coverage.sh  # Skill routing coverage tests

# Resync after local edits
bash setup --host claude
```

## Product Contract

- Supported user-facing flow: `/codesop`
- Supported user-facing commands: `codesop init`, `codesop update`, `codesop uninstall`
- During cleanup, do not add new features outside this contract

## Architecture

```
codesop                     # CLI entrypoint, sources lib modules in order
├── lib/
│   ├── detection.sh        # Project detection, find_superpowers_plugin_path(), has_mcp_server(), check_understand_usability()
│   ├── updates.sh          # Version checking, CHANGELOG extraction, git update checks
│   ├── commands.sh         # Subcommands; target contract keeps init/update/uninstall
│   └── init-interview.sh   # Init workflow: tool detection, system links, project files
├── commands/               # Sub-command files synced to ~/.claude/commands/
│   ├── codesop-init.md     # /codesop-init
│   ├── codesop-update.md   # /codesop-update
│   └── codesop-uninstall.md # /codesop-uninstall
├── config/
│   └── codesop-router.md   # Router card
├── templates/
│   ├── system/             # System-level AGENTS.md template
│   ├── project/             # Project-level templates (PRD.md, README.md, CONTEXT.md, adr-template.md)
│   └── init/               # Init prompt templates
├── docs/                   # Design specs and implementation plans
│   └── superpowers/
│       ├── specs/          # Approved design documents
│       └── plans/          # Implementation plans
├── patches/                # Skill patches applied by setup on sync
│   └── superpowers/        # Patched superpowers skill files (5):
│       ├── brainstorming-SKILL.md           # v9: spec 三件 + codex high-risk + 内联 reviewer
│       ├── writing-plans-SKILL.md           # v9: simple 跳 plan + 复杂度分流 + emoji→文字
│       ├── verification-before-completion-SKILL.md  # v9 新建: deliver-gate 风险分级 + diff 守护
│       ├── _evidence-pack-schema.md         # v9 新建: 证据包 schema（setup 同步为 sibling）
│       └── finishing-a-development-branch-SKILL.md
├── setup                   # Host-aware installation script (router card + hook config + skill patches)
├── SKILL.md                # Full skill definition for /codesop; target source of truth
├── AGENTS.md               # → @CLAUDE.md (project-level reference)
├── CLAUDE.md               # This file
├── PRD.md                  # Living document (product spec + progress + work log)
└── README.md               # Project README
```

**Module loading order** (in codesop entrypoint):
1. `lib/detection.sh` → 2. `lib/updates.sh` → 3. `lib/commands.sh` → 4. `lib/init-interview.sh`

## Init Flow

`/codesop-init` skill handles project initialization in coordination with Claude Code's `/init`:

| Phase | Owner | What it does |
|-------|-------|-------------|
| 0 | Skill Step 0 | Self-heal: `codesop update` + re-read fresh skill |
| 0 | CLI | Tool detection, system links, `CLAUDE_CODE_NEW_INIT` |
| 1 | — | (v4.4 删访谈) 标准偏好硬编码在模板；用户偏好由 Claude Code `/init` + 全局 CLAUDE.md 管 |
| 2 | — | **User runs `/init`** to generate project CLAUDE.md |
| 3 | CLI | AGENTS.md (`@CLAUDE.md`), PRD.md, README.md |
| 4 | CLI | Check skill dependencies (`check_skill_dependencies`) |
| 4a | Skill | If `ADAPT_MODE:YES`: template adaptation (PRD/README diff + CLAUDE.md dedup) |
| 5 | Skill | Prompt user to run `/init` (new mode) or confirm adaptation (adapt mode) |

**Adaptation mode** triggers when all three core files (AGENTS.md, PRD.md, README.md) already exist. CLI outputs `ADAPT_MODE:YES`; skill compares templates vs project files and suggests changes for user confirmation.

CLAUDE.md is NOT generated by codesop. Claude Code's official `/init` handles it.

## Host Integration

The `setup` script handles host-specific installations:

| Host | Config Target | Commands | Hook |
|------|--------------|----------|------|
| Claude Code | `~/.claude/CLAUDE.md` → symlink → `templates/system/AGENTS.md` | `~/.claude/skills/codesop/` + `~/.claude/commands/` (sub-commands only) | SessionStart hook in settings.json |
| Codex | `~/.codex/AGENTS.md` | `~/.codex/commands/` | — |
| OpenCode | `~/.config/opencode/AGENTS.md` | — | — |

The CLI is symlinked to `~/.local/bin/codesop`.

## Key Gotchas

- `set -euo pipefail` in the entrypoint. Every pipe command that might fail needs `|| true` or `|| fallback`
- `bare return` inherits exit status of preceding command. Use `return 0` explicitly
- `git fetch` can hang. Use `_run_with_timeout()` from updates.sh instead of raw `timeout`
- `wc -l` output has leading whitespace. Pipe through `tr -d ' '` before arithmetic
- setup's `configure_hooks()` uses jq with nested schema: `{ "matcher": "", "hooks": [{ "type": "command", ... }] }`
- Hook command uses absolute path (not `~` or `$HOME`) — `sh -c` (dash) doesn't expand `~` when HOME is unset
- Entry points (`codesop`, `setup`) and `lib/updates.sh` guard HOME with `${HOME:-$(echo ~)}` for hook/IDE environments
- Product contract is already narrower than the original implementation. Keep cleaning toward the contract instead of reintroducing legacy surfaces
- `SKILL.md` is the single source of truth for `/codesop`. `setup` installs it into `~/.claude/skills/codesop/SKILL.md`
- SKILL.md §3 step 10.5 manages pipeline-to-todo: TaskList check → stale detection → initial confirmation → TaskCreate. Auto re-entry after each task completion (no per-step confirmation)
- jq `test()` can fail on null values. Always guard with `type == "string" and test(...)`
- `git stash pop` conflict is a real failure. Exit 1, don't just warn
- `config/dependencies.sh` is the managed dependency manifest (type|id|tier|patched|min_version). `lib/updates.sh` loads it at runtime for `install_managed_deps()` and `upgrade_managed_deps()`
- `_dep_installed_version()` reads plugin version from `installed_plugins.json` via jq; returns empty string if unavailable (jq missing, file missing, plugin not found)
- `upgrade_managed_deps()` gates `patched=yes` plugins on `dep_patch_compat()` — skips `claude plugin update` when installed version is already compatible with manifest min_version
- `patch_skills()` uses `dep_patch_compat()` from updates.sh to check major.minor match before applying patches
- `_run_with_timeout()` in updates.sh wraps `timeout` with macOS fallback. Use this pattern for any timed command
- `has_mcp_server()` in `lib/detection.sh` checks `~/.claude/settings.json` mcpServers for skill detection fallback
- `patch_skills()` in setup overwrites third-party skill files from `patches/superpowers/` — logic is "different from ours → overwrite, same → skip". Plugin updates will be re-patched on next `setup` run
- v9: `patch_skills()` 还同步 `_evidence-pack-schema.md` 作为 sibling 到 3 个引用 skill 目录（brainstorming/writing-plans/verification）——patched SKILL.md 用**相对引用** `_evidence-pack-schema.md`（非源仓库路径），避 v8 子文件盲区。schema 更新时所有引用点一并刷新
- `find` on non-existent directory returns exit 1; under `set -e`, always append `|| true` to `find` in command substitutions

## File References

When modifying skill content or commands, run `bash setup --host claude` to sync to all host runtimes.

## Release Checklist

每次 feat/fix 合并到 main 后，按顺序执行：

1. **VERSION** — `echo "X.Y.Z" > VERSION`，bump 对应版本号
2. **skill.json** — 更新 `"version": "X.Y.Z"` 与 VERSION 保持一致
3. **CHANGELOG.md** — 在 `[Unreleased]` 下方添加 `## [X.Y.Z] - YYYY-MM-DD` 条目（Added / Changed / Fixed）
4. **提交** — `git add VERSION skill.json CHANGELOG.md && git commit -m "chore: bump vX.Y.Z"`
5. **Tag** — `git tag vX.Y.Z && git push && git push origin vX.Y.Z`
6. **GitHub Release** — `gh release create vX.Y.Z --title "vX.Y.Z" --notes "..."`
7. **分支清理** — 删除已合并的远程分支 + `git remote prune origin`
