# 对抗式审查 v1（spec-as-goal，待 codex 审 + 人 spec-gate）

**日期**：2026-07-01
**状态**：spec-gate 过（人审 rubric 五项 + 攻击者视角 dig_deeper；codex Cloudflare 封锁 + Hiddify 代理坏双重不可用 → R9 降级人审）→ 实施中（simple 跳 plan）
**定位**：v9 之后的视角强化——交付前多 agent **攻击者视角**全链路扫 bug。卡兹克第二点。
**关联**：卡兹克《2 个 Vibe Coding 神级 Prompt》、PRD §2.2 剩候选、codesop v9（deliver-gate 风险分级）、动态工作流 adversarial verify、codex:adversarial-review

---

## 1. 背景

### 1.1 命题
verification（测试/lint 过）不能保证"上线稳"——**边界 bug**（OOM 死循环 / 未来时间污染 / 缓存穿透 / 超大数据 / HTML 性能炸弹）自己写代码想不到。对抗式审查：让 AI 站**"恶意用户怎么搞崩"**角度，全链路找这类 bug。

卡兹克实例：AIHOT 的 OOM 死循环（worker 处理 50MB HTML 爆内存→杀→重试→再爆）+ 未来时间污染（文章时间戳是明天→排信息流最前→推 RSS/飞书）——都是"正常写代码想不到，攻击者视角才看到"。

### 1.2 codesop 现状
- `verification-before-completion`（v9 patch）：deliver-gate 风险分级（low 自动 / high 人审）+ 完成条件外部锚点 + diff 守护
- **缺**：high-risk deliver 前的"对抗式审查"（攻击者视角扫边界 bug）
- 现成可复用：**动态工作流**（Claude Code，adversarial verify 模式——N 个 skeptic 攻击者投票）+ **codex:adversarial-review**（跨模型挑战设计假设）

### 1.3 定位
不加新 skill，**强化 verification deliver-gate**：
- high-risk deliver 前，**多 agent 攻击者视角全链路扫**（复用动态工作流 adversarial verify）
- **跨模型第二意见**（codex:adversarial-review）
- 找到的 bug 进证据包，**blocking 不清零不交付**

---

## 2. 变更点（R 列表，dogfood §6 三件）

| R | 变更 | 完成条件（机器可验证）| 边界 | 风险 | 落点 |
|---|---|---|---|---|---|
| **R1** | verification deliver-gate 加对抗式审查子步骤（high-risk） | `verification-before-completion-SKILL.md` 含"high-risk deliver 前对抗式审查"（多 agent 攻击者视角全链路扫边界 bug，**含但不限于**：OOM 死循环 / 未来时间污染 / 缓存穿透 / 超大数据 / 性能炸弹 / **资源泄漏**（文件句柄·连接池·内存渐进）/ **并发竞态**（race·死锁）/ **权限越界**（鉴权绕过）/ **注入**（SQL·命令·XSS）/ **日志泄敏** / **降级熔断失效**）；行为测试触发 | **high-risk 才走**（low 自动过不变）；不阻塞 low | medium | T1（verification patch）|
| **R2** | 对抗式审查复用动态工作流 + codex:adversarial-review | SKILL/verification 引用：① 动态工作流（ultracode）多 agent 攻击者扫（adversarial verify pattern，**AI 自动走**）② codex:adversarial-review 跨模型第二意见（**用户手动**——路由卡约束，AI 不可自动调用）| **复用现有**（动态工作流 / codex:adversarial-review），**不另造**攻击者 agent；AI 自动部分 = 动态工作流多 agent，codex:adversarial-review 由用户手动触发 | low | T1/T2 |
| **R3** | 找到的 bug 进证据包 blocking | 对抗式审查发现的 bug 进 evidence-pack (a) 判定为 blocking（没满足），不清零不交付；边界类降 advisory 给人定夺 | 衔接 v9 证据包 + AI 自证循环 | low | T1 |
| **R4** | 行为测试 | `tests/` 含对抗式审查触发测试（high-risk deliver 前走 + 攻击者视角文本 + 多 agent/codex 引用）| golden-content 下限，dispatch 实测降级 dogfood | low | T3 |

---

## 3. 边界（何时走对抗式审查）
- **high-risk deliver**（改 public 行为 / 跨模块 / 外部接口 / 数据完整性）→ 走对抗式审查
- **low-risk**（纯重构 / simple / 无 public 影响）→ 自动过，不走
- 风险分级复用 v9 deliver-gate（spec 风险分级 low/high），对齐——high 走对抗式 + 人审，low 自动过
- **low 判定可疑兜底**：deliver 涉及**鉴权 / 外部输入 / 并发 / 资源 / 注入面**，即使 spec 声明 low 也**升级 high** 走对抗式（防 spec 作者误判 low 放过边界 bug——人审攻击者视角 dig_deeper 点）
- **双机制都不可用降级**：动态工作流（ultracode 未开）+ codex:adversarial-review（用户未触发）都没走时，**至少单 agent 攻击者视角扫**（不静默跳过，advisory 给人定夺——延续 v9"不静默丢锚点"）

---

## 4. 明确不做
- **不加新 skill**（强化 verification deliver-gate）
- **不强制每个 deliver 走**（high-risk 才，low 自动过）
- **不上 hook**（skill 文本约束，延续 v9）
- **不另造攻击者 agent**（复用动态工作流 adversarial verify + codex:adversarial-review）
- **不替代 verification Gate Function**（Gate Function 测试/lint 照跑，对抗式审查是其后的边界 bug 扫）

---

## 5. spec 自验收（dogfood §6）
- ☑ 每条 R 自带完成条件（§2，grep/行为测试可验证）
- ☑ 每条 R 自带边界（§2 边界列 + §3）
- ☑ 每条 R 自带风险分级（§2，medium/low）
- ☑ 完成条件引用外部锚点（多 agent/codex 信号 + 行为测试），非 AI 自述
- ☐ codex 跨模型审（Cloudflare 封锁 + Hiddify 代理坏，不可用 → R9 降级人审，不阻塞）
- ☑ 人 spec-gate（过：rubric 五项 + 攻击者视角 dig_deeper，补 2 漏洞）

---

## 6. 与 v9 的关系
v9 deliver-gate 风险分级（low 自动 / high 人审）基础上，**high-risk 加对抗式审查**（交付前攻击者视角扫边界 bug）。simple/moderate/low 跳过；high-risk complex 走。spec-gate 后 /goal 实施（verification patch 改 + tests）。

**攻击者视角**与 v9"外部锚点"互补：v9 防 AI 自吹"完成了"（认测试/lint），对抗式审查防 AI"没想到边界 bug"（攻击者视角补盲）。

## 7. 前置：superpowers 版本
基于 superpowers **6.0.3**（obra/superpowers 最新 release，codesop 已适配）。**6.1 未发布**（obra/superpowers releases 最新 6.0.3），无需 6.1 适配。若 6.1 发布，patches 重 base 时本 spec 改动保留。
