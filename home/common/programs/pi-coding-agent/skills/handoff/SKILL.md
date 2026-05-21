---
name: handoff
description: "REQUIRED when user says 'pickup', '/pickup', 'handoff', '/handoff' — MUST load this skill BEFORE any other work. Compacts conversations into handoff docs or resumes work from a prior handoff document."
argument-hint: "What will the next session be used for?"
commands:
  - handoff
  - pickup
---

### For "handoff"

If a request to "handoff" is invoked by the user, then write a handoff document summarising the current conversation so a fresh agent or session can continue the work. Save to `~/.local/share/pi/handoffs/$(basename $PWD)/$(date '+%Y-%m-%dT%H-%M-%S').md`, not the current workspace.

Include a "suggested skills" section in the document, which suggests skills that the agent should invoke.

Include a "next steps" section in the document, that might include questions that still need answers from the user, blockers or issues that were found in the summarized session conversation, any task pipeline next steps.

Do not duplicate content already captured in other artifacts (PRDs, plans, tasks, ADRs, tickets, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly. Do not immediately start working on those passed arguments before you create the handoff document; instead, include those in the next steps section for the agent to use as context on what to work on next or to prioritize.

Prepend helpful, relevant, human-readable frontmatter to the handoff document:

```markdown
# Handoff: {brief title}

**Tmux Session:** {output of `tmux display-message -p '#{session_name}'`}
**Time:** 2026-02-19 14:30:00 EST
**Working Directory:** /Users/seth/.dotfiles
**Branch/Bookmark:** feature-auth-refactor
```

### For "pickup"

If a request to "pickup" or `/pickup` is invoked, the agent should use the following methods for finding the correct handoff document (using `rg` or `fd`) to pickup:

- `~/.local/share/pi/handoffs/$(basename $PWD)/*.md`, find the specific document via the "Time:" in the frontmatter, the format is `2026-02-19 14:30:00 EST`
- `~/.local/share/pi/handoffs/{the current tmux session}/*.md`, find the specific document via the "Time:" in the frontmatter, the format is `2026-02-19 14:30:00 EST` (legacy/older handoff documents followed this pattern of storage in subdirectories based on the tmux session)

If the user passed arguments to pickup:

- First, try to match arguments against handoff document titles/content (use `rg` to search) to find the right doc
- If no specific match, use the most recent handoff and treat arguments as a focus directive — prioritize matching next steps and tailor the summary accordingly

If no arguments, use the most recent handoff document.

The agent should then:

- Verify state: `git status` or `jj status`, check key files exist
- Summarize back to user before continuing, including the items the agent believes it should work on next, any skills, etc it should run, etc. Include any of the errors, issues, blockers it determined.
- Ask for confirmation before starting work
