{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (pkgs) pi-coding-agent;

  piStateDir = "${config.xdg.stateHome}/pi";

  piPackageFiles = builtins.filter (name: lib.hasSuffix ".nix" name && !(lib.hasPrefix "_" name)) (
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

  piNodeAliases = pkgs.runCommand "pi-node-aliases" { } ''
    mkdir -p $out/node_modules/@earendil-works

    piRoot=$(find ${pi-coding-agent}/lib/node_modules -mindepth 1 -maxdepth 1 -type d | head -n1)
    piNodeModules="$piRoot/node_modules"

    makeAlias() {
      target="$1"
      package="$2"
      aliasDir="$out/node_modules/@earendil-works/$package"

      mkdir -p "$aliasDir"
      ln -s "$target/dist" "$aliasDir/dist"
      printf '{"name":"@earendil-works/%s","type":"module","main":"./dist/index.js","types":"./dist/index.d.ts"}\n' "$package" > "$aliasDir/package.json"
    }

    makeAlias "$piRoot" pi-coding-agent

    for package in pi-ai pi-agent-core pi-tui; do
      if [ -e "$piNodeModules/@earendil-works/$package" ]; then
        makeAlias "$piNodeModules/@earendil-works/$package" "$package"
      elif [ -e "$piNodeModules/@mariozechner/$package" ]; then
        makeAlias "$piNodeModules/@mariozechner/$package" "$package"
      fi
    done
  '';

  # Auto-discover extensions (.ts files and directories with index.ts)
  extensionEntries = builtins.readDir ./extensions;
  extensionSymlinks = builtins.listToAttrs (
    builtins.concatLists [
      # Single .ts files
      (map (name: {
        name = ".pi/agent/extensions/${name}";
        value = {
          source = ./extensions/${name};
        };
      }) (builtins.filter (name: lib.hasSuffix ".ts" name) (builtins.attrNames extensionEntries)))
      # Directories (extension subdirectories like subagent/)
      (map
        (name: {
          name = ".pi/agent/extensions/${name}";
          value = {
            source = ./extensions/${name};
          };
        })
        (
          builtins.filter (name: extensionEntries.${name} == "directory") (
            builtins.attrNames extensionEntries
          )
        )
      )
    ]
  );

  # Agent definitions now come from pi-subagents package (scout, researcher, planner, worker, reviewer, oracle, context-builder, delegate)
  # Custom agents can be added to ./agents/ directory — auto-discovered and symlinked to ~/.pi/agent/agents/
  agentFiles = builtins.filter (name: lib.hasSuffix ".md" name) (
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
  skillDirs = builtins.attrNames (builtins.readDir ./skills);
  skillSymlinks = builtins.listToAttrs (
    map (name: {
      name = ".pi/agent/skills/${name}";
      value = {
        source = ./skills/${name};
      };
    }) skillDirs
  );

  # Auto-discover prompt templates (.md files in prompts/)
  promptFiles = builtins.filter (name: lib.hasSuffix ".md" name) (
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

  piWrapper = pkgs.writeShellScriptBin "pi" ''
    export PATH="${pkgs.nodejs_24}/bin:${pkgs."poppler-utils"}/bin:${pkgs.rtk}/bin:$PATH"
    export NODE_PATH="${piNodeAliases}/node_modules''${NODE_PATH:+:$NODE_PATH}"
    export PI_STATE_DIR="''${PI_STATE_DIR:-${piStateDir}}"
    mkdir -p "$PI_STATE_DIR/sockets" "$PI_STATE_DIR/manifests" "$PI_STATE_DIR/pinvim"
    unset PIMUX_FROM_NVIM 2>/dev/null || true

    XDG_CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}"
    if [ -f "$XDG_CONFIG_HOME/opnix/secrets/env-vars.sh" ]; then
      . "$XDG_CONFIG_HOME/opnix/secrets/env-vars.sh"
    fi

    if [ -n "$BRAVE_SEARCH_API_KEY" ] && [ -z "$BRAVE_API_KEY" ]; then
      export BRAVE_API_KEY="$BRAVE_SEARCH_API_KEY"
    fi

    exec ${pi-coding-agent}/bin/pi "$@"
  '';

  piAcp = pkgs.callPackage ./packages/pi-acp.nix { };
  piAcpWrapper = pkgs.writeShellScriptBin "pi-acp" ''
    export PI_ACP_PI_COMMAND="''${PI_ACP_PI_COMMAND:-${piWrapper}/bin/pi}"
    export PI_ACP_ENABLE_EMBEDDED_CONTEXT="''${PI_ACP_ENABLE_EMBEDDED_CONTEXT:-true}"
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
in
{
  home = {
    packages = [
      (pkgs.writeShellScriptBin "work-tickets" (builtins.readFile ./scripts/work-tickets.sh))

      piWrapper

      pkgs."poppler-utils"

      piAcpWrapper
      pinvim
      p
    ];
    sessionVariables = {
      PI_STATE_DIR = piStateDir;
      PI_ACP_PI_COMMAND = "${piWrapper}/bin/pi";
      PI_ACP_ENABLE_EMBEDDED_CONTEXT = "true";
    };

    file = {
      ".pi/agent/AGENTS.md".source = ./sources/GLOBAL_AGENTS.md;
      ".pi/agent/APPEND_SYSTEM.md".source = ./sources/APPEND_SYSTEM.md;
      ".pi/agent/extensions/sentinel-rules.json".source = ./extensions/sentinel-rules.json;
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

  programs.fish.shellAliases = {
    pic = "pi -c"; # Continue last session
    pir = "pi -r"; # Resume mode
    pisock = "pinvim"; # pi with socket connection
    pis = "pinvim"; # Short alias
  };
}
