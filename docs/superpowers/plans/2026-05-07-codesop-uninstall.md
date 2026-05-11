# codesop uninstall Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `codesop uninstall` subcommand that removes all codesop-installed artifacts without touching installed plugins.

**Architecture:** Add uninstall functions to `setup` with a `--uninstall` flag. Add `uninstall` subcommand route in `codesop` CLI. Add guard functions for symlink, copy, and runtime safety. Add `commands/codesop-uninstall.md` command file.

**Tech Stack:** Bash, jq, git

---

### Task 1: Guard functions in setup

**Files:**
- Modify: `setup` (after line 119, before `write_skill_runtime`)
- Test: `tests/codesop-uninstall.sh`

- [ ] **Step 1: Write failing tests for guard functions**

```bash
# In tests/codesop-uninstall.sh, test section for guards
source "$ROOT_DIR/setup" --host auto 2>/dev/null || true

# Test: _verify_codesop_symlink accepts correct symlink
ln -sfn "$ROOT_DIR/codesop" "$tmpdir/codesop-test"
if _verify_codesop_symlink "$tmpdir/codesop-test"; then
  echo "PASS: correct symlink accepted"
else
  echo "FAIL: correct symlink rejected" >&2; exit 1
fi

# Test: _verify_codesop_symlink rejects non-codesop symlink
ln -sfn "/usr/bin/ls" "$tmpdir/codesop-other"
if _verify_codesop_symlink "$tmpdir/codesop-other"; then
  echo "FAIL: non-codesop symlink accepted" >&2; exit 1
else
  echo "PASS: non-codesop symlink rejected"
fi

# Test: _verify_codesop_symlink rejects overlapping path prefix
mkdir -p "$tmpdir/codesop-backup"
ln -sfn "$tmpdir/codesop-backup/bin/codesop" "$tmpdir/codesop-prefix"
if _verify_codesop_symlink "$tmpdir/codesop-prefix"; then
  echo "FAIL: overlapping prefix symlink accepted" >&2; exit 1
else
  echo "PASS: overlapping prefix symlink rejected"
fi

# Test: _verify_codesop_copy accepts matching file
cp "$ROOT_DIR/commands/codesop-init.md" "$tmpdir/codesop-init.md"
if _verify_codesop_copy "$tmpdir/codesop-init.md" "$ROOT_DIR/commands/codesop-init.md"; then
  echo "PASS: matching copy accepted"
else
  echo "FAIL: matching copy rejected" >&2; exit 1
fi

# Test: _verify_codesop_copy rejects modified file
cp "$ROOT_DIR/commands/codesop-init.md" "$tmpdir/codesop-modified.md"
echo "# modified" >> "$tmpdir/codesop-modified.md"
if _verify_codesop_copy "$tmpdir/codesop-modified.md" "$ROOT_DIR/commands/codesop-init.md"; then
  echo "FAIL: modified copy accepted" >&2; exit 1
else
  echo "PASS: modified copy rejected"
fi

# Test: _verify_codesop_runtime accepts valid runtime
mkdir -p "$tmpdir/codesop-runtime"
printf '%s\n' "$ROOT_DIR" > "$tmpdir/codesop-runtime/.codesop-source"
if _verify_codesop_runtime "$tmpdir/codesop-runtime"; then
  echo "PASS: valid runtime accepted"
else
  echo "FAIL: valid runtime rejected" >&2; exit 1
fi

# Test: _verify_codesop_runtime rejects runtime without marker
mkdir -p "$tmpdir/codesop-nomarker"
if _verify_codesop_runtime "$tmpdir/codesop-nomarker"; then
  echo "FAIL: runtime without marker accepted" >&2; exit 1
else
  echo "PASS: runtime without marker rejected"
fi

# Test: _verify_codesop_runtime rejects runtime with wrong marker
mkdir -p "$tmpdir/codesop-wrong"
printf '%s\n' "/wrong/path" > "$tmpdir/codesop-wrong/.codesop-source"
if _verify_codesop_runtime "$tmpdir/codesop-wrong"; then
  echo "FAIL: wrong marker accepted" >&2; exit 1
else
  echo "PASS: wrong marker rejected"
fi
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/codesop-uninstall.sh 2>&1 | head -5`
Expected: FAIL (functions not defined yet)

- [ ] **Step 3: Implement guard functions**

Add these functions in `setup` after `remove_dir_if_exists()` (after line 119):

