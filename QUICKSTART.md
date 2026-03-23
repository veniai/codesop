# codesop 使用说明

## 你只需要记住一件事

```
cd ~/codesop && vim SKILL.md
```

在这里改文件。改完提交。其他电脑拉一下。

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
