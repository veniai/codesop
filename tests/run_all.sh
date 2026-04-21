#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

suites=(
  codesop-router.sh
  detect-environment.sh
  setup.sh
  codesop-init.sh
  codesop-init-interview.sh
  codesop-symlink.sh
  codesop-update.sh
  skill-routing-coverage.sh
  codesop-e2e.sh
)

passed=0
failed=0
failures=()

for suite in "${suites[@]}"; do
  if bash "$ROOT_DIR/tests/$suite" >/dev/null 2>&1; then
    passed=$((passed + 1))
    echo "  PASS  $suite"
  else
    failed=$((failed + 1))
    failures+=("$suite")
    echo "  FAIL  $suite"
  fi
done

echo ""
echo "Results: $passed passed, $failed failed"

if [ "$failed" -gt 0 ]; then
  echo "Failures: ${failures[*]}"
  exit 1
fi
