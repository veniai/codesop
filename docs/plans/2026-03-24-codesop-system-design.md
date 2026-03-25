# codesop System Design

**Date:** 2026-03-24

## Goal

Define `codesop` as a single coherent system instead of a loose collection of:

- a CLI
- a skill
- generated project documents
- workflow recommendations

This design makes explicit what each layer is responsible for, how they interact, and where the existing `/codesop` v2 diagnosis plan fits.

## Problem

The project is already moving in the right direction, but the architecture is still implicit.

Today, `codesop` is doing several things at once:

- mapping user scenarios to workflows in [`SKILL.md`](/home/qb/codesop/SKILL.md)
- generating project-level operating documents in [`codesop`](/home/qb/codesop/codesop)
- evolving a diagnosis/recommendation CLI in [2026-03-24-codesop-v2-implementation-plan.md](/home/qb/codesop/docs/plans/2026-03-24-codesop-v2-implementation-plan.md)
- evolving `PRD.md` into a live work-memory document in [2026-03-24-codesop-live-prd-design.md](/home/qb/codesop/docs/plans/2026-03-24-codesop-live-prd-design.md)

All of these are compatible, but without a top-level system definition they look like parallel efforts instead of one intentional product.

## Core Decision

`codesop` is a `skill-oriented operating system for AI-assisted coding work`.

It has four layers:

1. `codesop skill`
2. `codesop CLI`
3. generated project documents
4. downstream workflow skills

The most important decision is:

`The skill is the orchestrator. The CLI is infrastructure.`

This means `codesop` is not “just a CLI tool with a skill wrapper”, and it is not “just a skill that happens to shell out sometimes”. It is a skill-first system with a CLI support layer.

## System Layers

### 1. `codesop` skill

This is the primary user-facing intelligence layer.

It should:

- trigger proactively when the user seems lost, is resuming work, is switching tasks, needs a status summary, or asks what to do next
- read project context in the correct order
- summarize current project state
- recommend the next workflow or skill
- tell the user what not to do yet

It should not:

- be the source of truth for project state
- directly hardcode project-specific facts
- replace the generated docs

### 2. `codesop` CLI

This is the mechanical layer.

It should:

- initialize project operating documents
- inspect project state using shell-verifiable signals
- output structured diagnosis context
- support host-independent mechanical steps

It should not:

- become the full reasoning engine
- depend on hidden conversation context
- replace the skill’s judgment layer

### 3. Generated project documents

These are persistent memory and boundary documents generated or maintained by `codesop`.

They are:

- `AGENTS.md` — project-level behavior boundaries
- `PRD.md` — live product spec + flowing work memory
- `README.md` — external usage and runbook information
- `CLAUDE.md` — wrapper that imports `AGENTS.md`

These documents are the long-lived memory surface that allows the skill to recover project context reliably.

### 4. Downstream workflow skills

These are the execution tools `codesop` routes into:

- `office-hours`
- `writing-plans`
- `investigate`
- `subagent-driven-development`
- `review`
- `ship`
- and others already mapped in [`SKILL.md`](/home/qb/codesop/SKILL.md)

`codesop` should not duplicate them. It should route into them.

## Responsibility Split

### Skill responsibilities

The `codesop` skill is responsible for:

- deciding when to engage
- reading context in the correct priority order
- restoring project orientation
- summarizing state
- suggesting next steps
- recommending the right downstream skill

### CLI responsibilities

The `codesop` CLI is responsible for:

- deterministic detection
- deterministic generation
- deterministic diagnosis input collection
- deterministic structured output

### Document responsibilities

#### `AGENTS.md`

Answers:

- what rules apply
- how the AI must work
- what must be checked before delivery

#### `PRD.md`

Answers:

- what we are building
- why it exists
- what stage we are in
- what changed recently
- what is blocked
- what comes next

#### `README.md`

Answers:

- how to run or use the project
- what changed for operators or users

## Read Priority

Approved read priority for the skill:

1. `AGENTS.md`
2. `PRD.md`
3. `README.md` only when needed

This is important.

The skill should first calibrate behavior boundaries, then restore project state, then pull operational usage details only when relevant.

## Trigger Model

Approved trigger model:

- `aggressive / proactive trigger`

`codesop` should trigger not only when explicitly named, but also when the user shows any of these patterns:

- “I don’t know what to do next”
- “continue”
- “where are we”
- “what should I use”
- “help me start this”
- resuming after a gap
- switching from planning to implementation
- switching from implementation to review
- asking for a project status summary

This is consistent with the actual user problem: drift, forgetting, context loss, and workflow confusion.

## Default Output

Approved default output:

- `workbench summary`, not a short card
- not execution-first

Default structure:

```md
## 工作台摘要

**长期目标**: ...
**当前阶段**: ...
**当前进度**: ...
**阻塞/风险**: ...
**最近决策**: ...
**下一步**: ...

## Skill 建议
- 推荐: ...
  - 原因: ...
- 备选: ...
  - 原因: ...
- 暂不建议: ...
  - 原因: ...
```

This output is intentionally operational. It should help the user recover orientation before any deeper planning or execution.

## Relationship To The Existing `/codesop` v2 Plan

The existing [2026-03-24-codesop-v2-implementation-plan.md](/home/qb/codesop/docs/plans/2026-03-24-codesop-v2-implementation-plan.md) remains valid, but its scope must be interpreted correctly.

It is:

- a CLI-layer implementation plan
- specifically for diagnosis signal collection and recommendation context generation

It is not:

- the full `codesop` system plan
- the full skill design
- the full document-memory design

So the correct hierarchy is:

1. `codesop system design` — this document
2. `live PRD design` — document-memory layer
3. `/codesop v2 implementation plan` — CLI diagnosis layer

This resolves the earlier ambiguity. The v2 plan is part of the system, not the whole system.

## Recommended Skill Behavior

When `codesop` triggers, it should:

1. announce that it is using `codesop`
2. inspect `AGENTS.md`
3. inspect `PRD.md`
4. inspect `README.md` only if the current task touches run/use/install behavior
5. produce the workbench summary
6. recommend a downstream skill or next action
7. avoid implementation unless the user clearly wants to proceed

## Non-Goals

For now, `codesop` should not:

- automatically edit `PRD.md` every time it triggers
- replace downstream execution skills
- become a generic universal project memory engine outside software work
- require the CLI to access conversation history

## Next Design Step

After this document, the next artifact should be a focused `codesop skill design` that defines:

- exact trigger description
- read order
- output template
- when to update `PRD.md`
- when to inspect `README.md`
- how to map workbench state into downstream skills

That design can then drive a concrete rewrite of [`SKILL.md`](/home/qb/codesop/SKILL.md).
