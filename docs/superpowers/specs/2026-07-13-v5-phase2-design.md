# codesop v5 Phase 2：minimal 走通 + 判定可测化 + SessionStart 瘦身

**日期**：2026-07-13
**状态**：Draft，待 spec-gate
**定位**：在 Phase 1（adapter 解耦 + router 文案层 profile）之上，把 profile 判定做成可测映射，让 minimal 真正走轻路径，并把 SessionStart 常驻内容压到 kernel。
**与前版关系**：实现 `2026-07-11-v5-profile-decouple.md`（r3，已采纳）的 §8 Phase 2。继承其设计原则与非目标，不重议架构。

## 1. 决策摘要

| 维度 | 决策 | 一句话理由 |
|------|------|-----------|
| 判定可测化 | `lib/profile.sh` 表驱动 `judge_profile()` + router 文案两源一致 | router 文案 AI 读判不可测；函数给场景测试做断言锚点、给审计做 floor 验证器 |
| floor 保证 | best-effort（文案约束 + 审计验证器），无机械硬拦截 | profile-decouple §5 已砍 PEP/deny hook，硬保证不在 v5 范围 |
| dogfood | 退化为**行为契约测试**（fixture + 输出契约断言） | spec §8 R8 要求"可重复"；真跑 AI 不可重复、不可判定 |
| minimal 改造 | SKILL.md §3/§4 加 profile 分支 | 执行层目前是 v4 固定 pipeline，profile 判定无落点 |
| SessionStart | router card 拆 kernel（常驻 ≤30 行）+ full router（按需） | 现在 96 行全注入，minimal 任务不需完整 router |

## 2. 要解决的问题（Phase 1 退出条件核对后的缺口）

profile-decouple spec §8 把"profile 判定 + floor 场景测试"划进 Phase 1，但 Phase 1 提交（`ff99b57`）实际只完成：
- adapter 解耦（`lib/adapter/claude.sh` + `patch-health-check.sh`）
- core grep 守卫（`tests/grep-guard.sh`：detection/commands 无 Claude 路径词）
- router card 文案层 profile（分档表 + floor 不可降 + 审计 jsonl 文案）

**未完成的 Phase 1 退出条件**：
1. **profile 判定无可测逻辑**——router card 只有文案表，detection.sh 无判定函数，SKILL.md 对 `profile/minimal/floor` 零命中（执行层未改造）。
2. **floor 场景测试不存在**——spec §8 要求"floor 不能被 Agent 降档（场景测试）"，`tests/` 零命中，run_all 20 项无此项。

Phase 2 把这两项纳入（判定表 + floor 场景测试本质是同一物），并完成 minimal 行为改造 + SessionStart 瘦身 + dogfood。

## 3. 第一性原理推导

1. **profile 判定可测化的本质** = `(intent, risk, ambiguity, blast) → profile` 映射要确定可断言。markdown 文案 AI 读判每次可能不同，不可测。
2. **floor 不可降不可能有机械硬保证**——profile-decouple §5 明确砍了 PEP/deny hook。floor 是 best-effort 工作流契约，强模型理论上可绕。所以"可测"只能分两层：
   - 测**映射自洽**（场景表：给定输入→profile 对不对）
   - 测**AI 真实行为**（dogfood：profile→输出契约对不对）
3. 因此 `judge_profile()` **主要服务测试与审计验证，不服务运行时**——运行时 AI 仍读 router 文案判（bash 函数不会被 skill 执行时同步调用）。函数的价值是：场景测试可断言 + dogfood 后审计可验证（AI 声明 profile ≥ `judge_profile(声明输入)`）。
4. **对比类比**：类比会照搬"加个 hook 拦 Agent 降档"——但 spec 已明确不自造执行点，那条路被砍。推导结论是"文案 + 审计验证器"的 best-effort，与类比分歧在"放弃机械硬保证"，这是 spec 有意取舍。

## 4. Profile 判定表

```text
intent     = explore | change | debug | review | ship
risk       = low | medium | high
ambiguity  = low | high
blast      = local | cross-module | external
profile    = minimal | standard | governed
```

**硬规则（优先级从高到低，命中即定，不再看后续）**：

| # | 条件 | profile | 说明 |
|---|------|---------|------|
| H1 | risk=high ∨ blast=external ∨ 含鉴权/数据迁移/部署/公共接口/破坏性 | governed | 高风险 override，无视其他输入；单文件鉴权也 governed |
| H2 | ambiguity=high ∨ blast=cross-module | standard（或 governed，若 H1 命中） | 高歧义/跨模块不进 minimal |
| H3 | 缺任一输入（unknown） | 默认升档（不判 minimal） | 缺信息不降档 |
| H4 | risk=low ∧ ambiguity=low ∧ blast=local ∧ intent∈{explore,change,debug} ∧ 可回滚 | minimal | 仅此进入 minimal |

