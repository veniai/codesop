# Product: codesop
# Current Version: 3.5.0
# Last Updated: 2026-04-24
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

- **当前阶段**: stable
- **当前目标**: 稳定维护，按需迭代新能力
- **长期目标**: 让 AI 编码助手在任意项目中有统一的 workflow 纪律和 skill 路由
- **当前里程碑**: v3.5.0 领域语言层 + 架构原则增强
- **完成度**: 100%
- **下一步**: 按需迭代
- **负责人/执行主体**: Mixed
- **最后更新原因**: v3.5.0 发布 — 领域语言层 + 架构原则增强

## 2. 当前进度

### 2.1 In Progress
- 无

### 2.2 Next Up
- 无（按需驱动）

### 2.3 Blocked
- 无

### 2.4 Done Recently
- [x] v3.5.0: 领域语言层 + 架构原则增强 — CONTEXT.md 领域词汇表、ADR 架构决策记录、brainstorming grill patch、跨 skill 领域语言规则、路由卡增强、文档 gate 扩展
- [x] v3.4.1: PR Review 反馈链路补全 — 路由表+SKILL.md+README 三层同步补 receiving-code-review → finishing 反馈路径；含代码库全面清理（删死模块/函数、统一测试、Pipeline 分支衔接）
- [x] v3.3.3: writing-plans skill patch Pipeline Continuation 触发器 — 补回 skill ending 的 next-step 指导
- [x] v3.3.2: pipeline auto re-entry — task list 确认后全程自动执行，不逐个询问
- [x] v3.3.1: skill patch 机制（writing-plans + finishing-branch）、worktree 条件化、setup set -e 修复
- [x] v3.1.0: 移除子 agent 执行架构——去掉 A/B/C 分类、Sub-agent Dispatch、session-state；保留 statusLine + compact 提醒 + v3.0.1 开源基建
- [x] v3.0.2: 路由表分类简化——去掉 B/C，只保留 A 标记（已被 v3.1.0 完全取代）
- [x] v3.0.1: 开源基建补全——tests/run_all.sh、PRD 模板去重、Python→jq、skill.json 补字段、README 国际化
- [x] v3.0.0: 子 agent 执行架构——已被 v3.1.0 移除（冷启动延迟问题）
- [x] v2.6.1: 工作台摘要精简——7 字段 → 2 固定（状态+分支）+ 1 条件（注意）
- [x] v2.6.0: 执行层术语统一为 Claude Code 原生 "task list"（展示层保留 pipeline 概念）
- [x] v2.5.5: 展示层/执行层分离——(☆/★) 标记只留 dashboard，TaskCreate subject 用干净 skill name
- [x] v2.5.4: Pipeline task subject 加入显式 "Skill" 标记（`使用 X Skill 做Y`）
- [x] v2.5.3: Pipeline task subject 指令式格式（`使用 X 做Y`）+ 三层注入 anti-inline 规则
- [x] v2.5.2: §4 输出格式精简（Case A/B/C 合并为 1 个完整示例 + 3 行场景规则，衔接任务一致化，pipeline 编号+完整 skill 名）
- [x] v2.5.1: Pipeline TaskCreate 规范化（顺序创建+blockedBy、skill/衔接任务 subject 格式、re-entry 实际 TaskUpdate）
- [x] v2.5.0: 系统模板加沟通原则，通用约束/铁律去冗余（铁律 6→5 条）
- [x] v2.4.3: Chrome DevTools MCP 纳入路由表和依赖检测（大类 7 重命名 + REQUIRED_PLUGINS 更新）
- [x] v2.4.2: pipeline relevance 判断原则替代枚举式 stale 检测 + PRD 审计遗留修复
- [x] v2.4.1: 链路完整性原则 + 任务卫生铁律 + 调试路径修正（三层同步：路由卡 + AGENTS.md + SKILL.md）
- [x] v2.4.0: Pipeline-to-todo 链路可视化（SKILL.md step 10.5 + pipeline dashboard + re-entry rule）
- [x] v2.0: Superpowers-only backbone，移除 GStack 双引擎 (PR #9)
- [x] 新依赖系统: CORE_PLUGINS / OPTIONAL_PLUGINS / OPTIONAL_SKILLS
- [x] 路由表重写: 13 类 27 skill 生命周期表
- [x] has_plugin() 统一插件检测
- [x] check_routing_coverage() 替代旧 scan_routed_skills()
- [x] AGENTS.md 增加约束冲突和失败处理
- [x] Codex plugin_id double-suffix bug 修复
- [x] 仓库精简: 删除 7 个过时文件，PRD 440→210 行
- [x] has_plugin() JSON 路径 bug 修复（根对象→.plugins）
- [x] AGENTS.md 模板 v1 残留修复（document-release→claude-md-management，移除"检查状态/检查更新"）
- [x] README.md v1 残留修复（覆盖场景更新为 v2 skill）
- [x] Skill 哲学审查：三条原则逐条审查，结论为当前设计已有效

## 3. 最近决策记录

| Date | Decision | Why | Impact |
|------|----------|-----|--------|
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
| 2026-04-03 | v2.0 移除 GStack，Superpowers-only | 双引擎维护成本高，实际只用到 Superpowers | 依赖检测/版本检查/路由表全面重写 |
| 2026-04-03 | 依赖分三层: CORE / OPTIONAL_PLUGIN / OPTIONAL_SKILL | 区分必须和可选，避免强耦合 | lib/updates.sh 重构 |
| 2026-04-06 | 清理 docs/ 和 evals/ 目录 | 历史计划和 spec 已全部落地到代码，保留是噪音 | 文件数 43→35 |
| 2026-04-06 | PRD 精简，移除历史工作日志 | git log 是权威来源，PRD 重复记录无价值 | PRD 440→210 行 |
| 2026-03-30 | `VERSION` 保留为发布版本真相源 | runtime 与 update 流程都需要稳定版本号 | 元数据围绕 VERSION + Unreleased 对齐 |
| 2026-03-30 | 文档纪律默认只判定 CLAUDE.md、PRD.md、README.md | CHANGELOG 更像发布文档，不应进入日常强制集合 | 收尾 gate 只围绕 3 个核心文档 |
| 2026-03-30 | `/codesop` 统一以 SKILL.md 为唯一真相源 | 双份正文会持续漂移 | setup 从 SKILL.md 安装到运行时 |
| 2026-03-30 | 冻结产品合同为 1 套流程 + 2 个命令 | 先收窄边界，避免在噪音上叠功能 | setup 退回内部工具 |

## 4. 版本历史

### **V3.5.0 - 2026-04-29 - (Domain Language Layer + Architecture Principles)**
- **目标**: 增加领域语言层，增强 brainstorming 提问质量，合成 Clean Architecture + 深模块原则
- **变更摘要**:
  - 新增 CONTEXT.md 领域词汇表模板（懒创建）
  - 新增 ADR 架构决策记录机制（懒创建）
  - brainstorming patch：grill 模式（代码优先、决策树追踪、术语对齐）
  - AGENTS.md：跨 skill 领域语言规则 + 架构原则
  - 路由卡：grill 式术语对齐 + 领域语言铁律 + 调试路径架构反思
  - 文档 gate 扩展至三文档 + 可选 CONTEXT.md

### **V3.4.1 - 2026-04-25 - (PR Review Feedback Chain + Codebase Cleanup)**
- **目标**: 补全 PR Review 反馈链路；清理死代码、统一测试框架
- **变更摘要**:
  - PR Review 反馈链路: 路由表加 receiving-code-review → finishing 反馈路径（三层同步：路由卡+SKILL.md+README）
  - SKILL.md 冲突解决表补 review feedback 条目
  - README/README.en Code Review 反馈场景更新
  - 删除死模块: lib/templates.sh、lib/output.sh（find_superpowers_plugin_path 迁入 detection.sh）
  - 删除死函数: detection.sh (7 函数 + 2 数组)、updates.sh (3 项)、init-interview.sh (2 项)
  - 统一测试框架: tests/test_helpers.sh + run_all.sh 失败输出 + 删重复测试
  - Pipeline 分支衔接: main 上开发前插入衔接任务"创建 feat/ 分支"
  - 过时文档修复: 版本标签、死引用、patch 描述对齐

### **V3.3.3 - 2026-04-24 - (Writing-plans Pipeline Continuation Trigger)**
- **目标**: 修复 writing-plans 完成后停止询问的根因——skill ending 缺少 next-step 指导
- **变更摘要**:
  - writing-plans skill patch 新增 Pipeline Continuation 触发器（Self-Review 后 TaskUpdate + TaskList → 下一个）
  - setup patch_skills() 改用 find_superpowers_plugin_path() 替代硬编码路径

### **V3.3.2 - 2026-04-24 - (Pipeline Auto Re-entry)**
- **目标**: pipeline task list 确认后全程自动执行，不逐个询问
- **变更摘要**:
  - SKILL.md: re-entry 从"Ask the user"改为 auto-proceed；§4.4 Continuing 句式删除，保留 Proposing/Stale
  - AGENTS.md: Skill 纪律补 pipeline auto re-entry 规则
  - PRD/CLAUDE.md: 描述同步更新

### **V3.3.1 - 2026-04-24 - (Skill Patch + Worktree 条件化)**
- **目标**: 修复 writing-plans/finishing-branch 阻塞 pipeline 的问题，worktree 退出默认链路
- **变更摘要**:
  - 新增 skill patch 机制：writing-plans 删除 Execution Handoff、finishing-branch 直接 push+PR
  - worktree 从必走改为仅用户明确要求时插入
  - setup 修复 `set -e` 下 `find` 不存在目录的退出码问题

### **V3.1.0 - 2026-04-24 - (回退子 Agent 架构)**
- **目标**: 回退冷启动延迟严重的子 agent 执行架构，保留 statusLine/compact 等好东西
- **变更摘要**:
  - 路由表和 SKILL.md 恢复到 v2.6.1 状态

### **V3.0.0 - 2026-04-20 - (Sub-agent Execution Architecture)**
- **目标**: 解决长 pipeline 会话的 context bloat 问题
- **变更摘要**:
  - 路由表新增"执行方式"列（A/B/C 分类），所有 skill 统一分类
  - SKILL.md 新增 sub-agent dispatch 逻辑、retry template、failure strategy
  - SKILL.md 新增 session-state.md 读写（5 行覆盖模式）
  - AGENTS.md 模板新增 sub-agent 原则和 compact 提醒规则
  - setup 新增 statusLine tee 配置（写入 `/tmp/claude-context.json`）
  - .gitignore 新增 `.codesop/session-state.md`
  - 测试新增 sub-agent dispatch 和执行方式列断言

### **V2.6.1 - 2026-04-17 - (工作台摘要精简)**
- 7 字段 → 2 固定 + 1 条件：**状态**（阶段+进度）、**分支**、**注意**（仅异常）
- 删除长期目标（PRD 已有）、文档状态/阻塞/决策合并为条件字段

### **V2.6.0 - 2026-04-16 - (Task List 术语统一)**
- 执行层全面改用 Claude Code 原生 "task list"（TaskCreate/TaskList/TaskUpdate）
- 展示层保留 "pipeline"（dashboard 显示的 workflow chain 概念）
- §4.4 末行三种句式 + step 10.5 标题/判断/确认/re-entry + §4.4 场景适配 + §4.5 示例，共 15 处改动

### **V2.5.5 - 2026-04-15 - (展示层/执行层分离)**
- step 10.5 spec 明确 TaskCreate subject 不含 (☆/★)，给示例 `code-simplifier:code-simplifier`
- §4.3 format rules 拆成 Dashboard 显示行（带标记）和 TaskCreate subject（不带标记）
- 全面审查：路由卡、AGENTS.md、CLAUDE.md 均无标记泄漏

### **V2.5.4 - 2026-04-15 - (Skill 显式标记)**
- Pipeline task subject 格式加入 "Skill"：`使用 {skill-name} Skill 做{描述}`
- SKILL.md 四处统一（spec + proposing + continuing + complete example）

### **V2.5.3 - 2026-04-14 - (Pipeline Task 指令式格式)**
- Pipeline task subject 从描述式（`X — Y`）改为指令式（`使用 X 做Y`）
- SKILL.md step 10.5 spec、§4.3 proposing/continuing、§4.5 Complete Example 全部统一
- AGENTS.md Skill 纪律：新增 anti-inline 规则
- 路由卡铁律：新增 anti-inline 规则

### **V2.5.2 - 2026-04-14 - (§4 输出格式精简)**
- Case A/B/C 合并为 §4.5 一个完整示例 + §4.4 三行场景适配规则（净删 69 行）
- §4.3 两个示例链路完全一致（proposing/continuing 用同一条链 + 同一个衔接任务）
- 衔接任务："整理审查反馈" → "根据审查反馈修订方案"（行动而非被动整理）
- Skill 名统一为路由表完整名称，pipeline 行带编号
- 测试断言同步更新

### **V2.5.1 - 2026-04-14 - (Pipeline TaskCreate 规范化)**
- step 10.5 新增 Pipeline TaskCreate 规范：skill/衔接任务区分（subject 格式 + metadata）、逐个顺序创建、addBlockedBy 保证顺序
- Re-entry rule：改用 TaskUpdate(completed) 实际标记完成（不再 advisory）、衔接任务自动完成后继续下一个
- §4.3 Pipeline Dashboard：补衔接任务显示格式、示例加衔接任务行

### **V2.5.0 - 2026-04-14 - (Communication Principles + Template Cleanup)**
- 新增沟通原则段：结论先行、不奉承、不过度确认
- 通用约束删除"交付前运行验证命令"（铁律 #4 已覆盖）
- 铁律 #5"流程优先"删除（Skill 纪律 + 冲突解决已覆盖），铁律 6→5 条
- AGENTS.md 模板版本 v2.4.1 → v2.5.0

### **V2.4.3 - 2026-04-13 - (Chrome DevTools MCP)**
- 路由表大类 7 加入 chrome-devtools-mcp（浏览器诊断），重命名为"浏览器工具"
- Playwright 定位描述从"日常页面操作"调整为"页面交互与自动化测试"
- REQUIRED_PLUGINS 加入 chrome-devtools-mcp

### **V2.4.2 - 2026-04-13 - (Pipeline Relevance)**
- SKILL.md step 10.5: stale 枚举改为通用判断原则，比较 pipeline 任务与当前上下文，不对就全清重建
- PRD 审计遗留修复：补 v2.4.1 Done Recently + §5.6 版本号
- §4 header 修复：two-line inline → one field per line

### **V2.4.1 - 2026-04-13 - (Chain Completeness + Task Hygiene)**
- 链路完整性原则：组装链路后检查相邻 skill 之间逻辑断层，自动补充
- 任务卫生铁律：SKILL.md §9 + AGENTS.md + 路由卡三层同步
- 调试路径补 ☆claude-md-management（之前缺）
- README 覆盖场景与路由卡对齐
- 自审修正：SKILL.md step 9 补链路完整性引用

### **V2.4.0 - 2026-04-12 - (Pipeline-to-Todo)**
- SKILL.md step 10.5: 检查 TaskList，检测失效 pipeline（分支/git/意图变化），单次确认创建或继续
- §4.3 pipeline dashboard 替换"推荐/备选链路"，☐/☑ 可视化进度
- §4.4 三种单次确认末行 shape（新 pipeline/继续/检测失效）
- Re-entry rule: 每个 skill 完成后回看 TaskList 提示下一步
- §4.1 工作台摘要改为一行一字段
- 新增 Case C 示例（re-entering /codesop with existing pipeline）

### **V2.3.1 - 2026-04-10 - (Chain Assembly Rules)**
- 路由表链路组装规则替换调试路径，SKILL.md 示例去硬编码

### **V2.3.0 - 2026-04-09 - (Init Adaptation Mode)**
- **目标**: 已有项目可同步模板更新，不全量覆盖
- **变更摘要**:
  - init 适配模式: CLI 输出 ADAPT_MODE:YES 信号，skill 层对比模板与项目文件
  - update 模板变更检测: 拉取新版本后检查 templates/ diff，提示用户重新运行 init
  - SKILL.md 末行疑问句式: "要我用 X 做 Y 吗？" 提升灰色建议命中率
  - 新增 spec + plan 文档: docs/superpowers/specs/ + plans/
  - 测试: 新增 5 个测试（3 个信号测试 + 2 个 CLI 集成测试）

### **V2.2.0 - 2026-04-08 - (Routing Authority + Worktree Fix)**
- 路由权威修正、worktree git 检测修复、skill 全名解析、重复注册清理
- update 后 re-source updates.sh、routing coverage 插件名查找修复

### **V2.2.1 - 2026-04-08 - (Plugin Lookup Fix)**
- has_plugin() 插件名前缀剥离、版本号同步修复

### **V2.0.0 - 2026-04-03 - (Superpowers-only Backbone)**
- **目标**: 移除 GStack 双引擎，Superpowers + curated plugins 单栈
- **变更摘要**:
  - 路由表重写: 13 类 27 skill 生命周期表
  - 依赖系统: CORE_PLUGINS / OPTIONAL_PLUGINS / OPTIONAL_SKILLS 三层
  - 新增 has_plugin(), check_plugin_completeness(), check_routing_coverage()
  - lib/updates.sh 删除 5 个旧函数，新增 5 个新函数
  - SKILL.md 重写: 409→226 行
  - 移除全部 GStack 引用 (lib/, tests/, templates/, commands/)

### **V1.1.5 - 2026-03-31 - (Routing Coverage Fix)**
- 修复路由覆盖检测的系统性误报

### **V1.1.1 - 2026-03-30 - (Bug Fix + Cleanup)**
- 修复 update 命令 bug，清理 ~5500 行死代码

### **V1.1.0 - 2026-03-30 - (Router Card Discipline Layer)**
- SessionStart hook + router card 纪律注入

### **V1.0.0 - 2026-03-25 - (Initial Release)**
- CLI 框架，基础检测和模板生成

## 5. 产品核心规范

### 5.1 核心目标
让 AI 编码助手在任意项目中拥有统一的 workflow 纪律：知道用什么 skill、按什么顺序执行、什么时候该停下来验证。

### 5.2 用户画像
- **目标用户**: 使用 Claude Code / Codex / OpenCode 的开发者
- **核心痛点**:
  - AI 助手跳过测试、review、文档更新等关键步骤
  - 不同 AI 工具间没有统一的 workflow 指导
  - 每次新会话都要重新告诉 AI 项目规则

### 5.3 范围定义
#### In Scope
- 一套主流程：`/codesop` 工作台摘要 + workflow 路由
- 两个机械命令：`codesop init`、`codesop update`
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

### 5.5 产品合同

#### 对外只承诺这 3 个入口
- `/codesop`
- `codesop init`
- `codesop update`

#### 真相源策略
- `/codesop` 内容只保留一个真相源：`SKILL.md`
- `setup` 负责把 `SKILL.md` 安装到 `~/.claude/skills/codesop/SKILL.md`

### 5.6 版本规划
- **Now (v3.3.x)**: 按需迭代，稳定维护
- **Later**: 反馈回路设计 + 可选 Python 模块验证 bash 是否足够

### 5.7 目标架构

```
codesop                     # CLI 入口，只暴露 init / update
setup                       # 宿主安装与同步
├── lib/
│   ├── detection.sh        # 项目与宿主检测
│   ├── updates.sh          # 版本管理与依赖检查
│   ├── commands.sh         # 子命令入口
│   └── init-interview.sh   # Init 交互流程
├── SKILL.md                # /codesop 唯一真相源
├── commands/               # Slash command 文件
│   ├── codesop-init.md
│   └── codesop-update.md
├── config/
│   └── codesop-router.md   # Router card
├── templates/
│   ├── system/             # 系统级模板
│   ├── project/            # 项目级模板
│   └── init/               # Init prompt 模板
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

- **Core plugins**: superpowers, code-review
- **Optional plugins**: skill-creator, frontend-design, context7, code-simplifier, playwright, claude-md-management, codex
- **Optional skills**: codesop, browser-use, claude-to-im
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
- `CHANGELOG.md` 不纳入默认强制集合
- 任一文档需更新时，优先用 `claude-md-management`；若不可用，手动更新
- 输出格式:
  ```
  - CLAUDE.md: 已更新 / 未更新，原因：...
  - PRD.md: 已更新 / 未更新，原因：...
  - README.md: 已更新 / 未更新，原因：...
  ```

## 6. 当前风险与假设

### 6.1 Risks
- **文档纪律执行靠 AI 自觉**: router card 注入规则但没有结构性检查点
- **bash 复杂度上限**: shell 体量继续增长时可能需迁移 Python
- **PRD 文档滞后风险**: 代码和 PR 先行时 PRD 容易落后

### 6.2 Assumptions
- 用户已安装 Claude Code 或 Codex 或 OpenCode 中的至少一个
- superpowers 是推荐的核心 skill 生态，但不是必需的
- bash 足够处理当前复杂度
