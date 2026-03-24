# codesop 使用说明

## 你只需要记住一件事

```
cd ~/codesop && vim SKILL.md
```

在这里改文件。改完提交。其他电脑拉一下。

## `/codesop init`

`/codesop init [path]` 会先做几件事：

- 扫描当前项目，判断主语言、项目类型、常见框架
- 默认中文生成项目配置
- 检测你本机上有哪些 AI 编码工具
- 检测 `superpowers`、`gstack` 是否已经装好
- 生成完整 `AGENTS.md`、导入型 `CLAUDE.md`、独立 `PRD.md`
- 如果已有 `AGENTS.md`，保留原文件，并输出终端合并优化建议
- 自动推断测试、lint、类型检查、smoke 命令并写入模板
- 如果缺失，会按当前宿主工具提示安装命令，确认后由当前大模型继续执行
- 如果已经装好，会提示更新命令，确认后也可继续执行

输出会固定分成几块：

- 项目识别
- 环境识别
- 配置计划
- 建议安装命令 / 更新建议
- 下一步

如果你已经跑过安装脚本，也可以直接这样用：

```bash
codesop init .
```

## 完整流程

```bash
# 1. 新电脑安装（只需一次）
curl -sSL https://raw.githubusercontent.com/veniai/codesop/main/install.sh | bash

# 2. 改东西
cd ~/codesop
vim SKILL.md        # 改工作流
vim AGENTS.md       # 改全局规则

# 3. 提交
git add .
git commit -m "改了什么"
git push

# 4. 其他电脑同步
cd ~/codesop
git pull
```

## 文件说明

```
~/codesop/
├── SKILL.md       ← 工作流指南（改这个）
├── AGENTS.md      ← 全局规则（改这个）
├── codesop        ← CLI 入口
└── install.sh     ← 安装脚本（别动）
```

## 它干了什么

装完之后，Claude Code / OpenClaw / Codex CLI 都能读到你的 SOP。
改一次文件，三个工具自动同步。

## 查看状态

```bash
cd ~/codesop && git status    # 有改动吗
cd ~/codesop && git log --oneline  # 改了什么
```
