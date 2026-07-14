#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$(dirname "$0")/test_helpers.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

echo "--- uninstall guard: non-codesop symlink ---"
# Test that a non-codesop symlink is NOT deleted by uninstall
fake_home="$tmpdir/guard-home"
mkdir -p "$fake_home/.claude/skills/codesop" "$fake_home/.local/bin" "$fake_home/.codex" "$fake_home/.config/opencode" "$fake_home/.agents/skills/codesop"

# Create non-codesop symlink at ~/.claude/CLAUDE.md
echo "user content" > "$fake_home/.claude/CLAUDE.md"
# Create non-codesop symlink at ~/.local/bin/codesop
ln -sfn "/usr/local/bin/other-tool" "$fake_home/.local/bin/codesop"
# Create runtime without .codesop-source marker
cp "$ROOT_DIR/SKILL.md" "$fake_home/.claude/skills/codesop/SKILL.md"
# Create settings with codesop hook
cat > "$fake_home/.claude/settings.json" <<'EOF'
{"hooks":{"SessionStart":[{"matcher":"","hooks":[{"type":"command","command":"cat $HOME/.claude/codesop-router.md"}]}]}}
EOF

output="$(HOME="$fake_home" bash "$ROOT_DIR/codesop" uninstall 2>&1)" || true

# Non-codesop files should be preserved
[ -f "$fake_home/.claude/CLAUDE.md" ] || fail "non-codesop CLAUDE.md was deleted"
assert_not_contains "$output" "✓ Removed ~/.claude/CLAUDE.md"
echo "PASS: non-codesop CLAUDE.md preserved"

[ -L "$fake_home/.local/bin/codesop" ] || fail "non-codesop CLI symlink was deleted"
assert_not_contains "$output" "✓ Removed CLI"
echo "PASS: non-codesop CLI symlink preserved"

echo "--- uninstall guard: runtime without marker ---"
# Runtime without .codesop-source should NOT be deleted
[ -d "$fake_home/.agents/skills/codesop" ] || fail "runtime without marker was deleted"
echo "PASS: runtime without marker preserved"

echo "--- uninstall full: correct artifacts removed ---"
fake_home2="$tmpdir/full-uninstall-home"
mkdir -p "$fake_home2/.claude/skills/codesop" "$fake_home2/.claude/commands" "$fake_home2/.local/bin"
mkdir -p "$fake_home2/.codex" "$fake_home2/.config/opencode" "$fake_home2/.agents/skills/codesop"

# Create proper codesop installation artifacts
ln -sfn "$ROOT_DIR/templates/system/AGENTS.md" "$fake_home2/.claude/CLAUDE.md"
cp "$ROOT_DIR/commands/codesop-init.md" "$fake_home2/.claude/commands/codesop-init.md"
cp "$ROOT_DIR/commands/codesop-update.md" "$fake_home2/.claude/commands/codesop-update.md"
cp "$ROOT_DIR/config/codesop-router.md" "$fake_home2/.claude/codesop-router.md"
cp "$ROOT_DIR/config/codesop-router-kernel.md" "$fake_home2/.claude/codesop-router-kernel.md"
ln -sfn "$ROOT_DIR/codesop" "$fake_home2/.local/bin/codesop"
printf '%s\n' "$ROOT_DIR" > "$fake_home2/.claude/skills/codesop/.codesop-source"
printf '%s\n' "$ROOT_DIR" > "$fake_home2/.agents/skills/codesop/.codesop-source"
ln -sfn "$ROOT_DIR/templates/system/AGENTS.md" "$fake_home2/.codex/AGENTS.md"
ln -sfn "$ROOT_DIR/templates/system/AGENTS.md" "$fake_home2/.config/opencode/AGENTS.md"

cat > "$fake_home2/.claude/settings.json" <<'EOF'
{"hooks":{"SessionStart":[{"matcher":"","hooks":[{"type":"command","command":"cat $HOME/.claude/codesop-router.md"}]}]}}
EOF

output2="$(HOME="$fake_home2" bash "$ROOT_DIR/codesop" uninstall 2>&1)" || true

assert_contains "$output2" "codesop uninstall"
assert_contains "$output2" "Done. codesop has been uninstalled"

