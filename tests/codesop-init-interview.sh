#!/bin/bash
# tests/codesop-init-interview.sh - Test init --interview command
#
# Tests for lib/init-interview.sh functions:
# - has_user_preferences()
# - detect_installed_tools()
# - is_simple_reference()
# - is_living_prd()
# - setup_system_links()
# - confirm_and_backup()

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source the library modules in correct order
source "$ROOT_DIR/lib/output.sh"
source "$ROOT_DIR/lib/detection.sh"
source "$ROOT_DIR/lib/templates.sh"
source "$ROOT_DIR/lib/updates.sh"
source "$ROOT_DIR/lib/init-interview.sh"

# Set source_dir for template functions
source_dir="$ROOT_DIR"

# Test utilities
tests_passed=0
tests_failed=0

pass() {
  echo "PASS: $1"
  tests_passed=$((tests_passed + 1))
}

fail() {
  echo "FAIL: $1" >&2
  tests_failed=$((tests_failed + 1))
}

# ============================================================================
# Test 1: has_user_preferences() with placeholders
# ============================================================================
test_has_user_preferences_with_placeholders() {
  local tmpfile
  tmpfile=$(mktemp)
  echo "{LANG} {STYLE}" > "$tmpfile"

  if has_user_preferences "$tmpfile"; then
    fail "has_user_preferences with placeholders - should return 1 (has placeholders)"
  else
    pass "has_user_preferences with placeholders - correctly detected placeholders"
  fi

  rm -f "$tmpfile"
}

# ============================================================================
# Test 2: has_user_preferences() without placeholders
# ============================================================================
test_has_user_preferences_without_placeholders() {
  local tmpfile
  tmpfile=$(mktemp)
  echo "Chinese Standard" > "$tmpfile"

  if has_user_preferences "$tmpfile"; then
    pass "has_user_preferences without placeholders - correctly detected real preferences"
  else
    fail "has_user_preferences without placeholders - should return 0 (no placeholders)"
  fi

  rm -f "$tmpfile"
}

# ============================================================================
# Test 3: has_user_preferences() with all placeholder types
# ============================================================================
test_has_user_preferences_all_placeholders() {
  local tmpfile
  tmpfile=$(mktemp)
  cat > "$tmpfile" <<'EOF'
Language: {LANG}
Style: {STYLE}
Function Length: {FUNC_LENGTH}
Comment Style: {COMMENT_STYLE}
EOF

  if has_user_preferences "$tmpfile"; then
    fail "has_user_preferences all placeholders - should return 1 (has placeholders)"
  else
    pass "has_user_preferences all placeholders - correctly detected all placeholder types"
  fi

  rm -f "$tmpfile"
}

# ============================================================================
# Test 4: has_user_preferences() with missing file
# ============================================================================
test_has_user_preferences_missing_file() {
  if has_user_preferences "/nonexistent/path/to/file.md"; then
    fail "has_user_preferences missing file - should return 1"
  else
    pass "has_user_preferences missing file - correctly handled missing file"
  fi
}

# ============================================================================
# Test 5: detect_installed_tools()
# ============================================================================
test_detect_installed_tools() {
  local tmpdir
  tmpdir=$(mktemp -d)

  # Create fake home directories
  mkdir -p "$tmpdir/.claude"
  mkdir -p "$tmpdir/.codex"
  mkdir -p "$tmpdir/.config/opencode"

  local tools
  tools=$(HOME="$tmpdir" detect_installed_tools)

  if [ -z "$tools" ]; then
    fail "detect_installed_tools - should detect at least one tool"
  else
    pass "detect_installed_tools - returned: $tools"
  fi

  # Check that all expected tools are detected
  if echo "$tools" | grep -q "claude"; then
    pass "detect_installed_tools - claude detected"
  else
    fail "detect_installed_tools - claude not detected"
  fi

  if echo "$tools" | grep -q "codex"; then
    pass "detect_installed_tools - codex detected"
  else
    fail "detect_installed_tools - codex not detected"
  fi

  if echo "$tools" | grep -q "opencode"; then
    pass "detect_installed_tools - opencode detected"
  else
    fail "detect_installed_tools - opencode not detected"
  fi

  rm -rf "$tmpdir"
}

# ============================================================================
# Test 6: detect_installed_tools() with no tools
# ============================================================================
test_detect_installed_tools_empty() {
  local tmpdir
  tmpdir=$(mktemp -d)

  local tools
  tools=$(HOME="$tmpdir" detect_installed_tools)

  if [ -n "$tools" ]; then
    fail "detect_installed_tools empty - should return empty string, got: $tools"
  else
    pass "detect_installed_tools empty - correctly returned empty for no tools"
  fi

  rm -rf "$tmpdir"
}

