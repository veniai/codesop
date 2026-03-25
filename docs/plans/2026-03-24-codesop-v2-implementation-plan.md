# codesop v2 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 实现 codesop v2 的 CLI 诊断层，让 `/codesop` 命令能输出结构化的项目诊断上下文，为上层 `codesop` skill 的“工作台摘要 + skill 路由”提供稳定输入。

**Architecture:** 采用渐进式扩展策略，在现有 codesop CLI 基础上添加三个独立模块：信号采集器、诊断引擎、推荐上下文生成器。CLI 只负责可验证的信号采集、阶段判断和推荐上下文输出；真正的“工作台摘要”和 skill 路由由上层 `codesop` skill 完成。复用现有的项目检测逻辑与 skill 映射，但不让 CLI 成为完整推理层。

**Tech Stack:** Bash (与现有代码一致), git, 文件系统操作

---

## 性能约束（实现时必须遵守）

1. **git 调用缓存**: 将 git 命令结果缓存到临时文件，避免同一次诊断中重复调用
2. **技能索引缓存**: 将技能索引缓存到 `~/.gstack/skills-index-cache.json`，只在目录变化时更新
3. **推荐数量限制**: 最多推荐 5 个技能，按置信度排序

## 信号范围说明（v2 MVP）

**v2 MVP 只支持仓库内可采集信号**：
- ✅ Git 状态：分支、未提交文件、最近提交
- ✅ 配置文件：CLAUDE.md/AGENTS.md/PRD.md 是否存在
- ✅ 工具链：package.json 等配置文件
- ✅ 代码健康：TODO/FIXME 数量

**v2 不支持的信号**（需要宿主注入或用户输入）：
- ❌ 当前用户目标（需对话上下文）
- ❌ 阻塞原因（需用户提供）
- ❌ 最近失败命令（需 shell 历史访问权限）
- ❌ 多文件跳跃检测（需 git diff 分析，可后续添加）

**理由**：这些信号需要额外的权限或上下文，超出 v2 MVP 范围。

## 与上层 `codesop` skill 的关系

这份计划只覆盖 `CLI diagnosis layer`，不覆盖完整的 `codesop` 系统。

分工如下：

- CLI 负责：采集仓库内可验证信号、输出结构化诊断结果、输出推荐上下文
- `codesop` skill 负责：读取 `AGENTS.md` / `PRD.md` / `README.md`、生成工作台摘要、推荐下游 skill、解释下一步与暂不建议事项

因此，本计划的输出应该被理解为：

- `diagnosis output`: 机器可读/可引用的项目状态判断
- `recommendation context`: 供上层 skill 消费的推荐上下文

而不是最终用户体验的完整终态。

## CLI 输出契约（对齐当前 skill 设计）

v2 CLI 的输出目标不是独立替代 `codesop` skill，而是给上层提供稳定的原始材料。

因此输出要尽量贴近上层需要的字段：

- 当前阶段
- 置信度
- 健康问题
- Git 状态
- 配置状态
- 供 skill 解释的推荐上下文

CLI 可以直接打印人类可读内容，但不应假装自己已经完成了最终的工作台摘要。

---

## Task 1: 信号采集器 (Signal Collector)

**Files:**
- Create: `scripts/collect-signals.sh`
- Modify: `codesop:~700` (添加 source 引用)
- Test: `tests/collect-signals.sh`

**Step 1: Write the failing test**

```bash
#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/collect-signals.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# 创建测试项目
cd "$tmpdir"
git init -q
echo "test" > file.txt
git add . && git commit -q -m "init"

# 获取实际的默认分支名
expected_branch=$(git branch --show-current)

# 测试信号采集
signals=$(collect_signals "$tmpdir")

assert_contains "$signals" "GIT_BRANCH=$expected_branch"
assert_contains "$signals" "GIT_UNTRACKED=0"
assert_contains "$signals" "CONFIG_CLAUDE_MD=false"
```

**Step 2: Run test to verify it fails**

Run: `bash tests/collect-signals.sh`
Expected: FAIL with "collect_signals: command not found"

**Step 3: Write minimal implementation**

