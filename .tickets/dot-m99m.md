---
id: dot-m99m
status: in_progress
deps: []
links: []
created: 2026-05-06T01:18:17Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Optimize Qwen 3.6 + oMLX + pi-coding-agent on megabookpro

Configure megabookpro to run Qwen 3.6 optimally via oMLX for pi-coding-agent across: Elixir, LiveView, JavaScript, Tailwind, Phoenix, Nix, Neovim, Hammerspoon, Lua, Swift.

End state: concrete nix config changes committed — not just documentation. Every lever/knob for tuning local inference performance identified and wired.

## Performance levers to map

### oMLX server knobs
- Model + quant selection (Q4_K_M, Q5_K_M, Q6_K, unsloth UD variants)
- Context window size (`--context-length`)
- Batch size / parallel requests
- Flash attention, KV cache quantization
- Thinking mode toggle
- Sampling params: temp, top-p, top-k, min-p, presence-penalty, repeat-penalty
- Adapter/LoRA for stack-specific fine-tuning (if applicable)

### Nix config
- oMLX service definition (home/common/services.nix or modules/)
- Model download + path management
- Host-conditional config (megabookpro vs rxbookpro)
- Memory budget coexistence with Hammerspoon, Neovim, browser
- Launchd plist tuning (KeepAlive, MemoryLimit, Nice)

### pi-coding-agent provider config
- Provider endpoint (oMLX OpenAI-compat API)
- Model name mapping
- Context window, temperature, stop tokens
- Thinking budget / mode
- System prompt tweaks for our stack
- Compaction strategy for long sessions

Reference threads:
- https://www.reddit.com/r/LocalLLaMA/comments/1t4ji36/use_qwen36_right_way_send_it_to_pi_coding_agent/
- https://www.reddit.com/r/LocalLLaMA/comments/1t4e046/running_a_26b_llm_locally_with_no_gpu/

## Thread 1 research: "Use Qwen3.6 right way → send it to pi coding agent and forget"

Key insights from r/LocalLLaMA (9h old, 52 upvotes, 70 comments):

- **OP (Willing-Toe1942)**: Uses pi.dev + exa web search + agent-browser extension. Qwen3.6 35B-A3B (MoE) with unsloth UD Q4 XL quant. 36 t/s usable. Solves 80% of use cases (coding, sysadmin, web research).
- **llama.cpp server config** (from OP):
  - `--flash-attn on --no-mmap --jinja`
  - `--temp 0.7 --top-p 0.95 --top-k 20 --min-p 0.00`
  - `--presence-penalty 1.5`
  - `--ctx-size 600000` (600K context!)
  - `--cont-batching -np 3 -b 4096 -ub 2048` (3 parallel requests)
  - `--chat-template-kwargs '{"preserve_thinking": true}'`
  - Uses llama-swap for model swapping
- **Comfortable-Crew-919**: M4 Pro 64GB via oMLX, Qwen3.6 with recommended coding settings, 128k context. Uses gsd-2 (built on pi).
- **Cupakov**: Specifying preferred tech stack in system prompt + Matt Pocock's /grill-me skill. Persistent memory not useful.
- **epicfilemcnulty**: Minimal harness (4 tools: read/write/edit/bash) + custom skills for planning. Works great.
- **Looping issue**: Qwen 35B & 27B loop regardless of harness (even Claude Code). Fix: unsloth UD Q4 quant eliminates looping (OP). Others: run bigger context window + compact more often.
- **Pi vs OpenCode**: Pi is more context-efficient, better for fire-and-forget. OpenCode more structured/interactive but slower. Pi wins on speed for Qwen 3.6.
- **Extensions mentioned**: @feniix/pi-exa (web search), pi-agent-browser-native, pi-web-access, firecrawl (self-hosted)
- **Thinking mode**: Can be toggled via `--chat-template-kwargs '{"preserve_thinking": true}'`

## Thread 2 research: "Running a 26B LLM locally with no GPU"

Key insights (13h old, 102 upvotes, 71 comments):

- **OP (JackStrawWitchita)**: Gemma 4 26B MoE on i5-8500 + 32GB DDR4-2400, no GPU. Runs "really fast".
- **SettingAgile9080** (detailed benchmark): i7-14700K + 96GB DDR5, Gemma 4 26B-A4B Q4_K_XL:
  - PP: ~90 tok/s, TG: ~13 tok/s
  - Asymmetric threads: `--threads 8 --threads-batch 28` (TG bandwidth-bound at 8, PP compute-bound scales to 28)
  - Flash attention: +2% PP, +2.5% TG
  - `ubatch=512` optimal (below 256 PP collapses)
  - f16 KV cache, no mmap diff with mlock
  - Full serve script with docker + llama.cpp provided
- **Key takeaway**: MoE models with 3-4B active params run great on CPU. Active params matter more than total.
- **ArchdukeofHyperbole**: Dense 7B barely usable on PC and causes lag. MoE 2-3B active params fine.
- **Ordynar**: Qwen 3.6 35B A3B on Intel Core Ultra 7 270K+ with 6000MHz CL28: 19 t/s initially, drops to 10 t/s after 22K context. Prompt processing 50-100 t/s.

## Apple Silicon implications for megabookpro

megabookpro = M-series (likely M3/M4 Pro with 36/48GB unified memory). Key differences vs CPU-only in threads:
- Unified memory = much higher bandwidth than DDR4/5 → higher tok/s
- Apple GPU cores can accelerate inference (MLX/oMLX)
- MoE models (Qwen 3.6 35B-A3B, 35B total / 3B active) are ideal: low active params = fast
- oMLX on Apple Silicon likely beats llama.cpp CPU-only by significant margin
- 128K context feasible with 36-48GB unified memory

Related: dot-8arp (replace ollama with oMLX), dot-bd5i (brew-nix + oMLX coexistence), dot-j9q6 (configure oMLX models + wire pi provider)
See: home/common/programs/pi-coding-agent/, home/common/services.nix (omlx), pkgs/default.nix

## Acceptance Criteria

1. ~~Reddit threads fetched and key insights summarized~~ (done — see Thread 1 & 2 research above)
2. oMLX server config committed in nix: model, quant, context window, batch size, sampling params, thinking mode — all configurable via nix opts
3. Model downloaded and served via oMLX on megabookpro (verified: `curl localhost:<port>/v1/models` returns Qwen 3.6)
4. pi-coding-agent provider config committed: oMLX endpoint, model name, context window, temp, stop tokens, thinking budget
5. Memory budget documented: model footprint + Hammerspoon + Neovim + browser stays within unified memory with headroom
6. All performance knobs documented in AGENTS.md or inline comments: what each lever does, trade-offs, recommended defaults for coding
7. `just validate` passes after all changes
8. Side-by-side tok/s benchmark: oMLX vs ollama on same model (even if ollama removed later, confirms oMLX is the right choice)

