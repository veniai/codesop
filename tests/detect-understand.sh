#!/bin/bash
#
# check_understand_usability 7 状态断言（spec §1.5 + §5 验收 G7/G8/G9/G10/G12）
#
# 真跑 mock 场景：每个 case 自建临时 git 仓库 + .understand-anything/ 文件，
# source detection.sh 后断言 UA_STATE 输出。不依赖 codesop 自身仓库状态。
#
# Acceptance 映射：
#   G6  —— bash -n lib/detection.sh 通过
#   G7  —— 7 状态各 case 实测正确
#   G8  —— config 字符串 {"autoUpdate":"true"} → fresh_degraded（非 fresh_on）
#   G9  —— worktree 重定向读主 repo root 图谱
#   G10 —— 子目录运行读仓库根图谱
#   G12 —— corrupt（graph 损坏 / meta 损坏 / meta 缺 gitCommitHash）识别
#

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$(dirname "$0")/test_helpers.sh"

# 前置依赖：node 用于 JSON 解析
command -v node >/dev/null 2>&1 || { echo "SKIP: node unavailable"; exit 0; }
command -v git  >/dev/null 2>&1 || { echo "SKIP: git unavailable";  exit 0; }

# ---------------------------------------------------------------------------
# G6 回归：bash -n 语法检查
# ---------------------------------------------------------------------------
bash -n "$ROOT_DIR/lib/detection.sh" || fail "G6: bash -n lib/detection.sh failed"

# ---------------------------------------------------------------------------
# 辅助：临时工作区
# ---------------------------------------------------------------------------
WORKROOT="$(mktemp -d)"
trap 'rm -rf "$WORKROOT"' EXIT

# 在 $1 目录建一个 git 仓库（含 1 commit），并 echo HEAD hash
make_git_repo() {
  local dir="$1"
  mkdir -p "$dir"
  git -C "$dir" init -q
  git -C "$dir" config user.email  test@example.com
  git -C "$dir" config user.name   "Test"
  printf 'hello\n' > "$dir/file.txt"
  git -C "$dir" add file.txt
  git -C "$dir" commit -q -m "init"
  git -C "$dir" rev-parse HEAD
}

# 在 $1 仓库做第二个 commit 并 echo 新 HEAD
advance_repo() {
  local dir="$1"
  printf 'change\n' >> "$dir/file.txt"
  git -C "$dir" add file.txt
  git -C "$dir" commit -q -m "second"
  git -C "$dir" rev-parse HEAD
}

# 写 .understand-anything/ 文件
# usage: write_ua <repo_root> <graph|meta|config|fp> <content-or-"ABSENT">
write_ua() {
  local root="$1" kind="$2" content="$3"
  local uadir="$root/.understand-anything"
  mkdir -p "$uadir"
  case "$kind" in
    graph)  local f="knowledge-graph.json" ;;
    meta)   local f="meta.json" ;;
    config) local f="config.json" ;;
    fp)     local f="fingerprints.json" ;;
    *) fail "write_ua: unknown kind $kind" ;;
  esac
  if [ "$content" != "ABSENT" ]; then
    printf '%s\n' "$content" > "$uadir/$f"
  fi
}

# 在指定 cwd 下跑 check_understand_usability 并 echo 结果（剥掉可能的 stderr）
run_check() {
  local cwd="$1"
  (
    cd "$cwd"
    # 重新 source 一次确保独立
    # shellcheck disable=SC1090
    source "$ROOT_DIR/lib/detection.sh"
    check_understand_usability 2>/dev/null
  )
}

assert_state() {
  local actual="$1" expected="$2" label="$3"
  [ "$actual" = "$expected" ] || fail "$label: expected UA_STATE=$expected, got '$actual'"
}

# ===========================================================================
# G7 / G12: 7 状态 + corrupt 子类
# ===========================================================================