```bash

_verify_codesop_symlink() {
  local path="$1"
  [ -L "$path" ] || return 1
  local target
  target="$(readlink -f "$path")"
  case "$target" in
    "$SOURCE_DIR"/*) return 0 ;;
    "$SOURCE_DIR") return 0 ;;
    *) return 1 ;;
  esac
}

_verify_codesop_copy() {
  local path="$1"
  local source="$2"
  [ -f "$path" ] || return 1
  cmp -s "$path" "$source"
}

_verify_codesop_runtime() {
  local path="$1"
  [ -d "$path" ] || return 1
  local marker="$path/.codesop-source"
  [ -f "$marker" ] || return 1
  local installed_source
  installed_source="$(cat "$marker" 2>/dev/null || true)"
  [ "$installed_source" = "$SOURCE_DIR" ]
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/codesop-uninstall.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add setup tests/codesop-uninstall.sh
git commit -m "feat: add guard functions for uninstall safety checks"
```

---

### Task 2: Hook removal function in setup

**Files:**
- Modify: `setup` (after `configure_hooks()`, before `install_cli()`)
- Test: `tests/codesop-uninstall.sh`

- [ ] **Step 1: Write failing tests for hook removal**

```bash
# Test: remove_codesop_hook removes only codesop hook
cat > "$tmpdir/settings-test.json" <<'EOF'
{
  "hooks": {
    "SessionStart": [
      {"matcher": "", "hooks": [{"type": "command", "command": "cat $HOME/.claude/codesop-router.md"}]},
      {"matcher": "", "hooks": [{"type": "command", "command": "echo other-hook"}]}
    ]
  }
}
EOF

HOME="$tmpdir/home"
mkdir -p "$HOME/.claude"
cp "$tmpdir/settings-test.json" "$HOME/.claude/settings.json"
remove_codesop_hook

# Verify codesop hook removed, other hook preserved
codesop_count=$(jq '[.hooks.SessionStart[] | select(.hooks // [] | .[]?.command | test("codesop-router.md"))] | length' "$HOME/.claude/settings.json" 2>/dev/null || echo "1")
other_count=$(jq '[.hooks.SessionStart[] | select(.hooks // [] | .[]?.command | test("other-hook"))] | length' "$HOME/.claude/settings.json" 2>/dev/null || echo "0")

[ "$codesop_count" = "0" ] || { echo "FAIL: codesop hook not removed" >&2; exit 1; }
[ "$other_count" = "1" ] || { echo "FAIL: other hook not preserved" >&2; exit 1; }
echo "PASS: hook removal preserves other hooks"

# Test: remove_codesop_hook handles entry with no command field
cat > "$HOME/.claude/settings.json" <<'EOF'
{
  "hooks": {
    "SessionStart": [
      {"matcher": "", "hooks": [{"type": "command", "command": "cat $HOME/.claude/codesop-router.md"}]},
      {"matcher": "", "hooks": [{"type": "command"}]}
    ]
  }
}
EOF
remove_codesop_hook
jq '.' "$HOME/.claude/settings.json" >/dev/null 2>&1 || { echo "FAIL: settings.json corrupted by null command" >&2; exit 1; }
echo "PASS: handles null command without error"

# Test: idempotent — no error when hook already removed
remove_codesop_hook
echo "PASS: idempotent hook removal"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/codesop-uninstall.sh`
Expected: FAIL (function not defined)

- [ ] **Step 3: Implement remove_codesop_hook**

Add after `configure_hooks()` in `setup` (after line 311):

```bash

remove_codesop_hook() {
  local settings="$HOME/.claude/settings.json"

  [ -f "$settings" ] || return 0
  command -v jq >/dev/null 2>&1 || { echo "  ⚠ jq not found — hook removal skipped"; return 0; }
  jq '.' "$settings" >/dev/null 2>&1 || { echo "  ⚠ $settings invalid JSON — hook removal skipped"; return 0; }

  # Check if codesop hook exists before attempting removal
  local existing
  existing=$(jq '[.hooks.SessionStart // [] | .[] | select(.hooks // [] | .[]?.command | test("codesop-router.md"))] | length' "$settings" 2>/dev/null || echo "0")
  if [ "$existing" = "0" ]; then
    echo "  ⚠ No codesop hook found — skipping"
    return 0
  fi

  if jq '
    if .hooks.SessionStart then
      .hooks.SessionStart |= map(
        if (.hooks | type) == "array" then
          .hooks |= map(select(((.command? // "") | tostring | contains("codesop-router.md")) | not))
        else . end
      )
      | .hooks.SessionStart |= map(select((.hooks | type != "array") or ((.hooks | length) > 0)))
    else . end
  ' "$settings" > "$settings.tmp"; then
    mv "$settings.tmp" "$settings"
    echo "  ✓ Removed SessionStart hook"
  else
    rm -f "$settings.tmp"
    echo "  ⚠ Failed to update $settings — hook not removed"
  fi
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/codesop-uninstall.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add setup tests/codesop-uninstall.sh
git commit -m "feat: add remove_codesop_hook for uninstall"
```

