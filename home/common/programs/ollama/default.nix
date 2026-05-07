# Ollama - Local LLM inference (safe memory management on constrained hosts)
#
# Default ON for megabookpro (32GB) — Ollama handles sequential model swap
# safely, refusing to dual-load past physical RAM. oMLX is unsafe on 32GB
# (Jetsam OOM kills, see oMLX #702). rxbookpro (64GB) uses oMLX instead.
#
# Enable per host:
#   home/<hostname>.nix: services.ollamaAgent.enable = true;
#
# Model directory: ${XDG_DATA_HOME}/ollama (= ~/.local/share/ollama/)
#   Parallel to oMLX at ~/.local/share/omlx/models/
#
# Models (pull manually after first rebuild, or use llm-pull):
#   llm-pull qwen3.6             # Dense 27B Q4_K_M, ~16GB, primary coding/reasoning
#   llm-pull deepseek14b         # R1 distill 14B Q4_K_M, ~8GB, reasoning specialist
#   llm-pull gemma4              # Gemma 4 MoE ~4B active Q4_K_M, ~9GB, vision + light
#
# ⚠️ qwen3.6:latest is the MoE 35B-A3B variant (22GB) — always use :27b explicitly.
#
# Check status:
#   ollama list
#   curl http://localhost:11434/api/tags
{
  config,
  pkgs,
  lib,
  ...
}: {
  options.services.ollamaAgent = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable ollama launchd agent (opt-in, default OFF).";
    };

    extraEnv = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = ''
        Host-specific ollama environment variables merged into the launchd agent.
        Use for memory tuning: OLLAMA_MAX_LOADED_MODELS, OLLAMA_GPU_OVERHEAD,
        OLLAMA_CONTEXT_LENGTH, etc.
      '';
    };
  };
}
