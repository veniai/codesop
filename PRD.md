# Product: codesop
# Last Updated: 2026-06-29
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
- **当前里程碑**: v3.10.1 稳定维护
- **完成度**: 100%
- **下一步**: 按需迭代
- **负责人/执行主体**: Mixed
- **最后更新原因**: 对抗式审查 v4.2.0（verification §C.2 high-risk deliver 前攻击者视角扫边界 bug）

## 2. 当前进度

### 2.1 In Progress
- 无

### 2.2 Next Up
- 无（v4.1.0 第一性原理 + v4.2.0 对抗式审查均落地；按需迭代）

### 2.3 Blocked
- 无

### 2.4 Done Recently
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

See [GitHub Releases](https://github.com/veniai/codesop/releases) for full version history. Current version: v4.0.0.

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
- **文档纪律执行靠 AI 自觉**: router card 注入规则但没有结构性检查点
- **bash 复杂度上限**: shell 体量继续增长时可能需迁移 Python
- **PRD 文档滞后风险**: 代码和 PR 先行时 PRD 容易落后

### 6.2 Assumptions
- 用户已安装 Claude Code 或 Codex 或 OpenCode 中的至少一个
- superpowers 是推荐的核心 skill 生态，但不是必需的
- bash 足够处理当前复杂度
