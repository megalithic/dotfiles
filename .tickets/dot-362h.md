---
id: dot-362h
status: open
deps: [dot-g8dx]
links: []
created: 2026-05-05T12:23:21Z
type: feature
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Flip default to omlx, make ollama opt-in via nix flag

Disable ollama launchd agent by default (services.ollama.enable = false), remove ollama models from pi enabledModels, and clean up documentation references. omlx becomes the daily driver; ollama remains available via opt-in flag.

This is Phase 4 of the oMLX migration plan. Ollama models directory (~/.ollama/models, 16GB) is preserved — NOT deleted. Full ollama package removal deferred to follow-up ticket.

**Files:**
- home/common/programs/ollama/default.nix — add services.ollama.enable option (default false), add note about opt-in re-enable
- home/common/programs/omlx/default.nix — add services.omlx.enable option (default true) for symmetry
- home/common/services.nix — wrap launchd.agents.ollama in mkIf config.services.ollama.enable; wrap launchd.agents.omlx in mkIf config.services.omlx.enable; same for activation entries
- home/common/programs/pi-coding-agent/settings.json — remove ollama/gemma4:e4b and ollama/gemma4:e2b from enabledModels (keep ollama provider block in models.json for discoverability)
- AGENTS.md, home/AGENTS.md, docs/nix-structure-proposal.md, docs/gui-apps-research.md, home/common/programs/claude-code/default.nix — update ollama doc references to note omlx as default, ollama opt-in

**Coexistence guarantee (AC 15):** Both services.ollama.enable and services.omlx.enable exist as nix flags. Default: omlx=true, ollama=false.

## Acceptance Criteria

1. services.ollama.enable option exists in home/common/programs/ollama/default.nix with default=false
2. services.omlx.enable option exists in home/common/programs/omlx/default.nix with default=true
3. After just home: launchctl list shows omlx agent, does NOT show ollama agent
4. After just home: curl :11434 connection refused, curl :8000/v1/models returns 200
5. pi-coding-agent/settings.json enabledModels no longer includes ollama/* models
6. pi-coding-agent/models.json still has ollama provider block (not deleted — for opt-in re-enable)
7. rg -i ollama in docs/ and AGENTS.md returns only intentional references (opt-in instructions, historical)
8. Setting services.ollama.enable=true in a host file causes ollama agent to load on next just home (verified in scratch branch, not committed)
9. ~/.ollama/models directory still exists (not deleted)
10. just validate passes

