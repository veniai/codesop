# codesop v5 自适应治理架构

**日期**：2026-07-11  
**状态**：Draft，待 spec-gate 评审  
**定位**：从「为弱模型规定编码步骤」转向「为强 Agent 声明意图、权限、风险和证据要求」  
**替代范围**：本 spec 只定义 v5 目标架构与迁移顺序；v4.9 在 v5 默认启用前继续作为稳定版本维护

## 1. 背景与问题

codesop 最初解决的是模型容易忘步骤、跳测试、误用 Skill 和丢失项目上下文。随着模型与宿主原生编排能力增强，项目已经从全程 pipeline 转向「spec 前造目标、spec 后由 `/goal` 跑目标、codesop 退到验证层」。方向正确，但当前实现仍把三类不同性质的内容绑在一起：

1. **长期不变量**：用户优先级、权限边界、安全、证据后声明。
2. **项目事实**：架构、命令、产品目标、领域语言和决策。
3. **宿主过程**：任务对齐块、Skill 路由、TaskList、`/goal`、HTML gate、subagent 证据包。

绑定后的直接后果：

- Claude Code 每次会话常驻加载全局契约和 router；过程细节占用上下文并影响自然交互。
- simple 任务仍可能进入 spec 和人审仪式，流程成本与风险不成比例。
- `1% chance` Skill 规则会随 Skill 数量增长而过度触发。
- Claude 专属的 `/goal`、SessionStart 和插件路径混入跨 Agent 产品核心。
- 第三方 Skill 通过覆盖文件打补丁，升级兼容和行为归属不清晰。
- 仓库、Claude runtime、Codex/OpenCode runtime 可以处于不同版本，但现有生态检查仍报告「路由覆盖完整」。
- 现有 20 套测试擅长保护文本契约和安装行为，尚不能回答「启用 codesop 是否比宿主原生更可靠、更省成本」。

## 2. 第一性原理

任何正确的 v5 方案都必须满足以下事实：

1. **模型能力会持续变化，用户意图不会自动变得明确**。模型更聪明不能替代用户对目标、范围和风险的定义。
2. **自主性越高，越需要权限和可验证结果**。强 Agent 减少的是过程教学，不是授权、审计和外部证据。
3. **宿主能力天然不同**。跨 Agent 复用必须复用语义，不能假设每个宿主都有 `/goal`、Claude hooks 或相同 Skill 注册机制。
4. **上下文是有限资源**。常驻内容只应包含每次任务都成立、缺失会造成真实风险的信息。
5. **流程成本应与风险和不确定性成比例**。文件数只能辅助判断，不能作为风险的唯一代理。
6. **Prompt 文本不是可靠护城河**。长期价值来自策略模型、宿主适配、评测集和真实反馈。

## 3. 方案比较

### 方案 A：继续在 v4 上逐条减负

保留当前 SKILL、router、patch 和 gate 架构，只增加更多 simple 出口并继续去重。

- 优点：改动小，兼容风险低。
- 缺点：无法解决跨宿主耦合、第三方覆盖、运行时分裂和「规则只能增加出口」的问题。
- 结论：适合作为 v5 迁移期维护策略，不适合作为目标架构。

### 方案 B：分层治理内核 + 自适应编排（推荐）

将稳定语义与宿主机制拆开：最小治理内核常驻，项目事实按需读取，路由器根据风险、歧义和宿主能力生成工作流，具体 Skill 与宿主命令延迟加载，评测系统决定规则去留。

- 优点：能力越强流程越薄；可跨 Agent；能用数据判断限制是否值得。
- 缺点：需要兼容层和分阶段迁移，短期会同时维护 v4 与 v5 profile。
- 结论：唯一同时满足可移植、可演进和可验证的方案。

### 方案 C：只做 Skill 安装器，取消治理和编排

codesop 只安装精选 Skill，把任务判断完全交给宿主模型。

