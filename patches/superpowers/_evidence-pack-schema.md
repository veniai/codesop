# Evidence-Pack Schema + Visual Companion（共用模板）

> **源码模板（v9 sibling 同步，spec §4.6）**：本文件是**源码模板**，安装时（setup `patch_skills`）由 setup 复制到每个 patched skill 目录作为 **sibling 文件**（`_evidence-pack-schema.md`）——`writing-plans/`、`brainstorming/`、`verification-before-completion/` 各一份。patched SKILL.md 用**相对引用** `_evidence-pack-schema.md`（sibling），plugin cache runtime 可访问，避 v8 子文件不同步盲区（v8 踩坑：`spec-document-reviewer-prompt.md` 子文件不同步导致 reviewer 跑旧 schema）。setup 同步逻辑见 `setup` 的 `patch_skills()`：先同步 4 个主 SKILL.md，再把本 schema 作为 sibling 复制到上述 3 个 skill 目录。
>
> 共用模板：spec 阶段（T3 brainstorming reviewer）/ plan 阶段（writing-plans spec-coverage）/ 代码阶段（T5 verification Gate Function）三方引用同一份 schema。
>
> 字段定义以本 schema 为准（spec §4.5 协同机制 + §4.6 可执行契约**引用本 schema**，非反过来）：`docs/superpowers/specs/2026-06-29-spec-as-goal.md`（v9 spec-as-goal，覆盖 v7/v8 同章节）。本文件描述 schema + 给 visual companion 调用模板 + HTML 片段示例，是 T3/T5 实施时的**参考模板**，本身不是可执行代码。

---

## 1. 三块内容（本 schema 定义）

| 块 | 名称 | 内容 |
|---|---|---|
| **(a)** | 逐条判定 | §引用 + spec 原文摘录 + 产物位置 + 判定（满足 / 没满足 / 顾虑）+ 顾虑（顾虑 = advisory，标给人看，人决定阻不阻塞，同 §6） |
| **(b)** | 未覆盖扫描 | 扫全 spec，列没出现在产物的需求 |
| **(c)** | 跨模型审查栏 | codex 审查结果 |

**统一判定口径**（替 ✅/⚠️/❌，同 spec §4.2）：`满足` / `没满足` / `顾虑`。

---

## 2. (a) 逐条判定 —— 字段定义

每条 spec 需求一行 / 一卡。**字段固定，顺序固定**：

| 字段 | 必填 | 说明 |
|---|---|---|
| **§引用** | 是 | spec 章节号，如 `§4.1` / `§2 表` / `§8 不做表 第3行` |
| **spec 原文摘录** | 是 | **直接复制 spec 原文，不改写、不概括**。引号包裹或缩进块。这是 spec 作为「标杆」的机械锚点 |
| **产物位置** | 是 | **通用字段**——三阶段填法不同，见下表 |
| **判定** | 是 | 三选一：`满足` / `没满足` / `顾虑` |
| **顾虑** | 否 | 仅当判定=`顾虑` 时填。**advisory 性质**：标给人看，人决定阻不阻塞。同 §6「gate 收到的是 blocking 已清的证据包——人只看 advisory 顾虑做定夺」 |

**产物位置 —— 三阶段通用填法**（同一字段，按阶段填不同粒度）：

| 阶段 | 产物 | 产物位置填法 | 示例 |
|---|---|---|---|
| ① spec | spec 自身 | spec 章节（即 §引用 自身或邻近 §） | `§4.5 本节` |
| ② plan | plan task | `task-N` / `task-N.M` / `task-N 步骤K` | `task-3` / `task-5.2` |
| ③ 代码 | 代码 file:行 | `<path>:<line>` 或 `<path>:<start>-<end>` | `lib/detection.sh:142` / `setup:88-104` |

---

## 3. (b) 未覆盖扫描

扫全 spec，列**没出现在产物**的需求（产物里没对应行 / 没对应 task / 没对应 file:行）。

输出格式（表）：

| spec § | 未覆盖需求（原文摘录） | 性质 |
|---|---|---|
| §X.Y | 「…」 | 必做 / 边界 / 明确不做（误覆盖则报警） |

空表 = 全覆盖。非空 = /goal 完成条件 AND 不满足（§4.6 / R6），/goal 继续修，不判满足。

