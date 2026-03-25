# codesop Dependency Governance Design

**Date:** 2026-03-24

## Goal

Define how `codesop` should manage dependency drift across:

- host environments
- `superpowers`
- `gstack`
- path and format assumptions

The purpose of this design is not just “check installed or not”. It is to make `codesop` resilient as its upstream ecosystem changes.

## Problem

Today, `codesop` already knows how to answer:

- is `superpowers` installed?
- is `gstack` installed?
- which host is present?

But that is only the first layer.

The real operational risks are:

- upstream skills rename or disappear
- frontmatter or description format changes
- host paths change
- update flows drift
- CLI assumptions remain stale while installs still “exist”

This means `installed != compatible`.

## Core Decision

Treat dependency management as three separate checks:

1. `presence`
2. `compatibility`
3. `freshness`

This is the governance model `codesop` should eventually follow.

## Dependency Classes

### Class A: Hard structural dependencies

These are required for `codesop` to behave as designed:

- host ability to load `AGENTS.md`
- host ability to load `SKILL.md`
- local `codesop` install paths

If these fail, `codesop` is not operational.

### Class B: Functional ecosystem dependencies

These are not required for the repo to exist, but are required for the intended workflow graph:

- `superpowers`
- `gstack`

If these fail, `codesop` still exists, but routes into a degraded or incomplete ecosystem.

### Class C: Semantic dependencies

These are the most fragile and easiest to overlook:

- specific skill names existing
- frontmatter fields existing
- multiline `description` remaining parseable
- workflow assumptions still matching upstream behavior

If these fail, the system may appear installed while silently degrading.

## Governance Model

### 1. Presence check

Already mostly implemented.

Examples:

- host path exists
- gstack path or binary exists
- superpowers path exists

### 2. Compatibility check

Not yet implemented as a first-class feature.

Should answer:

- can `codesop` still find the expected skill directories?
- can it still parse key metadata?
- do the expected skill names still exist?
- does the current host still map to the assumed install paths?

### 3. Freshness check

Partially implemented in wording, not yet in governance.

Should answer:

- is `codesop` itself outdated?
- is `gstack` outdated?
- is `superpowers` outdated?
- if something updated, did the update invalidate any assumptions?

## Current Dependency Assumptions

The current system assumes:

- `superpowers` and `gstack` remain discoverable from known host paths
- key downstream skill names remain stable
- skill metadata continues to expose a usable `description`
- host install locations remain recognizable

These assumptions are reasonable, but they are currently implicit.

## What Should Be Tracked Explicitly

`codesop` should eventually track:

- supported hosts
- expected host paths
- expected ecosystem paths
- required downstream skill names
- metadata fields relied upon
- current known-good versions if available

This does not need to be a full package manager. It only needs to be enough to detect drift early.

## Minimal Governance Artifact

The smallest useful next artifact would be one manifest file, for example:

- `docs/codesop-dependency-manifest.md`
or
- `dependencies/manifest.yaml`

Minimum contents:

- hosts supported
- paths expected
- ecosystems expected
- skill names expected
- metadata assumptions expected
- last manually validated date

## Recommended Checks For A Future `doctor` Mode

If `codesop doctor` or an expanded `codesop status` is added later, it should check:

- host detection
- AGENTS/skill path validity
- `superpowers` presence
- `gstack` presence
- required skill names exist
- descriptions are parseable
- local caches are not obviously stale
- `codesop` repo itself is current

## Update Semantics

### `codesop update`

Should remain focused on updating `codesop` itself.

But after update, it should eventually also surface:

- ecosystem compatibility warnings
- host path mismatch warnings
- parser assumption warnings

### Ecosystem updates

`superpowers` and `gstack` updates should not be treated as simple install actions.

They should be treated as:

- potential compatibility events

Meaning:

- after update, re-check assumptions
- do not assume success just because install/update command succeeded

## Real-Usage Governance Loop

The most important governance signal is still real use.

For every real issue found, classify it as one of:

- host-path issue
- host-trigger issue
- ecosystem-presence issue
- ecosystem-update issue
- semantic-parser issue
- workflow-mapping issue

This classification will keep feedback actionable.

## Immediate Next Step

Before building a full governance command, do these first:

1. start real usage feedback logging
2. validate all three hosts against the same prompt set
3. record which dependency assumptions break first
4. then decide whether to build `doctor` or enhance `status`

## Decision

Do not overbuild dependency management yet.

First:

- use the system for real
- log host-specific and ecosystem-specific failures
- turn repeated failures into explicit checks

That is the correct “边用边补” strategy for this phase.
