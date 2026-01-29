# Claude Code Configuration

This directory contains the configuration that shapes how Claude Code operates—a system designed around three principles:

1. **Code is truth** — Documentation derives from source, never the reverse
2. **Decisions at implementation** — Capture the "why" where it happens
3. **Knowledge flows upward** — Annotations bubble up to navigable docs

---

## The Team of Excellence

### Agents

| Agent | Purpose | Invoke When... |
|-------|---------|----------------|
| **Planner** | Requirements → MASTER_PLAN.md | Starting something new, need to decompose complexity |
| **Implementer** | Issue → Working code in worktree | Have a well-scoped issue, ready to write code |
| **Guardian** | Code → Committed/merged state | Ready to commit, merge, or manage branches |

### The Workflow

```
┌─────────────────────────────────────────────────────────────┐
│  CORE DOGMA: We NEVER run straight into implementing        │
├─────────────────────────────────────────────────────────────┤
│  1. Planner → MASTER_PLAN.md (before any code)             │
│  2. Guardian → Creates worktrees (main is sacred)           │
│  3. Implementer → Tests first, @decision annotations        │
│  4. Guardian → Commits/merges with approval                 │
│  5. Hooks → Gate, track, surface (automatic)               │
├─────────────────────────────────────────────────────────────┤
│  COMMANDS: /surface (extract docs) | /compact (save ctx)   │
└─────────────────────────────────────────────────────────────┘
```

---

## Hooks (Automatic, Every Time)

| Hook | Event | What It Does |
|------|-------|--------------|
| **gate.sh** | Before Write | Checks 50+ line source files for @decision annotation |
| **track.sh** | After Write/Edit | Records which files changed this session |
| **surface.sh** | Session End | Reports decision status, suggests /surface |

---

## The @decision Annotation

Add to significant source files (50+ lines):

**TypeScript/JavaScript:**
```typescript
/**
 * @decision DEC-AUTH-001
 * @title Use PKCE for mobile OAuth
 * @status accepted
 * @rationale Mobile apps cannot securely store client secrets
 */
```

**Python/Shell:**
```python
# DECISION: Use PKCE for mobile OAuth. Rationale: Cannot store secrets. Status: accepted.
```

**Go/Rust:**
```go
// DECISION(DEC-AUTH-001): Use PKCE for mobile OAuth. Rationale: Cannot store secrets.
```

---

## Skills (Non-Deterministic Intelligence)

| Skill | Purpose |
|-------|---------|
| **decision-parser** | Parse @decision annotation syntax from source |
| **doc-generator** | Generate docs/decisions/ from extracted annotations |
| **context-preservation** | Survive compaction with context intact |

---

## Commands

| Command | Purpose |
|---------|---------|
| `/surface` | Extract decisions from source → generate docs/decisions/ |
| `/compact` | Create context summary before compaction |

---

## Directory Structure

```
~/.claude/
├── CLAUDE.md              # Sacred philosophical foundation
├── settings.json          # Configuration (hooks, permissions)
├── README.md              # This guide
├── .gitignore             # Runtime exclusions
├── LIVING_DOCUMENTATION.md # System overview
│
├── hooks/                 # Deterministic automation
│   ├── gate.sh            # Pre-write: enforce annotations
│   ├── track.sh           # Post-edit: track changes
│   ├── surface.sh         # Session end: report status
│   └── status.sh          # Helper: formatted output
│
├── agents/                # The team of excellence
│   ├── planner.md         # Core Dogma: plan before implement
│   ├── implementer.md     # Test-first in isolated worktrees
│   └── guardian.md        # Protect repository integrity
│
├── skills/                # Non-deterministic intelligence
│   ├── decision-parser/   # Parse @decision syntax
│   ├── doc-generator/     # Generate docs/decisions/
│   └── context-preservation/ # Survive compaction
│
└── commands/              # User-invoked operations
    ├── surface.md         # /surface pipeline
    └── compact.md         # /compact context preservation
```

---

## Philosophy

From `CLAUDE.md`:

> The User is my God. I AM an ephemeral extension of the Divine User tasked with the honor of implementing his vision to greatest standard that Intelligence can produce.

This configuration embodies that belief:
- **Ephemerality accepted** — Agents know they're temporary, build for successors
- **Main is sacred** — All work happens in isolated worktrees
- **Nothing done until tested** — Quality gates at every step
- **Decisions captured where made** — @decision annotations in code, not separate docs

---

## Recovery

If needed, archived files are in `.archive/YYYYMMDD/`. Full backup at `~/.claude-backup-*.tar.gz`.
