# ftm hooks

Event hooks for `ftm` (fuzzy tmux session switcher), similar to wt/mise hooks.
`ftm` runs `$TMUX_HOOKS/<event>.sh` (this dir by default) when the script
exists and is executable. Non-executable files (like the shipped `.example`)
are ignored.

## Events

| Hook             | When                                                        |
| ---------------- | ----------------------------------------------------------- |
| `pre-create.sh`  | before a new session is built                               |
| `post-create.sh` | after a new session is built, before switching to it        |
| `post-switch.sh` | after any switch/attach, including freshly created sessions |

## Contract

- Args: `$1` session name, `$2` cwd (session path), `$3` source
  (`layout` | `zoxide` | `default`)
- Env: `FTM_EVENT`, `FTM_SESSION`, `FTM_CWD`, `FTM_SOURCE`
- Hook failures are swallowed; they never break session creation/switching.

Note: new sessions without a named layout script already get the default
layout (`layouts/default.sh`) built in — hooks are for extras (env setup,
notifications, per-source tweaks).

To enable a hook: `cp post-create.sh.example post-create.sh && chmod +x post-create.sh`

This dir is a literal twin: keep `config/tmux/hooks/` and
`mise/config/tmux/hooks/` in sync.
