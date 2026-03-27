# /codesop 智能路由器设计

## 背景

当前 `/codesop` 是 CLI 的薄包装，无参数时跑 `run_diagnose`。诊断信号收集简陋（只有 git 状态 + 5 个文件存在检查），`recommend_skills()` 是 stub（只列出所有技能不做匹配）。用户打开新项目后不知道下一步该做什么。

## 目标

将 `/codesop` 改为智能路由器：先输出轻量项目诊断，再基于诊断结果推荐具体行动。

## 架构

CLI 诊断 + skill 路由，和 `init` 的协作模式一致。

### CLI 层

`codesop`（无参数）调用增强版 `run_diagnose`：

- 复用 `detect_environment()` 获取语言、框架、AI 工具、技能状态
- 补充项目阶段信号：git 分支模式、未提交变更数、配置文件存在性
- 轻量输出，3-5 行结构化文本

输出格式：
```
项目状态：
  主语言：TypeScript | 框架：Next.js
  配置：AGENTS.md ✓ PRD.md ✓ CLAUDE.md ✗
  Git：feature/auth (3 ahead, 2 uncommitted)
  技能：superpowers 5.0.6 ✓ gstack 0.12.5.0 ✓
```

### Skill 层

`/codesop` skill 读取 CLI 输出，匹配场景，推荐行动。

三个场景：

| 场景 | 信号特征 | 推荐行动 |
|------|---------|---------|
| 全新项目 | 无 AGENTS.md 且无 CLAUDE.md | `/codesop init` |
| 半成品 | 有配置但缺关键项（无 PRD、无测试、技能未安装） | 提示缺失项 + 对应命令 |
| 活跃开发 | feature/fix/refactor 分支 + 未提交变更 | 推荐开发技能（brainstorm/write-plan/TDD） |

输出 2-3 条建议，每条：推荐命令 + 一句话理由。

## 变更范围

### 修改

- `lib/commands.sh`：重写 `run_diagnose`，调用 `detect_environment()` + 轻量输出
- `commands/codesop.md`：重写 skill 文件，增加路由逻辑
- `codesop` 入口：无参数时仍调用 `run_diagnose`（接口不变）

### 删除

- `scripts/collect-signals.sh`
- `scripts/diagnose.sh`
- `scripts/recommend.sh`

### 不变

- `lib/detection.sh`：`detect_environment()` 不变，被 diagnose 复用
- `lib/init-interview.sh`：init 流程不受影响
- `/codesop-init`、`/codesop-status` 等其他 skill 不变

## 设计决策

1. **为什么不用 JSON 输出**：结构化文本对人类和 AI 都友好，且不需要额外解析库
2. **为什么废弃 scripts/**：逻辑内化到 lib/ 后更易测试和维护，且复用 `detect_environment()` 后 scripts/ 的独立采集没有存在意义
3. **为什么不做停滞项目检测**：长期无提交的项目不需要状态确认，直接推荐有价值的行动
4. **为什么 skill 不直接调 CLI 子命令**：skill 只推荐，让用户/AI 决定是否执行，避免意外副作用
