---
name: codesop
description: |
  Project workbench and workflow router for AI-assisted coding.
  Restores context from AGENTS.md and PRD.md, summarizes current state, composes the next workflow chain, and validates fit.
  Proactively invoke this skill (do NOT answer directly) when the user:
  - asks what to do next, what skill to use, or wants a status/progress summary
  - says "continue", returns to a project after a gap, or looks confused about what step comes next
  - explicitly mentions codesop, /codesop, workflow, project status, or next step
  - wants help deciding whether to plan, debug, implement, review, or ship
  - describes a new feature, bug, refactoring, or small change without specifying a workflow
  - 下一步做什么 / 继续做什么 / 看看项目状态 / 进度总结 / 不确定该怎么做 / 帮我看看 / 接着做
  Do not trigger when the user is explicitly invoking a mechanical subcommand like /codesop init or /codesop update.
  (codesop)
---

# codesop: Project Workbench and Workflow Router

Announce: "Using codesop to restore project context and route the next workflow."

## 1. System Position

`codesop` is a skill-first operating system for AI-assisted coding work.

The skill is the orchestrator. The CLI is infrastructure.

Use this skill to:

- restore project orientation
- summarize current state
- compose the next move
- route into specialized downstream skills

Do not use this skill as a replacement for specialist execution skills.

## 1.1 CLI Command Bypass

If the user is explicitly asking to run a mechanical `codesop` subcommand, do not switch into workbench-summary mode.

Treat these as command execution requests first:

- `/codesop init`
- `/codesop update`

For these requests:

- run the command
- summarize the command output faithfully
- keep interpretation minimal and local to the command result
- do not output `## 工作台摘要`
- do not output `## 下一步建议`
- do not recommend downstream workflow skills unless the user separately asks what to do next

## 2. Read Order

Read project context in this order:

1. `AGENTS.md`
2. `PRD.md`
3. `README.md` only if needed

Why:

- `AGENTS.md` defines boundaries, rules, verification, and delivery format
- `PRD.md` defines long-term goal, current progress, recent decisions, blockers, and next step
- `README.md` is only relevant when the user request touches install, run, API, env, or operator-facing usage

If `AGENTS.md` or `PRD.md` is missing, say so explicitly and continue with the best available context.

The `/codesop` CLI is an optional but preferred mechanical context source.

Call `/codesop` when you need fresh project-state facts from the repo.

Do not call `/codesop` for abstract workflow questions that do not depend on repo state.

Use `PRD.md` for long-term orientation and `/codesop` for fresh mechanical facts.

## 3. Default Behavior

When this skill triggers:

1. Read `AGENTS.md`
2. Read `PRD.md`
3. Decide whether fresh repo facts are needed and call `/codesop` if they are
4. Decide whether `README.md` is needed
5. Run dependency report:
   ```bash
   (source ~/codesop/lib/output.sh && source ~/codesop/lib/updates.sh && ROOT_DIR=~/codesop VERSION_FILE=~/codesop/VERSION check_routing_coverage) || echo "依赖检查跳过: 模块不可用"
   (source ~/codesop/lib/output.sh && source ~/codesop/lib/updates.sh && ROOT_DIR=~/codesop VERSION_FILE=~/codesop/VERSION check_document_consistency) || echo "文档一致性检查跳过: 模块不可用"
   ```
6. Produce a workbench summary (include routing coverage result under `## Skill 生态`)
7. **Verify git context before routing.** Run lightweight checks to ground the routing decision in observed facts:
   ```bash
   git branch --show-current 2>/dev/null
   git log --oneline -5 2>/dev/null
   gh pr list --state open --head "$(git branch --show-current 2>/dev/null)" 2>/dev/null || echo "无 open PR"
   git status --short 2>/dev/null | head -10
   ```
   Use the results to disambiguate the user's intent. The principle is: **when the signal could mean multiple things, observed git state breaks the tie.**
   When git status is dirty and the user did not explicitly say to ignore it, prefer a cleanup-first workflow before recommending roadmap-next work.
