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

`tmux.conf` also installs a global `session-closed` hook. It invokes
`ftm --snapshot-all` for sessions that survive a close. tmux does not expose the
closed session after this hook fires, so a session must be explicitly selected
or killed through `ftm` to guarantee its final snapshot.

## Contract

- Args: `$1` session name, `$2` cwd (session path), `$3` source
  (`layout` | `zoxide` | `default` | `snapshot`)
- Env: `FTM_EVENT`, `FTM_SESSION`, `FTM_CWD`, `FTM_SOURCE`
- Hook failures are swallowed; they never break session creation/switching.
- Snapshots live under `${FTM_STATE_DIR}/snapshots/<session>` and are written
  atomically. Normal `ftm` Enter restores a dead session snapshot before
  consulting layouts. Alt-Enter creates fresh using `default.sh` and bypasses
  snapshots and named layouts.

Note: new sessions without a named layout script already get the default
layout (`layouts/default.sh`) built in — hooks are for extras (env setup,
notifications, per-source tweaks).

To enable a hook: `cp post-create.sh.example post-create.sh && chmod +x post-create.sh`

This mise-managed directory is the sole source for `~/.config/tmux/hooks/`.
