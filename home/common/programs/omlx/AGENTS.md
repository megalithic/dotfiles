# oMLX — performance knob reference + memory budget

Apple Silicon native LLM inference server. OpenAI-compat API on
`http://127.0.0.1:8000/v1`. Driven by pi-coding-agent for daily coding work
(Elixir/Phoenix/LiveView, JS/Tailwind, Nix, Neovim/Lua, Hammerspoon, Swift).

This doc maps every tuning lever surfaced through nix to its trade-off and the
recommended setting per host. Source of truth for nix:

- `home/common/programs/omlx/default.nix` — module + global defaults
- `home/megabookpro.nix` — M2 Max / 32 GB overrides
- `home/rxbookpro.nix` — M4 Max / 64 GB overrides
- `home/common/services.nix` — launchd agent

After editing: `just home` (apply) or `just validate home` (build only).

## Knob reference

### Server-level (`programs.omlx.settings.*`)

Rendered to `~/.omlx/settings.json` by activation script. Precedence: CLI flags
> env > settings.json > omlx defaults.

| Path | Default (this repo) | Trade-off |
|---|---|---|
| `server.host` | `127.0.0.1` | Bind addr. Localhost-only for security. |
| `server.port` | `8000` | API port. |
| `model.model_dirs` | `[~/.local/share/omlx/models]` | Where models are discovered (subdir per model). |
| `model.max_model_memory` | `20GB` (mega) / `48GB` (rx) | Hard cap on combined loaded-model RAM. Below this, LRU eviction kicks in. Set to total model footprint of pinned + ~1 hot. |
| `memory.max_process_memory` | `75%` (mega) / `auto` (rx) | Total process RAM cap. `auto` ≈ `RAM − 8 GB`. Lower if Hammerspoon/browser starve. |
| `scheduler.max_concurrent_requests` | `4` | Parallel inflight requests. Pi-coding-agent issues 1–2; >4 wastes KV-cache RAM unless serving multiple agents. Bump to 8 on rx for parallel sessions. |
| `cache.enabled` | `true` | Master switch for paged SSD KV cache (prefix sharing across requests). |
| `cache.ssd_cache_dir` | `~/.cache/omlx` | Cold KV cache on SSD. |
| `cache.ssd_cache_max_size` | `40GB` (mega) / `100GB` (rx) | Larger = more prefix-cache hits across long sessions. Costs disk. |
| `cache.hot_cache_max_size` | `2GB` (mega) / `8GB` (rx) | In-RAM tier above SSD cache. `0` disables. Bigger = lower TTFT on long contexts but eats unified memory. |
| `cache.initial_cache_blocks` | `256` | KV blocks pre-allocated at startup. Higher = less dynamic-allocation overhead at long contexts; default fine for 32–65 K windows. |
| `auth.skip_api_key_verification` | `false` | Localhost-only bind already gates access; flip true only if reverse-proxied. |
| `sampling.{temperature,top_p,top_k,repetition_penalty,max_tokens,max_context_window}` | omlx defaults | **Global fallback.** Per-model `model_settings.json` always wins. Only edit if adding a model without its own block. |

### Per-model (`programs.omlx.modelSettings.models.<id>.*`)

Rendered to `~/.omlx/model_settings.json`. Per-model overrides global sampling.

| Field | Purpose |
|---|---|
| `model_alias` | Friendly name (`qwen3.6`, `gemma4`) used by clients. Lets us swap quants without changing pi config. |
| `max_context_window` | Per-model context cap. Memory ≈ 2·layers·heads·head_dim·tokens·dtype. 32 K @ 4-bit Qwen3.6 ≈ 1.5 GB KV. |
| `max_tokens` | Default max output tokens (8192 for coding — long completions on diff/edit). |
| `is_pinned` | `true` keeps model resident; ignores LRU. Pin daily-driver Qwen on mega; pin both on rx. |
| `ttl_seconds` | Idle eviction. `null` = never. `600` = 10 min idle → unload. Use for secondary models. |
| `enable_thinking` | Qwen-only: turn on `<thinking>` blocks. Bake `true` for Qwen, lock `false` on Gemma4 (gatekeeper) via `forced_ct_kwargs`. |
| `reasoning_parser` | `qwen` strips `<thinking>` from final answer for Qwen. |
| `chat_template_kwargs` | Passed into Jinja chat template (e.g. `enable_thinking`). |
| `forced_ct_kwargs` | List of `chat_template_kwargs` keys clients cannot override. Use to lock Gemma4 thinking off. |
| `temperature` / `top_p` / `top_k` / `min_p` / `presence_penalty` | Sampling. Defaults follow upstream `omlx_preset.json` (Qwen → `qwen3-r-code`, Gemma4 → `gemma4`). |
| `specprefill_enabled` | Speculative prefill of long prompts (Qwen-MoE only). Cuts TTFT on >8 K prompts. |
| `specprefill_threshold` | Minimum prompt length to trigger SpecPrefill (`8192`). |
| `specprefill_keep_pct` | Fraction of speculatively-prefilled tokens to retain (`0.2`). |

### Pi-coding-agent compat (`models.json` provider compat)