```bash
#!/bin/bash
# scripts/collect-signals.sh - 信号采集器

collect_signals() {
  local project_dir="${1:-.}"
  local signals=""
  local original_dir="$(pwd)"

  # Git 信号（带完整缓存）
  local git_cache="/tmp/codesop-git-$$"
  
  if [ -f "$git_cache/signals" ]; then
    # 读取完整缓存
    signals=$(cat "$git_cache/signals")
  else
    mkdir -p "$git_cache"
    cd "$project_dir" || return 1
    
    # 分支名
    local branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    signals+="GIT_BRANCH=$branch\n"
    
    # 未跟踪文件数
    local untracked=$(git status --porcelain 2>/dev/null | grep -c "^??" || echo "0")
    signals+="GIT_UNTRACKED=$untracked\n"
    
    # 未提交文件数
    local uncommitted=$(git status --porcelain 2>/dev/null | grep -cv "^??" || echo "0")
    signals+="GIT_UNCOMMITTED=$uncommitted\n"
    
    # 最近提交时间
    local last_commit=$(git log -1 --format="%ar" 2>/dev/null || echo "none")
    signals+="GIT_LAST_COMMIT=$last_commit\n"
    
    # 缓存完整信号
    echo -e "$signals" > "$git_cache/signals"
    
    # 恢复目录
    cd "$original_dir"
  fi

  # 配置文件信号
  for config in CLAUDE.md AGENTS.md PRD.md PLAN.md README.md; do
    if [ -f "$project_dir/$config" ]; then
      signals+="CONFIG_${config%.*}_MD=true\n"
    else
      signals+="CONFIG_${config%.*}_MD=false\n"
    fi
  done

  # 工具链信号
  if [ -f "$project_dir/package.json" ]; then
    signals+="HAS_PACKAGE_JSON=true\n"
  else
    signals+="HAS_PACKAGE_JSON=false\n"
  fi

  echo -e "$signals"
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "FAIL: expected output to contain: $needle" >&2
    exit 1
  fi
}
```

**Step 4: Run test to verify it passes**

Run: `bash tests/collect-signals.sh`
Expected: PASS

**Step 5: Commit**

```bash
git add scripts/collect-signals.sh tests/collect-signals.sh
git commit -m "feat: add signal collector with git and config signals"
```

---

## Task 2: 诊断引擎 (Diagnosis Engine)

**Files:**
- Create: `scripts/diagnose.sh`
- Modify: `codesop:~700` (添加 source 引用)
- Test: `tests/diagnose.sh`

**Step 1: Write the failing test**

```bash
#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/diagnose.sh"

# 测试场景 1: feature 分支，有未提交文件
signals="GIT_BRANCH=feature/test
GIT_UNTRACKED=2
GIT_UNCOMMITTED=3
CONFIG_CLAUDE_MD=true
CONFIG_AGENTS_MD=true
CONFIG_PRD_MD=false
HAS_PACKAGE_JSON=true"

result=$(diagnose_project "$signals")

assert_contains "$result" "CURRENT_STAGE=feature"
assert_contains "$result" "STAGE_CONFIDENCE=medium"

# 测试场景 2: 有测试失败（需要 mock）
# 这里简化处理，实际需要 mock git diff
```

**Step 2: Run test to verify it fails**

Run: `bash tests/diagnose.sh`
Expected: FAIL with "diagnose_project: command not found"

**Step 3: Write minimal implementation**

