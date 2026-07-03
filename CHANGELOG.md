# Changelog

## [Unreleased]

## [4.6.0] - 2026-07-03

### Changed — spec-gate 可视化重构（dispatch 独立 subagent + spec 实质为主）
实际工作反馈（Cherry）：spec-gate 可视化主 AI 做（无交叉检验）+ 内容套 evidence pack 模板（审完备性，非 spec 实质——"方案对不对" vs "够不够齐"做混）。两层修：
- **§8.7 B 重写**：spec-gate 可视化派**全新独立 subagent**（交叉检验，非主 AI 自审）+ subagent 渲染两层（**主 spec 实质呈现**：功能去留地图/改动拓扑/数据流/去留卡片；**辅 evidence pack**：rubric 五项）+ completed 认 serve URL（外部锚点，§1.1 第 4 条）
- **schema §8 改**：spec 实质呈现为主（subagent 读 spec 定制）+ evidence pack 为辅（完备性锚点）

**防空洞**：机制（serve URL 锚点）防"跳过"；独立 subagent + spec 实质任务防"内容做错对象"（Cherry 反馈：套 evidence pack 模板，内容空洞）。两层 = 交叉检验 + 内容对。

### SKILL.md 去重（533→522，-11 行）
- §8.7 D（plan-gate/deliver-gate）引用 §8.5 三 gate 降级表（不重复）
- §9 /goal 铁律引用 §1.1/§8.5/§8.7（不重复列 9 条）

run_all 18/0。

## [4.5.0] - 2026-07-03

### Changed — spec-gate 归位（架构重构，codex 审 A'）
spec-gate（人审 rubric + 可视化）从 brainstorming patch **归位到 codesop SKILL §8.7 B**（spec-gate 是 codesop gate，本就该在 codesop 层，不在造 spec 的 brainstorming skill）：
- **brainstorming 瘦身**：只造 spec + 自审链（inline reviewer + codex 跨模型 + 证据包 + AI self-proof 清 blocker），到**交付 codesop spec-gate** 止。删 spec-gate 人审 + 可视化 + 直接进 writing-plans。流程图/checklist/terminal/头部锚点同步改
- **SKILL §8.7 B**：改"**读** brainstorming 交出的证据包"（不重复 dispatch，防双出）+ **可视化 serve**（gate 职责，必可视化，非 just-in-time 可选）+ 人审 rubric
- **setup write_skill_runtime**：`_evidence-pack-schema.md` 同步到 codesop skill 目录（sibling，§8.7 B 引用）

**根因**：spec-gate 可视化寄生 brainstorming，AI 混两个 visual companion（设计讨论 just-in-time vs spec-gate 必可视化）→ 不自动可视化。归位后位置对 + 消歧。codex 审 A'（三点风险全解）+ 锚点残留清理。

run_all 18/0。

## [4.4.4] - 2026-07-03

### Changed — 新项目反馈首批（CONTEXT 定位 + superpowers Codex 输出）
- **CONTEXT.md 文档澄清**（问题 1）：CLAUDE 架构 + Init Flow Phase 3 + README init 段注明 CONTEXT.md 是可选业务领域文档（DDD 统一语言），init 不生成（需领域专家填，空骨架无价值）；模板在 templates/project/ 供复杂业务项目手动建。codesop 自己不用（方法术语在 spec/SKILL，建会重复真相源）
- **superpowers (Codex) 输出注明区分**（问题 2）：`_check_skills_all` 输出从"Codex"改为"Codex 宿主（superpowers 框架端，非 codex AI 模型）"——区分 superpowers 框架的 codex 宿主安装 vs codex@openai-codex AI 模型插件（9/9 已装），用户不再混

### Added — 防再犯 E（A-F 齐全）
- consistency-guards 加 E：patch 头部 changelog 的 codesop 版本（vX.Y）在 CHANGELOG 存在（排除 Based on/upstream/Retained/superpowers v 的 superpowers 版本引用）

run_all 18/0。

## [4.4.3] - 2026-07-03

