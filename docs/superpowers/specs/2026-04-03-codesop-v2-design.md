# codesop v2.0 设计规格

> 日期：2026-04-03
> 状态：待审批（Codex 审查意见已纳入）
> 触发：GStack 卸载，技术栈从双引擎改为 Superpowers 为基座 + 精选插件

## 1. 背景与动机

codesop v1.x 依赖 Superpowers + GStack 双引擎，存在以下问题：

1. **GStack 卸载** — 2026-04-03 彻底卸载，120 处代码引用需清理
2. **路由表过时** — 还在引用 office-hours、investigate、ship、review 等 GStack skill
3. **依赖检查过时** — updates.sh 有 52 处 GStack 引用
4. **插件生态扩展** — 新装 8 个官方插件 + 1 个 OpenAI codex 插件，路由和检查都未覆盖
5. **路由重复** — 路由表和 SKILL.md 各维护一套路由定义

v2.0 目标：**单一技术栈、单一路由源、覆盖所有已装插件。**

## 2. 技术栈定义（v2.0）

### 官方插件（Plugin）

| 插件 | 来源 | 用途 |
|------|------|------|
| superpowers | claude-plugins-official | 核心技能集（14 个 skill） |
| skill-creator | claude-plugins-official | Skill 全生命周期开发 |
| frontend-design | claude-plugins-official | 前端 UI 设计 |
| context7 | claude-plugins-official (MCP) | 第三方库文档查询 |
| code-review | claude-plugins-official | PR 自动审查 |
| code-simplifier | claude-plugins-official | 代码质量优化 |
| playwright | claude-plugins-official (MCP) | 浏览器自动化 |
| claude-md-management | claude-plugins-official | CLAUDE.md 质量审计 |
| codex | openai-codex | OpenAI 第二意见审查/对抗性审查/应急接管 |

### 独立 Skill

| Skill | 路径 | 用途 |
|-------|------|------|
| codesop | ~/.claude/skills/codesop/ | 项目工作台和路由 |
| browser-use | ~/.claude/skills/browser-use/ | 浏览器自动化（云浏览器/tunnel 补充） |
| claude-to-im | ~/.claude/skills/claude-to-im/ | IM 平台桥接 |

### 不归 codesop 管理的

| 类型 | 名称 | 处理方式 |
|------|------|---------|
| MCP server | filesystem, fetch, zread | 存在但不管，不检查、不路由 |

### 宿主支持（Codex review P1-2 修正）

v2.0 **正式只支持 Claude Code** 作为主要宿主。理由：

1. 所有 9 个插件都通过 Claude Code 插件系统安装，Codex/OpenCode 没有对应机制
2. `installed_plugins.json` 只存在于 `~/.claude/`
3. 插件检查逻辑依赖 Claude Code 的目录结构

**兼容处理**：setup 中的 Codex/OpenCode 安装函数（同步 AGENTS.md、skill 目录）保留不动，但插件检查只检查 Claude 环境。非 Claude 宿主跳过插件检查，只报告 "插件检查仅支持 Claude Code"。

## 3. 设计决策

| 编号 | 决策 | 选项 | 理由 |
|------|------|------|------|
| D1 | 路由模式 | 纯参考表，Claude 自主判断 | 保持灵活性 |
| D2 | Update 检查 | 版本检查 + 完整性 + 路由覆盖 | 全面保障 |
| D3 | MCP 管理 | 不管 | 降低复杂度 |
| D4 | Init 变更 | 去掉 GStack 检测，加新插件检查 | 最小改动 |
| D5 | 描述格式 | 一句话自然语言，优化措辞 | 简洁 |
| D6 | 路由源 | 单一表格直接写入 config/codesop-router.md | 唯一来源，零同步 |
| D7 | Completion Gate | 调用 claude-md-management + 补充 PRD/README | 复用插件能力 |
| D8 | 改造方案 | 重写核心，保留骨架 | 风险最低 |
| D9 | 依赖分级 | CORE 必装 + OPTIONAL 装了就检查 | Codex P2-3 修正 |
| D10 | 宿主范围 | Claude Code 为主，Codex/OpenCode 兼容保留 | Codex P1-2 修正 |
| D11 | Bug-fix 路由 | 路由表铁律后补充调试路径 | Codex P1-1 修正 |
| D12 | 版本检查源 | superpowers 用 GitHub tags，其他只检查存在性 | Codex P2-4 修正 |
| D13 | 验收范围 | grep 限定运行时文件，排除 docs/ 和历史文档 | Codex P2-5 修正 |

