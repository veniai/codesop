# codesop v5：治理提炼 + Claude 解耦 + Profile 分档

**日期**：2026-07-11（r3，收口：fingerprint 措辞统一 / Phase 0 状态对齐实现 / 文档压缩）
**状态**：Draft，待 spec-gate
**定位**：把 v4.9 实战纪律（router card、文档职责、simple 出口、测试防再犯）提炼成三层平实能力——profile 分档、Claude 解耦、事实完整性。codesop 的角色是**帮模型做对，不是防模型做错**。
**与前版关系**：替代 `2026-07-11-v5-adaptive-governance-architecture.md`（「前版」，保留作历史）。前版诊断正确但实现规划对一个 bash 工具过度；本版继承诊断、砍宏大架构。

## 1. 决策摘要

| 维度 | 决策 | 一句话理由 |
|------|------|-----------|
| 评测 | 砍完整平台，留**轻量行为测试**（表驱动 12-20 路由场景 + 6 dogfood，§9 R8） | 平台是第二项目；纯「人工抽检」无法机械验证 profile 行为 |
| 宿主 | **Claude-first 能力分级**（§6）：Claude 完整编排；Codex/OpenCode 核心纪律薄包装 | 编排能力是宿主给的，假装对等是浪费 |
| floor / 执行点 | floor 是 **Prompt 层 best-effort 契约**（非安全边界）；不可逆操作靠**宿主原生审批**（adapter 不弱化）；**不自造 PEP/deny hook** | floor 是工作流契约；不可逆的安全边界在宿主原生层 |
| Patch | **模式保持 + fingerprint 门禁**（§7）；审计已完成（5 全必要） | 整文件覆盖对单人维护最优；fingerprint 门禁防吞上游修复 |
| SessionStart | **Phase 2 瘦身**（只注入 kernel，router 按需） | minimal 任务不需完整 router，省 context |

## 2. 要解决的问题

1. Claude 专属机制（`/goal`、SessionStart、plugin registry、patch）混入核心 → 解耦（§6）。
2. `dep_patch_compat` 只比 major.minor 是盲区——minor 内升级（6.1.1→6.1.2）判兼容然后整文件覆盖吞上游修复 → fingerprint 门禁（§7，v4.9.2 部分修）。
3. 仓库/runtime/plugin 版本可脱节却报「覆盖完整」→ 事实完整性（Phase 0）。**项目自己踩过**：v4.9.1/v4.9.2 release 时两次漏改 PRD 版本号被 `consistency-guards` 抓——正是 Phase 0 要防的。
4. `1% chance` Skill 规则过度触发 → 按需加载（Phase 2）。
5. simple 任务走全套仪式（spec/对齐块/HTML）→ profile 分档（§4）。

## 3. 设计原则

1. **治理常驻、过程按需**：全局契约只放七类不变量；router/Skill/文档细节按需读取。
2. **流程成本与风险成比例**：profile 三档替代一条默认完整 pipeline。
3. **不硬编码 Claude 路径**：核心不含 `/goal`、`installed_plugins.json`、`~/.claude`、SessionStart（claude-adapter 专属）。
4. **floor 是 best-effort 契约，安全靠宿主原生**：adapter 只增强不弱化宿主原生审批。
5. **不靠 Prompt 堆叠当护城河**。

## 4. Profile 分档

router 不再输出固定链路，先判定 profile：

```text
intent     = explore | change | debug | review | ship
risk       = low | medium | high
ambiguity  = low | high
blast      = local | cross-module | external
profile    = minimal | standard | governed
```

| Profile | 适用条件 | 默认行为 |
|---------|----------|----------|
| `minimal` | 低风险、低歧义、局部、可回滚、**不含**鉴权/迁移/部署/公共接口 | 直接执行 + diff/测试验证；不强制 spec、TaskList、人审、对齐块、HTML |
| `standard` | 多步骤、跨文件、ambiguity=high | 轻量目标；必要时 plan；阶段末独立验证 |
| `governed` | 鉴权、数据迁移、公共接口、部署、破坏性、外部影响 | 正式 spec + 人审目标 + 独立复核 + 机械证据 + 回滚 |

**Floor 是 best-effort 工作流契约，不是安全边界**：router 算出的 floor 是 codesop 对流程强度的要求（模型自律遵守，Agent 只能升档不能降档，缺信息默认升档）。但它**不替代**宿主原生安全层——不可逆操作的真实拦截由宿主 sandbox/审批/用户授权提供。governed 人审是用户风控：模型识别后请求，批准权在用户/宿主。

## 5. governed 怎么落地

不自造执行点（砍 PDP/PEP/Audit/deny hook）。三件平实事：

1. **Profile 判定**（router）：从「输出链路」改成「先算 floor，再按 floor 组装链路」。
2. **宿主原生审批不弱化**（唯一涉「硬」层面）：adapter 配置宿主原生 sandbox/审批/hook，**只增强不弱化**——不得关闭宿主对不可逆操作的审批。codesop 复用宿主已有审批，不自造。
3. **审计**（可选）：`$XDG_STATE_HOME/codesop/audit.jsonl`（回退 `$HOME/.local/state/codesop/`），不写 `~/.claude/`。记录 `{intent, risk, profile, floor_reason, evidence, approver, ts}`，观察工具非 gate。

