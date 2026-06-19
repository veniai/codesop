# superpowers 6.0 重基 + 漂移硬化 设计

**日期**: 2026-06-18
**状态**: 待复核（v3 — diff 验证可行性后修正）
**关联**: superpowers v6.0.0 (2026-06-16 release)、codesop v3.14.2

## 背景

superpowers 升级到 6.0.2（本机已装，5.1.0 已 orphan）。codesop 在 `config/dependencies.sh` 把 superpowers 钉在 `min_version=5.1.0, patched=yes`。`dep_patch_compat()`（lib/updates.sh）按 major.minor 严格匹配 → `6.0 ≠ 5.1` → **4 个 superpowers 补丁被 `patch_skills()`（setup）跳过**，当前用户实际跑 vanilla superpowers 6.0，codesop 定制（Grill Mode、验收矩阵、分阶段 checkpoint、反 stub、去 menu 收尾）失效。

> 注：跳过时**有告警**（setup 输出 `⚠ superpowers X.Y (patches target A.B.x) — skipping patches`），但只在 `bash setup --host claude` 时触发；用户若经 Claude Code 插件管理器升级 superpowers 而未重跑 setup，则感知不到。

副作用：用户"写 plan 时断"痛点，根因之一正是 writing-plans 补丁失效——vanilla 6.0 的 writing-plans 无分阶段流、且 complete-code-in-every-step，复杂功能 plan 一次性大生成易截断。

6.0 引入了对 codesop 有价值的新思路（视觉伴侣 per-session key 鉴权、per-task Interfaces 块、Global Constraints、Task Right-Sizing、worktree provenance 清理、合并后的 task-reviewer），重基时吸收。

## 目标

1. 让 codesop 补丁在 6.0 上重新生效
2. 吸收 6.0 对 codesop 有价值的新思路（不回退）
3. 验证现有漂移告警正确、沉淀重基流程防再发生
4. 不改交付机制（保留整文件覆盖）

## 非目标

- **不改交付机制**：已评估"组合式 overlay"（纪律上移路由/SKILL、停止覆盖 skill 文件），更复杂、两层真相、覆盖不可靠，否决。
- **不新增 writing-plans 机制**：现有设计（分阶段流 + subagent 覆盖审查）已覆盖 plan 截断痛点，失效才是根因，重基即修复。
- 不动 router / SKILL.md 架构，不碰其他 plugin。
- 不新建工作台时漂移检测（超出"小改"，列为未来可选）。

## 每纪律重基映射

### reviewer ×2 → 删除

6.0 把 `spec-reviewer-prompt.md` + `code-quality-reviewer-prompt.md` 合并成单个 `task-reviewer-prompt.md`，且吸收 codesop 反 stub 意图（"不信实现者自辩"、file:line 证据、只读、rationale 不能降级 finding、Missing/Extra/Misunderstood 三分类）。

**行动**：
1. 删除 `patches/superpowers/subagent-driven-development-spec-reviewer-prompt.md` 与 `...-code-quality-reviewer-prompt.md`
2. **删除 setup `patch_skills()` 中对应两个映射块**（`sdd_spec` 约 L277-286、`sdd_cq` 约 L288-296）——否则 6.0 下 plugin 无这两个文件，每次 setup 打印 stale "not found, skipping patch" 告警
3. 历史文档 `docs/superpowers/{plans,specs}/2026-05-28-execution-reviewer-*` 是已完成计划的历史记录，**不动**

### brainstorming → 重基 + 结合

**codesop 增量（插入段）**：Grill Mode（code-first / decision-tree / domain-vocabulary 对齐）、ADR trigger、Domain Language Delta、CONTEXT.md 检查。

> 注：原补丁头列"3 项改动（Grill/ADR/Review Gate）"不准——User Review Gate 上游也有（非 codesop 独有），且漏列 Domain Language Delta 与 CONTEXT.md 检查。重基时修正头为实际的 4 项独有增量。

**整份以 6.0.2 为基底**（diff 核实 codesop 补丁在多处落后于 6.0.2，不只视觉伴侣）：
- just-in-time 视觉伴侣 + per-session key 鉴权 + 沙箱（替换旧"一次性 consent"）
- **简化版 process flow digraph**（6.0.2 因视觉伴侣改 just-in-time，删了 "Visual questions ahead?" 节点；codesop 补丁还是旧版）
- **排版**：6.0.2 全文用 em-dash `—` 与 `→`，codesop 补丁是 `--` 与 `->`——基底取 6.0.2 即自动对齐

