# Product: codesop
# Current Version: 1.1.2
# Last Updated: 2026-03-30
# Status: active

---

## 0. 使用说明
> 本文档同时承担两种职责：
> 1. 产品主文档：描述当前有效的目标、范围、规则与架构。
> 2. 工作记录：记录当前进度、最近决策、阻塞项与每步工作日志。
>
> 更新规则：
> - 长期稳定信息：直接覆盖更新，保持“当前真实状态”
> - 短期流动信息：追加记录，保留时间线
> - 每次任务结束前，检查是否需要更新本文件

## 1. 当前快照

- **当前阶段**: release
- **当前目标**: 发布 v1.1.2，完成内核收口、文档 gate 落地和版本规则收敛
- **长期目标**: 让 AI 编码助手在任意项目中有统一的 workflow 纪律和 skill 路由
- **当前里程碑**: v1.1.2 (contract cleanup + doc gate + versioning)
- **完成度**: 95%
- **下一步**: 完成 review 与 ship，打出 v1.1.2 tag
- **负责人/执行主体**: Mixed
- **最后更新原因**: 进入 v1.1.2 ship 阶段，统一版本号与发布记录

## 2. 当前进度

### 2.1 In Progress
- [ ] 完成 v1.1.2 发布前最后校验与打 tag

