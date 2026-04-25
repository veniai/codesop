#!/usr/bin/env bash

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  printf '%s' "$haystack" | grep -qF -- "$needle" || fail "expected to contain: $needle"
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  printf '%s' "$haystack" | grep -qF -- "$needle" && fail "expected NOT to contain: $needle" || true
}
