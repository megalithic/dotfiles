---
id: dot-satx
status: open
deps: []
links: []
created: 2026-06-11T11:38:03Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-a9wd
tags: [ready-for-development]
---

# Add Nvim-owned pinvim pair identity

Generate one pair id per Nvim process and propagate it through Nvim-side pinvim state. File hints: config/nvim/lua/pinvim.lua (Registry.setup, Transport.build_peer_identity, registry_base_record, Registry.write_main_intent, Registry.write_main_session_intent, write_nvim_peer_manifest). Ensure vim.env.PINVIM_PAIR_ID is set for pimux/Pi launch.

## Acceptance Criteria

1. require("pinvim").api.info() reports pairId for the current Nvim instance
2. Nvim manifests and main intent records include the same pairId
3. Restarting Nvim creates a different pairId
4. Child session records do not replace main pair identity
5. Existing pinvim behavior still validates with devenv shell -- just validate home
