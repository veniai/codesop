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

### 1.1 核心准则

设计 / 计划 / 代码类任务路由时，遵循四条核心准则：

1. **spec 即目标文件** —— spec 自带三件（完成条件 + 边界 + 风险分级），是可喂 `/goal` 的目标文件。plan / 代码必须满足 spec，下游产物向 spec 对齐，不允许下游反过来改 spec 口径
2. **/goal 分水岭** —— spec 立住把流程切成两半：spec 前 = 造目标（codesop pipeline + brainstorming 主导，`/goal` 替代不了），spec 后 = 跑目标（`/goal` 主导循环，codesop 退为**验证层**，输出 /goal 完成条件引用的外部锚点信号）。`/goal` 是 Claude Code v2.1.139+ 官方命令（设完成条件、每轮自评是否达标），codesop 依赖它、不另造循环。**`/goal` 是 built-in slash command，AI 不能自触发**——spec-gate 通过后 codesop 生成 exact /goal 命令交用户手动发（交接包，§8.7 A①），不假装自动启动
3. **三 human-gate 降级** —— spec-gate 是**唯一硬审**（审目标定义够不够，做重）；plan-gate **降级**（AI 自证清零后默认过，人只扫 advisory 不阻塞）；deliver-gate **风险分级**（low 自动过 / high 强制人审）。减的是人审 blocking（机器能判，纯浪费），不减人审语义偏离（防 AI 脑补 spec 没写的，机器判不了）。全程人随时可叫停
4. **完成条件引用外部锚点信号** —— /goal 完成条件是外部锚点的 AND（测试 + lint + 独立 subagent 证据包 blocking 清零 + spec-coverage 未覆盖=空），**不认 AI 自述**。至少一项 mechanical（测试 / lint），不能全靠 independent-AI。这是从「AI 自证」升级到「外部信号证」，抗古德哈特

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

   **pre-/goal preparation segment 边界**：链路组装到 **/goal handoff 为止**（brainstorming → codex:rescue → spec-gate → [optional plan → plan-gate] → [optional branch setup] → /goal handoff）。/goal handoff 后由 `/goal` 接管 dev/verify/finishing（§8.7），**不在 chain 里编排 /goal 后步骤**——/goal 后步骤（dev/verify/finishing）嵌入 `/goal` 完成条件，非 codesop pipeline。修 bug / 调试路径（§8.5）不经 spec-as-goal，直接 systematic-debugging → verification → finishing。
10. If step 9 produced a lead skill → read that skill's full content (invoke Skill tool), then assess fit on this scale:
   - ✅ 适合 — skill trigger matches user intent, preconditions met, process appropriate
   - ⚠️ 部分适合 — skill works but has gaps; some preconditions unmet or context partially mismatched
   - ❌ 不适合 — skill mismatch; another skill would be significantly better
   - ❓ 信息不足 — context insufficient to judge fit; skip validation, output routing table recommendation only
   The routing table defines the candidate set. Validation may only rank or reorder within that set. If no candidate fits, ask the user one focused question — do not invent chains outside the routing table.

**pipeline 适用边界（pre-/goal preparation segment）**：pipeline-to-todo + auto re-entry 覆盖**进入 /goal 前的准备段**——brainstorming → spec-gate（人审通过）→ [optional plan → plan-gate] → [optional branch setup] → **/goal handoff**（生成 exact /goal 命令交用户手动发，§8.7 A①）。**到 /goal handoff 停**，用户手动发 /goal 后进入 /goal 主循环，不走 pipeline auto re-entry。本节 Re-entry 另服务于 `/goal` 不可用时的降级回退（§8.5）。

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
- 顺序创建，**有依赖才 blockedBy**（第 N+1 个依赖第 N 个时 blockedBy；无依赖允许并行 task，不强制线性化）
- 衔接任务（无 skill）：从上下文推断该做什么，完成后 TaskUpdate(completed)

