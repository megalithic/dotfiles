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

## Jujutsu (jj) Aliases

**Use these aliases instead of full commands:**

| Alias | Command | Description |
|-------|---------|-------------|
| `jj dm "msg"` | describe + move bookmark | Commit with message |
| `jj dv` | describe (interactive) + move bookmark | Edit commit message |
| `jj push -b <name>` | git push --bookmark | Push bookmark (required -b flag) |
| `jj pr` | push + gh pr create | Create PR from bookmark |
| `jj feat <name>` | new + bookmark create | Start feature branch |
| `jj done` | cleanup after merge | Delete bookmark, switch to main |
| `jj b` | bookmark | Manage bookmarks |
| `jj s` | status | Show status |
| `jj d` | diff | Show diff |
| `jj l` | log | Show log |

## Jujutsu Interactive Commands (AVOID)

**These commands open an editor by default - use flags to skip:**

| Command | Problem | Non-interactive alternative |
|---------|---------|----------------------------|
| `jj squash` | Opens editor for combined message | `jj squash -m "message"` |
| `jj describe` | Opens editor | `jj describe -m "message"` |
| `jj dv` | Opens editor (intentionally) | Use `jj dm "msg"` instead |
| `jj split` | Interactive by design | Avoid, or use `--tool` |

**Always check `--help`** before assuming flags - don't guess.

## Pushing (RESTRICTED)

**NEVER push without explicit user permission.** This includes:
- `jj push -b <bookmark>`
- `jj git push`
- `jj pr` (includes push)

**When requesting push permission:** show both alias and full command:
```
Ready to push. Run this?
jj push -b my-feature        # alias
jj git push -b my-feature    # full command
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

## Telegram / Pi Bridge Integration

Pi can receive messages from Telegram via Hammerspoon. This requires running pi through `pinvim` or `pisock` wrapper.

### Architecture

```
Telegram → Hammerspoon → Unix Socket → pi (bridge.ts) → notify.ts
```

**Key files (nix-managed in `home/programs/ai/pi-coding-agent/`):**
- `extensions/bridge.ts` - Creates socket, receives messages, forwards to pi
- `extensions/notify.ts` - Suppresses notifications during Telegram conversations
- `config/hammerspoon/lib/interop/pi.lua` - Forwards Telegram to socket

### Debugging Telegram Issues

**1. Check if running via pinvim/pisock:**
```bash
echo $PI_SOCKET      # Should show /tmp/pi-{session}.sock
echo $PI_SESSION     # Should show tmux session name
```

**2. Check if socket exists:**
```bash
ls -la /tmp/pi-*.sock
```

**3. Test socket manually:**
```bash
echo '{"type":"telegram","text":"test message"}' | nc -U /tmp/pi-{session}.sock
```

**4. Check Hammerspoon logs:**
```bash
tail -f ~/.hammerspoon/logs/hammerspoon.log | grep -i telegram
# Or open Hammerspoon console: Cmd+Alt+Ctrl+H
```

**5. Verify extensions are loaded:**
- Check pi startup output for "Bridge listening: /tmp/pi-*.sock"
- Look for errors in pi output

### Default Session

Telegram messages are forwarded to the `mega` session by default (configured in `lib/interop/pi.lua`).

### Common Issues

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| No socket file | Not running via pinvim/pisock | Use `pinvim` or `pisock pi` |
| Socket exists but no messages | Hammerspoon not forwarding | Check HS console/logs |
| Messages received but no notification suppression | `notify.ts` issue | Check TELEGRAM_PREFIX matches |
| "Bridge listening" not shown | Extension not loaded | Check `~/.pi/agent/extensions/` |
| Telegram not forwarding | Check `pi.lastActiveSession` | `hs -c "print(require('lib.interop.pi').lastActiveSession)"` |

### Environment Variables

Set by `pinvim`/`pisock` wrapper:
- `PI_SOCKET` - Full socket path (e.g., `/tmp/pi-mega.sock`)
- `PI_SESSION` - Tmux session name
- `PI_SOCKET_DIR` - Socket directory (`/tmp`)
- `PI_SOCKET_PREFIX` - Socket prefix (`pi`)

## Landing the Plane (Session Completion)

**When ending a work session:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **Commit changes** - Use `jj describe` to set commit message
5. **Ask user if they want to push** - Do NOT push automatically
6. **Hand off** - Provide context for next session


### Sending Formatted Messages to Telegram

Use `ntfy telegram` for rich MarkdownV2 formatting:

```bash
# Must escape special chars: _ * [ ] ( ) ~ ` > # + - = | { } . !
~/bin/ntfy telegram '*Bold title*

• Item one
• Item two

\`code here\`'
```

For simple notifications, use `ntfy send -T` (auto-escapes).


## Nix/Dotfiles Relationship (CRITICAL)

### Source of Truth

**`~/.dotfiles/` is ALWAYS the source of truth.** It's version controlled in git/jj.

```
~/.dotfiles/bin/script.sh  ← SOURCE (edit here)
        ↓ (nix builds)
/nix/store/.../bin/script.sh  ← DERIVED (read-only)
        ↓ (home-manager symlinks)
~/bin/script.sh  ← SYMLINK (may point to dotfiles or nix store)
```

### Rules

1. **ALWAYS edit files in `~/.dotfiles/`** - never in `~/bin`, `~/.config`, etc.
2. **NEVER symlink FROM nix store TO dotfiles** - flow is always dotfiles → nix → home
3. **NEVER write to `/nix/store/`** - it's read-only
4. **Check before editing:** `ls -la <file>` to see if it's a symlink

### Common Paths

| You want to edit... | Edit this instead |
|---------------------|-------------------|
| `~/bin/*` | `~/.dotfiles/bin/*` |
| `~/.config/fish/*` | `~/.dotfiles/config/fish/*` |
| `~/.config/nvim/*` | `~/.dotfiles/config/nvim/*` |
| `~/.hammerspoon/*` | `~/.dotfiles/config/hammerspoon/*` |
| `~/.pi/agent/*` | `~/.dotfiles/home/programs/ai/pi-coding-agent/` |

### After Editing

Some files are live-linked (same inode), others require rebuild:

```bash
# Check if rebuild needed:
ls -la ~/bin/script.sh  # Same inode as dotfiles? → Live
                        # Points to /nix/store? → Needs rebuild

# Rebuild if needed:
just rebuild
```