# ============================================================================
# Test 7: is_simple_reference() with @CLAUDE.md
# ============================================================================
test_is_simple_reference() {
  local tmpfile
  tmpfile=$(mktemp)
  echo "@CLAUDE.md" > "$tmpfile"

  if is_simple_reference "$tmpfile"; then
    pass "is_simple_reference - correctly detected @CLAUDE.md"
  else
    fail "is_simple_reference - should detect @CLAUDE.md as simple reference"
  fi

  rm -f "$tmpfile"
}

# ============================================================================
# Test 8: is_simple_reference() with @./CLAUDE.md
# ============================================================================
test_is_simple_reference_with_dot() {
  local tmpfile
  tmpfile=$(mktemp)
  echo "@./CLAUDE.md" > "$tmpfile"

  if is_simple_reference "$tmpfile"; then
    pass "is_simple_reference with dot - correctly detected @./CLAUDE.md"
  else
    fail "is_simple_reference with dot - should detect @./CLAUDE.md as simple reference"
  fi

  rm -f "$tmpfile"
}

# ============================================================================
# Test 9: is_simple_reference() with complex content
# ============================================================================
test_is_simple_reference_complex() {
  local tmpfile
  tmpfile=$(mktemp)
  cat > "$tmpfile" <<'EOF'
# Project Rules

@CLAUDE.md

## Additional Rules
EOF

  if is_simple_reference "$tmpfile"; then
    fail "is_simple_reference complex - should return 1 for complex content"
  else
    pass "is_simple_reference complex - correctly rejected complex content"
  fi

  rm -f "$tmpfile"
}

# ============================================================================
# Test 10: is_simple_reference() with missing file
# ============================================================================
test_is_simple_reference_missing() {
  if is_simple_reference "/nonexistent/path/to/file.md"; then
    fail "is_simple_reference missing - should return 1 for missing file"
  else
    pass "is_simple_reference missing - correctly handled missing file"
  fi
}

# ============================================================================
# Test 11: is_living_prd() with Chinese sections
# ============================================================================
test_is_living_prd_chinese() {
  local tmpfile
  tmpfile=$(mktemp)
  echo "## 当前快照" > "$tmpfile"

  if is_living_prd "$tmpfile"; then
    pass "is_living_prd Chinese - correctly detected living PRD with 当前快照"
  else
    fail "is_living_prd Chinese - should detect living PRD with 当前快照"
  fi

  rm -f "$tmpfile"
}

# ============================================================================
# Test 12: is_living_prd() with English sections
# ============================================================================
test_is_living_prd_english() {
  local tmpfile
  tmpfile=$(mktemp)
  echo "## Current Snapshot" > "$tmpfile"

  if is_living_prd "$tmpfile"; then
    pass "is_living_prd English - correctly detected living PRD with Current Snapshot"
  else
    fail "is_living_prd English - should detect living PRD with Current Snapshot"
  fi

  rm -f "$tmpfile"
}

# ============================================================================
# Test 13: is_living_prd() with work log
# ============================================================================
test_is_living_prd_worklog() {
  local tmpfile
  tmpfile=$(mktemp)
  echo "## 工作日志" > "$tmpfile"

  if is_living_prd "$tmpfile"; then
    pass "is_living_prd worklog - correctly detected living PRD with 工作日志"
  else
    fail "is_living_prd worklog - should detect living PRD with 工作日志"
  fi

  rm -f "$tmpfile"
}

# ============================================================================
# Test 14: is_living_prd() with non-living PRD
# ============================================================================
test_is_living_prd_static() {
  local tmpfile
  tmpfile=$(mktemp)
  cat > "$tmpfile" <<'EOF'
# Product Requirements

## Overview
This is a static PRD.

## Features
- Feature 1
- Feature 2
EOF

  if is_living_prd "$tmpfile"; then
    fail "is_living_prd static - should return 1 for non-living PRD"
  else
    pass "is_living_prd static - correctly rejected non-living PRD"
  fi

  rm -f "$tmpfile"
}

# ============================================================================
# Test 15: is_living_prd() with missing file
# ============================================================================
test_is_living_prd_missing() {
  if is_living_prd "/nonexistent/path/to/file.md"; then
    fail "is_living_prd missing - should return 1 for missing file"
  else
    pass "is_living_prd missing - correctly handled missing file"
  fi
}