**衔接任务 — 创建分支**：
- 新功能链路且当前在 main/master 时，在 **pre-/goal preparation segment 内（spec-gate 通过后、/goal handoff 前）**插入（v4.0：分支创建锚点是 spec-gate，不是 writing-plans——simple 跳 plan，§8.5）
- 用户说"用 worktree"时改为 worktree
- 完成后 TaskUpdate(completed)

**衔接任务 — Git 残留清理**：
- 条件：git 健康检查检测到 ORPHAN_COUNT > 0 或 IS_LEFTOVER=true
- 插入位置：pipeline 最前面（在创建分支之前）
- 执行时：先检查工作区是否干净，然后清理已 merge 的孤立分支（按检测到的默认分支名，排除当前分支）+ git fetch --prune——AI 按状态选 git 命令，不硬编码序列
- 如果工作区脏 → 中止清理，在 **注意** 中提示

**Pipeline Re-entry**: After any routed task completes:
1. TaskUpdate(taskId, status: "completed") — 标记完成
2. Call TaskList() and filter to tasks with metadata `source: codesop-pipeline`
3. Identify the next pending task (skill or transition)
4. If next is a skill task → load skill and execute. If transition task → complete the work, TaskUpdate(completed), check next again
5. Auto-proceed to execute next task. Only pause on pipeline failure, real blocker, or user interrupt.

Default to orientation and routing first. Do not jump into implementation unless the user clearly asks to proceed.

**spec 变更重走**：spec 改了（**人主动发起**，spec-gate 之前或之后均可）→ 回到 spec 阶段重走（① spec → spec-gate → ② plan / `/goal` → ③ deliver）。不搞 spec 变更失效标记机制（常识：人改了 spec 自然让下游重做）。pipeline 已在执行 / `/goal` 已跑时若检测到 spec 变化，**停当前循环**，提示用户回 spec 阶段重走——不静默继续旧 spec。

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
## Skill 生态（条件输出——完整时简注，不完整时粘贴）
- 路由覆盖：✓ 路由覆盖完整（完整时只此 1 行，不粘贴 check_routing_coverage 原文）
```

**条件输出**：覆盖完整时只输出 1 行简注（不粘贴 check_routing_coverage 全输出，减噪）；不完整 / 模块不可用时粘贴缺失条目原文。三种映射："路由覆盖完整" → 1 行简注，不完整 → 显示原文含缺失条目，模块不可用 → 标注。此区块只反映 codesop 的 skill/runtime 生态，当前项目文档状态应放在 `## 工作台摘要` 中。

### 4.3 Pipeline Dashboard

Show the pipeline as a numbered list. Use **routing table's full skill names** (e.g. `superpowers:brainstorming`, not `brainstorming`). Apply **链路完整性** principle: after chain assembly, check for logical gaps between adjacent skills and insert transition tasks.

**Proposing new pipeline** — 见 §4.5 Complete Example。

**Continuing existing pipeline**:

```md
## 下一步建议
当前 Pipeline（pre-/goal preparation segment codesop 编排，/goal handoff 后 /goal 接管）：
── 造目标段（codesop 编排）──
☑ 1. 使用 superpowers:brainstorming Skill 做 spec（自带三件）
☑ 2. 使用 codex:rescue Skill 做设计审查
☑ 3. spec-gate 人审（rubric 五项，唯一硬审）
── 跑目标段（/goal 主导，codesop 退验证层）──
☐ 4. 创建 feat/ 分支
☐ 5. /goal 跑 spec 完成条件（dev/verify 嵌 /goal，每轮 dispatch 证据包）
☐ 6. deliver-gate（风险分级：low 自动 / high 人审）
☐ 7. 使用 superpowers:finishing-a-development-branch Skill 做提交 PR
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
pipeline pre-/goal preparation segment 执行过程中（task list 已确认），不问，自动执行下一个；**到 /goal handoff 停**（§8.7 A①），用户手动发 /goal 后不走 pipeline auto-proceed。

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
- 路由覆盖：✓ 路由覆盖完整（完整时只此 1 行简注，省略 check 原文）

## 下一步建议
提议 Pipeline（pre-/goal preparation segment / /goal 范式）：
── 造目标段（codesop 编排）──
1. 使用 superpowers:brainstorming Skill 做 spec（自带三件）
2. 使用 codex:rescue Skill 做设计审查
3. spec-gate 人审（rubric 五项）
── 跑目标段（/goal 主导）──
4. 创建 feat/ 分支
5. /goal 跑 spec 完成条件（dev/verify 嵌 /goal）
6. deliver-gate（风险分级）
7. 使用 superpowers:finishing-a-development-branch Skill 做提交 PR

要把这个 pipeline 转成 task list 并从 superpowers:brainstorming Skill 开始造 spec 吗？
```

