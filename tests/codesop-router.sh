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
[ "$lines" -le 72 ] || fail "Router card is $lines lines (max 72 for v2 lifecycle table)"
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
grep -q "文档状态" "$ROOT_DIR/SKILL.md" || fail "Project document status missing from SKILL.md"
grep -q "下一步建议" "$ROOT_DIR/SKILL.md" || fail "Next-step recommendation template missing from SKILL.md"
grep -q "workflow instruction" "$ROOT_DIR/SKILL.md" || fail "Final workflow-instruction rule missing from SKILL.md"
grep -q "document drift scan" "$ROOT_DIR/SKILL.md" || fail "Missing document drift scan guidance"
grep -q "check_project_document_drift" "$ROOT_DIR/SKILL.md" || fail "Missing current-project doc drift function reference"
grep -q "场景适配" "$ROOT_DIR/SKILL.md" || fail "Missing scenario adaptation rules"
grep -q "cleanup-first\|前置.*finishing" "$ROOT_DIR/SKILL.md" || fail "Missing dirty-worktree priority rule"
grep -q "Complete Example" "$ROOT_DIR/SKILL.md" || fail "Missing complete output example"
grep -q "提议 Pipeline" "$ROOT_DIR/SKILL.md" || fail "Missing proposing pipeline format"
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

# Test 8.5: Chain assembly rules exist in routing table
echo "Test 8.5: Chain assembly rules in routing table..."
grep -q "链路组装" "$ROOT_DIR/config/codesop-router.md" || fail "链路组装 section missing from routing table"
grep -q "code-simplifier" "$ROOT_DIR/config/codesop-router.md" || fail "code-simplifier insertion rule missing"
grep -q "claude-md-management" "$ROOT_DIR/config/codesop-router.md" || fail "claude-md-management insertion rule missing"
echo "  PASS"

# Test 8.6: Key skills from router table are referenced in SKILL.md
echo "Test 8.6: Key skills referenced in SKILL.md..."
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

# Test 9.5: /codesop skill registered from SKILL.md
echo "Test 9.5: /codesop skill registered from SKILL.md..."
[ -f "$test_home/.claude/skills/codesop/SKILL.md" ] || fail "~/.claude/skills/codesop/SKILL.md not installed"
diff -q "$ROOT_DIR/SKILL.md" "$test_home/.claude/skills/codesop/SKILL.md" >/dev/null 2>&1 || fail "Installed codesop skill differs from SKILL.md"
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

# Test 12: statusLine configured
echo "Test 12: statusLine configured for context tracking..."
if command -v jq >/dev/null 2>&1; then
  statusline_cmd=$(jq -r '.statusLine.command // ""' "$test_home/.claude/settings.json" 2>/dev/null || echo "")
  [[ "$statusline_cmd" == *"tee /tmp/claude-context.json"* ]] || fail "statusLine missing tee to /tmp/claude-context.json"
  echo "  PASS"
else
  echo "  SKIP (jq not available)"
fi

# Test 13: statusLine idempotency
echo "Test 13: statusLine idempotency..."
HOME="$test_home" bash "$ROOT_DIR/setup" --host claude >/dev/null 2>&1
if command -v jq >/dev/null 2>&1; then
  statusline_cmd=$(jq -r '.statusLine.command // ""' "$test_home/.claude/settings.json" 2>/dev/null || echo "")
  [[ "$statusline_cmd" == *"tee /tmp/claude-context.json"* ]] || fail "statusLine lost after second setup run"
  # Verify no duplicate statusLine keys (jq would have overwritten, not duplicated)
  statusline_count=$(jq 'if .statusLine then 1 else 0 end' "$test_home/.claude/settings.json" 2>/dev/null || echo "0")
  [ "$statusline_count" -le 1 ] || fail "statusLine duplicated after second setup"
  echo "  PASS"
else
  echo "  SKIP (jq not available)"
fi

echo ""
echo "All tests passed."
