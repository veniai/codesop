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

5. 若图谱**可用**（`check_understand_usability` 返回 fresh_on/fresh_degraded/stale_on/stale_off，见 §3 step 7），作为项目结构认知输入。fresh_* 为可信输入；stale_* 为参考性输入（AI 须警惕结构滞后，工作台已提示更新）；absent/corrupt/unknown_head 跳过。codesop 不负责触发建图

## 3. Default Behavior

When this skill triggers:

1. Read `AGENTS.md`
2. Read `PRD.md`
3. Decide whether fresh repo facts are needed and gather them via direct git/file commands
4. Decide whether `README.md` is needed
5. Run ecosystem report:
   ```bash
   (source ~/codesop/lib/updates.sh && ROOT_DIR=~/codesop VERSION_FILE=~/codesop/VERSION check_routing_coverage) || echo "生态检查跳过: 模块不可用"
   ```
5.5. Run update notification check (shows result only when new version available):
   ```bash
   (source ~/codesop/lib/updates.sh && ROOT_DIR=~/codesop VERSION_FILE=~/codesop/VERSION check_update_notification) || true
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
   Also run git health check:
   ```bash
   (source ~/codesop/lib/detection.sh && check_git_health) || echo "Git 健康检查跳过"
   ```
   Parse the output to detect:
   - `HEALTH_SKIP=*` → skip, no warning (no-git or no-remote)
   - `ORPHAN_COUNT > 0` → add to `**注意**`: `Git 有 N 个已 merge 的孤立分支（branch list），建议清理`
   - `IS_LEFTOVER=true` → add to `**注意**`: `当前在 feat/xxx 分支，无 open PR，疑似上次任务残留`
   - `IS_LEFTOVER=unknown` → add to `**注意**`: `当前在 feat/xxx 分支，无法确认 PR 状态（gh 不可用）`
   Also run understand-anything knowledge graph usability check:
   ```bash
   (source ~/codesop/lib/detection.sh && check_understand_usability) || echo "UA 检查跳过"
   ```
   注：`check_understand_usability` 内部已加 node 兜底（无 node → `unknown_head`，不误判 corrupt）+ node 调用包 timeout（防 NFS/大文件挂起）；调用方无需再加 node/timeout 守卫
   Parse the output `UA_STATE=...` to decide graph usability (see §4.1 注意行 for per-state warning text):
   - `UA_STATE=absent` → 静默跳过（无图谱，不提示）
   - `UA_STATE=fresh_on` → 不提示（理想状态）
   - `UA_STATE=fresh_degraded` → add to `**注意**`: `图谱新鲜但有隐患（未开 auto-update 或 fingerprints 缺失，下次增量可能 FULL_UPDATE）。建议 /understand --auto-update`
   - `UA_STATE=stale_off` → add to `**注意**`: `图谱已过期（落后 HEAD）且未开自动更新。建议 /understand --auto-update`
   - `UA_STATE=stale_on` → add to `**注意**`（事实性，**严禁断言钩子未生效**——understand 用 Claude PostToolUse hook，会话外 commit 天然不触发 ≠ hook 坏了）: `图谱已过期（meta 落后 HEAD），auto-update 开启但自动更新未跟上——可能是**会话外 commit 未触发**（understand 钩子仅覆盖会话内 commit）/ 钩子未激活 / 增量失败。图谱可降级使用但须警惕滞后。建议 /understand 增量更新`（分级提示规则详见 §4.1，本处与之同源）
   - `UA_STATE=corrupt` → add to `**注意**`: `知识图谱损坏（graph/meta JSON 无效或缺关键字段），无法使用。建议重跑 /understand`
   - `UA_STATE=unknown_head` → add to `**注意**`: `非 git 仓库 / HEAD 不可读 / node 不可用，无法判断图谱新鲜度`
8. **Perform a quick document drift scan.** Ask whether current repo facts imply updates to `CLAUDE.md`, `PRD.md`, or `README.md`.
   - workflow/tooling/constraints changed → `CLAUDE.md`
   - product state/progress/decisions/scope changed → `PRD.md`
   - user-visible usage/commands/config changed → `README.md`
   Use this scan to decide whether doc updates belong in the next workflow chain.
   Run:
   ```bash
   (source ~/codesop/lib/updates.sh && PROJECT_ROOT="$(pwd)" check_project_document_drift) || echo "当前项目文档检查跳过: 模块不可用"
   ```
9. **Read the routing table** (`~/.claude/codesop-router.md` or `config/codesop-router.md`). Match the user's signal against the "什么时候用" column. Use it as a palette, then compose the matching workflow chain using the **链路组装** rules — do not stop at one skill name. When multiple skills match, prefer ★-marked skills (e.g. subagent-driven-development over other options). After assembling the chain, apply the **链路完整性** principle: check for logical gaps between adjacent skills (e.g. code-review without receiving-code-review, feedback without fix-and-verify), and fill them before outputting.
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
- 链路中每个步骤创建一个 task，subject 用指令式（有 skill 写"使用 {skill-name} Skill 做{描述}"，不含 ☆/★）
- metadata：skill 任务 `{source: "codesop-pipeline", skill: "skill-name"}`，衔接任务 `{source: "codesop-pipeline"}`
- 逐个顺序创建，第 N+1 个 blockedBy 第 N 个
- 衔接任务（无 skill）：从上下文推断该做什么，完成后 TaskUpdate(completed)

**衔接任务 — 创建分支**：
- 新功能链路且当前在 main/master 时，在 writing-plans 后、开发前插入
- 用户说"用 worktree"时改为 worktree
- 完成后 TaskUpdate(completed)

**衔接任务 — Git 残留清理**：
- 条件：git 健康检查检测到 ORPHAN_COUNT > 0 或 IS_LEFTOVER=true
- 插入位置：pipeline 最前面（在创建分支之前）
- 执行时：先检查工作区是否干净，然后 git checkout $MAIN_BRANCH（使用检测到的默认分支名） → git pull → 删除已 merge 的 feat/*/fix/*/chore/* 分支（排除当前分支） → git fetch --prune
- 如果工作区脏 → 中止清理，在 **注意** 中提示

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
**更新**: codesop X → Y available. Run `codesop update` to upgrade.（仅当有新版本时输出，来自 step 5.5）
**注意**: {具体内容}（仅在异常时加此行，无异常不输出）
```