## 5. Completion Gate

**文档判定 gate**——在 deliver-gate（§8.7 D，/goal 退出后代码风险人审）**之后**触发：代码风险过了，再判 CLAUDE.md/PRD.md/README.md 要不要更新。修 bug / 调试路径不经 /goal，直接在 verification 后触发本 gate。

Before the final answer on any routed implementation task:

1. identify the change types from this task (consult the change impact matrix in AGENTS.md)
2. for each document, check against its audit dimensions — no skipping or batch marking:
   - CLAUDE.md: invoke `claude-md-management` skill to audit and revise
   - PRD.md: check P1-P5 (progress/decision/scope/risk/milestone); if any triggered, update the target PRD section
   - README.md: check R1-R4 (install/run/config/interface); if any triggered, update the target README section
   - CONTEXT.md: if exists, check C1-C2 (term change/definition conflict); if any triggered, update
   - docs/adr/: if exists, check A1-A2 (new decision/existing ADR conflict); if any triggered, suggest ADR creation
3. include this exact block in the final answer:

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
| `/codesop init [path]` | `codesop init <dir>` | Generate AGENTS.md (`@CLAUDE.md`), PRD.md (活文档), README.md (if missing), docs/adr/ (scaffold). Defaults to 中文. |
| `/codesop update` | `codesop update` | Check plugin versions → show status → resync host integration. |
| `/codesop uninstall` | `codesop uninstall` | Remove codesop integration (keeps installed plugins). |

## 8.5 适用边界（/goal 分水岭）

| 任务复杂度 | 走法 | 人审次数 |
|-----------|------|---------|
| **simple** | spec → **spec-gate（硬审）** → `/goal`（deliver 自动过） | 1 |
| **moderate / complex** | spec → **spec-gate（硬审）** → plan（依赖拓扑编排）→ plan-gate（默认过+advisory）→ `/goal` → deliver-gate（high risk 人审） | 1 硬 + 1 可选 + 1 条件 |
| **trivial / 探索 / 调试** | 不进 spec-as-goal（直接干 / systematic-debugging） | — |

complex 多走 plan 不是流程教条，是复杂度管理——复杂任务依赖拓扑（先后 / 并行 / 风险点）若让 `/goal` 边跑边拆，AI 长链拓扑判断弱易拆错；plan 把拓扑预先理清，`/goal` 在清晰拓扑上才稳。simple 无复杂依赖，跳过 plan。复杂度阈值复用 `writing-plans-SKILL.md` 现有 complexity assessment，不另造。

**spec-gate 铁律 + rubric**：spec-gate 是**唯一不可省的人审**——审的是"目标定义够不够"。没审就 `/goal` = 放大没定义好的目标。spec-gate 审质量不只审字段齐，五项 rubric：

| # | rubric | 审什么 |
|---|--------|-------|
| 1 | **可验证性** | 每条完成条件有可执行验证命令或明确外部信号（不是"优化一下"） |
| 2 | **反例 / 边界** | 每条边界覆盖至少一条"缩减 / 钻空子"路径（防古德哈特） |
| 3 | **不可缩减边界** | 测试覆盖率不降 / 不删测试 / lint 规则数不减等硬约束，与完成条件同定义 |
| 4 | **风险分级校准** | low / high 有理由（low=纯重构 / 无 public 行为变；high=改 public / 跨模块 / 外部接口），不空分 |
| 5 | **traceability** | 每条需求→完成条件可追溯（无悬空需求 / 完成条件） |