```bash
#!/bin/bash
# scripts/diagnose.sh - 诊断引擎

diagnose_project() {
  local signals="$1"
  local result=""

  # 解析信号
  local branch=$(echo "$signals" | grep "^GIT_BRANCH=" | cut -d= -f2)
  local untracked=$(echo "$signals" | grep "^GIT_UNTRACKED=" | cut -d= -f2)
  local uncommitted=$(echo "$signals" | grep "^GIT_UNCOMMITTED=" | cut -d= -f2)
  local has_prd=$(echo "$signals" | grep "^CONFIG_PRD_MD=" | cut -d= -f2)
  local has_plan=$(echo "$signals" | grep "^CONFIG_PLAN_MD=" | cut -d= -f2)

  # 阶段判断
  local stage="unknown"
  local confidence="low"

  if [[ "$branch" == feature/* ]]; then
    stage="feature"
    confidence="medium"
  elif [[ "$branch" == fix/* ]] || [[ "$branch" == bugfix/* ]]; then
    stage="debug"
    confidence="medium"
  elif [[ "$branch" == refactor/* ]]; then
    stage="refactor"
    confidence="medium"
  elif [[ "$branch" == main ]] || [[ "$branch" == master ]]; then
    if [ "$uncommitted" -gt 0 ]; then
      stage="feature"
      confidence="low"
    else
      stage="unknown"
      confidence="low"
    fi
  fi

  # 健康度评估
  local health_issues=""
  
  if [ "$has_prd" = "false" ]; then
    health_issues+="MISSING_PRD,"
  fi
  
  if [ "$has_plan" = "false" ] && [ "$stage" = "feature" ]; then
    health_issues+="MISSING_PLAN,"
  fi

  # 输出结果
  result+="CURRENT_STAGE=$stage\n"
  result+="STAGE_CONFIDENCE=$confidence\n"
  
  if [ -n "$health_issues" ]; then
    result+="HEALTH_ISSUES=${health_issues%,}\n"
  fi

  echo -e "$result"
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "FAIL: expected output to contain: $needle" >&2
    exit 1
  fi
}
```

**Step 4: Run test to verify it passes**

Run: `bash tests/diagnose.sh`
Expected: PASS

**Step 5: Commit**

```bash
git add scripts/diagnose.sh tests/diagnose.sh
git commit -m "feat: add diagnosis engine with stage detection"
```

---

## Task 3: 推荐上下文生成器 (Recommendation Context Generator)

**设计原则**：遵循 using-superpowers 的理念，不预先分类技能，让上层 skill 在运行时根据 description 语义判断技能类型。

**核心思路**：`recommend_skills` 函数不直接承担最终推荐职责，而是输出规范化的推荐上下文。当前环境中的 `codesop` skill **可能**会继续消费这些上下文并给用户回复。

**⚠️ 重要说明**：
- CLI 层：负责输出规范化推荐上下文（这是确定的）
- skill 层：由上层 `codesop` skill 消费该上下文并完成工作台摘要与技能推荐（这是期望行为，不是 CLI 保证）
- 在支持 agent 接管的环境中可获得最佳效果
- 在不支持的环境中，用户看到的是推荐上下文，需要手动选择

**Files:**
- Create: `scripts/recommend.sh`
- Modify: `codesop:~700` (添加 source 引用)
- Test: `tests/recommend.sh`

**Step 1: Write the failing test**

```bash
#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/recommend.sh"

# 测试场景 1: feature 阶段，缺少 PRD
diagnosis="CURRENT_STAGE=feature
STAGE_CONFIDENCE=medium
HEALTH_ISSUES=MISSING_PRD"

result=$(recommend_skills "$diagnosis")

# 验证输出包含必要的信息（CLI 层验证）
assert_contains "$result" "可用技能"
assert_contains "$result" "推荐规则"

# 验证输出包含诊断上下文
assert_contains "$result" "当前阶段: feature"
assert_contains "$result" "健康问题: MISSING_PRD"

# 验证输出包含技能列表（至少有一个技能）
skill_count=$(echo "$result" | grep -c "^\w.*: " || true)
if [ "$skill_count" -lt 1 ]; then
  echo "FAIL: no skills found in output" >&2
  exit 1
fi

# 验证推荐规则中明确提到数量限制
assert_contains "$result" "3-5"
```

**Step 2: Run test to verify it fails**

Run: `bash tests/recommend.sh`
Expected: FAIL with "recommend_skills: command not found"

**Step 3: Write minimal implementation**

