{
  inputs,
  config,
  pkgs,
  lib,
  system,
  ...
}:
let
  # inherit (pkgs) pi-coding-agent;
  piPackage = inputs.pi-nix.packages.${system}.coding-agent;

  piStateDir = "${config.xdg.stateHome}/pi";

  plannotatorVersion = "0.20.3";
  plannotator = pkgs.stdenvNoCC.mkDerivation {
    pname = "plannotator";
    version = plannotatorVersion;

    src = pkgs.fetchurl {
      url = "https://github.com/backnotprop/plannotator/releases/download/v${plannotatorVersion}/plannotator-darwin-arm64";
      hash = "sha256-gMGOKz6VeW6FkCtOPsktj3v0nfjr/L0SGVx4T6Ui/do=";
    };

    dontUnpack = true;

    installPhase = ''
      install -Dm755 "$src" "$out/bin/plannotator"
    '';

    meta = {
      description = "CLI for reviewing and annotating plans";
      homepage = "https://github.com/backnotprop/plannotator";
      mainProgram = "plannotator";
      platforms = [ "aarch64-darwin" ];
    };
  };

  sesameVersion = "0.10.0";
  sesame = pkgs.stdenvNoCC.mkDerivation {
    pname = "sesame";
    version = sesameVersion;

    src = pkgs.fetchurl {
      url = "https://github.com/aliou/sesame/releases/download/@aliou/sesame-cli@${sesameVersion}/sesame-darwin-arm64";
      hash = "sha256-euh1FhInwYtjZ882Q6mDsnADcA834ILRr10fDahUxQA=";
    };

    dontUnpack = true;

    installPhase = ''
      install -Dm755 "$src" "$out/bin/sesame"
    '';

    meta = {
      description = "BM25 search for Pi session files";
      homepage = "https://github.com/aliou/sesame";
      license = lib.licenses.mit;
      mainProgram = "sesame";
      platforms = [ "aarch64-darwin" ];
    };
  };

  isEnabledEntry = name: !(lib.hasPrefix "_" name);

  piPackageFiles = builtins.filter (name: lib.hasSuffix ".nix" name && isEnabledEntry name) (
    builtins.attrNames (builtins.readDir ./packages)
  );
  piExtensionPackageFiles = builtins.filter (
    name: lib.removeSuffix ".nix" name != "pi-acp"
  ) piPackageFiles;
  piExtensionPackages = builtins.listToAttrs (
    map (
      fileName:
      let
        name = lib.removeSuffix ".nix" fileName;
      in
      {
        inherit name;
        value = pkgs.callPackage (./packages + "/${fileName}") { };
      }
    ) piExtensionPackageFiles
  );
  piExtensionPackageSymlinks = builtins.listToAttrs (
    map (name: {
      name = ".pi/agent/extensions/${name}";
      value = {
        source = piExtensionPackages.${name};
      };
    }) (builtins.attrNames piExtensionPackages)
  );

  piWrapper = pkgs.writeShellScriptBin "pi" ''
    export PI_STATE_DIR="''${PI_STATE_DIR:-${piStateDir}}"
    mkdir -p "$PI_STATE_DIR/sockets" "$PI_STATE_DIR/manifests" "$PI_STATE_DIR/pinvim"
    unset PIMUX_FROM_NVIM 2>/dev/null || true

    if [ -f "$XDG_CONFIG_HOME/opnix/secrets/env-vars.sh" ]; then
      . "$XDG_CONFIG_HOME/opnix/secrets/env-vars.sh"
    fi

    # Derive lat.md semantic-search config from synthetic key (single source
    # of truth). Mirrors the opnix shell-init derivation so pi sessions launched
    # outside interactive shells (GUI, launchd, subprocesses) still see LAT_LLM_*.
    if [ -n "$SYNTHETIC_API_KEY" ]; then
      export LAT_LLM_KEY="$SYNTHETIC_API_KEY"
      export LAT_LLM_BASE_URL="https://api.synthetic.new/openai/v1"
      export LAT_LLM_MODEL="hf:nomic-ai/nomic-embed-text-v1.5"
      export LAT_LLM_DIMENSIONS="768"
    fi

    # if [ -n "$BRAVE_SEARCH_API_KEY" ] && [ -z "$BRAVE_API_KEY" ]; then
    #   export BRAVE_API_KEY="$BRAVE_SEARCH_API_KEY"
    # fi

    # Patch pi-bash-live-view until upstream handles wide glyphs/ANSI truncation.
    # Without this, PTY live view can render one cell past terminal width and crash Pi.
    bash_live_view_widget="$HOME/.pi/agent/npm/node_modules/pi-bash-live-view/widget.ts"
    if [ -f "$bash_live_view_widget" ]; then
      cp ${./patches/pi-bash-live-view/widget.ts} "$bash_live_view_widget"
    fi

    export PATH="$HOME/.pi/agent/bin:${sesame}/bin:${plannotator}/bin:${pkgs."poppler-utils"}/bin:${pkgs.rtk}/bin:$PATH"
    exec ${piPackage}/bin/pi "$@"
  '';

  # Auto-discover extensions (.ts files and directories with index.ts)
  extensionEntries = builtins.readDir ./extensions;
  extensionSymlinks = builtins.listToAttrs (
    builtins.concatLists [
      # Single .ts files
      (map
        (name: {
          name = ".pi/agent/extensions/${name}";
          value = {
            source = ./extensions/${name};
          };
        })
        (
          builtins.filter (name: lib.hasSuffix ".ts" name && isEnabledEntry name) (
            builtins.attrNames extensionEntries
          )
        )
      )
      # Directories (extension subdirectories like subagent/)
      (map
        (name: {
          name = ".pi/agent/extensions/${name}";
          value = {
            source = ./extensions/${name};
          };
        })
        (
          builtins.filter (name: extensionEntries.${name} == "directory" && isEnabledEntry name) (
            builtins.attrNames extensionEntries
          )
        )
      )
    ]
  );

  # Agent definitions now come from pi-subagents package (scout, researcher, planner, worker, reviewer, oracle, context-builder, delegate)
  # Custom agents can be added to ./agents/ directory — auto-discovered and symlinked to ~/.pi/agent/agents/
  agentFiles = builtins.filter (name: lib.hasSuffix ".md" name && isEnabledEntry name) (
    builtins.attrNames (builtins.readDir ./agents)
  );
  agentSymlinks = builtins.listToAttrs (
    map (name: {
      name = ".pi/agent/agents/${name}";
      value = {
        source = ./agents/${name};
      };
    }) agentFiles
  );

  # Auto-discover simple skills (no deps) - symlink entire directories
  skillEntries = builtins.readDir ./skills;
  skillDirs = builtins.filter (name: skillEntries.${name} == "directory" && isEnabledEntry name) (
    builtins.attrNames skillEntries
  );
  skillSymlinks = builtins.listToAttrs (
    map (name: {
      name = ".pi/agent/skills/${name}";
      value = {
        source = ./skills/${name};
      };
    }) skillDirs
  );

  promptFiles = builtins.filter (name: lib.hasSuffix ".md" name && isEnabledEntry name) (
    builtins.attrNames (builtins.readDir ./prompts)
  );
  promptSymlinks = builtins.listToAttrs (
    map (name: {
      name = ".pi/agent/prompts/${name}";
      value = {
        source = ./prompts/${name};
      };
    }) promptFiles
  );

  piAcp = pkgs.callPackage ./packages/pi-acp.nix { };
  piAcpWrapper = pkgs.writeShellScriptBin "pi-acp" ''
    export PI_ACP_PI_COMMAND="''${PI_ACP_PI_COMMAND:-${piWrapper}/bin/pi}"
    export PI_ACP_ENABLE_EMBEDDED_CONTEXT="''${PI_ACP_ENABLE_EMBEDDED_CONTEXT:-true}"
    export PI_PROFILE="''${PI_PROFILE:-alt}"
    export PI_PROFILE_SOURCE="''${PI_PROFILE_SOURCE:-profile-flag}"
    export PI_ACP_MODEL_PREFIXES="''${PI_ACP_MODEL_PREFIXES:-alt-anthropic,alt-codex}"
    exec ${piAcp}/bin/pi-acp "$@"
  '';

  pinvim = pkgs.writeShellScriptBin "pinvim" ''
    # Clear conflicting env from previous pinvim sessions
    unset PI_CODING_AGENT_DIR 2>/dev/null || true

    # Parse --profile flag and collect pi args
    EXPLICIT_PROFILE=""
    PI_ARGS=()
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --profile)
          if [[ -z "''${2:-}" || "$2" == --* ]]; then
            echo "Warning: --profile requires a profile name" >&2
            shift
          else
            EXPLICIT_PROFILE="$2"
            shift 2
          fi
          ;;
        *)
          PI_ARGS+=("$1")
          shift
          ;;
      esac
    done

    # Runtime state — pinvim.ts derives sockets/, manifests/, and pinvim/ from this.
    export PI_STATE_DIR="${piStateDir}"
    mkdir -p "$PI_STATE_DIR/sockets" "$PI_STATE_DIR/manifests" "$PI_STATE_DIR/pinvim"

    # Detect session name (pinvim.ts handles socket)
    if [ -n "$TMUX" ]; then
      PI_SESSION=$(${pkgs.tmux}/bin/tmux display-message -p '#{session_name}')
    else
      PI_SESSION="default"
    fi
    export PI_SESSION

    # If pinvim is started from an existing Pi pane, inherited main-session
    # pinvim env must not rebind or unlink the original Nvim-owned socket.
    CURRENT_CMD=""
    START_CMD=""
    PANE_TITLE=""
    if [ -n "$TMUX" ]; then
      CURRENT_CMD=$(${pkgs.tmux}/bin/tmux display-message -p '#{pane_current_command}' 2>/dev/null || true)
      START_CMD=$(${pkgs.tmux}/bin/tmux display-message -p '#{pane_start_command}' 2>/dev/null || true)
      PANE_TITLE=$(${pkgs.tmux}/bin/tmux display-message -p '#{pane_title}' 2>/dev/null || true)
    fi
    if [ "''${PIMUX_FROM_NVIM:-}" != "1" ] && \
       [ "''${PINVIM_SESSION_ROLE:-}" != "child" ] && \
       [ -n "''${PINVIM_PARENT_ID:-}''${PINVIM_WORKSPACE_ID:-}''${PINVIM_INSTANCE_ID:-}''${PI_SOCKET:-}" ] && \
       { [ "$CURRENT_CMD" = "pi" ] || [ "$CURRENT_CMD" = "pinvim" ] || [[ "$START_CMD" == *"pinvim"* ]] || [[ "$START_CMD" == *" pi"* ]] || [[ "$PANE_TITLE" == π* ]] || [[ "$PANE_TITLE" == pi* ]]; }; then
      export PINVIM_NESTED_ATTACH_ONLY=1
      export PINVIM_SESSION_ROLE="nested"
      export PINVIM_LINK_MODE="attach-only"
      unset PI_SOCKET 2>/dev/null || true
    fi

    # Profile detection: --profile > explicit envs > tmux > directoryProfiles > mega
    SETTINGS_PATH="$HOME/.pi/agent/settings.json"
    RESOLVER="${./scripts/resolve-pinvim-profile.mjs}"
    RESOLVER_ARGS=(--settings "$SETTINGS_PATH" --cwd "$(pwd)" --session "$PI_SESSION")
    if [ -n "$EXPLICIT_PROFILE" ]; then
      RESOLVER_ARGS+=(--explicit-profile "$EXPLICIT_PROFILE")
    fi
    eval "$(${pkgs.nodejs}/bin/node "$RESOLVER" "''${RESOLVER_ARGS[@]}")"

    # Delegate to pi wrapper (which handles opnix, PATH, NODE_PATH)
    exec pi "''${PI_ARGS[@]}"
  '';

  p = pkgs.writeShellScriptBin "p" ''exec ${pinvim}/bin/pinvim "$@"'';

  piviewScopes = [
    "uncommitted"
    "unpushed"
    "branch"
    "pr"
    "ticket"
    "worktrees"
  ];

  piviewFishCompletions = lib.concatMapStringsSep "\n" (
    scope:
    "complete -c pview -f -a ${lib.escapeShellArg scope} -d ${lib.escapeShellArg "/piview ${scope}"}"
  ) piviewScopes;

  pview = pkgs.writeShellScriptBin "pview" ''
    set -euo pipefail

    if [[ -z "''${TMUX:-}" ]]; then
      exec ${p}/bin/p
    fi

    prompt="/piview"
    if [[ $# -gt 0 ]]; then
      prompt="/piview $*"
    fi

    pane_count="$(${pkgs.tmux}/bin/tmux display-message -p '#{window_panes}' 2>/dev/null || printf '1')"
    if [[ "$pane_count" =~ ^[0-9]+$ ]] && (( pane_count > 1 )); then
      printf -v quoted_prompt '%q' "$prompt"
      exec ${pkgs.tmux}/bin/tmux new-window -c "$PWD" -n "piview" "exec ${pinvim}/bin/pinvim $quoted_prompt"
    fi

    exec ${pinvim}/bin/pinvim "$prompt"
  '';
in
{
  home = {
    packages = [
      (pkgs.writeShellScriptBin "work-tickets" (builtins.readFile ./scripts/work-tickets.sh))
      pkgs."poppler-utils"
      plannotator
      sesame
      piAcpWrapper
      pinvim
      p
      pview
    ];
    sessionVariables = {
      PI_STATE_DIR = piStateDir;
      PI_ACP_PI_COMMAND = "${piWrapper}/bin/pi";
      PI_ACP_ENABLE_EMBEDDED_CONTEXT = "true";
    };

    file = {
      ".pi/agent/AGENTS.md".source = ./sources/GLOBAL_AGENTS.md;
      ".pi/agent/APPEND_SYSTEM.md".source = ./sources/APPEND_SYSTEM.md;
      ".pi/agent/keybindings.json".source = ./keybindings.json;
      ".pi/agent/models.json".source = ./models.json;
      ".pi/agent/mcp.json".source = ./mcp.json;
    }
    // piExtensionPackageSymlinks
    // extensionSymlinks
    // agentSymlinks
    // skillSymlinks
    // promptSymlinks;

    # Activation script to merge settings into settings.json
    # This preserves all other settings managed by pi itself
    activation = {
      mergeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.bash}/bin/bash ${./scripts/merge-settings.sh} ${./settings.json}
      '';

      linkPiAcpBinary = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        bin_dir="$HOME/.local/bin"
        mkdir -p "$bin_dir"
        run ln -sf ${piAcpWrapper}/bin/pi-acp "$bin_dir/pi-acp"
      '';

      # Clean up redundant extension deps (pi's jiti resolves these internally)
      cleanExtensionDeps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ext_dir="$HOME/.pi/agent/extensions"
        for f in "$ext_dir/package.json" "$ext_dir/package-lock.json"; do
          [ -f "$f" ] && run rm "$f"
        done
        [ -d "$ext_dir/node_modules" ] && run rm -rf "$ext_dir/node_modules"
      '';
    };
  };

  xdg.configFile."sesame/config.jsonc" = {
    force = true;
    text = ''
      {
        "piSessionPaths": ["${config.home.homeDirectory}/.pi/agent/sessions"]
      }
    '';
  };

  launchd.agents.sesame-session-indexer = {
    enable = true;
    config = {
      ProgramArguments = [
        "${sesame}/bin/sesame"
        "watch"
        "--interval"
        "30"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${config.home.homeDirectory}/.cache/sesame-session-indexer.log";
      StandardErrorPath = "${config.home.homeDirectory}/.cache/sesame-session-indexer.log";
      ProcessType = "Background";
      LowPriorityIO = true;
    };
  };

  launchd.agents.pi-session-indexer = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.bash}/bin/bash"
        "${./scripts/build-session-index.sh}"
      ];
      StartInterval = 7200;
      RunAtLoad = true;
      StandardOutPath = "${config.home.homeDirectory}/.cache/pi-session-indexer.log";
      StandardErrorPath = "${config.home.homeDirectory}/.cache/pi-session-indexer.log";
      ProcessType = "Background";
      LowPriorityIO = true;
    };
  };

  programs = {
    fish = {
      shellAliases = {
        pic = "pi -c"; # Continue last session
        pir = "pi -r"; # Resume mode
        pisock = "pinvim"; # pi with socket connection
        pis = "pinvim"; # Short alias
      };
      shellInit = ''
        ${piviewFishCompletions}
      '';
    };
    pi = {
      coding-agent = {
        enable = true;
        package = piWrapper;
      };
    };
  };
}