# --- absent：无 .understand-anything ---
REPO="$WORKROOT/absent"; HEAD=$(make_git_repo "$REPO")
assert_state "$(run_check "$REPO")" "UA_STATE=absent" "absent(no-ua-dir)"

# --- absent：有目录但缺 graph 或 meta ---
REPO="$WORKROOT/absent-meta"; HEAD=$(make_git_repo "$REPO")
write_ua "$REPO" graph '{"nodes":[]}'
assert_state "$(run_check "$REPO")" "UA_STATE=absent" "absent(no-meta)"

# --- corrupt：graph 损坏 JSON ---
REPO="$WORKROOT/corrupt-graph"; HEAD=$(make_git_repo "$REPO")
write_ua "$REPO" graph '{"nodes":'        # invalid JSON
write_ua "$REPO" meta   "{\"gitCommitHash\":\"$HEAD\"}"
assert_state "$(run_check "$REPO")" "UA_STATE=corrupt" "corrupt(graph-bad-json)"

# --- corrupt：graph 合法 JSON 但无 nodes 数组 ---
REPO="$WORKROOT/corrupt-graph-nodes"; HEAD=$(make_git_repo "$REPO")
write_ua "$REPO" graph '{"edges":[]}'     # 合法 JSON，无 nodes
write_ua "$REPO" meta   "{\"gitCommitHash\":\"$HEAD\"}"
assert_state "$(run_check "$REPO")" "UA_STATE=corrupt" "corrupt(graph-no-nodes)"

# --- corrupt：meta 损坏 JSON ---
REPO="$WORKROOT/corrupt-meta"; HEAD=$(make_git_repo "$REPO")
write_ua "$REPO" graph '{"nodes":[]}'
write_ua "$REPO" meta   '{"gitCommitHash":'   # invalid JSON
assert_state "$(run_check "$REPO")" "UA_STATE=corrupt" "corrupt(meta-bad-json)"

# --- corrupt：meta 缺 gitCommitHash 字段（G12 核心）---
REPO="$WORKROOT/corrupt-meta-nohash"; HEAD=$(make_git_repo "$REPO")
write_ua "$REPO" graph '{"nodes":[]}'
write_ua "$REPO" meta   '{"other":"x"}'
assert_state "$(run_check "$REPO")" "UA_STATE=corrupt" "corrupt(meta-no-hash)"

# --- corrupt：meta.gitCommitHash 为 undefined 字符串（防 node -p 返回 "undefined" 误判）---
REPO="$WORKROOT/corrupt-meta-undef"; HEAD=$(make_git_repo "$REPO")
write_ua "$REPO" graph '{"nodes":[]}'
write_ua "$REPO" meta   '{"gitCommitHash":"undefined"}'
assert_state "$(run_check "$REPO")" "UA_STATE=corrupt" "corrupt(meta-hash-undefined-str)"

# --- corrupt：meta.gitCommitHash 过短（<8 字符）---
REPO="$WORKROOT/corrupt-meta-short"; HEAD=$(make_git_repo "$REPO")
write_ua "$REPO" graph '{"nodes":[]}'
write_ua "$REPO" meta   '{"gitCommitHash":"abc"}'
assert_state "$(run_check "$REPO")" "UA_STATE=corrupt" "corrupt(meta-hash-too-short)"

# --- unknown_head：非 git 目录，图谱完整但 HEAD 读不到 ---
REPO="$WORKROOT/nongit"; mkdir -p "$REPO/.understand-anything"
write_ua "$REPO" graph '{"nodes":[]}'
write_ua "$REPO" meta   '{"gitCommitHash":"0123456789abcdef"}'
assert_state "$(run_check "$REPO")" "UA_STATE=unknown_head" "unknown_head(non-git)"

