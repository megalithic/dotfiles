## Tools

- Always use `trash` instead of `rm` for file deletion
- Always use `rg` instead of `grep` for searching for text in files/folders
- Always use `fd` instead of `find` for finding files/folders
- Always set the pi tool `timeout` parameter for Bash tool call for commands that may run long or hang; especially `mise <command>`, `just <command>`, backgrounded executions, and command shapes sentinel flags as risky.
- If `mise.toml`, `.config/mise.local.toml`, or similar root file markers are available, use `mise` related tasks and toolchain commands.
- When working with external libraries, use MCP tools (`context7`, `githits`) to look up docs and examples instead of guessing APIs

### Command Execution

- For long-running or progress-heavy commands (`mise <command>`, package installs, tests), run the command directly with PTY/live output when available (pass `usePTY: true` parameter for the Bash tool call).
- Do not pipe long-running commands through `tail`, `grep`, `head`, or `sed` while they run; those filters can buffer or hide output from `pi-bash-live-view`.
- If output needs filtering, run the command first and inspect logs or captured output afterward.
- Short, finite inspection commands may still use pipes when live progress is not useful.

## Writing

- Use sentence case: "Next steps" not "Next Steps", "Plan overview" not "Plan Overview"
- For answering directly, sacrifice grammar over being concise unless specifically asked to write clearly
- When actually editing or creating text to be read by humans use skill `writing-clearly-and-concisely`.
- Prefer bullet points over paragraphs
- Never include time estimations unless specifically asked
- Avoid corporate buzzwords and AI phrases (see `writing-clearly-and-concisely` skill for substitution list)

## Git

- For non-interactive rebases, always run `GIT_EDITOR=true git rebase --continue`
- Worktree conventions in `git-worktrees` skill
- After creating or pushing to a PR, watch its CI with `gh` until every check is green (approvals don't count). Load the `github` skill for the procedure

## Coding specific guidelines

- KISS, YAGNI - prefer duplication over wrong abstraction
- Prefer unix tools for single task scripts
- Only fix what's asked - no bonus improvements, refactoring, or extra comments unless requested
- Don't reorganize imports or rename variables unless explicitly asked to
- Use existing patterns and conventions in the codebase — same error shapes, same file structure, same naming. Don't invent new approaches when there's already a working one.
- Place tests next to the files they test, not in a separate test directory. Integration tests can be next to the stack/module they test.
- When `lat.md/` exists in the project root, use `lat search` to understand the codebase before making changes. Update `lat.md/` to reflect codebase changes, except for local-only paths under `.local_scripts/` or `.sandbox/`. Run `lat check` before finishing when lat docs changed.
- When `hk.pkl` exists, run `hk validate`, inspect the planned checks for the changed files, then run `hk check --check --safe` on that scope before finishing. Never bypass failed checks; only drop `--safe` after confirming every refused command is read-only.

## General workflow

- For macOS setup, installation, native build, or service validation, load `macos-vm-testing` and use a disposable macOS VM unless the user explicitly authorizes host testing. Keep provisioning approval and report what the VM cannot validate.
- Always clarify users intention unless request is completely clear
- If uncertain, say so immediately - don't guess what to implement
- When debugging, run diagnostic commands and present findings before proposing a fix. Don't jump to solutions.
- Work incrementally: complete step → verify → commit. Only commit when a step is fully working.
- When user says "investigate", "check", "inspect", or "audit", only investigate and report findings. Don't implement changes unless explicitly told to.
- Delegate complex tasks through pi-interactive-subagents: scout → plan → implement → review → fix
- Use natural language delegation: "use scout to understand X", "have worker implement Y", "run parallel reviewers"
- Run parallel reviewers after every non-trivial implementation
- Ask oracle for a second opinion before risky decisions

## Local development scripts

- Use .local_scripts/ for temporary, messy, repo-specific scripts that shouldn't be committed

## Research, audit, and exploration docs

- Ad-hoc agent-generated documents (audits, research notes, mental-model writeups, investigation reports) go to `~/.local/share/pi/docs/$(basename $PWD)/`, mirroring the layout used by handoffs (`~/.local/share/pi/handoffs/$(basename $PWD)/`) and plans.
- Use a descriptive filename, e.g. `helium-audit.md`, `widevine-research.md`. Companion artifacts (HTML, diagrams) sit next to the markdown with the same stem.
