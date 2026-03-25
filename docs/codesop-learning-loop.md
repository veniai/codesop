# codesop Learning Loop

**Purpose:** 用一个文件承载 `真实使用反馈 -> 经验沉淀 -> 迭代候选` 的半自动闭环。  
**Current Mode:** 半自动  
**Future Mode:** 尽量自动汇总，但仍保留人工确认

---

## 1. 使用记录

> 每次真实使用后，只需要追加一条。先记事实，不急着下结论。

### Entry Template

```md
### <YYYY-MM-DD> | Host: <Claude Code / Codex / OpenCode> | Scenario: <继续项目 / 规划 / bug / review / 发布 / 其他>
- Trigger: good / weak / missed / over-triggered
- Outcome: good / acceptable / poor
- What worked:
  - ...
- What failed:
  - ...
- Dependency / host issue:
  - none / superpowers / gstack / path / trigger / output / other
- Expected behavior:
  - ...
```

### Entries

<!-- Append new entries below -->

---

## 2. 模式总结

> 不是每次都改。只有当相同问题出现 >= 2 次，或者你明确认为它是系统性问题时，再把它提炼到这里。

### Trigger Patterns

- [待补充]

### Host Compatibility Patterns

- [待补充]

### Dependency Drift Patterns

- [待补充]

### Routing / Output Patterns

- [待补充]

---

## 3. 迭代候选

> 这里放“值得改”的点，但先不自动改 `SKILL.md` / `codesop`。等你确认后再执行。

| Date | Candidate Change | Source Entry | Priority | Status |
|------|------------------|--------------|----------|--------|
| <YYYY-MM-DD> | [例如：增强 Codex 下的 skill 路由提示] | [link or date] | high / medium / low | proposed |

---

## 4. 使用规则

- 先记录，再总结，不要一上来就改规则。
- 同类问题至少出现 2 次，再考虑提炼为模式。
- 进入“迭代候选”的项目，默认需要人工确认后再改系统。
- 如果问题属于宿主适配或依赖漂移，优先关联：
  - `docs/plans/2026-03-24-codesop-host-compatibility-matrix.md`
  - `docs/plans/2026-03-24-codesop-dependency-governance-design.md`

---

## 5. 当前结论

- 现在先坚持一个文件，降低维护成本。
- 先用真实使用把高频问题打出来。
- 等记录足够多，再决定是否拆分成独立经验库或自动汇总流程。
