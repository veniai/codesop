# Upgrade Managed Deps Timeout Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix `upgrade_managed_deps` timeout false-positive and patch compatibility risk by gating patched plugin upgrades and using version comparison for non-patched plugins.

**Architecture:** Add `_dep_installed_version()` helper to read plugin versions from `installed_plugins.json`. Gate `patched=yes` plugins on manifest compatibility (skip if already compatible). For `patched=no` plugins, compare version before/after upgrade to distinguish timeout from real failure. Update reporting to 4 categories.

**Tech Stack:** Bash, jq, existing test helpers

---

### Task 1: Add `_dep_installed_version()` helper and rewrite `_dep_upgrade_one()`

**Files:**
- Modify: `lib/updates.sh:801-828` (between `_dep_parse` and `dep_patch_compat`)

- [ ] **Step 1: Add `_dep_installed_version()` after `_dep_parse()` (line ~800)**

Insert after the `_dep_parse()` function:

```bash
# Read installed version of a managed dependency from installed_plugins.json.
# Returns version string (semver or git hash) or empty string if unavailable.
_dep_installed_version() {
  local id="$1"
  local plugins_json="$HOME/.claude/plugins/installed_plugins.json"
  if [ -f "$plugins_json" ] && command -v jq >/dev/null 2>&1; then
    jq -r --arg id "$id" '.plugins[$id][0].version // ""' "$plugins_json" 2>/dev/null || true
  fi
}
```

- [ ] **Step 2: Rewrite `_dep_upgrade_one()` to use version comparison**

Replace the entire `_dep_upgrade_one()` function (currently lines 811-828):

```bash
# Upgrade a single managed dependency.
# Returns: 0 = upgraded, 1 = failed, 2 = timeout with version unchanged.
_dep_upgrade_one() {
  local type="$1" id="$2"
  case "$type" in
    plugin)
      if ! command -v claude >/dev/null 2>&1; then
        echo "claude CLI not available" >&2
        return 1
      fi

      # Record pre-upgrade version
      local pre_ver
      pre_ver=$(_dep_installed_version "$id")

      _run_with_timeout 30 claude plugin update "$id" --scope user >/dev/null 2>&1
      local exit_code=$?

      # Exit 0: upgrade succeeded
      [ "$exit_code" -eq 0 ] && return 0

      # Non-zero exit: check if version changed despite the error
      local post_ver
      post_ver=$(_dep_installed_version "$id")

      # Version changed → upgrade actually completed
      if [ -n "$pre_ver" ] && [ -n "$post_ver" ] && [ "$pre_ver" != "$post_ver" ]; then
        return 0
      fi

      # Timeout (124) with version unchanged → no update needed
      if [ "$exit_code" -eq 124 ]; then
        return 2
      fi

      # Genuine failure
      return 1
      ;;
    *)
      echo "unsupported dep type: $type" >&2
      return 1
      ;;
  esac
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/updates.sh
git commit -m "refactor: add version comparison to _dep_upgrade_one()"
```

---

### Task 2: Rewrite `upgrade_managed_deps()` with patched gate and 4-category reporting

**Files:**
- Modify: `lib/updates.sh:848-879` (`upgrade_managed_deps` function)

- [ ] **Step 1: Replace `upgrade_managed_deps()` function**

Replace the entire function:

```bash
# Main entry: upgrade all managed dependencies.
# Patched plugins: skip if already at compatible version (dep_patch_compat).
# Non-patched plugins: upgrade with version comparison for timeout handling.
# Returns 0 if all core/required succeed, 1 otherwise.
upgrade_managed_deps() {
  _dep_manifest_load || { printf '%s\n' "  依赖清单不存在，跳过升级"; return 0; }

  local upgraded=() uptodate=() timedout=() skip=() fail=()
  local has_required_fail=false

  for entry in "${DEP_MANIFEST[@]}"; do
    _dep_parse "$entry"

    # Skip if upgrade tool unavailable
    case "$_d_type" in
      plugin) command -v claude >/dev/null 2>&1 || { skip+=("$_d_id"); continue; } ;;
      *) skip+=("$_d_id"); continue ;;
    esac

    # Patched plugins: skip upgrade if already at compatible version
    if [ "$_d_patched" = "yes" ]; then
      local installed_ver
      installed_ver=$(_dep_installed_version "$_d_id")
      if [ -n "$installed_ver" ] && dep_patch_compat "$installed_ver" "$_d_min_ver"; then
        uptodate+=("$_d_id")
        printf '  %-45s %s\n' "$_d_id" "✓ (已是最新)"
        continue
      fi
    fi

    printf '  %-45s ' "$_d_id"
    local rc=0
    _dep_upgrade_one "$_d_type" "$_d_id" || rc=$?

    case $rc in
      0)
        upgraded+=("$_d_id")
        printf '%s\n' "✓"
        ;;
      2)
        timedout+=("$_d_id")
        printf '%s\n' "✓ (超时，版本未变)"
        ;;
      *)
        fail+=("$_d_id [$_d_tier]")
        printf '%s\n' "✗"
        has_required_fail=true
        ;;
    esac
  done

  [ ${#upgraded[@]} -gt 0 ] && printf '%s\n' "  已升级（${#upgraded[@]} 个）：${upgraded[*]}"
  [ ${#uptodate[@]} -gt 0 ] && printf '%s\n' "  已是最新（${#uptodate[@]} 个）：${uptodate[*]}"
  [ ${#timedout[@]} -gt 0 ] && printf '%s\n' "  超时未变（${#timedout[@]} 个）：${timedout[*]}"
  [ ${#skip[@]} -gt 0 ] && printf '%s\n' "  已跳过：${skip[*]}"
  [ ${#fail[@]} -gt 0 ] && printf '%s\n' "  失败（${#fail[@]} 个）：${fail[*]}"

  [ "$has_required_fail" = false ]
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/updates.sh
git commit -m "feat: patched plugin gate + 4-category upgrade reporting"
```

---

### Task 3: Update `_ensure_superpowers_version()` warning message

**Files:**
- Modify: `lib/updates.sh:924` (warning line)

- [ ] **Step 1: Fix misleading "still below" message**

Replace:
```bash
printf '  %s\n' "⚠ superpowers $actual_ver still below $required_ver — patches will be skipped"
```

With:
```bash
printf '  %s\n' "⚠ superpowers $actual_ver 与当前补丁不兼容（需要 $required_ver 同系列）— 补丁将被跳过"
```

- [ ] **Step 2: Commit**

```bash
git add lib/updates.sh
git commit -m "fix: clarify superpowers version incompatibility message"
```

---

### Task 4: Add unit tests for `_dep_installed_version` and patched gate logic

**Files:**
- Modify: `tests/codesop-update.sh` (append new tests)

- [ ] **Step 1: Add test for `_dep_installed_version` with mock plugins.json**

Append to `tests/codesop-update.sh` before the final `echo "PASS"`:

```bash

# Test 4: _dep_installed_version reads from plugins.json
mock_plugins_dir="$tmpdir/mock-plugins"
mock_plugins_json="$mock_plugins_dir/installed_plugins.json"
mkdir -p "$mock_plugins_dir"

# Override HOME temporarily for this test
_orig_home="$HOME"
export HOME="$mock_plugins_dir"
mkdir -p "$mock_plugins_dir/.claude/plugins"

cat >"$mock_plugins_json" <<'JSONEOF'
{
  "plugins": {
    "test-plugin@repo": [
      {"version": "1.2.3", "installPath": "/tmp/test"}
    ],
    "hash-plugin@repo": [
      {"version": "d6947b6f35ad", "installPath": "/tmp/hash"}
    ]
  }
}
JSONEOF

ver_result=$(_dep_installed_version "test-plugin@repo")
assert_contains "$ver_result" "1.2.3"

hash_result=$(_dep_installed_version "hash-plugin@repo")
assert_contains "$hash_result" "d6947b6f35ad"

missing_result=$(_dep_installed_version "nonexistent@repo")
assert_not_contains "$missing_result" "."

# Test 5: dep_patch_compat gates patched plugin upgrade
# superpowers 5.1.0 vs manifest 5.1.0 → compatible → should skip
dep_patch_compat "5.1.0" "5.1.0" && compat_result="yes" || compat_result="no"
assert_contains "$compat_result" "yes"

# superpowers 5.2.0 vs manifest 5.1.0 → incompatible → should NOT skip
dep_patch_compat "5.2.0" "5.1.0" && compat_result="yes" || compat_result="no"
assert_contains "$compat_result" "no"

# superpowers 5.1.5 vs manifest 5.1.0 → compatible (same major.minor)
dep_patch_compat "5.1.5" "5.1.0" && compat_result="yes" || compat_result="no"
assert_contains "$compat_result" "yes"

# Restore HOME
export HOME="$_orig_home"
```