- 优点：最轻，维护面最小。
- 缺点：失去跨项目意图、权限、证据和组织记忆；无法解释启用前后的质量差异。
- 结论：可作为 `minimal` profile 的下限，不作为完整产品方向。

## 4. 目标架构

```text
用户意图 / 项目状态
        |
        v
+-----------------------------+
| L0 Portable Policy Kernel   |  稳定不变量：权限、安全、证据、升级人
+-----------------------------+
        |
        v
+-----------------------------+
| L1 Project Context Contract |  CLAUDE/PRD/README/CONTEXT/ADR 的职责和按需读取
+-----------------------------+
        |
        v
+-----------------------------+
| L2 Adaptive Orchestrator    |  风险 + 歧义 + 影响面 + 宿主能力 -> profile
+-----------------------------+
        |                         \
        v                          v
+----------------------+   +----------------------+
| L3 Host Adapter      |   | L4 Skill Pack        |
| Claude/Codex/OpenCode+|  | 按需加载、组合、不覆盖 |
+----------------------+   +----------------------+
        \                         /
         v                       v
        +-------------------------+
        | L5 Evidence & Evaluation|  外部信号、A/B 基准、shadow mode
        +-------------------------+
```

### 4.1 L0 Portable Policy Kernel

常驻于各宿主全局指令，只保存跨项目、跨宿主、跨模型都成立的不变量：

- 用户指令和明确授权优先。
- 只改任务范围内内容，不泄露或硬编码凭据。
- 冲突、失败和不确定性必须显式报告。
- bug 修复需要根因证据；完成声明需要新鲜验证证据。
- 高风险、不可逆或外部影响操作需要升级人。

不得包含 Skill 名、宿主命令、固定输出格式、文档细表、Git 命令序列或 UI 呈现规则。

### 4.2 L1 Project Context Contract

项目文档继续存在，但职责严格分离并按任务需要读取：

| 文档 | 唯一职责 | 默认加载 |
|------|----------|----------|
| `AGENTS.md` | 薄入口，指向项目工程说明 | 是 |
| `CLAUDE.md` | 怎么造：架构、命令、依赖、约束 | 是 |
| `PRD.md` | 造什么：目标、范围、进度、决策 | 路由/设计时 |
| `README.md` | 怎么用：安装、运行、配置、接口 | 使用方式相关时 |
| `CONTEXT.md` | 领域术语和定义冲突 | 复杂领域任务时 |
| `docs/adr/` | 已批准的架构决策 | 架构/跨模块任务时 |

短期任务状态进入宿主 Task/Goal 状态，不把 PRD 变成逐步执行日志。

### 4.3 L2 Adaptive Orchestrator

路由器不再输出一条默认完整 pipeline，而是先生成 `TaskAssessment`：

```text
intent       = explore | change | debug | review | ship
risk         = low | medium | high
ambiguity    = low | high
blast_radius = local | cross-module | external
host         = capabilities actually available in this session
profile      = minimal | standard | governed
reason       = one concise, inspectable rationale
```

profile 规则：

| Profile | 适用条件 | 默认行为 |
|---------|----------|----------|
| `minimal` | 低风险、低歧义、局部、可回滚 | 直接执行；测试/检查 + diff 验证；不强制 spec、TaskList 或人审 |
| `standard` | 中等影响面、需求需澄清、多个依赖步骤 | 轻量目标说明；必要时 plan；阶段末独立验证 |
| `governed` | 安全、权限、数据迁移、公共接口、部署、破坏性或外部影响 | 正式 spec；人审目标；独立复核；机械证据；明确回滚 |

文件数量只作为 blast radius 的一个信号。鉴权、迁移、部署等任务即使单文件也进入 `governed`。

治理必须区分三个责任面，不能继续只靠 Agent 自律：

