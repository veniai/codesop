# 设计：codesop init 适配模式

日期：2026-04-09
状态：已批准

## 背景

`codesop init` 目前只支持全新项目初始化。当 codesop 模板更新后（如新增 §8 并行开发记录、§4 版本历史等），已有项目无法同步这些变更。需要一个适配模式，让已有项目采纳模板更新，且所有变更由用户逐项确认。

## 模式检测

当 `/codesop init` 触发时（通过 skill），AI 在 Step 4 执行 CLI 前判断模式：

| 条件 | 模式 |
|------|------|
| 项目缺少 AGENTS.md 或 PRD.md 或 README.md 任何一个 | 新建 |
| 三个文件都存在 | 适配 |

不做内容检测。理由：同时存在这三个文件的项目几乎一定是 codesop 初始化过的。

## update 联动

`codesop update` 拉到新版本后，检测模板文件是否有变更：

```bash
git diff "$old_hash".."$new_hash" -- templates/ --quiet
```

- 有变更 → 在 update 输出末尾追加："模板已更新，建议对已有项目运行 /codesop init"
- 无变更 → 不输出额外内容

只在"有新提交"分支执行此检查。其他分支没有拉到新远端代码，不需要检查。

## 新建模式改动

Step 5（提示用户运行 /init）的指令从"运行 /init 生成项目级 CLAUDE.md"改为：

> 初始化完成。请在当前会话中运行 `/init` 生成项目级 CLAUDE.md。参考系统级 CLAUDE.md 中对项目文档的要求。

不改其他。`/init` 自己会读系统级 CLAUDE.md，理解项目 CLAUDE.md 该放什么。

## 适配模式行为

适配发生在 **skill 层面**（`commands/codesop-init.md`），不是 CLI 层面。CLI 照常跑 Phase 0-4，Step 4 完成后 skill 多一个适配环节。

### 控制流

```
Step 0: codesop update（现有）
Step 1-3: 偏好检查（现有）
Step 4: CLI 执行 init（现有）
         ↓
    三个核心文件都存在？
         │              │
        是             否
         │              │
         ↓              ↓
    适配模式          新建模式
         │           （现有行为）
         ↓
    AI 做两件事：
    ① 模板适配（PRD.md、README.md）
       对比 templates/project/ 和项目文件，列出差异建议
    ② 去重检测（CLAUDE.md）
       对比项目 CLAUDE.md 和 templates/system/AGENTS.md
       发现重复内容，建议清理
         │
         ↓
    输出建议清单，用户逐项确认后执行
         │
         ↓
    Step 5: 正常完成
```

CLI 需要输出一个明确信号（如 `ADAPT_MODE:YES`），让 skill 知道应走适配流程。

### 对比映射

```
templates/project/PRD.md     ←→  项目 PRD.md       （模板适配）
templates/project/README.md  ←→  项目 README.md    （模板适配）
templates/system/AGENTS.md   ←→  项目 CLAUDE.md    （去重检测）
```

### 核心原则

**AI 建议，用户确认，改什么用户说了算。**

- AI 列出所有差异（新增、修改、删除、结构调整都可以建议）
- 用户逐项确认（可以全选、全不选、或逐个 y/n）
- AI 只执行用户确认的变更
- 对比范围：PRD.md、README.md、CLAUDE.md — 所有项目文件

### 不做的事

- 不规定 AI 的 diff 算法
- 不限制只能加不能删
- 不生成中间文件
- 不自动执行适配（必须用户触发）
- 不持久化差异信息
- 不改新建模式的核心流程（只改 Step 5 的提示语）

## 文件变更清单

| 文件 | 改什么 |
|------|--------|
| `lib/commands.sh` | `run_update()` "有新提交"分支加 templates/ diff 检测 + 提示 |
| `commands/codesop-init.md` | 新建模式 Step 5 提示语；适配模式完整流程指令 |
| `lib/init-interview.sh` | `generate_project_files()` 输出 `ADAPT_MODE:YES` 信号 |
| `CLAUDE.md` | Init Flow 表格更新 |
| `tests/codesop-init.sh` | 适配模式测试 |
| `tests/codesop-init-interview.sh` | 信号输出测试 |
