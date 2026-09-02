# llama.cpp — local LLM inference server (OpenAI-compat API)
#
# Repo:   https://github.com/ggml-org/llama.cpp
# Pkg:    pkgs.llama-cpp (nixpkgs, Metal + server on aarch64-darwin)
# Bin:    llama-server (router mode with --models-dir)
# API:    OpenAI-compat at http://127.0.0.1:18080/v1
#
# This module configures llama-server in router mode: it scans --models-dir
# for GGUF files and serves them via aliases. Models are loaded on demand
# (or at boot with --models-autoload), up to --models-max simultaneous.
#
# Model directory: ${XDG_DATA_HOME}/llama.cpp/models  (= ~/.local/share/llama.cpp/models)
# Log directory:    ~/Library/Logs/llama-cpp/
#
# Pulling models (run manually after first rebuild, or use llm-pull):
#   llm-pull -b llamacpp qwen3.6      # Qwen3.6-27B Q4_K_M GGUF
#   llm-pull -b llamacpp deepseek14b  # DeepSeek-R1-Distill-Qwen-14B Q4_K_M GGUF
#   llm-pull -b llamacpp gemma4       # Gemma-4-e4b-it Q4_K_M GGUF
#
# Service is a user launchd agent defined in this module.
# Toggle with `programs.llamaCppLocal.enable` (default false; opt-in per host).
#
# Per-host tuning: set options in home/<hostname>.nix:
#   programs.llamaCppLocal.enable = true;
#   programs.llamaCppLocal.modelsMax = 1;       # conservative on 32GB
#   programs.llamaCppLocal.ctxSize = 8192;
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.programs.llamaCppLocal;
  modelDir = "${config.xdg.dataHome}/llama.cpp/models";
in
{
  options.programs.llamaCppLocal = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable llama.cpp local inference launchd agent (opt-in, default OFF).";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.llama-cpp;
      defaultText = "pkgs.llama-cpp";
      description = "llama.cpp derivation to use. Must provide bin/llama-server.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Bind address for llama-server. Localhost-only for security.";
    };

    port = lib.mkOption {
      type = lib.types.int;
      default = 18080;
      description = "Port for llama-server. 18080 avoids common dev ports 8080/8000 and old Ollama 11434.";
    };

    modelDir = lib.mkOption {
      type = lib.types.str;
      default = modelDir;
      description = "Directory containing GGUF model files. Router mode scans this dir for models.";
    };

    modelsMax = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "Maximum number of models loaded simultaneously in router mode. 1 for 32GB hosts, 2 for 64GB.";
    };

    ctxSize = lib.mkOption {
      type = lib.types.int;
      default = 8192;
      description = "Default prompt context size per slot. Raised on hosts with more RAM.";
    };

    parallel = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "Number of parallel server slots (concurrent requests). Single-user = 1 safe default.";
    };

    cacheTypeK = lib.mkOption {
      type = lib.types.enum [
        "f32"
        "f16"
        "bf16"
        "q8_0"
        "q4_0"
        "q4_1"
        "iq4_nl"
        "q5_0"
        "q5_1"
      ];
      default = "q8_0";
      description = "KV cache data type for K. q8_0 halves KV cache memory vs f16.";
    };

    cacheTypeV = lib.mkOption {
      type = lib.types.enum [
        "f32"
        "f16"
        "bf16"
        "q8_0"
        "q4_0"
        "q4_1"
        "iq4_nl"
        "q5_0"
        "q5_1"
      ];
      default = "q8_0";
      description = "KV cache data type for V. q8_0 halves KV cache memory vs f16.";
    };

    flashAttn = lib.mkOption {
      type = lib.types.enum [
        "on"
        "off"
        "auto"
      ];
      default = "on";
      description = "Flash attention mode. Required for q8_0 KV cache on most models.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra CLI arguments appended to llama-server invocation.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure directories exist for the launchd agent.
    home.activation.makeLlamaCppDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p ${cfg.modelDir}
      mkdir -p ${config.home.homeDirectory}/Library/Logs/llama-cpp
    '';

    launchd.agents.llama-cpp = {
      enable = true;
      config = {
        ProgramArguments = [
          "${cfg.package}/bin/llama-server"
          "--host"
          cfg.host
          "--port"
          (toString cfg.port)
          "--models-dir"
          cfg.modelDir
          "--models-max"
          (toString cfg.modelsMax)
          "-c"
          (toString cfg.ctxSize)
          "--parallel"
          (toString cfg.parallel)
          "--cache-type-k"
          cfg.cacheTypeK
          "--cache-type-v"
          cfg.cacheTypeV
          "--flash-attn"
          cfg.flashAttn
          "--jinja"
          "--cont-batching"
        ]
        ++ cfg.extraArgs;
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/llama-cpp/stdout.log";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/llama-cpp/stderr.log";
      };
    };
  };
}
