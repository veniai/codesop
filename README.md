[English](README.en.md) | **中文**

<p align="center">
  <img src="docs/assets/codesop-readme-hero.png" alt="codesop — AI Coding SOP" width="100%">
</p>

<p align="center">
  <strong>Skill-first 的 AI 编码工作流操作系统</strong><br>
  上下文恢复 · Skill 路由 · Pipeline task list · 验证与文档完成关卡
</p>

<p align="center">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License">
  <img src="https://img.shields.io/badge/Claude_Code-Plugin-blue.svg" alt="Claude Code">
  <img src="https://img.shields.io/badge/version-3.5.2-blue.svg" alt="Version">
</p>

---

> 让 AI 助手在任意项目中拥有统一的 workflow 纪律——<br>
> 知道用什么 skill、按什么顺序执行、什么时候该停下来验证。

## 快速体验

在你的 AI 编码助手中发送：

> 帮我安装 codesop：https://github.com/veniai/codesop

AI 会自动完成克隆和配置。然后：

```bash
/codesop init .    # 初始化当前项目
/codesop           # 打开工作台
```

<details>
<summary>手动安装</summary>

```bash
git clone https://github.com/veniai/codesop.git ~/codesop
cd ~/codesop && bash install.sh
```

确保 `~/.local/bin` 在你的 `PATH` 中。

</details>

## 它做什么

`/codesop` 是你的 AI 编码工作台。每次进入项目时：

1. **恢复上下文** — 读取 AGENTS.md、PRD.md，理解项目当前状态
2. **路由推荐** — 根据你的意图，组装最合适的 skill 链路
3. **Pipeline 执行** — 将链路转为 task list，逐步自动执行
4. **验证关卡** — 每个环节完成前必须通过验证，不允许跳过

跨工具支持：Claude Code（主要）· Codex · OpenCode

## 覆盖场景

| 你想做什么 | /codesop 的链路 |
|-----------|----------------|
| 新功能 | brainstorming → 设计审查 → 计划 → 开发 → 验证 → 提交 PR |
| 修 Bug | 定位根因 → 验证 → 提交 PR |
| 小改动 | 开发 → 验证 → 提交 PR |
| PR 反馈 | 评估意见 → 修复 → 全量测试 → 提交 |

## 初始化项目

```bash
/codesop init .
```

自动扫描项目形态，生成 AI 助手所需的项目文件：

- `AGENTS.md` → `@CLAUDE.md`（AI 入口）
- `PRD.md` → 产品规范 + 进度 + 工作日志
- `README.md` → 安装/运行/测试命令（如不存在）
- `docs/adr/` → 架构决策记录

## Skill 生态

codesop 编排以下 skill：

- **[superpowers](https://github.com/obra/superpowers)** — brainstorming, writing-plans, TDD, systematic-debugging, subagent-dev, verification
- **code-review** — 5 agent 并行 PR 审查 + 置信度评分
- **codex** — 双 AI 审查（设计 + 代码审查阶段）
- **claude-md-management** — 文档漂移检查
- **code-simplifier** — 代码润色

```bash
/plugin install superpowers                      # Claude Code
/plugin install code-review
/plugin marketplace add openai/codex-plugin-cc
```

<details>
<summary>架构</summary>

```
codesop                     # CLI 入口
setup                       # 宿主安装与同步
├── lib/                    # 核心 shell 模块
├── SKILL.md                # /codesop 定义
├── commands/               # Slash 命令文件
├── config/
│   └── codesop-router.md   # 路由卡
├── templates/
│   ├── system/             # 系统级 AGENTS.md 模板
│   ├── project/            # PRD.md, README.md 模板
│   └── init/               # Init prompt 模板
├── tests/                  # 合同测试
├── AGENTS.md               # → @CLAUDE.md
├── CLAUDE.md               # 项目指南
├── PRD.md                  # 活文档
```

</details>

<details>
<summary>测试</summary>

```bash
bash tests/run_all.sh
```

</details>

## License

MIT
