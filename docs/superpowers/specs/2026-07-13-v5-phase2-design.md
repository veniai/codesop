# codesop v5 Phase 2：判定可测化 + minimal 走通 + SessionStart 瘦身

**日期**：2026-07-13（r6，codex 五审 1 表述矛盾驱动：统一 judge_profile 运行时参与表述——AI 不直接调，经 write_audit 间接调）
**状态**：Draft r6，待 spec-gate
**定位**：在 Phase 1（adapter 解耦 + router 文案层 profile）之上，把 profile 判定做成可测映射，让 minimal 走轻路径，SessionStart 常驻压到 kernel。
**与前版关系**：实现 `2026-07-11-v5-profile-decouple.md`（r3，已采纳）§8 Phase 2。

## 1. 决策摘要

| 维度 | 决策 | 一句话理由 |
|------|------|-----------|
| 可测范围 | **诚实承认 prompt 行为不可单测**；只测判定函数 + 文本结构守卫 + 审计数据结构 | codesop 核心是 SKILL.md prompt，AI 读后行为不可程序化驱动；预录样本断言/grep 都是自证（codex P0） |
| 判定函数 | `judge_profile(6 参)` 表驱动单一规则源；定位**测试 oracle + 审计 floor_reason 生成器** | 运行时 AI **不直接调**（经 write_audit 间接调算 floor）；函数给测试算期望，不伪称发现真实降档 |
| dogfood | **人工抽检，不进 CI**（对齐 §10 不真跑 AI） | 真行为只能人跑 + 看审计回溯；进 CI 的"行为契约测试"是 tautological（codex P0-1） |
| floor 保证 | best-effort（文案 + `write_audit` 审计锚），无机械硬拦截；真实降档靠 `write_audit` 的 `violation` 字段 + 人工 dogfood 回溯 | profile-decouple §5 砍了 PEP/deny hook |
| SessionStart | kernel **独立文件** ≤30 行；full router 原文件不动 | 避免 sed 拆同文件的脆弱接口（codex P1-7） |

## 2. 要解决的问题

Phase 1 提交（`ff99b57`）只完成 adapter 解耦 + grep 守卫 + router 文案层 profile。**未完成的 Phase 1 退出条件**：profile 判定无可测逻辑（detection.sh 无判定函数，SKILL.md 对 profile/minimal/floor 零命中）；floor 场景测试不存在（run_all 20 项无此项）。

Phase 2 纳入判定可测化 + floor 测试（同一物），并完成 minimal 行为改造 + SessionStart 瘦身。

**r2 新增（codex 审查驱动）**：r1 的测试设计是 tautological——对预录样本断言（生产行为错了也过）+ 关键词 grep（证明不了行为）。codesop 的 prompt 行为不可单元测，r2 把可测范围收缩到程序化部分，行为验证退为人工 dogfood。

## 3. 第一性原理推导

1. **profile 判定可测化** = `(输入)→profile` 映射确定可断言。函数表驱动给测试做 oracle。
2. **floor 不可降无机械硬保证**（profile-decouple §5 砍 PEP）。best-effort：文案约束 + 审计字段。真实降档检测靠人工 dogfood + 人看 audit.jsonl 回溯，**不靠自动 verifier**（r1 的"审计验证器"是摆设——codex P1-3）。
3. **codesop 核心是 prompt（SKILL.md），AI 读后行为不可程序化驱动**。故：
   - 可单测：判定函数（judge_profile）、文本结构（SKILL.md/router 含必要段）、审计数据结构（audit.jsonl 字段/类型）。
   - 不可单测：minimal 真跳不跳仪式、governed 真停不停——这些是 AI 读 prompt 后的行为，靠人工 dogfood。
4. **对比类比**：类比会照搬"加 hook 拦降档"——已被 spec 砍。或"预录样本行为测试"——codex 证伪（自证）。r2 诚实收缩可测范围。

## 4. 判定表（judge_profile，6 参 + 确定映射）

```text
judge_profile(intent, risk, ambiguity, blast, override, reversible) -> profile

intent     = explore | change | debug | review | ship
risk       = low | medium | high
ambiguity  = low | high
blast      = local | cross-module | external
override   = subset of {auth, migration, deploy, public_api, destructive}  # H1 触发集，空集=无
reversible = true | false
profile    = minimal | standard | governed
```

**硬规则（按求值顺序，命中即短路返回）**：

