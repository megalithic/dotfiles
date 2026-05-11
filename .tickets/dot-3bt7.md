---
id: dot-3bt7
status: open
deps: []
links: []
parent: dot-0fjk
created: 2026-05-11T17:39:21Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Add enabledModelScopes to settings.json: per-profile model lists

From plan: `~/.local/share/pi/plans/.dotfiles/profile-scoped-pi-models_PLAN.md` (Phase 2)

Extend `settings.json` with `enabledModelScopes` map that overrides `enabledModels` per profile:

```json
{
  "enabledModels": [...],
  "enabledModelScopes": {
    "mega": ["anthropic/claude-opus-4-6", ...],
    "rx": ["rx-anthropic/claude-opus-4-6", ...]
  }
}
```

`enabledModels` remains fallback/default. `enabledModelScopes[PI_PROFILE]` overrides for current session.

## Acceptance Criteria
1. `settings.json` has `enabledModelScopes` with `mega` and `rx` scopes
2. `enabledModels` kept as default/fallback
3. mega scope includes all personal models (anthropic + synthetic + ollama + omlx)
4. rx scope includes only rx-anthropic models
5. nix module generates this correctly
6. `just validate` passes
