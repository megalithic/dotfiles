# "provider_product_id": 180User services (launchd agents)
#
#"provider_product_id": 180 This module consolidates user-level launchd agents that run per-user.
# For system-level daemons, see: modules/darwin/services.nix
#
# Usage:
#   imports = [ ./services.nix ];
#
# To add host-specific agents, add them in home/<user>/<hostname>.nix:
#   launchd.agents.my-agent = { ... };
#
{
  config,
  pkgs,
  lib,
  ...
}: {
  # ─────────────────────────────────────────────────────────────────────────────
  # llama.cpp - local LLM inference server (OpenAI-compat API)
  # ─────────────────────────────────────────────────────────────────────────────
  # Router mode: scans --models-dir for GGUF files, serves on 127.0.0.1:18080.
  # Opt-in via programs.llamaCppLocal.enable (default OFF).
  # Per-host tuning: programs.llamaCppLocal.{modelsMax, ctxSize, parallel, ...}
  launchd.agents.llama-cpp = {
    enable = config.programs.llamaCppLocal.enable;
    config = {
      ProgramArguments =
        [
          "${config.programs.llamaCppLocal.package}/bin/llama-server"
          "--host"
          config.programs.llamaCppLocal.host
          "--port"
          (toString config.programs.llamaCppLocal.port)
          "--models-dir"
          config.programs.llamaCppLocal.modelDir
          "--models-max"
          (toString config.programs.llamaCppLocal.modelsMax)
          "-c"
          (toString config.programs.llamaCppLocal.ctxSize)
          "--parallel"
          (toString config.programs.llamaCppLocal.parallel)
          "--cache-type-k"
          config.programs.llamaCppLocal.cacheTypeK
          "--cache-type-v"
          config.programs.llamaCppLocal.cacheTypeV
          "--flash-attn"
          config.programs.llamaCppLocal.flashAttn
          "--jinja"
          "--cont-batching"
        ]
        ++ config.programs.llamaCppLocal.extraArgs;
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/llama-cpp/stdout.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/llama-cpp/stderr.log";
    };
  };

  # ─────────────────────────────────────────────────────────────────────────────
  # oMLX - Apple Silicon native LLM inference
  # ─────────────────────────────────────────────────────────────────────────────
  # Listens on http://127.0.0.1:8000/v1. CLI installed via brew tap
  # (jundot/omlx); see modules/brew.nix and home/common/programs/omlx/.
  #
  # Disabled on megabookpro (32GB): ProcessMemoryEnforcer only tracks Metal
  # allocations, not true RSS — causes Jetsam OOM kills. See oMLX #702.
  # Works on rxbookpro (64GB) where headroom is sufficient.
  launchd.agents.omlx = {
    enable = config.programs.omlx.enable;
    config = {
      ProgramArguments = [
        "/opt/homebrew/bin/omlx"
        "serve"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/omlx/stdout.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/omlx/stderr.log";
      EnvironmentVariables = {
        OMLX_HOST = "127.0.0.1";
        OMLX_PORT = "8000";
      };
    };
  };

  # ─────────────────────────────────────────────────────────────────────────────
  # Ollama - Local LLM inference (legacy, opt-in via services.ollamaAgent.enable)
  # ─────────────────────────────────────────────────────────────────────────────
  # Listening on http://localhost:11434. Opt-in only — default OFF.
  # Enable with: services.ollamaAgent.enable = true; in home/<hostname>.nix
  launchd.agents.ollama = {
    enable = config.services.ollamaAgent.enable;
    config = {
      ProgramArguments = [
        "${pkgs.ollama}/bin/ollama"
        "serve"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/ollama/stdout.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/ollama/stderr.log";
      EnvironmentVariables =
        {
          OLLAMA_MODELS = "${config.xdg.dataHome}/ollama/models";
          OLLAMA_HOST = "127.0.0.1:11434"; # localhost only (security)
          OLLAMA_FLASH_ATTENTION = "1"; # Flash attention (default 0.21.1+, explicit)
          OLLAMA_KV_CACHE_TYPE = "q8_0"; # Halve KV cache memory (requires flash attn)
          OLLAMA_NUM_PARALLEL = "1"; # Single user, single KV alloc
          OLLAMA_KEEP_ALIVE = "30m"; # Keep model loaded 30min (avoid reload latency)
        }
        // config.services.ollamaAgent.extraEnv;
    };
  };

  launchd.agents.espanso = {
    enable = true;
    config = {
      Label = "com.federicoterzi.espanso";
      ProgramArguments = [
        "${config.home.profileDirectory}/bin/espanso"
        "launcher"
      ];
      RunAtLoad = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/espanso/stdout.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/espanso/stderr.log";
    };
  };

  # Home Manager currently emits `launchctl bootout --wait ...`, but macOS 15's
  # launchctl does not support `--wait` for `bootout`; it treats the flag as the
  # target and fails with "Unrecognized target specifier." Keep HM's launcher,
  # minus that unsupported flag, until upstream gates it by macOS version.
  home.activation.setupLaunchAgents = lib.mkForce (lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Disable errexit to ensure we process all agents even if some fail
    set +e

    # Stop an agent if it's running
    bootoutAgent() {
      local domain="$1"
      local agentName="$2"

      verboseEcho "Stopping agent '$domain/$agentName'..."
      local bootout_output
      bootout_output=$(run /bin/launchctl bootout "$domain/$agentName" 2>&1) || {
        # Only show warning if it's not the common "No such process" error
        if [[ "$bootout_output" != *"No such process"* ]]; then
          warnEcho "Failed to stop agent '$domain/$agentName': $bootout_output"
        else
          verboseEcho "Agent '$domain/$agentName' was not running"
        fi
      }
    }

    installAndBootstrapAgent() {
      local srcPath="$1"
      local dstPath="$2"
      local domain="$3"
      local agentName="$4"

      verboseEcho "Installing agent file to $dstPath"
      if ! run install -Dm444 -T "$srcPath" "$dstPath"; then
        errorEcho "Failed to install agent file for '$agentName'"
        return 1
      fi

      verboseEcho "Starting agent '$domain/$agentName'"
      local bootstrap_output
      bootstrap_output=$(run /bin/launchctl bootstrap "$domain" "$dstPath" 2>&1) || {
        local error_code=$?

        if [[ "$bootstrap_output" == *"Bootstrap failed: 5: Input/output error"* ]]; then
          errorEcho "Failed to start agent '$domain/$agentName' with I/O error (code 5)"
          errorEcho "This typically happens when the agent wasn't unloaded before attempting to bootstrap the new agent."
        else
          errorEcho "Failed to start agent '$domain/$agentName' with error: $bootstrap_output"
        fi

        return 1
      }

      verboseEcho "Successfully started agent '$domain/$agentName'"
      return 0
    }

    processAgent() {
      local srcPath="$1"
      local dstDir="$2"
      local domain="$3"

      local agentFile="''${srcPath##*/}"
      local agentName="''${agentFile%.plist}"
      local dstPath="$dstDir/$agentFile"

      # Skip if unchanged and already loaded. If a previous activation copied
      # the plist but failed to bootstrap it, load it now.
      if cmp -s "$srcPath" "$dstPath"; then
        if /bin/launchctl print "$domain/$agentName" >/dev/null 2>&1; then
          verboseEcho "Agent '$agentName' is already up-to-date"
          return 0
        fi

        verboseEcho "Agent '$agentName' is installed but not loaded"
        installAndBootstrapAgent "$srcPath" "$dstPath" "$domain" "$agentName"
        return 0
      fi

      verboseEcho "Processing agent '$agentName'"

      # Stop/Unload agent if it's already running
      if [[ -f "$dstPath" ]]; then
        bootoutAgent "$domain" "$agentName"
      fi

      installAndBootstrapAgent "$srcPath" "$dstPath" "$domain" "$agentName"
      # Note: We continue processing even if this agent fails
      return 0
    }

    removeAgent() {
      local srcPath="$1"
      local dstDir="$2"
      local newDir="$3"
      local domain="$4"

      local agentFile="''${srcPath##*/}"
      local agentName="''${agentFile%.plist}"
      local dstPath="$dstDir/$agentFile"

      if [[ -e "$newDir/$agentFile" ]]; then
        verboseEcho "Agent '$agentName' still exists in new generation, skipping cleanup"
        return 0
      fi

      if [[ ! -e "$dstPath" ]]; then
        verboseEcho "Agent file '$dstPath' already removed"
        return 0
      fi

      if ! cmp -s "$srcPath" "$dstPath"; then
        warnEcho "Skipping deletion of '$dstPath', since its contents have diverged"
        return 0
      fi

      # Stop and remove the agent
      bootoutAgent "$domain" "$agentName"

      verboseEcho "Removing agent file '$dstPath'"
      if run rm -f $VERBOSE_ARG "$dstPath"; then
        verboseEcho "Successfully removed agent file for '$agentName'"
      else
        warnEcho "Failed to remove agent file '$dstPath'"
      fi

      return 0
    }

    setupLaunchAgents() {
      local oldDir newDir dstDir domain

      newDir="$(readlink -m "$newGenPath/LaunchAgents")"
      dstDir=${lib.escapeShellArg "${config.home.homeDirectory}/Library/LaunchAgents"}
      domain="gui/$UID"

      if [[ -n "''${oldGenPath:-}" ]]; then
        oldDir="$(readlink -m "$oldGenPath/LaunchAgents")"
        if [[ ! -d "$oldDir" ]]; then
          verboseEcho "No previous LaunchAgents directory found"
          oldDir=""
        fi
      else
        oldDir=""
      fi

      verboseEcho "Setting up LaunchAgents in $dstDir"
      [[ -d "$dstDir" ]] || run mkdir -p "$dstDir"

      verboseEcho "Processing new/updated LaunchAgents..."
      find -L "$newDir" -maxdepth 1 -name '*.plist' -type f | while read -r srcPath; do
        processAgent "$srcPath" "$dstDir" "$domain"
      done

      # Skip cleanup if there's no previous generation
      if [[ -z "$oldDir" || ! -d "$oldDir" ]]; then
        verboseEcho "LaunchAgents setup complete"
        return
      fi

      verboseEcho "Cleaning up removed LaunchAgents..."
      find -L "$oldDir" -maxdepth 1 -name '*.plist' -type f | while read -r srcPath; do
        removeAgent "$srcPath" "$dstDir" "$newDir" "$domain"
      done
    }

    setupLaunchAgents

    # Restore errexit
    set -e
  '');

  # Ensure log directories exist
  home.activation.makeOllamaLogDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p ${config.home.homeDirectory}/Library/Logs/ollama
  '';

  home.activation.makeOmlxLogDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p ${config.home.homeDirectory}/Library/Logs/omlx
  '';

  home.activation.makeEspansoLogDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p ${config.home.homeDirectory}/Library/Logs/espanso
  '';

  home.activation.makeLlamaCppLogDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p ${config.home.homeDirectory}/Library/Logs/llama-cpp
  '';
}