`review`/`ship` intent 不进 minimal（需复核/提交仪式）。

## 5. 功能需求（每条三件）

### R1. 判定表 + 函数（含 floor 场景测试）

- **完成条件**：
  - `lib/profile.sh` 提供 `judge_profile(intent,risk,ambiguity,blast)→profile`，表驱动（规则数据与函数分离，便于场景测试枚举）。
  - `tests/profile-routing.sh` ≥12 场景全过，覆盖：高风险误入 minimal=0；单文件鉴权必 governed；单文件数据迁移必 governed；局部文案/低风险配置必 minimal；ambiguity=high 不进 minimal；blast=cross-module 不进 minimal；缺任一输入不判 minimal（升档）；intent=review/ship 不进 minimal。
  - router card 文案与函数硬规则两源一致：`tests/profile-routing.sh` 含一致性校验——H1 触发关键字集合 {鉴权, 数据迁移, 部署, 公共接口, 破坏性} 在 `judge_profile` 函数 case 分支与 router card H1 文本中**均出现**（集合包含断言，可判定 pass/fail，非模糊"不矛盾"）。
  - 注册进 `run_all.sh`。
- **边界**：不得通过删场景/放宽 H1 硬规则来满足通过率；H1（鉴权/迁移/部署/公共接口/破坏性→governed）不可被其他输入降级；场景数不得低于 12；函数不得在运行时被声称为"已强制执行 floor"（它是验证器不是执行点）。
- **风险分级**：high。改变所有任务的路由判定，误判会让高风险任务走轻路径。

### R2. minimal 行为改造（SKILL.md 执行层）

- **完成条件**：
  - `SKILL.md` §3/§4 加 profile 分支：`minimal` 跳过任务对齐块（理解+阶段+Skill）、固定四段输出、spec-gate、HTML serve，只做"执行 + diff/测试验证 + 简短结论"；`standard`/`governed` 保留既有仪式。
  - `tests/minimal-behavior.sh` 用 minimal fixture（局部文案改动）断言输出不含"任务对齐块/spec-gate/## 工作台摘要 固定四段/HTML serve"标记；用 governed fixture（鉴权改动）断言输出仍含 spec-gate + 人审请求。
  - 注册进 `run_all.sh`。
- **边界**：minimal 仍必须有与变更相称的新鲜验证证据（diff/测试/lint），不得以 minimal 为由跳过验证；不得删 standard/governed 的任何仪式；minimal 的"简短结论"不得退化为无证据的"已完成"声明。
- **风险分级**：high。直接改 `/codesop` 默认行为契约与铁律。

### R3. dogfood 行为契约测试

- **完成条件**：
  - `tests/profile-dogfood.sh` 提供 6 fixture（minimal/standard/governed 各 2），每个 = 固定任务描述 + 期望 profile + **预录期望输出样本**（人工预先写定的该 profile 下 codesop 应产出文本，非真跑 AI）+ 输出契约断言（对期望样本断言）：
    - minimal fixture：输出不含 spec-gate/HTML/任务对齐块；含 diff/测试验证证据标记。
    - governed fixture（鉴权 + 数据迁移各 1）：输出含"请求批准 + 证据 + 回滚"；不得自动过。
    - standard fixture（跨模块 + 高歧义各 1）：输出含"阶段末独立复核"。
  - 每个 fixture 执行后写一行审计 `$XDG_STATE_HOME/codesop/audit.jsonl`（回退 `~/.local/state/codesop/`），字段 `intent/risk/profile/floor_reason/evidence/approver/ts`；测试校验记录存在且字段齐。
  - floor 验证器：测试对每 fixture 调 `judge_profile(声明输入)`，断言 fixture 期望 profile ≥ 函数输出（Agent 不得低于 floor）。
  - 注册进 `run_all.sh`。
- **边界**：dogfood 不得退化为只查 Prompt 字样（必须校验输出契约实质内容）；governed 的"请求批准"不得降级为自动过；每档 fixture ≥2 不得减；审计路径不得写 `~/.claude/`（中立路径原则）。
- **风险分级**：high。定义三档行为契约，误判会固化错误仪式。

### R4. SessionStart 瘦身（router card 拆分）

