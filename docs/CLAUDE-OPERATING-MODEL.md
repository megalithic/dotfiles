# Claude Operating Model & How to Guide Claude Effectively

This document explains how Claude (the AI assistant) processes instructions, what causes it to "miss" directives, and patterns for writing instructions that reliably influence Claude's behavior.

---

## Directive Hierarchy

Claude processes instructions in layers, with earlier layers taking precedence:

```
┌─────────────────────────────────────────────────────────────┐
│ 1. ANTHROPIC SAFETY CONSTRAINTS (hardcoded, non-negotiable) │
│    - No malware creation, no harm, no deception             │
│    - These CANNOT be overridden by any user instruction     │
└─────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. SYSTEM PROMPT (from Claude Code, MCP servers, etc.)      │
│    - Tool definitions and usage patterns                    │
│    - Output style preferences                               │
│    - General behavioral guidelines                          │
└─────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. CLAUDE.md FILES (project + global)                       │
│    - ~/.claude/CLAUDE.md (global, applies everywhere)       │
│    - ./CLAUDE.md (project-specific, checked into repo)      │
│    - These are READ but can be "forgotten" mid-task         │
└─────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. CONVERSATION CONTEXT                                     │
│    - Recent messages have highest salience                  │
│    - Earlier context can fade in long conversations         │
│    - Compaction/summarization loses detail                  │
└─────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. IMMEDIATE TASK FOCUS                                     │
│    - Claude can develop "tunnel vision" on the current task │
│    - May not re-check CLAUDE.md when deeply focused         │
└─────────────────────────────────────────────────────────────┘
```

---

## Why Claude "Misses" Instructions

### 1. Tunnel Vision
When deeply focused on solving a problem, Claude may not pause to re-check CLAUDE.md or earlier conversation context. The immediate goal (e.g., "restart Phoenix") becomes the sole focus, and the means (pkill vs mprocs) gets chosen based on general knowledge rather than project-specific instructions.

**Solution:** Add explicit "STOP AND CHECK" triggers for destructive actions.

### 2. Context Dilution
In long conversations, or after compaction, earlier instructions may not be present or may be summarized away. CLAUDE.md content is shown at conversation start but isn't refreshed mid-conversation.

**Solution:** Reference instructions directly when relevant: "Per CLAUDE.md, use mprocs for this."

### 3. Ambiguous Authority
When CLAUDE.md says "use mprocs" but doesn't explicitly forbid alternatives, Claude may treat it as a preference rather than a requirement.

**Solution:** Use explicit NEVER/ALWAYS tables with consequences.

### 4. General Knowledge Override
Claude has broad knowledge about Linux/Unix patterns. When the specific instruction isn't front-of-mind, Claude falls back to general knowledge (e.g., "pkill is how you restart processes").

**Solution:** Make project-specific patterns more salient than general patterns through explicit contrast tables.

---

## Instruction Patterns That Work

### Pattern 1: Hard Stops (Circuit Breakers)

Hard stops are instructions that should trigger an immediate "STOP AND CHECK" response before Claude takes an action. They work best when:

1. **Placed prominently** - At the top of CLAUDE.md, with visual emphasis
2. **Use negative framing** - "NEVER do X" is stronger than "prefer Y"
3. **Provide alternatives** - Always show what TO do, not just what NOT to do
4. **Explain consequences** - Why this matters

**Example format:**

```markdown
## ⛔ HARD STOPS — READ BEFORE ANY DESTRUCTIVE ACTION

| ❌ NEVER DO THIS | ✅ ALWAYS DO THIS INSTEAD |
|------------------|---------------------------|
| `pkill -f "phx.server"` | `mprocs --ctl '{c: restart-proc, p: phoenix}'` |

**Why?** mprocs manages process lifecycle. Direct kills orphan processes.
```

### Pattern 2: Explicit Checklists

For multi-step procedures, provide explicit checklists Claude can mentally execute:

