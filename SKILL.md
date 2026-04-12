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

When fresh mechanical facts are needed (version, plugin status, document drift), run CLI subcommands directly via Bash — e.g. `~/.local/bin/codesop update`, or source individual `lib/*.sh` modules. **Never invoke `/codesop` from within this skill** — that would recurse into itself.

Use `PRD.md` for long-term orientation and direct git/file commands for mechanical facts.

## 3. Default Behavior

When this skill triggers:

1. Read `AGENTS.md`
2. Read `PRD.md`
3. Decide whether fresh repo facts are needed and gather them via direct git/file commands
4. Decide whether `README.md` is needed
5. Run ecosystem report:
   ```bash
   (source ~/codesop/lib/output.sh && source ~/codesop/lib/updates.sh && ROOT_DIR=~/codesop VERSION_FILE=~/codesop/VERSION check_routing_coverage) || echo "生态检查跳过: 模块不可用"
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
   Run:
   ```bash
   (source ~/codesop/lib/updates.sh && PROJECT_ROOT="$(pwd)" check_project_document_drift) || echo "当前项目文档检查跳过: 模块不可用"
   ```
9. **Read the routing table** (`~/.claude/codesop-router.md` or `config/codesop-router.md`). Match the user's signal against the "什么时候用" column. Use it as a palette, then compose the matching workflow chain using the **链路组装** rules — do not stop at one skill name. When multiple skills match, prefer ★-marked skills (e.g. subagent-driven-development over executing-plans).
10. If step 9 produced a lead skill → read that skill's full content (invoke Skill tool), then assess fit on this scale:
   - ✅ 适合 — skill trigger matches user intent, preconditions met, process appropriate
   - ⚠️ 部分适合 — skill works but has gaps; some preconditions unmet or context partially mismatched
   - ❌ 不适合 — skill mismatch; another skill would be significantly better
   - ❓ 信息不足 — context insufficient to judge fit; skip validation, output routing table recommendation only
   The routing table defines the candidate set. Validation may only rank or reorder within that set. If no candidate fits, ask the user one focused question — do not invent chains outside the routing table.

10.5. **Check TaskList and manage pipeline.**
   - Call TaskList() and filter to tasks with metadata `source: codesop-pipeline` — ignore tasks created by the user or other skills
   - Detect stale pipeline: branch switched, worktree dirty/clean flipped, new open PR appeared, or user intent shifted since pipeline was created
   - If stale detected → mark old pipeline tasks deleted, re-run step 9, propose new pipeline
   - If pipeline tasks exist with pending/in_progress items (and not stale):
     - Mark skills that have been executed as ☑ (advisory, based on conversation history)
     - Output pipeline status view
     - Single confirmation: "要继续当前 pipeline，从 X 开始做 Y 吗？"
     - If continue → skip TaskCreate, proceed to execute next skill
     - If adjust → re-run step 9 with new intent, propose updated pipeline
   - If no pipeline tasks or all completed:
     - Propose new pipeline based on step 9's chain
     - Single confirmation: "要创建这个 pipeline 并从 X 开始做 Y 吗？"
     - If confirmed → call TaskCreate for each skill with metadata `{source: "codesop-pipeline"}`, then immediately execute first skill
     - If rejected → adjust and re-propose

**Pipeline Re-entry**: After any routed skill completes execution:
1. Call TaskList() and filter to tasks with metadata `source: codesop-pipeline`
2. Mark the just-completed skill as ☑ (advisory)
3. Identify the next pending skill in the pipeline
4. Ask the user: "Pipeline 中下一步是 {next-skill}，要继续吗？"
This is a soft reminder, not a hard gate.

Default to orientation and routing first. Do not jump into implementation unless the user clearly asks to proceed.

## 4. Default Output

Output MUST contain exactly these 4 sections in this order, nothing else:

1. `## 工作台摘要` — two-line inline format (no nested bullets)
2. `## Skill 生态` — routing coverage only
3. `## 下一步建议` — pipeline dashboard (proposed chain or current pipeline status)
4. **末行** — one natural-language workflow instruction