## 4. 改造方案：方案 B — 重写核心，保留骨架

保留：模块结构、codesop 入口、setup 骨架、lib/ 划分
重写：路由表、依赖检查逻辑、detection 函数
小改：SKILL.md、init-interview.sh、templates、setup

### 4.1 config/codesop-router.md — 路由表（直接写入）

不再有单独的 inventory 文件。路由表就是那张完整表格：

```markdown
## codesop 路由卡 (v2)

新任务必须先输出任务对齐块（理解 + 阶段 + Skill）。
完整 pipeline 定义见 /codesop。

### 技能总表（按项目生命周期排序）

| 大类 | 优选 | 来源 | Skill | 什么时候用 |
|------|------|------|-------|-----------|
| **1. 需求分析与设计** | | | | |
| | ★ | sp | brainstorming | 任何新功能/改动前：理解需求→澄清问题→出设计方案→写 spec→spec 自审→用户审阅 |
| | ★ | plugin | frontend-design | 做前端 UI 时：强制设计思维阶段，拒绝通用 AI 审美，独特的排版/配色/动效 |
| **2. 生成执行文档** | | | | |
| | ★ | sp | writing-plans | spec 已批准，拆成可执行的分步任务 |
| **3. 开发与执行** | | | | |
| | ★ | sp | using-git-worktrees | 开发前创建隔离工作区 |
| | ★ | sp | subagent-driven-development | 日常首选，内含 TDD + 两阶段 review + 自动 finishing |
| | | sp | dispatching-parallel-agents | 2+ 个完全独立任务并行加速时 |
| | | sp | executing-plans | 自己串行执行计划（不用子 agent） |
| | | sp | requesting-code-review | 开发中完成一个功能后提前让 AI 审一遍 |
| **4. 测试与验证** | | | | |
| | ★ | sp | verification-before-completion | 声明完成前必须运行验证命令确认输出 |
| | | plugin | code-simplifier | 功能验证通过后，自动优化代码可读性和结构 |
| | | sp | test-driven-development | 单独使用 TDD 红绿重构（subagent-driven-development 已内置） |
| **5. 提交 PR** | | | | |
| | ★ | sp | finishing-a-development-branch | 测试通过后提交 PR 或合并 |
| **6. 代码审查** | | | | |
| | ★ | plugin | code-review | PR 提交后自动审查：5 agent 并行 + 置信度评分 + 自动发评论 |
| | | plugin | codex:review | 需要 OpenAI 第二意见审查代码 diff 时（独立视角） |
| | | plugin | codex:adversarial-review | 高风险操作需要挑战设计假设和实现选择时 |
| | | sp | receiving-code-review | 收到 code-review 评论后，先技术评估再执行 |
| **7. 前端测试与自动化** | | | | |
| | | plugin | playwright | 日常页面操作：导航/截图/填表/点击/JS 执行 |
| | | skill | browser-use | 需要登录态/云浏览器/tunnel 时的补充 |
| **8. 调试与调查** | | | | |
| | ★ | sp | systematic-debugging | 遇到 bug/测试失败/异常行为时，假设驱动逐步排查（修 bug 必走） |
| **9. 文档管理** | | | | |
| | | plugin | claude-md-management | CLAUDE.md 质量审计：6 维度评分→出报告→定向修复 |
| | | plugin | context7 | 查询第三方库/框架的最新文档和代码示例 |
| **10. Skill 开发** | | | | |
| | ★ | plugin | skill-creator | Skill 全生命周期：创建→测试→基准评估→盲测 A/B→描述优化 |
| | | sp | writing-skills | 轻量备选：创建/编辑 skill 的流程指导 |
| **11. 项目编排** | | | | |
| | ★ | skill | codesop | 项目工作台：上下文恢复→路由推荐→fit 验证→完成关卡 |
| **12. 通讯桥梁** | | | | |
| | | skill | claude-to-im | Claude Code 桥接到 Telegram/Discord/飞书/QQ/微信 |
| **13. 应急接管** | | | | |
| | | plugin | codex:rescue | 线程卡住或需要换个智能体重新来过时，把任务交给 Codex 接管 |

### 调试路径（Codex P1-1 修正）
用户说"修 bug"、"测试挂了"、"为什么坏了"、"这个不工作了"时：
→ systematic-debugging（假设驱动排查）→ verification-before-completion → finishing-a-development-branch
跳过需求分析和执行文档阶段，直接进入调试。

### 铁律
- 跳过必走 Skill = 先输出对齐块说明原因
- 不确定 → 先调用 /codesop
```

