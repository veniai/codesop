# codesop 代码库全面清理 Spec

> **Date**: 2026-04-25
> **Scope**: 删死代码、消重复、修过时内容、统一测试框架、Pipeline 衔接补全
> **Principle**: 只删不改功能，不引入新行为（2.3.4 分支衔接除外）

---

## 0. 全局总览

```
清理前                              清理后
─────────────────────────────      ─────────────────────────────

codesop 入口                       codesop 入口
├── lib/output.sh (10 函数)        ├── lib/detection.sh
│   ├─ 8 个死函数 ✂️               │   ├─ detect_project_language()
│   └─ find_superpowers_..() →迁    │   ├─ find_superpowers_plugin_path() ←迁入
├── lib/detection.sh               │   ├─ has_mcp_server()
│   ├─ detect_environment() ✂️     │   └─ detect_project_shape_and_framework()
│   ├─ has_plugin() ✂️             ├── lib/updates.sh
│   └─ 4 个内部死函数 ✂️           │   └─ 删 check_plugin_versions + 死数组
├── lib/templates.sh 整个删 ✂️     ├── lib/commands.sh (不变)
├── lib/updates.sh                 ├── lib/init-interview.sh
│   ├─ check_plugin_versions ✂️    │   └─ 删 has_superpowers + _SP_CANDIDATES
│   ├─ CORE_PLUGINS ✂️            └── ...
│   └─ OPTIONAL_PLUGINS ✂️        └─
├── lib/commands.sh (不变)
├── lib/init-interview.sh
│   └─ has_superpowers() ✂️
└── ...

测试框架 (9 文件)                  测试框架 (9 文件 + 1 共享)
├── 每个文件自己定义 fail() ✂️     ├── tests/test_helpers.sh ←新增
├── run_all.sh 吞输出 ✂️          │   └─ fail() + assert_contains() + assert_not_contains()
└── init-interview 重复测试 ✂️    ├── 每个文件 source test_helpers.sh
                                    ├── run_all.sh 失败时显示输出
                                    └── init-interview 删重复 + 重编号

文档清理                            文档清理
├── docs/superpowers/plans/         ├── 2026-04-20 subagent 架构文档 ✂️
├── docs/superpowers/specs/         ├── 2026-04-20 subagent 架构文档 ✂️
├── config/codesop-router.md        │   v2 → v3
├── templates/system/AGENTS.md      │   PRD §7 引用 ✂️ · compact 描述改为务实
├── PRD.md                          │   v2.4.x → v3.3.x · v3.1.0/v3.3.1 去重
├── CLAUDE.md                       │   status/diagnose ✂️ · has_plugin 引用 ✂️
├── README.md / README.en.md        │   status/diagnose ✂️
└── finishing-branch patch          └── 描述对齐实际行为（直接 push+PR）

Pipeline 衔接补全
├── SKILL.md                        │   writing-plans 后插入衔接任务"创建 feat/ 分支"
└── config/codesop-router.md        └   链路组装规则同步

图例: ✂️ = 删除  ←迁 = 迁移  →迁 = 迁出
```

## 1. 目标

清理 codesop 代码库中长期积累的死代码、重复实现、过时文档和测试不一致问题。不改变任何用户可见行为。补全 Pipeline 衔接（创建分支），使开发流程不在 main 上直接写代码。

## 2. 清理项

### 2.1 删除死模块

#### 2.1.1 `lib/templates.sh` — 整个文件

`generate_templates()` 从未被调用（6 个函数全死）。PRD 模板生成已由 `init-interview.sh:generate_prd_template()` 接管。AGENTS.md 生成已简化为写 `@CLAUDE.md`。

**操作**：删除文件，从 `codesop` 入口的 source 行中移除 `templates.sh`。

**受影响文件**：
- 删除：`lib/templates.sh`
- 修改：`codesop`（移除 `source lib/templates.sh` 行）
- 修改：`tests/codesop-init-interview.sh`（移除 L19 的 `source templates.sh` 行）

#### 2.1.2 `lib/output.sh` — 整个文件删除

10 个函数中只有 `find_superpowers_plugin_path()` 被 `setup` 和 `updates.sh` 使用。其余 8 个从未被调用。但只剩 1 个函数时文件名 "output" 完全误导。

**操作**：
1. 将 `find_superpowers_plugin_path()` 移到 `lib/detection.sh`（语义更匹配：检测插件路径）
2. 删除 `lib/output.sh` 整个文件
3. 从 `codesop` 入口的 source 行中移除 `output.sh`
4. `tests/skill-routing-coverage.sh:32` 的 `source output.sh` 改为 `source detection.sh`

