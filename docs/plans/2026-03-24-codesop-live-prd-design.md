# codesop Live PRD Design

**Date:** 2026-03-24

## Goal

Upgrade the generated `PRD.md` from a static product spec into a live working document that keeps long-term goals, current progress, recent decisions, blockers, and step-by-step work history in one stable structure.

## Context

The current `write_prd_template()` output in [`codesop`](/home/qb/codesop/codesop) is a traditional static PRD:

- version history
- current specification
- roadmap, entities, use cases, architecture

That works for requirement capture, but it does not solve the operational problem this project now needs to solve:

- humans and agents forget the long-term goal
- humans and agents lose track of current progress
- work expands into long, messy sessions without a stable external memory
- `AGENTS.md` can define rules, but it cannot carry the current project state by itself

The new PRD must therefore support both:

1. Product source of truth
2. Flowing project memory

## Scope

This design covers:

- the final generated structure of `PRD.md`
- shared PRD update rules that can be reused in `AGENTS.md`
- how `PRD.md` relates to `AGENTS.md` and `/codesop`
- testable expectations for generated content

This design does not cover:

- `/codesop` runtime diagnosis changes
- automatic parsing of PRD state by the v2 diagnosis engine
- README redesign

## Core Decision

Use a `dual-zone PRD`:

- `stable zone`: low-frequency, overwrite-in-place sections for mission, scope, features, roadmap, entities, use cases, architecture, standards
- `flow zone`: high-frequency, append-or-refresh sections for current snapshot, progress board, recent decisions, risks, and work log

This is the simplest structure that preserves professional PRD discipline while also acting as external working memory.

## Why This Structure

### Option A: Keep static PRD and add a small log appendix

Pros:

- minimal changes
- easy migration

Cons:

- current state is still hard to find
- the log will drift away from the actual spec
- agents will still miss the most important short-term context

### Option B: Dual-zone PRD

Pros:

- clear separation between stable and flowing information
- easy for both humans and AI to scan
- preserves PRD professionalism
- supports recurring updates without turning the whole file into a diary

Cons:

- requires a more opinionated template
- requires explicit update rules

### Option C: Replace PRD with a pure work log

Pros:

- very easy to update

Cons:

- loses spec quality
- makes product definition unstable
- not suitable as the project source of truth

## Recommendation

Choose Option B.

This matches the actual need: `PRD.md` should remain the product master document, but it must also become the current-memory document that prevents drift during long AI-assisted development sessions.

## Final PRD Structure

### 0. How To Use This PRD

State that the file has two roles:

- current product specification
- current work memory

Also define the editing rule:

- stable sections are updated in place
- flowing sections are appended or refreshed as work progresses

### 1. Current Snapshot

Fast 30-second scan for humans and agents.

Fields:

- current stage
- current goal
- long-term goal
- current milestone
- completion estimate
- next step
- execution owner
- last update reason

### 2. Progress Board

Short-lived task state.

Sections:

- in progress
- next up
- blocked
- done recently

This section should stay compact and reflect only active state.

### 3. Recent Decisions

A short decision ledger for decisions that still affect ongoing work.

Columns:

- date
- decision
- why
- impact

Keep only the recent active decisions here. Older major decisions remain represented in version history or current specification.

### 4. Version History

Keep the existing semantics:

- newest first
- why it changed
- what changed

This remains the historical release/change ledger, not the daily work log.

### 5. Current Specification

Keep the current static PRD body, slightly reorganized:

- mission
- persona
- scope
- core features
- roadmap
- entities
- use cases
- optional ASCII UI prototype
- architecture blueprint
- implementation standards

This section continues to represent the current truth of the product.

### 6. Risks and Assumptions

Add a compact place for:

- current risks
- current assumptions

This makes project uncertainty visible and avoids burying risk notes inside logs.

### 7. Work Log

Append-only short operational history in reverse chronological order.

Each entry should include:

- timestamp
- title
- context
- action
- result
- impact
- next step

This is the main flowing history and should be concise, factual, and incremental.

### 8. Optional Extensions

Retain optional DI and anti-corruption guidance from the current template.

## Shared PRD Update Rules

These rules should be reusable both:

- in generated `AGENTS.md`
- in the future `codesop` skill instructions

### Must update `PRD.md`

Update when any of the following happens:

- requirement scope changes
- core business rules or use cases change
- milestone, roadmap, or acceptance criteria change
- project stage changes
- a meaningful implementation step finishes
- a blocker appears or is resolved
- a decision meaningfully changes architecture, process, or scope

### Usually update the stable zone

Update sections in `Current Specification` when:

- the product definition changes
- the roadmap changes
- entities or use cases change
- standards or architecture expectations change

### Usually update the flow zone

Update `Current Snapshot`, `Progress Board`, `Recent Decisions`, `Risks and Assumptions`, and `Work Log` when:

- work advances
- work pauses
- the next step changes
- blockers appear or disappear
- important tradeoffs are made

### May skip update

PRD can usually remain unchanged for:

- pure refactors with no behavior change
- test-only changes
- comment-only edits
- mechanical formatting work

If not updated, the final handoff should still explicitly state why.

## Relationship Between Files

### `AGENTS.md`

Defines:

- rules
- boundaries
- required checks
- output format

It answers: `How should the AI work here?`

### `PRD.md`

Defines:

- what the project is
- why it exists
- what state it is currently in
- what was recently decided
- what is next

It answers: `What are we building, where are we now, and what changed recently?`

### `/codesop`

Should eventually read these documents as inputs to diagnosis and recommendations, but that is a later integration step. This design only upgrades the generated baseline documents.

## Template Writing Constraints

The generated template should:

- remain concise enough to scan
- avoid duplicating `AGENTS.md` behavior rules
- default to Chinese, matching current `codesop init`
- preserve ASCII-safe structure
- work for general project types, not just web apps

## Test Expectations

`tests/codesop-init.sh` should verify that generated `PRD.md` contains at least:

- `## 0. 使用说明`
- `## 1. 当前快照`
- `## 2. 当前进度`
- `## 3. 最近决策记录`
- `## 4. 版本历史`
- `## 5. 产品核心规范`
- `## 6. 当前风险与假设`
- `## 7. 工作日志`

`tests/codesop-init.sh` should also verify that generated `AGENTS.md` includes shared PRD update rules that refer to:

- stable spec updates
- flow zone updates
- skip conditions

## Implementation Notes

The smallest implementation is:

1. replace the heredoc inside `write_prd_template()`
2. extend `write_agents_template()` with reusable PRD update rules
3. update init tests to lock in the new structure
4. update docs that describe generated files so they say `PRD.md` is a live document

This is enough to establish the foundation before any diagnosis-engine integration.
