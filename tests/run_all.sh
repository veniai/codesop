#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

suites=(
  codesop-router.sh
  detect-environment.sh
  detect-understand.sh
  setup.sh
  codesop-init.sh
  init-deadcode-removed.sh
  consistency-guards.sh
  codesop-symlink.sh
  codesop-update.sh
  codesop-uninstall.sh
  skill-routing-coverage.sh
  spec-as-goal-behavior.sh
  first-principles-behavior.sh
  adversarial-review-behavior.sh
  setup-patch-sync.sh
  dep-upgrade.sh
  codesop-e2e.sh
)

passed=0
failed=0
failures=()

for suite in "${suites[@]}"; do
  if output=$(bash "$ROOT_DIR/tests/$suite" 2>&1); then
    passed=$((passed + 1))
    echo "  PASS  $suite"
  else
    failed=$((failed + 1))
    failures+=("$suite")
    echo "  FAIL  $suite"
    echo "$output"
  fi
done

echo ""
echo "Results: $passed passed, $failed failed"

if [ "$failed" -gt 0 ]; then
  echo "Failures: ${failures[*]}"
  exit 1
fi
