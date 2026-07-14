#!/bin/bash
# v5 Phase 2 R3 审计写入接口测试（spec §5 R3）
# write_audit：严格校验（任一非法拒写+非零+stderr）+ 合法调 judge_profile 算 floor + violation + 字段契约。
# 注意：H0 容错是 judge_profile 的独立行为（R1 测），write_audit 严格校验在先不触发 H0。
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$(dirname "$0")/test_helpers.sh"

command -v jq >/dev/null 2>&1 || { echo "SKIP: jq unavailable"; exit 0; }

WORKROOT="$(mktemp -d)"
trap 'rm -rf "$WORKROOT"' EXIT
export HOME="$WORKROOT/home"
export XDG_STATE_HOME="$WORKROOT/state"
mkdir -p "$HOME"

# shellcheck disable=SC1091
source "$ROOT_DIR/lib/profile.sh"

audit="$XDG_STATE_HOME/codesop/audit.jsonl"

# --- 合法写入：minimal fixture（floor=minimal, declared=minimal → violation:false, approver=null）---
write_audit change low low local "" true minimal "diff+test passed" "" || fail "write_audit minimal 应成功"
[ -f "$audit" ] || fail "audit.jsonl 未创建"
line=$(tail -1 "$audit")
assert_contains "$line" '"declared_profile":"minimal"'
assert_contains "$line" '"floor":"minimal"'
assert_contains "$line" '"floor_reason":"low_local_reversible"'
assert_contains "$line" '"violation":false'
assert_contains "$line" '"approver":null'
# ts ISO8601
ts=$(echo "$line" | jq -r .ts)
echo "$ts" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$' || fail "ts 非 ISO8601: $ts"
# override 空数组
assert_contains "$line" '"override":[]'

# --- declared<floor → violation:true（override=auth→floor=governed，declared=minimal）---
write_audit change low low local "auth" true minimal "tried minimal but override" "" || fail "write_audit violation 应成功"
line=$(tail -1 "$audit")
assert_contains "$line" '"floor":"governed"'
assert_contains "$line" '"declared_profile":"minimal"'
assert_contains "$line" '"violation":true'

# --- governed 合法批准（approver 非空，violation:false）---
write_audit change low low local "auth" true governed "auth change + approval" "user_claw" || fail "write_audit governed 应成功"
line=$(tail -1 "$audit")
assert_contains "$line" '"approver":"user_claw"'
assert_contains "$line" '"violation":false'

# --- 前 6 参非法 → 拒写 + 非零 + 不追加行 ---
before=$(wc -l < "$audit" | tr -d ' ')
if write_audit badintent low low local "" true minimal "x" "" 2>/dev/null; then fail "非法 intent 应拒写"; fi
if write_audit change badrisk low low local "" true minimal "x" "" 2>/dev/null; then fail "非法 risk 应拒写"; fi
if write_audit change low badamb low local "" true minimal "x" "" 2>/dev/null; then fail "非法 ambiguity 应拒写"; fi
if write_audit change low low badblast "" true minimal "x" "" 2>/dev/null; then fail "非法 blast 应拒写"; fi
if write_audit change low low local "badmember" true minimal "x" "" 2>/dev/null; then fail "非法 override 应拒写"; fi
if write_audit change low low local "" maybe minimal "x" "" 2>/dev/null; then fail "非法 reversible 应拒写"; fi
after=$(wc -l < "$audit" | tr -d ' ')
[ "$before" = "$after" ] || fail "非法写入不应追加行（before=$before after=$after）"

# --- declared_profile 非法 → 拒写 ---
if write_audit change low low local "" true bogus "x" "" 2>/dev/null; then fail "非法 declared_profile 应拒写"; fi
# --- evidence 空 → 拒写 ---
if write_audit change low low local "" true minimal "" "" 2>/dev/null; then fail "空 evidence 应拒写"; fi

# --- 字段契约：每行 13 字段 + 必填字段非空（floor_reason/evidence）---
while IFS= read -r l; do
  nf=$(echo "$l" | jq '. | length')
  [ "$nf" = "13" ] || fail "审计行字段数非 13（$nf）"
  fr=$(echo "$l" | jq -r .floor_reason); [ -n "$fr" ] && [ "$fr" != "null" ] || fail "floor_reason 必须非空"
  ev=$(echo "$l" | jq -r .evidence);      [ -n "$ev" ] && [ "$ev" != "null" ] || fail "evidence 必须非空"
done < "$audit"

# --- profile_rank 排序比较（minimal<standard<governed）---
[ "$(profile_rank minimal)" -lt "$(profile_rank standard)" ] || fail "rank minimal<standard"
[ "$(profile_rank standard)" -lt "$(profile_rank governed)" ] || fail "rank standard<governed"

# --- override JSON 数组（合法多成员，canonical 不影响存储）---
write_audit change low low local "auth,migration" true governed "multi override" "u" || fail "write_audit multi override"
line=$(tail -1 "$audit")
ov=$(echo "$line" | jq -c '.override')
assert_contains "$ov" '"auth"'
assert_contains "$ov" '"migration"'

echo "  PASS audit-structure（write_audit 严格校验 + floor/violation + 13 字段契约 + profile_rank + override 数组）"