---

### Task 3: Uninstall functions in setup

**Files:**
- Modify: `setup` (after `install_codex()`)
- Test: `tests/codesop-uninstall.sh`

- [ ] **Step 1: Write failing tests for uninstall functions**

```bash
# Setup a fake codesop installation
fake_home="$tmpdir/uninstall-home"
mkdir -p "$fake_home/.claude/skills/codesop" "$fake_home/.claude/commands" "$fake_home/.local/bin"
mkdir -p "$fake_home/.codex" "$fake_home/.config/opencode" "$fake_home/.agents/skills/codesop"

# Create fake installation artifacts
ln -sfn "$ROOT_DIR/templates/system/AGENTS.md" "$fake_home/.claude/CLAUDE.md"
cp "$ROOT_DIR/commands/codesop-init.md" "$fake_home/.claude/commands/codesop-init.md"
cp "$ROOT_DIR/commands/codesop-update.md" "$fake_home/.claude/commands/codesop-update.md"
cp "$ROOT_DIR/config/codesop-router.md" "$fake_home/.claude/codesop-router.md"
ln -sfn "$ROOT_DIR/codesop" "$fake_home/.local/bin/codesop"
printf '%s\n' "$ROOT_DIR" > "$fake_home/.claude/skills/codesop/.codesop-source"
printf '%s\n' "$ROOT_DIR" > "$fake_home/.agents/skills/codesop/.codesop-source"
ln -sfn "$ROOT_DIR/templates/system/AGENTS.md" "$fake_home/.codex/AGENTS.md"
ln -sfn "$ROOT_DIR/templates/system/AGENTS.md" "$fake_home/.config/opencode/AGENTS.md"

# Write settings with codesop hook
cat > "$fake_home/.claude/settings.json" <<'EOF'
{
  "hooks": {
    "SessionStart": [
      {"matcher": "", "hooks": [{"type": "command", "command": "cat $HOME/.claude/codesop-router.md"}]}
    ]
  }
}
EOF

# Run uninstall
HOME="$fake_home" SOURCE_DIR="$ROOT_DIR" bash "$ROOT_DIR/setup" --uninstall --host auto 2>&1

# Verify all artifacts removed
[ -L "$fake_home/.claude/CLAUDE.md" ] && { echo "FAIL: CLAUDE.md symlink not removed" >&2; exit 1; }
[ -d "$fake_home/.claude/skills/codesop" ] && { echo "FAIL: skills/codesop not removed" >&2; exit 1; }
[ -f "$fake_home/.claude/commands/codesop-init.md" ] && { echo "FAIL: codesop-init.md not removed" >&2; exit 1; }
[ -f "$fake_home/.claude/commands/codesop-update.md" ] && { echo "FAIL: codesop-update.md not removed" >&2; exit 1; }
[ -f "$fake_home/.claude/codesop-router.md" ] && { echo "FAIL: router card not removed" >&2; exit 1; }
[ -L "$fake_home/.local/bin/codesop" ] && { echo "FAIL: CLI symlink not removed" >&2; exit 1; }
[ -L "$fake_home/.codex/AGENTS.md" ] && { echo "FAIL: codex AGENTS.md not removed" >&2; exit 1; }
[ -L "$fake_home/.config/opencode/AGENTS.md" ] && { echo "FAIL: opencode AGENTS.md not removed" >&2; exit 1; }
[ -d "$fake_home/.agents/skills/codesop" ] && { echo "FAIL: shared runtime not removed" >&2; exit 1; }
echo "PASS: all artifacts removed by uninstall"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/codesop-uninstall.sh`
Expected: FAIL (`--uninstall` flag not recognized)

- [ ] **Step 3: Add --uninstall flag to setup argument parsing**

In `setup`, add `--uninstall` to the argument parsing block (around line 25-46). Add `ACTION="install"` default variable and set it to `"uninstall"` when the flag is passed:

After `HOST="auto"` (line 6), add:

```bash
ACTION="install"
```

In the `while` loop (around line 25), add before the `*)` case:

```bash
    --uninstall)
      ACTION="uninstall"
      shift
      ;;
```

- [ ] **Step 4: Implement uninstall functions**

Add after `install_codex()` in `setup`:

```bash

restore_superpowers_patches() {
  local plugin_dir
  plugin_dir=$(find_superpowers_plugin_path || true)
  if [ -z "$plugin_dir" ]; then
    echo "  ⚠ superpowers plugin not found — patch restoration skipped"
    return 0
  fi

  if ! command -v claude >/dev/null 2>&1; then
    echo "  ⚠ claude CLI not found — patch restoration skipped"
    return 0
  fi

  echo "  Restoring superpowers skill patches..."
  if _run_with_timeout 30 claude plugin update superpowers@claude-plugins-official --scope user 2>/dev/null; then
    echo "  ✓ Restored superpowers skill patches"
  else
    echo "  ⚠ claude plugin update failed — patches may still be applied"
    echo "    Manual fix: claude plugin update superpowers@claude-plugins-official --scope user"
  fi
}

_safe_rm_symlink() {
  local path="$1"
  local label="$2"
  if [ ! -e "$path" ] && [ ! -L "$path" ]; then
    echo "  ⚠ $label not found — skipping"
    return 0
  fi
  if _verify_codesop_symlink "$path"; then
    rm -f "$path"
    echo "  ✓ Removed $label"
  else
    echo "  ⚠ Skipped $label (symlink does not point to codesop)"
  fi
}

_safe_rm_copy() {
  local path="$1"
  local source="$2"
  local label="$3"
  if [ ! -f "$path" ]; then
    echo "  ⚠ $label not found — skipping"
    return 0
  fi
  if _verify_codesop_copy "$path" "$source"; then
    rm -f "$path"
    echo "  ✓ Removed $label"
  else
    echo "  ⚠ Skipped $label (file has been modified)"
  fi
}

_safe_rm_runtime() {
  local path="$1"
  local label="$2"
  if [ ! -d "$path" ]; then
    echo "  ⚠ $label not found — skipping"
    return 0
  fi
  if _verify_codesop_runtime "$path"; then
    rm -rf "$path"
    echo "  ✓ Removed $label"
  else
    echo "  ⚠ Skipped $label (directory does not belong to this codesop installation)"
  fi
}

uninstall_claude() {
  echo "Removing Claude Code integration..."

  _safe_rm_symlink "$HOME/.claude/CLAUDE.md" "~/.claude/CLAUDE.md"
  _safe_rm_runtime "$HOME/.claude/skills/codesop" "~/.claude/skills/codesop/"
  _safe_rm_copy "$HOME/.claude/commands/codesop-init.md" "$SOURCE_DIR/commands/codesop-init.md" "~/.claude/commands/codesop-init.md"
  _safe_rm_copy "$HOME/.claude/commands/codesop-update.md" "$SOURCE_DIR/commands/codesop-update.md" "~/.claude/commands/codesop-update.md"

  if [ -f "$SOURCE_DIR/commands/codesop-uninstall.md" ]; then
    _safe_rm_copy "$HOME/.claude/commands/codesop-uninstall.md" "$SOURCE_DIR/commands/codesop-uninstall.md" "~/.claude/commands/codesop-uninstall.md"
  fi

  _safe_rm_copy "$HOME/.claude/codesop-router.md" "$SOURCE_DIR/config/codesop-router.md" "~/.claude/codesop-router.md"
  remove_codesop_hook
  restore_superpowers_patches
}

uninstall_codex() {
  echo "Removing Codex integration..."
  _safe_rm_symlink "$HOME/.codex/AGENTS.md" "~/.codex/AGENTS.md"
}

uninstall_opencode() {
  echo "Removing OpenCode integration..."
  _safe_rm_symlink "$HOME/.config/opencode/AGENTS.md" "~/.config/opencode/AGENTS.md"
}

_uninstall_shared_runtime() {
  _safe_rm_runtime "$HOME/.agents/skills/codesop" "~/.agents/skills/codesop/"
}

_uninstall_cli() {
  if [ ! -L "$HOME/.local/bin/codesop" ] && [ ! -e "$HOME/.local/bin/codesop" ]; then
    echo "  ⚠ CLI not found — skipping"
    return 0
  fi
  if _verify_codesop_symlink "$HOME/.local/bin/codesop"; then
    rm -f "$HOME/.local/bin/codesop"
    echo "  ✓ Removed CLI: ~/.local/bin/codesop"
  else
    echo "  ⚠ Skipped CLI (symlink does not point to codesop)"
  fi
}
```