机制：取 6.0.2 `brainstorming/SKILL.md` 原文，把上述 4 项 codesop 增量作为插入段叠入对应位置，其余（含 digraph、视觉伴侣、排版）一律用 6.0.2。

### writing-plans → 重基 + 结合（不加新机制，本次最重）

> diff 逐 section 核实：6.0.2 新增 `Task Right-Sizing` / `Global Constraints` / per-task `Interfaces` 块（codesop 无，会被回退）；codesop 有 9 个增量段（6.0.2 无）。spec 冲突清单已完整捕到，无遗漏。这是三个补丁里最重的重基（9 codesop 段 + 3 新 6.0 段 merge），plan 应拆子步逐段落。

**保留 codesop 现有全套**（已覆盖 plan 截断痛点，失效才是根因）：
- Requirement Extraction (R1..RN)
- Acceptance Criteria (G1..GN Given/When/Then + adversarial self-check + Coverage Matrix + Gap Scan)
- Complexity Assessment（simple/moderate/complex 分层 → 走轻量还是完整 plan）
- Phase Split + Lightweight Plan
- **Staged checkpoint flow + Resume Protocol**（skeleton → 逐 task 扩展【每扩存盘】→ self-review，断了从 checkpoint 续）——治"写 plan 时断"的核心
- subagent spec-coverage Self-Review（漏 Rn → ❌，即完整性门禁；仅 complex 路径）
- Pipeline Continuation（替代 Execution Handoff menu）
- implementation-brief（复杂任务写接口签名+约束+边界+测试义务，不写整段代码 → 减小 plan 体积）

**继承 6.0 新增**：Global Constraints 块（Plan Document Header 内）、per-task Interfaces 块（Consumes/Produces）、Task Right-Sizing 段。

**冲突调和**：
- Complexity Assessment vs Task Right-Sizing：都留，互补（前者管 plan 深度路径，后者管单任务边界）
- implementation-brief vs complete-code：保留 brief，覆盖 6.0 complete-code 指引（brief 给了接口+边界+测试义务，具体不空，不违反 No-Placeholders 精神）
- 删除 6.0 Execution Handoff menu（Pipeline Continuation 替代）

### finishing → 重基 + 结合

**保留 codesop 流程**：去 menu 直推 PR / PR 存在检查 / fetch-prune。

**forge 中立**：不硬编码 `gh`。PR 存在检查与创建用泛化表述（"用你的 forge 工具检查/创建 PR"），模型按上下文选 gh/glab。理由：模型知道 forge 情况，写死限死平台。

**worktree：采 6.0 行为 — PR 后保留**（用户决策）：
- 删除 codesop 现"PR 后删 worktree"逻辑；PR 建完后 worktree 保留，供 review 迭代时回到同一工作区改代码、更新 PR。
- worktree 生命周期交既有机制：EnterWorktree 管理的由 ExitWorktree 退出时清理；merged/orphan 分支由 `check_git_health` 检测。
- 继承 6.0 的 provenance 清理**指导**（只清 `.worktrees/`/`worktrees/`、harness 拥有的不动）写入 skill，供未来 merge/discard 路径用——codesop 默认走 PR 不触发，但保留指导无害。
- naive `git worktree remove` 误删 harness worktree 的潜在 bug 因此自然消除（PR 路径不再删）。

**顺带修**：setup `patch_skills()` 里 `# finishing-a-development-branch: v5.1.0 options menu...` 注释已 stale（实际 skip menu），重基时改正。

## 硬化

### 硬化 1：漂移告警 — 已存在，降级为验证 + 文档化

深度核对发现：`patch_skills()`（setup）与 `_ensure_superpowers_version()`（updates.sh）**已有**漂移告警，`dep_patch_compat` 失败时输出 `⚠ superpowers X.Y (patches target A.B.x) — skipping patches`；`tests/dep-upgrade.sh:50-51` 已断言 `patch_mm`/`skipping patches`。原"静默无告警"判断错误。

