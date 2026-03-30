# Product: codesop
# Current Version: 1.1.1
# Last Updated: 2026-03-30
# Status: active

---

## 0. 使用说明
> 本文档同时承担两种职责：
> 1. 产品主文档：描述当前有效的目标、范围、规则与架构。
> 2. 工作记录：记录当前进度、最近决策、阻塞项与每步工作日志。
>
> 更新规则：
> - 长期稳定信息：直接覆盖更新，保持"当前真实状态"
> - 短期流动信息：追加记录，保留时间线
> - 每次任务结束前，检查是否需要更新本文件

## 1. 当前快照

- **当前阶段**: maintenance
- **当前目标**: 稳定 v1.1.x，补齐测试覆盖，推进文档纪律自动化
- **长期目标**: 让 AI 编码助手在任意项目中有统一的 workflow 纪律和 skill 路由
- **当前里程碑**: v1.1.1 (router card + cleanup)
- **完成度**: 70%
- **下一步**: 评估文档纪律自动化的方案（PostTask hook 或新 skill）
- **负责人/执行主体**: Mixed
- **最后更新原因**: PR #3/#4 合并后，PRD 全是占位符，需要填实

## 2. 当前进度

### 2.1 In Progress
- [ ] 文档纪律自动化：研究如何在任务完成时自动触发 verification + document-release

