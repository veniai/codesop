# codesop Host Compatibility Matrix

**Date:** 2026-03-24

## Goal

Make `codesop` host compatibility explicit and maintainable across:

- Claude Code
- Codex
- OpenCode / OpenClaw

This document is not a feature spec. It is an operational compatibility reference for real-world use and debugging.

## Why This Exists

`codesop` is intentionally cross-host, but the hosts are not identical.

They differ in:

- where `AGENTS.md` is loaded from
- where skills are installed
- how ecosystem dependencies are installed
- how update commands are expressed
- how likely the host is to naturally continue from CLI output

Without a compatibility matrix, these assumptions remain buried in shell code and user memory.

## Compatibility Policy

`codesop` should maintain:

- one shared system design
- one shared `SKILL.md`
- one shared CLI
- host-specific install/update guidance only where required

This means the default rule is:

- `shared behavior first`
- `host-specific adaptation second`

## Host Matrix

| Host | AGENTS Path | Skill Path | Ecosystem Paths Checked | Current Install Strategy | Current Update Strategy | Current Status |
|------|-------------|------------|--------------------------|--------------------------|-------------------------|----------------|
| Claude Code | `~/.claude/CLAUDE.md` | `~/.claude/skills/codesop/SKILL.md` | `~/.claude/plugins/superpowers`, `~/.claude/skills/superpowers`, `~/.claude/skills/gstack` | symlink / generated install flow | `/plugin update superpowers`, `/gstack-upgrade` | Best supported |
| Codex | `~/.codex/AGENTS.md` | `~/.codex/skills/codesop/SKILL.md` | `~/.codex/superpowers`, `~/.codex/skills/.system`, `~/.codex/skills/gstack` | symlink / generated install flow | re-run official superpowers install doc, `/gstack-upgrade` | Supported, needs more real-world validation |
| OpenCode / OpenClaw | `~/.config/opencode/AGENTS.md` or equivalent OpenClaw path | `~/.agents/skills/codesop/SKILL.md` | `~/.config/opencode/plugins/superpowers`, `~/.agents/skills/superpowers`, `~/.agents/skills/gstack` | symlink / generated install flow | re-run official superpowers install doc, `/gstack-upgrade` | Supported, least validated |

## Current Strengths

### Shared strengths

Across all hosts, `codesop` already has:

- shared `SKILL.md`
- shared `codesop` CLI
- shared `AGENTS.md` / `PRD.md` generation logic
- host-specific install suggestion logic in `codesop init`
- host-specific ecosystem detection in `scripts/detect-environment.sh`

### Claude Code

This is currently the strongest path because:

- plugin-style install flow is explicit
- local skill paths are already part of the main development loop
- gstack and superpowers assumptions have been exercised the most

### Codex

Codex is partly supported because:

- install paths are already recognized
- `AGENTS.md` and skill placement are already handled
- superpowers install/update guidance exists

But it still needs stronger validation for:

- real trigger behavior
- real skill continuation from `/codesop` CLI output
- dependency path assumptions

### OpenCode / OpenClaw

This path is present in install and detection logic, but currently has the least empirical validation.

Treat it as:

- implemented
- not yet operationally hardened

## Known Gaps

### 1. Skill discovery path asymmetry

`scripts/recommend.sh` currently prefers:

- `codesop` from the local repo
- gstack skills from `~/.claude/skills/gstack`

This is acceptable for current development, but not truly host-neutral.

Future improvement:

- resolve gstack skill paths based on detected host
- or scan a host-aware ordered path list

### 2. Trigger behavior is host-dependent

Even with one `SKILL.md`, actual trigger quality may differ between hosts.

This must be validated through real usage feedback, not just static design confidence.

### 3. CLI → skill continuation behavior is host-dependent

The current architecture assumes:

- the CLI provides structured diagnosis context
- the host AI can interpret or continue from that context

This assumption is stronger in some hosts than others.

### 4. Update mechanism consistency is weak

`codesop update` updates the `codesop` repo itself.

It does **not** yet verify:

- whether `superpowers` changed its format or install path
- whether `gstack` changed skill names or descriptions
- whether a host changed how it loads `AGENTS.md` or `SKILL.md`

## Operational Guidance

### Recommended host priority for real usage

Use in this order:

1. Claude Code
2. Codex
3. OpenCode / OpenClaw

This is not a product preference statement. It is a confidence ordering based on current validation depth.

### During feedback collection

Every real usage note should record:

- host
- task type
- whether `codesop` triggered appropriately
- whether `/codesop` CLI output helped
- whether routing felt correct
- whether any install/update/path assumptions were wrong

## Feedback Template

Use this structure for host-specific feedback:

```md
### <date> - <host> - <scenario>
- Trigger quality: good / weak / over-triggered / missed
- CLI usefulness: good / neutral / poor
- Routing quality: correct / acceptable / wrong
- Dependency issue: none / superpowers / gstack / host path / other
- Notes: ...
```

## Next Compatibility Work

The next practical improvements should be:

1. host-aware skill discovery in `recommend.sh`
2. a compatibility/doctor command or mode
3. a small real-usage feedback log
4. explicit validation of all three hosts with the same eval prompts

## Decision

For now:

- keep one shared system
- treat host differences as compatibility overlays
- validate in production-like use before adding more abstraction
