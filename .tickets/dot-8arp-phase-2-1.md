---
id: dot-8arp-phase-2-1
title: Download oMLX models (Qwen 3.6 + Gemma 4) for dot-8arp
description: |
  Pull the actual model weights for oMLX to complete Phase 2.1 of dot-8arp.
  Model downloads are ~34GB total and should run offline/background.
status: proposed
deps: [dot-8arp]
links:
  - ~/.local/share/pi/plans/dotfiles/dot-8arp-replace-ollama-with-omlx_PLAN.md
  - ~/.local/share/pi/plans/dotfiles/dot-8arp-replace-ollama-with-omlx_TASK.md
created: 2026-05-05T10:42:00Z
type: task
priority: 2
assignee: Seth Messer
tags: [omlx, model-download, blocking]
---
# Download oMLX models for dot-8arp

Phase 2.1 follow-up for ticket dot-8arp. Pull actual model weights.

## megabookpro (M2 Max 32GB)

| Model | Quant | On-disk | Peak mem | Settings |
|-------|-------|---------|----------|----------|
| Qwen3.6-35B-A3B | 4bit | ~19 GB | ~20 GB | `is_pinned: true` |
| gemma-4-26b-a4b-it | 4bit | ~14.6 GB | ~15 GB | `is_pinned: false`, `ttl_seconds: 600` |
| **Total** | — | **~33.6 GB** | **~35 GB** | Pin only Qwen |

**Pull commands:**
```bash
mkdir -p ~/.local/share/omlx/models

/opt/homebrew/opt/omlx/libexec/bin/hf download mlx-community/Qwen3.6-35B-A3B-4bit \
  --local-dir ~/.local/share/omlx/models/Qwen3.6-35B-A3B-4bit

/opt/homebrew/opt/omlx/libexec/bin/hf download mlx-community/gemma-4-26b-a4b-it-4bit \
  --local-dir ~/.local/share/omlx/models/gemma-4-26b-a4b-it-4bit
```

## rxbookpro (M4 Max 64GB)

| Model | Quant | On-disk | Peak mem | Settings |
|-------|-------|---------|----------|----------|
| Qwen3.6-35B-A3B | 4bit | ~19 GB | ~22 GB @ 16k | `is_pinned: true` |
| gemma-4-26b-a4b-it | 8bit | ~26 GB | ~26 GB | `is_pinned: true` |
| **Total** | — | **~45 GB** | **~48 GB** | Both pinned, ~16GB headroom |

**Pull commands:**
```bash
mkdir -p ~/.local/share/omlx/models

/opt/homebrew/opt/omlx/libexec/bin/hf download mlx-community/Qwen3.6-35B-A3B-4bit \
  --local-dir ~/.local/share/omlx/models/Qwen3.6-35B-A3B-4bit

/opt/homebrew/opt/omlx/libexec/bin/hf download mlx-community/gemma-4-26b-a4b-it-8bit \
  --local-dir ~/.local/share/omlx/models/gemma-4-26b-a4b-it-8bit
```

## Post-pull verification
- `ls ~/.local/share/omlx/models/` — both directories exist
- `du -sh ~/.local/share/omlx/models/*` — sizes match
- `launchctl kickstart -k gui/$(id -u)/org.nix-community.home.omlx`
- `curl -s http://127.0.0.1:8000/v1/models | jq '.data[].id'` — lists aliases
