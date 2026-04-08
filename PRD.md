# Product: codesop
# Current Version: 2.1.8
# Last Updated: 2026-04-08
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
- **当前里程碑**: v2.0.0 已发布 (Superpowers-only backbone + curated plugins)
- **完成度**: 100%
- **下一步**: 按需迭代
- **负责人/执行主体**: Mixed
- **最后更新原因**: Skill 哲学审查完成，结论为当前设计已有效

## 2. 当前进度

### 2.1 In Progress
- 无

### 2.2 Next Up
- 无（按需驱动）

### 2.3 Blocked
- 无

### 2.4 Done Recently
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
- **`/codesop` 收尾格式**: 推荐区之后，最后一行输出自然语言工作流指令，可串联 1 到 3 个 skill，提升 Claude Code 灰色默认建议命中概率
- **文档漂移扫描**: 在路由前先判断当前项目的 `CLAUDE.md` / `PRD.md` / `README.md` 是否已经落后于代码与当前状态，并把必要的文档更新编进下一步工作流链
- **Router card**: SessionStart hook 注入纪律表，强制 AI 遵循必走 skill pipeline
- **`codesop init`**: 检测项目技术栈，生成 `AGENTS.md` / `PRD.md` / `README.md`
- **`codesop update`**: git pull + 自动重同步宿主集成

### 5.5 产品合同

#### 对外只承诺这 3 个入口
- `/codesop`
- `codesop init`
- `codesop update`

#### 真相源策略
- `/codesop` 内容只保留一个真相源：`SKILL.md`
- `setup` 负责把 `SKILL.md` 同步到 `~/.claude/commands/codesop.md`

### 5.6 版本规划
- **Now (v2.0.x)**: 按需迭代，稳定维护
- **Later**: 反馈回路设计 + 可选 Python 模块验证 bash 是否足够

### 5.7 目标架构

```
codesop                     # CLI 入口，只暴露 init / update
setup                       # 宿主安装与同步
├── lib/
│   ├── output.sh           # 格式化工具
│   ├── detection.sh        # 项目与宿主检测
│   ├── templates.sh        # AGENTS.md 模板生成
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
└── tests/                  # 内核合同测试
```

**模块加载顺序**: output → detection → templates → updates → commands → init-interview

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