# --- stale_off：meta≠HEAD + autoUpdate≠true（布尔） ---
REPO="$WORKROOT/stale-off"; HEAD1=$(make_git_repo "$REPO"); HEAD2=$(advance_repo "$REPO")
write_ua "$REPO" graph  '{"nodes":[]}'
write_ua "$REPO" meta   "{\"gitCommitHash\":\"$HEAD1\"}"   # 落后
write_ua "$REPO" config '{"autoUpdate":false}'
assert_state "$(run_check "$REPO")" "UA_STATE=stale_off" "stale_off(meta-behind,cfg-off)"

# --- stale_off：config.json 缺失（默认视为 cfg_on=false）---
REPO="$WORKROOT/stale-off-nocfg"; HEAD1=$(make_git_repo "$REPO"); HEAD2=$(advance_repo "$REPO")
write_ua "$REPO" graph  '{"nodes":[]}'
write_ua "$REPO" meta   "{\"gitCommitHash\":\"$HEAD1\"}"
# 无 config.json
assert_state "$(run_check "$REPO")" "UA_STATE=stale_off" "stale_off(no-config-file)"

# --- stale_on：meta≠HEAD + autoUpdate=true + fingerprints 存在 ---
REPO="$WORKROOT/stale-on"; HEAD1=$(make_git_repo "$REPO"); HEAD2=$(advance_repo "$REPO")
write_ua "$REPO" graph  '{"nodes":[]}'
write_ua "$REPO" meta   "{\"gitCommitHash\":\"$HEAD1\"}"
write_ua "$REPO" config '{"autoUpdate":true}'
write_ua "$REPO" fp     '{"file.txt":"abc"}'
assert_state "$(run_check "$REPO")" "UA_STATE=stale_on" "stale_on(meta-behind,cfg-on,fp-ok)"

# --- fresh_on：meta=HEAD + autoUpdate=true + fingerprints ok ---
REPO="$WORKROOT/fresh-on"; HEAD=$(make_git_repo "$REPO")
write_ua "$REPO" graph  '{"nodes":[{"id":"a"}]}'
write_ua "$REPO" meta   "{\"gitCommitHash\":\"$HEAD\"}"
write_ua "$REPO" config '{"autoUpdate":true}'
write_ua "$REPO" fp     '{"file.txt":"abc"}'
assert_state "$(run_check "$REPO")" "UA_STATE=fresh_on" "fresh_on(meta=head,cfg-on,fp-ok)"

# --- fresh_degraded：meta=HEAD + autoUpdate=true + fingerprints 缺失 ---
REPO="$WORKROOT/fresh-degraded-no-fp"; HEAD=$(make_git_repo "$REPO")
write_ua "$REPO" graph  '{"nodes":[]}'
write_ua "$REPO" meta   "{\"gitCommitHash\":\"$HEAD\"}"
write_ua "$REPO" config '{"autoUpdate":true}'
# 无 fingerprints.json
assert_state "$(run_check "$REPO")" "UA_STATE=fresh_degraded" "fresh_degraded(meta=head,cfg-on,no-fp)"

# --- fresh_degraded：meta=HEAD + autoUpdate=false（布尔）---
REPO="$WORKROOT/fresh-degraded-cfg-off"; HEAD=$(make_git_repo "$REPO")
write_ua "$REPO" graph  '{"nodes":[]}'
write_ua "$REPO" meta   "{\"gitCommitHash\":\"$HEAD\"}"
write_ua "$REPO" config '{"autoUpdate":false}'
assert_state "$(run_check "$REPO")" "UA_STATE=fresh_degraded" "fresh_degraded(meta=head,cfg-off)"

# ===========================================================================
# G8：config 字符串 {"autoUpdate":"true"} 不得当布尔 true
# ===========================================================================
REPO="$WORKROOT/cfg-string-true"; HEAD=$(make_git_repo "$REPO")
write_ua "$REPO" graph  '{"nodes":[]}'
write_ua "$REPO" meta   "{\"gitCommitHash\":\"$HEAD\"}"
write_ua "$REPO" config '{"autoUpdate":"true"}'   # 字符串，非布尔
assert_state "$(run_check "$REPO")" "UA_STATE=fresh_degraded" "G8 string-true -> fresh_degraded"

