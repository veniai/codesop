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
9. **Read the routing table** (`~/.claude/codesop-router.md` or `config/codesop-router.md`). Match the user's signal against the "什么时候用" column. Use it as a palette, then compose the matching workflow chain using the **链路组装** rules — do not stop at one skill name. When multiple skills match, prefer ★-marked skills (e.g. subagent-driven-development over executing-plans). After assembling the chain, apply the **链路完整性** principle: check for logical gaps between adjacent skills (e.g. code-review without receiving-code-review, feedback without fix-and-verify), and fill them before outputting.
10. If step 9 produced a lead skill → read that skill's full content (invoke Skill tool), then assess fit on this scale:
   - ✅ 适合 — skill trigger matches user intent, preconditions met, process appropriate
   - ⚠️ 部分适合 — skill works but has gaps; some preconditions unmet or context partially mismatched
   - ❌ 不适合 — skill mismatch; another skill would be significantly better
   - ❓ 信息不足 — context insufficient to judge fit; skip validation, output routing table recommendation only
   The routing table defines the candidate set. Validation may only rank or reorder within that set. If no candidate fits, ask the user one focused question — do not invent chains outside the routing table.

10.5. **Check TaskList and manage task list.**
   - Call TaskList() and filter to tasks with metadata `source: codesop-pipeline` — ignore tasks created by the user or other skills
   - **Judge task list relevance**: compare existing tasks in the task list against current project context (PRD state, git state, user intent). If they no longer align, delete ALL old tasks and re-route from scratch
   - If task list is still relevant and has pending/in_progress items:
     - Output task list status view (§4.3)
     - 自动执行下一个 pending task（已确认的 task list 等于授权全程执行）
     - If adjust → re-run step 9 with new intent, propose updated task list
   - If no relevant tasks exist in the task list:
     - Propose new task list based on step 9's chain
     - Single confirmation: "要把这个 pipeline 转成 task list 并从 X Skill 开始做 Y 吗？"
     - If confirmed → create tasks per the **Pipeline TaskCreate 规范** below, then immediately execute first task
     - If rejected → adjust and re-propose

**Pipeline TaskCreate 规范**：
- 链路中每个步骤（skill 或衔接工作）创建一个 task
- subject：有 skill 写 `使用 {routing-table-skill-name} Skill 做{描述}`（指令式，明确标注 Skill 强制调用），衔接工作写 `{描述}`
  - **注意**：`{routing-table-skill-name}` 必须是纯 skill 名称（如 `code-simplifier:code-simplifier`），不含 `(☆/★)` 标记——标记只在 §4.3 dashboard 显示层使用，不能进入 task subject
- metadata：skill 任务 `{source: "codesop-pipeline", skill: "routing-table-skill-name"}`，衔接任务 `{source: "codesop-pipeline"}`（有 `skill` 键 = skill 任务，没有 = 衔接任务）
- 逐个顺序创建（不并行），第 N+1 个 `addBlockedBy` 第 N 个的 ID，保证执行顺序
- 第一个 task 创建后立即执行

**Pipeline Re-entry**: After any routed task completes:
1. TaskUpdate(taskId, status: "completed") — 标记完成
2. Call TaskList() and filter to tasks with metadata `source: codesop-pipeline`
3. Identify the next pending task (skill or transition)
4. If next is a skill task → load skill and execute. If transition task → complete the work, TaskUpdate(completed), check next again
5. Auto-proceed to execute next task. Only pause on pipeline failure, real blocker, or user interrupt.

Default to orientation and routing first. Do not jump into implementation unless the user clearly asks to proceed.

## 4. Default Output

Output MUST contain exactly these 4 sections in this order, nothing else:

1. `## 工作台摘要` — one field per line (no nested bullets)
2. `## Skill 生态` — routing coverage only
3. `## 下一步建议` — pipeline dashboard (proposed chain or current pipeline status)
4. **末行** — one natural-language workflow instruction

NEVER add `---` dividers between sections. NEVER add extra headings. NEVER change section titles.

### 4.1 Workbench Summary

```md
## 工作台摘要
**状态**: {分支名} — {一句话描述当前在干什么}
**分支**: {分支名}（{PR 状态}）
```

如果有需要关注的异常（文档漂移、阻塞/风险、重要决策），加一行：
```md
**注意**: {具体内容}
```

**规则**：
- Exactly 2 fields always shown: **状态** + **分支**
- **注意** field: only when there's something actionable. 如果文档无漂移、无阻塞、无重要决策 → 不显示。永远不输出"无"
- Each field on its own line — bold key with inline value
- 摘要必须反映当前 git 分支的上下文。在 main 分支就讲 main 的事，在 feature 分支就讲 feature 分支的事

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

Show the pipeline as a numbered list. Use **routing table's full skill names** (e.g. `superpowers:brainstorming`, not `brainstorming`). Apply **链路完整性** principle: after chain assembly, check for logical gaps between adjacent skills and insert transition tasks.