2 个必显字段（**状态** + **分支**），每行一个 bold key + inline value。摘要反映当前分支上下文。`**更新**` 和 `**注意**` 为条件字段，仅在对应信号存在时输出。

**`UA_STATE` 分级提示规则**（来自 step 7 `check_understand_usability` 检测，按状态决定是否加 `**注意**` 行）：
- `UA_STATE=absent` → 静默（无图谱，不输出注意行）
- `UA_STATE=fresh_on` → 不提示（理想状态）
- `UA_STATE=fresh_degraded` → 加 `**注意**`: 图谱新鲜但有隐患（未开 auto-update 或 fingerprints 缺失，下次增量可能 FULL_UPDATE）。建议 `/understand --auto-update`
- `UA_STATE=stale_off` → 加 `**注意**`: 图谱已过期（落后 HEAD）且未开自动更新。建议 `/understand --auto-update`
- `UA_STATE=stale_on` → 加 `**注意**`（事实性，**严禁断言钩子未生效**——understand 用 Claude PostToolUse hook，会话外 commit 天然不触发 ≠ hook 坏了）: 图谱已过期（meta 落后 HEAD），auto-update 开启但自动更新未跟上——可能是**会话外 commit 未触发**（understand 钩子仅覆盖会话内 commit）/ 钩子未激活 / 增量失败。图谱可降级使用但须警惕滞后。建议 `/understand` 增量更新
- `UA_STATE=corrupt` → 加 `**注意**`: 知识图谱损坏（graph/meta JSON 无效或缺关键字段），无法使用。建议重跑 `/understand`
- `UA_STATE=unknown_head` → 加 `**注意**`: 非 git 仓库 / HEAD 不可读 / node 不可用，无法判断图谱新鲜度

### 4.2 Skill Ecosystem

```md
## Skill 生态
- 路由覆盖：（粘贴 check_routing_coverage 输出）
```

三种结果映射："路由覆盖完整"→"✓ 路由覆盖完整"，不完整→显示原文含缺失条目，模块不可用→标注。此区块只反映 codesop 的 skill/runtime 生态，当前项目文档状态应放在 `## 工作台摘要` 中。

### 4.3 Pipeline Dashboard

Show the pipeline as a numbered list. Use **routing table's full skill names** (e.g. `superpowers:brainstorming`, not `brainstorming`). Apply **链路完整性** principle: after chain assembly, check for logical gaps between adjacent skills and insert transition tasks.

**Proposing new pipeline** — 见 §4.5 Complete Example。

**Continuing existing pipeline**:

```md
## 下一步建议
当前 Pipeline：
☑ 1. 使用 superpowers:brainstorming Skill 做需求澄清和设计
☑ 2. 使用 codex:rescue Skill 做设计审查
☑ 3. 根据审查反馈修订方案
☐ 4. 使用 superpowers:writing-plans Skill 做拆分执行计划
☐ 5. 创建 feat/ 分支
☐ 6. 使用 superpowers:subagent-driven-development Skill 做开发实施
☐ 7. 使用 code-simplifier:code-simplifier(☆) Skill 做代码润色
☐ 8. 使用 superpowers:verification-before-completion Skill 做验证
☐ 9. 使用 claude-md-management:claude-md-improver(☆) Skill 做文档审计
☐ 10. 使用 superpowers:finishing-a-development-branch Skill 做提交 PR
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

**确认句式**：`要把这个 pipeline 转成 task list 并从 {first-skill} Skill 开始做 {intent} 吗？`（上下文变化时在句首加变化原因）。

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
5. 创建 feat/ 分支
6. 使用 superpowers:subagent-driven-development Skill 做开发实施
7. 使用 code-simplifier:code-simplifier(☆) Skill 做代码润色
8. 使用 superpowers:verification-before-completion Skill 做验证
9. 使用 claude-md-management:claude-md-improver(☆) Skill 做文档审计
10. 使用 superpowers:finishing-a-development-branch Skill 做提交 PR

要把这个 pipeline 转成 task list 并从 superpowers:writing-plans Skill 开始拆分执行计划吗？
```