> 修正前版描述：前版 PEP 是「宿主原生 sandbox/审批/hook/状态机的抽象执行点」，**≠要求新建 deny hook**。本版砍「自造执行点体系」，保留「复用宿主原生审批」（第 2 点）。

## 6. Claude 解耦 + 能力分级

**当前 Claude 耦合点**（实测 grep lib/+setup+config/+SKILL.md）→ 移到 claude-adapter：

| 耦合点 | 现位置 |
|--------|--------|
| SessionStart hook 注入 router | `setup` + settings.json |
| `/goal` handoff | SKILL.md / router 文案（2 处，不在 lib/ 逻辑代码） |
| `installed_plugins.json` 探测 | lib/updates.sh、lib/patch-health-check.sh |
| `patches/superpowers/` 覆盖 | `patches/` + `setup patch_skills()` |
| `~/.claude` 路径 | **横切散在 5 文件**（detection/updates/init-interview/patch-health-check/setup），需抽象「宿主能力/路径接口」 |

**能力分级（Claude-first）**：

| 宿主 | 等级 | 提供 |
|------|------|------|
| Claude Code | **完整** | router 编排 + SessionStart + /goal + patch + 审计 |
| Codex | **核心纪律** | L0 kernel + 项目文档 + codesop Skill；编排按 Codex 原生 |
| OpenCode/OpenClaw | **核心纪律** | 同 Codex；安装目标分别验证 |

**不承诺行为对等，只承诺核心纪律语义一致**（七类不变量、floor 语义、证据要求）。spec 批准后同步 PRD §5（README 经核实无三端同级宣传，不改）。

## 7. Patch：模式保持 + fingerprint 门禁

**机制**（`setup patch_skills`）：codesop 在 `patches/superpowers/` 放 5 文件 → 找到 superpowers 目录 → `diff -q` 比对 → 不同就 `cp` 整文件覆盖。

**模式保持**（单人维护 + 手动适配上游，覆盖最优）+ **fingerprint 门禁**（补 compat 盲区）：

- **fingerprint = `gitCommitSha`**（从 `installed_plugins.json` 读，存基线 stamp `$XDG_STATE_HOME/codesop/patch-upstream-sha`）。apply 前比当前 gitCommitSha vs 基线 → 变了报警暂停不覆盖（即使 major.minor 兼容）。
- **为何用 gitCommitSha 而非「文件 hash」**：上游文件被 patch 覆盖后无法 hash 官方原版；gitCommitSha 是上游 commit 指纹，可行且比 major.minor 严。
- **保守型误报**：gitCommitSha 变了不一定改了 patched skill（可能改别的），但「误报暂停」比「漏报吞修复」安全；人工确认后更新基线。
- **双门**：major.minor（跨 minor，`dep_patch_compat`）+ gitCommitSha（minor 内任何 commit 变化）。`patch-health-check` 会话级也比这两道。

**审计结论**（v4.9.1 适配 6.1.1 时逐个验证：diff patch源 vs 官方 6.1.1 + md5 对比共享骨架）：**5 patch 全必要**——brainstorming / writing-plans / verification（共享骨架与官方 md5 一致，codesop 增量官方未吸收）；finishing（146<官方 241 是减法补丁，删菜单/forge中立/PR去重/ref清理，官方 6.1.1 仍含 menu 未吸收）；schema（codesop 新增）。细节见 v4.9.1 CHANGELOG。Phase 2 不再议「finishing 弃留」。

## 8. 迁移路线

### Phase 0：事实完整性 + patch 门禁（v4.9.x，进行中）

| 子项 | 状态 | 说明 |
|------|------|------|
| patch 跨 minor 失效提示 | ✅ v4.9.1 | `_patch_stale_warn`（setup 醒目警告）+ SessionStart `patch-health-check` hook（major.minor 对比） |
| patch fingerprint 门禁 | ✅ v4.9.2 | gitCommitSha 双门（apply 前暂停 + 会话级告警），防 minor 内吞上游修复 |
| runtime version 报告 | 待实施 | 复用 `_dep_installed_version`（读 installed_plugins.json） |
| manifest hash | 待实施 | sha256 哈希 codesop 关键文件（kernel/router/patches/dependencies.sh）→ stamp 对比 |
| capability state 模型 | 待实施 | 仿 `check_understand_usability`（多态）+ `check_git_health`（三态）：healthy/stale/absent/unknown |
| family 汇总 | 待实施 | 取最差（任一 stale/unknown → family 上浮） |

**退出条件**：所有已安装宿主目标 runtime/version/hash 一致；family 内任一 stale/unknown 上浮；stale 测试必红；fingerprint 门禁测试（模拟 commit 变 → 暂停）必过；缺 capability 为 unknown 时不报「覆盖完整」。

### Phase 1：Claude 解耦 + Profile floor + 审计（v5 alpha）

