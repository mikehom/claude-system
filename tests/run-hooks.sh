#!/usr/bin/env bash
# run-hooks.sh — Test harness for Claude Code hooks
#
# Purpose: Integration tests for hooks and scripts. Tests run in isolated
# environments (temp directories) and verify hook behavior without polluting
# the actual project state.
#
# @decision DEC-TEST-001
# @title Integration tests for hook and script behavior
# @status accepted
# @rationale Test the actual implementations (statusline cache read/write, hook
# output) rather than mocking. Use temp directories for isolation. Tests verify
# the cache format, graceful degradation without cache, and multi-segment rendering.
#
# Usage: bash tests/run-hooks.sh
#
# Exit codes: 0=all pass, 1=any failure
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PASS_COUNT=0
FAIL_COUNT=0

# Test result tracking
pass() {
    echo "✓ $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
    echo "✗ $1"
    echo "  $2"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

# --- statusline.sh ---
echo "--- statusline.sh ---"
# Create temp dir for test
SL_TEST_DIR=$(mktemp -d)
mkdir -p "$SL_TEST_DIR/.claude"
echo '{"dirty":5,"worktrees":1,"plan":"Phase 2/4","test":"pass","updated":1234567890}' > "$SL_TEST_DIR/.claude/.statusline-cache"
SL_INPUT=$(jq -n --arg dir "$SL_TEST_DIR" '{model:{display_name:"opus"},workspace:{current_dir:$dir},version:"1.0.0"}')
SL_OUTPUT=$(echo "$SL_INPUT" | bash "$SCRIPT_DIR/../scripts/statusline.sh" 2>/dev/null) || true
if echo "$SL_OUTPUT" | grep -q "dirty"; then
    pass "statusline.sh — shows dirty count from cache"
else
    fail "statusline.sh — dirty count" "expected 'dirty' in output: $SL_OUTPUT"
fi
if echo "$SL_OUTPUT" | grep -q "WT:"; then
    pass "statusline.sh — shows worktree count from cache"
else
    fail "statusline.sh — worktree count" "expected 'WT:' in output: $SL_OUTPUT"
fi
if echo "$SL_OUTPUT" | grep -q "Phase"; then
    pass "statusline.sh — shows plan phase from cache"
else
    fail "statusline.sh — plan phase" "expected 'Phase' in output: $SL_OUTPUT"
fi
if echo "$SL_OUTPUT" | grep -q "tests"; then
    pass "statusline.sh — shows test status from cache"
else
    fail "statusline.sh — test status" "expected 'tests' in output: $SL_OUTPUT"
fi
rm -rf "$SL_TEST_DIR"
echo ""

SL_TEST_DIR2=$(mktemp -d)
SL_INPUT2=$(jq -n --arg dir "$SL_TEST_DIR2" '{model:{display_name:"opus"},workspace:{current_dir:$dir},version:"1.0.0"}')
SL_OUTPUT2=$(echo "$SL_INPUT2" | bash "$SCRIPT_DIR/../scripts/statusline.sh" 2>/dev/null) || true
if [[ -n "$SL_OUTPUT2" ]]; then
    pass "statusline.sh — works without cache file"
else
    fail "statusline.sh — no cache" "no output produced"
fi
rm -rf "$SL_TEST_DIR2"
echo ""

# --- subagent tracking ---
echo "--- subagent tracking ---"
SA_TEST_DIR=$(mktemp -d)
mkdir -p "$SA_TEST_DIR/.claude"
# Create mock tracker with 2 active and 1 done
cat > "$SA_TEST_DIR/.claude/.subagent-tracker" << 'TRACKER'
ACTIVE|planner|1234567890
ACTIVE|implementer|1234567891
DONE|guardian|1234567880|30
TRACKER

# Create cache with subagent data
echo '{"dirty":0,"worktrees":0,"plan":"no plan","test":"unknown","updated":1234567890,"agents_active":2,"agents_types":"implementer,planner","agents_total":3}' > "$SA_TEST_DIR/.claude/.statusline-cache"
SA_INPUT=$(jq -n --arg dir "$SA_TEST_DIR" '{model:{display_name:"opus"},workspace:{current_dir:$dir},version:"1.0.0"}')
SA_OUTPUT=$(echo "$SA_INPUT" | bash "$SCRIPT_DIR/../scripts/statusline.sh" 2>/dev/null) || true
if echo "$SA_OUTPUT" | grep -q "agents"; then
    pass "statusline.sh — shows active agent count from cache"
else
    fail "statusline.sh — agent count" "expected 'agents' in output: $SA_OUTPUT"
fi
rm -rf "$SA_TEST_DIR"
echo ""

# --- Summary ---
echo "========================================="
echo "Total: $((PASS_COUNT + FAIL_COUNT)) tests"
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"
echo "========================================="

if [[ "$FAIL_COUNT" -gt 0 ]]; then
    exit 1
fi

exit 0
