# Product: codesop
# Last Updated: 2026-07-11
# Status: active

---

## 0. 使用说明
> 本文档同时承担两种职责：
> 1. 产品主文档：描述当前有效的目标、范围、规则与架构。
> 2. 工作记录：记录当前进度、最近决策与阻塞项。
>
> 更新规则：
> - 长期稳定信息：直接覆盖更新，保持"当前真实状态"
> - 短期流动信息：追加记录，保留时间线
> - 每次任务结束前，检查是否需要更新本文件

## 1. 当前快照

- **当前阶段**: v5 Phase 0 完成（v4.9.3 stable；Phase 1 待启）
- **当前目标**: v5 Phase 0 事实完整性落地完成，Phase 1（Claude 解耦）待启
- **长期目标**: 让 AI 编码助手在任意项目中有统一的核心 workflow 纪律和 skill 路由（编排按宿主能力分级）
- **当前里程碑**: v4.9.3
- **完成度**: v4.9.3 stable（Phase 0 全 done：6.1.1 适配 + fingerprint 门禁 + capability state 4 函数）；v5 spec r3 已 spec-gate approved
- **下一步**: v5 Phase 1（Claude 解耦：拆 core/ + claude-adapter/ + grep 守卫）
- **负责人/执行主体**: Mixed
- **最后更新原因**: v4.9.3 Phase 0 capability state 4 函数（runtime version / manifest hash / capability state / family 汇总）+ 测试

## 2. 当前进度

### 2.1 In Progress
- [ ] v5 自适应治理架构 spec-gate：确认治理内核、三档 profile、宿主适配、第三方 Skill 解耦和 Phase 0 优先级

### 2.2 Next Up
- spec-gate 通过后先做 Phase 0：runtime 版本/hash 完整性、宿主感知 routing coverage、文档漂移修正

### 2.3 Blocked
- 无

