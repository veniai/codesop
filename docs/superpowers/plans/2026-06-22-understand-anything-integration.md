# understand-anything 接入 codesop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** 把 understand-anything 作为「0. 项目理解与导航」环节接入 codesop 路由表 + 工作台，含 7 状态图谱可用性检测（`check_understand_usability`），stale 降级使用。

**Architecture:** 路由表新增大类 0（条件触发，stale 降级）+ `lib/detection.sh` 加唯一函数 `check_understand_usability`（7 状态：absent/corrupt/unknown_head/stale_on/stale_off/fresh_on/fresh_degraded；worktree+子目录+JSON parser+完整性+fingerprints）+ SKILL §2/§4.1 接入 + README 兼容生态说明 + tests。

**Tech Stack:** bash（detection.sh）+ markdown（路由表/SKILL/README）+ codesop test framework（tests/）

**Spec:** `docs/superpowers/specs/2026-06-22-understand-anything-integration-design.md`（v3.1，已通过 codex 三审 + detection 实测）

## Global Constraints

- 不进产品合同 3+1 入口（`/codesop` + init/update/uninstall）
- codesop **不自动运行** `/understand`（用户显式动作）
- **stale（过期但完整）= 降级使用**（调用 understand-* + AI 警惕），**不跳过**；absent/corrupt/unknown_head = 跳过
- detection **唯一函数** `check_understand_usability`（删 v2 的 `has_understand_graph`）
- bash 必须 `bash -n` 通过（v2 有语法错误，已修）
- 路由表/SKILL/README 中文（codesop 默认中文）
- detection 代码用 **spec §1.5 的实测版**（已 `bash -n` + 7 状态 + worktree + 子目录全测过）—— 直接落地，不重写

## File Structure

| 文件 | 责任 |
|---|---|
| `lib/detection.sh` | 加 `check_understand_usability()`（7 状态，唯一图谱检测） |
| `config/codesop-router.md` | 技能总表最前加「0. 项目理解与导航」（4 条目）+ 链路组装加 2 条件插入规则 |
| `SKILL.md` | §2 Read Order 加第 5 条 + §4.1 step 7 旁加 `check_understand_usability` 调用 + 7 状态分级提示 |
| `README.md` / `README.en.md` | 加「兼容生态：understand-anything」段（中英） |
| `tests/` | 加 `check_understand_usability` 7 状态断言 + `bash -n` + 子目录/config 字符串实测 |

## Acceptance Criteria

**G1**: 路由表含新大类「0. 项目理解与导航」
- Verify: `grep "项目理解与导航" config/codesop-router.md && grep "understand-anything:understand-chat" config/codesop-router.md`
- Failure prevented: 大类缺失则接入失败
- Covers: R1

**G2**: 链路组装含 2 规则 + 触发锚点
- Verify: `grep "brainstorming 前条件插入 understand" config/codesop-router.md && grep "≥2 个路由模块" config/codesop-router.md`
- Covers: R2

**G3**: SKILL §2 Read Order 含第 5 条（图谱可用作上下文）
- Verify: `awk '/## 2. Read Order/,/## 3./' SKILL.md | grep "图谱.*可用"`
- Covers: R3

**G4**: SKILL §4.1 含 `check_understand_usability` 调用 + 7 状态分级提示
- Verify: `grep "check_understand_usability" SKILL.md && grep "UA_STATE=stale_on" SKILL.md`
- Covers: R4

**G5**: detection.sh 含 `check_understand_usability`
- Verify: `grep "check_understand_usability()" lib/detection.sh`
- Covers: R5

**G6**: `bash -n` 通过（防 v2 语法错误重演）
- Verify: `bash -n lib/detection.sh && echo OK`
- Failure prevented: v2 反引号注释语法错误
- Covers: R5

**G7**: 7 状态实测正确
- Given: 构造 7 种图谱状态（absent/corrupt-graph/corrupt-meta/stale-on/stale-off/fresh-on/fresh-degraded）
- When: 跑 `check_understand_usability`
- Then: 各状态输出对应 `UA_STATE`
- Verify: `bash tests/run_all.sh`（含 7 状态断言，真跑非 grep）
- Boundary: graph 损坏/meta 损坏/缺 hash → corrupt；非 git → unknown_head
- Covers: R5, R9, R12

**G8**: config 字符串拒绝
- Given: `config = {"autoUpdate":"true"}`（字符串非布尔）
- When: 跑 detection
- Then: 输出 `fresh_degraded`（非 `fresh_on`）
- Verify: tests 断言（构造字符串 config）
- Covers: R10

