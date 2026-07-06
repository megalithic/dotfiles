# Pi Coding Agent Instructions

## Core Principles

**Read before you edit.** Never modify code you haven't read. Before changing
any file: read it, check for `AGENT CONTEXT` inline comments, check for
`AGENTS.md` in the directory. Understand existing patterns before touching them.

**Try before asking.** When about to ask "do you have X installed?" — just run
it. If it works, proceed. If it fails, inform the user and suggest a fix.

**Verify before claiming done.** Never say "tests pass" without running them.
Run the command, show the output, confirm your claim. Evidence before assertions.

**Investigate before fixing.** When something breaks: observe the error, form a
hypothesis, verify it, then fix. No shotgun debugging. No fixes without
understanding root cause.

**"Investigate" means only investigate.** When user says "check", "inspect", or
"audit" — report findings only. Don't implement changes unless explicitly asked.

**Clean up after yourself.** Remove debug artifacts before committing:
`console.log`, commented-out code, temp files, hardcoded test values. Scan your
diff before every commit.

**Only fix what's asked.** No bonus improvements, refactoring, or extra comments
beyond what was requested. KISS, YAGNI — prefer duplication over wrong
abstraction.

**Respect convention files.** Projects may contain `AGENTS.md`, `CLAUDE.md`,
`.cursorrules`, `.clinerules`, `.github/copilot-instructions.md`. Read these
before working in any new project. Check for `AGENT CONTEXT` comment blocks in
implementation files.

## Tools

- Always use `trash` instead of `rm` for file deletion
- Use `jj` instead of `git` when a `.jj` directory exists at repo root (jj-managed repo). Otherwise use `git` normally
- Always use `fd` instead of `find` for file discovery
- Always use `rg` instead of `grep` for content search
- Use project scripts (just, package.json, Makefile) for linting/formatting
- Use `~/bin/ntfy` for notifications
- Use `/tmp/` for temporary scripts — clean up after use

## Writing

- Use sentence case: "Next steps" not "Next Steps"
- Prefer bullet points over paragraphs
- Be concise — sacrifice grammar for brevity
- No corporate buzzwords: comprehensive, robust, utilize, leverage, streamline, enhance
- No AI phrases: "dive into", "diving into"

## Version Control

Detect VCS at session start: if `.jj` directory exists at repo root, use `jj`.
Otherwise use `git`. **Never assume jj** — check first.

- **Never push to main** — use feature branches/bookmarks
- **Never push without explicit user permission** — show exact command, wait for approval
- **Never deploy or SSH without explicit user permission** — same rule

### Jujutsu (jj) repos

When `.jj` exists, use jj equivalents:
`git status` → `jj status`, `git diff` → `jj diff`,
`git commit` → `jj describe`, `git log` → `jj log`, `git push` → `jj git push`

### Multi-phase work

Always create a new commit BEFORE starting each new phase:

```bash
jj desc -m "feat(x): phase 1 - core functionality"
jj new                                              # <- CRITICAL before phase 2
jj desc -m "feat(x): phase 2 - reliability"
```

Without `jj new`, phase 2 changes overwrite phase 1 in a single commit.

### Codebase etiquette

Small focused commits. Descriptive messages. Don't rewrite shared history.
Review (`jj diff`, `jj log`) before pushing. Sync often (`jj git fetch`).
Rebase onto main before pushing. Atomic PRs.

## Uncommitted Changes (CRITICAL)

**User's uncommitted changes are SACRED.** Before ANY VCS operation:

1. Check status (`jj status` or `git status`) to see working copy state
2. If changes exist, ask user — do NOT assume

For jj repos: never assume "(no description set)" means empty. Sentinel
extension enforces blocked commands (`jj rebase`, `jj abandon`, `jj restore`,
`jj undo`) — check `jj status` first, commit WIP, ask user.

## Interactive Commands (AVOID)

These hang forever without flags:

| Command                       | Non-interactive alternative     |
| ----------------------------- | ------------------------------- |
| `jj squash`                   | `jj squash -m "msg"` or `-u`    |
| `jj squash --from X --into Y` | Add `-u` or `-m "msg"`          |
| `jj describe`                 | `jj describe -m "msg"`          |
| `jj commit`                   | `jj commit -m "msg"`            |
| `jj split`                    | Avoid — use separate commits    |
| `vim`, `nano`, `emacs`        | Use `Write` tool or `cat <<EOF` |

**Don't guess flags** — run `<cmd> --help` to find the right option.

## Guardrail Override Protocol

Sentinel extension blocks dangerous commands (push, rebase, abandon, SSH, deploy).
When blocked, user can say `override` or `!override` for single-use bypass.

**On "Override granted... Retry the command now"** — immediately retry the exact
blocked command. Don't ask again. Override is single-use and expires in 2 minutes.

## Workflow

- Clarify user's intention unless request is completely clear
- If uncertain, say so immediately — don't guess
- Work incrementally: complete step → verify (build/lint/test) → commit
- Complex tasks: write plan first. Simple tasks: just do it
- Plans and research live in `~/.local/share/pi/plans/$(basename $PWD)/` as `{slug}_TASK.md`, `{slug}_PLAN.md`, and `{slug}.ticket-context.md`. `{slug}` = `${TICKET_ID}-<kebab>` if a tk ticket is in progress, else `<kebab>` from the user's prompt. See the task-pipeline skill for slug resolution rules.

## Session Completion

1. File issues for remaining work
2. Run quality gates (tests, linters, builds)
   - For nix-darwin changes, run `just darwin` and monitor output
   - For home-manager changes, run `just home` and monitor output
   - For both, or when unsure which applies, run `just rebuild` and monitor output
3. Commit changes (`jj describe -m` or `git commit`)
4. Ask user if they want to push — never push automatically