---

## 4. (c) 跨模型审查栏

codex 审查结果归位（spec §5 #4 跨模型强制 + §8 codex 不可用降级 / v9 R9）：

- **① spec 必走 codex:rescue**；②③ 可选（risk:high）；adversarial 不自动（用户手动）
- **R9 跨模型强制**：high-risk「满足」条目 codex 必复核，**不得标"跳过"**；codex 真不可用 → 该条目降级 advisory（人定夺），**不自动判满足**
- **codex 不可用** → 本栏标「codex 不可用，降级 advisory」，(a)(b) 照出；**非 high-risk 不阻塞**（advisory 给人可见，不静默丢锚点）；high-risk 见上一条（不自动判满足）
- codex 可用时本栏**顺带跨模型扫未覆盖**（补同模型盲点；结果并入 (b) 复核）

输出格式：

```
- codex 状态：可用 / 不可用（降级 advisory） / high-risk 强制未走（降级 advisory，不自动判满足）
- codex 结论：…（原文归位，不改写）
- 跨模型未覆盖补充：（并入 (b) 复核，或「无补充」）
```

---

## 5. 不可缩减边界字段（v9 R7，spec §2.4 / §5 #1 / §6 三件之一）

**不可缩减边界 = 防古德哈特硬约束，与完成条件同定义（spec §2.4）**：完成条件是"达到什么"，不可缩减边界是"不许怎么缩"。两者**同字段、同卡、同判定**，不是独立附加项。

证据包 (a) 逐条判定**必须含不可缩减边界字段**（当 spec 条目涉及边界时）。固定字段：

| 边界字段 | 含义 | 判定口径（mechanical，零 AI 判断） |
|---|---|---|
| **测试覆盖率不降** | 本轮改动后覆盖率 ≥ 改动前 | `coverage_after >= coverage_before`（pytest-cov / jest --coverage / go test -coverprofile 数值比对） |
| **不删测试** | 测试文件删除行 = 0 | `git diff` 断言：测试文件 `*.test.*` / `*_test.*` / `tests/` 删除行计数 = 0（**R8 diff 守护落点**：违反立即判失败，停 /goal） |
| **lint 规则数不减** | lint 配置规则数 ≥ 改动前 | eslint `.eslintrc` rules 计数 / ruff `select` 计数 / shellcheck directives 计数比对 |

**判定**：三选一——`满足`（边界未被触碰）/ `没满足`（违反任一，立即 blocker，停 /goal）/ `顾虑`（边界值变化但未违反，advisory 给人）。

**与完成条件 AND（R6，下一节）的关系**：不可缩减边界是完成条件 AND 的**前提**——边界被触碰 → 整个 AND 立即判失败，不进入测试/lint/证据包判定。

> **防古德哈特（spec §5 #1）**：边界字段与完成条件**同定义、同卡、同判定口径**，完成条件判满足但边界违反 → 整条判失败（防止 AI 钻空子：满足表面完成条件但偷偷删测试/降覆盖率/放宽 lint）。

---

## 6. 外部锚点 AND（v9 R6，spec §4.2 / §4.6 / §5）

**核心原则（spec §5）**：完成条件只认外部锚点信号，**不认 AI 自述**。

证据包完成条件 = 四项外部锚点 **AND**：

```
完成条件 = 测试全过 AND lint 零违规 AND 独立 subagent 证据包 blocking 清零 AND spec-coverage 未覆盖扫描 = 空
```

### 6.1 信号分级（spec §4.6）

| 分级 | 信号 | AI 判断成分 |
|---|---|---|
| **mechanical**（机器跑） | 测试 / lint / diff | 零 AI 判断 |
| **independent-AI** | 独立 subagent 证据包（挡同类脑补，不绝对） | 独立 AI 判断（非干活 AI） |
| **human** | deliver-gate 人审（语义偏离最后防线） | 人 |

**AND 约束（spec §4.6）**：完成条件 AND 里，**至少一项 mechanical**（测试或 lint），不能全靠 independent-AI。证据包 (a) 逐条判定 + (b) 未覆盖扫描 = independent-AI；测试/lint = mechanical；两者 AND 才算满足。

### 6.2 复杂度分级（spec §4.6，修 simple vs spec-coverage 冲突）