**受影响文件**：
- 删除：`lib/output.sh`
- 修改：`lib/detection.sh`（新增函数）、`codesop`（移除 source 行）、`tests/skill-routing-coverage.sh`（改 source 目标）

### 2.2 删除死函数和死变量

#### 2.2.1 `lib/detection.sh`

| 删除项 | 原因 |
|--------|------|
| `detect_environment()` (L257-276) | 从未调用，`run_init_interview` 自行检测 |
| `has_plugin()` (L219-224) | 从未调用，实际检测用内联 jq |
| `detect_tool_by_registry()` (L168) | 仅被 `detect_environment` 调用，随主函数一起删 |
| `detect_ecosystem_by_registry()` (L191) | 同上 |
| `detect_all_tools()` (L241) | 同上 |
| `detect_all_ecosystems()` (L247) | 同上 |
| `detect_project_shape_and_framework()` 的 `$2`/`$3` 文档注释 (L78-79) | 参数不存在，注释过时 |
| `AI_TOOLS` 数组 (L63-69) | 仅被 `detect_all_tools()` 使用，随主函数一起删 |
| `ECOSYSTEM_REGISTRY` 数组 (L72-74) | 仅被 `detect_all_ecosystems()` 使用，随主函数一起删 |

**保留**：`detect_project_language()`、`detect_project_shape_and_framework()`、`has_mcp_server()`、`find_superpowers_plugin_path()`（从 output.sh 迁入）— 这些仍在使用。

#### 2.2.2 `lib/updates.sh`

| 删除项 | 原因 |
|--------|------|
| `check_plugin_versions()` (L236-248) | 已被 `check_plugin_completeness()` 取代 |
| `CORE_PLUGINS` 数组 (L46) | 只在测试中引用，实际代码直接用 `SUPERPOWERS_PLUGIN` + `REQUIRED_PLUGINS` |
| `OPTIONAL_PLUGINS=()` (L47) | 空数组，从未使用 |
| `check_document_consistency()` (L501-503) | 单行包装器，唯一调用者可直接调 `check_codesop_document_consistency()` |

**修改**：将 `check_document_consistency()` 的调用者（如有）改为直接调用 `check_codesop_document_consistency()`。

#### 2.2.3 `lib/init-interview.sh`

| 删除项 | 原因 |
|--------|------|
| `_SP_CANDIDATES` 数组 (L174-181) | 仅 `has_superpowers()` 使用，而 `has_superpowers()` 仅在 `updates.sh` 未加载时触发——实际上 `updates.sh` 总是在之前加载 |
| `has_superpowers()` (L186) | 同上 |

**验证**：先 grep 确认 `has_superpowers` 和 `_SP_CANDIDATES` 确实只在 init-interview.sh 内部引用。

### 2.3 消除重复

#### 2.3.1 `find_superpowers_plugin_path()` — setup 保持独立副本

`setup:151-163` 和 `output.sh:152-166` 定义了完全相同的函数。2.1.2 将 output.sh 中的版本迁到 `detection.sh`。

**操作**：setup 中保留独立副本（setup 是自包含脚本，不 source lib/），加注释标明 canonical 版本在 `lib/detection.sh`。

#### 2.3.2 `ensure_symlink()` — setup 保持独立副本

`setup:80-86` 和 `init-interview.sh:86-92` 定义了完全相同的函数（3 行代码）。

**操作**：setup 中保留独立副本（理由同上——setup 是自包含脚本）。3 行函数不值得引入 source 依赖。

#### 2.3.3 PRD 模板生成去重

`templates.sh:write_prd_template()` 和 `init-interview.sh:generate_prd_template()` 做同样的事。

**操作**：2.1.1 删掉 `templates.sh` 后，此重复自动消除。`init-interview.sh` 的版本成为唯一实现。

### 2.3.4 Pipeline 分支创建 — 修复 main 上直接写代码的问题

当前 pipeline 链路：`writing-plans → subagent-driven-development → ... → finishing-a-development-branch`

`finishing-a-development-branch` 的 Step 3 (push + PR) 假设已在 feature branch 上，但 pipeline 中没有步骤在 writing-plans 之后创建新分支。结果是代码直接写在 main 上。

**问题链路**：
```
writing-plans ──→ subagent-driven-development ──→ ... ──→ finishing-branch
     │                    │                                    │
     │ 在 main 上          │ 在 main 上写代码                    │ 假设在 feature 分支
     │                    │ → 脏的 main                         │ → push 失败或直接推 main
     └────────────────────┴────────────────────────────────────┘
                          缺少"创建分支"这一步
```

