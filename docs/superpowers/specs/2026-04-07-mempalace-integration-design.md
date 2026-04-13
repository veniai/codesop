# MemPalace 集成设计 spec

Date: 2026-04-07
Status: draft
Scope: codesop 集成 MemPalace AI 记忆系统

## 1. 背景与目标

MemPalace 是一个本地优先的 AI 记忆系统（pip 安装，MCP server 集成），让 AI 跨会话保持记忆。codesop 作为"水电工"，负责安装检测、配置状态报告、安装指引。

**目标**：用户跑一次 `codesop update` 就能知道 MemPalace 的安装/配置状态，获得完整的安装指引。

**不目标**：控制 AI 如何使用记忆工具（那是 MemPalace MCP server 的事）。

**宿主范围**：阶段一只支持 Claude Code 宿主。`~/.claude/settings.json` 和 `claude mcp add` 是 Claude 专属路径。Codex/OpenCode 等其他宿主暂不检测，输出时标注"仅 Claude"。

## 2. 两阶段策略

### 阶段一（现在）：轻量检测 + 安装指引

上游 MemPalace 不成熟（发布仅 2 天，版本号不一致，`init` 不能非交互，无 `--version` 命令）。投入完整自动化风险高。

codesop 只做：
- 检测安装状态（CLI 是否存在）
- 检测 MCP 配置状态（settings.json 中是否有 mempalace 条目）
- 输出官方安装命令（不改装、不包装）
- 不做版本读取（上游无 `--version`，`pip show` 版本号不可信）

**改动文件**：`lib/updates.sh`（检测函数 + 安装指引 + 集成到报表）、`SKILL.md`（Skill 生态展示）、`tests/skill-routing-coverage.sh`（新测试）。

### 阶段二（上游稳定后）：完整集成

切换条件（每条必须可执行验收）：

| 条件 | 验收方式 |
|------|---------|
| `mempalace --version` 可用且版本一致 | `mempalace --version` exit 0 且输出与 pyproject.toml 一致 |
| `mempalace init` 支持非交互 | `mempalace init --yes /tmp/empty_dir` 在 CI 中无交互完成 |
| MCP 工具签名稳定 | 工具清单快照与基线文件对比一致 |
| 有正式 release 流程 | 上游发布带 git tag 且 CHANGELOG.md 可解析 |

完整集成包括：
- `setup --host claude` 自动配置 MCP server（`claude mcp add`）
- `setup` 自动配置 Stop + PreCompact hooks
- AGENTS.md 模板加 MemPalace 唤醒指令
- 版本对比 + 更新 changelog 展示
- `codesop init` 可选触发 `mempalace init`

## 3. 阶段一详细设计

### 3.1 检测函数：check_mempalace_status()

Phase 1 只有 mempalace 一个 MCP 工具，不做泛化抽象。直接写专用函数。

状态模型为三态，避免"无法判断"误报为"未配置"：

| 状态 | 含义 | 计入"就绪" |
|------|------|-----------|
| `ok` | CLI 存在 + MCP 已配置 | 是 |
| `cli_missing` | CLI 未安装 | 否 |
| `mcp_missing` | CLI 已装 + MCP 未配置 | 否 |
| `unknown` | CLI 已装但无法检查 MCP（jq 缺失或 settings.json 不存在） | 不计 |

```bash
check_mempalace_status() {
  local settings_file="$HOME/.claude/settings.json"

  # 检测 CLI 安装
  if ! command -v mempalace >/dev/null 2>&1; then
    printf '%s\n' "⚠️ MemPalace: 未安装"
    printf '%s\n' "  安装:"
    printf '    pip install mempalace\n'
    printf '    %s\n' "https://github.com/milla-jovovich/mempalace"
    printf '%s\n' "  安装后步骤（仅 Claude Code 宿主）:"
    printf '    1. mempalace init <项目目录>\n'
    printf '    2. mempalace mine <项目目录>\n'
    printf '    3. claude mcp add mempalace -- python -m mempalace.mcp_server\n'
    return 0
  fi

  # 检测 MCP 配置（三态）
  if [ ! -f "$settings_file" ]; then
    printf '%s\n' "? MemPalace: 已安装，MCP 配置状态未知（settings.json 不存在）"
    printf '%s\n' "  配置（仅 Claude Code 宿主）:"
    printf '    claude mcp add mempalace -- python -m mempalace.mcp_server\n'
    return 0
  fi

  if ! command -v jq >/dev/null 2>&1; then
    printf '%s\n' "? MemPalace: 已安装，MCP 配置状态未知（jq 未安装）"
    printf '%s\n' "  配置（仅 Claude Code 宿主）:"
    printf '    claude mcp add mempalace -- python -m mempalace.mcp_server\n'
    return 0
  fi

  if jq -e --arg name "mempalace" '.mcpServers | has($name)' "$settings_file" 2>/dev/null | grep -q true; then
    printf '%s\n' "✓ MemPalace: 已安装并配置"
  else
    printf '%s\n' "⚠️ MemPalace: 已安装但 MCP 未配置"
    printf '%s\n' "  配置（仅 Claude Code 宿主）:"
    printf '    claude mcp add mempalace -- python -m mempalace.mcp_server\n'
    printf '    %s\n' "注意: 安装后重启 Claude Code 生效"
    printf '    %s\n' "初始化: mempalace init <项目目录>"
    printf '    %s\n' "数据导入: mempalace mine <项目目录>"
  fi

  return 0
}
```

