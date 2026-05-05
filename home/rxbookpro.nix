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
  # oMLX tuning (M4 Max / work laptop, larger unified memory) — dot-8arp Phase 2.3
  # ===========================================================================
  programs.omlx.settings = {
    model.max_model_memory = "48GB";
    cache.hot_cache_max_size = "8GB";
    cache.ssd_cache_max_size = "100GB";
    memory.max_process_memory = "auto";
  };

  # Both pinned — 64GB has headroom for dual-model + KV cache
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