**关键变化**：
- 去掉"必走路径"和"可选路径"分离，统一为一张生命周期表
- 去掉所有 GStack skill 引用
- 新增第 8 类"调试与调查"，把 systematic-debugging 提升为必走（Codex P1-1 修正）
- 新增"调试路径"段，明确 bug-fix 走向
- 生命周期顺序：需求→文档→开发→测试→提交→审查→前端→调试→文档→Skill→编排→通讯→应急
- 这是唯一路由源，setup 同步到 `~/.claude/codesop-router.md`

### 4.2 SKILL.md 重写

**从 409 行 → ~250 行**

```
结构：
1. 元数据（name, description, allowed-tools）
2. 总览（codesop 是什么、技术栈 = Superpowers + 插件）
3. 工作流（5 步）
   Step 1: 读上下文（AGENTS.md + PRD.md + git status）
   Step 2: 生成工作台摘要
   Step 3: 读路由表（codesop-router.md）
   Step 4: 基于用户信号匹配"什么时候用"列，推荐 skill
   Step 5: Fit 验证 — 读推荐 skill 的完整内容，评估 ✅/⚠️/❌/❓
4. Git 上下文验证（保留现有逻辑）
5. 完成关卡 — 调用 claude-md-management 审计 CLAUDE.md，
   补充检查 PRD.md 和 README.md 是否需要根据本次变更更新
6. 冲突解决规则（精简，去掉 GStack 相关条目）
7. 铁律（保留）
```

**去掉的内容**：
- 28 处 GStack 引用
- 具体的 skill 路由定义（路由表已经定义了）
- autoplan/codex-gs/office-hours 等所有 GStack 路径

### 4.3 lib/updates.sh 重写

**从 525 行 → ~300 行**

职责：**版本检查 + 完整性检查 + 路由覆盖**

**依赖分级（Codex P2-3 修正）**：

```bash
# 核心依赖 — 缺失 = 报错
CORE_PLUGINS=(
  "superpowers@claude-plugins-official"
  "code-review@claude-plugins-official"
)

# 可选依赖 — 缺失 = 提示建议安装，不报错
OPTIONAL_PLUGINS=(
  "skill-creator@claude-plugins-official"
  "frontend-design@claude-plugins-official"
  "context7@claude-plugins-official"
  "code-simplifier@claude-plugins-official"
  "playwright@claude-plugins-official"
  "claude-md-management@claude-plugins-official"
  "codex@openai-codex"
)

# 独立 Skill — 缺失 = 提示，不报错
OPTIONAL_SKILLS=(
  "codesop"
  "browser-use"
  "claude-to-im"
)
```

**检查逻辑**：

1. `check_plugin_completeness()` — 遍历 CORE + OPTIONAL，读 installed_plugins.json，核心缺失报错，可选缺失提示
2. `check_skill_completeness()` — 遍历 OPTIONAL_SKILLS，检查目录存在，缺失提示
3. `check_plugin_versions()` — 版本检查策略（基于调研确认）：
   - **superpowers**：通过 GitHub tags (`git ls-remote --tags anthropics/claude-plugins-official`) 对比最新版本，保留现有逻辑。这是唯一能做语义版本对比的插件（package.json 有版本 + tags 有版本）
   - **其他 8 个插件**：只检查存在性，不做版本对比。原因：`installed_plugins.json` 中 5 个插件版本为 `"unknown"`，3 个虽有版本号但无"最新版"来源（市场 repo 无 tags/package.json）。用户通过 `/plugin update` 重装即为最新
   - 不对 codex 做 gitCommitSha 对比（重装即最新，不值得加复杂度）
