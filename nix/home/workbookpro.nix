# workbookpro (work laptop) home-manager configuration
# Imports shared config + adds host-specific overrides
{
  ...
}:
{
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

  # Work-specific overrides
  # Example: different email config, work tools, etc.
}
