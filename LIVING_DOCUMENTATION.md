# Living Documentation

A self-enforcing system that captures decisions at implementation and surfaces them into navigable documentation. Decisions live in code, documentation is derived.

## Why This Exists

Documentation drifts from reality. Specs get written, code gets changed, docs get stale. Dead documentation actively misleads—it's worse than no documentation at all.

Living Documentation solves this by making the code the single source of truth:
- Decisions are captured WHERE they're implemented
- Documentation is DERIVED from source annotations
- The system ENFORCES annotation requirements
- Drift becomes structurally impossible

## How It Works

1. **You work normally** — write code, make decisions
2. **Gates enforce annotations** — significant code requires @decision blocks
3. **Tracking monitors changes** — system knows what was modified
4. **Surfacing extracts decisions** — annotations become navigable docs
5. **Generated docs stay current** — zero manual maintenance

## The Flow

```
Code with @decision → Extract → Validate → Generate docs/decisions/
```

Status appears as you work:
- `[GATE]` — Annotation requirements
- `[DECISION]` — What changed
- `[SURFACE]` — Extraction progress
- `[OUTCOME]` — Final state

## Implementation

The system lives in `.claude/`:

| Component | File | Purpose |
|-----------|------|---------|
| Gate | `hooks/gate.sh` | Enforce annotations |
| Track | `hooks/track.sh` | Monitor changes |
| Surface | `hooks/surface.sh` | Trigger extraction |
| Command | `commands/surface.md` | Main pipeline |
| Extractor | `agents/extractor.md` | Parallel scanning |
| Parser | `skills/decision-parser/` | Annotation syntax |
| Generator | `skills/doc-generator/` | Output templates |

Run `/surface` to regenerate documentation from source.

## Annotation Quick Reference

**Block format** (for significant decisions):
See `skills/decision-parser/SKILL.md` for full specification.

**Required fields**: id, title, status, rationale

The actual implementation files ARE the reference. Don't duplicate here—that's what causes drift.