"齐"防空字段，rubric 防空泛完成条件 / 伪机器验证 / 边界遗漏 / 风险错分。**spec 质量是 /goal 天花板，spec-gate 是天花板检查。**

**三 human-gate 降级表**：

| gate | 角色 |
|------|------|
| **spec-gate** | 唯一硬审，做重——审"完成条件 + 边界 + 风险分级是否齐 + rubric 五项" |
| **plan-gate** | 降级：AI 自证清零后默认通过；人只扫 advisory，不阻塞 re-entry |
| **deliver-gate** | 风险分级：low risk（simple / 纯重构）自动过；high risk（改 public 行为 / 跨模块 / 外部接口）强制人审 |

**注**：brainstorming 的 design approval（present design 后用户认可方向，upstream 固有）≠ spec-gate（spec 立住后质量硬审 rubric 五项）。前者轻（防做错方向），后者重（审 spec 质量）——两个阶段，不重复。

**/goal 不可用降级**：`/goal` 命令缺失 / 宿主不支持 / dispatch subagent 失败 / `/goal` 死循环（默认 10 轮未收敛）→ **回退 codesop pipeline（§3 step 10.5）**（codesop 主导逐步执行 + 三 gate 人审）**或**停止升级人，附最近一轮证据包 + 已尝试路径——**不静默改走普通执行**（普通执行无 spec 锚点，等于放飞 AI，违背分水岭命题）。

## 8.7 /goal 协同四步 + gate 流程机制

§1.1 准则 + §8.5 适用边界 + §8.5 三 gate 降级表 定义「审什么 / 降级到什么」；本节落「**流程怎么触发 / 证据包怎么出 / /goal 怎么交接退出 / 抽样怎么落**」——补机制，不重复准则。/goal 协同是 **SKILL 文本指示**（codesop SKILL 告诉 AI 怎么**交接** /goal——生成 exact 命令交用户手动发、每轮 dispatch 证据包、退出接 deliver-gate），不是 hook（§8.6 不做表已声明：外部锚点信号已够，hook 是死规则不抗钻空子）。

### A. /goal 协同四步（spec-gate 通过 → deliver-gate）

| 步 | 触发 | codesop SKILL 指示 AI 做什么 | 外部锚点 |
|---|------|----------------------------|---------|
| **① 交接** | spec-gate 硬审通过（§8.5 rubric 五项过，approved） | **生成 exact /goal 命令**（condition 逐字引用 spec §完成条件的 AND 表达，按复杂度分级见 C）+ **/goal handoff packet**（spec 路径 / condition 来源 / 下一步提示 / AI 停止规则）展示给用户复制发送。**AI 不得自称已启动 /goal**——/goal 是 built-in slash command，AI 不能自触发；用户手动发后才进入 /goal 主循环。codesop pipeline 在此停（pre-/goal preparation segment 结束） | spec 文件本身 |
| **② 每轮** | /goal 自评 condition 未达标 | /goal 主循环的 Claude（执行者）改代码 → 跑测试 / lint（mechanical）→ **dispatch 独立 subagent** 出证据包（按 `_evidence-pack-schema.md`，sibling 文件，setup 同步到 runtime skill 目录；干活 AI 不写结论，独立 subagent 出证据包是古德哈特防御核心）→ 写 `.superpowers/goal-evidence/round-N.md`（N 自增）→ 评估 condition AND，未达标继续循环 | 测试 + lint + 独立 subagent 证据包 + spec-coverage 扫描 |
| **③ 退出** | condition AND 全真 → /goal 退出 | codesop SKILL 接管：读**最后一轮** `round-N.md` 证据包 → 进入 deliver-gate（按 spec 风险分级，见 D） | 最后证据包 |
| **④ 失败码** | 连续 N 轮（默认 10）未收敛 / dispatch 失败 / condition 不可评估 | **停 + 升级人**，附最近一轮证据包 + 已尝试路径——按 §8.5「/goal 不可用降级」规则处理（绝不静默放飞 AI） | 最近一轮证据包 |