```bash
#!/bin/bash
# scripts/recommend.sh - 推荐上下文生成器（自然语义版）

# 发现所有可用技能（带缓存）
discover_skills() {
  local cache_file="$HOME/.gstack/skills-index-cache.json"
  local skills_dir="$HOME/.claude/skills/gstack"
  
  # 检查缓存是否有效（目录未变化）
  if [ -f "$cache_file" ]; then
    local cache_time=$(stat -c %Y "$cache_file" 2>/dev/null || echo "0")
    local dir_time=$(stat -c %Y "$skills_dir" 2>/dev/null || echo "0")
    
    if [ "$cache_time" -ge "$dir_time" ]; then
      # 缓存有效，直接返回
      cat "$cache_file"
      return
    fi
  fi
  
  # 缓存无效，重新扫描
  local skills_info=""
  
  for skill_dir in "$skills_dir"/*/; do
    local skill_name=$(basename "$skill_dir")
    local skill_file="$skill_dir/SKILL.md"
    
    # 跳过非技能目录
    if [ ! -f "$skill_file" ]; then
      continue
    fi
    
    # 提取 description
    local description=$(sed -n '/^---$/,/^---$/p' "$skill_file" | grep "^description:" | cut -d: -f2- | sed 's/^[[:space:]]*//' | sed 's/^"//' | sed 's/"$//')
    
    if [ -n "$description" ]; then
      skills_info+="$skill_name: $description\n"
    fi
  done
  
  # 写入缓存
  echo -e "$skills_info" > "$cache_file"
  echo -e "$skills_info"
}

# 主推荐函数（输出上下文，让上层 skill 处理）
recommend_skills() {
  local diagnosis="$1"
  
  # 1. 发现所有可用技能
  local skills_info=$(discover_skills)
  
  # 2. 解析诊断结果
  local stage=$(echo "$diagnosis" | grep "^CURRENT_STAGE=" | cut -d= -f2)
  local confidence=$(echo "$diagnosis" | grep "^STAGE_CONFIDENCE=" | cut -d= -f2)
  local health_issues=$(echo "$diagnosis" | grep "^HEALTH_ISSUES=" | cut -d= -f2)
  
  # 3. 构造上下文信息
  local context="当前阶段: $stage\n置信度: $confidence"
  if [ -n "$health_issues" ]; then
    context+="\n健康问题: $health_issues"
  fi
  
  # 4. 输出推荐上下文（让上层 skill 处理）
  echo "## 技能推荐"
  echo ""
  echo "根据项目诊断结果，推荐以下技能（**最多 5 个**）："
  echo ""
  echo "**诊断结果**："
  echo -e "$context"
  echo ""
  echo "**可用技能**："
  echo -e "$skills_info"
  echo ""
  echo "**推荐规则**："
  echo "1. 流程技能（决定怎么去）优先于实现技能（指导怎么做）"
  echo "2. **推荐 3-5 个最相关的技能**"
  echo "3. 每个推荐需要说明原因和置信度"
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "FAIL: expected output to contain: $needle" >&2
    exit 1
  fi
}
```

**Step 4: Run test to verify it passes**

Run: `bash tests/recommend.sh`
Expected: PASS

**Step 5: Commit**

```bash
git add scripts/recommend.sh tests/recommend.sh
git commit -m "feat: add recommendation context generator"
```

---

## Task 4: 重构 `/codesop` 主命令为诊断功能

**设计依据**：设计稿已收敛为"/codesop 是标准诊断，diagnose 删除"

**Files:**
- Modify: `codesop` (重构主命令，默认执行诊断)
- Test: `tests/codesop-diagnose.sh`

**Step 1: Write the failing test**

```bash
#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$ROOT_DIR/codesop"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# 创建测试项目
cd "$tmpdir"
git init -q
echo '{"name":"test"}' > package.json
git add . && git commit -q -m "init"

# 测试 /codesop 主命令（不带参数，默认执行诊断）
output=$(bash "$CLI" 2>&1)

assert_contains "$output" "## 项目诊断"
assert_contains "$output" "当前阶段"
assert_contains "$output" "可用技能"
```

**Step 2: Run test to verify it fails**

Run: `bash tests/codesop-diagnose.sh`
Expected: FAIL (现有 codesop 主命令不输出诊断信息)

**Step 3: Write minimal implementation**

重构 `codesop` 文件，主命令默认执行诊断：

