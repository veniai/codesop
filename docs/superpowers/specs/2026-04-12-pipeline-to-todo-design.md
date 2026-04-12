# Pipeline-to-Todo Design Spec

**Date**: 2026-04-12
**Status**: Draft
**Version**: 1.0
**Scope**: SKILL.md only — no CLI or downstream skill changes

## Problem

The routing table defines chain assembly rules (dev→simplifier→verification→claude-md→finishing), but AI frequently remembers only the first skill and skips subsequent steps. The chain assembly rules are text instructions the AI reads but does not persistently track.

## Solution

Convert the recommended skill chain into Claude Code's TaskCreate task items. The task list serves as a visual reminder — not a state machine — so the AI sees pending steps and is nudged to complete them.

## Design Decisions

| Decision | Choice | Reason |
|----------|--------|--------|
| Task lifecycle | Visual tracking only, no strict completion enforcement | No completion callback exists; strict state management creates circular dependency (forgetting chain = forgetting to update tasks) |
| Trigger point | Every /codesop invocation, smart judgment | User naturally calls /codesop to check status or change direction |
| User confirmation | Required before creating/updating tasks | Task list is a suggestion, not a command; user always has veto |
| Chain mutation | Handled at pipeline dashboard level, no separate mechanism | User's intent to change direction is naturally expressed when calling /codesop |
| Downstream skill participation | None in v1 | Would require modifying every skill; same circular dependency problem |
| Modified section | §4.3 (下一步建议) replaced with pipeline dashboard | User's intent: replace the skill recommendation, not add a new section |

## Flow

### New Flow (with pipeline-to-todo)

```
/codesop
  → §3 steps 1-8 (unchanged: read docs, ecosystem, git, drift)
  → step 9: read routing table + assemble chain
  → step 10: validate fit
  → step 10.5 (NEW): check TaskList
      → has old tasks?
          → yes: show pipeline state, ask continue or update
          → no: propose new pipeline, ask user confirm
      → user confirms → TaskCreate for each skill in chain
      → user rejects → adjust and re-propose
  → §4 output (pipeline dashboard + final line question)
  → user presses Enter → execute first skill
```

### Step 10.5 Logic

```
tasks = TaskList()
if tasks has pending or in_progress items:
    output pipeline status with ☐/☑ markers
    final line: "继续当前 pipeline 从 X 开始？还是需要调整？"
    if user says adjust → re-route (step 9) with new intent
    if user says continue → skip TaskCreate, proceed
else:
    output proposed pipeline
    final line: "要创建这个 pipeline 并从 X 开始做 Y 吗？"
    if user confirms → TaskCreate for each skill in chain
    if user rejects → adjust and re-propose
```

## Output Format Change

### §4.3 Before

```md
## 下一步建议
- 推荐链路：{chain}. 理由：{why}
- 备选链路：{chain}. 理由：{why}
```

### §4.3 After — First invocation (no old tasks)

```md
## 下一步建议
提议 Pipeline：
brainstorming → codex:rescue → writing-plans → subagent-driven-development → code-simplifier(☆) → verification → claude-md-management(☆) → finishing

要创建这个 pipeline 并从 brainstorming 开始做 X 的需求澄清吗？
```

### §4.3 After — Subsequent invocation (has old tasks)

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

继续当前 pipeline，从 writing-plans 开始拆分执行计划吗？还是需要调整？
```

### Format Rules

1. **(☆) marker**: Skills that only run when the plugin is installed (from routing table chain assembly rules)
2. **(★) marker**: Skills that always run (★ from routing table)
3. **☑/☐ markers**: Visual progress indicator — AI is instructed to mark completed skills as ☑, but this is advisory not enforced
4. **One pipeline per output**: No "备选链路" anymore — the pipeline IS the recommendation. If the user rejects, adjust and re-propose a single pipeline.
5. **Task description**: Each line shows `skill-name — one-line description` for readability

## SKILL.md Changes

### §3 — Add step 10.5

After step 10 (fit validation), before §4 output:

```md
10.5. **Check TaskList and manage pipeline.**
    - Call TaskList() to check for existing tasks
    - If tasks exist with pending/in_progress items:
      - Mark skills that have been executed as ☑ (advisory, based on conversation history)
      - Output pipeline status view
      - Ask user: continue current pipeline or adjust?
      - If continue → skip to §4 output
      - If adjust → re-run step 9 with new intent, then propose updated pipeline
    - If no tasks or all completed:
      - Propose new pipeline based on step 9's chain
      - Ask user to confirm
      - If confirmed → call TaskCreate for each skill in the recommended chain
      - If rejected → adjust and re-propose
```

### §4.3 — Replace recommendation format

Remove the old "推荐链路/备选链路" two-line format. Replace with pipeline dashboard format described above.

### §4.4 — Update final line rules

Add two final-line shapes:

1. **Proposing new pipeline**: `要创建这个 pipeline 并从 {first-skill} 开始做 {intent} 吗？`
2. **Continuing existing pipeline**: `继续当前 pipeline，从 {next-skill} 开始做 {intent} 吗？还是需要调整？`

Remove the old "简单" vs "chain" shape distinction — the pipeline dashboard always shows the chain, so the final line always references it.

### §4 structure — Remains 4 sections

1. `## 工作台摘要` — unchanged
2. `## Skill 生态` — unchanged
3. `## 下一步建议` — changed to pipeline dashboard (this section absorbs the chain visualization + user confirmation)
4. **末行** — updated shapes as above

## What Does NOT Change

- §3 steps 1-8: Unchanged (read docs, ecosystem, git, drift scan)
- §4.1 Workbench summary: Unchanged
- §4.2 Skill ecosystem: Unchanged
- §5 Completion gate: Unchanged
- §6 Conflict resolution: Unchanged
- CLI: No changes
- Downstream skills: No changes
- Routing table (config/codesop-router.md): No changes
- Chain assembly rules: No changes — routing table remains the single source of truth

## Limitations (v1)

1. **No enforcement**: Task completion marking is advisory. If AI forgets the chain, it may also forget to check the task list.
2. **No downstream skill integration**: Skills like brainstorming don't know about the task list. They don't self-mark as completed.
3. **Session-scoped**: TaskCreate tasks live in the current session. New conversation = new pipeline.
4. **Manual ☐→☑**: The AI decides which tasks to mark ☑ based on conversation history. No automatic tracking.

## Success Criteria

1. User calls /codesop → sees proposed pipeline → confirms → tasks appear in task list
2. User calls /codesop again → sees current pipeline state with ☐/☑ markers → chooses continue or adjust
3. AI executes first skill → remembers to check task list for next pending skill
4. (☆) marked skills are skipped when the plugin is not installed, and the pipeline reflects this
