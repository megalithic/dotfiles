---
id: dot-71if
status: open
deps: []
links: []
created: 2026-05-06T20:07:13Z
type: task
priority: 2
assignee: Seth Messer
---
# Track JANG quantization support in oMLX and evaluate for 32GB megabookpro

JANG (Jang Adaptive N-bit Grading) applies mixed-precision quantization per layer type — attention gets 4-8bit, MLP gets 2-6bit. For MoE models like Qwen3.6-35B-A3B, JANG dramatically outperforms uniform 4-bit: 56.1% HumanEval vs 34.2% (+22 points) at fewer average bits.

Currently NOT in omlx 0.3.8. Two open PRs:
- PR #364: feat: JANG implementation (updated 2026-04-29)
- PR #820: Adds JANG quantized model support to batched engine (updated 2026-04-28)

Blocking bugs:
- #982: JANG dequantizer produces wrong shape for MoE gate_proj
- #967: MiniMax MoE model fails to load — shape mismatch

No JANG code in installed /opt/homebrew/Cellar/omlx/0.3.8/. Not mentioned in release notes through v0.3.9.dev1.

When JANG lands, it could let us run Qwen3.6-35B-A3B on 32GB megabookpro with BETTER quality than current uniform 4-bit — potentially eliminating the need to downsize to 27B.

HuggingFace org: JANGQ-AI (pre-quantized models available).
Source: medium.com/@alexandru_vasile article on adaptive quantization.

See omlx-32gb-models_TASK.md and omlx-32gb-models_PLAN.md in ~/.local/share/pi/plans/dotfiles/ for full research.

## Acceptance Criteria

1. Monitor omlx PRs #364 and #820 for merge status
2. Monitor bugs #982 and #967 for resolution
3. When JANG merges: upgrade omlx (brew upgrade jundot/omlx/omlx), verify JANG code present in installed package
4. Download JANGQ-AI/Qwen3.6-35B-A3B variant (check exact model name on HF when available)
5. Test JANG model loads without errors: curl -s -X POST http://127.0.0.1:8000/v1/chat/completions with JANG model
6. Benchmark: omlx-bench comparing JANG 35B vs uniform-4bit 27B on tok/s and quality (HumanEval-style prompt)
7. If JANG 35B fits in 24GB budget with acceptable perf: update omlx/default.nix and megabookpro.nix to use JANG model as primary
8. Update omlx-32gb-models plan docs with results

