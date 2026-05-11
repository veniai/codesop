# Fix: upgrade_managed_deps timeout false-positive and patch compatibility

**Date**: 2026-05-07
**Status**: Approved

## Problem

`codesop update` calls `claude plugin update` for all managed plugins unconditionally. Two issues:

1. **Timeout false-positive**: When a plugin is already at the latest version, `claude plugin update` hangs instead of returning immediately. The 30s timeout kills it (exit 124), which `upgrade_managed_deps` reports as "failed" — but the plugin was already up to date.

2. **Patch compatibility risk**: For `patched=yes` plugins (superpowers), a blind upgrade could jump to a new major.minor (e.g. 5.1 → 5.2), breaking codesop's patches. `dep_patch_compat` would detect the mismatch and skip patches, leaving the user running unpatched superpowers.

Both issues share a root cause: `upgrade_managed_deps` doesn't know when to skip vs. when to upgrade.

## Design

### Patched plugins (`patched=yes`)

**Gate on manifest compatibility.** Before calling `claude plugin update`, check if the installed version's major.minor matches the manifest's `min_version` major.minor (using existing `dep_patch_compat`).

- **Compatible** (same major.minor): Skip the upgrade call entirely. The installed version satisfies codesop's patch requirements.
- **Incompatible** (different major.minor): Call `claude plugin update`. After upgrade, re-check compatibility. If still incompatible, warn the user.
- **Not installed**: Fall through to upgrade (will be caught by `install_managed_deps` separately).

This ensures patched plugins only get upgraded when codesop's manifest explicitly requires a new version — which happens when codesop ships updated patches for that version.

### Non-patched plugins (`patched=no`)

**Version comparison before/after.** Record the installed version string before calling `claude plugin update`. On non-zero exit:

- **Version changed** → Upgrade succeeded despite non-zero exit code. Report as success.
- **Version unchanged + exit 124 (timeout)** → No upgrade happened. Report as "超时未变" (timeout, version unchanged).
- **Version unchanged + other error** → Genuine failure. Report as failed.

Version is read from `installed_plugins.json` via `jq -r --arg id "$id" '.plugins[$id][0].version // ""'`. Comparison is string equality — works for both semver ("5.1.0") and git hash ("d6947b6f35ad").

Fallback: if `jq` or `installed_plugins.json` unavailable, use exit code only (current behavior).

### Reporting categories

`upgrade_managed_deps` output changes from 3 categories to 4:

| Category | Meaning | Impact on `has_required_fail` |
|----------|---------|-------------------------------|
| `upgraded` | Version actually changed | No |
| `uptodate` | Patched plugin skipped (already compatible) | No |
| `timedout` | Non-patched plugin: timeout + version unchanged | No (not a failure) |
| `fail` | Genuine failure | Yes |

### `_ensure_superpowers_version` fix

Current logic compares installed version against manifest min_version using `dep_patch_compat`. After this change, superpowers should rarely reach this function with a version mismatch (the gate in `upgrade_managed_deps` prevents it). But as a safety net, keep the function — it handles edge cases like manual `claude plugin update` by the user between codesop runs.

No structural change needed to `_ensure_superpowers_version`, but the warning message should be clearer about why patches are being skipped.

## Files changed

- `lib/updates.sh`: `_dep_upgrade_one()`, `upgrade_managed_deps()`, minor `_ensure_superpowers_version()` message update
- `VERSION`: bump to 3.9.7
- `CHANGELOG.md`: add entry
- `CLAUDE.md` / `PRD.md` / `README.md`: assess and update if needed

## What this does NOT change

- `install_managed_deps()`: untouched — first-time install still calls `claude plugin install`
- `dep_patch_compat()`: unchanged — existing major.minor comparison logic is correct
- `config/dependencies.sh`: unchanged — manifest format stays the same
- `setup` / `patch_skills()`: unchanged — compatibility check already in place

## Limitation

For patched plugins that DO need upgrading (manifest bumped), `claude plugin update` is a black box — we cannot control which version it installs. If it installs a version outside the compatible major.minor, we detect and warn but cannot downgrade. This is acceptable because codesop releases and superpowers releases are typically synchronized.