```markdown
**Before killing/restarting ANY process:**
1. Check: Is mprocs running? (`pgrep mprocs`)
2. If yes: Use mprocs commands exclusively
3. If no: Ask user before using direct process control
```

### Pattern 3: Command Reference Tables

Provide exact commands for common operations:

```markdown
### mprocs Remote Control Commands

| Action | Command |
|--------|---------|
| Restart Phoenix | `mprocs --ctl '{c: restart-proc, p: phoenix}'` |
| Stop all services | `just dev-stop` |
```

### Pattern 4: Contextual Triggers

Add reminders in relevant sections, not just at the top:

```markdown
### Development Server

When you need to restart the development server, **use mprocs** (see Hard Stops section).
Do NOT use pkill or direct process signals.
```

### Pattern 5: Explicit Exceptions

If there ARE cases where the rule doesn't apply, state them explicitly:

```markdown
**Exception:** If mprocs is not running AND user explicitly approves,
you may use `kill -TERM <pid>` as a last resort.
```

---

## Reminding Claude Mid-Conversation

If Claude seems to have forgotten an instruction, you can:

1. **Direct reference:** "Check the Hard Stops section in CLAUDE.md before doing that."
2. **Explicit reminder:** "Remember: use mprocs, not pkill."
3. **Question prompt:** "What does CLAUDE.md say about restarting processes?"

---

## Writing Effective CLAUDE.md Files

### Structure for Maximum Retention

```markdown
# Project Name

Brief description.

---

## ⛔ HARD STOPS (most important, most prominent)

[Circuit breakers that must trigger before destructive actions]

---

## Version Control / Critical Workflow

[Next most important - things done frequently]

---

## Development Environment

[Tools, commands, setup]

---

## Code Guidelines

[Language-specific patterns]

---

## Project Guidelines

[Testing, deployment, etc.]
```

### Visual Emphasis

- Use `⛔`, `❌`, `✅` emoji for hard stops (visual pattern recognition)
- Use `---` horizontal rules to separate major sections
- Use **bold** for key terms
- Use tables for NEVER/ALWAYS contrasts
- Use code blocks for exact commands

### Redundancy Is Good

Repeat critical instructions in multiple places:
- Once in the Hard Stops section
- Once in the relevant technical section
- In command reference tables

---

## Debugging Claude Misbehavior

When Claude does something wrong:

1. **Identify the gap:** Was the instruction present? Was it prominent enough?
2. **Check tunnel vision:** Was Claude deeply focused on solving a problem?
3. **Check context:** Has the conversation been compacted? Is context lost?
4. **Strengthen the instruction:** Add it to Hard Stops, add visual emphasis, add consequences.

### Questions to Ask Claude

- "What does CLAUDE.md say about X?"
- "Before you do Y, what should you check?"
- "Show me the mprocs command for restarting Z."

These prompts force Claude to retrieve and verbalize the instruction, reducing tunnel vision.

---

## Key Takeaways

1. **CLAUDE.md is read but can fade** - Make critical instructions visually prominent
2. **Tunnel vision is real** - Add explicit STOP triggers for destructive actions
3. **Negative framing works** - "NEVER do X" is stronger than "prefer Y"
4. **Provide alternatives** - Always show what TO do, not just what NOT to do
5. **Redundancy helps** - Repeat critical instructions in multiple relevant sections
6. **Mid-conversation reminders work** - Reference CLAUDE.md directly when relevant

---

## Template: Hard Stops Section

Copy this template for new projects:

```markdown
## ⛔ HARD STOPS — READ BEFORE ANY DESTRUCTIVE ACTION

These are **non-negotiable circuit breakers**. STOP and use the correct approach.

### [Category Name]

| ❌ NEVER DO THIS | ✅ ALWAYS DO THIS INSTEAD |
|------------------|---------------------------|
| `bad-command` | `good-command` |

**Why?** [Explanation of consequences]

**Before [action]:**
1. Check: [precondition]
2. If [condition]: [correct action]
3. If not: Ask user first
```