# 同一字符串在 stale 路径下也应判 cfg_on=false → stale_off（而非 stale_on）
REPO="$WORKROOT/cfg-string-true-stale"; HEAD1=$(make_git_repo "$REPO"); HEAD2=$(advance_repo "$REPO")
write_ua "$REPO" graph  '{"nodes":[]}'
write_ua "$REPO" meta   "{\"gitCommitHash\":\"$HEAD1\"}"
write_ua "$REPO" config '{"autoUpdate":"true"}'
assert_state "$(run_check "$REPO")" "UA_STATE=stale_off" "G8 string-true stale -> stale_off"

# ===========================================================================
# G10：子目录运行读仓库根图谱
# ===========================================================================
REPO="$WORKROOT/subdir"; HEAD=$(make_git_repo "$REPO")
write_ua "$REPO" graph  '{"nodes":[]}'
write_ua "$REPO" meta   "{\"gitCommitHash\":\"$HEAD\"}"
write_ua "$REPO" config '{"autoUpdate":true}'
write_ua "$REPO" fp     '{"file.txt":"x"}'
# 在多层子目录下跑（子目录本身不含 .understand-anything）
DEEP="$REPO/client/src/components"
mkdir -p "$DEEP"
assert_state "$(run_check "$DEEP")" "UA_STATE=fresh_on" "G10 subdir reads repo root graph"

# 子目录 + 无图谱在 repo root → absent（验证子目录没误判自身为 root）
REPO2="$WORKROOT/subdir-absent"; HEAD=$(make_git_repo "$REPO2")
mkdir -p "$REPO2/deep"
assert_state "$(run_check "$REPO2/deep")" "UA_STATE=absent" "G10 subdir absent(no graph at root)"

# ===========================================================================
# G9：worktree 重定向读主 repo root 图谱
# ===========================================================================
MAIN="$WORKROOT/main-repo"; HEAD=$(make_git_repo "$MAIN")
write_ua "$MAIN" graph  '{"nodes":[]}'
write_ua "$MAIN" meta   "{\"gitCommitHash\":\"$HEAD\"}"
write_ua "$MAIN" config '{"autoUpdate":true}'
write_ua "$MAIN" fp     '{"file.txt":"x"}'

# linked worktree（git worktree add）：common-dir ≠ git-dir → 重定向到 main root
WT="$WORKROOT/main-wt"
git -C "$MAIN" worktree add "$WT" -b wt-branch >/dev/null 2>&1 \
  || fail "G9: git worktree add failed (git too old?)"
assert_state "$(run_check "$WT")" "UA_STATE=fresh_on" "G9 linked-worktree reads main root graph"

# worktree 子目录也该走主 root
mkdir -p "$WT/sub"
assert_state "$(run_check "$WT/sub")" "UA_STATE=fresh_on" "G9 worktree-subdir reads main root graph"

# 清理 worktree（避免影响后续 mktemp 清理）
git -C "$MAIN" worktree remove "$WT" --force >/dev/null 2>&1 || true

# M1: 无 node（空 PATH，command -v node 失败）→ node 兜底触发 → unknown_head（不误判 corrupt）
M1_DIR="$(mktemp -d)"
M1_H="$(make_git_repo "$M1_DIR")"
write_ua "$M1_DIR" meta "{\"gitCommitHash\":\"$M1_H\"}"
write_ua "$M1_DIR" graph '{"nodes":[]}'
write_ua "$M1_DIR" config '{"autoUpdate":true}'
write_ua "$M1_DIR" fp '{"f":1}'
assert_state "$(cd "$M1_DIR" && PATH= && source "$ROOT_DIR/lib/detection.sh" && check_understand_usability)" "UA_STATE=unknown_head" "M1 empty-PATH (no node) → unknown_head (not corrupt)"
rm -rf "$M1_DIR"

echo "PASS"
