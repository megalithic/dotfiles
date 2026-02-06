# Agent Instructions

This is a **nix-darwin + home-manager** managed dotfiles repo.

## Nix-Managed Config Files (CRITICAL)

**Before editing ANY config file outside `~/.dotfiles/`:**

1. Check if it's a symlink: `ls -la <path>`
2. If symlinked to `/nix/store/` → find source in `~/.dotfiles/` and edit there
3. If it doesn't exist but should be managed → add to appropriate nix module
4. Run `just rebuild` after nix changes

**Common nix-managed paths:**
- `~/.pi/agent/*` → `home/programs/ai/pi-coding-agent/`
- `~/.config/fish/*` → `home/programs/fish/` or `config/fish/`
- Most `~/.config/<app>/*` → check `home/programs/<app>/` first

**Never:**
- Write directly to symlinked files (will fail or be overwritten)
- Use `brew install` - all packages via Nix
- Edit files in `/nix/store/` (read-only)

## Bead Issue Tracking

This project uses **bd** (beads) for issue tracking. Run `bd onboard` to get started.

## Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd sync               # Sync with git
```

## Pushing (RESTRICTED)

**NEVER push without explicit user permission.** This includes:
- `jj git push`
- `jj push` (if aliased)
- Any git push equivalent

**When requesting push permission:** show the exact command, e.g.:
```
Ready to push. Run this?
jj git push -b my-feature
```

Only push when the user explicitly requests it (e.g., "push it", "push to remote", "go ahead and push").

## Remote Server Access (RESTRICTED)

**NEVER SSH to remote servers without explicit user permission.**

- Treat `ssh` the same as `jj git push` - requires explicit consent
- Includes any remote execution: `ssh user@host`, `scp`, `rsync` to remote, etc.

**When requesting SSH permission:** show the exact command, e.g.:
```
Need to check server logs. Run this?
ssh user@host "tail -100 /var/log/app.log"
```

Only SSH when the user explicitly requests it (e.g., "ssh in and check logs", "check the server").

## Deployments (RESTRICTED)

**NEVER deploy without explicit user permission.**

- Includes: `just deploy`, `deploy`, `fly deploy`, `vercel`, `netlify deploy`, `kubectl apply`, `terraform apply`, `pulumi up`, `dokploy`, etc.

**When requesting deploy permission:** show the exact command, e.g.:
```
Ready to deploy. Run this?
just deploy
```
```
Ready to deploy. Run this?
dokploy app deploy --app-id abc123
```

Only deploy when the user explicitly requests it (e.g., "deploy it", "ship it", "push to prod").

## Landing the Plane (Session Completion)

**When ending a work session:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **Commit changes** - Use `jj describe` to set commit message
5. **Ask user if they want to push** - Do NOT push automatically
6. **Hand off** - Provide context for next session

