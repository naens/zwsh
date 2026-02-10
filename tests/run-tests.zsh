#!/usr/bin/env zsh
# Simple test runner for zwsh
# Usage: zsh tests/run-tests.zsh [test-dir...]
# If no arguments, runs all test directories under tests/

set -e

# Stub ZLE commands (not available outside line editor)
zle() { : }
bindkey() { : }

srcdir=$(cd "$(dirname "$0")/.." && pwd)
testdir="$srcdir/tests"

# Source modules needed for tests (order matters: wsfun first for helpers)
. "$srcdir/wsfun.zsh"
. "$srcdir/wstxtfun.zsh"
. "$srcdir/wstext.zsh"
. "$srcdir/wsblock.zsh"

# Test counters
typeset -i total=0 passed=0 failed=0

# Assert function: assert_eq <actual> <expected> <description>
assert_eq() {
    local actual="$1"
    local expected="$2"
    local desc="$3"
    total=$((total+1))
    if [[ "$actual" = "$expected" ]]; then
        passed=$((passed+1))
    else
        failed=$((failed+1))
        echo "  FAIL: $desc"
        echo "    expected: '$expected'"
        echo "    actual:   '$actual'"
    fi
}

# Run all .zsh files in a test directory (skip files without assert_eq)
run_test_dir() {
    local dir="$1"
    local name=$(basename "$dir")
    echo "--- $name ---"
    for f in "$dir"/*.zsh; do
        [[ -f "$f" ]] || continue
        grep -q 'assert_eq' "$f" || continue
        echo "  $(basename $f)"
        . "$f"
    done
}

# Determine which test directories to run
if [[ $# -gt 0 ]]; then
    dirs=("$@")
else
    dirs=()
    for d in "$testdir"/*/; do
        [[ -d "$d" ]] && dirs+=("$d")
    done
fi

echo "=== zwsh tests ==="
echo ""

for d in "${dirs[@]}"; do
    run_test_dir "$d"
done

echo ""
echo "=== Results: $passed/$total passed, $failed failed ==="
if [[ $failed -gt 0 ]]; then
    exit 1
fi
