#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SETUP="$ROOT_DIR/setup"
VERSION_VALUE="$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

assert_exists() {
  local path="$1"
  [ -e "$path" ] || fail "expected path to exist: $path"
}

assert_symlink() {
  local path="$1"
  [ -L "$path" ] || fail "expected symlink: $path"
}

assert_file_contains() {
  local path="$1"
  local needle="$2"

  grep -Fq "$needle" "$path" || fail "expected $path to contain: $needle"
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

home_codex="$tmpdir/home-codex"
mkdir -p "$home_codex"

HOME="$home_codex" bash "$SETUP" --host codex >/tmp/codesop-setup-codex.out 2>/tmp/codesop-setup-codex.err || fail "setup --host codex failed"

assert_symlink "$home_codex/.codex/AGENTS.md"
assert_exists "$home_codex/.agents/skills/codesop/SKILL.md"
assert_exists "$home_codex/.agents/skills/codesop/skill.json"
[ ! -e "$home_codex/.agents/skills/codesop/agents" ] || fail "expected Codex runtime to avoid repo-local agents residue"
if [ -e "$home_codex/.codex/skills/codesop" ]; then
  fail "expected Codex setup to avoid duplicate ~/.codex/skills/codesop skill"
fi
assert_symlink "$home_codex/.local/bin/codesop"
assert_file_contains "$home_codex/.agents/skills/codesop/SKILL.md" "name: codesop"
assert_file_contains "$home_codex/.agents/skills/codesop/skill.json" "\"version\": \"$VERSION_VALUE\""

home_auto="$tmpdir/home-auto"
mkdir -p "$home_auto/.claude" "$home_auto/.codex" "$home_auto/.config/opencode"

HOME="$home_auto" bash "$SETUP" --host auto >/tmp/codesop-setup-auto.out 2>/tmp/codesop-setup-auto.err || fail "setup --host auto failed"

assert_symlink "$home_auto/.claude/CLAUDE.md"
assert_file_contains "$home_auto/.claude/CLAUDE.md" "AI 编码契约"
assert_exists "$home_auto/.claude/skills/codesop/SKILL.md"
assert_exists "$home_auto/.claude/commands/codesop.md"
assert_exists "$home_auto/.claude/commands/codesop-init.md"
assert_exists "$home_auto/.claude/commands/codesop-update.md"
[ ! -e "$home_auto/.claude/skills/codesop/agents" ] || fail "expected Claude runtime to avoid repo-local agents residue"
assert_file_contains "$home_auto/.claude/skills/codesop/skill.json" "\"version\": \"$VERSION_VALUE\""

assert_symlink "$home_auto/.codex/AGENTS.md"
if [ -e "$home_auto/.codex/skills/codesop" ]; then
  fail "expected auto setup to avoid duplicate ~/.codex/skills/codesop skill"
fi
assert_symlink "$home_auto/.config/opencode/AGENTS.md"
assert_exists "$home_auto/.agents/skills/codesop/SKILL.md"
[ ! -e "$home_auto/.agents/skills/codesop/agents" ] || fail "expected shared runtime to avoid repo-local agents residue"
assert_file_contains "$home_auto/.agents/skills/codesop/skill.json" "\"version\": \"$VERSION_VALUE\""

echo "PASS"