**关键分工**：/goal 主循环的 Claude = 执行者；codesop skill（`_evidence-pack-schema.md` schema / dispatch 协议）= 它每轮调用的方法论。condition AND 保证正确性下限，skill 保证高效路径（§8.6 不做表「纯 /goal 不用 skill」已解释为什么不全裸跑）。

### B. spec-gate 流程（dispatch 独立 subagent，交叉检验）

spec-gate 是人审（§8.5 唯一硬审）。人审的本质是人看 spec 做了什么 + 判 rubric 够不够齐——所以派**全新独立 subagent**（交叉检验，非主 AI 自审）渲染**两层**呈现（统一 gate-visual 模板），serve 给人。

brainstorming 交付 spec + evidence pack（blockers 已清）后，codesop **自动 dispatch spec-gate**（不问用户要不要可视化——**禁止降级**为文字摘要/终端 Layer 1 输出，serve URL 是 ready 的唯一信号）：
1. **dispatch 全新独立 subagent**（codesop spec-gate 的，非主 AI，也独立于 brainstorming 阶段的 evidence-pack subagent）读 spec + evidence pack，渲染两层：
   - **Layer 1 白话摘要**（3 秒入口，优先白话可用术语）——4 块：要解决的问题 / 实际会改变什么 / 为什么这样改 / 明确不改变什么（≤5 行、**优先白话**（可用术语但避免堆砌）、**不抄 spec 原文**、subagent 重写）
   - **Layer 2 具体判定**——spec 实质呈现（功能去留地图 / 改动跨层拓扑 / 数据流）+ evidence pack（rubric 五项，§8.5）
2. **serve**：subagent 渲染 HTML（schema §8 模板，Layer 1 在前）+ 调 start-server serve server 进程（复用 brainstorming 的 server 进程，非它的 just-in-time offer 逻辑——codesop spec-gate 是强制 serve）产出 URL = **ready**
3. **人审**：人看 Layer 1（3 秒入口）+ Layer 2（方案对不对 / spec 够不够齐）——任一不过回 brainstorming 修 spec；人明确点通过 = **approved**
4. **approved → /goal handoff**（§8.7 A①，AI 生成命令交用户手动发）

**ready / approved 拆分**：serve URL 生成 = ready（可审）；人明确点通过 = approved。spec-gate task completed **只认 approved**（不认 ready——URL 生成只代表"可审"，不代表"人审通过"，防 hard gate 被 task completed 语义绕过）。没 serve → 没 URL → 没 ready → 不触发人审 → task 未完成。spec-gate 接 TaskList（§3 step 10.5）。

### C. 完成条件按复杂度分级（condition 表达式）

| 复杂度 | /goal condition（spec 写明，外部锚点 AND） |
|--------|------------------------------------------|
| **simple** | 测试全过 AND lint 零违规（spec 短，spec-coverage 无意义；至少一项 mechanical 已满足） |
| **moderate / complex** | 测试全过 AND lint 零违规 AND 独立 subagent 证据包 blocking 清零 AND spec-coverage 未覆盖 = 空 |

complexity 阈值复用 `writing-plans-SKILL.md` 现有 assessment（§8.5 已声明不另造）。**至少一项 mechanical**（测试 / lint）是硬下限，不能全靠 independent-AI（§1.1 第 4 条准则）。

### D. gate 流程（降级规则见 §8.5 三 gate 降级表）

