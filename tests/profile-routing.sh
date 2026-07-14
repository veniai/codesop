#!/bin/bash
# v5 Phase 2 R1 profile 判定测试（spec §4 判定表 / §5 R1）
# judge_profile：H0 合法性前置短路 → H1 → H2 → H3 → default；floor_reason 唯一性。
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$(dirname "$0")/test_helpers.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/lib/profile.sh"

PASS=0
check() {
  local expected="$1"; shift
  local got
  got=$(judge_profile "$@")
  assert_contains "$got" "$expected"
  PASS=$((PASS+1))
}

# --- H3 minimal（四要件齐全）---
check "PROFILE=minimal FLOOR_REASON=low_local_reversible" change low low local "" true
check "PROFILE=minimal FLOOR_REASON=low_local_reversible" explore low low local "" true
check "PROFILE=minimal FLOOR_REASON=low_local_reversible" debug   low low local "" true

# --- review/ship 不进 minimal（落 standard）---
check "PROFILE=standard FLOOR_REASON=default_standard" review low low local "" true
check "PROFILE=standard FLOOR_REASON=default_standard" ship   low low local "" true

# --- H3 reversible=false → 不 minimal → standard ---
check "PROFILE=standard FLOOR_REASON=default_standard" change low low local "" false

# --- H1 override（canonical order：auth migration deploy public_api destructive）---
check "PROFILE=governed FLOOR_REASON=override:auth"      change low low local "auth" true
check "PROFILE=governed FLOOR_REASON=override:auth"      change low low local "migration,auth" true   # canonical→auth
check "PROFILE=governed FLOOR_REASON=override:migration" change low low local "migration" true
check "PROFILE=governed FLOOR_REASON=override:deploy" change low low local "deploy,public_api" true   # canonical→deploy（在 public_api 前）

# --- H1 risk=high / blast=external ---
check "PROFILE=governed FLOOR_REASON=risk:high"      change high low local "" true
check "PROFILE=governed FLOOR_REASON=blast:external" change low low external "" true

# --- H2 ---
check "PROFILE=standard FLOOR_REASON=ambiguity:high"     change low high local "" true
check "PROFILE=standard FLOOR_REASON=blast:cross-module" change low low cross-module "" true

# --- default standard（risk=medium）---
check "PROFILE=standard FLOOR_REASON=default_standard" change medium low local "" true

# --- H0 合法性前置短路（按字段固定顺序 intent→risk→ambiguity→blast→override→reversible）---
check "PROFILE=governed FLOOR_REASON=input_incomplete:intent"     badintent low low local "" true
check "PROFILE=governed FLOOR_REASON=input_incomplete:risk"       change badrisk low local "" true
check "PROFILE=governed FLOOR_REASON=input_incomplete:ambiguity"  change low badamb local "" true
check "PROFILE=governed FLOOR_REASON=input_incomplete:blast"      change low low badblast "" true
check "PROFILE=governed FLOOR_REASON=input_incomplete:override"   change low low local "badmember" true
check "PROFILE=governed FLOOR_REASON=input_incomplete:reversible" change low low local "" maybe

# --- H0 短路压 H1：risk=high 但 intent 非法 → input_incomplete:intent（非 risk:high）---
check "PROFILE=governed FLOOR_REASON=input_incomplete:intent" badintent high low local "" true

# --- profile_rank ---
[ "$(profile_rank minimal)" = "0" ] || fail "profile_rank minimal"
[ "$(profile_rank standard)" = "1" ] || fail "profile_rank standard"
[ "$(profile_rank governed)" = "2" ] || fail "profile_rank governed"
PASS=$((PASS+3))

# --- codex 复核 P2：override 畸形集合拒绝（auth, / ,auth / auth,,b 空成员）---
check "PROFILE=governed FLOOR_REASON=input_incomplete:override" change low low local "auth," true
check "PROFILE=governed FLOOR_REASON=input_incomplete:override" change low low local ",auth" true
check "PROFILE=governed FLOOR_REASON=input_incomplete:override" change low low local "auth,,migration" true

# --- codex 复核 P2：少参 set -u 安全（judge_profile 缺 $6 → H0 input_incomplete:reversible，不崩溃）---
_got=$(judge_profile change low low local "" 2>/dev/null || true)
assert_contains "$_got" "input_incomplete:reversible"
PASS=$((PASS+1))

# --- 一致性：router card 含三档名 + floor 不可降声明（结构存在校验，非规则细节一致）---
ROUTER="$ROOT_DIR/config/codesop-router.md"
rc=$(cat "$ROUTER")
assert_contains "$rc" "minimal"
assert_contains "$rc" "standard"
assert_contains "$rc" "governed"
assert_contains "$rc" "floor 不可降"
PASS=$((PASS+4))

echo "  PASS profile-routing（$PASS 项：H0-H3 + floor_reason 唯一 + profile_rank + router 结构一致性）"