### 2.2 Next Up
- [ ] 补齐 `run_update` 专项测试（TODOS.md）
- [ ] bats-core 单元测试框架引入（TODOS.md）
- [ ] 模块契约文档：每个 lib/*.sh 的公开接口（TODOS.md）

### 2.3 Blocked
- 无

### 2.4 Done Recently
- [x] PR #3: 修复 `codesop update` 的 timeout/remote/stash-pop/jq 问题 (v1.1.1)
- [x] PR #4: 清理 ~5500 行死代码，删除 21 个废弃文件 (v1.1.1)
- [x] Router card 纪律层：SessionStart hook + AGENTS.md + codesop.md 三层冗余 (v1.1.0)
- [x] `/codesop` skill 重写为英文 workbench/workflow router (v1.1.0)
- [x] Init interview 模式：交互式偏好设置 + 系统级 symlink (v1.0.1)
- [x] Superpowers plugin cache 路径检测 (v1.0.1)

## 3. 最近决策记录

| Date | Decision | Why | Impact |
|------|----------|-----|--------|
| 2026-03-30 | 清理全部历史 plans/specs | 已完成的规划文档变成噪音，阻碍"看着清爽" | 删除 docs/plans/ 和 docs/superpowers/ 下 16 个文件 |
| 2026-03-30 | PR #3 先于 PR #4 合并 | 两者都改 lib/commands.sh，bug fix 先入 main | PR #4 rebase onto updated main |
| 2026-03-30 | 删除 scripts/detect-environment.sh | 0 处生产代码引用，仅测试引用 | 测试改为只验证文档内容 |
| 2026-03-30 | 删除 /codesop-status 命令 | 功能与 /codesop 重复，增加维护负担 | tests/codesop-status.sh 保留用于 router card 集成测试 |
| 2026-03-27 | Init interview 替代 run_init | 面试式交互比静态模板更贴合用户需求 | lib/commands.sh 移除 run_init，lib/init-interview.sh 接管 |

## 4. 版本历史

### **V1.1.1 - 2026-03-30 - (Bug Fix + Cleanup)**
- **目标**: 修复 update 命令 bug，清理死代码
- **变更摘要**:
  - 修复 `codesop update`: macOS timeout 兼容、动态 remote、stash pop 冲突退出码
  - 修复 jq test() 对 null 值的防护
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
- 跨宿主 skill 路由和纪律强制
- 项目初始化（AGENTS.md / PRD.md / README.md）
- 环境检测（语言、框架、工具、skill 依赖）
- 版本更新和宿主集成同步
- 生态依赖检查（superpowers、gstack）

#### Out of Scope
- AI 模型选择或配置
- 具体项目的业务逻辑
- CI/CD 流水线管理
- 非 Claude Code / Codex / OpenCode 的宿主支持

### 5.4 核心功能
- **`/codesop` skill**: 工作台摘要 + 工作流路由，读取项目上下文推荐下一步 skill
- **Router card**: SessionStart hook 注入纪律表，强制 AI 遵循必走 skill pipeline
- **`codesop init`**: 检测项目技术栈，生成 AGENTS.md / CLAUDE.md / PRD.md
- **`codesop update`**: git pull + 自动重同步宿主集成
- **`codesop setup`**: 安装 router card + 配置 hooks + 同步 commands
- **环境检测**: 语言、框架、工具、skill 依赖一站式检测

### 5.5 版本规划
- **Now (v1.1.x)**: 稳定化 + 补测试 + 文档纪律自动化
- **Next (v1.2)**: bats-core 测试框架 + 模块契约文档
- **Later (v2.0)**: 可选 Python 模块验证 bash 是否足够

### 5.6 架构

```
codesop                     # CLI 入口，按序加载 lib 模块
├── lib/
│   ├── output.sh           # 格式化工具：render_tech_stack, infer_*_cmd
│   ├── detection.sh        # 项目检测：语言、框架、工具、skill 依赖
│   ├── templates.sh        # 模板生成：AGENTS.md 内容填充
│   ├── init-interview.sh   # Init 流程：工具检测、symlink、偏好面试、项目文件、skill 检查
│   ├── updates.sh          # 版本管理：CHANGELOG 解析、git 更新检查
│   └── commands.sh         # 子命令：run_init, run_status, run_update, run_version, run_diagnose
├── commands/               # Slash command skill 文件（同步到 ~/.claude/commands/）
│   ├── codesop.md          # /codesop — workflow router
│   ├── codesop-init.md     # /codesop-init
│   ├── codesop-setup.md    # /codesop-setup
│   └── codesop-update.md   # /codesop-update
├── config/
│   └── codesop-router.md   # Router card 源文件（同步到 ~/.claude/）
├── templates/
│   ├── system/             # 系统级模板（AGENTS.md 含 skill 纪律）
│   ├── project/            # 项目级模板（PRD.md, README.md）
│   └── init/               # Init prompt 模板
├── scripts/                # 诊断流程脚本
│   ├── collect-signals.sh  # 信号采集
│   ├── diagnose.sh         # 阶段诊断
│   └── recommend.sh        # Skill 推荐
├── setup                   # 宿主安装脚本（router card + hook 配置）
└── tests/                  # 测试套件（12 个测试文件）
```

**模块加载顺序** (codesop 入口):
1. `lib/output.sh` → 2. `lib/detection.sh` → 3. `lib/templates.sh` → 4. `lib/updates.sh` → 5. `lib/commands.sh` → 6. `lib/init-interview.sh`

**宿主集成映射**:

| Host | Config Target | Commands | Hook |
|------|--------------|----------|------|
| Claude Code | `~/.claude/CLAUDE.md` | `~/.claude/commands/` | SessionStart hook in settings.json |
| Codex | `~/.codex/AGENTS.md` | `~/.codex/commands/` | — |
| OpenCode | `~/.config/opencode/AGENTS.md` | — | — |

### 5.7 技术实现规范

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
- [ ] 所有测试套件通过（12 个测试文件）
- [ ] `bash setup --host claude` 幂等
- [ ] PRD.md 反映当前真实状态（无占位符）

## 6. 当前风险与假设

### 6.1 Risks
- **文档纪律执行靠 AI 自觉**: router card 注入规则但没有结构性检查点，AI 在惯性执行时容易跳过
- **bash 复杂度上限**: 当前 ~1500 行 shell，继续增长可能需要迁移到 Python
- **跨宿主测试困难**: Codex 和 OpenCode 集成难以在 CI 中自动化验证

### 6.2 Assumptions
- 用户已安装 Claude Code 或 Codex 或 OpenCode 中的至少一个
- superpowers 和 gstack 是推荐的 skill 生态，但不是必需的
- bash 足够处理当前复杂度，暂不需要 Python

## 7. 工作日志

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
