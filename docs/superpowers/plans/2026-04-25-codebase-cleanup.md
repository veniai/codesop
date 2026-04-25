# 代码库全面清理 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 清理死代码、消重复、修过时内容、统一测试框架、补全 Pipeline 分支衔接

**Architecture:** 纯删除/清理为主，唯一的"新增"是 Pipeline 衔接任务（创建分支）和测试辅助函数提取。所有改动不改变用户可见行为。

**Tech Stack:** Bash, jq, git

**Spec:** `docs/superpowers/specs/2026-04-25-codebase-cleanup-design.md`

---

### Task 1: 删除 lib/templates.sh

**Files:**
- Delete: `lib/templates.sh`
- Modify: `codesop` (移除 source 行)
- Modify: `tests/codesop-init-interview.sh` (移除 source 行)

- [ ] **Step 1: 确认 templates.sh 无活调用者**

Run: `grep -rn 'templates\.sh' ~/codesop/ --include='*.sh' | grep -v 'templates.sh:' | grep -v test | grep -v '#'`
Expected: 只显示 codesop 入口的 source 行和测试的 source 行，无其他调用

Run: `grep -rn 'generate_templates\|write_agents_template\|write_prd_template\|contains_text\|print_agents_merge' ~/codesop/lib/ --include='*.sh'`
Expected: 只在 templates.sh 内部出现

- [ ] **Step 2: 删除文件，移除 source 行**

```bash
rm lib/templates.sh
```

修改 `codesop` 入口：删除 `source "$ROOT_DIR/lib/templates.sh"` 行。

修改 `tests/codesop-init-interview.sh`：删除 `source` templates.sh 的行。

- [ ] **Step 3: 跑测试验证**

Run: `bash tests/run_all.sh`
Expected: 9/9 PASS

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "chore: delete dead module lib/templates.sh"
```

---

### Task 2: 删除 lib/output.sh，迁移 find_superpowers_plugin_path 到 detection.sh

**Files:**
- Delete: `lib/output.sh`
- Modify: `lib/detection.sh` (迁入函数)
- Modify: `codesop` (移除 source 行)
- Modify: `tests/skill-routing-coverage.sh` (改 source 目标)
- Modify: `setup` (标注 canonical 来源)

- [ ] **Step 1: 确认 output.sh 只有 find_superpowers_plugin_path 是活的**

Run: `grep -rn 'find_superpowers_plugin_path\|render_tech_stack\|infer_.*_cmd\|pick_host\|format_tool_state\|format_ecosystem_state\|find_first_existing_path' ~/codesop/ --include='*.sh' | grep -v 'output.sh:' | grep -v 'setup:' | grep -v test`
Expected: 只有 `updates.sh` 调用 `find_superpowers_plugin_path`，其余函数无外部调用

- [ ] **Step 2: 将 find_superpowers_plugin_path 迁入 detection.sh**

从 `lib/output.sh` 复制 `find_superpowers_plugin_path()` 函数（含注释），追加到 `lib/detection.sh` 末尾。

- [ ] **Step 3: 删除 output.sh，修改 source 行**

```bash
rm lib/output.sh
```

修改 `codesop` 入口：删除 `source "$ROOT_DIR/lib/output.sh"` 行。

修改 `tests/skill-routing-coverage.sh`：`source` output.sh 改为 `source` detection.sh。

修改 `setup` 中 `find_superpowers_plugin_path()` 上方注释：
```bash
# Canonical: lib/detection.sh — setup 保留独立副本（自包含脚本）
```

- [ ] **Step 4: 跑测试**

Run: `bash tests/run_all.sh`
Expected: 9/9 PASS

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "chore: delete dead module lib/output.sh, migrate find_superpowers_plugin_path to detection.sh"
```

---

### Task 3: 删除 detection.sh 和 updates.sh 死函数

**Files:**
- Modify: `lib/detection.sh`
- Modify: `lib/updates.sh`

- [ ] **Step 1: 删除 detection.sh 死代码**

删除以下函数和数据：
- `AI_TOOLS` 数组
- `ECOSYSTEM_REGISTRY` 数组
- `detect_tool_by_registry()`
- `detect_ecosystem_by_registry()`
- `detect_all_tools()`
- `detect_all_ecosystems()`
- `detect_environment()`
- `has_plugin()`
- `detect_project_shape_and_framework()` 的 `$2`/`$3` 文档注释

- [ ] **Step 2: 删除 updates.sh 死代码**

