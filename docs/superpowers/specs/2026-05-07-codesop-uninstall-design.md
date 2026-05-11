# codesop uninstall 设计

## Goal

Add `codesop uninstall` subcommand that removes all codesop-installed artifacts without touching installed plugins or user-created files.

## Scope

- Remove all symlinks, copied files, hook entries, and runtime directories created by `setup`
- Restore superpowers skill patches to upstream versions
- Do NOT uninstall any plugin (superpowers, code-review, etc.)
- Do NOT delete the codesop source repository

### Known residuals

- `~/.claude/settings.json` statusLine: codesop overwrites the existing command on install. Uninstall does NOT restore the original statusLine because codesop does not have a pre-install backup. This is an accepted residual.
- `install_managed_deps()` installs plugins via `claude plugin install`. Uninstall does NOT remove these — they are user-owned after installation.

## Uninstall Targets

### Claude Code host

| Artifact | Path | Action | Guard |
|----------|------|--------|-------|
| System CLAUDE.md | `~/.claude/CLAUDE.md` | `rm -f` | Symlink target must be under `$SOURCE_DIR` (case pattern match) |
| Skill runtime | `~/.claude/skills/codesop/` | `rm -rf` | Must contain `.codesop-source` pointing to `$SOURCE_DIR` |
| Sub-commands | `~/.claude/commands/codesop-init.md` | `rm -f` | `cmp -s` matches source copy |
| Sub-commands | `~/.claude/commands/codesop-update.md` | `rm -f` | `cmp -s` matches source copy |
| Sub-commands | `~/.claude/commands/codesop-uninstall.md` | `rm -f` | `cmp -s` matches source copy |
| Router card | `~/.claude/codesop-router.md` | `rm -f` | `cmp -s` matches source copy |
| SessionStart hook | `~/.claude/settings.json` | jq remove entry | See Hook removal section |
| Superpowers patches | plugin skill dirs | `claude plugin update superpowers` | Plugin installed, `claude` CLI available |
| CLI symlink | `~/.local/bin/codesop` | `rm -f` (LAST) | Symlink target must be under `$SOURCE_DIR` |

CLI symlink is deleted last so the user retains `codesop uninstall` as a retry mechanism if the process fails midway.

### Codex host

| Artifact | Path | Action | Guard |
|----------|------|--------|-------|
| AGENTS.md | `~/.codex/AGENTS.md` | `rm -f` | Symlink target must be under `$SOURCE_DIR` |

### OpenCode host

| Artifact | Path | Action | Guard |
|----------|------|--------|-------|
| AGENTS.md | `~/.config/opencode/AGENTS.md` | `rm -f` | Symlink target must be under `$SOURCE_DIR` |

### Shared runtime (used by Claude Code, Codex, and/or OpenCode)

| Artifact | Path | Action | Guard |
|----------|------|--------|-------|
| Skill runtime | `~/.agents/skills/codesop/` | `rm -rf` | Must contain `.codesop-source` pointing to `$SOURCE_DIR`. Only delete if no other host still references it. |

### What we do NOT touch

- `~/.claude/settings.json` statusLine entry (accepted residual — no pre-install backup exists)
- Any installed plugins (`claude plugin list`)
- The codesop source repository itself
- `/tmp/claude-context.json` (transient, not owned by codesop)

## Implementation Approach

1. Add `uninstall_claude()`, `uninstall_codex()`, `uninstall_opencode()` functions to `setup`
2. Add `--uninstall` flag to `setup` that routes to uninstall functions instead of install functions
3. Add `uninstall` subcommand in `codesop` CLI entrypoint
4. Add `commands/codesop-uninstall.md` command file (also added to uninstall target list above)

### Source directory resolution

When running `codesop uninstall`, the CLI resolves `$SOURCE_DIR` from its own symlink (same as `codesop` entrypoint). When running `bash setup --uninstall`, `$SOURCE_DIR` is already set. This ensures guards check against the actual installation source.

### Symlink safety

Use `case` pattern match for path boundary, not `grep` substring match:

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
```

### Copied file safety

For files that were copied (not symlinked), verify they still match the source before deleting. If the user has modified a copied file, skip deletion and warn:

```bash
_verify_codesop_copy() {
  local path="$1"
  local source="$2"
  [ -f "$path" ] || return 1
  cmp -s "$path" "$source"
}
```

### Runtime directory safety

Skill runtime directories contain a `.codesop-source` marker written by `write_skill_runtime()`. Verify this marker points to the current source before deleting:

```bash
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

### Hook removal

Remove inner hook entries matching `codesop-router.md`, then prune empty wrapper entries. Preserve all other hooks. Use temp file + atomic mv:

```bash
remove_codesop_hook() {
  local settings="$HOME/.claude/settings.json"
  [ -f "$settings" ] || return 0
  command -v jq >/dev/null 2>&1 || { echo "  ⚠ jq not found — hook removal skipped"; return 0; }
  jq '.' "$settings" >/dev/null 2>&1 || { echo "  ⚠ $settings invalid JSON — hook removal skipped"; return 0; }

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

### Patch restoration

Run `claude plugin update superpowers` to restore original SKILL.md files. This is the inverse of `patch_skills()`.

Limitations:
- `claude plugin update` may report "already up to date" without overwriting locally patched files. This is a known gap — a future version should save `.codesop-backup` copies before patching.
- Requires `claude` CLI available; skip with warning if not.
- Use `_run_with_timeout()` (from updates.sh) to prevent hanging.

## Output Format

```
=== codesop uninstall ===

Removing Claude Code integration...
  ✓ Removed ~/.claude/CLAUDE.md
  ✓ Removed ~/.claude/skills/codesop/
  ✓ Removed ~/.claude/commands/codesop-init.md
  ✓ Removed ~/.claude/commands/codesop-update.md
  ✓ Removed ~/.claude/commands/codesop-uninstall.md
  ✓ Removed ~/.claude/codesop-router.md
  ✓ Removed SessionStart hook
  ✓ Restored superpowers skill patches
  ✓ Removed CLI: ~/.local/bin/codesop

Removing Codex integration...
  ✓ Removed ~/.codex/AGENTS.md

Removing OpenCode integration...
  ✓ Removed ~/.config/opencode/AGENTS.md

Removing shared runtime...
  ✓ Removed ~/.agents/skills/codesop/

Done. codesop has been uninstalled.
Installed plugins (superpowers, code-review, etc.) were NOT removed.
Source repository at ~/codesop was NOT deleted.
Note: statusLine in ~/.claude/settings.json was NOT restored (codesop does not have a pre-install backup).
```

Skipped items output `⚠ Skipped X (reason)` instead of `✓`.

## Testing

Create `tests/codesop-uninstall.sh`:
- Symlink guard: non-codesop symlink at `~/.claude/CLAUDE.md` is NOT deleted
- Symlink guard: symlink with overlapping path prefix is NOT deleted
- Copied file guard: user-modified command file is NOT deleted
- Runtime guard: directory without `.codesop-source` is NOT deleted
- Hook removal: other SessionStart hooks are preserved
- Hook removal: entry with no command field does not cause jq error
- Hook removal: mixed entry (codesop + other hooks in same wrapper) correctly removes only codesop inner hook
- Idempotent: running uninstall twice does not error
- Patch restoration: `claude plugin update superpowers` is called when plugin is installed
- CLI last: if uninstall fails midway, `~/.local/bin/codesop` still exists for retry
- Shared runtime: not deleted when another host still has references
- Source resolution: running from different checkout correctly resolves installation source