| 责任面 | 作用 | 信任边界 |
|--------|------|----------|
| **Policy Decision Point (PDP)** | 根据项目策略和 `TaskAssessment` 计算最低 profile、必需证据与审批要求 | Agent 可以提交 assessment 或请求升档，但不能把策略算出的最低档位降级 |
| **Policy Enforcement Point (PEP)** | 用宿主 sandbox、审批、hook/command gate 或完成状态机执行不可绕过的要求 | `required/approval/forbidden` 规则由宿主或人执行，不能由干活 Agent 自己宣布跳过 |
| **Audit** | 记录 assessment、实际 profile、能力选择、证据和批准者 | 写入受控的本地 codesop 状态目录；默认不写项目、不上传外部 |

策略动作分四类：`advisory`（Agent 可选择方法）、`required-evidence`（缺证据不能声明完成）、`approval-required`（缺人或宿主批准不能执行）、`forbidden`（宿主直接拒绝）。模型能力只影响 advisory 的实现方式，不能覆盖后三类。信息不足时 PDP 选择更高的安全档位或升级人；任何自动降档都视为策略错误。

### 4.4 L3 Host Adapters

宿主适配器只负责把统一语义翻译为本地能力：

- Claude Code：`/goal`、SessionStart hook、Claude plugin registry。
- Codex：原生计划/目标、可用 Skill catalog、Codex 审批与 sandbox。
- OpenCode-compatible：OpenCode 与 OpenClaw 共享 adapter 语义，但分别验证各自的安装目标和 Skill 生命周期。

核心层只请求「持续执行直到完成条件」「列出当前可调用能力」「产生独立复核」等语义，不直接引用 `/goal` 或某个宿主路径。能力缺失时必须选择同语义降级或显式报告，不能假装调用成功。

### 4.5 L4 Skill Pack

- Skill 默认按需加载，不再使用 `>=1%` 的主观触发阈值。
- Router 匹配提供候选；模型可在 `advisory` 能力中选择或跳过并给出理由，但不能跳过 PDP 指定的必需能力，也不能自行降低 profile。
- 项目优先使用上游 Skill；codesop 扩展通过 wrapper、companion policy 或版本化 fork 提供。
- v5 默认不覆盖第三方插件缓存中的 `SKILL.md`。
- Skill 是否存在以当前宿主实际可调用结果为准，不以另一宿主的安装清单代替。

### 4.6 L5 Evidence & Evaluation

证据分成三层：

1. **Mechanical**：测试、lint、类型检查、构建、diff、运行时健康检查。
2. **Independent review**：不同上下文或不同模型对需求覆盖、边界和风险复核。
3. **Human judgment**：目标语义、权限、产品取舍和高风险交付。

`minimal` 默认只要求适用的 mechanical 信号；`standard` 在阶段边界增加独立复核；`governed` 组合三层。不得把 HTML 页面、固定文案或同模型自述当作完成证据。

评测系统使用同一批真实任务比较：

- 宿主原生 baseline。
- 仅启用 L0 kernel。
- 启用 v5 自适应编排。
- v4 full workflow（迁移期对照组）。

核心指标：任务成功率、回归缺陷、token、耗时、人工干预次数、误路由率、无效 Skill 调用数和高风险漏拦截数。每个任务固定初始仓库、模型版本、宿主版本和成功 oracle；非确定性路径至少重复 3 次并报告离散度或置信区间。评测数据默认只保存在本地，不上传代码或 Prompt。

## 5. 功能需求（每条含三件）

### R1. 最小可移植治理内核

- **完成条件**：全局模板不超过 50 行且不超过 4KB；结构校验确认七类不变量存在，代表性场景验证其实际行为；自动检查其中不存在具体 Skill 名、`/goal`、固定输出章节或 Git 命令序列；Claude、Codex、OpenCode-compatible 三个 adapter family 安装的 kernel 内容一致。
- **边界**：不得通过删除用户优先级、任务范围、安全、失败披露、根因、验证证据和高风险升级人七类不变量来满足尺寸限制；行数和字节数不能替代行为测试。
- **风险分级**：high。改变所有宿主的常驻行为和安全下限。