[ -e "$fake_home2/.claude/CLAUDE.md" ] && fail "CLAUDE.md symlink not removed"
[ -d "$fake_home2/.claude/skills/codesop" ] && fail "skills/codesop not removed"
[ -f "$fake_home2/.claude/commands/codesop-init.md" ] && fail "codesop-init.md not removed"
[ -f "$fake_home2/.claude/commands/codesop-update.md" ] && fail "codesop-update.md not removed"
[ -f "$fake_home2/.claude/codesop-router.md" ] && fail "router card not removed"
[ -f "$fake_home2/.claude/codesop-router-kernel.md" ] && fail "kernel not removed"
[ -L "$fake_home2/.local/bin/codesop" ] && fail "CLI symlink not removed"
[ -L "$fake_home2/.codex/AGENTS.md" ] && fail "codex AGENTS.md not removed"
[ -L "$fake_home2/.config/opencode/AGENTS.md" ] && fail "opencode AGENTS.md not removed"
[ -d "$fake_home2/.agents/skills/codesop" ] && fail "shared runtime not removed"
echo "PASS: all artifacts removed"

echo "--- uninstall hook: other hooks preserved ---"
fake_home3="$tmpdir/hook-home"
mkdir -p "$fake_home3/.claude/skills/codesop" "$fake_home3/.claude/commands" "$fake_home3/.local/bin"
mkdir -p "$fake_home3/.codex" "$fake_home3/.config/opencode" "$fake_home3/.agents/skills/codesop"
ln -sfn "$ROOT_DIR/templates/system/AGENTS.md" "$fake_home3/.claude/CLAUDE.md"
ln -sfn "$ROOT_DIR/codesop" "$fake_home3/.local/bin/codesop"
printf '%s\n' "$ROOT_DIR" > "$fake_home3/.claude/skills/codesop/.codesop-source"
printf '%s\n' "$ROOT_DIR" > "$fake_home3/.agents/skills/codesop/.codesop-source"
cp "$ROOT_DIR/commands/codesop-init.md" "$fake_home3/.claude/commands/codesop-init.md"
cp "$ROOT_DIR/commands/codesop-update.md" "$fake_home3/.claude/commands/codesop-update.md"
cp "$ROOT_DIR/config/codesop-router.md" "$fake_home3/.claude/codesop-router.md"
ln -sfn "$ROOT_DIR/templates/system/AGENTS.md" "$fake_home3/.codex/AGENTS.md"
ln -sfn "$ROOT_DIR/templates/system/AGENTS.md" "$fake_home3/.config/opencode/AGENTS.md"

cat > "$fake_home3/.claude/settings.json" <<'EOF'
{"hooks":{"SessionStart":[
  {"matcher":"","hooks":[{"type":"command","command":"cat $HOME/.claude/codesop-router.md"}]},
  {"matcher":"","hooks":[{"type":"command","command":"echo other-hook"}]}
]}}
EOF

HOME="$fake_home3" bash "$ROOT_DIR/codesop" uninstall 2>&1 || true

codesop_count=$(jq '[.hooks.SessionStart[]?.hooks[]?.command | select(test("codesop-router"))] | length' "$fake_home3/.claude/settings.json" 2>/dev/null || echo "1")
other_count=$(jq '[.hooks.SessionStart[]?.hooks[]?.command | select(test("other-hook"))] | length' "$fake_home3/.claude/settings.json" 2>/dev/null || echo "0")

[ "$codesop_count" = "0" ] || fail "codesop hook not removed"
[ "$other_count" = "1" ] || fail "other hook not preserved"
echo "PASS: other hooks preserved"

echo "--- uninstall hook: null command handled ---"
fake_home4="$tmpdir/null-cmd-home"
mkdir -p "$fake_home4/.claude/skills/codesop" "$fake_home4/.claude/commands" "$fake_home4/.local/bin"
mkdir -p "$fake_home4/.codex" "$fake_home4/.config/opencode" "$fake_home4/.agents/skills/codesop"
ln -sfn "$ROOT_DIR/templates/system/AGENTS.md" "$fake_home4/.claude/CLAUDE.md"
ln -sfn "$ROOT_DIR/codesop" "$fake_home4/.local/bin/codesop"
printf '%s\n' "$ROOT_DIR" > "$fake_home4/.claude/skills/codesop/.codesop-source"
printf '%s\n' "$ROOT_DIR" > "$fake_home4/.agents/skills/codesop/.codesop-source"
cp "$ROOT_DIR/commands/codesop-init.md" "$fake_home4/.claude/commands/codesop-init.md"
cp "$ROOT_DIR/commands/codesop-update.md" "$fake_home4/.claude/commands/codesop-update.md"
cp "$ROOT_DIR/config/codesop-router.md" "$fake_home4/.claude/codesop-router.md"
ln -sfn "$ROOT_DIR/templates/system/AGENTS.md" "$fake_home4/.codex/AGENTS.md"
ln -sfn "$ROOT_DIR/templates/system/AGENTS.md" "$fake_home4/.config/opencode/AGENTS.md"

