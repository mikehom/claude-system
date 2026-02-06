---
name: todos
description: List, manage, and review pending todos. Usage: /todos [done <#>] [--global] [stale]
argument-hint: "[done <#>] [--global] [--project] [stale] [review]"
---

# /todos — Manage Pending Todos

List, complete, and review your captured todos (GitHub Issues labeled `claude-todo`).

## Instructions

Parse `$ARGUMENTS` to determine the action:

### No arguments → List all todos
```bash
~/.claude/scripts/todo.sh list --all
```
Show the output to the user in a clean format.

### `done <number>` → Close a todo
```bash
~/.claude/scripts/todo.sh done <number>
```
If the user specifies `--global`, add that flag. If the issue number belongs to the global repo, add `--global`.

### `stale` → Show old todos that need attention
```bash
~/.claude/scripts/todo.sh stale
```
Show stale items and ask the user which to close, keep, or reprioritize.

### `review` → Interactive triage
1. Run `~/.claude/scripts/todo.sh list --all`
2. Present each todo one by one
3. For each, ask: **Keep**, **Close**, or **Reprioritize**?
4. Execute the user's decision

### `--project` or `--global` → Scoped listing
```bash
~/.claude/scripts/todo.sh list --project
~/.claude/scripts/todo.sh list --global
```

## Display Format

Present todos clearly:
```
PROJECT [owner/repo] (N open):
  #42 Fix auth middleware (2026-01-20)
  #43 Add rate limiting (2026-02-01)

GLOBAL [<your-github-user>/cc-todos] (N open):
  #7 Learn about MCP servers (2026-01-15)
```

For stale items, flag them: "This todo is 21 days old — still relevant?"
