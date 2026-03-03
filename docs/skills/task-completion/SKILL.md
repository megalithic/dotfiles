# Task Completion Summary Skill

Defines the format and requirements for task completion summaries in AI agent sessions.

## When to Use

Load this skill when completing any non-trivial task that involved:
- Creating or modifying files
- Making code changes
- Completing a multi-step implementation
- Finishing work that should be reviewed

## Summary Format

### 1. Opening Statement

Brief confirmation that the task is complete:

```
Done, my liege! [Brief description of what was accomplished].
```

### 2. Insight Block (Required for non-trivial tasks)

Provide 2-3 educational insights specific to the implementation:

```
`★ Insight ─────────────────────────────────────`
**[Pattern/Concept Name]**: [Explanation of why this approach was used, what problem it solves, or what makes it interesting]

**[Another Pattern]**: [Another insight specific to this codebase or implementation]
`─────────────────────────────────────────────────`
```

**Focus on:**
- Codebase-specific patterns and conventions
- Trade-offs and design decisions made
- Interesting technical details
- Why certain approaches were chosen over alternatives

**Avoid:**
- Generic programming concepts
- Obvious explanations
- Insights that apply to any codebase

### 3. Summary Section

Structured summary of changes:

```markdown
## Summary

**Created:**
- `path/to/file.ext` (~N lines) - Brief description

**Modified:**
- `path/to/file.ext` - What was changed

**Features/Fixes:**
- ✅ Feature or fix 1
- ✅ Feature or fix 2

**Usage:** (if applicable)
```bash
command-example arg1 arg2
```
```

### 4. Preview Diff (REQUIRED)

**CRITICAL**: At the end of every task completion, invoke `preview-ai diff` to show the changes in a split pane:

```bash
preview-ai diff
```

This ensures:
- User can visually review all changes
- Changes are shown excluding `.beads/**` noise
- Preview appears RIGHT next to the AI agent pane
- User can verify before committing

## Complete Example

```
Done, my liege! The authentication middleware is now implemented with JWT validation.

`★ Insight ─────────────────────────────────────`
**Middleware Ordering**: The auth middleware is registered early in the pipeline
(before route handlers) but after CORS and body parsing. This ensures credentials
are validated before any business logic runs while still allowing preflight requests.

**Token Refresh Pattern**: Using a sliding window refresh (refresh if <5min remaining)
rather than fixed expiry. This prevents the jarring UX of tokens expiring mid-session
while the user is actively working.
`─────────────────────────────────────────────────`

## Summary

**Created:**
- `lib/middleware/auth.ex` (~85 lines) - JWT validation middleware
- `lib/auth/token.ex` (~45 lines) - Token generation/validation helpers

**Modified:**
- `lib/router.ex` - Added auth middleware to protected routes

**Features:**
- ✅ JWT token validation with RS256
- ✅ Sliding window token refresh
- ✅ Proper error responses for expired/invalid tokens

**Usage:**
```elixir
# In router.ex
pipeline :authenticated do
  plug MyApp.Middleware.Auth
end
```

[Executes: preview-ai diff]
```

## Integration with Finish Command

When running `/finish`, `/end`, or `/done`:

1. Complete all pending work
2. Generate summary using this format
3. Run `preview-ai diff` to show changes
4. Proceed with beads sync and push workflow

## Pane Positioning

`preview-ai` ensures the diff preview opens:
- **RIGHT next to** the AI agent's pane (horizontal split)
- In the **same window** as the agent
- **Session-scoped** (won't affect other tmux sessions)
- Focus returns to the agent pane after opening

This works correctly even with multiple panes in the window.