cat > "$fake_home4/.claude/settings.json" <<'EOF'
{"hooks":{"SessionStart":[
  {"matcher":"","hooks":[{"type":"command","command":"cat $HOME/.claude/codesop-router.md"}]},
  {"matcher":"","hooks":[{"type":"command"}]}
]}}
EOF

HOME="$fake_home4" bash "$ROOT_DIR/codesop" uninstall 2>&1 || true
jq '.' "$fake_home4/.claude/settings.json" >/dev/null 2>&1 || fail "settings.json corrupted by null command"
echo "PASS: handles null command without error"

echo "--- uninstall: idempotent ---"
fake_home5="$tmpdir/idempotent-home"
mkdir -p "$fake_home5/.claude" "$fake_home5/.local/bin"
output_a="$(HOME="$fake_home5" bash "$ROOT_DIR/codesop" uninstall 2>&1)" || true
output_b="$(HOME="$fake_home5" bash "$ROOT_DIR/codesop" uninstall 2>&1)" || true
assert_contains "$output_b" "codesop uninstall"
echo "PASS: idempotent uninstall (no error on empty state)"

echo "--- uninstall hook: mixed entry ---"
fake_home6="$tmpdir/mixed-hook-home"
mkdir -p "$fake_home6/.claude/skills/codesop" "$fake_home6/.claude/commands" "$fake_home6/.local/bin"
mkdir -p "$fake_home6/.codex" "$fake_home6/.config/opencode" "$fake_home6/.agents/skills/codesop"
ln -sfn "$ROOT_DIR/templates/system/AGENTS.md" "$fake_home6/.claude/CLAUDE.md"
ln -sfn "$ROOT_DIR/codesop" "$fake_home6/.local/bin/codesop"
printf '%s\n' "$ROOT_DIR" > "$fake_home6/.claude/skills/codesop/.codesop-source"
printf '%s\n' "$ROOT_DIR" > "$fake_home6/.agents/skills/codesop/.codesop-source"
cp "$ROOT_DIR/commands/codesop-init.md" "$fake_home6/.claude/commands/codesop-init.md"
cp "$ROOT_DIR/commands/codesop-update.md" "$fake_home6/.claude/commands/codesop-update.md"
cp "$ROOT_DIR/config/codesop-router.md" "$fake_home6/.claude/codesop-router.md"
ln -sfn "$ROOT_DIR/templates/system/AGENTS.md" "$fake_home6/.codex/AGENTS.md"
ln -sfn "$ROOT_DIR/templates/system/AGENTS.md" "$fake_home6/.config/opencode/AGENTS.md"

cat > "$fake_home6/.claude/settings.json" <<'EOF'
{"hooks":{"SessionStart":[
  {"matcher":"","hooks":[
    {"type":"command","command":"cat $HOME/.claude/codesop-router.md"},
    {"type":"command","command":"echo keep-me"}
  ]}
]}}
EOF

HOME="$fake_home6" bash "$ROOT_DIR/codesop" uninstall 2>&1 || true
keep_count=$(jq '[.hooks.SessionStart[]?.hooks[]?.command | select(test("keep-me"))] | length' "$fake_home6/.claude/settings.json" 2>/dev/null || echo "0")
codesop_count=$(jq '[.hooks.SessionStart[]?.hooks[]?.command | select(test("codesop-router"))] | length' "$fake_home6/.claude/settings.json" 2>/dev/null || echo "1")
[ "$keep_count" = "1" ] || fail "keep-me hook not preserved in mixed entry"
[ "$codesop_count" = "0" ] || fail "codesop hook not removed from mixed entry"
echo "PASS: mixed hook entry handled correctly"

echo "--- uninstall guard: copied file modified by user ---"
fake_home7="$tmpdir/modified-copy-home"
mkdir -p "$fake_home7/.claude/skills/codesop" "$fake_home7/.claude/commands" "$fake_home7/.local/bin"
mkdir -p "$fake_home7/.codex" "$fake_home7/.config/opencode" "$fake_home7/.agents/skills/codesop"
ln -sfn "$ROOT_DIR/templates/system/AGENTS.md" "$fake_home7/.claude/CLAUDE.md"
ln -sfn "$ROOT_DIR/codesop" "$fake_home7/.local/bin/codesop"
printf '%s\n' "$ROOT_DIR" > "$fake_home7/.claude/skills/codesop/.codesop-source"
printf '%s\n' "$ROOT_DIR" > "$fake_home7/.agents/skills/codesop/.codesop-source"
ln -sfn "$ROOT_DIR/templates/system/AGENTS.md" "$fake_home7/.codex/AGENTS.md"
ln -sfn "$ROOT_DIR/templates/system/AGENTS.md" "$fake_home7/.config/opencode/AGENTS.md"
cat > "$fake_home7/.claude/settings.json" <<'EOF'
{}
EOF