### 2.4 Done Recently
- [x] 2026-07-11: 完成强模型/AGI 演进下的 codesop 战略审计，新增 v5 自适应治理架构草案（Policy Kernel + Project Context + Adaptive Orchestrator + Host Adapter + Skill Pack + Evaluation）
- [x] v4.9.0: codesop 减负（feat/v4.9，PR #49）— simple 出口（跳 codex）+ 测试双锚（术语锚 golden-lock + 措辞锁语义化）+ 去重降噪（§9/1% chance/不静默/Skill 生态）+ spec-gate 禁止降级（codesop 自身漏洞修复）+ 8 半锚点全包；Workflow 6-finder + codex 双审 + code-review；run_all 20/0
- [x] v4.8.1: code-review 补漏（feat/v4.8.1，PR #48）— verification §C +/或执行层矛盾 + §8.7 D deliver-gate completed 只认 approved + 抽样 low 不走 ready/approved；3 CONFIRMED 全修；run_all 19/0
- [x] v4.8.0: gate 流程逻辑修正（feat/v4.8，PR #47）— /goal 交接包 + pre-/goal preparation segment 边界统一 + spec-gate Layer 1 白话层 + deliver-gate §8b 可视化 + ready/approved 拆分 + 阻塞语义澄清；router+verification 同步；codex 双 AI 审（设计 + deliver-gate 复核）；run_all 19/0
- [x] v4.7.1: 全方位审查 P2 收尾（feat/v4.7.1）— HOME 守卫（detection/init-interview，hooks/IDE 环境）+ commands docs/adr scaffold + R2 rubric 实质断言（防字段在/实质退化）；codex 完整审查 #7/#9 不动；run_all 19/0
- [x] v4.7.0: 全方位审查 P0+P1（feat/v4.7）— setup jq null guard + §8.7 B 行为测试 + git pull timeout + PRD init/ 删 + F 扩 PRD + schema §10 矛盾；4 agent 扫 + codex 双 AI 验证；run_all 19/0
- [x] v4.6.1: review 修（feat/v4.6.1）— schema §8 注释 + §8.7 B subagent 区分（codesop vs brainstorming）+ serve 消歧（复用 server 非 just-in-time offer）；run_all 18/0
- [x] v4.6.0: spec-gate 可视化重构（feat/v4.6）— §8.7 B dispatch 独立 subagent（交叉检验）+ spec 实质呈现为主（功能地图/改动拓扑/数据流）+ evidence pack 为辅 + completed 认 serve URL + SKILL 去重 -11 行；run_all 18/0
- [x] v4.5.0: spec-gate 归位（feat/v4.5）— spec-gate 人审+可视化从 brainstorming patch 归位 codesop SKILL §8.7 B（架构修正：spec-gate 是 codesop gate）；brainstorming 瘦身（造 spec+自证，到交付 codesop 止）+ §8.7 B 读证据包（防双 dispatch）+ 可视化 serve + schema codesop sibling；codex 审 A' 三点解；run_all 18/0
- [x] v4.4.4: 新项目反馈首批 + 防再犯 E（feat/v4.4.4）— CONTEXT 定位澄清（可选业务领域文档，init 不生成）+ superpowers Codex 输出注明区分（框架宿主端 vs AI 模型）+ consistency-guards E（patch changelog vs CHANGELOG）；run_all 18/0
- [x] v4.4.3: 修 v4.4.2 连带遗漏 + 防再犯 F（feat/v4.4.3）— README/CLAUDE 架构段删已空的 templates/init/（v4.4.2 删孤儿 prompt.md 后悬空）+ consistency-guards F（架构段目录存在校验）；run_all 18/0
- [x] v4.4.2: P2 清理（feat/v4.4.2）— HOME 守卫（commands.sh+install.sh）+ 删孤儿 init/prompt.md + SKILL §8 补 docs/adr + brainstorming v7 hole 清 + README npm 通用化 + CLAUDE 架构补 install.sh；17 问题全清；run_all 18/0
- [x] v4.4.1: P1 清理（feat/v4.4.1）— bare return ×13→return 0/$? + brainstorming three-cycles→spec-gate + writing-plans T6→§8.7 D + spec §8 口差/v8-style + CLAUDE patches 注释补 v4.1/v4.2 + tests/goal-collaboration-behavior.sh（§8.7 协同四步覆盖）；run_all 18/0
- [x] v4.4.0: 全方位诊断 P0 + 防再犯守卫（feat/v4.4）— P0 init 死代码+假绿测试/PRD 版本脱节/schema §4.x 错引/spec 关联悬空 + 防再犯 consistency-guards(A引用/B run_all/C 版本)+init-deadcode-removed(D) + codex 审计划恢复 + run_all 注册 uninstall；run_all 17/0
- [x] v4.3.1: iron-laws 分层 + design approval 澄清（feat/v4.3.1）— §9 Iron Laws 分 v4.0 /goal 范式铁律(9) / 通用工程铁律(7)；§8.5 加注 brainstorming design approval ≠ spec-gate；run_all 15/0
- [x] v4.3.0: doc-consistency（feat/v4.3-doc-consistency）— /goal 分水岭贯穿工作台输出层（§3 step 9 链路组装 + §4.3/4.5 pipeline 示例 + §4.4 auto-proceed + 路由卡链路组装分造目标/跑目标段）+ §5 文档判定 gate 明确 deliver-gate 后 + §8.5 v8-style 命名清理 + §3 衔接任务锚点 spec-gate；修 v4.0 范式没贯穿输出层的内部矛盾；深度核查（逐行 SKILL + 路由卡 + patch）发现 7 处真实张力；run_all 15/0
- [x] v4.2.0: 对抗式审查（feat/adversarial-review）— verification patch §C.2 high-risk deliver 前加攻击者视角扫边界 bug（11 类含但不限于：OOM/未来时间/缓存穿透/超大数据/性能炸弹/资源泄漏/并发竞态/权限越界/注入/日志泄敏/降级熔断失效）+ 复用动态工作流（AI 自动）+ codex:adversarial-review（用户手动）+ 双机制降级单 agent + low 判定可疑升级 high + 找到的 bug 进证据包 blocking；tests/adversarial-review-behavior.sh；simple 路径（spec-gate→跳 plan→实施）；codex Cloudflare+代理坏 R9 降级人审补 2 漏洞；run_all 15/0
- [x] v4.1.0: 第一性原理强化（feat/first-principles）— brainstorming 加第一性原理推导步骤（造方案前从基本事实推）+ systematic-debugging 强化找根因（SKILL/路由卡）+ tests/first-principles-behavior.sh；simple 路径（spec-gate→跳 plan→实施）+ review Approved + run_all 14/0
- [x] v9: spec-as-goal 实施（feat/spec-as-goal）— /goal 范式（spec 立住=分水岭，前造目标/后跑目标）+ 三 gate 降级（spec-gate 硬 / plan-gate 默认过 / deliver-gate 风险分级）+ spec-gate rubric 五项 + /goal 协同四步（SKILL §8.7）+ 抽样人审 + spec 变更重走；patches 加 verification-before-completion（新建）+ _evidence-pack-schema（新建 sibling 同步）+ brainstorming/writing-plans v9 改；tests 加 spec-as-goal-behavior.sh（R1-R4）+ setup-patch-sync.sh（fake 树真跑 setup）；7 task SDD + final review 可 merge + run_all 13/0
- [x] understand-anything 接入（feat/understand-anything-integration）— 路由表新增「0. 项目理解与导航」大类 + `lib/detection.sh` `check_understand_usability`（7 状态可用性检测）+ SKILL §2/§4.1 工作台注意行 + README 兼容生态段 + `tests/detect-understand.sh`；spec 经 codex 三审 + detection 实测（bash -n + 7 状态 + worktree + 子目录）
- [x] v3.10.0: uninstall 子命令 — 安全移除 codesop 安装产物、guard 函数、robust hook 移除、补丁恢复、补丁文件头注释
- [x] v3.9.7: 升级可靠性 — patched 插件门禁（防补丁失效）、非 patched 版本对比（消超时误报）、4 类报告
- [x] v3.9.6: 补丁修复 — 恢复 finishing-branch 直接提交 PR + 修复 PR 存在性检查 null 误判
- [x] v3.9.5: 新版本通知修复 — update 缓存写入补全所有退出路径 + README 契约别名对齐
- [x] v3.9.4: 新版本通知 — 工作台 24h throttled 检查 + 缓存机制，`codesop update` 完成后自动清除通知
- [x] v3.9.3: 升级可靠性 — `_ensure_superpowers_version()` 升级后验证、清理孤立分支
- [x] v3.9.1: 文档与依赖清理 — README 大改（一键安装亮点+Skill 生态表）、移除 browser-use/claude-to-im 托管依赖、路由表精简、代码审查修复（SKILL.md 死引用、macOS 兼容、死代码）
- [x] v3.9.0: 初次安装自动依赖安装 — install_managed_deps() 幂等安装缺失插件，setup 集成替代 warn-only 的 check_discipline_deps
- [x] v3.3.2 ~ v3.8.0: 统一依赖升级、Git 健康检查、README 重设计、pipeline 自动重入、skill patch 机制等（详见 GitHub Releases）
- [x] v2.0: Superpowers-only backbone，移除 GStack 双引擎 (PR #9)

## 3. 最近决策记录

| Date | Decision | Why | Impact |
|------|----------|-----|--------|
| 2026-07-11 | 启动 v5 自适应治理架构设计（待 spec-gate） | 强模型降低过程教学价值，但放大权限、意图、证据和跨宿主一致性问题；当前还存在 repo 4.9 / Claude 4.8.1 / Codex-OpenCode 3.15 runtime 分裂 | 候选方向为最小治理内核 + 三档 profile + 宿主适配 + 按需 Skill + 结果评测；批准前不改变 v4.9 默认行为 |
| 2026-07-05 | codesop 减负（v4.9.0）| 回归初心：Workflow 6-finder + codex 双审找 5 类限制/仪式 | simple 出口 + 测试双锚 + 去重降噪 + spec-gate 禁止降级 + 8 半锚点；code-review + codex 双审全 fix；run_all 20/0 |
| 2026-07-05 | code-review 补漏（v4.8.1）| code-review skill 4-finder 审找 3 CONFIRMED（verification +/或执行层矛盾 / deliver-gate 漏 completed 只认 approved / 抽样 low ready-approved 空转）| SKILL §8.7 D + verification §C + schema §8b 三处同步；run_all 19/0 |
| 2026-07-05 | gate 流程逻辑修正（v4.8.0）| codex 双 AI 审找 5 件事 + 9 漏改 + 3 盲点（/goal 必须手动 / plan 驱动矛盾 / ready-approved 混 / 边界词乱）| /goal 交接包 + 边界统一 + spec-gate Layer 1 白话 + deliver-gate §8b 可视化 + ready/approved 拆分 + 阻塞语义；router+verification 同步；run_all 19/0 |
| 2026-07-03 | P2 收尾（v4.7.1）| v4.7.0 P0+P1 已修，P2 follow-up（codex 完整审查 #7/#9 建议不动）| HOME 守卫（detection/init-interview）+ commands docs/adr scaffold + R2 rubric 实质断言；run_all 19/0 |
| 2026-07-03 | 全方位审查 P0+P1（v4.7.0）| v4.6.1 后全方位审查（4 agent + codex）发现 P0 setup jq null guard + P1（§8.7 B 无测试/git pull timeout/PRD init/ 悬空/schema §10 矛盾）| setup jq guard + §8.7 B 测试 + git pull timeout + PRD init/ 删 + F 扩 PRD + schema §10 改；run_all 19/0 |
| 2026-07-03 | review 修（v4.6.1）| v4.6.0 review 发现 3 处（schema 注释残留 / subagent 混 / serve 歧义）| schema §8 注释 + §8.7 B subagent 区分 + serve 消歧；run_all 18/0 |
| 2026-07-03 | spec-gate 可视化重构（v4.6.0）| 实际工作 Cherry 反馈：spec-gate 可视化主 AI 做（无交叉）+ 内容套 evidence pack（完备性 vs spec 实质做混）| §8.7 B dispatch 独立 subagent + spec 实质为主 + completed 认 serve URL + SKILL 去重；run_all 18/0 |
| 2026-07-03 | spec-gate 归位（v4.5.0）| spec-gate 可视化寄生 brainstorming，AI 混两个 visual companion（设计讨论 just-in-time vs spec-gate 必可视化）→ 不自动可视化 | spec-gate 人审+可视化从 brainstorming 移 codesop §8.7 B（架构修正）+ brainstorming 瘦身 + §8.7 B 读证据包防双 dispatch + 可视化 serve + schema codesop sibling；codex 审 A' 三点解；run_all 18/0 |
| 2026-07-03 | 新项目反馈首批 + 防再犯 E（v4.4.4）| codesop init 新项目反馈：CONTEXT 为啥不生成 + superpowers(Codex) 咋来的 | CONTEXT 定位澄清（可选业务领域文档，init 不生成）+ superpowers Codex 输出注明（框架宿主端 ≠ codex AI 模型）+ consistency-guards E；run_all 18/0 |
| 2026-07-03 | 修 v4.4.2 连带遗漏 + 防再犯 F（v4.4.3）| v4.4.2 删孤儿 templates/init/prompt.md 后 README/CLAUDE 架构段仍列 init/（悬空） | 删 README/CLAUDE init/ + consistency-guards F（架构段目录存在 + 负向 init/）；run_all 18/0 |
| 2026-07-01 | P2 清理（v4.4.2）| v4.4 诊断 P2（6 小问题）清完，17 全清 | HOME 守卫（commands.sh+install.sh）+ 删孤儿 init/prompt.md + SKILL §8 补 docs/adr + brainstorming v7 hole + README npm 通用化 + CLAUDE 架构 install.sh；run_all 18/0 |
| 2026-07-01 | P1 清理（v4.4.1）| v4.4 诊断剩 6 P1（v8 命名残留/bare return/覆盖缺口）清完 | bare return ×13→return 0/$? + brainstorming three-cycles→spec-gate + writing-plans T6→§8.7 D + spec §8 口差/v8-style + CLAUDE patches 注释 + goal-collaboration-behavior §8.7 测试；run_all 18/0 |
| 2026-07-01 | 全方位诊断 P0 + 防再犯守卫（v4.4.0）| v4.3 后全方位诊断发现 17 真实问题（init 死代码+假绿测试/PRD 版本脱节/schema 错引/spec 悬空），根因=测试假绿+跨文件软引用无绑定+聚焦加法没扫存量+codex 跨模型审长期不可用 | P0×4 修复 + 防再犯 consistency-guards(A/B/C)+init-deadcode-removed(D) + codex 审计划恢复双 AI + run_all 注册 uninstall；codex 审计划打回补 5 点；run_all 17/0 |
| 2026-07-01 | doc-consistency：/goal 分水岭贯穿工作台输出层（v4.3.0）| v4.0 /goal 范式（v9 加 §1.1/§8.5/§8.7）没贯穿 §3/§4/路由卡（v3.x 全程编排口吻），SKILL 内部矛盾。逐行核查 SKILL+路由卡+patch 发现 7 处真实张力 | SKILL §3 step 9/§4.3/§4.5/§4.4 + 路由卡链路组装分造目标/跑目标段 + §5 顺序 + §8.5 命名 + §3 衔接任务；run_all 15/0 |
| 2026-07-01 | 对抗式审查视角强化（v4.2.0）| verification 测试过不保证上线稳——边界 bug（OOM/未来时间/注入等）自己写代码想不到。卡兹克第二点 | verification patch §C.2 high-risk deliver 前攻击者视角扫边界 bug（11 类）+ 复用动态工作流/codex:adversarial-review + low 升级兜底 + 双机制降级；不加 skill 强化 deliver-gate；codex 不可用 R9 降级人审补 2 漏洞（边界 bug 类不全 + low 无兜底）|
| 2026-06-30 | 第一性原理视角强化（v4.1.0）| AI 默认类比推理（照搬训练数据相似方案），第一性原理强制从基本事实推。卡兹克第一点 | brainstorming patch 加推导步骤 + SKILL/路由卡 debugging 强化 + tests；不加 skill，prompt 视角内化 |
| 2026-06-29 | /goal 范式：spec-as-goal v9 取代 v8 spec-as-truth | spec 立住后 /goal（Claude Code v2.1.139+ 命令）主导执行，codesop 退为验证层——避免 codesop 与宿主原生执行流重复造轮子；spec 立住前的"造目标"仍归 codesop（brainstorming spec 三件） | SKILL §8.7 /goal 协同四步（启动/每轮 dispatch 证据包/退出 deliver-gate/失败码）+ 三 gate 降级（spec-gate 硬 / plan-gate 默认过 / deliver-gate 风险分级）+ verification-before-completion patch + _evidence-pack-schema sibling 同步；v8 spec-as-truth/plan 标 superseded |
| 2026-06-22 | 接入 understand-anything 作为「0. 项目理解与导航」路由环节 + 7 状态可用性检测 | 12 大类缺"项目理解"环节（靠 brainstorming 兜底且兜不好）；图谱过期/损坏会误导 AI（codex 实证 AIGIS-V5 drift） | 路由表大类 0 + `lib/detection.sh` `check_understand_usability`（absent/corrupt/unknown_head/stale_on/stale_off/fresh_on/fresh_degraded）+ SKILL §2/§4.1 + tests；**stale 降级使用非跳过**；spec 三审 + detection 实测驱动 |
| 2026-04-30 | README 重设计：AI 安装提示 + 痛点开场 + 亮点展示 | 首页无法传达核心价值，AI 安装提示太模糊 | README 中英文全面重写，参考 oh-my-opencode 模式 |
| 2026-05-03 | Git 健康检查：工作台检测孤立分支 + 衔接任务自动清理 | 远程开发后分支残留导致 Git 混乱 | lib/detection.sh + SKILL.md step 7 + step 10.5 |
| 2026-04-29 | 新增领域语言层 + 架构原则增强 | Matt Pocock skills 研究后提取行为，不搬文件 | CONTEXT.md + ADR + grill patch + 深模块原则 |
| 2026-04-09 | 路由表链路组装规则替换调试路径 | AI 照抄 SKILL.md 示例链路，跳过 code-simplifier/claude-md-management | 路由表加链路组装段，SKILL.md 示例去硬编码 |
| 2026-04-12 | pipeline-to-todo: 链路转 TaskCreate 可视化 | AI 频繁遗忘链路中间步骤（simplifier/claude-md） | SKILL.md 加 step 10.5 + pipeline dashboard + re-entry rule |
| 2026-04-13 | 链路完整性原则 + 任务卫生铁律 | AI 盲走链路不检查 gap；task 不清理堆积 | 路由卡加链路完整性原则 + 调试路径补 claude-md；AGENTS.md 加铁律第 6 条 |
| 2026-04-13 | pipeline relevance 判断原则 | 枚举式 stale 检测漏掉"项目阶段已变"信号；旧阶段 task 堆积 | step 10.5 改为通用判断原则，不再枚举具体信号 |
| 2026-04-14 | 系统模板加沟通原则，铁律去冗余 | AI 奉承/过度确认影响效率；通用约束和铁律有重复条款 | 新增沟通原则段，删通用约束验证条款（铁律#4已覆盖），删铁律#5（Skill纪律+冲突解决已覆盖），铁律6→5条 |
| 2026-04-14 | Pipeline TaskCreate 规范化 | AI 创建任务顺序乱、subject 格式不一致、衔接任务没进 task、re-entry 没实际标记完成 | step 10.5 加 TaskCreate 规范（顺序+blockedBy+subject格式+metadata）、re-entry 改 TaskUpdate(completed)+处理衔接任务、§4.3 补衔接任务格式 |
| 2026-04-14 | §4 输出格式精简 | Case A/B/C 与 §4.3 格式示例重复（5 处 pipeline 列出）、衔接任务只出现 1 处、skill 名不真实 | Case 合并为 1 个完整示例 + 3 行场景规则，衔接任务所有示例一致，pipeline 用路由表完整 skill 名 + 编号 |
| 2026-04-14 | Pipeline task subject 指令式格式 + anti-inline 规则 | AI 看到 task subject 描述式格式后 inline 替代 skill 调用 | subject 改为 `使用 X 做Y` 指令式；AGENTS.md + 路由卡 + SKILL.md 三层注入 anti-inline 规则 |
| 2026-04-09 | init 适配模式：三文件存在时走适配而非覆盖 | 模板更新后已有项目无法同步变更 | CLI 输出 ADAPT_MODE:YES 信号，skill 层做对比建议 |
| 2026-04-09 | SKILL.md 末行改为疑问句式（"要我用 X 做 Y 吗？"） | 用户按 Enter 即可确认，提升灰色建议命中 | SKILL.md §4.4 格式变更 |
| 2026-04-09 | update 命令检测模板变更并提示 | 用户不知道模板已更新，遗漏同步 | run_update() 追加 templates/ diff 检查 |
| 2026-04-08 | 路由卡加入 codex 双 AI 审查（设计+代码审查阶段）和文档漂移检查步骤 | 双 AI 互补盲区；文档经常落后于代码 | 路由卡 13→6 类重组，codex:rescue 从应急改为必走 |
| 2026-04-08 | SKILL.md 输出格式收紧（MUST/NEVER 约束） | AI 输出偏离规范（3 行备选、错误标题、嵌套 bullets） | SKILL.md 4.1/4.3 增加 NEVER 约束 |
| 2026-04-08 | has_mcp_server() 检测 fallback | browser-use 通过 pip 安装注册为 MCP server，不在 skills 目录，导致误报 | detection.sh + updates.sh 增加 MCP server 检测路径 |
| 2026-04-07 | `/codesop` 默认前台改为检查当前项目文档状态，而不是 codesop 自检 | 用户进入的是项目工作台，不是 codesop 自身维护面板；对象混淆会降低可理解性 | 工作台摘要新增当前项目文档状态，`codesop` 自检保留为内部维护能力 |
| 2026-04-06 | Skill 哲学审查：不调整铁律/模板/路由表 | 铁律对 AI 消费者直接有效；三套模板反映真实不同的决策结果；★ 标记已够分级 | §2.2 Next Up 清空，按需驱动 |
| 2026-04-06 | has_plugin() 系列函数统一查 .plugins 路径 | installed_plugins.json 结构为 {version, plugins}，旧代码查根对象 | detection.sh + updates.sh 共 5 处修复 |
| 2026-04-03~06 | v2.0 基础架构确立 | 移除 GStack、三层依赖、文档纪律、产品合同冻结 | See GitHub Releases for detail |
| 2026-03-30 | 架构基线确立 | VERSION 真相源 + SKILL.md 唯一源 + 产品合同冻结 | setup 退回内部工具 |

## 4. 版本历史

See [GitHub Releases](https://github.com/veniai/codesop/releases) for full version history. Current version: v4.9.3.

## 5. 产品核心规范

### 5.1 核心目标
让 AI 编码助手在任意项目中拥有**统一的核心 workflow 纪律**：知道用什么 skill、按什么顺序执行、什么时候该停下来验证。编排能力（hook、/goal、patch）按宿主能力分级提供（见 §5.2），不承诺跨宿主行为完全对等，只承诺核心纪律语义一致。

### 5.2 用户画像与能力分级
- **目标用户**: 以 **Claude Code** 为主的开发者；Codex / OpenCode 用户提供核心纪律
- **能力分级**（Claude-first）:
  - **Claude Code（完整）**: router 编排 + SessionStart hook + /goal handoff + superpowers patch + 审计
  - **Codex（核心纪律）**: L0 kernel + 项目文档（AGENTS/PRD/README）+ codesop Skill；编排按 Codex 原生
  - **OpenCode/OpenClaw（核心纪律）**: 同 Codex；安装目标分别验证
- **核心痛点**:
  - AI 助手跳过测试、review、文档更新等关键步骤
  - 不同 AI 工具间没有统一的 workflow 指导
  - 每次新会话都要重新告诉 AI 项目规则

### 5.3 范围定义
#### In Scope
- 一套主流程：`/codesop` 工作台摘要 + workflow 路由
- 三个机械命令：`codesop init`、`codesop update`、`codesop uninstall`
- Router card + SessionStart hook 的纪律注入
- 项目初始化（AGENTS.md / PRD.md / README.md）
- 宿主集成同步与版本更新
- 环境检测与生态依赖检查

#### Out of Scope
- 独立的 `status` / `diagnose` 产品面
- AI 模型选择或配置
- 具体项目的业务逻辑
- 非 Claude Code / Codex / OpenCode 的宿主支持

### 5.4 核心功能
- **`/codesop` skill**: 工作台摘要 + 工作流路由，读取项目上下文并组织下一步工作流链
- **`/codesop` 收尾格式**: pipeline dashboard 展示链路进度（☐/☑），首次确认时末行输出疑问句（"要把这个 pipeline 转成 task list 并从 X Skill 开始做 Y 吗？"），用户按 Enter 确认后全程自动执行
- **Pipeline-to-todo**: 链路组装结果转 TaskCreate 任务列表，失效检测（分支/git/意图变化时自动重新路由），auto re-entry（每个 task 完成后自动执行下一个，不逐个询问），skill patch 为关键 skill 补 next-step 触发器（如 writing-plans Pipeline Continuation）
- **文档漂移扫描**: 在路由前先判断当前项目的 `CLAUDE.md` / `PRD.md` / `README.md` 是否已经落后于代码与当前状态，并把必要的文档更新编进下一步工作流链
- **Router card**: SessionStart hook 注入纪律表，强制 AI 遵循必走 skill pipeline
- **`codesop init`**: 检测项目技术栈，生成 `AGENTS.md` / `PRD.md` / `README.md`；已有项目自动进入适配模式，对比模板差异由用户确认
- **`codesop update`**: git pull + 自动重同步宿主集成
- **`codesop uninstall`**: 移除 codesop 安装产物（symlink/hook/commands/runtime），恢复 superpowers 补丁，不动已装插件

### 5.5 产品合同

#### 对外只承诺这 3+1 个入口
- `/codesop`
- `codesop init`
- `codesop update`
- `codesop uninstall`

#### 真相源策略
- `/codesop` 内容只保留一个真相源：`SKILL.md`
- `setup` 负责把 `SKILL.md` 安装到 `~/.claude/skills/codesop/SKILL.md`

### 5.6 版本规划
- **Now (v3.9.x)**: 稳定维护，按需迭代
- **Later**: 反馈回路设计 + 可选 Python 模块验证 bash 是否足够

### 5.7 目标架构

```
codesop                     # CLI 入口，暴露 init / update / uninstall
setup                       # 宿主安装、同步与卸载
├── lib/
│   ├── detection.sh        # 项目与宿主检测
│   ├── updates.sh          # 版本管理与依赖检查
│   ├── commands.sh         # 子命令入口
│   └── init-interview.sh   # Init 交互流程
├── SKILL.md                # /codesop 唯一真相源
├── commands/               # Slash command 文件
│   ├── codesop-init.md
│   ├── codesop-update.md
│   └── codesop-uninstall.md
├── config/
│   └── codesop-router.md   # Router card
├── templates/
│   ├── system/             # 系统级模板
│   └── project/            # 项目级模板
├── docs/                   # 设计 spec + 实施计划
│   └── superpowers/
│       ├── specs/          # 已批准的设计文档
│       └── plans/          # 实施计划
└── tests/                  # 内核合同测试
```

**模块加载顺序**: detection → updates → commands → init-interview

**宿主集成**:

| Host | Config Target | Commands | Hook |
|------|--------------|----------|------|
| Claude Code | `~/.claude/CLAUDE.md` → symlink → `templates/system/AGENTS.md` | `~/.claude/commands/` | SessionStart hook |
| Codex | `~/.codex/AGENTS.md` | `~/.codex/commands/` | — |
| OpenCode | `~/.config/opencode/AGENTS.md` | — | — |

### 5.8 生态依赖

- **Core**: superpowers (backbone, patches applied)
- **Required**: code-review, skill-creator, frontend-design, context7, code-simplifier, playwright, claude-md-management, chrome-devtools-mcp, codex
- 版本检查: 仅 superpowers 支持 GitHub tags 对比，其他仅检测存在性

### 5.9 技术实现规范

- `set -euo pipefail` 在入口脚本中，管道命令用 `|| true` 或 `|| fallback`
- `bare return` 继承前命令退出码，必须用 `return 0` 显式返回
- `git fetch` 用 `timeout` 包裹防挂起
- `wc -l` 输出有前导空格，管道 `tr -d ' '` 后再算术
- Hook 配置用 jq 嵌套 schema，幂等运行不重复 hook

### 5.10 文档纪律机制

- 默认判定文档: `CLAUDE.md`, `PRD.md`, `README.md`
- `AGENTS.md` 保持薄包装 `@CLAUDE.md`
- `CHANGELOG.md` 不纳入默认强制集合（版本历史见 GitHub Releases）
- 任一文档需更新时，优先用 `claude-md-management`；若不可用，手动更新
- 输出格式见 SKILL.md §5 Completion Gate（☐/☑ 可视化格式，含 CONTEXT.md 和 ADR 条件行）

## 6. 当前风险与假设

### 6.1 Risks
- **跨宿主 runtime 漂移**: 仓库、Claude、Codex/OpenCode 可运行不同代际的 SKILL，现有检查仍可能报告覆盖完整
- **强模型受过程约束**: 固定任务对齐块、simple spec-gate、强制 HTML 和过度 Skill 触发可能增加成本并压缩模型自主判断
- **缺少结果评测**: 当前测试主要保护安装和文本合同，尚不能证明 full workflow 相对宿主原生 baseline 的质量收益
- **文档纪律执行靠 AI 自觉**: router card 注入规则但没有结构性检查点
- **bash 复杂度上限**: shell 体量继续增长时可能需迁移 Python
- **PRD 文档滞后风险**: 代码和 PR 先行时 PRD 容易落后

### 6.2 Assumptions
- 用户已安装 Claude Code 或 Codex 或 OpenCode 中的至少一个
- superpowers 是推荐的核心 skill 生态，但不是必需的
- bash 足够处理当前复杂度