NEVER add `---` dividers between sections. NEVER add extra headings. NEVER change section titles.

### 4.1 Workbench Summary

```md
## 工作台摘要
**长期目标**: ...
**当前阶段**: ...
**当前进度**: ...
**当前分支**: ...
**文档状态**: ...
**阻塞/风险**: ...
**最近决策**: ...
```

Each field on its own line — bold key with inline value. NEVER expand into nested bullet lists, indented items, or multi-line field values. NEVER cram multiple fields onto one line.

摘要必须反映当前 git 分支的上下文。在 main 分支就讲 main 的事，在 feature 分支就讲 feature 分支的事。不要混入其他分支的已完成工作或无关信息。

### 4.2 Skill Ecosystem (放在 Skill 建议之前)

```md
## Skill 生态
- 路由覆盖：（粘贴 check_routing_coverage 输出）
  - "路由覆盖完整"→ "✓ 路由覆盖完整"
  - 不完整 → 显示原文（含缺失条目列表）
  - 模块不可用 → "路由覆盖：模块不可用"
```

这个区块只反映 codesop 的 skill/runtime 生态，不用于判断当前项目文档是否健康。当前项目文档状态应放在 `## 工作台摘要` 中。

### 4.3 Pipeline Dashboard

Show the recommended chain as a pipeline with progress markers. Format depends on whether tasks already exist:

**Proposing new pipeline** (no old tasks or all completed):

```md
## 下一步建议
提议 Pipeline：
brainstorming → codex:rescue → writing-plans → subagent-driven-development → code-simplifier(☆) → verification → claude-md-management(☆) → finishing
```

**Continuing existing pipeline** (has pending tasks):

```md
## 下一步建议
当前 Pipeline：
☑ brainstorming — 需求澄清和设计
☑ codex:rescue — 设计审查
☐ writing-plans — 拆分执行计划
☐ subagent-driven-development — 开发实施
☐ code-simplifier(☆) — 代码润色
☐ verification — 验证
☐ claude-md-management(☆) — 文档审计
☐ finishing — 提交 PR
```

**Format rules**:
- **(☆)**: Skill only runs when the plugin is installed (from routing table chain assembly)
- **(★)**: Skill always runs (★ from routing table)
- **☑/☐**: Visual progress indicator — mark completed skills ☑ based on conversation history (advisory)
- One pipeline per output — if user rejects, adjust and re-propose a single pipeline
- Each line: `skill-name — one-line description`
- If stale pipeline detected (branch switch, git state change, open PR appeared, intent shift): show new proposed pipeline instead of continuing old one

### 4.4 Final Line — Question-Style Workflow Instruction

The very last line of the output MUST be a single question-style workflow instruction ending with "吗？". The user presses Enter to confirm.

Single confirmation shapes (create pipeline + start execution in one step):

1. **Proposing new pipeline**: `要创建这个 pipeline 并从 {first-skill} 开始做 {intent} 吗？`
2. **Continuing existing pipeline**: `要继续当前 pipeline，从 {next-skill} 开始做 {intent} 吗？`
3. **Stale pipeline detected**: `检测到上下文变化（{reason}），建议新 pipeline。要创建并从 {first-skill} 开始做 {intent} 吗？`

Rules:

- The final line must be the last non-empty line in the whole response
- Output exactly one question on that line, ending with "吗？"
- The final line may mention 1 to 3 skills in sequence when the work naturally chains
- Use natural language; slash commands are optional, not required
- Start with "要" or "要我" — direct, conversational tone
- Keep the line short enough to work as a gray next-step suggestion
- Mention concrete skill names so the model can route itself correctly
- Do not wrap the final line in backticks
- Do not add bullets, labels, or prefixes before it
- Do not output any text after the final workflow instruction
- **Chain composition**: When composing a multi-skill chain, apply the routing table's 链路组装 rules — insert code-simplifier after development, claude-md-management after verification, codex:rescue after design. Do not copy skill sequences from the examples below; they demonstrate output format only