| Field | Value | Why |
|---|---|---|
| `compat.supportsDeveloperRole` | `false` | oMLX is OpenAI Chat Completions; no `developer` role. |
| `compat.supportsReasoningEffort` | `false` | Reasoning level is server-side via `enable_thinking`, not request param. |
| `compat.thinkingFormat` (qwen3.6 only) | `qwen-chat-template` | Pi sends `chat_template_kwargs.enable_thinking` per request — server-resolved against `forced_ct_kwargs`. |

## Memory budget (megabookpro, M2 Max, 32 GB unified)

Worst-case steady-state when pi is active, browser open, Hammerspoon running:

| Component | Footprint |
|---|---|
| Qwen3.6-35B-A3B 4-bit weights (pinned) | ~19 GB |
| Qwen KV cache @ 32 K context | ~1.5 GB |
| Gemma4-26B-A4B 4-bit weights (TTL, may be unloaded) | ~14.6 GB |
| Hot KV cache (`cache.hot_cache_max_size`) | 2 GB |
| oMLX runtime overhead | ~1 GB |
| **oMLX subtotal (Qwen pinned only)** | **~24 GB** |
| **oMLX subtotal (both loaded, transient)** | **~38 GB** *(triggers eviction)* |
| Hammerspoon | ~150 MB |
| Brave Nightly + ~10 tabs | 2–4 GB |
| Neovim + LSPs (basedpyright, eslint, etc.) | 0.5–1 GB |
| macOS + system | 4–6 GB |
| **Headroom target** | **≥ 4 GB** |

**Verdict.** 32 GB fits Qwen-pinned-only comfortably. Gemma4 must stay TTL'd
(eviction policy in `home/megabookpro.nix`). `model.max_model_memory = 20GB`
caps loaded-model RAM so Gemma4 cannot co-resident with Qwen.

## Memory budget (rxbookpro, M4 Max, 64 GB unified)

| Component | Footprint |
|---|---|
| Qwen3.6-35B-A3B 4-bit (pinned) | ~19 GB |
| Gemma4-26B-A4B 8-bit (pinned) | ~26 GB |
| KV cache (both, 65 K each) | ~4 GB |
| Hot KV cache | 8 GB |
| oMLX runtime | ~1 GB |
| **oMLX subtotal** | **~58 GB** |
| Headroom for browser/IDE/system | ~6 GB |

64 GB supports dual-pinned. `max_model_memory = 48GB` allows both to coexist.

## Tok/s expectations (Apple Silicon, single user)

Reference numbers from upstream and r/LocalLLaMA threads (linked in
`tk show dot-m99m`):

| Host | Model | Decode | Prefill | Notes |
|---|---|---|---|---|
| M2 Max 32 GB | Qwen3.6-35B-A3B-4bit | ~67 tok/s (measured) | ~600–800 tok/s | MoE 3 B active params; warm, 256-tok output |
| M4 Max 64 GB | Qwen3.6-35B-A3B-4bit | ~75–100 tok/s | ~1500–2000 tok/s | |
| M4 Max 64 GB | Gemma4-26B-A4B-8bit | ~60–75 tok/s | ~1500–2000 tok/s | |

Validate against your host with `bin/omlx-bench` (Phase 4).

## Tuning playbook

| Symptom | Knob to twist |
|---|---|
| First-token latency too high | `cache.hot_cache_max_size` ↑, `cache.initial_cache_blocks` ↑, `specprefill_*` (Qwen) |
| Throughput low under parallel sessions | `scheduler.max_concurrent_requests` ↑ (costs RAM) |
| Hammerspoon/browser sluggish | `memory.max_process_memory` ↓, `model.max_model_memory` ↓ |
| Model loops on long contexts | `presence_penalty` ↑ (Qwen general preset uses 1.5), reduce `temperature`, compact pi session |
| Output too random for code | `temperature` ↓ (0.6 baked), `top_p` ↓ |
| Gemma4 wastes tokens on thinking | already locked off via `forced_ct_kwargs` — verify in `~/.omlx/model_settings.json` |
| Pi treats qwen3.6 as non-reasoning | check `compat.thinkingFormat = "qwen-chat-template"` in `models.json` |

## Per-stack hints (system-prompt territory, not nix-managed)

Pi-coding-agent prompt should mention preferred stack so Qwen biases output:

- Elixir / Phoenix / LiveView / Tailwind
- JavaScript (no TS unless asked)
- Nix flakes (nix-darwin + home-manager)
- Neovim (Lua), Hammerspoon (Lua), Swift (macOS)

Add via `~/.pi/agent/AGENTS.md` (already nix-managed in
`home/common/programs/pi-coding-agent/sources/`). Not duplicated here to keep
this doc machine-knob focused.

## Verification

```bash
# Service running
launchctl print gui/$(id -u)/org.nix-community.home.omlx 2>&1 | grep state

# API up
curl -sS http://127.0.0.1:8000/v1/models | jq '.data[].id'

# Settings rendered
jq '.scheduler, .cache, .memory' ~/.omlx/settings.json
jq '.models | keys' ~/.omlx/model_settings.json

# Sampling defaults applied
jq '.models["Qwen3.6-35B-A3B-4bit"] | {temperature, top_p, top_k}' \
  ~/.omlx/model_settings.json
```
