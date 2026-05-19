---
id: dot-ywgf
status: done
deps: []
links: []
created: 2026-05-19T19:09:43Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-0fjk
tags: [ready-for-development]
---

# Move multi-sub config into settings and add directory profile presets

Update the pi multi-sub/multi-pass configuration flow so the extension can read its configuration from main pi settings.json under a multiSub key, while keeping legacy multi-pass.json compatibility if needed. Add directoryProfiles support for cwd-based preset selection using exact paths or wildcard globs such as ~/code/work/strive/\*\* → rx. Coordinate with pinvim wrapper env handling so explicit profile/env values win and directory-based presets can still drive PI_MODEL_SCOPE before startup.

Relevant files:

- home/common/programs/pi-coding-agent/extensions/multi-sub.ts
- home/common/programs/pi-coding-agent/default.nix (pinvim wrapper)
- home/common/programs/pi-coding-agent/settings.json
- home/common/programs/pi-coding-agent/multi-pass.json
- home/common/programs/pi-coding-agent/AGENTS.md

## Acceptance Criteria

1. settings.json supports a multiSub object containing subscriptions, pools, chains, presets, and directoryProfiles.
2. multi-sub.ts loads multiSub config from settings.json and preserves documented fallback/compatibility behavior for existing multi-pass.json users.
3. directoryProfiles entries accept either path or glob plus preset/profile name; exact paths and wildcard globs both work, including ~/code/work/strive/\*\*.
4. Preset/profile precedence is implemented and documented: --profile > explicit envs (PI_PROFILE, PI_MULTI_PASS_PRESET, PI_SUB_PRESET, PI_PRESET, PI_MODEL_SCOPE) > tmux session > directoryProfiles > mega.
5. pinvim wrapper changes avoid treating wrapper-derived defaults as explicit envs and ensure resolved directory profiles can set PI_MULTI_PASS_PRESET and PI_MODEL_SCOPE before pi starts.
6. Existing preset activation, Ctrl-P model scoping, project allowedSubs enforcement, and /mp-preset command behavior still work.
7. Add or update docs in AGENTS.md/settings comments explaining multiSub.directoryProfiles and precedence.
8. Run relevant validation (at minimum just validate home, or document why skipped) and verify a sample cwd under ~/code/work/strive resolves to rx.
