# codesop init Design

**Date:** 2026-03-23

## Goal

Refine `/codesop init` so it can inspect the current project, infer a practical project template, default generated content to Chinese, and detect whether the local AI coding environment already has the required tool ecosystems installed.

## Scope

This design covers:

- Project scanning for main language, project shape, and high-confidence framework hints
- Local tool detection for Claude Code, Codex, and OpenCode/OpenClaw
- Dependency ecosystem detection for `superpowers` and `gstack`
- User interaction for suggested installs, with confirmation required before execution

This design does not cover:

- Complex locale-based language selection
- Automatic dependency installation during the initial analysis phase
- Full CLI packaging for `codesop`

## Core Decisions

### 1. Default output language

`/codesop init` defaults to Chinese output and generated project-level guidance. It does not attempt to infer the user's preferred writing language from OS locale or shell environment. If the user explicitly wants English, the assistant can switch at runtime.

### 2. Project classification

`/codesop init` should classify the current repository in three passes:

- Main language
- Project shape
- High-confidence framework

The classification only needs to be precise enough to choose the right project template. It should avoid speculative inference.

### 3. Environment detection

`/codesop init` should explicitly check:

- Whether Claude Code, Codex, and OpenCode/OpenClaw footprints exist locally
- Whether `superpowers` skill directories exist
- Whether `gstack` is installed and callable

The first version should prefer reliable installed/not-installed detection over elaborate version intelligence.

### 4. Install behavior

When `superpowers` or `gstack` is missing, `/codesop init` should not install automatically. It should:

1. Explain what is missing
2. Show the recommended install command
3. Ask the user to confirm before running anything

## Proposed Flow

1. Scan the target repository
2. Summarize the detected project type
3. Detect local AI coding tools and supporting ecosystems
4. Announce that generated project guidance defaults to Chinese
5. Recommend files to generate
6. If required ecosystems are missing, show install commands and ask for confirmation
7. After confirmation, generate project-level configuration files

## Output Shape

The analysis should read like:

```text
项目识别：
- 主语言：TypeScript
- 项目形态：Web App
- 框架：Next.js

环境识别：
- 工具：Codex、Claude Code
- superpowers：未安装
- gstack：已安装

接下来将默认生成中文项目配置。
如需补齐依赖，我会先给出安装命令并等待确认。
```

## Implementation Strategy

Use a small local detection script to produce structured output. Keep `install.sh` focused on installing `codesop` itself. Update the SOP in `SKILL.md` so the assistant follows the detection-first flow consistently.
