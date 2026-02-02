#!/usr/bin/env bash
set -euo pipefail

# Main branch protection for Write/Edit operations.
# PreToolUse hook — matcher: Write|Edit
#
# DECISION: Hard deny for source file edits on main. Rationale: guard.sh only
# blocked git-commit on main, allowing agents to write files freely on main and
# accumulate substantial work in the wrong place before the commit block hit.
# This closes the gap by catching edits at write-time. Status: accepted.
#
# Denies (hard block) when:
#   - Editing a source code file
#   - The file's git repo has main/master checked out
#
# Does NOT fire for:
#   - Files outside git repos
#   - The ~/.claude directory itself (meta-infrastructure)
#   - MASTER_PLAN.md (plans are written on main by design)
#   - Non-source files (config, docs, markdown, JSON, YAML, etc.)
#   - Files in git worktrees (non-main branches)

source "$(dirname "$0")/log.sh"

HOOK_INPUT=$(read_input)
FILE_PATH=$(get_field '.tool_input.file_path')

# Exit silently if no file path
[[ -z "$FILE_PATH" ]] && exit 0

# Skip the .claude config directory itself (meta-infrastructure)
[[ "$FILE_PATH" =~ \.claude/ ]] && exit 0

# Skip MASTER_PLAN.md (plans are written on main by design)
[[ "$(basename "$FILE_PATH")" == "MASTER_PLAN.md" ]] && exit 0

# Skip non-source files (only check source code extensions)
[[ ! "$FILE_PATH" =~ \.(ts|tsx|js|jsx|py|rs|go|java|kt|swift|c|cpp|h|hpp|cs|rb|php|sh|bash|zsh)$ ]] && exit 0

# Skip test files, config files, generated files
[[ "$FILE_PATH" =~ (\.config\.|\.test\.|\.spec\.|__tests__|\.generated\.|\.min\.) ]] && exit 0
[[ "$FILE_PATH" =~ (node_modules|vendor|dist|build|\.next|__pycache__|\.git) ]] && exit 0

# Resolve the git repo for this file
FILE_DIR=$(dirname "$FILE_PATH")
if [[ ! -d "$FILE_DIR" ]]; then
    # Directory doesn't exist yet — try parent
    FILE_DIR=$(dirname "$FILE_DIR")
fi

# Check if file is in a git repo
REPO_ROOT=$(git -C "$FILE_DIR" rev-parse --show-toplevel 2>/dev/null || echo "")
[[ -z "$REPO_ROOT" ]] && exit 0

# Get current branch (symbolic-ref works even before first commit; rev-parse as fallback)
CURRENT_BRANCH=$(git -C "$REPO_ROOT" symbolic-ref --short HEAD 2>/dev/null || git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

# Block writes on main/master
if [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "master" ]]; then
    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: Cannot write source code on $CURRENT_BRANCH branch. Sacred Practice #2: Main is sacred. Create a worktree first: git worktree add ../feature-name -b feature-name $CURRENT_BRANCH"
  }
}
EOF
    exit 0
fi

# All checks passed
exit 0
