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
for skill in brainstorming writing-plans subagent-driven-development verification-before-completion systematic-debugging finishing-a-development-branch code-review; do
  if ! grep -q "$skill" "$ROOT_DIR/config/codesop-router.md"; then
    fail "Mandatory skill '$skill' from pipeline missing in router card"
  fi
done
echo "  PASS"

# Test 3: Router card length
echo "Test 3: Router card length..."
lines=$(wc -l < "$ROOT_DIR/config/codesop-router.md" | tr -d ' ')
[ "$lines" -le 70 ] || fail "Router card is $lines lines (max 70 for v2 lifecycle table)"
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

# Test 6: SKILL.md has workbench format
echo "Test 6: SKILL.md has workbench format..."
grep -q "Workflow Router" "$ROOT_DIR/SKILL.md" || fail "Workflow Router title missing from SKILL.md"
grep -q "工作台摘要" "$ROOT_DIR/SKILL.md" || fail "Workbench summary template missing from SKILL.md"
grep -q "下一步建议" "$ROOT_DIR/SKILL.md" || fail "Next-step recommendation template missing from SKILL.md"
grep -q "自然语言工作流指令" "$ROOT_DIR/SKILL.md" || fail "Final workflow-instruction rule missing from SKILL.md"
grep -q "document drift scan" "$ROOT_DIR/SKILL.md" || fail "Missing document drift scan guidance"
grep -q "1 to 3 skills in sequence" "$ROOT_DIR/SKILL.md" || fail "Missing multi-skill workflow instruction rule"
grep -q "cleanup-first workflow" "$ROOT_DIR/SKILL.md" || fail "Missing dirty-worktree priority rule"
grep -q "Case A — Dirty worktree" "$ROOT_DIR/SKILL.md" || fail "Missing dirty-worktree example"
grep -q "Case B — Clean worktree" "$ROOT_DIR/SKILL.md" || fail "Missing clean-worktree example"
echo "  PASS"

# Test 7: Hook schema is correct
echo "Test 7: Hook schema uses correct format..."
grep -q '"matcher"' "$ROOT_DIR/setup" || fail "Hook config missing 'matcher' field"
grep -q '"hooks".*"type".*"command"' "$ROOT_DIR/setup" || fail "Hook config missing nested hooks array"
echo "  PASS"

# Test 8: Iron Laws section exists
echo "Test 8: Iron Laws section..."
grep -q "Iron Laws" "$ROOT_DIR/SKILL.md" || fail "Iron Laws section missing from SKILL.md"
echo "  PASS"

# Test 8.5: Key skills from router table are referenced in SKILL.md
echo "Test 8.5: Key skills referenced in SKILL.md..."
for skill in brainstorming subagent-driven-development verification-before-completion; do
  if ! grep -q "$skill" "$ROOT_DIR/SKILL.md"; then
    fail "Key skill '$skill' from router table not referenced in SKILL.md"
  fi
done
echo "  PASS"

echo ""
echo "--- Integration Tests ---"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
test_home="$tmpdir/home"
mkdir -p "$test_home/.claude"
HOME="$test_home" bash "$ROOT_DIR/setup" --host claude >/dev/null 2>&1 || fail "setup --host claude failed in test home"
echo ""

# Test 9: Router card installed to ~/.claude/
echo "Test 9: Router card installed..."
[ -f "$test_home/.claude/codesop-router.md" ] || fail "~/.claude/codesop-router.md not installed"
diff -q "$ROOT_DIR/config/codesop-router.md" "$test_home/.claude/codesop-router.md" >/dev/null 2>&1 || fail "Installed router card differs from source"
echo "  PASS"

# Test 9.5: /codesop command installed from SKILL.md
echo "Test 9.5: /codesop command installed from SKILL.md..."
[ -f "$test_home/.claude/commands/codesop.md" ] || fail "~/.claude/commands/codesop.md not installed"
diff -q "$ROOT_DIR/SKILL.md" "$test_home/.claude/commands/codesop.md" >/dev/null 2>&1 || fail "Installed /codesop command differs from SKILL.md"
echo "  PASS"

# Test 10: Settings.json has correct hook
echo "Test 10: Settings hook configured..."
if command -v jq >/dev/null 2>&1; then
  hook_count=$(jq '[.hooks.SessionStart // [] | .[] | select(.hooks // [] | .[]?.command | type == "string" and test("codesop-router"))] | length' "$test_home/.claude/settings.json" 2>/dev/null || echo "0")
  [ "$hook_count" -ge 1 ] || fail "codesop-router hook not found in settings.json"
  echo "  PASS"
else
  echo "  SKIP (jq not available)"
fi

# Test 11: Idempotency
echo "Test 11: Idempotency..."
HOME="$test_home" bash "$ROOT_DIR/setup" --host claude >/dev/null 2>&1
if command -v jq >/dev/null 2>&1; then
  hook_count=$(jq '[.hooks.SessionStart // [] | .[] | select(.hooks // [] | .[]?.command | type == "string" and test("codesop-router"))] | length' "$test_home/.claude/settings.json" 2>/dev/null || echo "0")
  [ "$hook_count" -le 1 ] || fail "Hook duplicated after second setup run (idempotency broken)"
  echo "  PASS"
else
  echo "  SKIP (jq not available)"
fi

echo ""
echo "All tests passed."