真实缺口：告警仅 setup 时触发。按"小改"原则不新建工作台检测，改为：
1. 重钉 6.0.2 后验证现有告警仍正确触发（跑 dep-upgrade.sh）
2. 在硬化 2 checklist 注明：**superpowers 升级后须重跑 `bash setup --host claude`** 让补丁重评估

（工作台/SessionStart 时漂移检测列为未来可选，本次不做。）

### 硬化 2：重基 checklist 文档

位置：`docs/superpowers/playbooks/rebase-superpowers-patches.md`（**不进 CLAUDE.md**，守防膨胀）。

内容：
1. 每补丁逐条核对：读上游新版本 → diff（codesop 现补丁 vs fork 基线）→ 采纳上游结构变更 → 保留 codesop 增量 → 删 codesop 不要的段 → **同步 setup `patch_skills()` 映射块**（删/改文件时必同步，否则 stale 告警）
2. **别盖掉上游改进核对表**：视觉伴侣 per-session key 鉴权 / per-task Interfaces 块 / Global Constraints / Task Right-Sizing / worktree provenance 清理 —— 逐项确认已继承
3. 更新每个 patch 文件头 `Based on: superpowers vX.Y.Z`
4. bump `config/dependencies.sh` min_version + **同步 tests/dep-upgrade.sh:14 的版本断言**
5. superpowers 升级后须重跑 `bash setup --host claude`
6. `bash setup --host claude` + 验证补丁 apply + 跑 `bash tests/run_all.sh`

## 版本钉

`config/dependencies.sh`：`"plugin|superpowers@claude-plugins-official|core|yes|6.0.2"`。

`dep_patch_compat` 按 major.minor 门禁，故 6.0.2 表示"基于 6.0.2 重基、兼容 6.0.x"。

## 测试影响

| 测试 | 影响 | 处理 |
|---|---|---|
| `tests/dep-upgrade.sh:14` 断言 `core\|yes\|5.1.0` | **会失败** | 改为 `core\|yes\|6.0.2` |
| `tests/dep-upgrade.sh:29` entry_count ≥ 8 | 不受影响（计数不变） | 无 |
| `tests/dep-upgrade.sh:50-51` patch_mm/skipping | 不受影响（告警保留） | 无 |
| `tests/codesop-update.sh:141-150` 字面量 5.1.0 测函数 | 自包含，不读 manifest | 无 |
| reviewer 补丁文件存在性 | 无测试断言 | 无 |

## 发布产物

feat 级变更，按 Release Checklist 同步：VERSION bump、`skill.json` version、CHANGELOG `[X.Y.Z]` 条目。

## 验证

1. 删 2 个 reviewer 补丁 + setup 对应映射块（L277-296）
2. 重基 brainstorming / writing-plans / finishing 3 补丁到 6.0.2
3. 改 tests/dep-upgrade.sh:14 版本断言；修 setup finishing stale 注释
4. `bash setup --host claude`
5. 确认 3 补丁 apply（`diff` installed skill vs patch 文件 == 一致）
6. `bash tests/run_all.sh` 全套通过
7. 每个 patch 文件头 `Based on: superpowers v6.0.2`
8. 实测一次 finishing（验证 forge 中立表述 + worktree provenance 清理）

## 风险与缓解

| 风险 | 缓解 |
|---|---|
| 重基漏掉某 6.0 改进 | 硬化 2 checklist 逐项核对 |
| setup 映射块没同步删 → stale 告警 | 验证步骤 1 明确删 L277-296；checklist 固化"改补丁必同步 setup" |
| forge 中立表述不清，模型不执行 PR 检查 | 验证步骤 8 实测 finishing |
| 分阶段流若 agent 不严格遵循仍断 | 先靠重基恢复；复现再单独评估（本次不做，守小改） |
| brainstorming 重基误带旧视觉伴侣 | checklist 显式核对 + 以 6.0.2 为基底叠加 |

## 已核实非风险

- codesop 代码（detection/router/setup 除 finishing 补丁外）**无** `~/.config/superpowers/worktrees` 旧路径假设 → 6.0 worktree 改址不破坏
- `dep_patch_compat` 确为 major.minor 门禁，钉 6.0.2 兼容 6.0.x
- 无测试断言 reviewer 补丁文件存在