### Fixed — v4.4.2 删孤儿的连带遗漏 + 防再犯
- **README + CLAUDE 架构段删 templates/init/**：v4.4.2 删 templates/init/prompt.md（孤儿）后目录空，但 README/CLAUDE 架构段仍列 `init/` → 悬空引用，本次清
- **防再犯 F**：consistency-guards 加 F——README/CLAUDE 架构段列的目录真实存在（templates/system, project, lib, patches, config, docs, commands）+ 负向断言无悬空 `templates/init/`。防"删文件后文档架构段过时"再发（根因同类于 P0-3 跨文件引用悬空，这次是目录级）

run_all 18/0。

## [4.4.2] - 2026-07-01

### Fixed — 全方位诊断 P2 清理（17 问题全清）
- **HOME 守卫**：commands.sh:31-33 + install.sh:8 裸 `$HOME` → `${HOME:-$(echo ~)}`（Key Gotcha 一致性，hook/IDE 环境安全）
- **删孤儿模板** templates/init/prompt.md（无生产引用）
- **SKILL §8 init 补 docs/adr/**（实际 init 生成 docs/adr，文档漏列）
- **brainstorming "v7 §4.3 hole" → "v7 codex-skip 漏洞"**（去不可证 §引用，patch 头部 + 正文 2 处）
- **project/README.md 模板去 npm 硬编码** → 通用占位（按技术栈 npm/pip/cargo/go，非 JS 项目不误导）
- **CLAUDE 架构图补 install.sh**（用户一键入口调 setup；此前只列 setup）

run_all 18/0。**至此 v4.4 全方位诊断 P0+P1+P2 共 17 问题全清。**

## [4.4.1] - 2026-07-01

### Fixed — 全方位诊断 P1 清理（v8 命名残留 + bare return + 覆盖缺口）
- **bare return ×13 → return 0/return $?**：setup:81（copy_file 后 `return $?` 显式继承）+ updates ×10 + init-interview ×3（Key Gotcha：防继承前命令非 0 退出码）
- **brainstorming "three-cycles" v8 命名 → spec-gate**（patch 头部 changelog）
- **writing-plans "(T6)" v8 SUPERSEDED 引用 → §8.7 D**
- **spec §8 口径**：codex 不可用 (c) 栏"跳过"→"降级 advisory"（对齐 patch/schema）+ "v8-style pipeline"→"codesop pipeline（§3 step 10.5）"
- **CLAUDE patches 注释补 v4.1/v4.2**：brainstorming（第一性原理）+ verification（§C.2 对抗式审查）

### Added — /goal §8.7 协同四步行为测试
- tests/goal-collaboration-behavior.sh：§8.7 协同四步（①启动/②每轮/③退出/④失败码）+ round-N.md 证据包 + deliver-gate 衔接 + 不静默改走普通执行——补 v4.0 范式核心覆盖缺口（诊断 P1-4）

run_all 18/0。

## [4.4.0] - 2026-07-01

### Fixed — 全方位诊断 P0 + 防再犯守卫
- **P0-1 init 访谈死代码**：删 codesop 自己的访谈机制（check_user_preferences/has_user_preferences/interview_user_preferences + 占位符 sed + AskUserQuestion）+ 假绿测试 codesop-init-interview.sh；偏好由 Claude Code /init + 全局 CLAUDE.md 管，codesop init 只生成标准模板
- **P0-2 PRD 版本脱节**：§1 里程碑/§4 Current 同步（之前停 v3.10.1/v4.0.0）
- **P0-3 schema §4.x 错引**：_evidence-pack-schema 的 spec §号对齐实际章节（§4.1→自定/§4.5、§4.3→§5#4+§8、§4.4→brainstorming skill）
- **P0-4 spec 关联悬空**：spec-as-goal.md 删 spec-three-cycles.md（SUPERSEDED plan）关联

### Added — 防再犯守卫（治"为什么之前没发现"根因）
- tests/consistency-guards.sh：A 引用存在 / B run_all 一致 / C 版本快照（VERSION==PRD §1==§4）
- tests/init-deadcode-removed.sh：D init 无访谈 + 真实模板无占位符（禁合成 fixture）
- run_all 注册 codesop-uninstall.sh（32 断言此前零覆盖，B 暴露）

### Changed
- commands/codesop-init.md：删 Step 1-3 访谈入口，重编号 + Phase 1 清
- CLAUDE.md：Init Flow Phase 1（删访谈）+ 模块描述 + 死测试引用更新

### 根因（codex 审点出）
测试假绿 + 跨文件软引用无绑定 + 聚焦加法没扫存量 + codex 跨模型审长期不可用。本次补防再犯守卫 + codex 恢复（Hiddify 停，ohmycdn 直连）

## [4.3.1] - 2026-07-01

### Changed
- **§9 Iron Laws 分层**：v4.0 /goal 范式铁律（9 条）与通用工程铁律（7 条）分组
- **§8.5 加注**：brainstorming design approval（方向认可）≠ spec-gate（质量硬审）澄清——两个阶段不重复

## [4.3.0] - 2026-07-01

### Changed — doc-consistency：/goal 分水岭贯穿工作台输出层
- **SKILL §3 step 9**：链路组装加 /goal 分水岭边界（组装到 spec-gate，spec 后 /goal 接管）
- **SKILL §4.3/§4.5**：pipeline 示例从 v3.x 全程 10 步编排改为"造目标段（codesop）+ 跑目标段（/goal）"
- **SKILL §4.4**：auto-proceed 加 spec-gate 边界
- **SKILL §5**：文档判定 gate 明确在 deliver-gate 之后触发
- **SKILL §8.5**："/goal 不可用降级"的 "v8-style pipeline" 改 "codesop pipeline（§3 step 10.5）"（v8 superseded 命名清理）
- **SKILL §3 step 10.5**：衔接任务（创建分支）锚点改 spec-gate 后 + pipeline 适用边界（造目标 + 降级）
- **路由卡 v3→v4**：链路组装分"造目标段（codesop 编排）/ 跑目标段（嵌 /goal 完成条件）"

### Fixed
- v4.0 /goal 范式（v9 加在 §1.1/§8.5/§8.7）此前没贯穿工作台输出层（§3/§4/路由卡仍 v3.x 全程编排口吻），SKILL 内部矛盾（§8 说 /goal 主导 vs §3/§4 说 codesop 全程编排）。本次贯穿

## [4.2.0] - 2026-07-01

### Added — 对抗式审查视角强化
- **verification patch §C.2**: high-risk deliver 前加攻击者视角扫边界 bug（11 类含但不限于：OOM 死循环/未来时间污染/缓存穿透/超大数据/性能炸弹/资源泄漏/并发竞态/权限越界/注入/日志泄敏/降级熔断失效）；复用动态工作流多 agent（AI 自动）+ codex:adversarial-review（用户手动），不另造攻击者 agent
- **low 判定可疑兜底**: deliver 涉鉴权/外部输入/并发/资源/注入面，即使 spec 声明 low 也升级 high 走对抗式
- **双机制都不可用降级**: ultracode 未开 + codex:adversarial-review 未触发 → 至少单 agent 攻击者视角扫（不静默跳过）
- **找到的 bug 进证据包 blocking**: 不清零不交付
- **tests/adversarial-review-behavior.sh**: golden-content 行为测试（11 断言）

### Changed
- 不加新 skill（强化 verification deliver-gate §C.2）；衔接 v9 证据包 + AI 自证循环
- codex 跨模型审不可用（Cloudflare IP 封锁 + Hiddify 代理坏）→ R9 降级人审，补 2 spec 漏洞（边界 bug 类不全 + low 无兜底）

## [4.1.0] - 2026-06-30

### Added — 第一性原理视角强化
- **brainstorming patch**: 加"第一性原理推导"步骤（造方案前从基本事实/约束推，再对比类比方案权衡）；complex/moderate 走，simple/trivial 跳
- **systematic-debugging 强化**: SKILL + 路由卡排查路径加"第一性原理找根因"（强化"无根因不修 bug"铁律，不照搬"类似 bug 这样修"）
- **tests/first-principles-behavior.sh**: golden-content 行为测试（8 断言）

### Changed
- 不加新 skill / 不另造 systematic-debugging patch（prompt 视角内化）
- 叠加 v9 brainstorming（spec 三件 / codex high-risk / 内联 reviewer 不破坏）

## [4.0.0] - 2026-06-30

### Added — /goal 范式（spec-as-goal v9）
- **spec 立住 = 分水岭**：前造目标（codesop+brainstorming），后跑目标（Claude Code `/goal` 主导，codesop 退为验证层）。/goal 是 Claude Code v2.1.139+ 官方命令，codesop 依赖不另造
- **三 gate 降级**：spec-gate 唯一硬审 / plan-gate 默认过+advisory / deliver-gate 风险分级（low 自动 / high 人审）
- **spec-gate rubric 五项**：可验证性 / 反例边界 / 不可缩减边界 / 风险分级校准 / traceability
- **/goal 协同四步**（SKILL §8.7：启动 / 每轮 dispatch 证据包 / 退出接 deliver-gate / 失败码不静默）
- **五条古德哈特防御**：完成条件认外部锚点（测试/lint/diff）不认 AI 自述
- **verification-before-completion patch（新建）**：deliver-gate 风险分级 + 完成条件外部锚点 AND + diff 守护/test weakening + codex high-risk
- **_evidence-pack-schema（新建，setup sibling 同步）**：证据包三块 + 不可缩减边界
- **tests**: spec-as-goal-behavior.sh（R1-R4 行为测试）+ setup-patch-sync.sh（fake 树真跑 setup）

