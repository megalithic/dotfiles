---
id: dot-k4o7
status: open
deps: 4:1:deps: 4:1:deps: [, dot-satx, dot-o6bg]
links: []
created: 2026-06-11T11:38:03Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-a9wd
tags: [ready-for-development]
---

# Route Nvim-origin actions through own pair target

Ensure panel and send actions create or use the current Nvim pair before delivery. File hints: config/nvim/lua/pinvim.lua (api.run_panel_command, api.ensure_panel_visible, api.send_explicit_payload, api.send_explicit, api.prompt_explicit, api.compose_flush, <C-p> mappings). Preserve attach-vs-prompt semantics and :PiSplit child behavior.

## Acceptance Criteria

1. <C-p>, gpa/:PiSend, gps, and :PiFlush ensure the current Nvim pair target before sending
2. Nvim B actions do not send to Nvim A live Pi
3. <C-p> still attaches context and does not start an agent turn
4. :PiSplit remains explicit-only and does not replace the main target
5. Existing pinvim behavior still validates with devenv shell -- just validate home
