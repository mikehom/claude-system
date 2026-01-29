---
name: context-preservation
description: Generate structured context summaries for session continuity across compaction
---

# Context Preservation Skill

Generate structured context summaries when compaction is imminent or requested, ensuring session continuity without information loss.

## Purpose

Context compaction discards conversation history to fit the context window. Critical information—objectives, decisions, active state—can be lost. This skill captures that information in a dense, actionable format before compaction occurs.

## Output Format (STRICT - NO DEVIATIONS)

```markdown
### 1. 🎯 Current Objective & Status
- **Goal**: [Robust, multi-sentence description of what we are building. Include critical details, context, and the "Definition of Done". Do not summarize into a single vague line.]
- **Status**: [Completed | In Progress | Blocked]
- **Immediate Next Step**: [The very next command or code edit required. Be specific.]

### 2. 🧠 Active Context
- **Active Files**:
  - `[Absolute Path]`
  - `[Absolute Path]`
- **Recent Changes**: [Specific descriptions of what *just* changed in the code, referencing specific functions or logic.]
- **Variables/State**: [Key variable names, data structures, or temporary states currently in focus.]

### 3. 🛡️ Constraints & Decisions (CRITICAL)
- **Preferences**: [User preferences stated in this session, e.g., "no external deps", "use snake_case"]
- **Discarded Approaches**: [What did we try that failed? Do not repeat these mistakes.]
- **Architectural Rules**: [Patterns we agreed on, e.g., "Service Layer pattern", "DTOs required"]

### 4. 📝 Continuity Handoff
- "When resuming, the first thing to do is..."
```

## Content Extraction Rules

### Section 1: Current Objective & Status

**Extract Goal from:**
- User's initial request in the conversation
- Any `TodoWrite` output from the session
- Explicit goal statements ("I want to...", "We need to...", "The task is...")
- Definition of done indicators ("...should be able to...", "...must work with...")

**Determine Status:**
- `Completed`: All stated objectives achieved, tests passing, no pending work
- `In Progress`: Work ongoing, partial completion, tests may not exist yet
- `Blocked`: Explicit blocker mentioned, waiting on external input, unresolved error

**Extract Immediate Next Step:**
- Last `TodoWrite` item marked `in_progress`
- Last explicit "next I will..." or "then we need to..." statement
- If none found: first pending item from TodoWrite, or first unfulfilled objective

### Section 2: Active Context

**Detect Active Files:**
- Files touched via `Read`, `Write`, `Edit` operations in current session
- Prioritize by recency (most recent first)
- Include only files still relevant (not one-off reads for reference)
- **ALWAYS use absolute paths** (e.g., `/Users/turla/Code/project/src/auth.ts`)

**Extract Recent Changes:**
- Parse `Edit` operations
- Summarize function additions, modifications, deletions
- Reference specific function/class/method names
- Note line number ranges if significant

**Capture Variables/State:**
- Key variables discussed or manipulated
- Data structures under construction
- Temporary files or intermediate states
- Environment variables or configuration being used

### Section 3: Constraints & Decisions

**Detect Preferences:**
- Patterns: "don't use...", "prefer...", "always...", "never..."
- User statements: "I want...", "let's stick with...", "keep it simple..."
- Framework/library restrictions
- Code style preferences

**Track Discarded Approaches:**
- Patterns: "that didn't work...", "let's try something else..."
- Error messages that led to approach changes
- Explicit rejections ("no, not that way...")
- Failed test approaches

**Extract Architectural Rules:**
- Pattern discussions ("use the factory pattern...")
- Structure agreements ("all services go in...")
- Interface contracts ("the API should...")
- Dependency decisions ("we'll use X for Y")

### Section 4: Continuity Handoff

**Generate from:**
- Current `in_progress` TodoWrite item
- Last stated intention before compaction
- Most critical unfinished work
- First step to validate resumed context is correct

**Format:**
Always begin with "When resuming, the first thing to do is..."

## Anti-Patterns (NEVER DO)

### Goal Description

❌ **WRONG**:
- "Building a feature"
- "Fixing the bug"
- "Working on authentication"

✅ **RIGHT**:
- "Building a user authentication system with OAuth2 PKCE flow for the mobile app. The system must support Google and Apple SSO, store refresh tokens securely in the device keychain, and include a 'remember me' option that extends token lifetime to 30 days. Definition of Done: user can complete full login flow, tokens persist across app restarts, logout clears all tokens."

### Active Files

❌ **WRONG**:
- `file.ts`
- `./src/auth.ts`
- "the auth file"

✅ **RIGHT**:
- `/Users/turla/Code/myproject/src/auth/oauth-handler.ts`
- `/Users/turla/Code/myproject/src/auth/token-storage.ts`

