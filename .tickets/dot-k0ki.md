---
id: dot-k0ki
status: in_progress
deps: []
links: []
created: 2026-05-20T20:53:46Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---

# Add attach-only pinvim context delivery that avoids stop-hook turns

Add an attach-only context path for pinvim so Neovim can send focused file/selection/cursor context without starting an agent turn, without making pi ask what the user needs, and without triggering stop-hook follow-ups. Keep current explicit prompt behavior available for cases where the user wants to immediately ask something.

Background: current gpa/:PiSend explicit_send path in config/nvim/lua/pinvim.lua sends an explicit_send frame to home/common/programs/pi-coding-agent/extensions/pinvim.ts. pinvim.ts formats the context and calls pi.sendUserMessage(...). sendUserMessage always starts an agent turn, so context-only sends produce a no-task turn and can interact badly with stop-hook. Desired model: context can be attached silently, then injected into the next real user prompt.

Design options to evaluate and document in the ticket implementation:

1. Attach-only pending context: store latest formatted context in pinvim.ts, show UI status/widget, inject it into the next non-extension user prompt. Suggested default.
2. Custom session message: use pi.sendMessage({ customType: 'pinvim-context', ... }, { deliverAs: 'nextTurn' }) if custom messages reliably enter provider context, or combine with a context hook.
3. appendEntry + context hook: persist pending context via pi.appendEntry('pinvim-context', data) and use pi.on('context') to inject it into the next LLM call; most controlled and survives reload if needed.
4. before_agent_start injection: keep pending context and return a hidden/display-controlled message only when a real prompt starts.
5. Two-mode UX: keep gpa/:PiSend as attach-only; keep gps/:PiPrompt as context-plus-prompt / raw prompt that triggers an agent turn.

Suggested implementation: add a delivery/mode field to explicit_send payloads. gpa and :PiSend use delivery='attach' by default. gps sets userInput and uses delivery='prompt' (or equivalent) to trigger the agent. pinvim.ts stores attach-mode context without calling sendUserMessage, then consumes it on the next user-origin input/before_agent_start/context event. Include TTL/replace-latest behavior and status feedback so the user can see context is attached.

Relevant files: config/nvim/lua/pinvim.lua, config/nvim/after/plugin/pinvim.lua, home/common/programs/pi-coding-agent/extensions/pinvim.ts, home/common/programs/pi-coding-agent/extensions/stop-hook.ts, lat.md/lat.md.

## Acceptance Criteria

1. gpa and :PiSend can send cursor/selection context without calling pi.sendUserMessage immediately and without starting an agent turn.
2. gps and :PiPrompt still support immediate user prompt delivery and still start an agent turn intentionally.
3. Pending attached context is injected into the next real non-extension user prompt exactly once, with clear formatting that says it came from Neovim.
4. Attached context has visible status or notification feedback and can be replaced/expired predictably; no stale context is silently reused.
5. stop-hook does not send a follow-up for attach-only context sends because no agent turn is started.
6. Existing pinvim hello/heartbeat/ping behavior, explicit prompt behavior, ephemeral split send behavior, and protocol smoke expectations remain intact.
7. Documentation in lat.md reflects the new attach-only vs prompt-triggering delivery modes.
8. Verification passes: just home; nvim --headless '+lua require("pinvim").setup()' +qa; bin/pinvim-protocol-smoke; manual smoke for gpa attach-only followed by a separate user prompt.