8. **Perform a quick document drift scan.** Ask whether current repo facts imply updates to `CLAUDE.md`, `PRD.md`, or `README.md`.
   - workflow/tooling/constraints changed → `CLAUDE.md`
   - product state/progress/decisions/scope changed → `PRD.md`
   - user-visible usage/commands/config changed → `README.md`
   Use this scan to decide whether doc updates belong in the next workflow chain.
9. **Read the routing table** (`~/.claude/codesop-router.md` or `config/codesop-router.md`). Match the user's signal against the "什么时候用" column. Use it as a palette, then compose the matching workflow chain instead of stopping at one skill name.
10. If step 9 produced a lead skill → read that skill's full content (invoke Skill tool), then assess fit on this scale:
   - ✅ 适合 — skill trigger matches user intent, preconditions met, process appropriate
   - ⚠️ 部分适合 — skill works but has gaps; some preconditions unmet or context partially mismatched
   - ❌ 不适合 — skill mismatch; another skill would be significantly better
   - ❓ 信息不足 — context insufficient to judge fit; skip validation, output routing table recommendation only
   The routing table is the sole authority. Validation is informational and can never override it.

Default to orientation and routing first. Do not jump into implementation unless the user clearly asks to proceed.

## 4. Default Output

Output sections in this order:

1. `## 工作台摘要`
2. `## Skill 生态`
3. `## 下一步建议`（只有推荐链路 + 备选链路，两行，重点写理由）
4. **最后一行**：输出一条自然语言工作流指令

### 4.1 Workbench Summary

```md
## 工作台摘要
**长期目标**: ... **当前阶段**: ... **当前进度**: ...
**当前分支**: ... **阻塞/风险**: ... **最近决策**: ...
```

注意：摘要必须反映当前 git 分支的上下文。在 main 分支就讲 main 的事，在 feature 分支就讲 feature 分支的事。不要混入其他分支的已完成工作或无关信息。

### 4.2 Skill Ecosystem (放在 Skill 建议之前)

```md
## Skill 生态
- 路由覆盖：（粘贴 check_routing_coverage 输出）
  - "路由覆盖完整"→ "✓ 路由覆盖完整"
  - 不完整 → 显示原文（含缺失条目列表）
  - 模块不可用 → "路由覆盖：模块不可用"
- 文档一致性：（粘贴 check_document_consistency 输出）
  - 全部 ✓ → 合并为一行 "✓ 文档一致"
  - 含 ⚠️ → 显示原文
  - 模块不可用 → "文档一致性：模块不可用"
```

### 4.3 Next-Step Recommendation

Only two lines:

```md
## 下一步建议
- 推荐链路：{workflow}. 理由：{why this should happen first}
- 备选链路：{workflow}. 理由：{why this is secondary}
```

If validation reveals a mismatch, adjust the recommended skill. Routing table is the final authority.

The recommendation block should explain judgment, not repeat the final action verbatim.

### 4.4 Final Line — Natural-Language Workflow Instruction

The very last line of the output MUST be a single natural-language workflow instruction the user can send by pressing Enter.

Use this shape when the next step is a chain:

```text
先用 finishing-a-development-branch 处理当前未提交改动；如果这次改动影响文档，就同步更新文档；完成后用 brainstorming 为 Data 页面 P1 知识图谱 UI 做需求澄清和设计。
```

Use this shape when the next step is simple:

```text
用 brainstorming 为 Data 页面 P1 知识图谱 UI 做需求澄清和设计，确认范围、边界和成功标准。
```

Rules:

- The final line must be the last non-empty line in the whole response
- Output exactly one workflow instruction on that line
- The final line may mention 1 to 3 skills in sequence when the work naturally chains
- Use natural language; slash commands are optional, not required
- Keep the line short enough to work as a gray next-step suggestion
- Mention concrete skill names so the model can route itself correctly
- Do not wrap the final line in backticks
- Do not add bullets, labels, or prefixes before it
- Do not add a trailing question after the final workflow instruction
- Do not output any text after the final workflow instruction

Examples:

Case A — Dirty worktree