**修复后链路**：
```
writing-plans ──→ 创建 feat/ 分支 ──→ subagent-driven-development ──→ ... ──→ finishing-branch
     │               衔接任务              │                              │
     │ 在 main 上     │ checkout -b        │ 在 feature 分支上写代码        │ push + PR ✓
     └────────────────┴────────────────────┴──────────────────────────────┘
                      插入条件：仅在 main/master 上时插入
```

**设计决策**：用衔接任务（transition task），不用自动规则。

与现有衔接任务"根据审查反馈修订方案"同一模式 — 两个 skill 之间的机械过渡。在 pipeline dashboard 中可见，AI 执行即可。

**Dashboard 显示**（与现有衔接任务一致）：
```
☐ 4. 创建 feat/ 分支
```

**TaskCreate 规范**：
- subject: `创建 feat/ 分支`（衔接任务格式，无 skill 前缀）
- metadata: `{source: "codesop-pipeline"}`（无 skill 键 = 衔接任务）

**执行时**：
1. 从上下文推断分支名（PRD 里程碑、spec 文件名、用户原始请求）
2. `git checkout -b feat/<feature-name>`
3. TaskUpdate(completed)，自动进入下一个 task

**条件性插入**：在 SKILL.md step 10 组装链路时，检查 `git branch --show-current`。如果已在 feature 分支上，不插入此衔接任务。

**用户可覆盖**：默认是"创建分支"。用户说"用 worktree"时，衔接任务改为"创建 worktree 并切换"。

**修改文件**：
- `SKILL.md` §3 step 10 链路组装 + step 10.5 TaskCreate（插入衔接任务）
- `config/codesop-router.md` 链路组装段

### 2.4 过时内容修复

#### 2.4.1 删除过时设计文档

| 文件 | 原因 |
|------|------|
| `docs/superpowers/plans/2026-04-20-subagent-execution-architecture.md` | 子 agent 架构已回退 |
| `docs/superpowers/specs/2026-04-20-subagent-execution-architecture-design.md` | 同上 |

**操作**：删除这两个文件。

#### 2.4.2 路由卡版本标签

`config/codesop-router.md` 第 1 行标注 `v2`。

**操作**：改为 `v3`（不需要精确到小版本，反映大版本即可）。

#### 2.4.3 PRD 版本规划过时

PRD §5.6 第 300 行写 `Now (v2.4.x)`。

**操作**：改为 `Now (v3.3.x)`。

#### 2.4.4 AGENTS.md 引用不存在的 PRD §7

`templates/system/AGENTS.md` 第 71 行 `PRD §7 只保留最近 5 条`。

**操作**：PRD 当前结构中没有独立的工作日志节（工作日志相关内容在 §2.4 Done Recently），删除这一行。

#### 2.4.5 `finishing-branch` patch 描述清理

`patches/superpowers/finishing-a-development-branch-SKILL.md` 的 Overview 和 Step 4 仍引用"4 选项菜单"，但 patch 已改为直接 push+PR。

**操作**：
- Overview/描述改为反映实际行为："直接 push + 创建 PR"
- Step 4 删除 "For Options 1, 2, 4" / "For Option 3" 分类
- 保留 Cleanup Worktree 逻辑本身（内容正确，只是描述不对）

#### 2.4.6 `status`/`diagnose` 反面说明清理

4 个文件中有 "status / diagnose 已从产品合同中移除" 的说明。这些功能在 v1.1.2 移除，当前用户从未见过。

| 文件 | 操作 |
|------|------|
| `CLAUDE.md` L34 | 删除 "- `status` / `diagnose` have been removed..." |
| `README.md` L101 | 删除 "- `status` / `diagnose` 已从产品合同中移除" |
| `README.en.md` L95 | 删除对应英文行 |
| `PRD.md` L268 | "独立的 status / diagnose 产品面" 在 Out of Scope 中，可保留（表示明确不做的范围） |

#### 2.4.7 compact 提醒规则 — 改为务实描述

`templates/system/AGENTS.md` 第 43 行 `读取 /tmp/claude-context.json 的 used_percentage...`。

`setup` 仍在写入 `/tmp/claude-context.json`，这条规则是唯一的用户文档。但原描述暗示 AI 会主动检查百分比并触发提醒，实际上不会。

**操作**：改为务实描述，不承诺自动触发：
```
- statusLine 数据写入 `/tmp/claude-context.json`，context 高时用户可执行 `/compact` 释放空间
```

