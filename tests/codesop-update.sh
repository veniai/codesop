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

echo "PASS"