### Recent Changes

❌ **WRONG**:
- "Updated the file"
- "Fixed some issues"
- "Modified the function"

✅ **RIGHT**:
- "Added `validateTokenExpiry()` function to `/Users/turla/Code/myproject/src/auth/token-storage.ts` (lines 42-67) that checks JWT expiration and returns boolean. Modified `refreshToken()` to call this before attempting refresh."

### Discarded Approaches

❌ **WRONG**:
- "Tried some things"
- "Had some errors"

✅ **RIGHT**:
- "Attempted to store tokens in localStorage but rejected due to XSS vulnerability concerns. Then tried AsyncStorage but it doesn't encrypt at rest. Settled on react-native-keychain for secure storage."

### Immediate Next Step

❌ **WRONG**:
- "Continue working"
- "Fix the remaining issues"
- "Finish the implementation"

✅ **RIGHT**:
- "Run `npm test -- --testPathPattern=oauth-handler` to verify the new `validateTokenExpiry()` function works with expired tokens"

## Validation Checklist

### Section 1 Validation
- [ ] Goal is 2+ sentences minimum
- [ ] Goal includes context (what/why)
- [ ] Goal includes Definition of Done criteria
- [ ] Status is exactly one of: Completed, In Progress, Blocked
- [ ] Immediate Next Step is a specific command or edit, not vague

### Section 2 Validation
- [ ] All file paths are absolute (start with `/`)
- [ ] No relative paths (no `./` or `../`)
- [ ] At least one Active File listed if work occurred
- [ ] Recent Changes reference specific function/method names
- [ ] Changes include line number references where applicable

### Section 3 Validation
- [ ] Preferences include specific technical terms, not vague descriptions
- [ ] Discarded Approaches explain WHY they were discarded
- [ ] No empty sections (use "None stated this session" if applicable)

### Section 4 Validation
- [ ] Starts with "When resuming, the first thing to do is..."
- [ ] Contains a specific, actionable instruction
- [ ] Would allow a fresh Claude instance to immediately continue

## Example Output

```markdown
### 1. 🎯 Current Objective & Status
- **Goal**: Implementing a real-time notification system for the dashboard using WebSocket connections. The system must support user-specific channels, message persistence for offline users, and graceful reconnection with exponential backoff. Users should see a red badge on the notification bell when new unread notifications arrive. Definition of Done: notifications appear within 2 seconds of being triggered, persist across page refreshes, and clear when user views them.
- **Status**: In Progress
- **Immediate Next Step**: Create the `NotificationWebSocket` class in `/Users/turla/Code/dashboard/src/services/notification-ws.ts` with the `connect()`, `disconnect()`, and `onMessage()` methods.

### 2. 🧠 Active Context
- **Active Files**:
  - `/Users/turla/Code/dashboard/src/services/notification-ws.ts`
  - `/Users/turla/Code/dashboard/src/components/NotificationBell.tsx`
  - `/Users/turla/Code/dashboard/src/hooks/useNotifications.ts`
- **Recent Changes**: Added `useNotifications` hook skeleton with `notifications` state array and `unreadCount` computed property. Created empty `notification-ws.ts` file with class structure but no implementation yet.
- **Variables/State**: Using `WS_ENDPOINT = wss://api.example.com/notifications` environment variable. Notification schema: `{ id: string, userId: string, message: string, read: boolean, createdAt: ISO8601 }`.

### 3. 🛡️ Constraints & Decisions (CRITICAL)
- **Preferences**: No external WebSocket libraries—use native browser WebSocket API. Prefer React hooks over class components. TypeScript strict mode enabled.
- **Discarded Approaches**: Initially considered polling with `setInterval` but rejected due to unnecessary server load and delayed notification delivery. Also considered Server-Sent Events but need bidirectional communication for read receipts.
- **Architectural Rules**: All WebSocket logic lives in `/src/services/`, React integration via hooks in `/src/hooks/`. State management through React context, not Redux.

### 4. 📝 Continuity Handoff
- "When resuming, the first thing to do is implement the `connect()` method in `NotificationWebSocket` class that establishes the WebSocket connection and sets up the `onmessage`, `onerror`, and `onclose` event handlers."
```

## Usage

### Manual Invocation
```
/compact
```

### Skill Invocation
```javascript
Skill(skill: "context-preservation")
```

## Integration Notes

This skill complements the Living Documentation system:
- Decisions made during the session should be captured in code via `@decision` annotations
- Context preservation captures the ephemeral state that lives outside code
- Both systems together ensure no knowledge is lost across compaction boundaries
