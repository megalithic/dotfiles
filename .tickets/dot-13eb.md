---
id: dot-13eb
status: closed
deps: []
links: []
created: 2026-06-05T14:38:34Z
type: bug
priority: 2
assignee: Seth Messer
parent: dot-a9wd
tags: [pinvim, bug, ux]
---

# Skip orphaned --embed nvim manifests in repair scan

Pi repair scan picks up nvim manifests from headless --embed nvim processes that were orphaned when their GUI frontend (Neovide/VimR/Firenvim/etc.) quit without reaping the child. These show as repair candidates and cause stale 'nvim-rpc:fallback' + 'repair:nvim:...' footer entries in standalone 'p' launches, even though no real nvim is in use.

Real-world repro: PID 93651 ran for 13h28m with PPID=1, no TTY, no tmux pane, holding bash-LSP and nil (Nix LSP), still heartbeating to ~/.local/state/pi/manifests/nvim-local-0-93651.info every 5s. Triggered repair UI on any 'p' launch in the same tmux session+window.

## Design

Detection in scoreNvimCandidate:

1. After pidAlive check, read /proc-equivalent (ps -o ppid=,tty=) for candidate.pid
2. If ppid==1 AND tty=='??' AND no tmux pane matches candidate.tmux.pane → reject
3. Separately: if candidate.socket && !fs.existsSync(candidate.socket) → reject

Avoid blocking calls — use cached ps output or async fs.access. Keep scan under 50ms.

Related work: see standalone-p fallback UX gap discussed alongside this ticket; a separate ticket may gate the manifest scan on explicit ephemeral/orphan intent.

## Acceptance Criteria

- scoreNvimCandidate (home/common/programs/pi-coding-agent/extensions/pinvim.ts) rejects candidates whose pid has PPID=1 AND no tty AND no matching tmux pane
- candidates whose 'socket' field references a non-existent socket file are also rejected (covers stale-socket case)
- pinvim.lua VimLeavePre still cleans up its own manifest on graceful exit (no regression)
- /pinvim-doctor surfaces 'orphaned --embed nvim ignored' diagnostic when a manifest is skipped for this reason
- lat.md/lat.md 'Bidirectional peer repair' section updated to document the orphan-skip rule