| # | 条件 | profile | floor_reason |
|---|------|---------|--------------|
| H0 | 任一输入缺失/空串/非法枚举/override 含非法成员 | governed | `input_incomplete:<字段名>` |
| H1 | override≠∅ ∨ risk=high ∨ blast=external | governed | `override:<成员>` 或 `risk:high` 或 `blast:external`（首个命中） |
| H2 | ambiguity=high ∨ blast=cross-module | standard | `ambiguity:high` 或 `blast:cross-module` |
| H3 | risk=low ∧ ambiguity=low ∧ blast=local ∧ reversible=true ∧ intent∈{explore,change,debug} ∧ override=∅ | minimal | `low_local_reversible` |
| — | 其余（如 intent=review/ship 的低风险） | standard | `default_standard` |

**确定性契约**：**H0 先于一切求值**——任何 invalid 输入直接 governed + `input_incomplete:*`，**即使同时满足 H1 条件**（如 `risk=high ∧ intent=invalid`）也走 H0，不看 H1-H3。H1 压过 H2/H3。每种合法输入组合映射唯一 profile + 唯一 floor_reason。**floor_reason 唯一性**：多字段同时非法时，H0 按 `intent→risk→ambiguity→blast→override→reversible` 固定顺序取首个非法字段名；H1 override 多成员时按 `{auth,migration,deploy,public_api,destructive}` 固定 canonical order 取首个命中成员。故同一输入唯一确定 floor_reason（审计可重复）。review/ship intent 不进 minimal（落 standard 或 governed）。

**judge_profile 定位**：**测试 oracle + 审计 floor_reason 生成器**。测试用它算期望 profile 断言映射正确；运行时经 `write_audit` 间接调用算 floor/floor_reason（AI 不直接调函数）。**不宣称自动发现真实降档**——真实降档靠 `write_audit` 的 `violation` 字段 + 人工 dogfood + 人审 audit.jsonl 回溯。

## 5. 功能需求（每条三件）

### R1. 判定函数 + 确定性测试（单一规则源）

- **完成条件**：
  - `lib/profile.sh` `judge_profile(intent,risk,ambiguity,blast,override,reversible)`，规则数据与函数分离（单一结构化规则源，函数读它）。
  - `tests/profile-routing.sh` ≥12 场景全过，逐条断言：(a) 映射正确；(b) **H0 短路**——invalid 输入（含 `risk=high ∧ intent=invalid` 这种 H1 也会命中的组合）直接 governed + `input_incomplete:*`，不触发 H1；(c) **H1 优先级**——同时命中 H1+H3(minimal 条件) → governed；(d) review/ship 不进 minimal。
  - 一致性：judge_profile 的**规则数据是单一源**，测试枚举规则数据本身的 H0-H3 表（不依赖 router card 文案）；router card 文案是人维护的呈现，测试只校验 router card 含三档名 + floor 不可降声明（结构存在），不校验规则细节一致（避免 tautological 两源校验）。
  - 注册 run_all。
- **边界**：不得删场景/放宽 H1 满足通过率；H1 override 成员（auth/migration/deploy/public_api/destructive）不可被其他输入降级；场景数≥12 不得减；H0 必须对**每种** unknown/invalid 输入（含与 H1/H2 同时满足的情况）短路到 governed + `input_incomplete:*`；函数不得宣称运行时强制 floor。
- **风险分级**：high。改所有任务路由判定。

### R2. minimal 行为改造（SKILL.md 分支 + 文本结构守卫）

- **完成条件**：
  - `SKILL.md` §3/§4 加 profile 分支：minimal 跳过任务对齐块/固定四段/spec-gate/HTML serve，只做"执行 + diff/测试验证 + 简短结论"；standard/governed 保留仪式。
  - `tests/minimal-behavior.sh` **文本结构守卫**（明示：校验 SKILL.md 结构存在，**不伪称验证 AI 真行为**）：SKILL.md 含 minimal profile 分支标记；minimal 段声明跳过"任务对齐块/spec-gate/HTML serve"；standard/governed 段保留。
  - minimal 真行为（真跳仪式）验证归**人工 dogfood**（§8，不进 CI）。
  - 注册 run_all。
- **边界**：minimal 仍必须有新鲜验证证据（diff/测试/lint），不得以 minimal 跳过验证；不得删 standard/governed 仪式；测试不得伪称"验证了 minimal 真行为"（只校验文本结构）。
- **风险分级**：high。改 /codesop 默认行为契约。

### R3. 审计数据结构测试（程序化部分）+ 人工 dogfood 场景清单

