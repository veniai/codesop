#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/updates.sh"
source "$(dirname "$0")/test_helpers.sh"

init_repo_fixture() {
  local case_dir="$1"
  local seed_dir="$case_dir/seed"
  local remote_dir="$case_dir/remote.git"
  local local_dir="$case_dir/local"
  local updater_dir="$case_dir/updater"

  mkdir -p "$case_dir"
  git init -q -b main "$seed_dir"
  git -C "$seed_dir" config user.name "codesop-tests"
  git -C "$seed_dir" config user.email "codesop-tests@example.com"

  cat >"$seed_dir/VERSION" <<'EOF'
1.1.1
EOF

  cat >"$seed_dir/CHANGELOG.md" <<'EOF'
# Changelog

## [1.1.1] - 2026-03-30

### Added
- Initial release
EOF

  echo "seed" > "$seed_dir/README.md"

  git -C "$seed_dir" add VERSION CHANGELOG.md README.md
  git -C "$seed_dir" commit -q -m "seed"

  git clone -q --bare "$seed_dir" "$remote_dir"
  git clone -q "$remote_dir" "$local_dir"
  git clone -q "$remote_dir" "$updater_dir"
  git -C "$updater_dir" config user.name "codesop-tests"
  git -C "$updater_dir" config user.email "codesop-tests@example.com"

  printf '%s\n' "$local_dir"
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# Test 1: same VERSION, but upstream has new commits
same_version_case="$tmpdir/same-version"
local_repo="$(init_repo_fixture "$same_version_case")"
updater_repo="$same_version_case/updater"

echo "new behavior" >> "$updater_repo/README.md"
git -C "$updater_repo" add README.md
git -C "$updater_repo" commit -q -m "add behavior note"
git -C "$updater_repo" push -q

same_version_output="$(git_update_check "$local_repo" "codesop" "git pull")"
assert_contains "$same_version_output" "发现 1 个待更新提交"
assert_contains "$same_version_output" "add behavior note"
assert_contains "$same_version_output" "更新命令：git pull"
assert_not_contains "$same_version_output" "已是最新"

# Test 2: upstream bumps VERSION
version_bump_case="$tmpdir/version-bump"
local_repo="$(init_repo_fixture "$version_bump_case")"
updater_repo="$version_bump_case/updater"

cat >"$updater_repo/VERSION" <<'EOF'
1.1.2
EOF

cat >"$updater_repo/CHANGELOG.md" <<'EOF'
# Changelog

## [1.1.2] - 2026-03-30

### Changed
- Ship release

## [1.1.1] - 2026-03-30

### Added
- Initial release
EOF

git -C "$updater_repo" add VERSION CHANGELOG.md
git -C "$updater_repo" commit -q -m "release 1.1.2"
git -C "$updater_repo" push -q

version_bump_output="$(git_update_check "$local_repo" "codesop" "git pull")"
assert_contains "$version_bump_output" "1.1.1 → 1.1.2（发现新版本）"
assert_contains "$version_bump_output" "Ship release"
assert_contains "$version_bump_output" "更新命令：git pull"

# Test 3: already latest
latest_case="$tmpdir/latest"
local_repo="$(init_repo_fixture "$latest_case")"

latest_output="$(git_update_check "$local_repo" "codesop" "git pull")"
assert_contains "$latest_output" "1.1.1（已是最新）"

# Test 4: _dep_installed_version reads from plugins.json
mock_plugins_dir="$tmpdir/mock-plugins"
mock_plugins_json_dir="$mock_plugins_dir/.claude/plugins"
mkdir -p "$mock_plugins_json_dir"

# Override HOME temporarily for this test
_orig_home="$HOME"
export HOME="$mock_plugins_dir"

cat >"$mock_plugins_json_dir/installed_plugins.json" <<'JSONEOF'
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

# Restore HOME
export HOME="$_orig_home"

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

echo "PASS"