### R2. 任务定位由可见仪式改为按需呈现

- **完成条件**：所有任务都生成机器可检查的 `TaskAssessment`；`minimal` 的明确任务不向用户强制展示「理解 + 阶段 + Skill」，歧义任务、高风险任务和用户显式调用 `/codesop` 时展示 assessment 摘要；场景测试覆盖三种呈现条件。
- **边界**：隐藏呈现不得隐藏 assessment 本身；不得以减少输出为由跳过高风险识别，审计中必须能还原 profile 的输入和理由。
- **风险分级**：medium。影响交互合同，但不改变生产代码安全边界。

### R3. 宿主感知的能力与版本完整性

- **完成条件**：对每个已安装宿主目标分别报告仓库版本、runtime 版本、manifest hash 和 capability state；状态固定为 `healthy/stale/absent/unknown`；会话内由宿主 catalog/probe 证明可调用性，会话外无法探测时标 `unknown`；family 汇总只有在其全部已安装目标均 `healthy` 时才为 healthy，任一目标 stale/unknown 都必须显式上浮；必需能力不可调用时不得输出「覆盖完整」。
- **边界**：不能用文件存在或 Claude 插件清单代替其他宿主的可调用性；hash manifest 必须覆盖 kernel、codesop runtime、adapter 和路由策略；未安装目标为 `absent`，不阻塞已安装目标健康退出；OpenCode healthy 不能掩盖 OpenClaw stale，反之亦然。
- **风险分级**：high。跨宿主错误路由会导致流程静默缺失。

### R4. 三档自适应 profile

- **完成条件**：至少 12 个基础场景和一组相邻边界/组合风险场景覆盖 `minimal/standard/governed`；其中单文件鉴权和数据迁移必须为 `governed`，局部文案和低风险配置说明必须为 `minimal`；每次判断产出结构化 assessment，是否展示 reason 由 R2 决定。
- **边界**：不得只按文件数量或逐例硬编码分档；缺少风险信息时不能默认 `minimal`；Agent 只能升档或请求人裁决，不能低于 PDP 计算的 profile floor。
- **风险分级**：high。分档决定哪些 gate 可以省略。

### R5. 结果约束取代过程微管理

- **完成条件**：`minimal` 不强制 spec、TaskList、固定四段输出、HTML serve 或独立 subagent；`governed` 仍要求正式目标、风险边界、机械证据和人审；行为测试分别证明轻路径和重路径。
- **边界**：所有 profile 在声称完成前都必须有与变更相称的新鲜验证证据；bug 路径仍需要根因。
- **风险分级**：high。直接改变当前铁律和 gate 行为。

### R6. Skill 延迟加载与可解释跳过

- **完成条件**：全局和 codesop Skill 中不再出现 `1% chance` 规则；每个 profile 定义必需能力集合和 advisory 候选；审计记录候选、实际加载、跳过 reason 与缺失状态；关键场景验证必需能力召回，缺失时按策略升档、替代或阻断。
- **边界**：不得以「永远不加载 Skill」满足延迟加载；高风险任务需要的验证或安全能力不能无理由跳过；「模型更强」本身不是跳过证据。
- **风险分级**：medium。减少上下文和仪式，可能暴露路由漏判。

### R7. 宿主专属机制隔离

- **完成条件**：核心 policy/router 不含 `/goal`、Claude hook 路径或 `installed_plugins.json`；这些引用只存在于 Claude adapter；Claude、Codex、OpenCode-compatible 三个 adapter family 各有能力检测、PEP 映射和降级测试，OpenCode 与 OpenClaw 安装目标分别验证。
- **边界**：隔离不等于删除 Claude 的成熟能力；Claude 用户在相同 profile 下仍能使用 `/goal`。
- **风险分级**：high。涉及架构边界和三个 adapter family 的行为。

### R8. 停止覆盖第三方 Skill