- [ ] **Step 5: Add dispatch logic for --uninstall**

Replace the bottom dispatch section of `setup` (from `echo "=== codesop setup ==="` to end) with action-aware dispatch:

```bash
if [ "$ACTION" = "uninstall" ]; then
  echo "=== codesop uninstall ==="
  echo "Source: $SOURCE_DIR"

  case "$HOST" in
    auto)
      uninstall_claude
      uninstall_codex
      uninstall_opencode
      _uninstall_shared_runtime
      ;;
    claude)
      uninstall_claude
      ;;
    codex)
      uninstall_codex
      ;;
    opencode|openclaw)
      uninstall_opencode
      ;;
  esac

  echo "Removing CLI..."
  _uninstall_cli

  echo
  echo "Done. codesop has been uninstalled."
  echo "Installed plugins (superpowers, code-review, etc.) were NOT removed."
  echo "Source repository at $SOURCE_DIR was NOT deleted."
  echo "Note: statusLine in ~/.claude/settings.json was NOT restored (no pre-install backup)."
else
  echo "=== codesop setup ==="
  echo "Source: $SOURCE_DIR"

  case "$HOST" in
    auto)
      echo "[1/2] Installing host integrations..."
      install_claude
      install_codex
      install_opencode
      ;;
    claude)
      echo "[1/2] Installing Claude Code integration..."
      install_claude
      ;;
    codex)
      echo "[1/2] Installing Codex integration..."
      install_codex
      ;;
    opencode|openclaw)
      echo "[1/2] Installing OpenCode/OpenClaw integration..."
      install_opencode
      ;;
  esac

  echo "[2/2] Linking CLI..."
  install_cli
  echo "  ✓ CLI: ~/.local/bin/codesop"

  echo
  echo "Done."
  echo "To resync hosts after editing codesop locally: bash setup --host auto"
fi
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `bash tests/codesop-uninstall.sh`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add setup tests/codesop-uninstall.sh
git commit -m "feat: add uninstall functions and --uninstall flag to setup"
```

---

### Task 4: CLI subcommand and command file

**Files:**
- Modify: `codesop` (CLI entrypoint)
- Create: `commands/codesop-uninstall.md`
- Modify: `skill.json` (add uninstall to commands list)
- Test: `tests/codesop-uninstall.sh`

- [ ] **Step 1: Write failing test for CLI subcommand**

```bash
# Test: codesop uninstall routes to setup --uninstall
fake_home2="$tmpdir/uninstall-cli-home"
mkdir -p "$fake_home2/.claude/skills/codesop" "$fake_home2/.local/bin"
mkdir -p "$fake_home2/.codex" "$fake_home2/.config/opencode" "$fake_home2/.agents/skills/codesop"
ln -sfn "$ROOT_DIR/templates/system/AGENTS.md" "$fake_home2/.claude/CLAUDE.md"
ln -sfn "$ROOT_DIR/codesop" "$fake_home2/.local/bin/codesop"
printf '%s\n' "$ROOT_DIR" > "$fake_home2/.claude/skills/codesop/.codesop-source"
printf '%s\n' "$ROOT_DIR" > "$fake_home2/.agents/skills/codesop/.codesop-source"

output="$(HOME="$fake_home2" bash "$ROOT_DIR/codesop" uninstall 2>&1)" || true
assert_contains "$output" "codesop uninstall"
assert_contains "$output" "Done. codesop has been uninstalled"
echo "PASS: codesop uninstall CLI routes correctly"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/codesop-uninstall.sh`
Expected: FAIL (unknown subcommand: uninstall)

- [ ] **Step 3: Add uninstall subcommand to codesop CLI**

In `codesop`, add `run_uninstall` function and `uninstall)` case:

After `run_update()` function is sourced (it's in commands.sh), add to `commands.sh`:

```bash
run_uninstall() {
  bash "$ROOT_DIR/setup" --uninstall --host auto
}
```

In `codesop` entrypoint, update `usage()`:

```bash
usage() {
  cat <<'EOF'
Usage:
  codesop init [path]
  codesop update
  codesop uninstall
EOF
}
```

Add `uninstall)` case before `*)`:

```bash
  uninstall)
    run_uninstall
    ;;
```

- [ ] **Step 4: Create commands/codesop-uninstall.md**

```markdown
---
description: Uninstall codesop from the current host via the codesop CLI.
---

Run the real CLI:

```bash
bash ~/.local/bin/codesop uninstall
```

Report what was removed and any warnings about skipped items. Installed plugins are NOT removed.
```

- [ ] **Step 5: Update skill.json commands list**

In `skill.json`, add "uninstall" to the commands array:

```json
"commands": [
  "init",
  "update",
  "uninstall"
]
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `bash tests/codesop-uninstall.sh`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add codesop lib/commands.sh commands/codesop-uninstall.md skill.json tests/codesop-uninstall.sh
git commit -m "feat: add codesop uninstall CLI subcommand and command file"
```

---

### Task 5: Guard edge case tests

**Files:**
- Modify: `tests/codesop-uninstall.sh`

- [ ] **Step 1: Write edge case tests**

```bash
# --- Edge case: non-codesop symlink is NOT deleted ---
echo "--- non-codesop symlink safety ---"
fake_home3="$tmpdir/guard-home"
mkdir -p "$fake_home3/.claude" "$fake_home3/.local/bin"
echo "user content" > "$fake_home3/.claude/CLAUDE.md"
ln -sfn "/usr/local/bin/other-tool" "$fake_home3/.local/bin/codesop"

output="$(HOME="$fake_home3" SOURCE_DIR="$ROOT_DIR" bash "$ROOT_DIR/setup" --uninstall --host claude 2>&1)"
assert_not_contains "$output" "✓ Removed ~/.claude/CLAUDE.md"
assert_not_contains "$output" "✓ Removed CLI"
[ -f "$fake_home3/.claude/CLAUDE.md" ] || { echo "FAIL: non-codesop CLAUDE.md was deleted" >&2; exit 1; }
[ -L "$fake_home3/.local/bin/codesop" ] || { echo "FAIL: non-codesop CLI symlink was deleted" >&2; exit 1; }
echo "PASS: non-codesop artifacts preserved"

# --- Edge case: idempotent uninstall ---
echo "--- idempotent uninstall ---"
fake_home4="$tmpdir/idempotent-home"
mkdir -p "$fake_home4/.claude" "$fake_home4/.local/bin"
output1="$(HOME="$fake_home4" SOURCE_DIR="$ROOT_DIR" bash "$ROOT_DIR/setup" --uninstall --host auto 2>&1)"
output2="$(HOME="$fake_home4" SOURCE_DIR="$ROOT_DIR" bash "$ROOT_DIR/setup" --uninstall --host auto 2>&1)"
assert_contains "$output2" "codesop uninstall"
echo "PASS: idempotent uninstall (no error on empty state)"

# --- Edge case: mixed hooks in same wrapper entry ---
echo "--- mixed hook entry ---"
fake_home5="$tmpdir/mixed-hook-home"
mkdir -p "$fake_home5/.claude"
cat > "$fake_home5/.claude/settings.json" <<'EOF'
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {"type": "command", "command": "cat $HOME/.claude/codesop-router.md"},
          {"type": "command", "command": "echo keep-me"}
        ]
      }
    ]
  }
}
EOF

HOME="$fake_home5" SOURCE_DIR="$ROOT_DIR" bash "$ROOT_DIR/setup" --uninstall --host claude 2>&1
keep_count=$(jq '[.hooks.SessionStart[]?.hooks[]?.command | select(test("keep-me"))] | length' "$fake_home5/.claude/settings.json" 2>/dev/null || echo "0")
codesop_count=$(jq '[.hooks.SessionStart[]?.hooks[]?.command | select(test("codesop-router"))] | length' "$fake_home5/.claude/settings.json" 2>/dev/null || echo "1")
[ "$keep_count" = "1" ] || { echo "FAIL: keep-me hook not preserved in mixed entry" >&2; exit 1; }
[ "$codesop_count" = "0" ] || { echo "FAIL: codesop hook not removed from mixed entry" >&2; exit 1; }
echo "PASS: mixed hook entry handled correctly"
```

- [ ] **Step 2: Run full test suite**

Run: `bash tests/codesop-uninstall.sh`
Expected: PASS (all edge cases)

- [ ] **Step 3: Commit**

```bash
git add tests/codesop-uninstall.sh
git commit -m "test: add edge case tests for codesop uninstall"
```

---

### Task 6: Run all tests

**Files:**
- No new files

- [ ] **Step 1: Run full test suite**

Run: `bash tests/run_all.sh`
Expected: All tests pass including new `codesop-uninstall.sh`

- [ ] **Step 2: Run setup resync to ensure install still works after changes**

Run: `bash setup --host claude`
Expected: No errors, all install steps succeed