删除：
- `CORE_PLUGINS` 数组
- `OPTIONAL_PLUGINS` 数组
- `check_plugin_versions()` 函数

将 `check_document_consistency()` 调用者改为直接调 `check_codesop_document_consistency()`，然后删除 `check_document_consistency()`。

更新 updates.sh 文件头注释，删除对 `output.sh` 函数的依赖声明。

- [ ] **Step 3: 跑测试**

Run: `bash tests/run_all.sh`
Expected: 9/9 PASS

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "chore: remove dead functions from detection.sh and updates.sh"
```

---

### Task 4: 删除 init-interview.sh 死代码

**Files:**
- Modify: `lib/init-interview.sh`

- [ ] **Step 1: 验证 has_superpowers 和 _SP_CANDIDATES 无外部引用**

Run: `grep -rn 'has_superpowers\|_SP_CANDIDATES' ~/codesop/ --include='*.sh' | grep -v 'init-interview.sh:'`
Expected: 无结果

- [ ] **Step 2: 删除**

删除 `_SP_CANDIDATES` 数组和 `has_superpowers()` 函数。

- [ ] **Step 3: 跑测试**

Run: `bash tests/run_all.sh`
Expected: 9/9 PASS

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "chore: remove dead has_superpowers from init-interview.sh"
```

---

### Task 5: 过时文档和内容修复

**Files:**
- Delete: `docs/superpowers/plans/2026-04-20-subagent-execution-architecture.md`
- Delete: `docs/superpowers/specs/2026-04-20-subagent-execution-architecture-design.md`
- Modify: `config/codesop-router.md`
- Modify: `PRD.md`
- Modify: `templates/system/AGENTS.md`
- Modify: `CLAUDE.md`
- Modify: `README.md`
- Modify: `README.en.md`
- Modify: `patches/superpowers/finishing-a-development-branch-SKILL.md`
- Modify: `setup` (注释)
- Modify: `CHANGELOG.md`

- [ ] **Step 1: 删除过时设计文档**

```bash
rm docs/superpowers/plans/2026-04-20-subagent-execution-architecture.md
rm docs/superpowers/specs/2026-04-20-subagent-execution-architecture-design.md
```

- [ ] **Step 2: 修复路由卡版本标签**

`config/codesop-router.md` 第 1 行 `v2` → `v3`

- [ ] **Step 3: 修复 PRD**

- §5.6 `Now (v2.4.x)` → `Now (v3.3.x)`
- §4 v3.1.0 条目去重：删除重复的 skill patch / worktree / setup fix 描述

- [ ] **Step 4: 修复 AGENTS.md 模板**

- 删除 `PRD §7 只保留最近 5 条` 行
- compact 提醒改为：`statusLine 数据写入 /tmp/claude-context.json，context 高时用户可执行 /compact 释放空间`

- [ ] **Step 5: 清理 status/diagnose 反面说明**

- `CLAUDE.md`：删除 `- status / diagnose have been removed...` 行
- `README.md`：删除 `- status / diagnose 已从产品合同中移除` 行
- `README.en.md`：删除对应英文行

- [ ] **Step 6: 修复 finishing-branch patch 描述**

- Overview 描述改为反映实际行为（直接 push + PR）
- Step 4 删除 Options 分类，改为统一的 Cleanup Worktree 逻辑

- [ ] **Step 7: 修复其他过时内容**

- `updates.sh` 文件头：删除对 output.sh 死函数的依赖声明
- `detection.sh`：删除 `detect_project_shape_and_framework` 的 `$2`/`$3` 文档
- `setup` L242-244：更新 "v3.0" 注释
- `CLAUDE.md` gotchas：删除 `has_plugin()` 引用
- `CHANGELOG.md`：v1.2 → v1.1.x

- [ ] **Step 8: 跑测试**

Run: `bash tests/run_all.sh`
Expected: 9/9 PASS

- [ ] **Step 9: Commit**

```bash
git add -A && git commit -m "docs: fix stale content — version labels, dead refs, patch descriptions"
```

---

### Task 6: 测试框架统一

**Files:**
- Create: `tests/test_helpers.sh`
- Modify: `tests/codesop-router.sh`
- Modify: `tests/detect-environment.sh`
- Modify: `tests/setup.sh`
- Modify: `tests/codesop-init.sh`
- Modify: `tests/codesop-init-interview.sh`
- Modify: `tests/codesop-symlink.sh`
- Modify: `tests/codesop-update.sh`
- Modify: `tests/codesop-e2e.sh`
- Modify: `tests/skill-routing-coverage.sh`
- Modify: `tests/run_all.sh`

