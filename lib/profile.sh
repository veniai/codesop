#!/bin/bash
# lib/profile.sh — v5 Phase 2 profile 判定 + 审计写入（spec §4 判定表 / §5 R1 / R3）
#
# 设计（spec r6）：
# - judge_profile 是容错 oracle（H0：invalid→governed+input_incomplete），R1 独立测；
#   运行时 AI 不直接调，经 write_audit 间接调算 floor。
# - write_audit 是严格写入接口（全参校验，任一非法拒写+非零+stderr），合法才调 judge_profile。
# - profile_rank: minimal(0) < standard(1) < governed(2)。
# - floor 是 best-effort，无机械硬拦截；降档靠 write_audit 的 violation 字段 + 人审回溯。

# 合法枚举（单一规则源，judge_profile/write_audit 共用）
_PROFILE_INTENTS="explore change debug review ship"
_PROFILE_RISKS="low medium high"
_PROFILE_AMBIG="low high"
_PROFILE_BLAST="local cross-module external"
_PROFILE_OVERRIDES="auth migration deploy public_api destructive"
_PROFILE_PROFILES="minimal standard governed"

_profile_contains() {
  # $1 = space-separated set, $2 = value; return 0 if value in set
  local set_="$1" val="$2"
  [[ " $set_ " == *" $val "* ]]
}

_profile_valid_override_members() {
  # $1 = comma-separated override; 全部成员须合法；空串合法（∅）
  local o="$1"
  [ -z "$o" ] && return 0
  local m
  local IFS=','
  for m in $o; do
    _profile_contains "$_PROFILE_OVERRIDES" "$m" || return 1
  done
  return 0
}

profile_rank() {
  case "$1" in
    minimal)  echo 0 ;;
    standard) echo 1 ;;
    governed) echo 2 ;;
    *)        echo 2 ;;   # 非法视为 governed（最保守）
  esac
}

# judge_profile(intent, risk, ambiguity, blast, override, reversible)
# stdout: "PROFILE=<p> FLOOR_REASON=<r>"
# H0 合法性前置短路 → H1 override/risk/blast → H2 ambiguity/cross-module → H3 minimal 四要件 → default standard
judge_profile() {
  local intent="$1" risk="$2" ambiguity="$3" blast="$4" override="$5" reversible="$6"

  # H0：合法性校验（前置短路，按 intent→risk→ambiguity→blast→override→reversible 固定顺序取首非法）
  _profile_contains "$_PROFILE_INTENTS" "$intent"       || { echo "PROFILE=governed FLOOR_REASON=input_incomplete:intent"; return 0; }
  _profile_contains "$_PROFILE_RISKS"   "$risk"         || { echo "PROFILE=governed FLOOR_REASON=input_incomplete:risk"; return 0; }
  _profile_contains "$_PROFILE_AMBIG"   "$ambiguity"    || { echo "PROFILE=governed FLOOR_REASON=input_incomplete:ambiguity"; return 0; }
  _profile_contains "$_PROFILE_BLAST"   "$blast"        || { echo "PROFILE=governed FLOOR_REASON=input_incomplete:blast"; return 0; }
  _profile_valid_override_members       "$override"     || { echo "PROFILE=governed FLOOR_REASON=input_incomplete:override"; return 0; }
  { [[ "$reversible" == "true" || "$reversible" == "false" ]]; } || { echo "PROFILE=governed FLOOR_REASON=input_incomplete:reversible"; return 0; }

  # H1：override≠∅ ∨ risk=high ∨ blast=external → governed
  if [ -n "$override" ]; then
    local first=""
    local m
    for m in auth migration deploy public_api destructive; do   # canonical order
      if _profile_contains "${override//,/ }" "$m"; then first="$m"; break; fi
    done
    echo "PROFILE=governed FLOOR_REASON=override:$first"; return 0
  fi
  if [ "$risk" = "high" ]; then
    echo "PROFILE=governed FLOOR_REASON=risk:high"; return 0
  fi
  if [ "$blast" = "external" ]; then
    echo "PROFILE=governed FLOOR_REASON=blast:external"; return 0
  fi

  # H2：ambiguity=high ∨ blast=cross-module → standard
  if [ "$ambiguity" = "high" ]; then
    echo "PROFILE=standard FLOOR_REASON=ambiguity:high"; return 0
  fi
  if [ "$blast" = "cross-module" ]; then
    echo "PROFILE=standard FLOOR_REASON=blast:cross-module"; return 0
  fi

  # H3：minimal 四要件（risk=low ∧ ambiguity=low ∧ blast=local ∧ reversible=true ∧ intent∈{explore,change,debug} ∧ override=∅）
  if [ "$risk" = "low" ] && [ "$ambiguity" = "low" ] && [ "$blast" = "local" ] \
     && [ "$reversible" = "true" ] \
     && { [ "$intent" = "explore" ] || [ "$intent" = "change" ] || [ "$intent" = "debug" ]; }; then
    echo "PROFILE=minimal FLOOR_REASON=low_local_reversible"; return 0
  fi

  # default
  echo "PROFILE=standard FLOOR_REASON=default_standard"; return 0
}