**Proposing new pipeline**:

```md
## 下一步建议
提议 Pipeline：
1. 使用 superpowers:brainstorming Skill 做需求澄清和设计
2. 使用 codex:rescue Skill 做设计审查
3. 根据审查反馈修订方案
4. 使用 superpowers:writing-plans Skill 做拆分执行计划
5. 使用 superpowers:subagent-driven-development Skill 做开发实施
6. 使用 code-simplifier:code-simplifier(☆) Skill 做代码润色
7. 使用 superpowers:verification-before-completion Skill 做验证
8. 使用 claude-md-management:claude-md-improver(☆) Skill 做文档审计
9. 使用 superpowers:finishing-a-development-branch Skill 做提交 PR
```

**Continuing existing pipeline**:

```md
## 下一步建议
当前 Pipeline：
☑ 1. 使用 superpowers:brainstorming Skill 做需求澄清和设计
☑ 2. 使用 codex:rescue Skill 做设计审查
☑ 3. 根据审查反馈修订方案
☐ 4. 使用 superpowers:writing-plans Skill 做拆分执行计划
☐ 5. 使用 superpowers:subagent-driven-development Skill 做开发实施
☐ 6. 使用 code-simplifier:code-simplifier(☆) Skill 做代码润色
☐ 7. 使用 superpowers:verification-before-completion Skill 做验证
☐ 8. 使用 claude-md-management:claude-md-improver(☆) Skill 做文档审计
☐ 9. 使用 superpowers:finishing-a-development-branch Skill 做提交 PR
```

**Format rules**:
- 使用路由表中的完整 skill 名称（如 `superpowers:brainstorming`，不是 `brainstorming`）
- Dashboard 显示行：`N. 使用 {skill-name}(☆/★) Skill 做{description}`（给用户看的输出，标记表示条件性）
- TaskCreate subject：`使用 {skill-name} Skill 做{description}`（给 AI 执行的任务标题，不含 (☆/★) 标记，skill-name 必须可直接传给 Skill tool）
- 衔接任务行：`N. {description}`（无 skill 前缀，由链路完整性原则动态产生）
- **(☆)**: 有插件时才走
- **(★)**: 必走
- **☑/☐**: 已完成/待执行（仅 continuing 格式）
- One pipeline per output

### 4.4 Final Line

首次确认或上下文变化时，末行必须是疑问句，以"吗？"结尾。用户按 Enter 即可确认。
pipeline 执行过程中（task list 已确认），不问，自动执行下一个。

**两种确认句式**：
1. **Proposing**: `要把这个 pipeline 转成 task list 并从 {first-skill} Skill 开始做 {intent} 吗？`
2. **Stale**: `检测到上下文变化（{reason}），建议新 pipeline。要转成 task list 并从 {first-skill} Skill 开始做 {intent} 吗？`

**场景适配**：
- 工作区有未提交改动：task list 前置 superpowers:finishing-a-development-branch 处理
- 重新进入 /codesop：用 ☐/☑ 格式显示当前 task list，自动继续下一个 pending task
- 检测到上下文变化：输出新的 proposed task list，末行用 stale 句式

**规则**：
- 末行是整个输出的最后一行，其后不能有任何内容
- 以"要"或"要我"开头，自然语言，不包裹反引号
- 提到具体 skill 名称以便 AI 路由

### 4.5 Complete Example

```md
## 工作台摘要
**状态**: feat/p1-graph-ui — 设计完成，准备开发
**分支**: feat/p1-graph-ui（无 open PR）
**注意**: 设计审查微调了数据流方向

## Skill 生态
- 路由覆盖：✓ 路由覆盖完整

## 下一步建议
提议 Pipeline：
1. 使用 superpowers:brainstorming Skill 做知识图谱 UI 需求澄清（设计审查已通过，此步确认最终方案）
2. 使用 codex:rescue Skill 做设计审查（已完成，跳过）
3. 根据审查反馈修订方案（已完成，方案微调了数据流方向）
4. 使用 superpowers:writing-plans Skill 做拆分执行计划
5. 使用 superpowers:subagent-driven-development Skill 做开发实施
6. 使用 code-simplifier:code-simplifier(☆) Skill 做代码润色
7. 使用 superpowers:verification-before-completion Skill 做验证
8. 使用 claude-md-management:claude-md-improver(☆) Skill 做文档审计
9. 使用 superpowers:finishing-a-development-branch Skill 做提交 PR

要把这个 pipeline 转成 task list 并从 superpowers:writing-plans Skill 开始拆分执行计划吗？
```

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
| Task hygiene: completed→completed, obsolete→deleted, no buildup | codesop |
| Load skill if 1% chance it applies | using-superpowers |
| User instruction > project rules > default behavior | instruction priority |