| 复杂度 | 完成条件 AND |
|---|---|
| **simple** | 测试全过 + lint 零违规（spec 短，spec-coverage 无意义，跳过证据包） |
| **moderate / complex** | 测试全过 + lint 零违规 + 独立 subagent 证据包 blocking 清零 + spec-coverage 未覆盖 = 空（**全四项 AND**） |

**判定**：四项全真 = 满足；任一假 = /goal 继续循环修，不判满足（spec §8 降级表：spec-coverage 非空 → /goal 继续修）。

### 6.3 证据包 (a)(b)(c) 在 AND 里的位置

- **(a) 逐条判定** → 喂 independent-AI 锚点（独立 subagent 出，干活 AI 不写结论，spec §5 #3）
- **(b) 未覆盖扫描** → 喂 spec-coverage 锚点（空表 = 全覆盖）
- **(c) 跨模型审查栏** → high-risk 条目强制走（R9），非 high-risk 可选
- 测试 / lint / diff → **不在证据包内**，由 /goal 每轮机械跑（mechanical 锚点）

---

## 7. Visual Companion 调用模板（复用 brainstorming）

走 brainstorming visual companion 路线（brainstorming skill 内置，非 spec §4.4）。证据包 subagent **自己**调 start-server，写 HTML content fragment（证据包可视化：mermaid 全链路 + 判定卡片 + 未覆盖 + 跨模型栏 + 边界 + AND）到 `screen_dir`，浏览器 serve 给人定夺。

### 7.1 启动 server

```bash
# 复用 brainstorming visual companion（brainstorming skill 内置）
# --project-dir 持久化、--open 自动开浏览器
bash brainstorming/scripts/start-server.sh --project-dir <proj> --open

# 返回（JSON，单行）：
# {"type":"server-started","port":52341,
#  "url":"http://localhost:52341/?key=ab12…",
#  "screen_dir":"/<proj>/.superpowers/brainstorm/<id>/content",
#  "state_dir":"/<proj>/.superpowers/brainstorm/<id>/state"}
```

拿 `screen_dir`、`state_dir`、`url` 三个字段。

### 7.2 写 HTML content fragment

**写 content fragment（非完整文档）**：HTML 文件**不以** `<!DOCTYPE` / `<html>` 开头时，server 自动套 brainstorming frame template（header / CSS / 连接状态 / 交互）。证据包可视化**默认走 fragment**。

把下面 §8 的 HTML 写到 `$screen_dir/<名>.html`（新文件名 = 新 screen，server serve 最新一个）。

### 7.3 mermaid 加载 script（必含）

前几轮证据包 subagent 实测有效，**原样照搬**——fragment 内首部插入：

```html
<script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
<script>window.addEventListener('load',function(){if(window.mermaid){mermaid.initialize({startOnLoad:false,theme:'neutral'});mermaid.run();}});</script>
```

### 7.4 推送前健康检查（同 brainstorming visual-companion.md）

- 确认 `$STATE_DIR/server-info` 存在、`$STATE_DIR/server-stopped` 不存在
- server 挂了 → 用**同一 `--project-dir`** 重启（复用端口，浏览器 tab 自动重连）
- `--open` 已自动开浏览器；仍把 `url`（含 `?key=`）作 fallback 给人

---

## 8. HTML 片段示例（spec-gate 可视化：spec 实质为主 + evidence pack 为辅）

spec-gate 人审看两层：**主 spec 实质呈现**（功能去留地图 / 改动跨层拓扑 / 数据流 / 去留三色卡片——subagent 读 spec 内容定制，回答"方案对不对"）+ **辅 evidence pack**（mermaid + (a)(b)(c) + 边界 + AND——完备性锚点，回答"够不够齐"）。占位符 `<…>` subagent 按 spec 内容 + §2/§5/§6 填。