### Changed
- brainstorming patch: spec 产自带三件（完成条件+边界+风险分级）+ codex high-risk 强制不跳过 + 内联 reviewer
- writing-plans patch: simple 跳 plan + 复杂度分流 + emoji→文字口径（满足/没满足/顾虑）
- setup patch_skills: 加 verification 同步 + **schema sibling 同步**（修 v8 子文件盲区，patched SKILL.md 相对引用）
- CLAUDE.md: patches 列表 + Key Gotchas（schema sibling）；PRD: v9 进度 + /goal 决策

### Fixed
- v8 patch_skills 子文件盲区（schema 子文件不同步 runtime）→ v9 schema sibling 同步 + 相对引用

## [3.16.1] - 2026-06-23

### Fixed
- `check_understand_usability` 5 处 `node` 调用包 `_ua_to` timeout 前缀（仿 `check_git_health`，`command -v timeout` macOS fallback）——防 NFS/大文件 `require()` 挂起（CLAUDE.md Key Gotcha #113/#127 + 历史 `ada2445`）。code-review（5-agent）B1 发现。
- `meta_hash` 加 `|| meta_hash=""` 兜底——防 `set -euo pipefail` 下命令替换失败终止进程（latent）。code-review I2。
- `SKILL.md` §3 step 7 注释更正——M1 fix 后"无 node 误判 corrupt"已不成立（函数自兜底 `unknown_head`）+ 提 node timeout。code-review 3-agent 交叉确认。