## 5. Completion Gate

Before the final answer on any routed implementation task:

1. identify the change types from this task (consult the change impact matrix in AGENTS.md)
2. for each document, check against its audit dimensions — no skipping or batch marking:
   - CLAUDE.md: invoke `claude-md-management` skill to audit and revise
   - PRD.md: check P1-P5 (progress/decision/scope/risk/milestone); if any triggered, update the target PRD section
   - README.md: check R1-R4 (install/run/config/interface); if any triggered, update the target README section
   - CONTEXT.md: if exists, check C1-C2 (term change/definition conflict); if any triggered, update
   - docs/adr/: if exists, check A1-A2 (new decision/existing ADR conflict); if any triggered, suggest ADR creation
3. self-check: confirm step 2 covered all documents and no dimension was skipped
4. include this exact block in the final answer:

```md
## 文档判定
☐ CLAUDE.md — 未更新：{原因}
☑ PRD.md — 已更新：{命中维度：一句话}
☐ README.md — 未更新：{原因}
☐ CONTEXT.md — 未更新：{原因}
☐ ADR — 未更新：无架构决策
```

☐/☑ 规则：☑ = 已更新（附改了什么），☐ = 未更新（附原因）。每行必须出现（条件行见下方）。

**条件行**：
- `CONTEXT.md`：仅项目存在该文件时输出，不存在时省略该行
- `ADR`：仅项目存在 `docs/adr/` 时输出，不存在时省略该行
- ADR 触发但未写：`☐ ADR — 建议写 ADR：{一句话决策内容}`
- ADR 已写：`☑ ADR — 已更新：新增 ADR-XXXX`

PRD.md 检查清单（P1-P5）：

| # | 维度 | 触发信号 | 更新目标 |
|---|------|---------|---------|
| P1 | 进度对齐 | 新的完成项/阻塞项/下一步变化 | PRD §2：移动/新增条目 |
| P2 | 决策记录 | 技术选型/范围变更/优先级调整 | PRD §3：追加决策行 |
| P3 | 范围准确 | 功能或接口增删改 | PRD §5：同步功能描述 |
| P4 | 风险更新 | 新风险/风险缓解/假设打破（低频） | PRD §6：增删改条目 |
| P5 | 里程碑 | 版本号/里程碑/阶段变化（低频） | PRD §1 + §4 |

README.md 检查清单（R1-R4）：

| # | 维度 | 触发信号 | 更新目标 |
|---|------|---------|---------|
| R1 | 安装命令 | 安装步骤/依赖变化 | 安装段落 |
| R2 | 运行命令 | dev/build/test 命令变化 | 运行段落 |
| R3 | 配置说明 | 环境变量/配置路径增减 | 配置段落 |
| R4 | 接口文档 | API/CLI 接口变化 | 接口段落 |

CONTEXT.md 检查清单（C1-C2）：

| # | 维度 | 触发信号 | 更新目标 |
|---|------|---------|---------|
| C1 | 术语变化 | 新领域术语引入，或已有术语含义变化 | 新增/更新术语定义 |
| C2 | 定义冲突 | 代码实际用法与定义矛盾 | 确认方向后更新定义或建议修正代码 |

ADR 检查清单（A1-A2）：

| # | 维度 | 触发信号 | 处理 |
|---|------|---------|------|
| A1 | 新增 ADR | 产生了架构决策（选型/边界/依赖方向/权衡） | 建议写 ADR |
| A2 | 影响现有 ADR | 与已有 ADR 矛盾或约束条件实质性变化 | 建议写新 ADR 标记 supersedes |

Notes:

- do not list `AGENTS.md` as a separate document decision target; project `AGENTS.md` should stay a thin wrapper to `CLAUDE.md`
- `CHANGELOG.md` is not part of the default document gate
- for pure refactors, test-only changes, or formatting-only changes, it is valid to mark all as "未更新" with a concrete reason
- in a worktree, PRD edits are restricted to the current branch's subsection under "并行开发记录"; global PRD changes require switching to main
- ADR suggestions are advisory; the user decides whether to write the ADR
- P4/P5 marked low-frequency: skip when change type clearly does not involve risk or milestone

## 6. Conflict Resolution

| Conflict | Rule |
|----------|------|
| superpowers:requesting-code-review vs code-review:code-review | Task-level → superpowers:requesting-code-review; PR-level → code-review:code-review |
| 处理 PR vs 发 PR | 处理已有 PR → 先查 git log 确认上下文 → superpowers:finishing-a-development-branch; 发新 PR → superpowers:finishing-a-development-branch; PR review 反馈 → receiving-code-review → finishing-a-development-branch |
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
| `/codesop uninstall` | `codesop uninstall` | Remove codesop integration (keeps installed plugins). |

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
