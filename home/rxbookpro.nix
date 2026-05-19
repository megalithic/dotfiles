# rxbookpro (work laptop) home-manager configuration
# Imports shared config + adds host-specific overrides
{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./common
  ];

  # ===========================================================================
  # llama.cpp — primary local inference for 64GB work laptop
  # ===========================================================================
  # Migration from oMLX: use llama-server router mode with two loaded GGUF models
  # and two parallel slots. 32K context, q8_0 KV cache, and flash attention are
  # tuned for 64GB unified memory while keeping conservative headroom for work apps.
  programs.llamaCppLocal = {
    enable = true;
    modelsMax = 2;
    ctxSize = 32768;
    parallel = 2;
    cacheTypeK = "q8_0";
    cacheTypeV = "q8_0";
    flashAttn = "on";
  };

  # Legacy local inference backends disabled while llama.cpp replaces them.
  services.ollamaAgent.enable = false;
  programs.omlx.enable = false;

  # Preserved oMLX tuning from dot-8arp Phase 2.3 until obsolete wiring cleanup.
  programs.omlx.settings = {
    model.max_model_memory = "48GB";
    cache.hot_cache_max_size = "8GB";
    cache.ssd_cache_max_size = "100GB";
    memory.max_process_memory = "auto";
  };

  # Preserved oMLX model settings; llama.cpp now owns active serving defaults.
  programs.omlx.modelSettings.models = {
    "Qwen3.6-35B-A3B-4bit" = {
      is_pinned = true;
      max_context_window = 65536;
    };
    "gemma-4-26b-a4b-it-8bit" = {
      is_pinned = true;
      max_context_window = 65536;
    };
  };

  # Work-specific overrides
  # Example: different email config, work tools, etc.
}