## [3.16.0] - 2026-06-23

### Added
- 路由表新增「0. 项目理解与导航」大类（understand-chat/diff/explain/onboard）+ 链路组装条件插入规则——接入 [understand-anything](https://github.com/Egonex-AI/Understand-Anything) 作为项目理解/架构认知环节（spec `docs/superpowers/specs/2026-06-22-understand-anything-integration-design.md`）。
- `lib/detection.sh` `check_understand_usability`——7 状态图谱可用性检测（absent/corrupt/unknown_head/stale_on/stale_off/fresh_on/fresh_degraded），含 worktree 重定向、子目录 `show-toplevel`、JSON parser（`autoUpdate===true` 严格）、fingerprints 检查、node 兜底。
- `SKILL.md` §2 Read Order 第 5 条（图谱可用作上下文）+ §3 step 7 detection 调用 + §4.1 7 状态分级提示（stale_on 事实性文案，不断言 hook 坏了）。
- `tests/detect-understand.sh`——21+ 断言真跑（7 状态 + corrupt 变体 + config 字符串 + worktree + 子目录 + 无 node）。
- README 中英「兼容生态：understand-anything」段。
- `lib/updates.sh` `check_routing_coverage` understand-anything marketplace 特判（修路由覆盖误报）。

### Fixed
- 无 node 环境 `check_understand_usability` 不再误判 `corrupt`（node 兜底 → `unknown_head`）。

## [3.15.0] - 2026-06-18

### Changed
- Re-based superpowers patches onto v6.0.3 (brainstorming, writing-plans, finishing); preserves whole-file-overwrite delivery.
- finishing: PR operations now forge-neutral (no hardcoded `gh`); worktree kept after PR for review iteration (adopts upstream Option 2 behavior).
- writing-plans: retains upstream Global Constraints / per-task Interfaces / Task Right-Sizing alongside codesop acceptance-criteria + staged-checkpoint flow.

### Removed
- subagent-driven-development reviewer patches (`spec-reviewer-prompt.md`, `code-quality-reviewer-prompt.md`) — absorbed by superpowers 6.0's merged `task-reviewer-prompt.md`.

### Added
- Re-base checklist doc (docs/superpowers/playbooks/rebase-superpowers-patches.md) — anti-regression + drift handling.

### Fixed
- superpowers `min_version` 5.1.0 → 6.0.3; patches re-apply on 6.0 installs (were silently skipped). v6.0.3 verified compatible — the 3 patched skills are unchanged 6.0.2→6.0.3.

## [3.14.2] - 2026-06-15

### Fixed
- 文档判定 gate 减法纪律自洽性修订（dogfood 自检发现 v3.14.1 的问题）：
  - 去冗余：事故复盘从 3 处收敛到反膨胀清单 1 处（修复规则违反自身"合并优于追加"原则）
  - 补存量红线：加总尺寸警戒（`CLAUDE.md` >300 行/15KB 优先精简），补 neat-freak 第零步（v3.14.1 漏提取）
  - 可执行性：净涨幅改"相对 HEAD 的净增（`git diff --numstat -- <file>`）"，明确边界
- detect-environment.sh 加"总尺寸警戒"断言

## [3.14.1] - 2026-06-15

### Added
- 文档判定 gate 减法纪律（防膨胀）：AGENTS.md 文档职责段加判断标准"看不到会犯错吗" + 三原则（减优于加 / 合并优于追加 / 删除优于保留）；文档判定段加净涨幅红线（CLAUDE.md 净改 >30 行回头审）+ 反膨胀清理清单（5 类该删内容）
- detect-environment.sh 断言 AGENTS.md 模板含减法关键词（减法纪律 / 净涨幅警戒 / 反膨胀清理清单）
- 补全 neat-freak 的减法方向（2026-04-29 doc-gate-enhancement 当年只提取了正向补漏）

## [3.14.0] - 2026-06-12

### Added
- Staged checkpoint flow for complex plans: three-stage output (skeleton → task expansion → self-review)
- Stage 1 writes plan skeleton (AC + task outline, NO code) and saves to file
- Stage 2 expands tasks one at a time with implementation briefs (not full code blocks)
- Stage 3 runs traceability + self-review as a separate re-read operation
- Resume protocol: interrupted sessions can detect last completed stage and continue
- Implementation brief format: design constraints, interface signatures, edge cases, test obligations, critical snippets
- Checkpoint announcements between stages (Stage 1/3, Stage 2/3)
- Implementation briefs are explicitly distinguished from placeholders in No Placeholders section

### Changed
- Complex tasks no longer use full code blocks in plans — replaced with implementation briefs
- Task Structure section labeled as reference format (not used by either complex or lightweight paths)
- Self-Review subagent prompt updated to reference implementation briefs instead of steps
- Lightweight plan comparison table updated to reflect implementation brief format
- Remember section updated: complex tasks use briefs, not complete code
- Pipeline Continuation completion points updated for staged flow

## [3.13.0] - 2026-06-11

### Added
- writing-plans acceptance criteria phase: write verifiable G1..GN before task decomposition
- Two AC formats: full Given/When/Then (behavior changes) and simplified (mechanical edits)
- Adversarial self-check with two questions: implementation laziness + verify command reliability
- Complexity assessment with file/module metrics and override rules (public API, security, etc.)
- Phase split: simple/moderate → lightweight plan (brief guidance); complex → full plan with self-review
- Lightweight plan schema (unified with full plan, implementation_guidance depth field)
- Enhanced self-review with acceptance coverage matrix for complex tasks
- Gap scan (edge cases, regression risk, integration)
- Lightweight plan escalate mechanism for underestimated complexity
- Format classification guidance ("when in doubt, use full format")

### Changed
- Coverage Matrix simplified from mandatory table to one-sentence coverage check rule
- Gap Scan reduced from 6 items to 3 (merged related categories)
- Pipeline Continuation now has tiered completion points by complexity level

## [3.12.2] - 2026-05-31

### Changed
- Router: using-git-worktrees re-enabled as default (was "仅用户明确要求时插入")
- System AGENTS.md: git discipline simplified to branch cleanup + rebase rules (worktree lifecycle managed by Claude Code)

## [3.12.1] - 2026-05-31

### Added
- Git worktree discipline rules in system AGENTS.md: no auto-deleting worktree-bound branches, sync main before rebase, force-with-lease after rebase

## [3.12.0] - 2026-05-29

### Added
- Spec reviewer step compliance: mandatory sub-step enumeration (S1..SN) + Step Compliance Matrix
- Anti-stub detection: disabled UI, empty handlers, hardcoded returns, swallowed exceptions (frontend + backend)
- Complexity proportionality check: >3 sub-steps but <20 lines → flag
- Monolithic step self-decomposition: reviewer breaks complex steps into atomic requirements
- Code quality reviewer implementation depth check: verifies substance not just structure
- setup patch_skills() extended to sync subagent-driven-development reviewer prompt files

## [3.11.0] - 2026-05-27

### Added
- writing-plans spec coverage gate: requirement extraction (R1..RN enumeration) before plan review
- Subagent-based spec coverage check with Traceability Matrix, replacing subjective self-review "skim"
- Calibration examples for ❌/⚠️ coverage assessment in reviewer prompt
- Bounded re-dispatch (max 2 rounds) when coverage gaps are found

## [3.10.2] - 2026-05-11

### Fixed
- Sed injection vulnerability: escape `&`, `\`, `/` in project name during template substitution (`_escape_sed_replacement` helper)
- `codesop update` stash now includes untracked files (`-u` flag)
- Remove dead `executing-plans` reference from writing-plans patch
- Extract `_escape_sed_replacement()` using pure bash parameter expansion (zero forks)
- Document drift fixes: SKILL.md, PRD.md, CLAUDE.md, README.en.md synced

## [3.10.1] - 2026-05-11

### Fixed
- Dependency check: skip superpowers per-host gap for inactive hosts (no more "Codex: 未安装" for Claude-only users)
- Finishing skill patch: add `git fetch --prune` after PR creation to clean stale remote tracking refs

## [3.10.0] - 2026-05-11

### Added
- Completion Gate 文档管理增强：SKILL.md §5 从 3 文档扩展为 5 文档审计（CLAUDE.md / PRD.md / README.md / CONTEXT.md / docs/adr/）
- 结构化审计维度：P1-P5（进度/决策/范围/风险/里程碑）、R1-R4（安装/运行/配置/接口）、C1-C2（术语/冲突）、A1-A2（新增/影响 ADR）
- ADR 模板补全 Status 生命周期字段、Notes 追加段、可变性规则注释
- AGENTS.md 模板输出格式改为 ☐/☑ 可视化 + 维度交叉引用
- `codesop uninstall` 子命令：移除 codesop 集成（保留已安装插件）

### Changed
- AGENTS.md 文档判定输出块去重，改为交叉引用 SKILL.md §5

### Fixed
- 测试断言用表格行格式精确匹配维度标识符，防止裸字符串误匹配
- CLAUDE.md 合并重复的 dependencies.sh 说明行

## [3.9.7] - 2026-05-07

### Fixed
- `upgrade_managed_deps` timeout false-positive: non-patched plugins that are already at latest no longer reported as "failed"
- Patched plugin (superpowers) upgrade gate: skip `claude plugin update` when installed version is already compatible with manifest, preventing accidental major.minor jumps that break patches
- Clarify superpowers version incompatibility warning message

### Changed
- `upgrade_managed_deps` reporting now uses 4 categories: 已升级 / 已是最新 / 超时未变 / 失败
- New `_dep_installed_version()` helper reads plugin version from `installed_plugins.json`
- `_dep_upgrade_one()` uses before/after version comparison to detect successful upgrades despite non-zero exit codes

## [3.9.6] - 2026-05-06

### Fixed
- Restore finishing-branch patch to direct push+PR (skip 4-option menu)
- Fix PR existence check: `grep -qE '^[0-9]+$'` prevents `null` false positive

## [3.9.5] - 2026-05-06

### Fixed
- Write update cache in all `codesop update` exit paths (fork, local-ahead) to prevent stale notifications
- Add `worktree` and `finishing` mentions to README contract check

## [3.9.4] - 2026-05-06

### Added
- New version notification: `/codesop` workbench shows update prompt when a newer version is available (`check_update_notification()`)
- 24h throttled check via `git fetch origin main` + remote VERSION comparison, cached in `~/.cache/codesop/update-cache`
- `CODESOP_NO_UPDATE_CHECK=1` environment variable to skip the check

## [3.9.3] - 2026-05-06

### Fixed
- Added `_ensure_superpowers_version()` guard after `upgrade_managed_deps` — verifies superpowers reached required version before applying patches; retries once with 60s timeout if not

### Changed
- Cleaned up orphan git branches (local + remote)
- Removed stale design artifacts from working tree

## [3.9.2] - 2026-05-05

### Changed
- Removed dead `pip`/`git` code paths from `install_managed_deps()` and `_dep_upgrade_one()` — all 10 deps are plugin type
- Simplified tier failure logic: unconditional `has_required_fail` since all tiers are core/required
- Added `*)` fallback to dep type case blocks to catch future manifest errors
- Fixed `test_helpers.sh` SIGPIPE bug: `printf | grep` under `pipefail` caused flaky test failures on large files
- Compressed PRD Done Recently history (v3.3.2–v3.8.0 → one summary line)
- Updated `dependencies.sh` header to reflect current schema (`type: plugin`, no `optional` tier)

## [3.9.1] - 2026-05-05

### Changed
- README.md major update: added auto-install highlights, removed manual `/plugin install` instructions, added Skill ecosystem table
- Removed `browser-use` and `claude-to-im` from managed dependency manifest — they remain in routing table as optional user-installed skills
- Cleaned `OPTIONAL_SKILLS` and routing coverage report to match manifest scope

## [3.9.0] - 2026-05-05

### Added
- First-time install auto-dependencies: `setup` now auto-installs missing plugins and pip packages
- `install_managed_deps()` in `lib/updates.sh`: idempotent install using same manifest as upgrades

### Changed
- `install_claude()` in setup: sources `lib/updates.sh` and calls `install_managed_deps()` before `patch_skills()`

## [3.8.0] - 2026-05-05

### Added
- Unified dependency upgrade: `codesop update` now auto-upgrades all managed dependencies
- `config/dependencies.sh`: dependency manifest defining type, tier, patch status, min version

## [3.7.1] - 2026-05-05

### Changed
- Rebase superpowers patches onto v5.1.0 upstream

## [3.7.0] - 2026-05-03

### Added
- Git health check in workbench: detect orphan branches and leftover feature branches

## [3.6.0] - 2026-04-30 — README redesign

## [3.5.0] - 2026-04-29 — CONTEXT.md / ADR / architecture principles / domain language

## [3.4.0] - 2026-04-25 — Pipeline branch transition, dead module cleanup (templates.sh, output.sh)

## [3.3.1] - 2026-04-24 — Skill patch mechanism, worktree conditional, pipeline auto re-entry

## [3.0.0] - 2026-04-20 — Sub-agent execution architecture

## [2.6.0] - 2026-04-16 — Task list terminology, pipeline dashboard

## [2.4.0] - 2026-04-12 — Pipeline-to-todo conversion

## [2.2.0] - 2026-04-08 — Git worktree fix, qualified skill names

## [2.0.0] - 2026-04-03 — Remove GStack dependency, rewrite routing table

[1.0.0]: https://github.com/veniai/codesop/releases/tag/v1.0.0
