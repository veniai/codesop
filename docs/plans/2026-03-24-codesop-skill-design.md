# codesop Skill Design

**Date:** 2026-03-24

## Goal

Define the `codesop` skill as the project-orientation and workflow-routing layer of the overall `codesop` system.

## Position In The System

Within the full `codesop` system:

- the skill is the orchestrator
- the CLI is the mechanical support layer
- `AGENTS.md` and `PRD.md` are the persistent memory surface
- downstream skills perform specialized execution

This skill exists to stop humans and agents from losing orientation during long-running coding work.

## Trigger Strategy

`codesop` should trigger aggressively, not conservatively.

It should trigger when the user:

- asks what to do next
- asks what skill to use
- says “continue”
- returns to an existing project after a gap
- looks confused or unstructured
- wants to summarize current status
- wants to resume or hand off work
- wants help choosing workflow before implementation

It should also trigger when the user explicitly mentions:

- `codesop`
- `/codesop`
- workflow choice
- project status
- next step
- progress summary

## Read Order

The skill should read in this order:

1. `AGENTS.md`
2. `PRD.md`
3. `README.md` only when needed

Why:

- `AGENTS.md` defines how the AI must behave
- `PRD.md` defines current project memory
- `README.md` is only needed when run/use/install information affects the current task

## Default Behavior

On trigger, the skill should:

1. announce use of `codesop`
2. read `AGENTS.md`
3. read `PRD.md`
4. decide whether `README.md` is needed
5. produce a workbench summary
6. recommend the most relevant downstream skill or next action

It should not default to implementation.

## Default Output

The default response should be a `工作台摘要`.

Required fields:

- 长期目标
- 当前阶段
- 当前进度
- 阻塞/风险
- 最近决策
- 下一步
- 推荐 skill
- 备选 skill
- 暂不建议

## Recommended Output Template

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

## Relationship To `/codesop`

The skill and the CLI should cooperate like this:

### The skill does

- context recovery
- state summarization
- workflow routing
- guardrail-aware next-step recommendation

### The CLI does

- initialization
- project detection
- project file generation
- structured diagnosis signal collection

The skill may cite CLI outputs, but it should not depend on the CLI to understand long-term project state.

## Relationship To Generated Docs

### `AGENTS.md`

The skill must respect:

- behavior boundaries
- document sync rules
- verification rules
- final output rules

### `PRD.md`

The skill should treat `PRD.md` as the main project-memory document.

It should specifically look for:

- long-term goal
- current stage
- current progress
- blockers
- recent decisions
- next step
- work log recency

### `README.md`

Only inspect when the current user request is likely to touch:

- install
- run commands
- environment variables
- API usage
- external user/operator instructions

## Routing Policy

`codesop` should route to downstream skills, not replace them.

Examples:

- unclear feature request → `office-hours`
- approved design needing implementation plan → `writing-plans`
- active implementation with existing plan → `subagent-driven-development`
- bug / broken behavior → `investigate` or `systematic-debugging`
- ready for release/review → `review`, `ship`

## Non-Goals

This skill should not:

- become a giant static encyclopedia of every workflow
- directly replace specialist skills
- overwrite `PRD.md` by default
- force file edits when the user only wants orientation

## Current Gap

The current [`SKILL.md`](/home/qb/codesop/SKILL.md) already contains useful workflow mappings and sub-command notes, but it is still organized more like a command catalog than a deliberate orientation skill.

The next rewrite should preserve the good workflow mappings while adding:

- a stronger trigger description
- the explicit read order
- the workbench-summary output
- the relationship to `AGENTS.md` and `PRD.md`
- the relationship to the existing `/codesop` v2 CLI plan

## Next Implementation Step

Rewrite [`SKILL.md`](/home/qb/codesop/SKILL.md) around this structure:

1. description: aggressive trigger conditions
2. system position: skill-first architecture
3. read order: `AGENTS.md -> PRD.md -> README.md if needed`
4. workbench summary template
5. workflow routing rules
6. sub-command notes for `/codesop init` and `/codesop status`