### 3.2 集成到 print_dependency_report()

插入位置（精确顺序）：

1. 插件完整性（现有）
2. 独立 Skill（现有）
3. 路由覆盖（现有）
4. 文档一致性（现有）
5. **MCP 服务**（新增，在此处插入）
6. 更新建议（现有，仅 Claude 宿主）

```bash
printf '\n%s\n' "MCP 服务："
check_mempalace_status
```

### 3.3 集成到 SKILL.md

§3 step 5 的依赖报告新增一行：

```bash
(source ~/codesop/lib/output.sh && source ~/codesop/lib/updates.sh && ROOT_DIR=~/codesop VERSION_FILE=~/codesop/VERSION check_mempalace_status) || echo "MCP 检查跳过: 模块不可用"
```

§4.2 Skill 生态新增 MCP 服务状态行：

```md
- MCP 服务：（粘贴 check_mempalace_status 输出）
  - ✓ → "✓ MemPalace 已安装并配置"
  - ⚠️ → 显示原文（含安装/配置命令）
  - ? → "MemPalace: 已安装，配置状态未知"
  - 模块不可用 → "MCP 服务：模块不可用"
```

### 3.4 不改动的东西

- `setup` 脚本：不新增 MCP 配置自动化
- `templates/system/AGENTS.md`：不加 MemPalace 唤醒指令
- `lib/init-interview.sh`：不加 MemPalace 初始化
- `config/codesop-router.md`：不新增 MemPalace 路由条目
- 路由表：MemPalace 不是 workflow skill，不需要路由

## 4. 文件改动清单

| 文件 | 改动 |
|------|------|
| `lib/updates.sh` | 新增 `check_mempalace_status()` + 集成到 `print_dependency_report()` |
| `SKILL.md` | §3 step 5 新增 `check_mempalace_status` 调用 + §4.2 新增 MCP 服务状态行 |
| `tests/skill-routing-coverage.sh` | 新增测试（见 §5） |

## 5. 测试覆盖

| # | 测试内容 | 方法 |
|---|---------|------|
| 1 | CLI 未安装 | `PATH=` 隔离环境，断言含 "未安装" + "pip install" |
| 2 | CLI 已安装 + settings.json 缺失 | 临时 HOME，断言含 "配置状态未知" |
| 3 | CLI 已安装 + jq 缺失 | 临时 HOME + 删 jq，断言含 "配置状态未知" |
| 4 | CLI 已安装 + MCP 已配置 | mock settings.json 含 mempalace 条目，断言含 "已安装并配置" |
| 5 | CLI 已安装 + MCP 未配置 | mock settings.json 不含 mempalace，断言含 "MCP 未配置" + "claude mcp add" |
| 6 | print_dependency_report 顺序 | 完整运行，断言 "MCP 服务" 出现在 "文档一致性" 之后、"更新建议" 之前 |

## 6. 不做什么

- 不做版本读取/对比（上游无 `--version`，`pip show` 版本号不可信）
- 不自动安装 pip 包
- 不自动配置 MCP server
- 不自动配置 hooks
- 不修改 AGENTS.md 模板
- 不包装 MemPalace CLI 命令
- 不把 MemPalace 加入路由表
- 不做 OPTIONAL_MCPS 泛化抽象（Phase 1 只有 mempalace 一个）

## 7. 失败处理原则

- 只做只读解析，不修改任何用户文件
- 解析失败统一归类为 `unknown`（?），不误报为"未配置"
- stderr 不外泄（所有命令加 `2>/dev/null`）
- 函数始终 `return 0`（MCP 状态是信息性的，不阻塞流程）

## 8. 验证

```bash
bash tests/skill-routing-coverage.sh   # 新增 6 个测试
bash ~/codesop/codesop update          # 确认 MCP 服务出现在依赖报告的正确位置
/codesop                               # 确认 Skill 生态显示 MCP 状态
```