### 2.2 Next Up
- [ ] 观察文档判定 gate 的真实使用摩擦，再决定是否要更强的 `document-release` 自动触发
- [ ] bats-core 单元测试框架引入
- [ ] 模块契约文档：每个 lib/*.sh 的公开接口

### 2.3 Blocked
- 无

### 2.4 Done Recently
- [x] 修复 `codesop update`：同版本但上游有新提交时不再误报“已是最新”
- [x] `VERSION` / `skill.json` / `PRD.md` / `CHANGELOG.md` 的发布规则已收敛
- [x] 删除重复的 `QUICKSTART.md`
- [x] `/codesop` 收尾阶段加入固定文档判定 gate，并约定优先走 `document-release`
- [x] `codesop init` 口径收敛：项目级 `AGENTS.md` 默认只保留 `@CLAUDE.md`
- [x] PR #3: 修复 `codesop update` 的 timeout/remote/stash-pop/jq 问题 (v1.1.1)
- [x] PR #4: 清理 ~5500 行死代码，删除 21 个废弃文件 (v1.1.1)
- [x] Router card 纪律层：SessionStart hook + AGENTS.md + codesop.md 三层冗余 (v1.1.0)
- [x] `/codesop` skill 重写为英文 workbench/workflow router (v1.1.0)
- [x] Init interview 模式：交互式偏好设置 + 系统级 symlink (v1.0.1)
- [x] Superpowers plugin cache 路径检测 (v1.0.1)

## 3. 最近决策记录

| Date | Decision | Why | Impact |
|------|----------|-----|--------|
| 2026-03-30 | `VERSION` 保留为发布版本真相源，git tag 只在 ship 时创建 | runtime 与 update 流程都需要稳定版本号；未发布改动不该提前占用正式版本号 | `skill.json`、`PRD.md` 与 `CHANGELOG.md` 应围绕 `VERSION + Unreleased` 对齐 |
| 2026-03-30 | 文档纪律默认只判定 `CLAUDE.md`、`PRD.md`、`README.md` | `CHANGELOG.md` 更像发布文档，不应进入日常强制集合 | 收尾 gate 只围绕 3 个核心文档做判定 |
| 2026-03-30 | `AGENTS.md` 继续保持薄包装并在 init 阶段默认生成 | 避免和 `CLAUDE.md` 重复维护两份规则正文 | 初始化时优先生成 `@CLAUDE.md` 引用，后续文档判定只关注 `CLAUDE.md` |
| 2026-03-30 | `codesop` 负责文档判定，`document-release` 负责文档执行 | 不重复造一个重文档 skill，同时保留本地判定权 | 后续应优先集成 `gstack:document-release` 作为执行器 |
| 2026-03-30 | 保留 `install.sh`，删除 repo 内 `agents/` 运行时残留 | 安装入口有价值，但 `agents/openai.yaml` 没有实际消费方 | 安装说明保留，runtime 不再携带 `agents/` 目录 |
| 2026-03-30 | `/codesop` 统一以 `SKILL.md` 为唯一真相源 | 双份正文会持续漂移，维护成本过高 | `setup` 改为从 `SKILL.md` 安装 `/codesop` 到 Claude Code 运行时 |
| 2026-03-30 | 冻结产品合同为“1 套流程 + 3 个命令” | 先把边界收窄，避免继续在噪音上叠功能 | 后续要移除 `status/diagnose` 面向用户的入口和文档 |
| 2026-03-30 | 清理全部历史 plans/specs | 已完成的规划文档变成噪音，阻碍“看着清爽” | 删除 docs/plans/ 和 docs/superpowers/ 下 16 个文件 |
| 2026-03-30 | PR #3 先于 PR #4 合并 | 两者都改 lib/commands.sh，bug fix 先入 main | PR #4 rebase onto updated main |
| 2026-03-30 | 删除 scripts/detect-environment.sh | 0 处生产代码引用，仅测试引用 | 测试改为只验证文档内容 |
| 2026-03-30 | 删除 /codesop-status 命令 | 功能与 /codesop 重复，增加维护负担 | 相关测试与文档说明一并删除 |
| 2026-03-27 | Init interview 替代 run_init | 面试式交互比静态模板更贴合用户需求 | lib/commands.sh 移除 run_init，lib/init-interview.sh 接管 |

## 4. 版本历史

### **V1.1.1 - 2026-03-30 - (Bug Fix + Cleanup)**
- **目标**: 修复 update 命令 bug，清理死代码
- **变更摘要**:
  - 修复 `codesop update`: macOS timeout 兼容、动态 remote、stash pop 冲突退出码
  - 修复 jq `test()` 对 null 值的防护
  - 清理 ~5500 行死代码（codesop.backup、历史 plans/specs、detect-environment.sh）
  - 删除 init-interview.sh 中 3 个未使用函数

### **V1.1.0 - 2026-03-30 - (Router Card Discipline Layer)**
- **目标**: 让 AI 强制遵循 skill pipeline，不靠自觉
- **变更摘要**:
  - Router card 纪律层：SessionStart hook 注入必走路径表
  - `/codesop` skill 重写为英文 workbench + workflow router
  - 11 个工作流场景映射到下游 skill pipeline
  - setup 脚本增加 install_router_card + configure_hooks

### **V1.0.1 - 2026-03-27 - (Init Interview + Plugin Detection)**
- **目标**: 交互式初始化 + superpowers 跨宿主检测
- **变更摘要**:
  - Init interview 模式替代静态 run_init
  - Superpowers plugin cache 路径检测（Claude Code 官方插件市场）
  - Per-host skill 检测和安装建议

### **V1.0.0 - 2026-03-25 - (Initial Release)**
- **目标**: 发布 MVP，验证核心价值
- **变更摘要**:
  - 项目初始化，CLI 框架，基础检测和模板生成

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
- 三个机械命令：`codesop init`、`codesop update`、`codesop setup`
- Router card + SessionStart hook 的纪律注入
- 项目初始化（AGENTS.md / PRD.md / README.md）
- 宿主集成同步与版本更新
- 为 init/setup 服务的环境检测与生态依赖检查

#### Out of Scope
- 独立的 `status` / `diagnose` 产品面
- AI 模型选择或配置
- 具体项目的业务逻辑
- CI/CD 流水线管理
- 非 Claude Code / Codex / OpenCode 的宿主支持

### 5.4 核心功能
- **`/codesop` skill**: 工作台摘要 + 工作流路由，读取项目上下文推荐下一步 skill
- **Router card**: SessionStart hook 注入纪律表，强制 AI 遵循必走 skill pipeline
- **`codesop init`**: 检测项目技术栈，生成 `AGENTS.md` / `PRD.md` / `README.md`，并把 `AGENTS.md` 默认收敛为 `@CLAUDE.md`
- **`codesop update`**: git pull + 自动重同步宿主集成
- **`codesop setup`**: 安装 router card + 配置 hooks + 同步 commands

### 5.5 产品合同

#### 对外只承诺这 4 个入口
- `/codesop`
- `codesop init`
- `codesop update`
- `codesop setup`

#### 当前不再承诺稳定的入口
- `codesop status`
- 默认无参数走 diagnose 的 CLI 行为
- 任何围绕 `scripts/diagnose*.sh` 暴露给用户的新能力

#### 真相源策略
- `/codesop` 内容只保留一个真相源：`SKILL.md`
- `setup` 负责把 `SKILL.md` 同步到 `~/.claude/commands/codesop.md`
- 不再在仓库中维护第二份 `/codesop` 正文

### 5.6 版本规划
- **Now (v1.1.x)**: 稳定化 + 架构收口 + 文档纪律自动化方案评估
- **Next (v1.2)**: bats-core 测试框架 + 模块契约文档
- **Later (v2.0)**: 可选 Python 模块验证 bash 是否足够

### 5.7 目标架构

以下是收口后的目标结构，不等于当前实现已经完全到位：

```
codesop                     # CLI 入口，只暴露 init / update / setup
setup                       # 宿主安装与同步
├── lib/
│   ├── output.sh           # 格式化工具：render_tech_stack, infer_*_cmd
│   ├── detection.sh        # init/setup 所需的项目与宿主检测
│   ├── templates.sh        # 模板生成：AGENTS.md 内容填充
│   ├── init-interview.sh   # Init 流程：工具检测、symlink、偏好面试、项目文件、skill 检查
│   ├── updates.sh          # 版本管理：CHANGELOG 解析、git 更新检查
│   └── commands.sh         # 子命令：run_init_interview, run_update, run_setup
├── SKILL.md                # /codesop 唯一真相源
├── commands/               # 机械 slash command 文件
│   ├── codesop-init.md     # /codesop-init
│   ├── codesop-setup.md    # /codesop-setup
│   └── codesop-update.md   # /codesop-update
├── config/
│   └── codesop-router.md   # Router card
├── templates/
│   ├── system/             # 系统级模板（AGENTS.md 含 skill 纪律）
│   ├── project/            # 项目级模板（PRD.md, README.md）
│   └── init/               # Init prompt 模板
└── tests/                  # 仅保留与内核合同一致的测试
```

**模块加载顺序** (codesop 入口):
1. `lib/output.sh` → 2. `lib/detection.sh` → 3. `lib/templates.sh` → 4. `lib/updates.sh` → 5. `lib/commands.sh` → 6. `lib/init-interview.sh`

**宿主集成映射**:

| Host | Config Target | Commands | Hook |
|------|--------------|----------|------|
| Claude Code | `~/.claude/CLAUDE.md` | `~/.claude/commands/` | SessionStart hook in settings.json |
| Codex | `~/.codex/AGENTS.md` | `~/.codex/commands/` | — |
| OpenCode | `~/.config/opencode/AGENTS.md` | — | — |

### 5.8 收口矩阵

#### 保留
- `/codesop` workflow router
- `codesop init`
- `codesop update`
- `codesop setup`
- `setup`
- `lib/output.sh`
- `lib/detection.sh`
- `lib/templates.sh`
- `lib/updates.sh`
- `lib/init-interview.sh`

#### 合并 / 归一
- Router card 生成口径与 `setup` 实现
- 文档中的“当前实现”与“目标架构”表述

#### 删除或退役
- `codesop status`
- 默认 diagnose 入口
- `scripts/collect-signals.sh`
- `scripts/diagnose.sh`
- `scripts/recommend.sh`
- 围绕 status/diagnose 的测试与文档说明

#### 待判定
- 无

### 5.9 技术实现规范

#### 代码规范
- `set -euo pipefail` 在入口脚本中，管道命令用 `|| true` 或 `|| fallback` 防误杀
- `bare return` 继承前命令退出码，必须用 `return 0` 显式返回
- `git fetch` 用 `timeout` 包裹防挂起，macOS 需要 fallback（无 GNU coreutils）
- `wc -l` 输出有前导空格，管道 `tr -d ' '` 后再算术

#### Hook 配置
- `configure_hooks()` 用 jq 嵌套 schema: `{ "matcher": "", "hooks": [{ "type": "command", ... }] }`
- Router card 是 `config/codesop-router.md`，setup 同步到 `~/.claude/`
- 幂等：重复运行 `setup --host claude` 不会重复 hook

#### 生态依赖
- **superpowers**: brainstorming, writing-plans, TDD, systematic-debugging, subagent-driven-dev
- **gstack**: office-hours, autoplan, review, ship, qa, investigate
- 更新: `/plugin update superpowers` (CC), `/gstack-upgrade` (gstack), `git pull` (Codex)

#### 验收标准
- [ ] 产品合同文档统一为“1 套流程 + 3 个命令”
- [ ] 所有保留测试通过
- [ ] `bash setup --host claude` 幂等
- [ ] PRD.md 反映当前真实状态（无占位符）

### 5.10 文档纪律机制

#### 目标
- 把“文档更新”从隐含习惯变成任务结束前的显式判定
- 不新增第 4 个命令，不把 codesop 再做成一个重自动化系统
- 优先复用 `gstack:document-release`，避免重复造轮子

#### 默认判定文档
- `CLAUDE.md`
- `PRD.md`
- `README.md`

#### 不纳入默认强制集合
- `CHANGELOG.md`
  - 默认归入发布文档
  - 仅在项目明确使用它作为正式发布记录时才进入检查范围

#### `AGENTS.md` 薄包装规则
- 项目级正文默认只维护 `CLAUDE.md`
- 项目级 `AGENTS.md` 默认保持薄包装：`@CLAUDE.md`
- 如需补充说明，最多只加一两行宿主兼容说明，不复制正文
- 该规则应在 `codesop init` 阶段直接落实，而不是在任务结束时再补救
- 文档判定时默认只检查 `CLAUDE.md`，不单独把 `AGENTS.md` 作为正文文档

#### 收尾 gate 的职责
- 在任务结束、准备输出最终结果前，执行一次文档判定
- 只回答“要不要更新文档”，不直接承担复杂文档生成逻辑

#### 收尾 gate 输出格式
```md
## 文档判定

- CLAUDE.md: 已更新 / 未更新，原因：...
- PRD.md: 已更新 / 未更新，原因：...
- README.md: 已更新 / 未更新，原因：...
```

#### 各文档的触发条件

`CLAUDE.md`
- 项目规则变化
- 架构边界变化
- 命令集合变化
- workflow / skill 纪律变化

`PRD.md`
- 当前阶段、目标、完成度、下一步变化
- 最近决策变化
- 产品范围、核心功能、版本规划变化
- 完成了一个值得记录的重要实现步骤
- 出现阻塞或阻塞解除

`README.md`
- 安装、运行、配置、使用方式变化
- 目录结构或对外入口变化
- 用户可见的命令或行为变化

#### 可不更新文档的场景
- 纯重构且不改变行为
- 只改测试、注释、格式化
- 内部实现细节变化但不影响规则、产品事实和使用方式

#### 与 `document-release` 的集成
- `codesop` 负责判定是否需要更新文档
- 任一核心文档判定为“需要更新”时，优先调用 `gstack:document-release`
- `document-release` 负责执行和整理文档更新
- 若 `document-release` 不可用，则回退为手动更新文档，但仍必须给出文档判定结果

#### 当前落位
- 放在 `/codesop` 主流程的收尾阶段
- 在最终回复前执行
- 不放进 `init / setup / update` 命令内部

## 6. 当前风险与假设

### 6.1 Risks
- **文档纪律执行靠 AI 自觉**: router card 注入规则但没有结构性检查点，AI 在惯性执行时容易跳过
- **bash 复杂度上限**: 当前 shell 体量继续增长时，可能需要迁移到 Python
- **跨宿主测试困难**: Codex 和 OpenCode 集成难以在 CI 中自动化验证

### 6.2 Assumptions
- 用户已安装 Claude Code 或 Codex 或 OpenCode 中的至少一个
- superpowers 和 gstack 是推荐的 skill 生态，但不是必需的
- bash 足够处理当前复杂度，暂不需要 Python

## 7. 工作日志

### 2026-03-30 - 冻结“1 套流程 + 3 个命令”产品合同
- **背景**: 当前目录和文件边界仍混杂，继续加功能会放大历史包袱
- **动作**: 明确 `/codesop` + `init/update/setup` 为唯一对外承诺，补充收口矩阵
- **结果**: 后续清理有了依据，`status/diagnose` 被明确标记为退役对象
- **影响**: 接下来应先做架构收口，再处理文档自动更新机制

### 2026-03-30 - 统一 `/codesop` 真相源到 `SKILL.md`
- **背景**: 仓库中同时维护 `SKILL.md` 和 `commands/codesop.md`，容易漂移
- **动作**: 删除 repo 内的 `commands/codesop.md`，改为由 `setup` 从 `SKILL.md` 安装 `/codesop`
- **结果**: `/codesop` 正文回到单一来源，Claude Code 运行时仍保持兼容
- **影响**: 后续只需更新 `SKILL.md`，不再需要双份同步

### 2026-03-30 - 删除旧 diagnose/status 链与历史 spec
- **背景**: `status/diagnose` 已不属于产品合同，旧 spec 继续保留只会误导维护
- **动作**: 删除 diagnose/status 脚本与测试，移除失真的 design spec 与未接入内核的对比文档
- **结果**: repo 只剩与当前内核一致的结构和说明
- **影响**: 后续新增能力前，先通过 PRD 更新产品合同

### 2026-03-30 - 确认文档判定与 `document-release` 集成方向
- **背景**: codesop 自己缺少任务结束时的文档检查点，文档更新主要靠模型自觉
- **动作**: 确认只判定 `CLAUDE.md`、`PRD.md`、`README.md`，并采用“codesop 判定 + `document-release` 执行”的结构
- **结果**: 文档纪律方案收敛，不需要新建第 4 个命令
- **影响**: 下一步应把收尾 gate 写入 `/codesop` 流程，并设计降级路径

### 2026-03-30 - 文档判定 gate 与 AGENTS 薄包装规则落地
- **背景**: 仅有方案不够，`/codesop` 和 init 口径必须在文档与模板层同步成一套真实合同
- **动作**: 给 `/codesop` 增加固定文档判定 block，补入 `document-release` 优先策略；同时收敛 init 文案和模板，明确项目级 `AGENTS.md` 默认为 `@CLAUDE.md`
- **结果**: 收尾阶段和初始化阶段的文档纪律开始对齐，不再各说各话
- **影响**: 下一步应在真实任务里观察这套 gate 的摩擦度，再决定是否继续自动化

### 2026-03-30 - 版本真相源与入门文档进一步收口
- **背景**: `VERSION`、`skill.json`、`CHANGELOG.md` 和 `QUICKSTART.md` 之间出现漂移，进入 review/ship 前会持续制造噪音
- **动作**: 确认 `VERSION` 为唯一发布版本源，`CHANGELOG.md` 顶部切回 `Unreleased`，移除重复的 `QUICKSTART.md`
- **结果**: 发布版本和开发中改动的边界更清楚，减少一份重复维护文档
- **影响**: ship 时只需要 bump `VERSION`、同步元数据并打 tag

### 2026-03-30 - v1.1.2 ship 准备完成
- **背景**: 合同收口、文档 gate、版本治理和 update 修复已经到位，可以进入正式发布
- **动作**: 将版本统一提升到 `1.1.2`，整理发布说明，并完成 ship 前全量校验
- **结果**: 仓库已经具备本地提交和打 tag 的条件
- **影响**: 下一步可直接执行 release commit 与 `v1.1.2` tag

### 2026-03-30 - PR #3/#4 合并 + PRD 更新
- **背景**: 两轮迭代完成后 PRD 全是占位符，发现文档纪律执行失败
- **动作**: 合并 PR #3 (bug fix) 和 PR #4 (cleanup)，更新 PRD.md
- **结果**: main 干净，v1.1.1，49 文件，~5500 行死代码已清
- **影响**: 暴露结构性问题：任务完成时没有机制强制触发 verification/document-release
- **后续**: 评估文档纪律自动化的方案

### 2026-03-30 - Router Card 纪律层上线
- **背景**: AI 助手频繁跳过必走 skill pipeline
- **动作**: 实现 SessionStart hook + AGENTS.md + codesop.md 三层冗余纪律注入
- **结果**: 新会话开始时 AI 自动加载必走路径表
- **影响**: 仍然依赖 AI 自律，没有中程检查点

### 2026-03-27 - Init Interview + Plugin Detection
- **背景**: 静态 init 无法收集用户偏好，superpowers 检测不完整
- **动作**: 实现交互式 init interview，增加 Claude Code plugin cache 路径检测
- **结果**: init 流程可以按用户偏好定制，跨宿主 superpowers 检测覆盖
- **影响**: run_init 被弃用，run_init_interview 接管