- **完成条件（程序化，进 CI）**：
  - `lib/profile.sh` 提供 **`write_audit()` 生产写入接口**：签名 `write_audit(intent,risk,ambiguity,blast,override,reversible,declared_profile,evidence,approver)`，AI 任务完成时调它（bash 调用，运行时唯一写入路径）；**内部调 `judge_profile(前6参)` 算 `floor`**（函数生成的唯一 floor 源，AI 不自报 floor），写入审计行含 `declared_profile`(AI 声明) + `floor`(函数算) + `floor_reason`(函数算) + 其余字段；若 `profile_rank(declared_profile) < profile_rank(floor)` → 审计行 `violation:true`（降档/漂移可见，人审回溯）。
  - `write_audit()` **参数合法性（严格校验，区别于 judge_profile 的 H0 容错）**：对全部 9 参做严格枚举/非空校验（前 6 参须合法枚举值 + `declared_profile` 须合法 profile 枚举 + `evidence` 非空 + `approver` 类型合规）；任一非法 → **拒写 + 非零退出码 + stderr 报字段名**（不规范化、不静默写）。**write_audit 合法才调 `judge_profile`**（此时输入合法，走 H1-H3，不触发 H0）。`violation:true` 只在 `declared_profile` **合法**但 `rank(declared) < rank(floor)` 时写（AI 合法声明却低于 floor = 降档）；非法 `declared_profile` 直接拒写，不存在"视为 governed"路径。
  - `tests/audit-structure.sh`：测 `write_audit()` 接口行为——合法输入写合法 JSON 行（write_audit 调 judge_profile 走 H1-H3 算 floor）；构造 `declared<floor` 写 `violation:true`、`declared≥floor` 写 `violation:false`；**前 6 参任一非法/declared_profile 非法/evidence 空/approver 非法 → 拒写 + 非零退出码**（write_audit 严格校验在先，不触发 judge_profile H0）；断言字段齐 + 类型 + `profile_rank` 排序 + ts ISO8601。**注**：H0 容错（invalid→governed+`input_incomplete:*`）是 `judge_profile` 独立行为，在 R1 测，不在 write_audit 测。
  - 审计字段契约（每行 JSON）：`intent`/`risk`/`ambiguity`/`blast`/`override`/`reversible`（输入，类型同判定表）/ `declared_profile`(枚举，AI 声明) / `floor`(枚举，write_audit 内部调 judge_profile 生成) / `floor_reason`(非空，函数生成) / `evidence`(非空字符串) / `approver`(governed 未批准=null，批准=人标识；minimal/standard=null) / `ts`(ISO8601) / `violation`(bool)。所有字段必填（approver/violation 按规则）。
  - profile 排序：`profile_rank()` minimal(0) < standard(1) < governed(2)；测试断言排序函数。
  - 注册 run_all。
- **完成条件（人工，不进 CI）**：spec §8 定义 6 dogfood 场景清单（minimal/standard/governed 各 2 的任务描述 + 期望行为），由人执行 + 结论记入 audit.jsonl。run_all 不含此项。
- **边界**：审计字段不得全 null 通过（floor_reason/evidence 必须非空）；approver 规则不得违反（governed 未批准必须 null）；dogfood **不得进 CI**（不真跑 AI，对齐 §10）；审计路径不得写 `~/.claude/`（中立路径）。
- **风险分级**：high（审计契约定义）。

### R4. SessionStart 瘦身（kernel 独立文件 + 明确接口）

- **完成条件**：
  - **kernel 独立文件** `config/codesop-router-kernel.md`（≤30 行，七类不变量 + floor 语义 + profile 判定入口）；full router `config/codesop-router.md` 原文件不动（skill 总表 + 链路组装）。
  - `setup` SessionStart hook 改注入 kernel 文件（`cat $HOME/.claude/codesop-router-kernel.md`）；full router 按需由 SKILL.md 读。
  - `tests/sessionstart-trim.sh`：(a) kernel 文件 `wc -l`（含空行注释）≤30；(b) **七类各最小语义断言**（不只字样——每类有一句与其语义相关的断言文本，如"凭据"类需含"不硬编码/不泄露凭据"语义句，非孤立关键词）；(c) floor/profile 判定入口存在；(d) full router 文件完整（行数基线 + sha256 基线 stamp，防丢内容）；(e) setup 注入的是 kernel 文件非 full router。
  - `SKILL.md` 指向 full router 读取路径；注册 run_all。
