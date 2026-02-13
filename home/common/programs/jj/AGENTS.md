# Jujutsu (jj) Configuration

## Structure

```
jj/
├── default.nix   # Main config: user, ui, signing, colors
├── aliases.nix   # All jj aliases (workflow commands)
├── templates.nix # Log templates, revsets, template-aliases
└── AGENTS.md     # This file
```

## Key aliases

| Alias | Usage | Description |
|-------|-------|-------------|
| `dm` | `jj dm "message"` | Describe + move bookmark to @ |
| `dv` | `jj dv` | Describe via editor + move bookmark |
| `push` | `jj push -b <name>` | Smart push with guardrails |
| `feat` | `jj feat -b <name>` | Create feature branch from main@origin |
| `feat-here` | `jj feat-here -b <name>` | Create branch from current position |
| `co` | `jj co <branch>` | Smart checkout (fetch + switch or create) |
| `pr` | `jj pr` | Push + create GitHub PR |
| `done` | `jj done` | Clean up after PR merge |
| `up` | `jj up` | Fetch + rebase onto main@origin |
| `here` | `jj here` | Move closest bookmark to @ |
| `tug` | `jj tug` | Move closest bookmark to @- |

## Guardrails in push alias

The `push` alias includes safety checks:
- Requires `-b <bookmark>` flag (no accidental pushes)
- Checks bookmark isn't empty
- Auto-adds `--allow-new` for new bookmarks
- Optional `--pr` to create PR after push

## Adding new aliases

Edit `aliases.nix`. Two formats:

```nix
# Simple alias (array of args)
s = [ "status" ];
ll = [ "log" "-T" "builtin_log_compact_full_description" ];

# Complex alias (bash script via util exec)
myalias = [
  "util" "exec" "--" "bash" "-c"
  ''
    set -euo pipefail
    # script here
  ''
  ""  # empty arg for $0
];
```

## Template customization

Edit `templates.nix`:
- `templates.log` - Main log format
- `templates.log_node` - Node symbols (@, ×, *, ·)
- `templates.draft_commit_description` - Commit message template
- `revset-aliases` - Custom revset shortcuts
- `template-aliases` - Reusable template functions

## Signing

Configured for SSH signing via 1Password:
- Signs own commits only (`behavior = "own"`)
- Uses `op-ssh-sign` program
- Allowed signers in `~/.ssh/allowed_signers`

## Agent workflow

When working with jj in this repo:

1. **Never use git** - always jj equivalents
2. **Use aliases** - `jj dm`, `jj push -b`, `jj feat -b`
3. **Check status first** - `jj s` before VCS operations
4. **Don't push without permission** - ask user first

See also: `~/.pi/agent/AGENTS.md` for full jj guidelines.
