#!/bin/bash
# templates.sh - Template generation functions for codesop
#
# This module provides functions for generating project templates:
# - AGENTS.md wrapper template
# - PRD.md template with full product documentation structure
# - Template generation orchestration
# - Merge suggestions for existing AGENTS.md files
#
# Dependencies:
# - lib/output.sh (for render_tech_stack, infer_*_cmd functions)
#
# Usage: source this file from another bash script
#   source /path/to/lib/templates.sh

contains_text() {
  local file_path="$1"
  local needle="$2"

  if [ ! -f "$file_path" ]; then
    return 1
  fi

  grep -Fq "$needle" "$file_path"
}

write_agents_template() {
  local target_dir="$1"
  local agents_file="$target_dir/AGENTS.md"

  cat >"$agents_file" <<'EOF'
@CLAUDE.md
EOF
}

write_prd_template() {
  local target_dir="$1"
  local project_name="$2"
  local date_today="$3"
  local tech_stack="$4"
  local prd_file="$target_dir/PRD.md"

  cat >"$prd_file" <<EOF
# Product: $project_name
# Current Version: 1.0.0
# Last Updated: $date_today
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
> 给人和 AI 在 30 秒内看懂"我们在做什么、做到哪了、下一步是什么"。

- **当前阶段**: discovery | planning | implementation | testing | review | release | maintenance
- **当前目标**: [一句话说明这阶段正在推进什么]
- **长期目标**: [一句话说明项目最终要解决什么问题]
- **当前里程碑**: [例如 v0.3 MVP / 支付闭环 / codesop v2]
- **完成度**: [例如 60%]
- **下一步**: [最明确的一步动作]
- **负责人/执行主体**: Human | AI | Mixed
- **最后更新原因**: [为什么这次更新 PRD]

## 2. 当前进度
> 只保留当前仍然相关的事项，已完成的重要事项移入工作日志。

### 2.1 In Progress
- [ ] [正在做的事 1]
- [ ] [正在做的事 2]

### 2.2 Next Up
- [ ] [接下来最该做的事 1]
- [ ] [接下来最该做的事 2]

### 2.3 Blocked
- [ ] [阻塞项]
  - 原因: [为什么卡住]
  - 解除条件: [满足什么即可继续]

### 2.4 Done Recently
- [x] [最近完成的重要事项 1]
- [x] [最近完成的重要事项 2]

## 3. 最近决策记录
> 只保留最近 5-10 条仍然影响当前工作的决策。更早的可归档到版本历史。

| Date | Decision | Why | Impact |
|------|----------|-----|--------|
| $date_today | [决定了什么] | [为什么这样定] | [影响哪些模块/流程] |

## 4. 版本历史 (Version History)
> 规则：新版本永远追加在最上方；记录"为什么改"和"改了什么"。

### **V1.0.0 - $date_today - (Initial Release)**
- **目标**: 发布 MVP，验证核心价值。
- **变更摘要**:
  - 项目初始化，创建 \`PRD.md\` v1.0.0。

## 5. 产品核心规范 (Current Specification)
> 此区域始终反映产品"当前真实状态"，每次迭代直接更新。

### 5.1 核心目标 (Mission)
- [一句话描述产品愿景与目标价值]

### 5.2 用户画像 (Persona)
- **目标用户**: [描述用户角色]
- **核心痛点**:
  - [痛点 1]
  - [痛点 2]

### 5.3 范围定义 (Scope)
#### In Scope
- [当前版本明确要做的内容]
- [当前版本明确要做的内容]

#### Out of Scope
- [当前明确不做的内容]
- [当前明确不做的内容]

### 5.4 核心功能 (Core Features)
- [功能点 1]
- [功能点 2]
- [功能点 3]

### 5.5 版本规划 (Roadmap)
- **Now**: [当前版本目标]
- **Next**: [下一阶段目标]
- **Later**: [后续方向]

### 5.6 领域实体 (Entities)
> 描述业务数据模型，不绑定具体框架实现。

- \`User\`: { id, email, name, createdAt }
- \`Order\`: { id, userId, status, totalPrice, items[] }
- \`[YourEntity]\`: { id, [字段...] }

### 5.7 业务用例 (Use Cases)
> 描述业务规则与流程，不写技术实现细节。

- **UC1**: [当...时，系统应...]
- **UC2**: [只有...才能...]
- **UC3**: [如果...则...]

### 5.8 ASCII UI 原型图 (ASCII Prototypes)（可选）
\`\`\`text
+------------------------------------------+
| $project_name |
|                                          |
| [核心界面元素示意]                        |
|                                          |
+------------------------------------------+
\`\`\`

### 5.9 架构设计蓝图 (Architecture Blueprint - ASCII)

- 技术栈: $tech_stack
- 系统交互:

\`\`\`text
+-----------------+          +-----------------+          +-----------------+
|   Frontend      | -------> |    Backend      | -------> |    Database     |
|   (用户界面)    | <------- |   (API服务)     | <------- |    (数据存储)   |
+-----------------+          +-----------------+          +-----------------+

USER                    APPLICATION                 DOMAIN                    DATA
  |                           |                        |                        |
  | 1. [用户操作]         --> |                        |                        |
  |                           | 2. 调用 UseCase      ->|                        |
  |                           |                        | 3. 业务规则 + 持久化 ->|
  |                           |                        |<-----------------------|
  |                           |<------- 4. 返回结果 ----|                        |
  |<------ 5. UI 更新 --------|                        |                        |
\`\`\`

- 建议目录结构（Pragmatic Clean）

\`\`\`text
/src
├── /domain          # 业务核心：实体、规则、仓储接口
├── /usecases        # 用例编排：业务流程组织
├── /infra           # 基础设施：数据库、外部服务实现
└── /presentation    # 表现层：页面、组件、状态管理
\`\`\`

### 5.10 技术实现规范 (Implementation Standards)

> 仅保留"项目技术决策与质量标准"，不放 AI 代理行为规则。

#### Domain 规范

- D1. 业务规则内聚：核心业务规则在 Domain 定义并可独立测试
- D2. 接口驱动：数据访问通过抽象接口约束
- D3. 模型一致性：领域实体字段与术语在全系统保持一致

#### Data / Infra 规范

- S1. 数据一致性：时间、时区、金额精度等规则统一
- S2. 外部依赖隔离：第三方 API 通过适配层接入，避免污染领域模型
- S3. 兼容性策略：数据库迁移、版本变更需可回滚

#### Presentation 规范

- P1. 状态管理策略：定义状态边界（页面级/全局）
- P2. 交互一致性：统一错误提示、加载态、空态策略

#### 验收标准 (Definition of Done)

- [ ] 需求范围内功能全部实现
- [ ] 核心业务用例可验证（测试/验收用例通过）
- [ ] 文档同步更新（本 PRD、接口文档、发布说明）
- [ ] 无阻塞上线的已知缺陷（或明确风险与补救计划）

## 6. 当前风险与假设
### 6.1 Risks
- [风险 1]
- [风险 2]

### 6.2 Assumptions
- [假设 1]
- [假设 2]

## 7. 工作日志
> 这是流动区。每次关键动作后追加一条，按时间倒序。简短、事实化。

### $date_today 10:00 - [标题]
- **背景**: [为什么做这一步]
- **动作**: [做了什么]
- **结果**: [产出/变更]
- **影响**: [影响了什么]
- **后续**: [下一步是什么]

## 8. 可选扩展 (Optional Extensions)

### 8.1 依赖注入规范 (DI)（可选）

- 依赖关系统一在组合根（Composition Root）装配
- 模块间通过接口协作，降低耦合

### 8.2 防腐层规范 (Anti-Corruption Layer)（可选）

- 外部 DTO 与内部 Entity 分离
- 通过 mapper/adapter 做模型转换
- 第三方 API 变更优先收敛在 Data/Infra 层
EOF
}

generate_templates() {
  local target_dir="$1"
  local project_name="$2"
  local tech_stack="$3"
  local test_cmd="$4"
  local lint_cmd="$5"
  local type_cmd="$6"
  local smoke_cmd="$7"
  local date_today
  local agents_status=""
  local claude_status=""
  local prd_status=""
  local prd_file="$target_dir/PRD.md"

  # SECURITY FIX: Sanitize project_name to prevent template injection
  # Only allow alphanumeric characters, underscores, and hyphens
  project_name="$(basename "$target_dir" | sed 's/[^a-zA-Z0-9_-]//g')"

  date_today="$(date +%F)"

  if [ -f "$target_dir/AGENTS.md" ]; then
    if grep -Fxq "@CLAUDE.md" "$target_dir/AGENTS.md" || grep -Fxq "@./CLAUDE.md" "$target_dir/AGENTS.md"; then
      agents_status="已保留（已是 @CLAUDE.md 引用包装）"
    else
      agents_status="已保留（非引用包装，建议收敛为 @CLAUDE.md）"
    fi
  else
    write_agents_template "$target_dir" "$project_name" "$tech_stack" "$test_cmd" "$lint_cmd" "$type_cmd" "$smoke_cmd"
    agents_status="已生成（@CLAUDE.md 引用包装）"
  fi

  claude_status="由 Claude Code 的 /init 生成，codesop 不覆盖"

  if [ -f "$prd_file" ]; then
    if grep -Fq "## 0. 使用说明" "$prd_file" && grep -Fq "## 1. 当前快照" "$prd_file"; then
      prd_status="已保留（已是活文档格式）"
    else
      cp "$prd_file" "$prd_file.codesop.legacy.bak"
      write_prd_template "$target_dir" "$project_name" "$date_today" "$tech_stack"
      prd_status="已迁移为活文档格式（备份: PRD.md.codesop.legacy.bak）"
    fi
  else
    write_prd_template "$target_dir" "$project_name" "$date_today" "$tech_stack"
    prd_status="已生成（活文档格式）"
  fi

  printf '
%s
' "已生成文件："
  printf '%s
' "- AGENTS.md：$agents_status"
  printf '%s
' "- CLAUDE.md：$claude_status"
  printf '%s
' "- PRD.md：$prd_status"

  # 检测系统级别的配置文件
  printf '
%s
' "系统级别配置："

  # 检测 ~/.claude/CLAUDE.md
  local system_claude_status=""
  if [ -L "$HOME/.claude/CLAUDE.md" ]; then
    local claude_target=$(readlink "$HOME/.claude/CLAUDE.md")
    if [ "$claude_target" = "$target_dir/CLAUDE.md" ]; then
      system_claude_status="符号链接 → 当前项目（应改为独立文件）"
    else
      system_claude_status="符号链接 → $claude_target"
    fi
  elif [ -f "$HOME/.claude/CLAUDE.md" ]; then
    # 检查是否包含 AI 编码契约
    if grep -q "AI 编码契约" "$HOME/.claude/CLAUDE.md" 2>/dev/null; then
      system_claude_status="已存在（独立文件，包含 AI 编码契约）"
    else
      system_claude_status="已存在（独立文件，但未包含 AI 编码契约）"
    fi
  else
    system_claude_status="不存在（建议创建，包含 AI 编码契约）"
  fi
  printf '%s
' "- ~/.claude/CLAUDE.md：$system_claude_status"

  # 检测 ~/.claude/AGENTS.md
  local system_agents_status=""
  if [ -L "$HOME/.claude/AGENTS.md" ]; then
    local agents_target=$(readlink "$HOME/.claude/AGENTS.md")
    system_agents_status="符号链接 → $agents_target"
  elif [ -f "$HOME/.claude/AGENTS.md" ]; then
    system_agents_status="已存在（独立文件）"
  else
    system_agents_status="不存在"
  fi
  printf '%s
' "- ~/.claude/AGENTS.md：$system_agents_status"

  # 检测 ~/.config/opencode/CLAUDE.md（OpenCode）
  if [ -f "$HOME/.config/opencode/CLAUDE.md" ]; then
    printf '%s
' "- ~/.config/opencode/CLAUDE.md：已存在"
  fi
}

print_agents_merge_suggestions() {
  local target_dir="$1"
  local agents_file="$target_dir/AGENTS.md"

  if [ ! -f "$agents_file" ]; then
    return
  fi

  printf '\n%s\n' "AGENTS.md 合并优化建议："
  printf '%s\n' "--- current/AGENTS.md"
  printf '%s\n' "+++ suggested/AGENTS.md"

  if grep -Fxq "@CLAUDE.md" "$agents_file" || grep -Fxq "@./CLAUDE.md" "$agents_file"; then
    printf '%s\n' "  (当前 AGENTS.md 已覆盖 codesop 关注的核心骨架，无额外建议)"
  else
    printf '%s\n' "- 建议把项目级 AGENTS.md 收敛成轻量包装，正文只保留在 CLAUDE.md"
    printf '%s\n' "+@CLAUDE.md"
  fi
}
