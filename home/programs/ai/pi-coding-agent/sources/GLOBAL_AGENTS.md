# Pi Coding Agent Instructions

## Tools

- Always use `trash` instead of `rm` for file deletion
- Always use `jj` instead of `git` for version control (this repo uses Jujutsu)
- Always use `fd` instead of `find` for file discovery
- Always use `rg` instead of `grep` for content search
- Always use `brave-search` skill for web searches (not browser)
- Always read `AGENTS.md` file in project roots

## Writing

- Use sentence case: "Next steps" not "Next Steps"
- Prefer bullet points over paragraphs
- Be concise - sacrifice grammar if needed for brevity
- No corporate buzzwords: comprehensive, robust, utilize, leverage, streamline, enhance
- No AI phrases: "dive into", "diving into"

## Version Control (Jujutsu)

- **Never use git commands** - always use `jj` equivalents
- **Never push to main** directly - use feature bookmarks
- **Never push without explicit user permission** - no `jj git push` unless user explicitly requests (e.g., "push it", "push to remote")
- Common mappings:
  - `git status` → `jj status`
  - `git diff` → `jj diff`
  - `git commit` → `jj describe` (changes auto-tracked)
  - `git log` → `jj log`
  - `git push` → `jj git push` (requires user permission)

## Coding Guidelines

- KISS, YAGNI - prefer duplication over wrong abstraction
- Prefer unix tools for single task scripts
- Use project scripts (just, package.json, Makefile) for linting/formatting
- Node: prefer package.json scripts over npx/bunx
- Always use lockfiles
- Only fix what's asked - no bonus improvements unless requested

## Multi-step Task Workflow

1. For complex tasks: write plan in markdown file first
2. Always clarify user's intention unless request is completely clear
3. If uncertain, say so immediately - don't guess
4. Work incrementally:
   - Complete step
   - Run verification commands (build, lint, test)
   - If verification passes, commit. If not, fix first.
5. Don't create plans for simple single-step tasks

## Nix Environment

- This Mac uses nix-darwin + home-manager
- All packages are managed via Nix (never `brew install`)
- Configuration lives in `~/.dotfiles`
- Use `just rebuild` to apply darwin changes

## Notifications

- Use `~/bin/ntfy` for sending notifications
- It handles attention detection and multi-channel routing automatically

## Local Development Scripts

- Use `.local_scripts/` for temporary verification scripts that shouldn't be committed
- Examples: version update checks, one-off validation scripts, personal dev utilities
- Scripts can be messy and repo-specific
