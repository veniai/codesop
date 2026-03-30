#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

echo "=== codesop-router consistency tests ==="
echo ""

# Test 1: Router card file exists
echo "Test 1: Router card exists..."
[ -f "$ROOT_DIR/config/codesop-router.md" ] || fail "config/codesop-router.md not found"
echo "  PASS"

# Test 2: Mandatory skills consistency
echo "Test 2: Mandatory skills consistency..."
for skill in brainstorming writing-plans autoplan using-git-worktrees subagent-driven-development test-driven-development verification-before-completion review ship document-release; do
  if ! grep -q "$skill" "$ROOT_DIR/config/codesop-router.md"; then
    fail "Mandatory skill '$skill' from pipeline missing in router card"
  fi
done
echo "  PASS"

# Test 3: Router card length
echo "Test 3: Router card length..."
lines=$(wc -l < "$ROOT_DIR/config/codesop-router.md" | tr -d ' ')
[ "$lines" -le 50 ] || fail "Router card is $lines lines (max 50 for dilution resistance)"
echo "  PASS ($lines lines)"

# Test 4: Setup has new functions
echo "Test 4: Setup has new functions..."
[ "$(grep -c 'install_router_card' "$ROOT_DIR/setup")" -ge 2 ] || fail "install_router_card not found in setup"
[ "$(grep -c 'configure_hooks' "$ROOT_DIR/setup")" -ge 2 ] || fail "configure_hooks not found in setup"
[ "$(grep -c 'check_discipline_deps' "$ROOT_DIR/setup")" -ge 2 ] || fail "check_discipline_deps not found in setup"
echo "  PASS"

# Test 5: AGENTS.md has discipline section
echo "Test 5: AGENTS.md has discipline section..."
grep -q "Skill 纪律" "$ROOT_DIR/templates/system/AGENTS.md" || fail "Skill discipline section missing from AGENTS.md"
grep -q "任务对齐块" "$ROOT_DIR/templates/system/AGENTS.md" || fail "Task alignment reference missing from AGENTS.md"
echo "  PASS"

# Test 6: codesop.md has workbench format
echo "Test 6: codesop.md has workbench format..."
grep -q "Workflow Router" "$ROOT_DIR/commands/codesop.md" || fail "Workflow Router title missing from codesop.md"
grep -q "工作台摘要" "$ROOT_DIR/commands/codesop.md" || fail "Workbench summary template missing from codesop.md"
grep -q "Skill 建议" "$ROOT_DIR/commands/codesop.md" || fail "Skill recommendation template missing from codesop.md"
echo "  PASS"

# Test 7: Hook schema is correct
echo "Test 7: Hook schema uses correct format..."
grep -q '"matcher"' "$ROOT_DIR/setup" || fail "Hook config missing 'matcher' field"
grep -q '"hooks".*"type".*"command"' "$ROOT_DIR/setup" || fail "Hook config missing nested hooks array"
echo "  PASS"

# Test 8: Iron Laws section exists
echo "Test 8: Iron Laws section..."
grep -q "Iron Laws" "$ROOT_DIR/commands/codesop.md" || fail "Iron Laws section missing from codesop.md"
echo "  PASS"

echo ""
echo "--- Integration Tests ---"
echo "Run 'bash setup --host claude' first."
echo ""

# Test 9: Router card installed to ~/.claude/
echo "Test 9: Router card installed..."
[ -f "$HOME/.claude/codesop-router.md" ] || fail "~/.claude/codesop-router.md not installed. Run: bash setup --host claude"
diff -q "$ROOT_DIR/config/codesop-router.md" "$HOME/.claude/codesop-router.md" >/dev/null 2>&1 || fail "Installed router card differs from source. Run: bash setup --host claude"
echo "  PASS"

# Test 10: Settings.json has correct hook
echo "Test 10: Settings hook configured..."
if command -v jq >/dev/null 2>&1; then
  hook_count=$(jq '[.hooks.SessionStart // [] | .[] | select(.hooks // [] | .[]?.command | type == "string" and test("codesop-router"))] | length' "$HOME/.claude/settings.json" 2>/dev/null || echo "0")
  [ "$hook_count" -ge 1 ] || fail "codesop-router hook not found in settings.json"
  echo "  PASS"
else
  echo "  SKIP (jq not available)"
fi

# Test 11: Idempotency
echo "Test 11: Idempotency..."
bash "$ROOT_DIR/setup" --host claude 2>&1 >/dev/null
if command -v jq >/dev/null 2>&1; then
  hook_count=$(jq '[.hooks.SessionStart // [] | .[] | select(.hooks // [] | .[]?.command | type == "string" and test("codesop-router"))] | length' "$HOME/.claude/settings.json" 2>/dev/null || echo "0")
  [ "$hook_count" -le 1 ] || fail "Hook duplicated after second setup run (idempotency broken)"
  echo "  PASS"
else
  echo "  SKIP (jq not available)"
fi

echo ""
echo "All tests passed."
