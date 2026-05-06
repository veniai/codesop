[English](README.en.md) | **中文**

<p align="center">
  <img src="docs/assets/codesop-readme-hero.png" alt="codesop — AI Coding SOP" width="100%">
</p>

<p align="center">
  <strong>装一个，AI 编码全家桶</strong><br>
  10 个精选 Skill 一键安装 · AI 自动拥有 SOP 纪律 · 覆盖编码全流程
</p>

<p align="center">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License">
  <img src="https://img.shields.io/badge/Claude_Code-Plugin-blue.svg" alt="Claude Code">
  <img src="https://img.shields.io/github/v/tag/veniai/codesop?label=version&color=blue" alt="Version">
</p>

---

> Claude Code 插件眼花缭乱，不知道装哪些？AI 写代码没纪律，想改就改？长任务做到一半就失控？
>
> **codesop 解决这些问题。** 一条命令安装 10 个经过实践验证的核心 Skill，装完直接用。

## 快速体验

把下面这段话**复制粘贴**给你的 AI 编码助手：

```text
请帮我安装 codesop —— AI 编码工作流操作系统。步骤如下：
1. git clone https://github.com/veniai/codesop.git ~/codesop
2. cd ~/codesop && bash install.sh
3. 确认 ~/.local/bin/codesop 可执行（如不在 PATH，帮我加到 ~/.bashrc 或 ~/.zshrc）
4. 在当前项目目录运行 codesop init 初始化项目
安装完成后，告诉我如何使用 /codesop 工作台。
```

安装成功后（在 Claude Code 中）：

```
/codesop init      # 初始化当前项目
/codesop           # 打开工作台，开始工作
/codesop update    # 更新 codesop，并自动升级所有依赖插件
```

<details>
<summary>手动安装</summary>

```bash
git clone https://github.com/veniai/codesop.git ~/codesop
cd ~/codesop && bash install.sh    # 自动安装 codesop + 全部依赖插件
```

确保 `~/.local/bin` 在你的 `PATH` 中。

</details>

## 为什么用 codesop

**精选全家桶，不用自己挑** — 10 个核心 Skill 自动安装：需求分析、设计审查、TDD、调试、代码审查、文档管理、前端设计、浏览器测试……全流程覆盖，经过实践验证，不踩坑

**AI 自动守纪律** — 四条 SOP 铁律硬约束：先设计再编码、先失败再生产、无根因不修 bug、无证据不完工。AI 不能随便写代码

**路由自动化** — 不知道该用什么 Skill？路由表自动选择。新功能走 brainstorming → plan → dev → verify，修 bug 走 debugging → verify，不用你自己判断

**长任务不失控** — Pipeline task list 自动拆分、顺序执行、☐/☑ 进度可视化。长时间开发任务也能稳定推进

**上下文不丢失** — 每次进入项目，AI 自动恢复完整上下文。不用担心 AI 忘了之前做了什么

## 覆盖场景

| 你想做什么 | /codesop 的链路 |
|-----------|----------------|
| 新功能 | brainstorming → 设计审查 → 计划 → 开发 → 验证 → 提交 PR |
| 修 Bug | 根因定位 → 验证 → 提交 PR |
| 小改动 | 开发 → 验证 → 提交 PR |
| PR 反馈 | 评估意见 → 修复 → 全量测试 → 提交 |

## Skill 全家桶

以下 Skill 安装时自动配置，无需手动操作：

| Skill | 能力 |
|-------|------|
| superpowers | brainstorming, writing-plans, TDD, systematic-debugging, subagent-dev, verification |
| code-review | 5 agent 并行 PR 审查 + 置信度评分 |
| codex | 双 AI 审查（设计 + 代码审查阶段） |
| frontend-design | 强制设计思维，拒绝通用 AI 审美 |
| context7 | 第三方库/框架最新文档实时查询 |
| code-simplifier | 代码润色（可读性 + 结构优化） |
| playwright | 页面交互与自动化测试 |
| chrome-devtools-mcp | 浏览器诊断：性能分析 / a11y 审计 |
| claude-md-management | CLAUDE.md 质量审计与文档漂移检查 |
| skill-creator | Skill 全生命周期管理 |

运行 `/codesop update` 可一键升级所有已安装 Skill。

<details>
<summary>初始化项目</summary>

```bash
/codesop init
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

</details>

## 相关项目

- **[cc-monitor](https://github.com/veniai/cc-monitor)** — Claude Code 远程监控与控制。任务完成自动通知到微信/钉钉/飞书，会话卡死自动恢复，手机远程发命令

## License

MIT
