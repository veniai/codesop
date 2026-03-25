# codesop Skill-CLI Integration Design

**Date:** 2026-03-24

## Goal

Define the contract between:

- the `codesop` skill
- the `/codesop` CLI diagnosis layer

so they work as one system instead of two adjacent features.

## Problem

The current state is improved but still incomplete:

- the skill knows it should produce a `工作台摘要`
- the CLI can now produce project diagnosis and recommendation context
- but there is no explicit rule for when the skill should call the CLI
- and no explicit mapping from CLI output into the workbench summary fields

Without this contract:

- the skill may ignore useful CLI output
- the CLI may drift into user-facing reasoning it should not own
- the same project state may be derived in two inconsistent ways

## Core Decision

The `codesop` skill remains primary.

The CLI is an optional but preferred mechanical context source.

That means:

- the skill should still be able to work from `AGENTS.md` + `PRD.md` alone
- but when shell-verifiable project state matters, the skill should prefer `/codesop` output over re-deriving facts informally

## Integration Model

### Layer order

1. `AGENTS.md`
2. `PRD.md`
3. `/codesop` CLI output when project-state facts are needed
4. `README.md` only when run/use/install details matter

This preserves the approved read priority while adding the CLI as a mechanical supplement, not a replacement for document memory.

## When The Skill Should Call `/codesop`

The skill should call `/codesop` when:

- the user asks for current status
- the user asks what to do next in an active repo
- the user says “continue”
- the skill needs fresh Git / config / health facts
- the skill suspects `PRD.md` may be stale relative to the repo

The skill usually does **not** need to call `/codesop` when:

- the user only asks about policy or workflow choice in the abstract
- the user is discussing process, not a concrete repo state
- the repository is unavailable or the task is purely conceptual

## CLI Output Role

`/codesop` should not try to produce the final user-facing workbench summary.

Its role is to provide:

- stable facts
- stable stage guess
- stable recommendation context

The skill then turns that into:

- long-term orientation
- current narrative
- next-step guidance
- downstream skill routing

## Mapping CLI Output To Workbench Summary

### Direct CLI-derived fields

These can come directly from `/codesop`:

- 当前阶段
- 置信度
- Git 状态
- 健康问题
- 配置状态

### Document-derived fields

These should still come primarily from `PRD.md`:

- 长期目标
- 当前进度
- 最近决策
- 阻塞/风险
- 下一步

### Merged fields

These require interpretation:

- 阻塞/风险
  - combine PRD blockers with CLI health issues
- 下一步
  - combine PRD next step with CLI stage/health realities
- Skill 建议
  - combine PRD state, CLI context, and skill routing rules

## Preferred Workbench Synthesis Algorithm

When `codesop` skill triggers in an active repo:

1. Read `AGENTS.md`
2. Read `PRD.md`
3. Run `/codesop` if fresh mechanical state is needed
4. Build workbench summary using:
   - PRD for long-term and narrative state
   - CLI for fresh repo facts
5. Explain any mismatch between PRD and CLI state
6. Recommend the next downstream skill

## Mismatch Handling

One important integration feature is mismatch reporting.

Examples:

- PRD says planning, but CLI suggests active feature implementation
- PRD says blockers cleared, but CLI shows missing plan or missing PRD
- PRD next step says implement, but CLI shows broken repo health

When mismatch exists, the skill should say so explicitly:

```md
注意：PRD 记录的当前状态和仓库现状不完全一致。
- PRD: ...
- CLI: ...
建议先同步 PRD，再继续执行。
```

This is one of the main reasons the CLI exists: it keeps the workbench honest.

## Output Contract For `/codesop`

The current human-readable output is acceptable for v1 integration, but the skill benefits from more stable sections.

Preferred section structure:

```md
## 项目诊断

**当前阶段**: ...
**置信度**: ...

**健康状态**:
- Git: ...
- 问题: ...

## 技能推荐
...
```

This is enough for the skill to quote or interpret reliably.

Longer term, a machine-stable mode may help:

- `codesop --format keyvalue`
- or `codesop --format json`

But that is not required for the current phase.

## What Stays In The Skill

The following must remain in `SKILL.md`, not CLI logic:

- aggressive trigger rules
- read order
- workbench summary template
- workflow routing policy
- “暂不建议” reasoning
- PRD/README sync judgment

## What Stays In The CLI

The following must remain in shell:

- Git status collection
- config-file presence detection
- package/toolchain detection
- stage heuristics
- recommendation context emission
- pure-facts `status`

## Immediate Next Step

After this design, the next implementation step should be:

1. update `SKILL.md` to explicitly say when to call `/codesop`
2. refine `/codesop` output wording so it is easier for the skill to consume
3. add 2-3 eval prompts for the integrated skill behavior

This should happen before expanding CLI diagnosis depth further.