- **完成条件**：全新 v5 安装默认不修改插件缓存中的第三方 `SKILL.md`；建立现有 patch 关键行为到 wrapper/companion 的对等矩阵并全部通过；`v4-compat` 通过 codesop 自有版本化实现提供；现有 patch 行为有显式迁移报告；卸载不再需要恢复第三方文件。
- **边界**：在替代 wrapper/companion 未覆盖现有关键行为前，不移除 v4 patch 兼容模式。
- **风险分级**：high。迁移错误会丢失当前 spec/verification 行为。

### R9. 文档职责与动态状态分离

- **完成条件**：初始化模板和检查器能识别 CLAUDE/PRD/README/CONTEXT/ADR 的职责错位；PRD 不再要求保存逐任务执行日志；短期状态由宿主 task/goal 管理；至少 5 个漂移场景有实质测试而非只检查文件存在。
- **边界**：不得删除产品范围、重要决策或架构约束；Git 历史不能替代当前有效事实。
- **风险分级**：medium。影响项目初始化和长期上下文质量。

### R10. 结果导向评测基线

- **完成条件**：建立不少于 20 个可重复任务的本地评测集，至少覆盖小改、bug、跨模块、公共接口、安全和文档任务；同任务在隔离的相同初始状态下运行 baseline/kernel/v5/v4 四组；固定模型/宿主版本和成功 oracle，非确定性路径至少重复 3 次并输出统一指标与离散度。
- **边界**：不得用 grep 命中率、Prompt 长度或单次运行替代任务正确率；评测不得默认上传用户代码、Prompt 或凭据；规则淘汰不能只依赖一个成本指标。
- **风险分级**：high。评测结果将决定规则删除和默认 profile。

### R11. Shadow mode 与规则淘汰机制

- **完成条件**：v5 在不改变实际工作流时，把「拟选择的 profile/Skill/gate」写入项目外的受控本地审计目录；规则至少积累 30 个适用决策、覆盖至少 2 个模型/宿主配置且多指标无安全回归后，才能标记为降级候选；任何规则退役必须人审批准并记录证据和回滚点。
- **边界**：shadow mode 不得写项目、发外部请求或阻塞用户任务；样本不足不能提出退役；安全、授权和高风险升级规则不能自动删除。
- **风险分级**：high。观测本身低风险，但结果会影响生产治理规则去留。

### R12. 兼容、回滚与用户控制

- **完成条件**：配置明确区分 `engine_mode=v4-compat|v5`、项目 profile 偏好和每任务 PDP profile floor；升级前输出行为差异；一次命令可恢复上一个已知可用配置；迁移测试覆盖升级、降级和混合宿主。
- **边界**：项目偏好不能把任务降到 PDP floor 以下；自适应逐任务选档不视为静默切换 engine mode，但 assessment 必须进入审计；回滚不得删除用户项目文档、第三方插件或未提交工作。
- **风险分级**：high。关系到安装状态和用户数据安全。

## 6. 非目标

- 不构建新的通用 Agent runtime 或替代 Claude Code/Codex/OpenCode。
- 不选择或托管模型，不代理模型 API。
- 不承诺用 Prompt 保证绝对正确；只提高可控性和可验证性。
- 不取消所有人审；只让人审集中在目标语义、权限和高风险交付。
- 不在 v5 第一阶段迁移 bash 到其他语言；先验证边界，再决定实现技术。
- 不把所有宿主能力强行做成最低共同功能集。

## 7. 迁移路线

### Phase 0：恢复事实完整性（v4.9.x）

目标：先确保「运行的就是以为在运行的版本」。

- 修正开发/发布同步命令，默认一次刷新所有已安装宿主。
- 增加每个已安装宿主目标的 runtime version + manifest hash 检查，并按最差目标状态汇总 adapter family。
- 让 routing coverage 基于当前会话的 authoritative capability probe；会话外不可探测时报告 `unknown`。
- 修正文档中 v4.9 与旧 pipeline 的漂移。