- **完成条件**：
  - `config/codesop-router.md` 拆为两段：**kernel**（七类不变量 + floor 语义 + profile 判定入口，≤30 行，常驻注入）+ **full router**（skill 总表 + 链路组装 + 调试/审查路径，按需读取）。
  - **七类不变量定义**（本 spec 内联，作 R4 grep 校验关键字唯一源——profile-decouple §3 只提名字未枚举，故在此收口）：① 用户优先级（用户指令/明确授权优先）② 任务范围（只改任务相关内容）③ 安全（不硬编码/泄露凭据）④ 失败披露（冲突/失败/不确定显式报告）⑤ 根因（bug 修复需根因证据）⑥ 验证证据（完成声明需新鲜验证证据）⑦ 高风险升级人（不可逆/外部影响操作升人审）。**kernel 结构预算**：七类 ≈14 行 + floor 语义 ≈3 行 + 判定入口 ≈4 行 + markdown 结构 ≈5 行 ≈26 行（≤30 可行）。
  - `setup` 默认只注入 kernel 到 SessionStart；full router 留在 `~/.claude/codesop-router.md` 供 SKILL.md 按需读。
  - `tests/sessionstart-trim.sh` 断言：注入内容 ≤30 行；含七类不变量关键字 grep 校验（七类关键词 {用户优先级, 任务范围, 凭据, 失败, 根因, 验证, 升级} 在 kernel 中各至少命中一次）；含 floor/profile 判定入口；full router 文件仍在且完整。
  - `SKILL.md` 指向 full router 读取路径。
  - 注册进 `run_all.sh`。
- **边界**：kernel 不得漏七类不变量任一类（以本 spec §5 R4 内联七类为 grep 校验源，不引用未枚举的外部文档）；不得以瘦身为由删 floor 语义或判定入口；full router 内容不得丢（skill 总表 + 链路组装完整保留）；瘦身不得改变 floor 语义本身。
- **风险分级**：high。改每次会话常驻 context，影响所有项目。

## 6. 非目标

- 不自造 PEP/deny hook（继承 profile-decouple §5）——floor 是 best-effort，硬保证不在范围。
- 不建评测平台 / shadow mode / 规则退役（继承 profile-decouple §10）。
- dogfood 不真跑 AI agent——用行为契约 fixture（可重复可判定）。
- 不改 Phase 1 已落地的 adapter / grep 守卫 / router 文案结构（只在文案层补判定入口一致性）。
- 不第一阶段迁出 bash。
- 不取消 governed 人审。

## 7. 迁移与入口

**入口条件**：Phase 1 已落地部分（adapter + grep 守卫 + router 文案 profile）保持可用；本 spec 把 Phase 1 欠的判定可测化 + floor 测试纳入，不要求 Phase 1 单独补。

**实施顺序**（建议，非硬性）：R1（判定表+函数+场景测试）→ R4（SessionStart 瘦身，依赖判定入口）→ R2（minimal 行为改造）→ R3（dogfood，依赖 R1/R2 契约）。R1 是其他三项的地基。

**退出条件**（spec §8 Phase 2 可判定形式）：R1-R4 全部完成条件满足；run_all 全过（含 4 个新测试）；v4 现有 20 测试不回归；SessionStart 注入 ≤30 行且路由正确（fixture 验证）。

## 8. 验证策略

- **合同测试**：profile 判定表映射自洽（H1-H4 优先级 + 覆盖率）；SessionStart kernel 尺寸 + 不变量关键字；router 文案 ↔ 函数两源一致。
- **行为测试**：minimal fixture 不产仪式；governed fixture 真请求批准 + 证据 + 回滚；standard fixture 阶段末复核；审计 jsonl 写入。
- **回归**：v4 现有 20 套测试全过；grep 守卫不破（core 仍无 Claude 路径词）。

## 9. 风险与缓解

| 风险 | 缓解 |
|------|------|
| 判定函数不参与运行时，floor 实际仍靠 AI 自律 | 审计验证器 + dogfood 抽检 + 文案强约束；明示 best-effort 不假装机械保证 |
| minimal 改造让 AI 借口跳过验证 | R2 边界硬性要求 minimal 必须有新鲜验证证据；dogfood 校验 |
| dogfood 退化为字样检查，不校验实质 | R3 边界要求校验输出契约实质内容（不只是 grep Prompt 字样） |
| SessionStart 瘦身漏不变量 | R4 边界七类不变量 grep 校验 + ≤30 行尺寸门 |
| router 文案与函数规则漂移 | R1 含两源一致性校验测试 |

## 10. Domain Language Delta

- **判定表（Profile Decision Table）**：`(intent,risk,ambiguity,blast)→profile` 的确定映射，含硬规则优先级 H1-H4。避免称"AI 自由裁量"。
- **floor 验证器（Floor Verifier）**：`judge_profile()` 在审计/dogfood 中校验 AI 声明 profile 不低于判定 floor 的角色。**非运行时执行点**。
- **行为契约测试（Behavior Contract Test）**：dogfood 的可重复形态——固定 fixture + 期望 profile + 输出契约断言，区别于"真跑 AI"。

## 11. 待 spec-gate 判定

1. 是否接受判定函数"主要服务测试/审计、不服务运行时"的定位（floor 无机械硬保证）。
2. 是否接受 dogfood 退化为行为契约测试（可重复可判定，但不真跑 AI）。
3. 是否接受把 Phase 1 欠的判定可测化 + floor 测试并入 Phase 2（不要求 Phase 1 单独补）。

> Q4（七类不变量定义源）已在 §5 R4 内联枚举收口，不再悬而未决。
