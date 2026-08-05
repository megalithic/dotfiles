---
name: interactive-tty
description: "Run commands needing user interaction: sudo-only commands via native Touch ID (with a reason shown to the user), and typed-input flows (logins, prompts) via a tmux display-popup. Use whenever a command fails or would fail with 'no TTY', 'requires a password', or needs human keystrokes."
license: Vibecoded
script: scripts/tty-run.sh
---

# interactive-tty skill

Two modes, one script:

- **sudo mode** — command only needs elevated privileges. User sees WHY sudo
  is needed and WHAT will run; authenticates via the native Touch ID dialog
  (pam_tid), password-in-popup as fallback. The real command then runs with
  cached credentials in the agent's shell, so the agent captures its output.
- **popup mode** — command needs typed input. Runs inside
  `tmux display-popup`: modal, grabs focus, auto-closes, focus returns to the
  invoking pane automatically.

## Usage

```bash
# sudo-only command — -m is REQUIRED: explain why + what it does
~/.pi/agent/skills/interactive-tty/scripts/tty-run.sh sudo \
  -m "Install Tailscale GUI pkg (network extension needs root installer)" -- \
  installer -pkg /path/to/Tailscale.pkg -target /

# typed-input flow
~/.pi/agent/skills/interactive-tty/scripts/tty-run.sh popup -- gh auth login

# mode auto-detects: leading `sudo` in the command selects sudo mode
~/.pi/agent/skills/interactive-tty/scripts/tty-run.sh -m "why" -- sudo whoami
```

Options: `-m` reason (required for sudo mode), `-t` timeout seconds
(default 600), `-w`/`-h` popup size (default 70%/45%, popup mode).

## Behavior details

- sudo mode validates with `sudo -v` inside a popup showing the reason;
  Touch ID dialog appears via pam_tid; cancelled Touch ID falls back to
  typing the password in the popup. With credentials already cached
  (`sudo -n true`), no popup appears at all.
- After validation the command runs as `sudo <command>` in the agent's own
  shell — output/errors are captured normally, not lost in the popup.
- popup mode shows a header (reason + exact command), runs the command, and
  on failure pauses up to 12s ("press Enter to close") so the user can read
  the error before the popup closes.
- Exit codes: the command's own code; `124` timeout; `125` popup closed
  without status; `2` usage / not inside tmux.
- Bounded wait: an abandoned prompt cannot hang the agent; on timeout the
  popup is force-closed (`display-popup -C`) and temp files are removed.

## Agent rules

- sudo mode: write an honest, specific `-m` reason — why root is needed and
  what the command changes. Never bury extra actions in the sudo command.
- Tell the user what input is expected BEFORE invoking, so the focus jump is
  no surprise.
- One invocation at a time; one interactive command per invocation — no
  compound one-liners.
- On exit 124/125, report timeout/abort; do not silently retry.
- sudo credentials stay cached ~5 minutes; group related sudo steps so the
  user authenticates once.