- [ ] **Step 1: 创建 tests/test_helpers.sh**

```bash
#!/usr/bin/env bash

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  printf '%s' "$haystack" | grep -qF "$needle" || fail "expected to contain: $needle"
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  printf '%s' "$haystack" | grep -qF "$needle" && fail "expected NOT to contain: $needle" || true
}
```

- [ ] **Step 2: 逐个修改测试文件**

每个测试文件（除 codesop-init-interview.sh 外）：
1. 删除本地 `fail()` 定义，改为 `source "$(dirname "$0")/test_helpers.sh"`
2. 如有本地 `assert_contains()` / `assert_not_contains()`，删除
3. `skill-routing-coverage.sh` 的 `assert_contains` 从精确行匹配改为子串匹配（使用 test_helpers.sh 版本）

`codesop-init-interview.sh`：
1. 删除 `source templates.sh` 行（如 Task 1 未删）
2. 删除 L550 重复的 `test_check_user_preferences` 调用
3. 重编号测试函数为连续序号
4. 保留自己的 `pass()`/`fail()` 计数机制（不强制统一为 exit 1 模式）

- [ ] **Step 3: 修改 run_all.sh**

改为捕获输出，失败时显示：
```bash
for suite in "$@"; do
  output=$(bash "$ROOT_DIR/tests/$suite" 2>&1)
  if [ $? -eq 0 ]; then
    echo "  PASS  $suite"
  else
    echo "  FAIL  $suite"
    echo "$output"
    failed=1
  fi
done
```

- [ ] **Step 4: 修复 codesop-init.sh 临时文件路径**

将 `/tmp/codesop-setup-codex.out` 等改为 `$tmpdir/` 下的路径。

- [ ] **Step 5: 跑测试**

Run: `bash tests/run_all.sh`
Expected: 9/9 PASS

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "test: unify test helpers, fix run_all.sh output, remove duplicate test"
```

---

### Task 7: Pipeline 分支衔接

**Files:**
- Modify: `SKILL.md`
- Modify: `config/codesop-router.md`

- [ ] **Step 1: 更新路由表链路组装规则**

`config/codesop-router.md` 链路组装段新增一行：
```
开发前 → 如在 main/master 上则插入衔接任务"创建 feat/ 分支"（条件性，用户可覆盖为 worktree）
```

- [ ] **Step 2: 更新 SKILL.md 链路组装逻辑**

在 SKILL.md §3 step 10 的链路组装中，当组装"新功能"类链路且当前分支是 main/master 时，在 writing-plans 后、subagent-driven-development 前插入衔接任务。

在 SKILL.md §4.3 的 proposing 格式示例中加入衔接任务行：
```
N. 创建 feat/ 分支
```

在 SKILL.md §4.5 Complete Example 中更新。

- [ ] **Step 3: 更新 SKILL.md TaskCreate 逻辑**

在 step 10.5 的 TaskCreate 规范中，说明衔接任务的创建方式：subject=`创建 feat/ 分支`，metadata=`{source: "codesop-pipeline"}`，blockedBy 前一个 task。

- [ ] **Step 4: 跑测试**

Run: `bash tests/run_all.sh`
Expected: 9/9 PASS

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: add pipeline transition task for branch creation before development"
```

---

### Task 8: 版本号更新、setup 同步、推送

**Files:**
- Modify: `VERSION`
- Modify: `skill.json`
- Modify: `PRD.md`
- Modify: `README.md`
- Modify: `README.en.md`
- Modify: `templates/system/AGENTS.md`
- Modify: `CHANGELOG.md`

- [ ] **Step 1: 更新 VERSION**

`3.3.3` → `3.4.0`

- [ ] **Step 2: 更新所有版本引用**

- `skill.json`: version → `3.4.0`
- `PRD.md`: Current Version → `3.4.0`，里程碑更新，Done Recently 更新，§4 新增 v3.4.0 条目
- `README.md` / `README.en.md`: badge 版本号
- `templates/system/AGENTS.md`: 头部版本号
- `CHANGELOG.md`: 新增 `[3.4.0]` 条目，汇总全部清理改动

- [ ] **Step 3: 跑全量验证**

Run: `bash tests/run_all.sh`
Expected: 9/9 PASS

Run: `bash setup --host claude`
Expected: 正常同步

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "chore: bump to v3.4.0 (codebase cleanup + pipeline branch transition)"
```

- [ ] **Step 5: 推送**

```bash
git push origin main
```
