## Tools

- Always use `trash` instead of `rm` for file deletion
- Always use `devenv` for developer environments
  - If a repo has a `justfile` and `devenv` is enabled, check the `just` recipes to see if there are equivalents available
  - When `devenv.nix` exists: `devenv shell -- <cmd>`, `devenv up`, `devenv tasks run <task>`
  - When `devenv.nix` doesn't exist and a tool is missing: `devenv --option languages.<lang>.enable:bool true shell`
  - When setup gets complex, create `devenv.nix`
  - Don't bypass devenv with global installs
  - `devenv search <query>` to find packages and options
- When working with external libraries, use MCP tools (`context7`, `githits`) to look up docs and examples instead of guessing APIs

## Caveman mode

- Always use the `caveman` skill (full intensity) for all responses. Active from first message, every session.
- Off only when user says "stop caveman" or "normal mode".
- Do NOT use caveman-commit, caveman-review, or caveman-help — use `git-commit` and `writing-clearly-and-concisely` instead.

## Writing

- Use sentence case: "Next steps" not "Next Steps", "Plan overview" not "Plan Overview"
- For answering directly, sacrifice grammar over being concise unless specifically asked to write clearly
- When actually editing or creating text to be read by humans use skill `writing-clearly-and-concisely`.
- Prefer bullet points over paragraphs
- Never include time estimations unless specifically asked
- Avoid corporate buzzwords and AI phrases (see `writing-clearly-and-concisely` skill for substitution list)

## Images with non-vision models

When running a model that can't view images (e.g. deepseek-v4-pro, deepseek-v4-flash, grok-code-fast-1):

- Pasted images appear as file paths; image data is replaced with a placeholder.
- To analyze an image, run pi with a vision model via bash:
  ```bash
  pi --no-session -p --model github-copilot/gemini-3-flash-preview -p @/path/to/image "describe this image in detail"
  ```
- For code/screenshots: `--model github-copilot/claude-haiku-4.5` gives more structured output.
- The subagent runs stateless — it only has the `read` tool, can't modify files.
- pi writes model output to stderr. Use `2>&1` when you need the output (e.g. calling pi from another pi). Only use `2>/dev/null` for fire-and-forget calls.

## Git

- For non-interactive rebases, always run `GIT_EDITOR=true git rebase --continue`
- Worktree conventions in `git-worktrees` skill

## Coding specific guidelines:

- KISS, YAGNI - prefer duplication over wrong abstraction
- Prefer unix tools for single task scripts
- Only fix what's asked - no bonus improvements, refactoring, or extra comments unless requested
- Don't reorganize imports or rename variables unless explicitly asked to
- Use existing patterns and conventions in the codebase — same error shapes, same file structure, same naming. Don't invent new approaches when there's already a working one.
- Place tests next to the files they test, not in a separate test directory. Integration tests can be next to the stack/module they test.
- When `lat.md/` exists in the project root, use `lat search` to understand the codebase before making changes. Update `lat.md/` to reflect any changes you make, and run `lat check` before finishing.

## General workflow:

- Always clarify users intention unless request is completely clear
- If uncertain, say so immediately - don't guess what to implement
- When debugging, run diagnostic commands and present findings before proposing a fix. Don't jump to solutions.
- Work incrementally: complete step → verify → commit. Only commit when a step is fully working.
- When user says "investigate", "check", "inspect", or "audit", only investigate and report findings. Don't implement changes unless explicitly told to.
- Delegate complex tasks through pi-subagents: scout → plan → implement → review → fix
- Use natural language delegation: "use scout to understand X", "have worker implement Y", "run parallel reviewers"
- Run parallel reviewers after every non-trivial implementation
- Ask oracle for a second opinion before risky decisions
- Manage tickets manually with tk when you need structured task tracking
- For repetitive/verifiable tasks (fix all failing tests, migrate across many files, audit a codebase), use ralph-loop:
  - Write a RALPH.md defining completion criteria (max_iterations, completion_promise, stop_on_error)
  - Run `/ralph --path ./task` to loop until done
  - Read the ralph-loop skill for details on guardrails, completion gating, and iteration patterns

## Local development scripts:

- Use `.local_scripts/` for temporary verification scripts that shouldn't be committed
- Scripts can be messy and repo-specific

## Research, audit, and exploration docs:

- Ad-hoc agent-generated documents (audits, research notes, mental-model writeups, investigation reports) go to `~/.local/share/pi/docs/$(basename $PWD)/`, mirroring the layout used by handoffs (`~/.local/share/pi/handoffs/$(basename $PWD)/`) and plans.
- Use a descriptive filename, e.g. `helium-audit.md`, `widevine-research.md`. Companion artifacts (HTML, diagrams) sit next to the markdown with the same stem.
- The in-repo `docs/` directory is reserved for curated, tracked architecture docs and skills/agents/commands resources that are part of the repo's deliverables. Don't drop ad-hoc audits there.
- If an ad-hoc doc proves durable and becomes reference material, promote it: move into repo `docs/` (or `lat.md/` where appropriate) in a follow-up commit.