**G9**: worktree 重定向
- Given: linked worktree（主仓有图谱）
- When: 在 worktree 跑 detection
- Then: 读主仓图谱（`fresh_on`，不 `absent`）
- Verify: tests worktree 实测
- Covers: R11

**G10**: 子目录运行
- Given: 仓库子目录（如 `repo/client`）
- When: 在子目录跑 detection
- Then: root 定位仓库根（读仓库根图谱，不 `absent`）
- Verify: tests 子目录实测（`cd sub && check`）
- Covers: R11

**G11**: README 中英兼容生态段
- Verify: `grep "understand-anything" README.md && grep "understand-anything" README.en.md`
- Covers: R6

**G12**: tests 全过
- Verify: `bash tests/run_all.sh`
- Covers: R7

**G13**: stale_on 文案事实性（不断言 hook broken）
- Verify: `grep "会话外 commit" SKILL.md`（正面）+ `! grep "post-commit 钩子未生效" SKILL.md`（不含过度断言）
- Covers: R4

**G14**: `has_understand_graph` 删除
- Verify: `! grep -r "has_understand_graph" lib/ SKILL.md config/`
- Covers: R5

**G15**: 现有 detection 函数不回归
- Verify: `grep "check_git_health" lib/detection.sh`（仍在）+ `bash tests/run_all.sh` 现有用例仍过
- Covers: regression

**对抗自检**：G7/G8/G9/G10 用真跑（构造 mock `.understand-anything/`），非 grep，无假阳性。G13 正面+负面 grep 组合。G6 `bash -n` 可靠。G15 防现有功能回归。

**Coverage**：R1-R12 全覆盖（见 Traceability）。

**Gap scan**：edge cases（G7 boundary）✓；regression（G15）✓；integration（detection 被 SKILL §4.1 调用 → G4）✓。

## Complexity Assessment

**Level:** moderate
**File estimate:** 6（detection.sh / router / SKILL / README / README.en / tests）
**Modules:** detection（lib）、routing（config）、skill（SKILL）、docs（README×2）、tests
**Override:** none（detection.sh 是内部 lib，非对外 API）
**理由：** 6 文件但每个独立增量 + spec v3.1 已详定每处改动 + detection 代码已实测。若实施发现跨文件强耦合或文件数增 → escalate complex。

## Tasks（Lightweight）

### Task 1: lib/detection.sh 加 check_understand_usability

**Scope:** 加 7 状态检测函数（唯一图谱检测），确保不破坏现有函数
**Acceptance IDs:** G5, G6, G7, G8, G9, G10, G14, G15
**Likely files:** `lib/detection.sh`
**Implementation guidance:** 直接用 spec §1.5 的 detection 代码（已 `bash -n` + 7 状态 + worktree + 子目录全实测）。函数含：root 定位（`git rev-parse --show-toplevel` + worktree 重定向 `git-common-dir` + 非 git 回退 pwd）、存在性（graph+meta）、完整性（`node -e` JSON parser 校验 graph.nodes 数组 + meta.gitCommitHash `typeof string && length>=8`）、HEAD 可读、config（`autoUpdate===true` 严格）、fingerprints（autoUpdate=true 时检查）、新鲜度+配置+fingerprints 组合输出 7 状态。
**Key direction:** 复制 spec §1.5 代码原样落地（已实测，勿改写法）。确认 `lib/detection.sh` 无残留 `has_understand_graph`。
**Validation:** G5/G6/G14/G15 grep + `bash -n`；G7/G8/G9/G10 在 Task 5 tests 验证
**Out of scope:** SKILL 接入（Task 3）、tests（Task 5）

### Task 2: config/codesop-router.md 新增大类 + 链路规则

**Scope:** 技能总表最前加「0. 项目理解与导航」（4 条目）+ 链路组装加 2 条件插入规则
**Acceptance IDs:** G1, G2
**Likely files:** `config/codesop-router.md`
**Implementation guidance:** 用 spec §1.1 路由表追加文本（4 条目，understand-chat/diff 带 ★，触发条件含"若图谱可用"+"stale 降级"+ understand-diff 触发锚点）+ §1.2 链路组装规则（含锚点 `≥2 个路由模块/跨 client-server/改公共接口`）。
**Key direction:** 大类编号 0（前置上下文层），4 条目格式对齐现有大类表格。
**Validation:** G1/G2 grep
**Out of scope:** SKILL（Task 3）

### Task 3: SKILL.md §2 + §4.1 接入