Examples:

Case A — Dirty worktree, no existing pipeline

```md
## 工作台摘要
**长期目标**: ...
**当前阶段**: ...
**当前进度**: ...
**当前分支**: main（无 open PR）
**文档状态**: 代码已变更但 PRD.md/README.md 未动，建议同步
**阻塞/风险**: 工作区仍有未暂存改动，需要先归拢边界
**最近决策**: ...

## Skill 生态
- 路由覆盖：...

## 下一步建议
提议 Pipeline：
finishing-a-development-branch → claude-md-management(☆) → brainstorming → codex:rescue → writing-plans → subagent-driven-development → code-simplifier(☆) → verification → claude-md-management(☆) → finishing

要创建这个 pipeline 并从 finishing-a-development-branch 处理未提交改动开始吗？
```

Case B — Clean worktree, no existing pipeline

```md
## 工作台摘要
**长期目标**: ...
**当前阶段**: ...
**当前进度**: ...
**当前分支**: feat/p1-graph-ui（无 open PR）
**文档状态**: 未见漂移信号
**阻塞/风险**: 无
**最近决策**: ...

## Skill 生态
- 路由覆盖：...

## 下一步建议
提议 Pipeline：
brainstorming → codex:rescue → writing-plans → subagent-driven-development → code-simplifier(☆) → verification → claude-md-management(☆) → finishing

要创建这个 pipeline 并从 brainstorming 做 Data 页面知识图谱 UI 的需求澄清开始吗？
```

Case C — Re-entering /codesop with existing pipeline

```md
## 工作台摘要
...

## Skill 生态
- 路由覆盖：...

## 下一步建议
当前 Pipeline：
☑ brainstorming — 需求澄清和设计
☑ codex:rescue — 设计审查
☐ writing-plans — 拆分执行计划
☐ subagent-driven-development — 开发实施
☐ code-simplifier(☆) — 代码润色
☐ verification — 验证
☐ claude-md-management(☆) — 文档审计
☐ finishing — 提交 PR

要继续当前 pipeline，从 writing-plans 开始拆分执行计划吗？
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
2. if any document needs updates, invoke `claude-md-management` skill to audit and revise
3. include this exact block in the final answer:

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
- in a worktree, PRD edits are restricted to the current branch's subsection under "并行开发记录"; global PRD changes require switching to main

## 6. Conflict Resolution

| Conflict | Rule |
|----------|------|
| superpowers:requesting-code-review vs code-review:code-review | Task-level → superpowers:requesting-code-review; PR-level → code-review:code-review |
| 处理 PR vs 发 PR | 处理已有 PR → 先查 git log 确认上下文 → superpowers:finishing-a-development-branch; 发新 PR → superpowers:finishing-a-development-branch |
| Open PR vs PRD 下一步 | Open PR 存在时，PR 审查/合并是推荐链路；PRD 下一步是备选。未完成的工作优先于未来规划 |
| User says "just fix it" vs skill workflow | User instruction wins, but still obey verification and delivery rules from `AGENTS.md` |

## 7. Fallback

When no scenario matches:

1. Produce the workbench summary anyway
2. Scan routing table entries for the closest match
3. Check whether document drift should be part of the next move
4. Recommend the least-risk next step
5. If still unclear, ask one focused question

## 8. Sub-commands

| Command | Run | What it does |
|---------|-----|-------------|
| `/codesop init [path]` | `codesop init <dir>` | Generate AGENTS.md (`@CLAUDE.md`), PRD.md (活文档), README.md (if missing). Defaults to 中文. |
| `/codesop update` | `codesop update` | Check plugin versions → show status → resync host integration. |

## 9. Iron Laws

| Iron Law | Source |
|----------|--------|
| No code without design approval | brainstorming |
| No production code without failing test first | TDD |
| No fix without root cause investigation | systematic-debugging |
| No completion claim without verification evidence | verification-before-completion |
| Load skill if 1% chance it applies | using-superpowers |
| User instruction > project rules > default behavior | instruction priority |
