---
id: dot-8arp
status: in_progress
deps: []
links: []
created: 2026-05-04T16:40:41Z
type: feature
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Replace Ollama with oMLX as local LLM inference server (Qwen 3.6 + Gemma 4)

Replace Ollama with oMLX (https://github.com/jundot/omlx) as the local LLM inference server in the dotfiles, configured for Qwen 3.6 and Gemma 4 models. oMLX provides continuous batching, tiered KV cache (hot RAM + cold SSD), prefix sharing, and macOS menubar management — optimized for Apple Silicon agent workloads.

Scope:
1. RESEARCH: Evaluate oMLX vs current Ollama setup. oMLX serves on localhost:8000 (OpenAI-compatible /v1 API). Current Ollama on localhost:11434. oMLX has vendor-recommended model presets (omlx_preset.json), built-in model downloader, SpecPrefill, and Claude Code context scaling. Key question: RESEARCH all installation options — nix derivation, homebrew, DMG app, source install — with tradeoffs for each.

2. RESEARCH: Determine optimal quantizations and settings for both hosts:
   - megabookpro (M2 Max, 32GB): RESEARCH best/most recommended quantizations and model variants for 32GB RAM. Need community benchmarks, not just 512GB reference numbers. Qwen3.6-35B-A3B is MoE (only ~3B active params) but total model size still matters for RAM. Gemma-4 variant TBD — need to find what fits with headroom for other processes.
   - rxbookpro (M4 Max, 64GB): RESEARCH best/most recommended quantizations for 64GB RAM. More headroom for larger quants or running both models pinned simultaneously.

   Reference performance (512GB machine, adjust down for smaller RAM):
   - Qwen3.6-35B-A3B-6bit: ~75 tok/s decode, ~2470 tok/s prefill
   - Gemma-4-26b-a4b-it-8bit: ~79 tok/s decode, ~2149 tok/s prefill
   - Gemma-4-31b-it-4bit: ~31 tok/s decode, ~319 tok/s prefill

3. INSTALL/CONFIGURE via nix-darwin/home-manager:
   - Coexistence mode: both ollama and omlx configurable via nix enable/disable flags (not full replacement). Default: omlx enabled, ollama disabled.
   - Update home/common/programs/ollama/default.nix or replace with omlx module
   - Configure model directory, server settings, port (8000)
   - Set up model downloads (omlx CLI or admin dashboard)
   - Apply per-model settings (presets, TTL, pinning, memory limits)
   - Host-specific tuning in home/megabookpro.nix and home/rxbookpro.nix

4. WIRE to consumers:
   - pi-coding-agent: Update models.json (provider baseUrl localhost:8000/v1) and settings.json (enabled models). Currently has ollama/gemma4:e4b and ollama/gemma4:e2b. Replace with omlx-served Qwen 3.6 + Gemma 4 model IDs.
   - Hammerspoon: Check config/hammerspoon/ for any ollama API calls, update to omlx endpoint
   - tmux: Ensure omlx server is accessible from tmux sessions (no Aqua domain issues)
   - neovim: Check config/nvim/ for any LLM/AI plugin configs pointing to ollama, update to omlx

Relevant files:
- home/common/services.nix (ollama launchd agent)
- home/common/programs/ollama/default.nix (model docs)
- home/common/programs/pi-coding-agent/models.json (provider config)
- home/common/programs/pi-coding-agent/settings.json (enabled models)
- home/megabookpro.nix (host-specific overrides)
- home/rxbookpro.nix (host-specific overrides)
- config/hammerspoon/ (check for ollama references)
- config/nvim/ (check for ollama references)

References:
- https://github.com/jundot/omlx (main repo)
- https://github.com/jundot/omlx/releases (v0.3.8 latest, DMG + homebrew)
- https://www.reddit.com/r/LocalLLM/comments/1szeghg/ (Qwen 3.6 35B A3B benchmarks)
- https://www.reddit.com/r/PiCodingAgent/comments/1t1qddb/ (oMLX + pi integration post)

## Model Download Options

5a. **oMLX admin dashboard downloader** — built-in HF search + one-click download. Best UX, requires omlx server running first. No nix integration.
5b. **oMLX CLI** — `omlx serve` discovers models from `--model-dir`. Download manually to that dir. CLI itself has no separate download command (uses HF downloader in admin).
5c. **Manual HuggingFace download** — `huggingface-cli download mlx-community/Qwen3.6-35B-A3B-6bit` to `~/.cache/huggingface/hub/`, then symlink or copy to model dir. oMLX auto-discovers HF cache dir per v0.3.5 feature.
5d. **Nix pre-seed** — fetchFromHurl in nix derivation to download model weights at build time. Problem: models are 5-30GB, nix store would balloon. Re-downloads on every version change. Not recommended.
5e. **Hybrid** — nix manages the omlx package + config + launchd; models are downloaded ad-hoc via admin dashboard or HF CLI into a persistent data dir outside /nix/store. Best of both worlds.

## Acceptance Criteria

1. Research complete: oMLX installation method determined (nix derivation, homebrew, or DMG app) with tradeoffs documented
2. Research complete: optimal model quantizations identified for megabookpro (32GB) and rxbookpro (64GB) with expected performance estimates
3. Research complete: per-model settings documented (presets, TTL, pinning, memory limits, hot_cache_only) per host
4. Ollama launchd agent removed from home/common/services.nix
5. omlx launchd agent or service configured (home/common/services.nix or new module)
6. Model directory and server settings configured (port, model-dir, memory limits)
7. pi-coding-agent models.json updated: provider baseUrl points to localhost:8000/v1 with correct model IDs
8. pi-coding-agent settings.json updated: enabled models list uses omlx-served Qwen 3.6 + Gemma 4
9. Hammerspoon config updated if any ollama references exist
10. Neovim config updated if any ollama references exist
11. tmux sessions can reach omlx API (verified curl from tmux pane)
12. Host-specific settings in megabookpro.nix and rxbookpro.nix for per-host quantization/tuning
13. just validate passes after all changes
14. Existing ollama models directory documented/migrated (not deleted without confirmation)
15. Coexistence mode: ollama and omlx both configurable via nix flags, can run side-by-side on different ports
16. Research complete: model download options documented with tradeoffs (omlx admin downloader, CLI, HF cache, manual, nix pre-seed)

## AC Checklist (2026-05-05)

| AC | Status | Evidence |
|----|--------|----------|
| 1  | ✅ | Brew tap `jundot/omlx` — lowest risk per TASK.md Stream 1 |
| 2  | ✅ | Qwen 4bit both hosts; Gemma 4bit mega / 8bit rx — TASK.md Stream 2 |
| 3  | ✅ | Per-model settings in `omlx/default.nix` + host overrides — TASK.md Stream 4 |
| 4  | ✅ | `services.ollamaAgent.enable = false` (default) in `ollama/default.nix` |
| 5  | ✅ | `launchd.agents.omlx` in `services.nix`, running on :8000 |
| 6  | ✅ | `~/.omlx/settings.json` with XDG dirs, port 8000, host tuning |
| 7  | ✅ | `omlx` provider in `models.json` with qwen3.6 + gemma4 |
| 8  | ✅ | `omlx/qwen3.6` + `omlx/gemma4` in enabledModels |
| 9  | ✅ | No ollama refs in hammerspoon/ (confirmed in research) |
| 10 | ✅ | No ollama refs in active nvim/ (confirmed in research) |
| 11 | ⏳ | Blocked on model pulls — see dot-8arp-phase-2-1 |
| 12 | ✅ | megabookpro.nix + rxbookpro.nix with pinning/TTL/memory |
| 13 | ✅ | `just home` passed 2026-05-05 |
| 14 | ✅ | `~/.ollama/models` untouched (16GB preserved) |
| 15 | ✅ | `services.ollamaAgent.enable` opt-in + omlx default ON |
| 16 | ✅ | TASK.md Stream 3 documents all 5 download options |

**Remaining blocker:** AC 11 (tmux reachability) requires model pulls (dot-8arp-phase-2-1).

