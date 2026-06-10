---
id: dot-cczp
status: closed
deps: 4:1:deps: 4:1:deps: [, dot-e5sy, dot-j262]
links: []
created: 2026-06-10T00:34:22Z
type: feature
priority: 2
assignee: Seth Messer
tags: [shade-next, phase-2]
---

# shade-next: real Pi socket fill adapter (inject into live Pi prompt, never submit)

Wire the deferred half of the Pi spike (dot-e5sy): an adapter that actually fills + focuses a live Pi prompt over its control socket (~/.local/state/pi/sockets/pi-\*.sock), backing PiMirror.commitFillAndFocus. PiDiscovery + PiMirror already model resolution/detach/restore/commit safely; this ticket implements the real RPC so 'pi:' commit injects text into the chosen Pi input and focuses it WITHOUT submitting. Honor ambiguity (save draft + ask) and detach/restore rules. Investigate Pi's socket protocol (reference ~/.dotfiles/home/common/programs/pi-coding-agent and current shade NvimSocketManager/MsgpackRpc patterns).

## Acceptance Criteria

1. With exactly one active Pi, 'pi:' commit fills that Pi's input and focuses it; it is never auto-submitted.
2. Ambiguous/none still saves a draft and asks (no guessing).
3. Detach-on-direct-edit and restore-on-empty behaviors hold against the live socket.
4. Tests or documented manual notes cover fill, no-submit, ambiguous, detach, restore.
5. shade-next reads Pi sockets read-only for discovery; current shade untouched.
