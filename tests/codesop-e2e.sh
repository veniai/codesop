#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$ROOT_DIR/codesop"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"

  if [[ "$haystack" != *"$needle"* ]]; then
    fail "expected output to contain: $needle"
  fi
}

usage_output="$(bash "$CLI" 2>&1)"
assert_contains "$usage_output" "Usage:"
assert_contains "$usage_output" "codesop init [path]"
assert_contains "$usage_output" "codesop setup [--host X]"
assert_contains "$usage_output" "codesop update"

if unknown_output="$(bash "$CLI" status 2>&1)"; then
  fail "expected removed status subcommand to fail"
fi

assert_contains "$unknown_output" "未知子命令：status"
assert_contains "$unknown_output" "Usage:"

if version_output="$(bash "$CLI" version 2>&1)"; then
  fail "expected removed version subcommand to fail"
fi

assert_contains "$version_output" "未知子命令：version"
assert_contains "$version_output" "Usage:"

echo "PASS"