# Copy init command then modify it
cp "$ROOT_DIR/commands/codesop-init.md" "$fake_home7/.claude/commands/codesop-init.md"
echo "# user modification" >> "$fake_home7/.claude/commands/codesop-init.md"
cp "$ROOT_DIR/commands/codesop-update.md" "$fake_home7/.claude/commands/codesop-update.md"
cp "$ROOT_DIR/config/codesop-router.md" "$fake_home7/.claude/codesop-router.md"

output7="$(HOME="$fake_home7" bash "$ROOT_DIR/codesop" uninstall 2>&1)" || true

# Modified copy should be preserved
[ -f "$fake_home7/.claude/commands/codesop-init.md" ] || fail "user-modified codesop-init.md was deleted"
assert_contains "$output7" "Skipped"
echo "PASS: user-modified copied file preserved"

echo "--- uninstall guard: overlapping path prefix ---"
fake_home8="$tmpdir/prefix-home"
mkdir -p "$fake_home8/.claude" "$fake_home8/.local/bin"
mkdir -p "$fake_home8/.codex" "$fake_home8/.config/opencode" "$fake_home8/.agents/skills/codesop"
cat > "$fake_home8/.claude/settings.json" <<'EOF'
{}
EOF
# Create a symlink that starts with the codesop source path but is NOT inside it
# e.g. /home/claw/codesop-backup/something
parent_dir="$(dirname "$ROOT_DIR")"
ln -sfn "${parent_dir}/codesop-backup/foo" "$fake_home8/.claude/CLAUDE.md"
ln -sfn "${parent_dir}/codesop-backup/bin/codesop" "$fake_home8/.local/bin/codesop"

output8="$(HOME="$fake_home8" bash "$ROOT_DIR/codesop" uninstall 2>&1)" || true

# Overlapping prefix symlink should be preserved
[ -L "$fake_home8/.claude/CLAUDE.md" ] || fail "overlapping-prefix CLAUDE.md was deleted"
[ -L "$fake_home8/.local/bin/codesop" ] || fail "overlapping-prefix CLI was deleted"
echo "PASS: overlapping path prefix symlink preserved"

echo "--- uninstall: CLI survives after host uninstall errors ---"
fake_home9="$tmpdir/cli-last-home"
mkdir -p "$fake_home9/.claude/skills/codesop" "$fake_home9/.claude/commands" "$fake_home9/.local/bin"
mkdir -p "$fake_home9/.codex" "$fake_home9/.config/opencode" "$fake_home9/.agents/skills/codesop"
ln -sfn "$ROOT_DIR/templates/system/AGENTS.md" "$fake_home9/.claude/CLAUDE.md"
printf '%s\n' "$ROOT_DIR" > "$fake_home9/.claude/skills/codesop/.codesop-source"
printf '%s\n' "$ROOT_DIR" > "$fake_home9/.agents/skills/codesop/.codesop-source"
cp "$ROOT_DIR/commands/codesop-init.md" "$fake_home9/.claude/commands/codesop-init.md"
cp "$ROOT_DIR/commands/codesop-update.md" "$fake_home9/.claude/commands/codesop-update.md"
cp "$ROOT_DIR/config/codesop-router.md" "$fake_home9/.claude/codesop-router.md"
ln -sfn "$ROOT_DIR/templates/system/AGENTS.md" "$fake_home9/.codex/AGENTS.md"
ln -sfn "$ROOT_DIR/templates/system/AGENTS.md" "$fake_home9/.config/opencode/AGENTS.md"
cat > "$fake_home9/.claude/settings.json" <<'EOF'
{}
EOF
# CLI symlink is valid codesop
ln -sfn "$ROOT_DIR/codesop" "$fake_home9/.local/bin/codesop"

HOME="$fake_home9" bash "$ROOT_DIR/codesop" uninstall 2>&1 || true

# After full uninstall, CLI should also be gone (it succeeded)
[ ! -L "$fake_home9/.local/bin/codesop" ] || fail "CLI should be removed after successful uninstall"
echo "PASS: CLI removed last after successful uninstall"
