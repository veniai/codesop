# codesop 接入 understand-anything（项目理解环节）Spec

> **Date**: 2026-06-22
> **Scope**: `config/codesop-router.md`（新增路由大类 + 链路触发规则）+ `SKILL.md §2` Read Order + `SKILL.md §4.1` 工作台注意行（可用性分级提醒）+ `README`（中英）+ `lib/detection.sh`（图谱可用性检测：worktree 重定向 + 存在 + 完整性 + 新鲜度 + 配置 + fingerprints）
> **Inspiration**: [understand-anything](https://github.com/Egonex-AI/Understand-Anything)（代码库 → 知识图谱插件）；接入决策原则由维护者确立——**功能性优先于成本**
> **Relation**: 无前序 spec。与 `2026-06-15-doc-gate-anti-bloat-design.md` 的克制精神形成张力。**修订历史**：
> - **v2**：经 codex 一审实证（AIGIS-V5 `autoUpdate:true` 但 `meta.gitCommitHash ≠ HEAD`，drift）——"存在 ≠ 新鲜"、"配置开 ≠ 钩子激活"，据此触发条件升级为"可用才用"
> - **v3**：经 codex 二审 + **实测验证**（`bash -n` 实测 v2 §1.5 detection **语法错误 exit 2**；graph/meta 损坏误判 fresh；config `"autoUpdate":"true"` 字符串被 grep 当布尔 true；meta 缺 hash 误判 stale）。落实全部 P0+P1，detection 重写为 7 状态显式逻辑，经 `bash -n` + 7 状态全实测通过
> - **v3.1（codex 三审，本版）**：codex 三审确认 5 P0 + 5 P1 **全部修到位**，但实测发现 v3 子目录运行误判（`root=$(pwd)` 在 `repo/a/b` 找不到仓库根图谱）。修复：`root` 改用 `git rev-parse --show-toplevel` + worktree 重定向 + 非 git 回退。已实测：子目录正确定位仓库根、worktree 重定向主 root、非 git 回退 pwd
> **Principle**: ① 填补 codesop 真实功能性缺口（项目理解/架构认知）；② 不替换任何现有 skill；③ 图谱是导航非真相；④ codesop **不自动运行** `/understand`；⑤ 无图谱/损坏时静默跳过；⑥ **stale（过期但完整）降级使用，不跳过**——图谱过期仍有部分价值

---

## 0. 问题陈述

codesop 路由表 12 大类**没有"项目理解 / 架构认知"这一功能性环节**。AI 动手前理解现有项目靠 `brainstorming` 的「读 CONTEXT.md / ADR / 代码探索」兜底——线性、文本式、易漏远端依赖。understand-anything 提供结构化全局图谱（节点 + 依赖边 + 分层 + 引导路径 + 影响面分析），功能性上是质的提升。

**不算违反 anti-bloat**：填的是一直靠 brainstorming 兜底且兜不好的环节（给它正名 + 专用工具）；不新增 codesop 自有 skill，只接入已存在的外部插件（同 playwright/context7 模式）；不替换 brainstorming（chat 负责"现有的是什么样"，brainstorming 负责"想做什么"）。

**成本不作为阻塞项**（维护者决策原则）：用户主动跑 `/understand` 即接受一次性建图成本；增量更新日常 token 极低。

## 1. 改什么

### 1.1 路由表新增大类「0. 项目理解与导航」（`config/codesop-router.md`）

**位置**：技能总表最前，在「1. 需求分析与设计」之前。

**追加文本**：

```markdown
| **0. 项目理解与导航** | | | understand-anything | |
| | ★ | plugin | understand-anything:understand-chat | 跨模块改动 / 大仓库 / 陌生项目动手前：若图谱可用（§1.5 状态 ∈ {fresh_on, fresh_degraded, stale_on, stale_off}），基于图谱建立全局架构认知（brainstorming 前置输入）。图谱不可用（absent/corrupt/unknown_head）则跳过回退读 CONTEXT.md/ADR；**stale（过期）降级使用——AI 须警惕结构滞后**，工作台注意行同步提示更新 |
| | ★ | plugin | understand-anything:understand-diff | 跨模块改动开发完成后、验证前：若图谱可用，基于图谱**辅助**复核影响面（定位为辅助非权威——机制有盲区，见 §4）。不可用则跳过；stale 同样降级使用（AI 警惕）。触发锚点：改动涉及 ≥2 个路由模块 / 跨 client-server / 改公共接口 |
| | | plugin | understand-anything:understand-explain | 需深度理解某文件/函数的上下游或在架构中的位置时（调试、接手陌生模块） |
| | | plugin | understand-anything:understand-onboard | 新会话接手陌生项目 / 新人 onboarding：生成架构学习路径 |
```

**设计决策**：
- "可用"精确定义见 §1.5：`check_understand_usability` 返回 `{fresh_on, fresh_degraded, stale_on, stale_off}` = 可用；`{absent, corrupt, unknown_head}` = 不可用（跳过）
- **统一语义（修 v2 矛盾）**：stale（过期但完整）= **降级使用**（调用 understand-chat/diff，AI 警惕 + 工作台提示更新），**不跳过**——图谱过期仍有部分价值，硬跳过浪费。chat 与 diff 行为一致（都降级，不一个跳过一个降级）
- understand-chat / understand-diff 带 ★（场景优选）；explain / onboard 不标，纯按需
- `/understand`（建图）不进路由表，是 init 级动作（见 §1.4）

### 1.2 链路组装规则追加（`config/codesop-router.md`）

**追加文本**（现有规则之后）：

```markdown
跨模块改动 / 大仓库（锚点：≥2 个路由模块 / 跨 client-server / 改公共接口）→ brainstorming 前条件插入 understand-anything:understand-chat（建立全局上下文；图谱不可用则跳过回退读 CONTEXT.md/ADR；stale 则降级使用并提示更新）| 同锚点场景开发后 → 验证前条件插入 understand-anything:understand-diff（辅助影响面复核；不可用跳过；stale 降级并提示）
```

**设计决策**：
- 触发锚点写进链路文本（修 v2 锚点只在风险表的问题）：`≥2 个路由模块 / 跨 client-server / 改公共接口`——给 AI 具体判断依据，不只靠"跨模块/大仓库"主观词
- stale 降级使用（与 §1.1 一致），absent/corrupt 跳过

### 1.3 SKILL.md §2 Read Order 补充

**追加文本**：

```markdown
5. 若图谱**可用**（`check_understand_usability` 返回 fresh_on/fresh_degraded/stale_on/stale_off，见 §1.5），作为项目结构认知输入。fresh_* 为可信输入；stale_* 为参考性输入（AI 须警惕结构滞后，工作台已提示更新）；absent/corrupt/unknown_head 跳过。codesop 不负责触发建图
```

### 1.4 `/understand` 建图的定位（不进路由表，进 init 文档）

`README.md`（中英）"兼容生态"段：`/understand` 是 init 级功能性补充（codesop init 建文本基座，/understand 建结构基座，同档）；codesop **不自动运行**，不进 3+1 入口；大项目首次接入建议跑一次。**务必确认 auto-update 钩子真正激活**（不只设 `config.autoUpdate=true`，要确认 plugin 已 reload、Claude PostToolUse 钩子在最近一次会话内 commit 触发了增量）。注意 understand 钩子**仅覆盖 Claude Code 会话内 commit**——终端/IDE 直接 commit 不会触发，需定期手动跑 `/understand`。

### 1.5 图谱可用性检测与提醒（`lib/detection.sh` + `SKILL.md §4.1`）

**动机**：图谱有效性依赖它跟着代码演进。实证（AIGIS-V5：`autoUpdate=true` 但 meta≠HEAD）证明"配置开 ≠ 图谱新鲜"。**v3 实测还发现**：v2 的 detection（反引号注释 + grep）有 bash 语法错误、graph/meta 损坏误判 fresh、config 字符串 `"true"` 被当布尔——这些会让 AI 基于损坏/漂移图谱下错结论。本节给出**经 `bash -n` + 7 状态全实测通过**的 detection。

**7 状态**：`absent` / `corrupt` / `unknown_head` / `stale_on` / `stale_off` / `fresh_on` / `fresh_degraded`

**检测逻辑**（`lib/detection.sh` 加 `check_understand_usability()`，**唯一**的图谱检测函数——取代 v2 的 `has_understand_graph` + `check_understand_autoupdate` 双函数）：

```bash
check_understand_usability() {
  # root 定位：优先 git 仓库根（支持从子目录跑 /codesop），再 worktree 重定向（图谱在主 repo root），非 git 回退 pwd
  local root common_dir git_dir common_abs git_abs
  root=$(git rev-parse --show-toplevel 2>/dev/null)
  common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
  git_dir=$(git rev-parse --git-dir 2>/dev/null)
  if [ -n "$common_dir" ] && [ -n "$git_dir" ]; then
    common_abs=$(cd "$common_dir" 2>/dev/null && pwd -P)
    git_abs=$(cd "$git_dir" 2>/dev/null && pwd -P)
    if [ -n "$common_abs" ] && [ "$common_abs" != "$git_abs" ]; then
      root="$(dirname "$common_abs")"   # linked worktree → 主 repo root
    fi
  fi
  [ -n "$root" ] || root="$(pwd)"   # 非 git 回退
  local graph="$root/.understand-anything/knowledge-graph.json"
  local meta="$root/.understand-anything/meta.json"
  local cfg="$root/.understand-anything/config.json"
  local fp="$root/.understand-anything/fingerprints.json"

  # 1. 存在性
  [ -f "$graph" ] && [ -f "$meta" ] || { echo "UA_STATE=absent"; return; }

  # 2. 完整性：graph 必须可解析且含 nodes 数组
  if ! node -e "const g=require(process.argv[1]); if(!Array.isArray(g.nodes))process.exit(1)" "$graph" 2>/dev/null; then
    echo "UA_STATE=corrupt"; return
  fi

  # 3. 完整性：meta 必须可解析且 gitCommitHash 是有效字符串（拒绝 undefined/空/<8字符）
  local meta_hash
  meta_hash=$(node -e "const m=require(process.argv[1]); const h=m.gitCommitHash; if(typeof h!=='string'||h==='undefined'||h.length<8)process.exit(1)" "$meta" 2>/dev/null \
    && node -p "require(process.argv[1]).gitCommitHash" "$meta" 2>/dev/null)
  [ -n "$meta_hash" ] || { echo "UA_STATE=corrupt"; return; }

  # 4. HEAD 可读
  local head_hash; head_hash=$(git rev-parse HEAD 2>/dev/null)
  [ -n "$head_hash" ] || { echo "UA_STATE=unknown_head"; return; }

  # 5. config：用 JSON parser 严格判 autoUpdate===true（拒绝字符串 "true" / missing / corrupt）
  local cfg_on="false"
  if node -e "const c=require(process.argv[1]); if(c.autoUpdate!==true)process.exit(1)" "$cfg" 2>/dev/null; then
    cfg_on="true"
  fi

  # 6. fingerprints：autoUpdate=true 时必须存在且可解析（缺失则下次增量会 FULL_UPDATE 爆炸）
  local fp_ok="yes"
  if [ "$cfg_on" = "true" ]; then
    if ! { [ -f "$fp" ] && node -e "require(process.argv[1])" "$fp" 2>/dev/null; }; then fp_ok="no"; fi
  fi

  # 7. 新鲜度 + 配置 + fingerprints 组合
  if [ "$meta_hash" != "$head_hash" ]; then
    if [ "$cfg_on" = "true" ]; then echo "UA_STATE=stale_on"; else echo "UA_STATE=stale_off"; fi
  else
    if [ "$cfg_on" = "true" ] && [ "$fp_ok" = "yes" ]; then echo "UA_STATE=fresh_on"; else echo "UA_STATE=fresh_degraded"; fi
  fi
}
```

**SKILL.md §4.1 接入**（step 7 旁加一步），分级提示：
- `UA_STATE=absent` → 静默跳过（无图谱）
- `UA_STATE=corrupt` → `**注意**`：「知识图谱损坏（graph/meta JSON 无效或缺关键字段），无法使用。建议重跑 `/understand`」
- `UA_STATE=unknown_head` → `**注意**`：「非 git 仓库或 HEAD 不可读，无法判断图谱新鲜度」
- `UA_STATE=fresh_on` → 不提示（理想状态）
- `UA_STATE=fresh_degraded` → `**注意**`：「图谱新鲜但有隐患（未开 auto-update 或 fingerprints 缺失，下次增量可能 FULL_UPDATE）。建议 `/understand --auto-update`」
- `UA_STATE=stale_off` → `**注意**`：「图谱已过期（落后 HEAD）且未开自动更新。建议 `/understand --auto-update`」
- `UA_STATE=stale_on` → `**注意**`（事实性，**不断言 hook 坏了**）：「图谱已过期（meta 落后 HEAD），auto-update 开启但自动更新未跟上——可能是会话外 commit 未触发（understand 钩子仅覆盖会话内 commit）/ 钩子未激活 / 增量失败。**图谱可降级使用但须警惕滞后**。建议 `/understand` 增量更新」

**设计决策**：
- **bash 语法**：显式 `if/else` + `node -e` 退出码判定，**无反引号注释**（修 v2 `bash -n` 报错）。已实测 `bash -n` 通过
- **JSON parser**：全部用 `node -e`/`node -p` 读 JSON（修 v2 grep 误判 `"autoUpdate":"true"` 字符串为布尔）。config 严格 `===true`
- **node 输出校验**：meta.gitCommitHash 校验 `typeof==='string' && !=='undefined' && length>=8`（修 v2 把 `node -p` 返回的 `"undefined"` 字符串当有效 hash）
- **graph/meta 损坏 → corrupt**（修 v2 损坏态误判 fresh）
- **fingerprints 检查**：autoUpdate=true 时缺 fingerprints 判 `fresh_degraded`（不判 fresh_on，避免下次 FULL_UPDATE 爆炸的"理想状态"假象）
- **root 定位（worktree + 子目录）**：`git rev-parse --show-toplevel` 取仓库根（支持从子目录跑 `/codesop`，修 codex 三审发现的子目录误判 absent）+ worktree 重定向到主 repo root（understand 把图谱写主 root，codesop 必走 worktree）。两者都是核心路径不是边缘
- **stale_on 文案事实性**：说"自动更新未跟上 + 可能原因（会话外 commit / 钩子未激活 / 增量失败）"，**不**断言"post-commit 钩子未生效"（understand 用的是 Claude PostToolUse hook，且会话外 commit 天然不触发，≠ hook 坏了）

## 2. 执行计划

| 文件 | 改什么 |
|------|--------|
| `config/codesop-router.md` | 技能总表最前插入「0. 项目理解与导航」（4 条目，触发条件含"可用"+"stale 降级"+ understand-diff 触发锚点）；链路组装段加 2 条条件插入规则（含锚点） |
| `SKILL.md` | §2 Read Order 加第 5 条（图谱可用作上下文输入，stale 为参考性）；§4.1 step 7 旁加 `check_understand_usability` 调用 + 7 状态分级提示规则 |
| `README.md` + `README.en.md` | 「兼容生态：understand-anything」段：定位 + 不自动建图 + **务必确认会话内 commit 触发了增量**（会话外 commit 不触发，需定期手动 /understand） |
| `lib/detection.sh` | 加 `check_understand_usability()`（**唯一**图谱检测函数，7 状态，含 worktree 重定向 + JSON parser + 完整性 + fingerprints）。**删去** v2 的 `has_understand_graph()`（存在性检查与"可用"语义冲突） |
| `tests/` | 路由覆盖检查；`check_understand_usability` 7 状态断言（重点：`bash -n` 通过、corrupt 识别、config 字符串 `"true"`→fresh_degraded、stale_on 文案事实性、worktree 重定向实测） |

不影响：产品合同 3+1 入口、setup patch、superpowers 补丁、现有 skill 定义。版本：minor bump。

## 3. 不做什么

| 不做 | 为什么 |
|------|------|
| `/understand` 进 3+1 入口 | 建图是外部插件显式动作，codesop 只兼容不代决 |
| codesop 自动运行 `/understand` | 一次性高 token 成本须用户显式选择 |
| understand-chat 替换 brainstorming 代码探索 | 导航（全局认知）≠ 确认（读真实代码） |
| 无图谱时强制提示建图 | 噪音；静默跳过 + README 说明 |
| understand-chat/diff 设为无条件必走 | 单文件小改动用不上；条件插入（锚点限定） |
| 新增 codesop 自有"项目理解" skill | understand-anything 已成熟，接入优于造轮子 |
| understand-diff 当权威影响面审计 | 机制有盲区（重命名/未入图/动态调用），定位辅助复核，权威性靠 verification + code-review |
| **stale（过期）跳过 understand-chat/diff** | 图谱过期仍有部分价值；**降级使用**（AI 警惕），硬跳过浪费 |
| **worktree 检测当"可选增强"** | codesop `using-git-worktrees` 是必走 skill，worktree 失效 = 推荐开发模式下失效，必须跟随重定向 |

## 4. 风险

| 风险 | 缓解 |
|------|------|
| **图谱过期**（codex 实证）→ AI 基于旧结构下错结论 | §1.5 含 staleness 检测（meta vs HEAD），stale_on/off 提示 + 降级使用（不跳过）；understand 自带 SessionStart hook 兜底；README 说明会话外 commit 不触发 |
| **detection 误判**（损坏态/config 字符串/反引号语法，v3 实测发现） | §1.5 detection 全用 JSON parser + 显式 if/else + node 输出校验；**`bash -n` + 7 状态全实测通过**；tests/ 含断言 |
| **understand-diff 机制盲区**（changed file path + 1-hop，重命名/未入图/动态调用漏报） | 定位辅助复核非权威（§3）；不替代 verification + code-review |
| 触发词靠 AI 自判 | 链路文本 + 路由条目含具体锚点（≥2 路由模块 / 跨 client-server / 改公共接口） |
| 图谱准确性 < 100% | 导航非真相；brainstorming/systematic-debugging 仍读真实代码 |
| worktree 检测不到图谱 | §1.5 detection 跟随 understand 重定向到主 repo root（git-common-dir）；必做非可选 |
| 路由表 12→13 大类 | §0 论证补缺口非膨胀；新大类对无图谱项目自熔断（触发条件显式"若可用"） |
| understand-chat 与 brainstorming 职责混淆 | chat 在 brainstorming 前（认知输入），README 强调"导航 vs 确认"边界 |
| fingerprints 缺失致下次增量 FULL_UPDATE | §1.5 autoUpdate=true 时检查 fingerprints，缺失判 fresh_degraded 提示 |

## 5. 验收标准

1. 路由表含「0. 项目理解与导航」（understand-chat/diff 带 ★，触发条件含"若图谱可用"+"stale 降级使用"，understand-diff 注明"辅助复核"+触发锚点）
2. 链路组装 2 条规则含锚点 + "不可用跳过 / stale 降级"
3. SKILL.md §2 第 5 条（图谱可用作上下文，stale 参考性）；§4.1 含 `check_understand_usability` + 7 状态分级提示
4. README（中英）含兼容生态段 + 会话内/外 commit 触发说明
5. `bash tests/run_all.sh` 通过；路由覆盖检查通过
6. **`bash -n lib/detection.sh` 通过**（v2 的语法错误已修）
7. **`check_understand_usability` 7 状态实测正确**：absent（无 graph/meta）/ corrupt（graph 损坏 / meta 损坏 / meta 缺 gitCommitHash）/ unknown_head（非 git）/ stale_on（meta≠HEAD + autoUpdate=true）/ stale_off（meta≠HEAD + autoUpdate≠true）/ fresh_on（meta=HEAD+autoUpdate=true+fp ok）/ fresh_degraded（meta=HEAD 但 autoUpdate≠true 或 fp 缺）
8. **config 字符串误判防护实测**：`{"autoUpdate":"true"}` → fresh_degraded（非 fresh_on）
9. **root 定位实测**：① worktree——在主仓有图谱的 worktree 里跑 `/codesop` 正确读主仓图谱（不误判 absent）；② **子目录**——在仓库子目录（如 `repo/client`）跑 `/codesop` 正确定位仓库根图谱（修 codex 三审发现的子目录误判）
10. **stale_on 文案事实性**：不含"post-commit 钩子未生效"断言，含"会话外 commit 未触发 / 钩子未激活 / 增量失败"可能性

## 6. 开放问题（待维护者确认）

1. **大类编号**：用「0」（前置上下文层）vs 归入现有类作子项。倾向 0。
2. **understand-chat/diff 是否升铁律**：当前条件插入（锚点限定）。可考虑升 ☆（有图谱时必走）。
3. **SessionStart 是否对"大项目 + 无图谱"提示建图**：默认不提示（静默）。备选：>300 文件一次性提示。倾向不提示。

（worktree 重定向已从开放问题移除——v3 升为必做，见 §1.5。）