- **七类不变量定义**（本 spec 内联，R4 校验唯一源）：① 用户优先级 ② 任务范围 ③ 安全（不硬编码/泄露凭据）④ 失败披露 ⑤ 根因 ⑥ 验证证据 ⑦ 高风险升级人。
- **边界**：kernel 不得漏七类任一类（各需语义句非孤立词）；不得删 floor 语义/判定入口；full router 内容不得丢（基线 hash 校验）；行数口径明确（`wc -l` 含空行注释）。
- **风险分级**：high。改每次会话常驻 context。

## 6. 非目标

- 不自造 PEP/deny hook（继承 profile-decouple §5）。
- 不建评测平台 / shadow mode / 规则退役。
- **不真跑 AI agent 做测试**——dogfood 是人工抽检，不进 CI（r1 的"行为契约测试"是 tautological，已删）。
- **不改 Phase 1 已落地的 adapter / grep 守卫**；router card 文案结构调整（kernel 拆独立文件）属 R4 范围（修正 r1 §112 与 R4 的矛盾）。
- 不把 codesop 行为层整体函数化（YAGNI——judge_profile 已够，输出模板函数化不自然且 codex P1-6 指出收益不明）。
- 不第一阶段迁出 bash；不取消 governed 人审。

## 7. 迁移与入口

**入口条件**：Phase 1 已落地部分保持可用；本 spec 把 Phase 1 欠的判定可测化 + floor 测试纳入。

**实施顺序**：R1（判定函数+测试）→ R4（SessionStart 瘦身，依赖判定入口）→ R2（minimal 行为改造）→ R3（审计结构测试）。R1 是地基。

**退出条件**：R1-R4 完成条件满足；run_all 全过（含 R1/R2/R3程序化/R4 四个新测试）；v4 现有 20 测试不回归；SessionStart 注入 kernel ≤30 行。

## 8. 验证策略

- **合同测试（程序化，进 CI）**：judge_profile 确定映射 + H1 优先级 + H3 确定性（R1）；SKILL.md minimal 分支文本结构（R2）；audit.jsonl 字段/类型/排序（R3）；kernel 文件尺寸/七类语义/full router hash（R4）。
- **人工 dogfood（不进 CI）**：6 场景清单——minimal(局部文案/低风险配置) 验证真跳仪式但仍带验证证据；governed(鉴权/数据迁移) 验证真停请求批准；standard(跨模块/高歧义) 验证阶段末复核。人执行 + 结论记 audit.jsonl + approver。
- **回归**：v4 现有 20 套全过；grep 守卫不破。

## 9. 风险与缓解

| 风险 | 缓解 |
|------|------|
| 判定函数不被 AI 直接调用（经 write_audit 间接调），floor 声明靠 AI 自律 | 明示 best-effort；write_audit 的 violation 字段 + 审计回溯 + 人工 dogfood 抽检（不假装机械保证） |
| 文本结构守卫过不到真行为 | R2 明示只校验结构不伪称行为；真行为靠人工 dogfood（§8） |
| minimal 改造让 AI 借口跳验证 | R2 边界硬性要求新鲜验证证据；人工 dogfood 校验 |
| kernel 拆独立文件后内容漂移 | R4 full router sha256 基线 + kernel 七类语义断言 |
| router 文案与函数规则两源漂移（运行时 AI 读文案，函数是 oracle） | write_audit 记 declared_profile vs floor 对比，漂移/降档时 violation:true 入审计供人审回溯（不假装 CI 自动检测，但留机械锚） |
| H0 短路实现分歧 | R1 测试枚举每种 unknown/invalid（含与 H1 并存）→ governed + input_incomplete |

## 10. Domain Language Delta

- **判定表（Profile Decision Table）**：`(intent,risk,ambiguity,blast,override,reversible)→profile` 确定映射，H0-H3 优先级。
- **测试 oracle（Test Oracle）**：`judge_profile()` 在测试中算期望 profile 的角色；运行时经 `write_audit` 间接调用（AI 不直接调）。**非强制执行点，非自动审计验证器**（降档靠 violation 字段 + 人审回溯，r1 措辞已收窄）。
- **文本结构守卫（Text Structure Guard）**：校验 SKILL.md/router 含必要段，不伪称验证 AI 行为。
- **人工 dogfood（Manual Dogfood）**：人执行场景 + 记审计，不进 CI。

## 11. 待 spec-gate 判定

1. 是否接受"prompt 行为不可单测、可测范围收缩到判定函数+文本结构+审计数据"（dogfood 退人工）。
2. 是否接受 judge_profile 定位为"测试 oracle + 审计 floor_reason 生成器"（不伪称发现真实降档）。
3. 是否接受 kernel 拆独立文件 `config/codesop-router-kernel.md`（vs sed 拆同文件）。