```html
<!-- 证据包可视化 fragment —— server 自动套 frame template -->
<script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
<script>window.addEventListener('load',function(){if(window.mermaid){mermaid.initialize({startOnLoad:false,theme:'neutral'});mermaid.run();}});</script>

<style>
  .ep-judge{display:grid;grid-template-columns:auto 1fr auto;gap:.5rem 1rem;padding:.6rem .8rem;border:1px solid #ddd;border-radius:6px;margin:.4rem 0}
  .ep-judge.satisfy{border-left:4px solid #2da44e}
  .ep-judge.miss{border-left:4px solid #cf222e}
  .ep-judge.concern{border-left:4px solid #bf8700}
  .ep-tag{font-size:.8rem;font-weight:600;padding:.1rem .5rem;border-radius:10px;background:#f6f8fa}
  .ep-uncov{background:#fff8c5;border-left:4px solid #bf8700;padding:.5rem .8rem;margin:.4rem 0;border-radius:4px}
  .ep-codex{background:#ddf4ff;border-left:4px solid #0969da;padding:.5rem .8rem;margin:.4rem 0;border-radius:4px}
  .ep-boundary{background:#fbefff;border-left:4px solid #8250df;padding:.5rem .8rem;margin:.4rem 0;border-radius:4px}
  .ep-and{background:#dafbe1;border-left:4px solid #1a7f37;padding:.5rem .8rem;margin:.4rem 0;border-radius:4px;font-family:monospace}
  .ep-blockquote{background:#f6f8fa;border-left:3px solid #888;margin:.3rem 0;padding:.3rem .6rem;font-size:.85rem;color:#444}
</style>

<h2>spec-gate 可视化 — <spec 主题></h2>

<!-- 主：spec 实质呈现（subagent 读 spec 定制，回答"方案对不对"）-->
<h3>spec 实质：做了什么</h3>

<h4>功能去留地图</h4>
<p><span style="color:#1a7f37">保留：…</span> · <span style="color:#cf222e;text-decoration:line-through">砍掉：…</span> · <span style="color:#6e7781">隐藏：…</span> —— subagent 读 spec §变更点 渲染</p>

<h4>改动跨层拓扑</h4>
<pre class="mermaid">
flowchart LR
  <层A> --> <层B>
  %% subagent 读 spec 渲染改动跨层（如 main → renderer → config）
</pre>

<h4>关键数据流</h4>
<p><数据流描述> —— subagent 读 spec 渲染（如 offline_mode: env → ConfigManager → IPC → Redux → UI）</p>

<!-- 辅：evidence pack（完备性锚点，回答"够不够齐"）-->
<h3>evidence pack：够不够齐</h3>

<!-- (0) mermaid 全链路：spec → 产物 → 判定 -->
<h3>spec → 产物 → 判定 全链路</h3>
<pre class="mermaid">
flowchart LR
  S["spec §4.5"] --> P["产物<br/>task-3 / lib/x.sh:142"]
  P --> J{"判定"}
  J -->|满足| OK["✓ 进入 (b)"]
  J -->|没满足| MISS["✗ blocker / major<br/>回阶段修产物（§4.5）"]
  J -->|顾虑| ADV["advisory<br/>升 human-gate 给人（§6）"]
</pre>

<!-- (a) 逐条判定 —— 每条 spec 需求一卡 -->
<h3>(a) 逐条判定</h3>

<div class="ep-judge satisfy">
  <span><strong>§引用</strong>：§4.1</span>
  <div>
    <div class="ep-blockquote">「<spec 原文摘录，直接复制不改写>」</div>
    <div><strong>产物位置</strong>：&lt;task-3 / lib/detection.sh:142 / §4.5 本节&gt;</div>
    <div class="ep-tag" style="color:#2da44e">满足</div>
  </div>
  <span></span>
</div>

<div class="ep-judge concern">
  <span><strong>§引用</strong>：§4.3</span>
  <div>
    <div class="ep-blockquote">「<spec 原文摘录>」</div>
    <div><strong>产物位置</strong>：&lt;task-5&gt;</div>
    <div class="ep-tag" style="color:#bf8700">顾虑</div>
    <div><strong>顾虑（advisory）</strong>：&lt;标给人看，人决定阻不阻塞&gt;</div>
  </div>
  <span></span>
</div>

<div class="ep-judge miss">
  <span><strong>§引用</strong>：§6</span>
  <div>
    <div class="ep-blockquote">「<spec 原文摘录>」</div>
    <div><strong>产物位置</strong>：—（产物无对应）</div>
    <div class="ep-tag" style="color:#cf222e">没满足</div>
  </div>
  <span></span>
</div>

<!-- (b) 未覆盖扫描 -->
<h3>(b) 未覆盖扫描</h3>
<div class="ep-uncov">
  <strong>§X.Y</strong>：「<未覆盖需求原文>」<br/>
  <small>性质：必做 / 边界 / 明确不做（误覆盖报警）</small>
</div>
<p><em>（空 = 全覆盖）</em></p>

<!-- (c) 跨模型审查栏 -->
<h3>(c) 跨模型审查栏</h3>
<div class="ep-codex">
  <strong>codex 状态</strong>：可用 / 不可用（降级 advisory） / high-risk 强制未走（降级 advisory，不自动判满足）<br/>
  <strong>codex 结论</strong>：&lt;原文归位，不改写&gt;<br/>
  <strong>跨模型未覆盖补充</strong>：并入 (b) 复核 / 「无补充」
</div>

<!-- 不可缩减边界（v9 R7） -->
<h3>不可缩减边界（R7，与完成条件同定义）</h3>
<div class="ep-boundary">
  <strong>测试覆盖率</strong>：&lt;before&gt; → &lt;after&gt; ［判定：满足 / 没满足 / 顾虑］<br/>
  <strong>测试删除行</strong>：&lt;diff 计数&gt;（R8 diff 守护，非 0 = 立即失败停 /goal）<br/>
  <strong>lint 规则数</strong>：&lt;before&gt; → &lt;after&gt; ［判定：满足 / 没满足 / 顾虑］
</div>

<!-- 外部锚点 AND（v9 R6） -->
<h3>外部锚点 AND（R6，完成条件只认外部信号）</h3>
<div class="ep-and">
  完成条件 =<br/>
  &nbsp;&nbsp;测试全过 ［mechanical］ = <strong>真 / 假</strong><br/>
  &nbsp;&nbsp;<strong>AND</strong> lint 零违规 ［mechanical］ = <strong>真 / 假</strong><br/>
  &nbsp;&nbsp;<strong>AND</strong> 独立 subagent 证据包 blocking 清零 ［independent-AI］ = <strong>真 / 假</strong><br/>
  &nbsp;&nbsp;<strong>AND</strong> spec-coverage 未覆盖 = 空 ［independent-AI］ = <strong>真 / 假</strong><br/>
  <strong>约束</strong>：至少一项 mechanical（spec §4.6）<br/>
  <strong>总判定</strong>：满足 / 不满足（/goal 继续循环）
</div>
```