**退出条件**：所有已安装宿主目标的 runtime 与仓库一致；同一 family 内任一目标 stale/unknown 都会上浮；stale runtime 测试必红；当前宿主缺 Skill 或能力为 `unknown` 时不再报告覆盖完整；未安装目标不阻塞退出。

### Phase 1：抽取内核与 profile（v5 alpha）

目标：不删除 v4 能力，先建立新边界。

- 抽取 L0 kernel、HostCapabilities 和 TaskAssessment。
- 定义 PDP/PEP/Audit 合同，完成三个 adapter family 的最低能力映射和安装目标测试。
- 实现三档 profile 与固定场景判定。
- 保留 v4 workflow 作为 `v4-compat`。
- 建立不少于 12 个代表任务的最小评测基线，每个 profile 至少 4 个，并覆盖鉴权/安全、数据迁移、公共接口、部署/破坏性外部影响等主要 high-risk override；固定初始状态、oracle、模型和宿主版本。
- 上线 shadow mode，只写项目外本地审计，不改变默认执行。
- 实现 `engine_mode` 配置和一键回滚的最低可用版本。
- 对每个 adapter family 做 PEP 端到端阻断测试：缺 required evidence 不能完成、缺 approval 不能执行、forbidden 操作被拒绝；宿主没有原生 PEP 时必须报告 unsupported 并阻断或升级人，不能以 Prompt 模拟强制成功。

**退出条件**：PDP 不能被 Agent 自行降档；PEP 的合同测试和端到端真实阻断测试均通过；三个 adapter family 的最低合同通过；最小评测覆盖三档和全部主要 high-risk override 且可重复运行；回滚实测通过；shadow 结果可解释；v4 全套测试继续通过。

### Phase 2：自适应流程成为默认（v5 beta）

目标：让低风险任务真正变轻，高风险任务保持下限。

**入口条件**：Phase 1 全部退出条件满足；最小评测覆盖每个 profile 和全部主要 high-risk override；shadow 至少覆盖 30 个适用决策及 2 个模型/宿主配置，其中每个 profile 不少于 5 个；已安装宿主 adapter 的真实 PEP 阻断、降级、审计和一键回滚可用。

- `minimal` 取消可见任务对齐块、spec-gate、固定输出和强制 HTML。
- `standard` 使用轻量目标和阶段末复核。
- `governed` 保留正式 spec、人审、独立复核和机械证据。
- SessionStart 默认只注入 kernel，不注入完整 router；router 按需读取。

**退出条件**：在 Phase 1 最小评测上，低风险任务 token/耗时相对 v4 中位数下降至少 30%；任务 oracle 成功率同时不劣于宿主 baseline 和当前 v4；high-risk override 误判为轻路径为 0，且高风险漏拦截不高于 v4；默认切换后至少 20 个适用任务的观察窗口内无 PEP 绕过，且可一键回滚。

### Phase 3：Skill 与宿主解耦（v5 RC）

目标：停止依赖覆盖第三方文件和 Claude 专属语义。

- 将 patch 行为迁入 wrapper/companion policy。
- 扩展 Claude/Codex/OpenCode-compatible adapter 合同测试，分别覆盖 OpenCode 与 OpenClaw 安装目标。
- 新安装默认关闭 patch；老安装保留可回滚兼容期。

**退出条件**：全新安装不改第三方缓存；patch-to-wrapper 关键行为对等矩阵全过；三个 adapter family 完成同一场景集且 OpenCode/OpenClaw 安装目标分别通过；新老安装的 `v4-compat` 均可用；卸载不恢复第三方文件。

### Phase 4：评测驱动稳定版（v5 stable）

目标：让规则增删有结果证据。

- 将 Phase 1 最小基线扩展为不少于 20 个任务，发布四组本地对照报告。
- 建立规则收益记录和废弃流程。
- 根据模型/宿主能力提供 profile 默认值，不按品牌硬编码质量假设。