- **plan-gate**（仅 moderate/complex 走 plan 后）：AI 自证清零 → 默认过；人扫 advisory 不阻塞（§8.5）；接 TaskList（§3 step 10.5）
- **deliver-gate**（/goal 退出 A③ 后，接 verification patch §C）：low 自动 / high 强制人审（§8.5）；high-risk codex 必复核（R9，patch §C.1），codex 不可用降级 advisory 升级人；**阻塞 re-entry 只限 high-risk**（抽样命中 low 不阻塞当前 deliver，§8.7 E）；**high-risk 强制出可视化页面（schema §8b）**——同 spec-gate 拆 ready/approved：页面生成 = ready，人点通过 = approved（**high-risk task completed 只认 approved**，防页面一生成就完成的绕过，同 §8.7 B）；**抽样命中 low 不走 ready/approved**（low 照常自动过），只生成页面作 audit-log 待清审查项（§8.7 E）

### E. 抽样人审（R10，soft 威慑）

`/goal` 范式减 blocking 不等于放飞（§8.6 不做表已声明）。**1/N 抽样**（默认 N=5）：每 N 次 deliver-gate 随机抽 1 次，**强制创建待清审查项**（人扫证据包，不只是自动过的 low risk）——**不阻塞当前 low deliver**（low 照常自动过），留 audit-log 待清下次人清审。记 `.superpowers/audit-log.md`：

```
# audit-log.md（抽样人审记录）
## YYYY-MM-DD / feat/xxx / round-3.md
- 抽中原因：第 5 次 deliver（N=5 命中）
- 人扫结论：{通过 / 打回（理由）}
```

- **先 soft**：抽中后提示人扫，人不响应 = 标 pending（不阻塞当前 deliver，但下次 deliver 前需清）
- N 可配（项目级 AGENTS.md 可覆盖，默认 5）
- 威慑式非阻断式：让 AI 知道「会被随机抽查证据包」，抗「自证清零就放过」的漂移（§5 古德哈特防御 #5 落点）

## 8.6 明确不做

codesop 在 /goal 范式下**明确不做**以下事项（相信 AI 能力 + 外部锚点信号已够，复用 superpowers 现有能力）：

| 不做 | 为什么 |
|------|--------|
| 完全无人交付（取消 deliver-gate） | spec 没覆盖的 AI 会脑补，语义锚必须留（high risk 强制人审） |
| 纯 `/goal` 不用任何 skill | 慢 / 贵 / 易跑偏（无方法论会乱试）；skill 提供"高效执行路径"，`/goal` 完成条件提供"正确性下限"，两层不替代 |
| spec 后仍把 skill 当必走步骤 | 范式转换：spec 后 skill = 验证信号（嵌入 /goal 完成条件），非指令 |
| PreToolUse hook 强制 gate / 防作假硬约束 | 外部锚点信号已够，hook 是死规则、不抗钻空子 |
| 删 brainstorming / verification | 两者在 /goal 范式下**强化**（前者造目标、后者是 /goal 完成条件核心验证器） |
| 另造 complexity assessment | 复用 writing-plans 现有 |
| spec 变更失效标记机制 | 人改 spec 自然重走（见 §3 末 spec 变更重走），不需要标记 |
| `/goal` 不可用时静默改走普通执行 | 普通执行无 spec 锚点 = 放飞 AI，违背分水岭；必须回退 pipeline 或停升级人 |

## 9. Iron Laws

**v4.0 /goal 范式铁律**：详见 §1.1 核心准则 + §8.5 适用边界 + §8.7 协同（含 spec-gate 流程 + ready-approved 拆分）。本节不再重述，避免与准则段重复。

**通用工程铁律**：

| Iron Law | Source |
|----------|--------|
| No code without design approval | brainstorming |
| No production code without failing test first | TDD |
| No fix without root cause investigation（第一性原理找根因：从基本事实/约束推根因，不照搬"类似 bug 这样修"） | systematic-debugging |
| No completion claim without verification evidence | verification-before-completion |
| Task hygiene: completed→completed, obsolete→deleted, no buildup | codesop |
| Load skill when routing table matches（命中路由表条目时加载对应 skill，可判定阈值，不靠 1% 主观） | using-superpowers |
| User instruction > project rules > default behavior | instruction priority |