# write_audit(intent, risk, ambiguity, blast, override, reversible, declared_profile, evidence, approver)
# 严格校验全 9 参 → 合法才调 judge_profile 算 floor/floor_reason → 追加一行 audit.jsonl
# 非法：拒写 + 非零退出 + stderr 报字段名。返回 0=写入成功。
write_audit() {
  local intent="$1" risk="$2" ambiguity="$3" blast="$4" override="$5" reversible="$6"
  local declared_profile="$7" evidence="$8" approver="${9:-}"

  _profile_contains "$_PROFILE_INTENTS"  "$intent"          || { echo "write_audit: invalid field: intent" >&2; return 1; }
  _profile_contains "$_PROFILE_RISKS"    "$risk"            || { echo "write_audit: invalid field: risk" >&2; return 1; }
  _profile_contains "$_PROFILE_AMBIG"    "$ambiguity"       || { echo "write_audit: invalid field: ambiguity" >&2; return 1; }
  _profile_contains "$_PROFILE_BLAST"    "$blast"           || { echo "write_audit: invalid field: blast" >&2; return 1; }
  _profile_valid_override_members        "$override"        || { echo "write_audit: invalid field: override" >&2; return 1; }
  { [[ "$reversible" == "true" || "$reversible" == "false" ]]; } || { echo "write_audit: invalid field: reversible" >&2; return 1; }
  _profile_contains "$_PROFILE_PROFILES" "$declared_profile" || { echo "write_audit: invalid field: declared_profile" >&2; return 1; }
  [ -n "$evidence" ]                                         || { echo "write_audit: invalid field: evidence (empty)" >&2; return 1; }
  # approver：空（governed 未批准 / minimal·standard）或非空字符串（批准）—— bash 字符串均合规，无额外类型校验

  local jp floor floor_reason
  jp=$(judge_profile "$intent" "$risk" "$ambiguity" "$blast" "$override" "$reversible")
  floor="${jp#PROFILE=}"               # "minimal FLOOR_REASON=..." → 去前缀
  floor="${floor%% *}"                 # 取首 token = profile
  floor_reason="${jp##*FLOOR_REASON=}"

  local declared_rank floor_rank violation
  declared_rank=$(profile_rank "$declared_profile")
  floor_rank=$(profile_rank "$floor")
  if [ "$declared_rank" -lt "$floor_rank" ]; then
    violation=true
  else
    violation=false
  fi

  local ts
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  local audit_file="${XDG_STATE_HOME:-$HOME/.local/state}/codesop/audit.jsonl"
  mkdir -p "$(dirname "$audit_file")"

  jq -c -n \
    --arg intent "$intent" --arg risk "$risk" --arg ambiguity "$ambiguity" \
    --arg blast "$blast" --arg override "$override" --arg reversible "$reversible" \
    --arg declared_profile "$declared_profile" --arg floor "$floor" \
    --arg floor_reason "$floor_reason" --arg evidence "$evidence" \
    --arg approver "$approver" --arg ts "$ts" --argjson violation "$violation" \
    '{intent:$intent, risk:$risk, ambiguity:$ambiguity, blast:$blast,
      override:($override|split(",")|map(select(.!=""))),
      reversible:$reversible, declared_profile:$declared_profile, floor:$floor,
      floor_reason:$floor_reason, evidence:$evidence,
      approver:(if $approver=="" then null else $approver end),
      ts:$ts, violation:$violation}' \
    >> "$audit_file"
}