- §6 解耦：拆 `core/`（宿主中立）+ `claude-adapter/`，核心 grep 守卫。
- router 改「先算 floor，再组装链路」。
- 审计 jsonl 落地（`$XDG_STATE_HOME`）；adapter 审批只增强不弱化。
- v4 workflow 保留为 `v4-compat`（`engine_mode`）。

**退出条件**：核心无 Claude 路径（grep 守卫）；floor 不能被 Agent 降档（场景测试）；adapter 不弱化宿主审批；v4 测试继续过。

### Phase 2：minimal 走通 + SessionStart 瘦身 + 行为测试（v5 beta）

- `minimal` 取消对齐块/spec-gate/固定输出/HTML；SessionStart 默认只注入 kernel。

**退出条件（可判定）**：表驱动 12-20 路由场景全过（高风险误入 minimal=0；鉴权/迁移必 governed；局部文案必 minimal；ambiguity=high 不进 minimal）；6 dogfood（每档 2）：minimal 不产 spec/HTML，governed 真停下请求批准+证据，standard 阶段末复核；SessionStart 瘦身后路由正确。

## 9. 功能需求

- **R1 治理内核守卫**：七类不变量 golden test + 尺寸上限 + 不含 Skill 名/`/goal`/固定章节。**风险 high**（改全局契约）。
- **R2 Profile 判定**：表驱动 12-20 场景（含 ambiguity=high 不进 minimal）；floor_reason 可审计；缺信息默认升档。风险 high。
- **R3 Minimal 轻路径**：不强制 spec/TaskList/对齐块/HTML/subagent；dogfood 验证 minimal 不产 spec/HTML。风险 high。
- **R4 Claude 解耦**：`core/` grep 不含 `/goal`/`installed_plugins.json`/`~/.claude`/`SessionStart`；Claude 能力不丢；adapter 按能力分级。风险 high。
- **R5 Governed 人审 + 行为测试**：governed 声明人审+证据+回滚；**dogfood 验证真停下请求批准+证据**（不只查 Prompt 字样）；adapter 不弱化宿主审批；不配自造 deny hook；审计 jsonl。风险 **high**（改人审语义 + 涉宿主审批）。
- **R6 事实完整性**：每宿主目标 runtime version + manifest hash + capability state；family 取最差。风险 medium。（patch 审计已完成 v4.9.1，不在此 R）
- **R7 Patch fingerprint 门禁**：apply 前比 gitCommitSha vs 基线 stamp，变了暂停不覆盖；patch-health-check 双门；测试（跨 minor + minor 内 commit 变）必过。风险 high。
- **R8 轻量 profile 行为评测**：表驱动 12-20 场景 + 6 dogfood 可重复；退出可判定。风险 medium。

## 10. 非目标

不建完整评测平台/shadow/规则退役（留 R8 轻量）；不自造执行点（PDP/PEP/Audit/deny hook）；adapter 不弱化宿主原生审批；不追求 Codex/OpenCode 对等；不建 wrapper/companion 体系；不取消 governed 人审；不第一阶段迁出 bash；不替代 Claude/Codex/OpenCode。

## 11. 决策记录与审查演进

| 议题 | 决策 | 不做（前版/初版误） | 演进 |
|------|------|---------------------|------|
| 架构 | profile + adapter + 事实完整性 | L0-L5 六层、PDP/PEP/Audit 自造执行点 | r1 砍六层；r1 误述前版「要求 deny hook」，r3 修正（前版 PEP=宿主原生抽象执行点） |
| floor | best-effort 契约 + 宿主原生审批 | 自造 deny hook 冒充安全边界 | r1 砍硬门禁；r2 写准 best-effort 语义 |
| 评测 | 轻量行为测试（R8） | 四组对照平台 / 纯人工抽检 | r1 砍平台；r2 补轻量测试（避免太弱） |
| 宿主 | Claude-first 能力分级 | 三端假装对等 | r2 明确能力分级 |
| Patch | 模式保持 + fingerprint 门禁 | wrapper/companion 迁移 | r1 模式保持；r2 加门禁；r3 措辞统一（gitCommitSha，非文件 hash） |
| 审计路径 | `$XDG_STATE_HOME/codesop/` | `~/.claude/codesop-audit/`（含 Claude 路径） | r3 修（核心不含 Claude 路径原则） |
| profile 输入 | 含 ambiguity | r1 误删 ambiguity | r3 补回 |
| R1/R5 风险 | high | r2 标 medium | r3 修正（改全局契约/人审语义） |

**v4.9.1**：6.1.1 适配 + 跨 minor 失效可见化。**v4.9.2**：r2 审查采纳 12 条 + gitCommitSha fingerprint 门禁 + PRD Claude-first 同步。**r3**（本版）：收口 fingerprint 措辞 / Phase 0 状态对齐实现 / 文档压缩（246→~190 行）/ 修 PRD 4.9.2 版本脱节（`consistency-guards` 恢复）。

后续若有新证据（fingerprint 误报率、profile 误判率），再回看修订。
