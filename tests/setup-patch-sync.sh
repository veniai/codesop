#!/bin/bash
#
# v9 setup patch sync 完整性测试（task-7-brief + spec §8 evidence-pack schema sibling）
#
# 验证 setup --host claude 把全部 v9 patch 同步到 runtime superpowers 插件目录：
#   - 4 个 SKILL.md patch（writing-plans / finishing-a-development-branch / brainstorming / verification）
#   - _evidence-pack-schema.md sibling 同步到每个被 patch 的 skill 目录（修 v8 sub-file 盲区）
#   - idempotent：第二次 setup 不重复 copy（diff -q 跳过）
#
# 用 fake superpowers plugin tree（不依赖真实插件是否安装）：
#   $HOME/.claude/plugins/cache/<market>/superpowers/<version>/skills/<skill>/SKILL.md
# 真跑 setup，断言 runtime 文件与 patch 源一致。
#

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SETUP="$ROOT_DIR/setup"
PATCHES="$ROOT_DIR/patches/superpowers"

source "$(dirname "$0")/test_helpers.sh"

# 依赖 find_superpowers_plugin_path 解析 $HOME/.claude/plugins/cache/*/<ver>
command -v git >/dev/null 2>&1 || { echo "SKIP: git unavailable"; exit 0; }

# ---------------------------------------------------------------------------
# 构造 fake superpowers 插件树
# ---------------------------------------------------------------------------
WORKROOT="$(mktemp -d)"
trap 'rm -rf "$WORKROOT"' EXIT

HOME_FAKE="$WORKROOT/home"
MARKET="claude-plugins-official"
SPVER="6.1.1"   # 与 config/dependencies.sh superpowers min_version 同口径
PLUGIN_ROOT="$HOME_FAKE/.claude/plugins/cache/$MARKET/superpowers/$SPVER"
SKILLS_ROOT="$PLUGIN_ROOT/skills"

# dependencies.sh patch_compat 走 major.minor 匹配；用与 manifest 一致的 6.1.x
mkdir -p "$SKILLS_ROOT/writing-plans" \
         "$SKILLS_ROOT/finishing-a-development-branch" \
         "$SKILLS_ROOT/brainstorming" \
         "$SKILLS_ROOT/verification-before-completion"

# 每个 SKILL.md 预置"陈旧"内容（setup 检测到 diff 才会 copy）
for skill in writing-plans finishing-a-development-branch brainstorming verification-before-completion; do
  printf '# STALE %s\nname: %s\n' "$skill" "$skill" > "$SKILLS_ROOT/$skill/SKILL.md"
done

# 假装插件已注册到 installed_plugins.json（find_superpowers_plugin_path 不读它，但保证真实路径解析）
mkdir -p "$HOME_FAKE/.claude/plugins/cache/$MARKET/superpowers"

# ---------------------------------------------------------------------------
# 跑 setup --host claude（在隔离 HOME 下）
# ---------------------------------------------------------------------------
run_output="$(HOME="$HOME_FAKE" bash "$SETUP" --host claude 2>&1)" || {
  echo "$run_output" >&2
  fail "setup --host claude failed in fake HOME"
}

# ---------------------------------------------------------------------------
# 断言 1: find_superpowers_plugin_path 能解析到 fake 插件
# ---------------------------------------------------------------------------
resolved="$(HOME="$HOME_FAKE" bash -c "source '$ROOT_DIR/lib/detection.sh' && find_superpowers_plugin_path || true")"
[ -n "$resolved" ] || fail "find_superpowers_plugin_path returned empty in fake HOME"
[ "$resolved" = "$PLUGIN_ROOT" ] || fail "resolved plugin path mismatch: got '$resolved', expected '$PLUGIN_ROOT'"

# ---------------------------------------------------------------------------
# 断言 2: 4 个 SKILL.md 全部从 patch 同步到 runtime（与源一致）
# ---------------------------------------------------------------------------
declare -a PATCH_SKILL_PAIRS=(
  "writing-plans-SKILL.md:writing-plans"
  "finishing-a-development-branch-SKILL.md:finishing-a-development-branch"
  "brainstorming-SKILL.md:brainstorming"
  "verification-before-completion-SKILL.md:verification-before-completion"
)