- [ ] **Step 2: Run tests to verify**

Run: `bash tests/codesop-update.sh`
Expected: PASS

- [ ] **Step 3: Run full test suite**

Run: `bash tests/run_all.sh`
Expected: all PASS

- [ ] **Step 4: Commit**

```bash
git add tests/codesop-update.sh
git commit -m "test: add _dep_installed_version and dep_patch_compat tests"
```

---

### Task 5: Version bump and CHANGELOG

**Files:**
- Modify: `VERSION`
- Modify: `CHANGELOG.md`
- Modify: `skill.json` (if version field exists)

- [ ] **Step 1: Bump VERSION to 3.9.7**

Write `VERSION`:
```
3.9.7
```

- [ ] **Step 2: Add CHANGELOG entry**

Insert after `## [Unreleased]` in `CHANGELOG.md`:

```markdown
## [3.9.7] - 2026-05-07

### Fixed
- `upgrade_managed_deps` timeout false-positive: non-patched plugins that are already at latest no longer reported as "failed"
- Patched plugin (superpowers) upgrade gate: skip `claude plugin update` when installed version is already compatible with manifest, preventing accidental major.minor jumps that break patches
- Clarify superpowers version incompatibility warning message

### Changed
- `upgrade_managed_deps` reporting now uses 4 categories: 已升级 / 已是最新 / 超时未变 / 失败
- New `_dep_installed_version()` helper reads plugin version from `installed_plugins.json`
- `_dep_upgrade_one()` uses before/after version comparison to detect successful upgrades despite non-zero exit codes
```

- [ ] **Step 3: Sync skill.json version if it exists**

Check and update version in `skill.json` to `3.9.7` if present.

- [ ] **Step 4: Commit**

```bash
git add VERSION CHANGELOG.md skill.json
git commit -m "chore: bump v3.9.7"
```

---

### Task 6: Update docs (CLAUDE.md, PRD.md, README.md)

**Files:**
- Modify: `PRD.md` (progress section)
- Assess: `CLAUDE.md`, `README.md`

- [ ] **Step 1: Update PRD.md progress**

In PRD.md §1 "当前快照", update:
- 当前里程碑 → v3.9.7
- 最后更新原因 → v3.9.7 — 修复 upgrade_managed_deps 超时误报 + 补丁兼容性门禁

In PRD.md §2.4 "Done Recently", prepend:
```
- [x] v3.9.7: 升级可靠性 — patched 插件门禁（防补丁失效）、非 patched 版本对比（消超时误报）、4 类报告
```

- [ ] **Step 2: Assess CLAUDE.md**

Check if Key Gotchas section needs updating for the new behavior. Add note about `_dep_installed_version` and patched gate if architecturally relevant.

- [ ] **Step 3: Assess README.md**

README likely does not need changes (no user-facing command changes, only internal upgrade logic).

- [ ] **Step 4: Commit**

```bash
git add PRD.md CLAUDE.md
git commit -m "docs: update PRD for v3.9.7"
```

---

### Task 7: Run setup sync and full verification

**Files:**
- No file changes, verification only

- [ ] **Step 1: Run setup to sync host integration**

Run: `bash setup --host claude`
Expected: successful sync

- [ ] **Step 2: Run full test suite**

Run: `bash tests/run_all.sh`
Expected: all PASS

- [ ] **Step 3: Verify upgrade_managed_deps output format**

Run a dry check of `upgrade_managed_deps` by sourcing the library:
```bash
source lib/updates.sh && ROOT_DIR="$(pwd)" VERSION_FILE="$(pwd)/VERSION" upgrade_managed_deps
```
Expected: 4-category output with superpowers in "已是最新" category