```bash
# 在 codesop 的 case 语句中，将主命令逻辑改为诊断
# 处理无参数或未知命令的情况
*)
  # 默认执行诊断
  target_dir="${1:-.}"
  
  # source 依赖
  source "$ROOT_DIR/scripts/collect-signals.sh"
  source "$ROOT_DIR/scripts/diagnose.sh"
  source "$ROOT_DIR/scripts/recommend.sh"
  
  # 收集信号
  signals=$(collect_signals "$target_dir")
  
  # 诊断
  diagnosis=$(diagnose_project "$signals")
  
  # 格式化输出
  echo "## 项目诊断"
  echo ""
  
  stage=$(echo "$diagnosis" | grep "^CURRENT_STAGE=" | cut -d= -f2)
  confidence=$(echo "$diagnosis" | grep "^STAGE_CONFIDENCE=" | cut -d= -f2)
  echo "**当前阶段**: $stage"
  echo "**置信度**: $confidence"
  echo ""
  
  echo "**健康状态**:"
  branch=$(echo "$signals" | grep "^GIT_BRANCH=" | cut -d= -f2)
  uncommitted=$(echo "$signals" | grep "^GIT_UNCOMMITTED=" | cut -d= -f2)
  echo "- Git: $branch 分支，$uncommitted 个未提交文件"
  echo ""
  
  # 输出推荐上下文（上层 codesop skill 可能会处理并回复）
  recommend_skills "$diagnosis"
  
  # 清理缓存
  rm -rf /tmp/codesop-git-$$
  ;;
```

**Step 4: Run test to verify it passes**

Run: `bash tests/codesop-diagnose.sh`
Expected: PASS

**Step 5: Commit**

```bash
git add codesop tests/codesop-diagnose.sh
git commit -m "feat: refactor /codesop to default diagnosis mode"
```

---

## Task 5: 重构 `/codesop status` 为纯事实报告

**设计依据**：设计稿定义"/codesop status = 只报事实，不做判断"

**Files:**
- Modify: `codesop` (重构 status 命令)
- Test: `tests/codesop-status.sh`

**Step 1: Write the failing test**

```bash
#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$ROOT_DIR/codesop"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

cd "$tmpdir"
git init -q
echo '{"name":"test"}' > package.json
git add . && git commit -q -m "init"

# 测试 status 命令
output=$(bash "$CLI" status 2>&1)

assert_contains "$output" "## 项目状态（纯事实）"
assert_contains "$output" "版本信息"
assert_contains "$output" "Git 状态"

# 边界检查：不应该包含"建议"、"推荐"、"应该"
if [[ "$output" == *"建议"* ]] || [[ "$output" == *"推荐"* ]] || [[ "$output" == *"应该"* ]]; then
  echo "FAIL: status output contains recommendation words" >&2
  exit 1
fi
```

**Step 2: Run test to verify it fails**

Run: `bash tests/codesop-status.sh`
Expected: FAIL (现有 status 命令可能不符合新格式)

**Step 3: Write minimal implementation**

重构 `codesop` 中的 `status)` case：

```bash
status)
  shift
  target_dir="${1:-.}"
  
  echo "## 项目状态（纯事实）"
  echo ""
  
  echo "**版本信息**:"
  echo "- codesop: $(current_version)"
  
  # 检查 gstack 版本
  if command -v gstack &>/dev/null; then
    gstack_version=$(gstack version 2>/dev/null | head -1 || echo "unknown")
    echo "- gstack: $gstack_version"
  fi
  echo ""
  
  echo "**Git 状态**:"
  cd "$target_dir" || return 1
  branch=$(git branch --show-current 2>/dev/null || echo "unknown")
  untracked=$(git status --porcelain 2>/dev/null | grep -c "^??" || echo "0")
  uncommitted=$(git status --porcelain 2>/dev/null | grep -cv "^??" || echo "0")
  last_commit=$(git log -1 --format="%ar" 2>/dev/null || echo "none")
  
  echo "- 分支: $branch"
  echo "- 未跟踪: $untracked 文件"
  echo "- 未提交: $uncommitted 文件"
  echo "- 最近提交: $last_commit"
  echo ""
  
  echo "**配置文件**:"
  for config in CLAUDE.md AGENTS.md PRD.md PLAN.md; do
    if [ -f "$config" ]; then
      echo "- $config: ✓ 存在"
    else
      echo "- $config: ✗ 不存在"
    fi
  done
  echo ""
  
  echo "**代码统计**:"
  file_count=$(find . -type f -not -path './.git/*' 2>/dev/null | wc -l | tr -d ' ')
  todo_count=$(grep -r "TODO" --include="*.md" --include="*.sh" --include="*.js" --include="*.ts" . 2>/dev/null | wc -l | tr -d ' ' || echo "0")
  fixme_count=$(grep -r "FIXME" --include="*.md" --include="*.sh" --include="*.js" --include="*.ts" . 2>/dev/null | wc -l | tr -d ' ' || echo "0")
  
  echo "- 文件数: $file_count"
  echo "- TODO: $todo_count"
  echo "- FIXME: $fixme_count"
  ;;
```