**Scope:** §2 Read Order 加第 5 条 + §4.1 step 7 旁加 `check_understand_usability` 调用 + 7 状态分级提示
**Acceptance IDs:** G3, G4, G13
**Likely files:** `SKILL.md`
**Implementation guidance:** §2 第 5 条用 spec §1.3 文本（图谱可用作上下文，stale 参考性）；§4.1 step 7（git 健康检查 `check_git_health`）旁加一步 `check_understand_usability`，用 spec §1.5 的 7 状态分级提示文案（stale_on 事实性："自动更新未跟上——可能是会话外 commit 未触发 / 钩子未激活 / 增量失败"，**不含**"post-commit 钩子未生效"断言）。
**Key direction:** §4.1 复用现有「工作台注意行 + detection 函数」模式（同 git 健康/文档漂移）。
**Validation:** G3/G4/G13 grep
**Out of scope:** detection 实现（Task 1）

### Task 4: README.md + README.en.md 兼容生态段

**Scope:** 加「兼容生态：understand-anything」段（定位 + 不自动建图 + 会话内/外 commit 触发说明）
**Acceptance IDs:** G11
**Likely files:** `README.md`, `README.en.md`
**Implementation guidance:** 用 spec §1.4 内容要点，中英对应。强调："understand 钩子仅覆盖 Claude Code 会话内 commit——终端/IDE 直接 commit 不触发自动更新，需定期手动跑 `/understand`"。
**Key direction:** 兼容生态定位（非核心入口），不自动建图。
**Validation:** G11 grep
**Out of scope:** 路由表/SKILL

### Task 5: tests/ 加 7 状态断言

**Scope:** `check_understand_usability` 7 状态断言 + `bash -n` + 子目录/config 字符串实测
**Acceptance IDs:** G7, G8, G9, G10, G12
**Likely files:** `tests/`（新测试脚本或扩展 detect-environment 相关）
**Implementation guidance:** 参考 codesop 现有 tests 模式（`tests/` 下 shell 测试）。7 状态各构造 mock `.understand-anything/`（graph/meta/config/fingerprints）场景断言。`bash -n lib/detection.sh` 抽测。worktree（linked）+ 子目录（`cd sub`）实测。config 字符串 `"true"` → fresh_degraded。
**Key direction:** tests 要**真跑**（构造 mock 仓库 + 文件），不是 grep 文本。
**Validation:** `bash tests/run_all.sh`（G7/G8/G9/G10/G12）
**Out of scope:** detection 实现（Task 1）

### Task 6: 全量验证 + 收尾

**Scope:** 全量 tests + 路由覆盖 + 端到端冒烟
**Acceptance IDs:** G12, G15
**Likely files:** `tests/run_all.sh`
**Implementation guidance:** 跑 `bash tests/run_all.sh` + `check_routing_coverage`（确认新大类 0 被识别）+ 在已有 `.understand-anything/` 的项目（AIGIS-V5）跑 `/codesop` 冒烟（工作台注意行正确提示）。
**Key direction:** 确保现有用例不回归 + 新大类进路由覆盖。
**Validation:** `bash tests/run_all.sh && (source ~/codesop/lib/updates.sh && ROOT_DIR=~/codesop VERSION_FILE=~/codesop/VERSION check_routing_coverage)`
**Out of scope:** 无（收尾）

## Requirement Traceability

| Req | Spec § | Plan Task | Gn | Status |
|---|---|---|---|---|
| R1 路由表新大类 | §1.1 | T2 | G1 | ✅ |
| R2 链路规则+锚点 | §1.2 | T2 | G2 | ✅ |
| R3 SKILL §2 Read Order | §1.3 | T3 | G3 | ✅ |
| R4 SKILL §4.1 + 7 状态提示 | §1.5 | T3 | G4, G13 | ✅ |
| R5 detection 函数（唯一） | §1.5 | T1 | G5, G6, G14 | ✅ |
| R6 README 兼容生态 | §1.4 | T4 | G11 | ✅ |
| R7 tests | §5 | T5, T6 | G7, G12 | ✅ |
| R8 stale 降级语义 | §1.1/§3 | T2, T3 | G1, G3 | ✅ |
| R9 corrupt/unknown_head | §1.5 | T1, T5 | G7 | ✅ |
| R10 config JSON parser | §1.5 | T1, T5 | G8 | ✅ |
| R11 worktree+子目录 | §1.5 | T1, T5 | G9, G10 | ✅ |
| R12 fingerprints 检查 | §1.5 | T1, T5 | G7 | ✅ |
| regression 现有函数 | — | T1, T6 | G15 | ✅ |