```md
## 工作台摘要
**长期目标**: ... **当前阶段**: ... **当前进度**: ...
**当前分支**: main（无 open PR） **阻塞/风险**: 工作区仍有未暂存改动，需要先归拢边界 **最近决策**: ...

## Skill 生态
- 路由覆盖：...
- 文档一致性：...

## 下一步建议
- 推荐链路：先收尾当前改动，再同步活文档，再进入下一阶段设计。理由：当前工作区未清，直接推进 roadmap-next 会混淆边界，且文档状态已落后于代码事实。
- 备选链路：直接进入 brainstorming。理由：只有当这些改动已确认可以延后处理时才成立。

先用 finishing-a-development-branch 处理当前未提交改动；如果这次改动影响 PRD.md/README.md，就顺手更新活文档；完成后用 brainstorming 为 Data 页面 P1 知识图谱 UI 做需求澄清和设计。
```

Case B — Clean worktree

```md
## 工作台摘要
**长期目标**: ... **当前阶段**: ... **当前进度**: ...
**当前分支**: feat/p1-graph-ui（无 open PR） **阻塞/风险**: 无 **最近决策**: ...

## Skill 生态
- 路由覆盖：...
- 文档一致性：...

## 下一步建议
- 推荐链路：直接进入当前阶段的设计工作流。理由：工作区干净，且当前目标已经明确。
- 备选链路：先写计划再实施。理由：如果 scope 已经稳定，可以直接把设计拆成执行任务。

用 brainstorming 为 Data 页面 P1 知识图谱 UI 做需求澄清和设计，确认范围、边界和成功标准。
```

Intent:

- Claude Code may use the last assistant line as a gray next-step suggestion in the input box
- There is no guaranteed API for setting that suggestion directly
- Therefore `/codesop` should maximize the chance by ending with one clean natural-language workflow instruction
- When git status is dirty and the user did not explicitly say to ignore it, prefer a cleanup-first workflow on the final line

Compress for quick answers, but keep the same mental model.

## 5. Completion Gate

Before the final answer on any routed implementation task:

1. decide whether `CLAUDE.md`, `PRD.md`, and `README.md` need updates
2. if `CLAUDE.md` needs updates, invoke `claude-md-management` skill to audit and revise
3. manually check whether `PRD.md` and `README.md` need updates based on the changes made
4. include this exact block in the final answer:

```md
## 文档判定

- CLAUDE.md: 已更新 / 未更新，原因：...
- PRD.md: 已更新 / 未更新，原因：...
- README.md: 已更新 / 未更新，原因：...
```

Notes:

- do not list `AGENTS.md` as a separate document decision target; project `AGENTS.md` should stay a thin wrapper to `CLAUDE.md`
- `CHANGELOG.md` is not part of the default document gate
- for pure refactors, test-only changes, or formatting-only changes, it is valid to mark all three as "未更新" with a concrete reason

## 6. Conflict Resolution

| Conflict | Rule |
|----------|------|
| requesting-code-review vs code-review | Task-level → requesting-code-review; PR-level → code-review |
| 处理 PR vs 发 PR | 处理已有 PR → 先查 git log 确认上下文 → finishing-a-development-branch; 发新 PR → finishing-a-development-branch |
| subagent-driven-development vs executing-plans | Independent tasks → subagent (parallel); serial → executing-plans |
| User says "just fix it" vs skill workflow | User instruction wins, but still obey verification and delivery rules from `AGENTS.md` |

## 7. Fallback

When no scenario matches:

1. Produce the workbench summary anyway
2. Scan all skill descriptions if available
3. Check whether document drift should be part of the next move
4. Rank the top 3 workflow options
5. Recommend the least-risk next step
5. If still unclear, ask one focused question

## 8. Sub-commands

| Command | Run | What it does |
|---------|-----|-------------|
| `/codesop init [path]` | `bash ~/codesop/codesop init <dir>` | Generate AGENTS.md (`@CLAUDE.md`), PRD.md (活文档), README.md (if missing). Defaults to 中文. |
| `/codesop update` | `bash ~/codesop/codesop update` | Check plugin versions → show status → resync host integration. |

## 9. Iron Laws

| Iron Law | Source |
|----------|--------|
| No code without design approval | brainstorming |
| No production code without failing test first | TDD |
| No fix without root cause investigation | systematic-debugging |
| No completion claim without verification evidence | verification-before-completion |
| Load skill if 1% chance it applies | using-superpowers |
| User instruction > project rules > default behavior | instruction priority |