4. `check_routing_coverage()` — 读 codesop-router.md 表格中所有 skill 名称，验证每个都有对应的插件/skill 安装
5. `print_dependency_report()` — 汇总输出

**去掉**：
- `plugin_update_check()` 中的 GStack CHANGELOG 逻辑
- `scan_installed_skills()` 中的 GStack 扫描
- 所有 `has_gstack` / `gstack_*` 调用

### 4.4 lib/detection.sh 修改

**从 263 行 → ~240 行**

- 从 `ECOSYSTEM_REGISTRY` 删掉 gstack 条目
- 新增 `has_plugin()` 函数 — 读 installed_plugins.json 检查
- `has_superpowers` 保留
- 删掉 `has_gstack` 和所有 gstack 检测函数

### 4.5 lib/init-interview.sh 修改

**从 891 行 → ~850 行**

- 删掉 31 处 GStack 引用
- 删掉 `has_gstack()` 调用和 gstack 版本检测
- 新增插件完整性检查（调用 `has_plugin`）
- 用户偏好访谈、项目文件生成流程不变

### 4.6 setup 修改

**从 265 行 → ~260 行**

- 删掉 2 处 GStack 引用（安装检查和 warning）
- 同步路由表（codesop-router.md → ~/.claude/codesop-router.md）逻辑保留
- 新增：检查 installed_plugins.json 是否有核心插件，缺的提示安装命令
- Codex/OpenCode 安装函数保留但标注为兼容模式

### 4.7 其他文件

| 文件 | 改动 |
|------|------|
| lib/output.sh (166行) | 去掉 GStack 相关显示逻辑 |
| lib/templates.sh (377行) | 模板中去掉 GStack 引用 |
| lib/commands.sh (144行) | update 命令中去掉 GStack 检查 |
| commands/codesop-init.md | 去掉 GStack 示例 |
| commands/codesop-update.md | 去掉 GStack 更新说明 |
| templates/init/prompt.md | 去掉 GStack 引用 |
| templates/system/AGENTS.md | 去掉 GStack 引用 |
| VERSION | 1.1.6 → 2.0.0 |
| CHANGELOG.md | 新增 v2.0 条目 |

## 5. 影响评估

| 维度 | 影响 |
|------|------|
| 删除代码 | ~150 行（GStack 引用 + 废弃逻辑） |
| 新增代码 | ~80 行（插件检查、新路由表、调试路径） |
| 净变化 | 总行数从 ~3076 → ~2900 |
| 测试 | 6 个测试套件全部需要更新路由表断言 |
| 向后兼容 | 不兼容 — v1.x 路由不适用于 v2.0 |

## 6. 验收标准

1. `grep -r "gstack\|GStack" --include="*.sh" --include="*.md" lib/ setup SKILL.md config/ commands/ templates/` 返回 0 结果（Codex P2-5 修正：限定运行时文件）
2. `bash tests/codesop-router.sh` 全部通过（需更新测试断言）
3. `bash setup --host claude` 成功同步路由表
4. 路由表覆盖所有 9 个已装插件 + 3 个独立 skill
5. `codesop update` 正确报告核心插件缺失（报错）和可选插件缺失（提示）
6. `codesop update` 对 superpowers 做版本对比，对其他插件只检查存在性
7. VERSION = 2.0.0

## 7. Codex 审查意见追踪

| # | 严重度 | 问题 | 处理 | 设计决策 |
|---|--------|------|------|---------|
| 1 | P1 | 缺少 bug-fix 路由 | 新增第 8 类"调试与调查" + "调试路径"段 | D11 |
| 2 | P1 | 多宿主兼容性断裂 | 正式只支持 Claude Code，Codex/OpenCode 兼容保留 | D10 |
| 3 | P2 | REQUIRED 全必装太严格 | 拆为 CORE + OPTIONAL + OPTIONAL_SKILLS | D9 |
| 4 | P2 | 版本检查无来源 | superpowers 用 GitHub tags，其他只检查存在性 | D12 |
| 5 | P2 | grep 验收范围太宽 | 限定运行时文件目录 | D13 |