**退出条件**：不少于 20 个任务按 R10 重复策略完成基线；每条强制规则能指向风险或评测证据；规则退役均经人审；无证据的过程规则已删除或降级为建议。

## 8. 兼容策略

- v4 spec-as-goal 文档保留为历史设计，不就地改写。
- v5 alpha/beta 默认不自动迁移现有项目；先提供审计报告。
- `v4-compat` 至少保留一个稳定版本周期。
- `engine_mode`、项目 profile 偏好和 adapter 版本写入本地状态，但项目文档保持宿主中立；每任务 profile floor 由 PDP 重新计算。
- 任何自动迁移必须先生成变更预览，并保留恢复点。

## 9. 验证策略

### 9.1 合同测试

- policy kernel 尺寸、禁用内容和六类不变量。
- profile 场景矩阵与 high-risk override。
- 三个 adapter family 的 capability 检测、runtime hash 和降级行为，并分别覆盖 OpenCode/OpenClaw 安装目标。
- 安装、升级、卸载和回滚的数据安全。

### 9.2 行为测试

- 真实执行 low-risk 小改，确认不产生 spec/HTML/subagent 仪式。
- 真实执行鉴权或迁移设计，确认进入 governed 并保留人审。
- 对每个 adapter family 实测无证据不能完成、无批准不能执行、forbidden 被拒绝；缺少原生强制能力时验证阻断/升级人降级路径。
- 模拟 Skill 缺失、宿主命令缺失和 runtime 过期，确认显式降级。

### 9.3 结果评测

- baseline/kernel/v5/v4 使用相同初始仓库和验收测试。
- 报告正确率、成本和人为干预，不只报告 Prompt 是否命中。
- 对失败案例记录根因：模型能力、目标歧义、路由、Skill、宿主或证据门禁。

## 10. 风险与缓解

| 风险 | 缓解 |
|------|------|
| profile 误判让高风险任务走轻路径 | 缺信息不判 minimal；high-risk override；shadow 期先观测 |
| 大拆分导致 v4 用户行为突变 | v4-compat；分阶段默认切换；可回滚 |
| adapter 抽象变成最小公分母 | 核心只定义语义；宿主保留增强能力 |
| 评测集被优化到失真 | 保留隐藏任务和真实失败样本；定期轮换；不以单指标决策 |
| Prompt 变短后遗漏重要纪律 | 六类 kernel 不变量 golden test；高风险行为测试 |
| wrapper 未覆盖现有 patch 能力 | patch 兼容模式直到对等测试通过 |

## 11. Domain Language Delta

- **治理内核（Policy Kernel）**：所有项目和宿主都应常驻的最小不变量集合。避免称为「完整系统 Prompt」。
- **自适应编排（Adaptive Orchestration）**：根据风险、歧义、影响面和实际宿主能力选择流程，而非固定 pipeline。
- **执行档位（Profile）**：`minimal / standard / governed` 三种流程强度，不代表模型质量等级。
- **宿主适配器（Host Adapter）**：把持续执行、能力发现、独立复核等统一语义翻译成宿主原生机制。
- **结果证据（Outcome Evidence）**：证明任务结果的机械信号、独立复核和人类判断；不包含固定文案或页面是否生成。
- **Shadow mode**：只记录 v5 会如何路由，不改变当前执行路径的观测模式。

## 12. 待 spec-gate 判定

1. 是否接受「v5 的核心产品是治理控制层，不再是 SOP Prompt 包」。
2. 是否接受 `minimal` 默认不生成 spec、不走人审、不展示任务对齐块。
3. 是否接受 `/goal` 和 SessionStart 从核心下沉为 Claude adapter。
4. 是否接受逐步停止覆盖第三方 Skill 文件。
5. 是否接受先做 Phase 0 运行时完整性，再开始 Prompt 和流程瘦身。
