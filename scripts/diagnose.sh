#!/bin/bash

diagnose_project() {
  local signals="$1"
  local branch=""
  local uncommitted="0"
  local has_prd=""
  local has_plan=""
  local stage="unknown"
  local confidence="low"
  local health_issues=""
  local result=""

  branch="$(printf '%s\n' "$signals" | awk -F= '/^GIT_BRANCH=/{print $2; exit}')"
  uncommitted="$(printf '%s\n' "$signals" | awk -F= '/^GIT_UNCOMMITTED=/{print $2; exit}')"
  has_prd="$(printf '%s\n' "$signals" | awk -F= '/^CONFIG_PRD_MD=/{print $2; exit}')"
  has_plan="$(printf '%s\n' "$signals" | awk -F= '/^CONFIG_PLAN_MD=/{print $2; exit}')"

  if [[ "$branch" == feature/* ]]; then
    stage="feature"
    confidence="medium"
  elif [[ "$branch" == fix/* ]] || [[ "$branch" == bugfix/* ]]; then
    stage="debug"
    confidence="medium"
  elif [[ "$branch" == refactor/* ]]; then
    stage="refactor"
    confidence="medium"
  elif [[ "$branch" == "main" ]] || [[ "$branch" == "master" ]]; then
    if [ "${uncommitted:-0}" -gt 0 ]; then
      stage="feature"
      confidence="low"
    fi
  fi

  if [ "$has_prd" = "false" ]; then
    health_issues+="MISSING_PRD,"
  fi

  if [ "$has_plan" = "false" ] && [ "$stage" = "feature" ]; then
    health_issues+="MISSING_PLAN,"
  fi

  result+="CURRENT_STAGE=$stage"$'\n'
  result+="STAGE_CONFIDENCE=$confidence"$'\n'

  if [ -n "$health_issues" ]; then
    result+="HEALTH_ISSUES=${health_issues%,}"$'\n'
  fi

  printf '%s' "$result"
}
