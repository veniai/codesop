#!/bin/bash

discover_skills() {
  local repo_root
  local skills_info=""
  local cache_file="$HOME/.gstack/skills-index-cache.json"
  local gstack_dir="$HOME/.claude/skills/gstack"
  local cache_version="v2"

  repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

  if [ -f "$repo_root/SKILL.md" ]; then
    skills_info+="codesop: $(awk '/^description: \|/{flag=1; next} /^---$/{if(flag){exit}} flag {sub(/^  /, ""); printf "%s ", $0}' "$repo_root/SKILL.md" | sed 's/[[:space:]]*$//')"$'\n'
  fi

  if [ -d "$gstack_dir" ]; then
    mkdir -p "$(dirname "$cache_file")"

    if [ -f "$cache_file" ]; then
      local cache_time
      local dir_time
      cache_time="$(stat -c %Y "$cache_file" 2>/dev/null || echo "0")"
      dir_time="$(stat -c %Y "$gstack_dir" 2>/dev/null || echo "0")"
      if [ "$cache_time" -ge "$dir_time" ] && grep -Fq "__CACHE_VERSION__=$cache_version" "$cache_file" && ! grep -Eq '^[A-Za-z0-9_-]+: \|$' "$cache_file"; then
        skills_info+="$(grep -v '^__CACHE_VERSION__=' "$cache_file")"
        printf '%s' "$skills_info"
        return
      fi
    fi

    local discovered=""
    local skill_dir=""
    for skill_dir in "$gstack_dir"/*/; do
      [ -d "$skill_dir" ] || continue
      local skill_file="$skill_dir/SKILL.md"
      [ -f "$skill_file" ] || continue
      local skill_name
      local description
      skill_name="$(basename "$skill_dir")"
      description="$(
        awk '
          BEGIN { in_frontmatter=0; capture=0 }
          /^---$/ {
            if (in_frontmatter == 0) {
              in_frontmatter=1
              next
            }
            if (in_frontmatter == 1) {
              exit
            }
          }
          in_frontmatter == 1 {
            if ($0 ~ /^description:[[:space:]]*\|[[:space:]]*$/) {
              capture=1
              next
            }
            if ($0 ~ /^description:[[:space:]]*/) {
              sub(/^description:[[:space:]]*/, "", $0)
              gsub(/^"/, "", $0)
              gsub(/"$/, "", $0)
              print
              exit
            }
            if (capture == 1) {
              if ($0 ~ /^[^[:space:]-]/) {
                exit
              }
              line=$0
              sub(/^[[:space:]]+/, "", line)
              if (line != "") {
                print line
              }
            }
          }
        ' "$skill_file" | paste -sd ' ' -
      )"
      if [ -n "$description" ]; then
        discovered+="$skill_name: $description"$'\n'
      fi
    done
    printf '%s\n%s' "__CACHE_VERSION__=$cache_version" "$discovered" >"$cache_file"
    skills_info+="$discovered"
  fi

  printf '%s' "$skills_info"
}

recommend_skills() {
  local diagnosis="$1"
  local skills_info
  local stage
  local confidence
  local health_issues
  local context

  skills_info="$(discover_skills)"
  stage="$(printf '%s\n' "$diagnosis" | awk -F= '/^CURRENT_STAGE=/{print $2; exit}')"
  confidence="$(printf '%s\n' "$diagnosis" | awk -F= '/^STAGE_CONFIDENCE=/{print $2; exit}')"
  health_issues="$(printf '%s\n' "$diagnosis" | awk -F= '/^HEALTH_ISSUES=/{print $2; exit}')"

  context="当前阶段: $stage"$'\n'"置信度: $confidence"
  if [ -n "$health_issues" ]; then
    context+=$'\n'"健康问题: $health_issues"
  fi

  printf '%s\n' "## 技能推荐"
  printf '\n%s\n' "根据项目诊断结果，推荐以下技能（最多 5 个）："
  printf '\n%s\n' "**诊断结果**："
  printf '%s\n' "$context"
  printf '\n%s\n' "**可用技能**："
  printf '%s\n' "$skills_info"
  printf '\n%s\n' "**推荐规则**："
  printf '%s\n' "1. 流程技能（决定怎么去）优先于实现技能（指导怎么做）"
  printf '%s\n' "2. 推荐 3-5 个最相关的技能"
  printf '%s\n' "3. 每个推荐需要说明原因和置信度"
}
