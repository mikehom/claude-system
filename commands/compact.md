---
name: compact
description: Generate context preservation summary for compaction
---

# /compact - Context Preservation

Generate a structured context summary before compaction occurs, preventing "context rot" and "amnesia" by capturing session state.

## Purpose

When the conversation context grows too large, compaction discards history to fit the window. Critical information can be lost. This command captures that information in a structured format before compaction happens.

## Usage

```bash
/compact
```

## What It Does

1. **Scans the conversation** for objectives, decisions, and state
2. **Extracts active context** from file operations and recent changes
3. **Identifies constraints** from user preferences and discarded approaches
4. **Generates structured summary** in the exact 4-section format
5. **Returns inline** for immediate review before compaction

## Output Format

The command produces a structured summary with:

### 1. Current Objective & Status
- Multi-sentence goal with Definition of Done
- Current status (Completed | In Progress | Blocked)
- Specific next step (command or edit)

### 2. Active Context
- Absolute file paths
- Recent changes with function names and line refs
- Key variables and data structures

### 3. Constraints & Decisions
- User preferences and technical constraints
- Discarded approaches with reasons
- Architectural rules agreed upon

### 4. Continuity Handoff
- Actionable first step for resumption

## When to Use

- **Context feels full**: Nearing context window limits
- **Before switching tasks**: Capture current state before pivoting
- **Complex continuation**: Preserve state for future sessions
- **Manual checkpoint**: Create restore point for long-running work

## Example

```bash
/compact
```

Output:
```markdown
### 1. 🎯 Current Objective & Status
- **Goal**: Building OAuth2 PKCE authentication for mobile app with Google/Apple SSO, secure token storage in device keychain, and 30-day "remember me" option. Definition of Done: user completes full login flow, tokens persist across app restarts, logout clears all tokens.
- **Status**: In Progress
- **Immediate Next Step**: Implement `validateTokenExpiry()` in `/Users/turla/Code/app/src/auth/token-storage.ts`

### 2. 🧠 Active Context
- **Active Files**:
  - `/Users/turla/Code/app/src/auth/oauth-handler.ts`
  - `/Users/turla/Code/app/src/auth/token-storage.ts`
- **Recent Changes**: Added OAuth handler skeleton, created token storage interface
- **Variables/State**: Using `react-native-keychain` for secure storage

### 3. 🛡️ Constraints & Decisions (CRITICAL)
- **Preferences**: No external auth libraries, native WebSocket API only
- **Discarded Approaches**: Rejected localStorage (XSS risk) and AsyncStorage (no encryption)
- **Architectural Rules**: All auth logic in `/src/auth/`, React hooks for state

### 4. 📝 Continuity Handoff
- "When resuming, the first thing to do is implement the `connect()` method in the OAuth handler that establishes the authentication flow."
```

## Integration

This command invokes the `context-preservation` skill. See `~/.claude/skills/context-preservation/SKILL.md` for detailed format specifications and extraction rules.

## Tips

- **Review before compaction**: The summary shows what will be preserved
- **Copy if needed**: Save the output externally for critical sessions
- **Validate specificity**: Check that files use absolute paths and next steps are actionable
- **Use with Living Documentation**: Combine with `@decision` annotations for complete knowledge capture
