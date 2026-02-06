---
name: todo
description: Capture a todo or idea mid-session. Persists as a GitHub Issue. Usage: /todo fix the login bug [--global] [--priority=high]
argument-hint: "description of the todo [--global] [--priority=high|medium|low]"
---

# /todo — Quick Idea Capture

Capture a todo, idea, or future task. Persists as a GitHub Issue so it survives session clears, restarts, and is visible on GitHub.

## Instructions

1. Parse `$ARGUMENTS` for the todo text and any flags (`--global`, `--priority=high|medium|low`)
2. Run the backend script to create the issue:

```bash
~/.claude/scripts/todo.sh add $ARGUMENTS
```

3. Confirm to the user with the issue URL returned by the script.

## Scope Rules

- **Default (no flag)**: Saves to current project's GitHub repo issues
- **`--global`**: Saves to the global backlog repo (`<your-github-user>/cc-todos`, auto-detected)
- If not in a git repo, automatically falls back to global

## Examples

- `/todo fix the auth middleware` → project issue
- `/todo --global learn about MCP servers` → global issue
- `/todo --priority=high fix the production bug` → high-priority project issue
