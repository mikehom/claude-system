#!/usr/bin/env bash
set -euo pipefail

# Subagent context injection at spawn time.
# SubagentStart hook — matcher: (all agent types)
#
# Injects current project state into every subagent so Planner,
# Implementer, and Guardian agents always have fresh context:
#   - Current git branch and dirty state
#   - MASTER_PLAN.md existence and active phase
#   - Active worktrees
#   - Agent-type-specific guidance

source "$(dirname "$0")/log.sh"
source "$(dirname "$0")/context-lib.sh"

HOOK_INPUT=$(read_input)
AGENT_TYPE=$(echo "$HOOK_INPUT" | jq -r '.agent_type // empty' 2>/dev/null)

PROJECT_ROOT=$(detect_project_root)
CONTEXT_PARTS=()

# --- Git state (via shared library) ---
get_git_state "$PROJECT_ROOT"

if [[ -n "$GIT_BRANCH" ]]; then
    CONTEXT_PARTS+=("Git branch: $GIT_BRANCH")

    if [[ "$GIT_DIRTY_COUNT" -gt 0 ]]; then
        CONTEXT_PARTS+=("Uncommitted changes: $GIT_DIRTY_COUNT files")
    fi

    if [[ "$GIT_WT_COUNT" -gt 0 ]]; then
        CONTEXT_PARTS+=("Active worktrees: $GIT_WT_COUNT")
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            CONTEXT_PARTS+=("  $line")
        done <<< "$GIT_WORKTREES"
    fi
fi

# --- MASTER_PLAN.md (via shared library) ---
get_plan_status "$PROJECT_ROOT"

if [[ "$PLAN_EXISTS" == "true" ]]; then
    if [[ -n "$PLAN_PHASE" ]]; then
        CONTEXT_PARTS+=("MASTER_PLAN.md: active ($PLAN_PHASE)")
    else
        CONTEXT_PARTS+=("MASTER_PLAN.md: exists")
    fi
else
    CONTEXT_PARTS+=("MASTER_PLAN.md: not found")
fi

# --- Agent-type-specific context ---
case "$AGENT_TYPE" in
    planner|Plan)
        CONTEXT_PARTS+=("Role: Planner — create MASTER_PLAN.md before any code. Include rationale, architecture, git issues, worktree strategy.")
        ;;
    implementer)
        # Check if any worktrees exist for this project
        if [[ "$GIT_WT_COUNT" -eq 0 ]]; then
            CONTEXT_PARTS+=("CRITICAL FIRST ACTION: No worktree detected. You MUST create a git worktree BEFORE writing any code. Run: git worktree add ../\<feature-name\> -b \<feature-name\> main — then cd into the worktree and work there. Do NOT write source code on main.")
        fi
        CONTEXT_PARTS+=("Role: Implementer — test-first development in isolated worktrees. Add @decision annotations to 50+ line files. NEVER work on main. The branch-guard hook will DENY any source file writes on main.")
        ;;
    guardian)
        CONTEXT_PARTS+=("Role: Guardian — REQUIRED: After merge approval, update MASTER_PLAN.md: mark phase status as completed, append decision log with @decision IDs from merged code, present plan update diff to user for approval before applying. The merge is not done until the plan is updated. Also: verify @decision annotations before merge. Check for staged secrets. Require explicit approval for commits/merges.")
        ;;
    Bash|Explore)
        # Lightweight agents — minimal context
        ;;
    *)
        CONTEXT_PARTS+=("Agent type: ${AGENT_TYPE:-unknown}")
        ;;
esac

# --- Output ---
if [[ ${#CONTEXT_PARTS[@]} -gt 0 ]]; then
    CONTEXT=$(printf '%s\n' "${CONTEXT_PARTS[@]}")
    ESCAPED=$(echo "$CONTEXT" | jq -Rs .)
    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SubagentStart",
    "additionalContext": $ESCAPED
  }
}
EOF
fi

exit 0