#### 2.4.8 PRD v3.1.0 和 v3.3.1 内容重复

PRD §4 中 v3.3.1 (L119-123) 和 v3.1.0 (L125-131) 列了相同的 skill patch + worktree + setup fix 改动。

**操作**：v3.1.0 条目只保留回退子 agent 架构的描述，删掉重复的 skill patch / worktree / setup fix 条目（这些已属于 v3.3.1）。

#### 2.4.9 过时注释清理

| 文件 | 注释 | 操作 |
|------|------|------|
| `updates.sh` L16 | "depends on output.sh: format_tool_state, format_ecosystem_state" — 依赖不存在 | 删除该行 |
| `detection.sh` L78-79 | "$2/$3 parameter docs" — 参数不存在 | 删除这两行 |
| `setup` L242-244 | "v3.0" 和 "(tracked)" — 版本过时 | 更新注释 |
| `CLAUDE.md` gotchas | 删除已不存在的 `has_plugin()` 引用 | 更新 |

#### 2.4.10 CHANGELOG v1.2 引用

CHANGELOG 第 306 行引用 `v1.2`，但 CHANGELOG 中无此版本。

**操作**：改为 `v1.1.x`（泛指 v1.1 系列的某个版本）。

### 2.5 测试统一

#### 2.5.1 提取共享测试辅助函数

9 个测试文件各自定义 `fail()` 和部分定义 `assert_contains()` / `assert_not_contains()`。

**操作**：
1. 创建 `tests/test_helpers.sh`，包含 `fail()`、`assert_contains()`（子串匹配）、`assert_not_contains()`
2. 每个测试文件改为 `source tests/test_helpers.sh`
3. 统一使用子串匹配语义（当前 `skill-routing-coverage.sh` 用的精确行匹配是 bug）

#### 2.5.2 `run_all.sh` 保留失败输出

当前 `run_all.sh` 将所有 stdout/stderr 重定向到 `/dev/null`，失败时看不到诊断。

**操作**：改为捕获输出，仅在失败时显示。策略：
```bash
output=$(bash "$test" 2>&1)
if [ $? -eq 0 ]; then
    echo "  PASS  $suite"
else
    echo "  FAIL  $suite"
    echo "$output"
fi
```

#### 2.5.3 init-interview 重复测试修复

`test_check_user_preferences` 被调用两次（L539 和 L550）。

**操作**：删除 L550 的重复调用，保留 L539 中的。

#### 2.5.4 init-interview 测试编号修复

Test 17 → Test 21 跳了 18-20。

**操作**：重编号为连续序号。

#### 2.5.5 `/tmp/` 硬编码临时文件

`codesop-init.sh` 写 `/tmp/codesop-setup-*.out` 不清理。

**操作**：改为写 `$tmpdir/` 下的路径（已有 trap 清理）。

## 3. 不做的事情

| 不做 | 原因 |
|------|------|
| 架构树去重 | 4 个文件各有不同侧重（CLAUDE.md 有模块加载顺序，PRD 有完整版，README 省略细节），保持各自完整比引入引用更清晰 |
| 产品合同去重 | 同上，6 个文件各自语境不同 |
| `interview_user_preferences()` 测试覆盖 | 交互式 `read -p` 无法在 CI 中可靠测试，不投入 |
| `patch_skills()` 加备份 | 当前 diff 检测逻辑足够，`setup` 重跑会重打 patch |
| `setup` 中 sed→jq 迁移 | `copy_skill_manifest()` 的 sed 只处理简单 JSON，风险大于收益 |
| 路由测试 skill 列表动态化 | 从路由表动态提取 skill 列表需要解析 markdown 表格，复杂度不值得 |

## 4. 执行顺序

1. 删死模块和函数 + `find_superpowers_plugin_path` 迁移（2.1 + 2.2 + 2.3.1 归属调整）→ 跑测试确认不破坏
2. 其余消重复（2.3.2 + 2.3.3）→ 跑测试
3. 过时内容修复（2.4）→ 跑测试
4. 测试统一（2.5）→ 跑测试
5. 全量 `bash tests/run_all.sh` + `bash setup --host claude` 最终验证
6. 版本号 3.3.3 → 3.4.0（清理性版本），更新所有版本文件
7. 推送远端

## 5. 验证标准

- 9/9 测试通过
- `setup --host claude` 正常同步
- 所有被删函数在代码库中无引用（grep 验证）
- 无行为变化（`codesop init`、`codesop update` 输出不变）