**Step 4: Run test to verify it passes**

Run: `bash tests/codesop-status.sh`
Expected: PASS

**Step 5: Commit**

```bash
git add codesop tests/codesop-status.sh
git commit -m "refactor: redesign /codesop status as pure facts report"
```

---

## Task 6: E2E 测试

**Files:**
- Create: `tests/codesop-e2e.sh`

**Step 1: Write the failing test**

```bash
#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$ROOT_DIR/codesop"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# 场景 1: feature 分支，缺少 PRD
cd "$tmpdir"
mkdir project1 && cd project1
git init -q
git checkout -q -b feature/new-feature
echo '{"name":"test"}' > package.json
git add . && git commit -q -m "init"

output=$(bash "$CLI" 2>&1)

assert_contains "$output" "## 项目诊断"
assert_contains "$output" "当前阶段"
assert_contains "$output" "可用技能"

# 场景 2: main 分支，配置齐全
cd "$tmpdir"
mkdir project2 && cd project2
git init -q
echo '# AGENTS' > AGENTS.md
echo '# PRD' > PRD.md
git add . && git commit -q -m "init"

output=$(bash "$CLI" 2>&1)

# 验证输出包含诊断信息（不硬编码具体文案）
assert_contains "$output" "## 项目诊断"
assert_contains "$output" "当前阶段"
assert_contains "$output" "健康状态"

echo "All E2E tests passed!"
```

**Step 2: Run test to verify it fails**

Run: `bash tests/codesop-e2e.sh`
Expected: Depends on previous tasks

**Step 3: Implementation**

这个测试依赖于前面所有任务的完成。当 Task 1-5 完成后，这个测试应该自动通过。

**Step 4: Run test to verify it passes**

Run: `bash tests/codesop-e2e.sh`
Expected: PASS

**Step 5: Commit**

```bash
git add tests/codesop-e2e.sh
git commit -m "test: add E2E tests for diagnose and status commands"
```

---

## Implementation Order (with performance optimization)

1. **Task 1**: 信号采集器（带缓存）← 先实现性能约束
2. **Task 2**: 诊断引擎
3. **Task 3**: 推荐引擎（带数量限制）← 先实现性能约束
4. **Task 4**: 集成 `/codesop` 主命令
5. **Task 5**: 重构 `/codesop status`
6. **Task 6**: E2E 测试

---

## Success Criteria

- [ ] `/codesop` 输出结构化的诊断报告
- [ ] `/codesop` 输出供上层 skill 消费的推荐上下文（最多 5 个候选）
- [ ] `/codesop status` 只输出事实，不含建议
- [ ] 信号采集器有缓存机制
- [ ] 推荐上下文生成器有数量限制
- [ ] 所有测试通过

---

## Plan Status Footer

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/autoplan` | Scope & strategy | 3 | CLEAN | 5 decisions, 0 taste |
| Eng Review | `/autoplan` | Architecture & tests | 5 | CLEAN | 11 issues fixed |
| Design Review | `/autoplan` | UI/UX gaps | 0 | — | — |
| Codex Review | `/codex review` | Independent 2nd opinion | 2 | ISSUES_FOUND | 11 issues, all fixed |

**VERDICT:** APPROVED — Implementation plan verified after addressing all review feedback. Ready to execute.

### Issues Fixed (from Codex reviews)
1. ✅ 命令边界回退：`diagnose` 改回主命令 `/codesop`
2. ✅ AI 自动接管：明确说明是期望行为，不是保证
3. ✅ 测试验证：从"打印 prompt"改为验证"推荐上下文完整"
4. ✅ 性能约束：git 缓存完整、技能索引缓存实现、推荐数量限制
5. ✅ Bash 健壮性：不硬编码 main、缓存完整、目录恢复
6. ✅ 信号范围：明确 v2 MVP 只支持仓库内可采集信号
7. ✅ E2E 测试：与输出契约一致
8. ✅ 任务结构：恢复 Task 5、Task 6 正文
9. ✅ Task 4 标题和内容一致：明确是主命令实现
10. ✅ 推荐数量限制：落实到实现和测试
11. ✅ 文档格式：修正代码块格式
