---
id: dot-0a9p
status: open
deps: []
links: []
created: 2026-05-15T16:14:09Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---
# Add Shade remote input mode for active-pane pinvim pairing

Add Shade remote-input mode for sending notes/prompts to the pi instance running in the originating terminal tmux pane.

When Hammerspoon invokes Shade with hyper+enter from a terminal app (Ghostty now; Kitty/other terminals later), capture the originating app/window/tmux context and identify the active tmux pane. If that active pane is running pi or maps to a pi socket/manifest, open Shade as a special nvim remote-input buffer paired to that pi instance. This is not normal markdown/Obsidian note capture and should not create/save a note by default.

The paired pi instance remains fixed for the lifetime of the special Shade buffer or Shade nvim instance. Subsequent hyper+enter presses keep existing toggle behavior. hyper+shift+enter continues the existing context-to-note capture path.

Relevant files and areas:
- config/hammerspoon/bindings.lua: hyper+enter and hyper+shift+enter Shade bindings
- config/hammerspoon/lib/interop/shade.lua: Shade launch/context writing and notifications
- ~/code/shade/Sources/ShadeAppDelegate.swift: context capture and note-capture notification handling
- ~/code/shade/Sources/ContextGatherer/ContextGatherer.swift: terminal/tmux/nvim context detection
- ~/code/shade/Sources/ShadeNvim.swift and NvimAPI.swift: opening/focusing nvim buffers
- ~/code/shade/Sources/ShadeServer.swift: Shade RPC handlers if needed
- config/nvim/lua/utils/interop.lua: Shade context reader/RPC client
- config/nvim/lua/plugins/obsidian.lua: current Shade note context behavior to avoid for remote-input mode
- config/nvim/lua/pinvim.lua: pinvim target selection, handshake, send/queue commands
- home/common/programs/pi-coding-agent/extensions/pinvim.ts: pi-side pinvim socket/manifest identity
- bin/tmux-toggle-pi: pi pane/socket detection patterns

Clarifications:
- Detection is active tmux pane first, not session/window. Do not auto-pair merely because another pane in the same tmux window has pi.
- <localleader>ps in the Shade remote-input buffer sends current visual selection, or whole buffer in normal mode, as a steering/follow-up prompt to paired pi.
- <localleader>pn queues current visual selection, or whole buffer in normal mode, into pinvim compose/queue for paired pi unless implementation finds a better explicit queue name; queued content should not be delivered until user flushes through existing or new queue UX.
- Buffer should be unsaveable or clearly non-note by default. Save behavior is intentionally undecided; do not wire normal note save without separate decision.

## Acceptance Criteria

1. hyper+enter from a supported terminal app captures originating tmux session/window/active pane id when available and attempts pairing only against that active pane.
2. If the active tmux pane is running pi or maps to a pi socket/manifest, Shade opens a special nvim remote-input buffer paired to that exact pi instance; it does not open the normal Obsidian markdown capture flow.
3. If no active-pane pi pairing is found, user gets a clear Shade/nvim notification and existing Shade toggle/capture behavior remains unaffected.
4. The paired pi target remains fixed until the special buffer closes or the Shade nvim instance exits; later hyper+enter presses keep normal Shade toggle semantics.
5. In the remote-input buffer, visual <localleader>ps sends selection to paired pi; normal <localleader>ps sends whole buffer to paired pi as an explicit follow-up/steering prompt.
6. In the remote-input buffer, visual <localleader>pn queues selection for paired pi; normal <localleader>pn queues whole buffer for paired pi without immediately sending.
7. Pairing and sends use pinvim.ts-owned socket/handshake path, not bridge.ts nvim behavior.
8. Remote-input buffer is clearly non-note/unsaveable by default or prevents accidental normal note save.
9. Works manually for Ghostty + tmux + pi in active pane; code is structured so Kitty/other terminal context adapters can be added later.
10. Verification includes existing checks (`just home --skip-sync`, `nvim --headless '+lua require("pinvim").setup()' +qa`, `bin/pinvim-protocol-smoke`) plus documented manual Ghostty/tmux/Shade smoke steps.

