[English](README.en.md) | **中文**

<p align="center">
  <img src="docs/assets/codesop-readme-hero.png" alt="codesop — AI Coding SOP" width="100%">
</p>

<p align="center">
  <strong>Skill-first 的 AI 编码工作流操作系统</strong><br>
  让 AI 拥有 SOP 纪律 — 知道用什么 Skill、按什么顺序、什么时候停下来验证
</p>

<p align="center">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License">
  <img src="https://img.shields.io/badge/Claude_Code-Plugin-blue.svg" alt="Claude Code">
  <img src="https://img.shields.io/badge/version-3.6.0-blue.svg" alt="Version">
</p>

---

> 不知道怎么让 AI 帮你写代码？不知道该给 AI 准备什么文档？长任务做到一半就失控？AI 写完代码你不敢用？
>
> codesop 解决这些问题。装一次，所有项目 AI-ready。

## 快速体验

把下面这段话**复制粘贴**给你的 AI 编码助手：

```text
请帮我安装 codesop —— AI 编码工作流操作系统。步骤如下：
1. git clone https://github.com/veniai/codesop.git ~/codesop
2. cd ~/codesop && bash install.sh
3. 确认 ~/.local/bin/codesop 可执行（如不在 PATH，帮我加到 ~/.bashrc 或 ~/.zshrc）
4. 在当前项目目录运行 codesop init . 初始化项目
安装完成后，告诉我如何使用 /codesop 工作台。
```

安装成功后（在 Claude Code 中）：

```
/codesop init .    # 初始化当前项目
/codesop           # 打开工作台，开始工作
/codesop update    # 更新到最新版本
```

<details>
<summary>手动安装</summary>

```bash
git clone https://github.com/veniai/codesop.git ~/codesop
cd ~/codesop && bash install.sh
```

确保 `~/.local/bin` 在你的 `PATH` 中。

</details>

## 它能做什么

`/codesop` 是你的 AI 编码工作台。每次进入项目：

1. **恢复上下文** — 自动读取 AGENTS.md 和 PRD.md，理解项目当前状态
2. **路由推荐** — 根据你的意图，从路由表中选择最佳 Skill 链路
3. **Pipeline 执行** — 链路转为 task list（☐/☑ 可视化进度），逐步自动执行
4. **验证关卡** — 每步完成前必须通过验证，不允许跳过

跨工具支持：Claude Code（主要）· Codex · OpenCode

## 核心亮点

**一键初始化** — 安装后运行 `/codesop init .`，自动生成 AI 协作文档：AGENTS.md（AI 纪律）、PRD.md（产品进度）、README.md（如缺失则生成）、ADR（架构决策）。同时同步系统级配置到 `~/.claude/CLAUDE.md`。装一次，所有项目 AI-ready

**SOP 四条铁律** — 先设计再编码 · 先失败再生产 · 无根因不修 bug · 无证据不完工。AI 不能随便写代码，每一步都有纪律约束

**Skill 路由** — 不知道该用什么 Skill？路由表自动选择。新功能走 brainstorming → plan → dev → verify，修 bug 走 debugging → verify，不用你自己判断

**长任务编排** — Pipeline task list 自动拆分、顺序执行、☐/☑ 进度可视化。长时间开发任务也能稳定推进，不会中途失控

**循环追问** — brainstorming Skill 采用迭代式需求澄清：一轮提问 → 理解 → 再追问，逐步逼近真实需求，拒绝拍脑袋开工

**Context 管理** — 每次进入项目，AI 自动读取 AGENTS.md（纪律）+ PRD.md（产品进度），恢复完整上下文。不用担心 AI 忘了之前做了什么

**ADR 架构决策记录** — 自动检测架构决策冲突。涉及跨模块改动时，先读 ADR 再动手，避免重复决策和矛盾

**文档关卡** — 任务完成前自动判定 CLAUDE.md / PRD.md / README.md 是否需要更新，防止文档落后于代码

## 覆盖场景

| 你想做什么 | /codesop 的链路 |
|-----------|----------------|
| 新功能 | brainstorming → 设计审查 → 计划 → 开发 → 验证 → 提交 PR |
| 修 Bug | 根因定位 → 验证 → 提交 PR |
| 小改动 | 开发 → 验证 → 提交 PR |
| PR 反馈 | 评估意见 → 修复 → 全量测试 → 提交 |

<details>
<summary>Skill 生态</summary>

codesop 编排以下 Skill：

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

</details>

<details>
<summary>初始化项目</summary>

```bash
/codesop init .
```

自动扫描项目形态，生成 AI 助手所需的项目文件：

- `AGENTS.md` → `@CLAUDE.md`（AI 入口）
- `PRD.md` → 产品规范 + 进度 + 工作日志
- `README.md` → 安装/运行/测试命令（如不存在）
- `docs/adr/` → 架构决策记录

</details>

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

`VERSION` 是发布版本的唯一真相源。Skill 路由完成后，最后一行输出自然语言工作流指令。路由前执行文档漂移扫描，确保项目文档不落后。

</details>

<details>
<summary>测试</summary>

```bash
bash tests/run_all.sh
```

</details>

## License

MIT
