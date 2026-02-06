# Pi Coding Agent Instructions

## Tools

- Always use `trash` instead of `rm` for file deletion
- Always use `jj` instead of `git` for version control (this repo uses Jujutsu)
- Always use `fd` instead of `find` for file discovery
- Always use `rg` instead of `grep` for content search
- Always use `web-search` skill first (ddg), fall back to `brave-search` if needed
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
- **When requesting push permission:** show the exact command, e.g.:
  ```
  Ready to push. Run this?
  jj git push -b my-feature
  ```
- Common mappings:
  - `git status` → `jj status`
  - `git diff` → `jj diff`
  - `git commit` → `jj describe` (changes auto-tracked)
  - `git log` → `jj log`
  - `git push` → `jj git push` (requires user permission)

## Interactive Commands (AVOID)

**These commands open an editor/prompt - use flags to skip:**

| Command | Non-interactive alternative |
|---------|----------------------------|
| `jj squash` | `jj squash -m "message"` |
| `jj describe` | `jj describe -m "message"` |
| `jj split` | Avoid - inherently interactive |

**Don't guess flags** - run `<cmd> --help` to find the right option.

## Remote Server Access

- **Never SSH to remote servers without explicit user permission**
- Treat `ssh` the same as `jj git push` - requires explicit consent
- Includes any remote execution: `ssh user@host`, `scp`, `rsync` to remote, etc.
- **When requesting SSH permission:** show the exact command, e.g.:
  ```
  Need to check server logs. Run this?
  ssh user@host "tail -100 /var/log/app.log"
  ```
- Always ask first and wait for approval
- Exception: user explicitly requests (e.g., "ssh in and check logs", "check the server")

## Deployments

- **Never deploy without explicit user permission**
- Includes: `just deploy`, `deploy`, `fly deploy`, `vercel`, `netlify deploy`, `kubectl apply`, `terraform apply`, `pulumi up`, `dokploy`, etc.
- **When requesting deploy permission:** show the exact command, e.g.:
  ```
  Ready to deploy. Run this?
  just deploy
  ```
  ```
  Ready to deploy. Run this?
  dokploy app deploy --app-id abc123
  ```
- Always ask first and wait for approval
- Exception: user explicitly requests (e.g., "deploy it", "ship it", "push to prod")

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

## Telegram Interaction

When receiving a message via Telegram (prefixed with `📱 **Telegram message:**`):

1. **Always acknowledge immediately** with a brief response:
   ```
   10-4, message received. {next action/decision}
   ```
2. Send acknowledgment via: `~/bin/ntfy send -t "pi agent" -m "..." --telegram`
3. Then proceed with the requested task

## Nix/Dotfiles Relationship (seth's system)

**`~/.dotfiles/` is ALWAYS the source of truth** - version controlled in git/jj.

### NEVER do:
- Symlink FROM nix store TO dotfiles
- Write to `/nix/store/` (read-only)
- Write to `~/bin/`, `~/.config/`, `~/.hammerspoon/` directly

### ALWAYS do:
- Edit files in `~/.dotfiles/` directly
- Check `ls -la <file>` before editing to see if it's a symlink
- Run `just rebuild` after nix changes if needed

### Path mappings:
| Managed path | Edit this instead |
|--------------|-------------------|
| `~/bin/*` | `~/.dotfiles/bin/*` |
| `~/.config/*` | `~/.dotfiles/config/*` |
| `~/.hammerspoon/*` | `~/.dotfiles/config/hammerspoon/*` |
| `~/.pi/agent/*` | `~/.dotfiles/home/programs/ai/pi-coding-agent/` |