# ============================================================================
# Test 16: ensure_symlink()
# ============================================================================
test_ensure_symlink() {
  local tmpdir
  tmpdir=$(mktemp -d)

  local src_file="$tmpdir/source.md"
  echo "test content" > "$src_file"

  local dst_link="$tmpdir/subdir/link.md"

  ensure_symlink "$src_file" "$dst_link"

  if [ -L "$dst_link" ]; then
    pass "ensure_symlink - symlink created"
  else
    fail "ensure_symlink - symlink not created"
  fi

  # Verify symlink points to correct source
  local resolved
  resolved=$(readlink -f "$dst_link")
  if [ "$resolved" = "$src_file" ]; then
    pass "ensure_symlink - points to correct source"
  else
    fail "ensure_symlink - points to wrong source: $resolved"
  fi

  rm -rf "$tmpdir"
}

# ============================================================================
# Test 17: generate_prd_template()
# ============================================================================
test_generate_prd_template() {
  local prd_content
  prd_content=$(generate_prd_template "TestProject")

  if echo "$prd_content" | grep -q "# Product: TestProject"; then
    pass "generate_prd_template - contains product name"
  else
    fail "generate_prd_template - missing product name"
  fi

  if echo "$prd_content" | grep -q "## 1. 当前快照"; then
    pass "generate_prd_template - contains 当前快照 section"
  else
    fail "generate_prd_template - missing 当前快照 section"
  fi

  if echo "$prd_content" | grep -q "## 3. 最近决策记录"; then
    pass "generate_prd_template - contains 最近决策记录 section"
  else
    fail "generate_prd_template - missing 最近决策记录 section"
  fi
}

# ============================================================================
# Test 21: generate_readme_template()
# ============================================================================
test_generate_readme_template() {
  local readme_content
  readme_content=$(generate_readme_template "TestProject")

  if echo "$readme_content" | grep -q "# TestProject"; then
    pass "generate_readme_template - contains project name"
  else
    fail "generate_readme_template - missing project name"
  fi

  if echo "$readme_content" | grep -q "## 快速开始"; then
    pass "generate_readme_template - contains 快速开始 section"
  else
    fail "generate_readme_template - missing 快速开始 section"
  fi
}

# ============================================================================
# Test 22: check_user_preferences()
# ============================================================================
test_check_user_preferences() {
  local tmpfile
  tmpfile=$(mktemp)

  # Test with placeholders - should return 1 (need interview)
  echo "{LANG} {STYLE}" > "$tmpfile"
  if check_user_preferences "$tmpfile" 2>/dev/null; then
    fail "check_user_preferences - should return 1 when has placeholders"
  else
    pass "check_user_preferences - correctly needs interview for placeholders"
  fi

  # Test without placeholders - should return 0 (skip interview)
  echo "Chinese Standard" > "$tmpfile"
  if check_user_preferences "$tmpfile" 2>/dev/null; then
    pass "check_user_preferences - correctly skips interview for filled preferences"
  else
    fail "check_user_preferences - should return 0 when no placeholders"
  fi

  rm -f "$tmpfile"
}

# ============================================================================
# Run all tests
# ============================================================================
run_tests() {
  echo "========================================"
  echo "  codesop init --interview tests"
  echo "========================================"
  echo ""

  # has_user_preferences tests
  echo "--- has_user_preferences() tests ---"
  test_has_user_preferences_with_placeholders
  test_has_user_preferences_without_placeholders
  test_has_user_preferences_all_placeholders
  test_has_user_preferences_missing_file
  echo ""

  # detect_installed_tools tests
  echo "--- detect_installed_tools() tests ---"
  test_detect_installed_tools
  test_detect_installed_tools_empty
  echo ""

  # is_simple_reference tests
  echo "--- is_simple_reference() tests ---"
  test_is_simple_reference
  test_is_simple_reference_with_dot
  test_is_simple_reference_complex
  test_is_simple_reference_missing
  echo ""

  # is_living_prd tests
  echo "--- is_living_prd() tests ---"
  test_is_living_prd_chinese
  test_is_living_prd_english
  test_is_living_prd_worklog
  test_is_living_prd_static
  test_is_living_prd_missing
  echo ""

  # Tool and utility tests
  echo "--- Tool and utility tests ---"
  test_ensure_symlink
  test_check_user_preferences
  echo ""

  # Template generation tests
  echo "--- Template generation tests ---"
  test_generate_prd_template
  test_generate_readme_template
  echo ""

  # check_user_preferences tests
  echo "--- check_user_preferences() tests ---"
  test_check_user_preferences
  echo ""

  # Summary
  echo "========================================"
  echo "  Test Summary"
  echo "========================================"
  echo "Passed: $tests_passed"
  echo "Failed: $tests_failed"
  echo ""

  if [ $tests_failed -gt 0 ]; then
    echo "RESULT: FAILED"
    exit 1
  else
    echo "RESULT: ALL TESTS PASSED"
    exit 0
  fi
}

run_tests "$@"
