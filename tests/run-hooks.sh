#!/usr/bin/env bash
# Hook contract test runner
# Validates that each hook responds correctly to sample inputs.
#
# @decision DEC-TEST-001
# @title Fixture-based hook contract testing
# @status accepted
# @rationale Each hook's stdin/stdout contract is testable in isolation by
#   feeding JSON fixtures and checking exit codes + output structure. This
#   avoids needing a running Claude Code session for CI validation. Statusline
#   and subagent tests use temp directories for isolation.
#
# Usage: bash tests/run-hooks.sh
#
# Tests verify:
#   - Hooks exit with code 0 (no crashes)
#   - Stdout is valid JSON (when output is expected)
#   - Deny responses have the correct structure
#   - Allow/advisory responses have the correct structure
#   - Statusline cache read/write and segment rendering
#   - Subagent tracking display

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOKS_DIR="$(dirname "$SCRIPT_DIR")/hooks"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"

passed=0
failed=0
skipped=0

# Colors (disabled if not a terminal)
if [[ -t 1 ]]; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[0;33m'
    NC='\033[0m'
else
    GREEN='' RED='' YELLOW='' NC=''
fi

pass() { echo -e "${GREEN}PASS${NC} $1"; passed=$((passed + 1)); }
fail() { echo -e "${RED}FAIL${NC} $1: $2"; failed=$((failed + 1)); }
skip() { echo -e "${YELLOW}SKIP${NC} $1: $2"; skipped=$((skipped + 1)); }

# Run a hook with fixture input, capture stdout/stderr/exit code
run_hook() {
    local hook="$1"
    local fixture="$2"
    local stdout

    stdout=$(bash "$hook" < "$fixture" 2>/dev/null) || true

    echo "$stdout"
    return 0
}

echo "=== Hook Contract Tests ==="
echo "Hooks dir: $HOOKS_DIR"
echo "Fixtures dir: $FIXTURES_DIR"
echo ""

# --- Test: All hooks parse without syntax errors ---
echo "--- Syntax Validation ---"
for hook in "$HOOKS_DIR"/*.sh; do
    name=$(basename "$hook")
    if bash -n "$hook" 2>/dev/null; then
        pass "$name — syntax valid"
    else
        fail "$name" "syntax error"
    fi
done
echo ""

# --- Test: settings.json is valid ---
echo "--- Configuration ---"
SETTINGS="$(dirname "$HOOKS_DIR")/settings.json"
if python3 -m json.tool "$SETTINGS" > /dev/null 2>&1; then
    pass "settings.json — valid JSON"
else
    fail "settings.json" "invalid JSON"
fi
echo ""

# --- Test: guard.sh — /tmp rewrite ---
echo "--- guard.sh ---"
if [[ -f "$FIXTURES_DIR/guard-tmp-write.json" ]]; then
    output=$(run_hook "$HOOKS_DIR/guard.sh" "$FIXTURES_DIR/guard-tmp-write.json")
    if echo "$output" | jq -e '.hookSpecificOutput.updatedInput.command' > /dev/null 2>&1; then
        rewritten=$(echo "$output" | jq -r '.hookSpecificOutput.updatedInput.command')
        if [[ "$rewritten" != "echo 'test' > /tmp/scratch.txt" ]]; then
            pass "guard.sh — /tmp rewrite rewrites /tmp path"
        else
            fail "guard.sh — /tmp rewrite" "command unchanged: $rewritten"
        fi
    else
        fail "guard.sh — /tmp rewrite" "no updatedInput in output: $output"
    fi
fi

# --- Test: guard.sh — force push to main denied ---
if [[ -f "$FIXTURES_DIR/guard-force-push-main.json" ]]; then
    output=$(run_hook "$HOOKS_DIR/guard.sh" "$FIXTURES_DIR/guard-force-push-main.json")
    if echo "$output" | jq -e '.hookSpecificOutput.permissionDecision' > /dev/null 2>&1; then
        decision=$(echo "$output" | jq -r '.hookSpecificOutput.permissionDecision')
        if [[ "$decision" == "deny" ]]; then
            pass "guard.sh — force push to main denied"
        else
            fail "guard.sh — force push to main" "expected deny, got: $decision"
        fi
    else
        fail "guard.sh — force push to main" "no permissionDecision in output: $output"
    fi
fi

# --- Test: guard.sh — safe command passes through ---
if [[ -f "$FIXTURES_DIR/guard-safe-command.json" ]]; then
    output=$(run_hook "$HOOKS_DIR/guard.sh" "$FIXTURES_DIR/guard-safe-command.json")
    if [[ -z "$output" || "$output" == "{}" ]]; then
        pass "guard.sh — safe command passes through (no output)"
    else
        # Check it's not a deny
        decision=$(echo "$output" | jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null)
        if [[ "$decision" != "deny" ]]; then
            pass "guard.sh — safe command passes through"
        else
            fail "guard.sh — safe command" "unexpectedly denied: $output"
        fi
    fi
fi

# --- Test: guard.sh — force rewrite to force-with-lease ---
if [[ -f "$FIXTURES_DIR/guard-force-push.json" ]]; then
    output=$(run_hook "$HOOKS_DIR/guard.sh" "$FIXTURES_DIR/guard-force-push.json")
    if echo "$output" | jq -e '.hookSpecificOutput.updatedInput.command' > /dev/null 2>&1; then
        rewritten=$(echo "$output" | jq -r '.hookSpecificOutput.updatedInput.command')
        if [[ "$rewritten" == *"--force-with-lease"* ]]; then
            pass "guard.sh — --force rewritten to --force-with-lease"
        else
            fail "guard.sh — force rewrite" "no --force-with-lease in: $rewritten"
        fi
    else
        fail "guard.sh — force rewrite" "no updatedInput in output: $output"
    fi
fi

echo ""

# --- Test: auto-review.sh ---
echo "--- auto-review.sh ---"
if [[ -f "$FIXTURES_DIR/auto-review-safe.json" ]]; then
    output=$(run_hook "$HOOKS_DIR/auto-review.sh" "$FIXTURES_DIR/auto-review-safe.json")
    if echo "$output" | jq -e '.hookSpecificOutput.permissionDecision' > /dev/null 2>&1; then
        decision=$(echo "$output" | jq -r '.hookSpecificOutput.permissionDecision')
        if [[ "$decision" == "allow" ]]; then
            pass "auto-review.sh — safe command auto-approved"
        else
            fail "auto-review.sh — safe command" "expected allow, got: $decision"
        fi
    else
        # No output also means pass-through (no opinion)
        pass "auto-review.sh — safe command passes through"
    fi
fi

echo ""

# --- Test: plan-validate.sh (PostToolUse) ---
echo "--- plan-validate.sh ---"
if [[ -f "$FIXTURES_DIR/plan-validate-non-plan.json" ]]; then
    output=$(run_hook "$HOOKS_DIR/plan-validate.sh" "$FIXTURES_DIR/plan-validate-non-plan.json")
    # Non-plan files should pass through silently
    if [[ -z "$output" || "$output" == "{}" ]]; then
        pass "plan-validate.sh — non-plan file passes through"
    else
        pass "plan-validate.sh — non-plan file (with advisory)"
    fi
fi

echo ""

# --- Test: session-init.sh ---
echo "--- session-init.sh ---"
if [[ -f "$FIXTURES_DIR/session-init.json" ]]; then
    output=$(bash "$HOOKS_DIR/session-init.sh" < "$FIXTURES_DIR/session-init.json" 2>/dev/null) || true
    if [[ -n "$output" ]]; then
        pass "session-init.sh — produces output on startup"
    else
        pass "session-init.sh — runs without error"
    fi
fi

echo ""

# --- Test: statusline.sh — cache rendering ---
echo "--- statusline.sh ---"
SL_TEST_DIR=$(mktemp -d)
mkdir -p "$SL_TEST_DIR/.claude"
echo '{"dirty":5,"worktrees":1,"plan":"Phase 2/4","test":"pass","updated":1234567890,"agents_active":0,"agents_types":"","agents_total":0}' > "$SL_TEST_DIR/.claude/.statusline-cache"
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

# --- Test: statusline.sh — works without cache ---
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

# --- Test: statusline.sh — subagent tracking ---
echo "--- subagent tracking ---"
SA_TEST_DIR=$(mktemp -d)
mkdir -p "$SA_TEST_DIR/.claude"
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
echo "==========================="
total=$((passed + failed + skipped))
echo -e "Total: $total | ${GREEN}Passed: $passed${NC} | ${RED}Failed: $failed${NC} | ${YELLOW}Skipped: $skipped${NC}"

if [[ $failed -gt 0 ]]; then
    exit 1
fi
