# oMLX — Apple Silicon native LLM inference server
#
# Repo:   https://github.com/jundot/omlx
# Tap:    jundot/omlx (registered in flake.nix)
# Brew:   /opt/homebrew/bin/omlx (installed via modules/brew.nix)
# API:    OpenAI-compat at http://127.0.0.1:8000/v1
# Admin:  http://127.0.0.1:8000/admin
#
# Settings precedence (per upstream): CLI > env > settings.json
# Files written by this module:
#   ~/.omlx/settings.json         (global, from programs.omlx.settings)
#   ~/.omlx/model_settings.json   (per-model, from programs.omlx.modelSettings)
#
# Model directory: ${XDG_DATA_HOME}/omlx/models  (= ~/.local/share/omlx/models)
# SSD cache dir:   ${XDG_CACHE_HOME}/omlx        (= ~/.cache/omlx)
#
# Pulling models (run manually after first rebuild):
#   omlx-pull qwen3.6   # ~19 GB, primary text/reasoning model
#   omlx-pull gemma4    # ~14.6 GB (4bit) or ~26 GB (8bit) per host
#
# Service is a user launchd agent defined in home/common/services.nix.
# Toggle with `services.omlx.enable` (default true; ollama is opt-in via
# `services.ollama.enable`).
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.programs.omlx;
  modelDir = "${config.xdg.dataHome}/omlx/models";
  cacheDir = "${config.xdg.cacheHome}/omlx";

  # Default global settings. Per-host overrides via programs.omlx.settings.
  defaultSettings = {
    server = {
      host = "127.0.0.1";
      port = 8000;
    };
    model = {
      model_dirs = [modelDir];
    };
    cache = {
      enabled = true;
      ssd_cache_dir = cacheDir;
    };
    auth = {
      skip_api_key_verification = false;
    };
  };

  # Default per-model settings (mirrors dot-8arp Stream 4 + PLAN Phase 2.2/3.2).
  # Hosts override in megabookpro.nix/rxbookpro.nix for is_pinned, ttl_seconds, etc.
  defaultModelSettings = {
    version = 1;
    models = {
      "Qwen3.6-35B-A3B-4bit" = {
        model_alias = "qwen3.6";
        max_tokens = 8192;
        reasoning_parser = "qwen";
        enable_thinking = true;
        specprefill_enabled = true;
        specprefill_threshold = 8192;
        specprefill_keep_pct = 0.2;
      };
      "gemma-4-26b-a4b-it-4bit" = {
        model_alias = "gemma4";
        max_context_window = 32768;
        # Gatekeeper uses this model — lock enable_thinking to prevent token burn
        chat_template_kwargs = { enable_thinking = false; };
        forced_ct_kwargs = [ "enable_thinking" ];
      };
      "gemma-4-26b-a4b-it-8bit" = {
        model_alias = "gemma4";
        max_context_window = 65536;
        # Gatekeeper uses this model — lock enable_thinking to prevent token burn
        chat_template_kwargs = { enable_thinking = false; };
        forced_ct_kwargs = [ "enable_thinking" ];
      };
    };
  };

  # Recursive merge so per-host overrides only need to set leaves.
  mergedSettings = lib.recursiveUpdate defaultSettings cfg.settings;
  mergedModelSettings = lib.recursiveUpdate defaultModelSettings cfg.modelSettings;
in {
  options.programs.omlx = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable oMLX launchd agent (default ON).";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = ''
        Global oMLX settings rendered to ~/.omlx/settings.json.
        Merged on top of sensible defaults (localhost:8000, XDG dirs).
      '';
    };

    modelSettings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = ''
        Per-model oMLX settings rendered to ~/.omlx/model_settings.json.
        Use `models.<key> = { ... }` shape per upstream model_settings.py.
      '';
    };
  };

  config = {
    # Write settings via activation script (out-of-store, writable by omlx).
    # home.file creates /nix/store symlinks which are read-only — omlx crashes
    # on startup when it tries to save merged settings back to settings.json.
    home.activation.writeOmlxSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p "${config.home.homeDirectory}/.omlx"
      cat > "${config.home.homeDirectory}/.omlx/settings.json" <<'OMLX_SETTINGS'
      ${builtins.toJSON mergedSettings}
      OMLX_SETTINGS
      cat > "${config.home.homeDirectory}/.omlx/model_settings.json" <<'OMLX_MODEL_SETTINGS'
      ${builtins.toJSON mergedModelSettings}
      OMLX_MODEL_SETTINGS
    '';

    # Ensure model and cache directories exist for the launchd agent.
    home.activation.makeOmlxDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p ${modelDir}
      mkdir -p ${cacheDir}
    '';
  };
}