---

## 9. advisory 语义（再强调，防漂移）

- 判定=`顾虑` ≠ 阻塞。**advisory = 标给人看，人决定阻不阻塞**（spec §3 gate 降级 / §6）
- /goal 完成条件 AND（§6）只清 **blocker / major**（independent-AI 锚点为真）；advisory 顾虑**保留**进 deliver-gate
- 人收到的永远是「blocking 已清、AND 全真」的证据包——**人不审 blocking（那是 AI 的活），只做最终定夺 + high-risk 强制人审**（deliver-gate 风险分级，spec §3）

---

## 10. 三阶段 dispatch 引用（spec §4.2 / §4.6，供 T3/T5 落地）

| 阶段 | 复用对象 | 输出 | 内联要求 |
|---|---|---|---|
| ① spec | **替换** brainstorming spec-document-reviewer prompt 成本 schema（保留原 placeholder/ambiguity/consistency/scope/YAGNI 检查维度，仅改输出格式） | spec 阶段证据包 | prompt 内联进主 SKILL.md（§0 v9 内联约束） |
| ② plan | writing-plans spec-coverage subagent（升级版，扩到 moderate） | plan 阶段证据包 | prompt 内联进主 SKILL.md |
| ③ 代码 | verification-before-completion 的 **Gate Function** 输出（复用现有 gate，仅改输出格式，**不新增函数**）+ 加 diff 守护（R8） | 代码阶段证据包 | Gate Function 文本内联进主 SKILL.md |

**三阶段共同要求**（spec §4.6）：dispatch 的 subagent prompt **必须内联本 schema 全文**，不靠子文件引用（v8 踩坑：子文件不同步）。setup `patch_skills()` 同步主 SKILL.md，本 schema 通过 patches 目录原样复制 + T3/T5 patch 在主 SKILL.md 内嵌全文双保险。
