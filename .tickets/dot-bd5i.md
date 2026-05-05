---
id: dot-bd5i
status: in_progress
deps: []
links: []
created: 2026-05-04T20:30:00Z
type: feature
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Migrate to brew-nix + nixify whisperkit-cli + install oMLX (coexistence with ollama)

Modernize the dotfiles homebrew setup by migrating to BatteredBunny's brew-nix overlay for casks, creating a custom nix derivation for whisperkit-cli, and installing oMLX as the only remaining homebrew formula. Then configure oMLX to run alongside ollama (coexistence mode).

This is Phase 1 of the oMLX migration plan (dot-8arp). Combines homebrew modernization with oMLX installation.

**Background:**
- Current setup: nix-darwin `homebrew` module manages 1 formula (whisperkit-cli) + 18 casks via nix-homebrew
- New setup: brew-nix overlay for all casks, whisperkit-cli as nix derivation, omlx as only homebrew formula
- Research findings: whisperkit-cli is highly nixifiable (Swift Package Manager, builds in 169s); omlx is complex (5 git-pinned deps, xgrammar wheel patching) — keep in homebrew for now

**Files:**

**Flake + overlays:**
- flake.nix — add brew-nix + brew-api inputs, add homebrew-jundot-omlx input, update brew_config taps
- overlays/default.nix — add brew-nix.overlays.default

**whisperkit-cli derivation:**
- pkgs/cli/whisperkit-cli.nix — NEW: stdenvNoCC.mkDerivation, fetch from argmaxinc/argmax-oss-swift v1.0.0, build with system swift, install binary
- pkgs/default.nix — add whisperkit-cli to overlay exports

**Cask migration:**
- modules/brew.nix — remove all casks from homebrew.casks, move to comment block; set brews = ["jundot/omlx/omlx"]; keep caskArgs.no_quarantine
- home/common/packages.nix or new home/common/programs/gui-apps.nix — add brewCasks.* to home.packages (1password → _1password for special chars)

**oMLX nix module + service:**
- home/common/programs/omlx/default.nix — NEW: doc-only module + options for programs.omlx.settings and programs.omlx.modelSettings + home.file generation of ~/.omlx/settings.json and ~/.omlx/model_settings.json + activation for model dir creation
- home/common/default.nix — add ./programs/omlx to imports
- home/common/services.nix — add launchd.agents.omlx block (mirror ollama pattern: /opt/homebrew/bin/omlx serve, RunAtLoad, KeepAlive, logs to ~/Library/Logs/omlx/, env vars OMLX_PORT=8000 OMLX_HOST=127.0.0.1) + makeOmlxLogDir activation

**Per-host config:**
- home/megabookpro.nix — programs.omlx.settings overrides: max_model_memory=20GB, hot_cache_max_size=2GB, ssd_cache_max_size=40GB, max_process_memory=75%
- home/rxbookpro.nix — programs.omlx.settings overrides: max_model_memory=48GB, hot_cache_max_size=8GB, ssd_cache_max_size=100GB, max_process_memory=auto

**Helper script:**
- bin/omlx-pull — NEW: wrapper for hf download with alias resolution (qwen3.6/gemma4) and XDG data dir

**Model dir:** ${config.xdg.dataHome}/omlx/models (= ~/.local/share/omlx/models)
**SSD cache dir:** ${config.xdg.cacheHome}/omlx (= ~/.cache/omlx)
**Service management:** custom launchd agent (NOT brew services)

## Acceptance Criteria

**brew-nix migration:**
1. flake.nix has brew-nix and brew-api inputs with inputs.nixpkgs follows
2. overlays/default.nix includes brew-nix.overlays.default
3. pkgs.brewCasks.* is available (test: nix eval .#darwinConfigurations.megabookpro.pkgs.brewCasks._1password)

**whisperkit-cli derivation:**
4. pkgs/cli/whisperkit-cli.nix exists and builds successfully
5. pkgs/default.nix exports whisperkit-cli
6. After just home: which whisperkit-cli resolves to /nix/store path
7. whisperkit-cli --version prints v1.0.0
8. modules/brew.nix no longer lists whisperkit-cli in brews

**Cask migration:**
9. modules/brew.nix has empty (or commented) casks list
10. home.packages includes brewCasks entries for all 18 apps
11. After just home: ls ~/Applications/ shows all GUI apps
12. Spotlight finds migrated apps
13. brew list --cask returns empty or minimal output

**oMLX installation:**
14. flake.nix has homebrew-jundot-omlx input
15. modules/brew.nix brews list contains only "jundot/omlx/omlx"
16. home/common/programs/omlx/default.nix exists with programs.omlx.settings and programs.omlx.modelSettings options
17. home/common/default.nix imports ./programs/omlx
18. home/common/services.nix has launchd.agents.omlx block with ProgramArguments=["/opt/homebrew/bin/omlx" "serve"], RunAtLoad=true, KeepAlive=true, logs to ~/Library/Logs/omlx/
19. home/common/services.nix has home.activation.makeOmlxLogDir
20. After just home: ~/.omlx/settings.json exists with server.port=8000 and model.model_dirs containing xdg data path
21. After just home: ~/.omlx/model_settings.json exists (empty models block ok — populated in next ticket)
22. On megabookpro: ~/.omlx/settings.json has model.max_model_memory=20GB, cache.hot_cache_max_size=2GB
23. On rxbookpro: ~/.omlx/settings.json has model.max_model_memory=48GB, cache.hot_cache_max_size=8GB

**Runtime verification:**
24. launchctl list shows both omlx and ollama agents loaded
25. curl -sf http://127.0.0.1:8000/v1/models returns 200 (empty list ok)
26. curl -sf http://127.0.0.1:11434/api/tags returns 200 (ollama still running)
27. bin/omlx-pull exists and omlx-pull --help prints usage
28. brew list shows only omlx and its dependencies (no casks, no whisperkit-cli)
29. just validate passes