for pair in "${PATCH_SKILL_PAIRS[@]}"; do
  patch_src="${pair%%:*}"
  skill_dir="${pair##*:}"
  runtime="$SKILLS_ROOT/$skill_dir/SKILL.md"
  [ -f "$runtime" ] || fail "runtime SKILL.md missing for $skill_dir"
  diff -q "$PATCHES/$patch_src" "$runtime" >/dev/null 2>&1 \
    || fail "runtime $skill_dir/SKILL.md differs from patch source ($patch_src)"
done

echo "  PASS 4 SKILL.md patches synced to runtime (writing-plans / finishing / brainstorming / verification)"

# ---------------------------------------------------------------------------
# 断言 3: _evidence-pack-schema.md sibling 同步到 3 个被 patch 的 skill 目录
#         （schema 引用是相对路径 sibling，setup 必须内联——修 v8 sub-file 盲区）
# ---------------------------------------------------------------------------
SCHEMA_SRC="$PATCHES/_evidence-pack-schema.md"
for skill_dir in writing-plans brainstorming verification-before-completion; do
  schema_dst="$SKILLS_ROOT/$skill_dir/_evidence-pack-schema.md"
  [ -f "$schema_dst" ] || fail "schema sibling missing in runtime $skill_dir/"
  diff -q "$SCHEMA_SRC" "$schema_dst" >/dev/null 2>&1 \
    || fail "runtime $skill_dir/_evidence-pack-schema.md differs from patch source"
done

# finishing-a-development-branch 不引用 schema，不应有 sibling（负面断言防过度 copy）
[ ! -f "$SKILLS_ROOT/finishing-a-development-branch/_evidence-pack-schema.md" ] \
  || fail "schema sibling should NOT exist in finishing-a-development-branch (no reference)"

echo "  PASS _evidence-pack-schema.md sibling synced to 3 referencing skills (v8 sub-file blind spot closed)"

# ---------------------------------------------------------------------------
# 断言 4: setup 输出报 patch 应用计数（4 SKILL + 3 schema）
# ---------------------------------------------------------------------------
printf '%s' "$run_output" | grep -Fq "Skill patches applied" \
  || fail "setup output missing 'Skill patches applied' line"
# 计数行格式: "(N SKILL.md + M schema sibling)" —— 4 + 3
printf '%s' "$run_output" | grep -Eq "4 SKILL\.md \+ 3 schema sibling" \
  || fail "setup patch count line mismatch (expected '4 SKILL.md + 3 schema sibling')"

echo "  PASS setup reports patch count (4 SKILL.md + 3 schema sibling)"

# ---------------------------------------------------------------------------
# 断言 5: idempotent —— 第二次跑不再 copy（diff -q 全跳过，计数行不出现）
# ---------------------------------------------------------------------------
run2="$(HOME="$HOME_FAKE" bash "$SETUP" --host claude 2>&1)" || {
  echo "$run2" >&2
  fail "second setup --host claude failed (idempotency)"
}

# 第二次应无 patch 应用行（全 diff 相等 → patched=0, schema_copied=0）
if printf '%s' "$run2" | grep -Fq "Skill patches applied"; then
  fail "idempotency broken: second setup re-applied patches (should be no-op when files match)"
fi

# runtime 文件仍与 patch 源一致（未被破坏）
for pair in "${PATCH_SKILL_PAIRS[@]}"; do
  patch_src="${pair%%:*}"
  skill_dir="${pair##*:}"
  runtime="$SKILLS_ROOT/$skill_dir/SKILL.md"
  diff -q "$PATCHES/$patch_src" "$runtime" >/dev/null 2>&1 \
    || fail "idempotency: runtime $skill_dir/SKILL.md drifted after second setup"
done
for skill_dir in writing-plans brainstorming verification-before-completion; do
  schema_dst="$SKILLS_ROOT/$skill_dir/_evidence-pack-schema.md"
  diff -q "$SCHEMA_SRC" "$schema_dst" >/dev/null 2>&1 \
    || fail "idempotency: runtime $skill_dir/_evidence-pack-schema.md drifted after second setup"
done

echo "  PASS idempotent (second setup is no-op, runtime files unchanged)"

echo ""
echo "All setup patch sync tests passed."
