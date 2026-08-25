---
name: interactive-tty
description: "Run commands needing user interaction — sudo/Touch ID elevation, PINs, passphrases, logins, interactive installers — via pi's native interactive_shell overlay (pi-interactive-shell extension). Use whenever a command fails or would fail with 'no TTY', 'requires a password', or needs human keystrokes."
license: Vibecoded
---

# interactive-tty skill

All interactive flows run in pi's embedded `interactive_shell` overlay
(pi-interactive-shell extension): full PTY, user watches and types directly,
hidden input stays hidden, agent blocks on the `sessionId` until done.

If the `interactive_shell` tool is unavailable, call
`enable_interactive_shell` first (tool becomes callable next turn). If the
extension is not installed: `pi install npm:pi-interactive-shell`.

## sudo / Touch ID flow

Touch ID works natively even under tmux/pi: `/etc/pam.d/sudo_local` has
`pam_reattach.so` + `pam_tid.so` (managed by mise task `setup:touchid-sudo`).
The dialog is GUI — no TTY needed. The overlay exists only to (a) show the
user why sudo is happening and (b) catch the typed-password fallback when
Touch ID is cancelled or unavailable.

```typescript
// 0. Cached already? Run directly, no interaction needed.
//    bash: sudo -n true  → exit 0 means skip to step 3.

// 1. Validate — Touch ID dialog appears; password fallback lands in overlay
interactive_shell({
  command: "sudo -v",
  mode: "interactive",
  reason: "Install Tailscale pkg — root installer. Touch ID or password."
})
// → { sessionId: "calm-reef" }

// 2. Block until validated
interactive_shell({ sessionId: "calm-reef" })
// → { status: "exited", exitCode: 0 }

// 3. Credentials cached (~5 min) — run the real command in the agent's own
//    shell so output is captured normally:
//    bash: sudo installer -pkg /path/to/Tailscale.pkg -target /
```

Rules:

- ALWAYS give an honest, specific `reason` — why root is needed and what the
  command changes. Never bury extra actions in the sudo command.
- Group related sudo steps within the ~5 min credential cache so the user
  authenticates once.
- Exit ≠ 0 from `sudo -v` = declined/failed auth — report it; do not retry
  silently.

## Typed input flow (PINs, passphrases, logins, prompts)

```typescript
// 1. Launch — overlay opens, user types at the prompts
interactive_shell({
  command: "ykman -d 15759055 piv access change-pin",
  mode: "interactive",
  reason: "Change PIV PIN — you will type current + new PIN"
})
// → { sessionId: "calm-reef" }

// 2. Poll status / read output after the user finishes
interactive_shell({ sessionId: "calm-reef" })
// → { status: "exited", exitCode: 0, output: "..." }
```

Rules:

- Tell the user BEFORE launching what prompts to expect and what to type.
- One interactive command per session — no compound one-liners.
- Secrets: let the USER type them in the overlay. Never pass secrets as
  command arguments or `input` strings; never echo them back from `output`.
- Use absolute paths for mise-shim binaries when PATH may differ
  (`command -v <tool>` first, e.g. `/Users/seth/.local/share/mise/shims/ykman`).
- The agent may send non-secret input with
  `interactive_shell({ sessionId, input, submit: true })`.
- Kill a stuck session: `interactive_shell({ sessionId, kill: true })`.
