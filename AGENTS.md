# Dotfiles

megalithic's macOS dotfiles. Both hosts (`megabookpro`, `workbookpro`) are fully mise-managed.

## Structure

- `config/` - app configs, linked per-file to `~/.config/<path>`
- `home/` - linked per-file to `~/<path>` (`.pi/`, `.claude/`, `.ssh/`, `.local/bin/` wrappers)
- `bin/` - user scripts, linked as one directory to `~/bin`
- `config/mise/config.toml` - machine config: tools, `[dotfiles]` link map, `[bootstrap.*]` packages/macOS defaults/launchd, tasks
- `config/mise/config.<host>.toml` - host overlay, merged when `MISE_ENV=<host>`
- `mise/scripts/` - task helpers; `mise/templates/` - generation inputs (fnox)
- `tools/` - source-only code that never deploys
- `mise.toml` - repo dev tooling and TS check tasks
- `bootstrap.sh` - first-install entry point

## Setup

```bash
mise run up                  # converge the machine
mise run update:dotfiles     # apply links only
mise run --dry-run <task>    # preview a task
mise tasks ls                # list tasks
mise run doctor              # health check
```

## Key conventions

- Only Git-tracked files deploy (`manifest = "git"`). Add the file at the matching source path and `git add` it; no new `[dotfiles]` entry needed.
- Never apply dotfiles with `--force`: it can replace repo sources with self-referential links. Resolve conflicts by hand.
- Host-only tools/packages go in `config.<host>.toml`.
- Missing tool: `MISE_AUTO_INSTALL=false mise exec <tool>@<version> -- <cmd>`. No global installs. Change tool config only when asked.
- Pi config lives in `home/.pi/` (see `home/.pi/AGENTS.md`). Prefix with `_` to disable an extension, skill, prompt, or agent.
- `config/{git,jj,zsh,atuin,worktrunk}/` have their own AGENTS.md; read it before editing there.
- Hammerspoon: reload only with `bin/hs-reload`. Anything else crashes it.

## Tests and checks

- Tests live in a `tests/` dir under the owning config or tool (`config/hammerspoon/tests/`, `home/.pi/tests/`, `mise/tests/`, `bin/tests/`). Root `tests/` is only for bootstrap/system checks. This overrides the global "tests next to the file" rule.
- TS (Pi extensions, skill scripts): run `mise run check:ts` before finishing; `mise run fmt:ts` formats. In a fresh clone or worktree, run `mise run deps:ts` first.
- hk runs the git hooks (`hk.pkl`). Don't bypass them.

## Interactive input and secrets

- TTY input (sudo, logins, PINs): use `interactive_shell`, not Bash. For sudo, check `sudo -n true`; if it isn't cached, run `sudo -v` in the overlay, then the real command in Bash.
- op/fnox failing: run `op whoami`; on "operation not permitted", restart the terminal app and tmux server, then `pkill -f 'op daemon'`; GUI-free fallback: `export OP_SERVICE_ACCOUNT_TOKEN="$(fnox --profile bootstrap get OP_SERVICE_ACCOUNT_TOKEN)"` (YubiKey).
