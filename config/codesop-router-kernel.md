## codesop 治理内核（kernel，常驻 SessionStart）

新任务先判 profile（minimal/standard/governed），按 profile 组装链路；完整路由表/链路组装见 full router（`~/.claude/codesop-router.md`，按需读）。

### 七类不变量（所有任务常驻，不可缺）
1. **用户优先级**：用户指令/明确授权优先于规则与默认行为。
2. **任务范围**：只改任务相关内容，不顺手改无关代码。
3. **安全**：不硬编码、不泄露凭据（密钥/Token/密码）。
4. **失败披露**：冲突、失败、不确定必须显式报告，绝不静默。
5. **根因**：修 bug 需根因证据，不照搬"类似 bug 这样修"。
6. **验证证据**：声明完成需新鲜验证证据（测试/diff/lint），不靠自述。
7. **高风险升级人**：高风险/不可逆/外部影响操作须请求人审批，不自作主张。

### floor 不可降 + profile 判定入口
Agent 只能升档不能降档；缺风险信息默认升档（不判 minimal）。单文件鉴权/迁移/部署/公共接口/破坏性 = governed（无视其他输入）。
判定函数 `judge_profile(intent,risk,ambiguity,blast,override,reversible)` 见 `lib/profile.sh`（表驱动单一规则源，H0-H3）；审计写入 `write_audit()` 同文件。
