{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (pkgs) pi-coding-agent;

  piStateDir = "${config.xdg.stateHome}/pi";

  pi-mcp-adapter = pkgs.callPackage ./packages/pi-mcp-adapter.nix { };
  pi-web-access = pkgs.callPackage ./packages/pi-web-access.nix { };
  pi-subagents = pkgs.callPackage ./packages/pi-subagents.nix { };
  # pi-ralph-loop = pkgs.callPackage ./packages/pi-ralph-loop.nix {};

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

  pinvim = pkgs.writeShellScriptBin "pinvim" ''
    # Clear conflicting env from previous pinvim sessions
    unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN PI_CODING_AGENT_DIR 2>/dev/null || true

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

    # Runtime state — pinvim.ts derives sockets/ and manifests/ from this.
    export PI_STATE_DIR="${piStateDir}"
    mkdir -p "$PI_STATE_DIR/sockets" "$PI_STATE_DIR/manifests"

    # Detect session name (pinvim.ts handles socket)
    if [ -n "$TMUX" ]; then
      PI_SESSION=$(${pkgs.tmux}/bin/tmux display-message -p '#{session_name}')
    else
      PI_SESSION="default"
    fi
    export PI_SESSION

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

      (pkgs.writeShellScriptBin "pi" ''
        export PATH="${pkgs.nodejs_24}/bin:${pkgs."poppler-utils"}/bin:${pkgs.rtk}/bin:$PATH"
        export NODE_PATH="${piNodeAliases}/node_modules''${NODE_PATH:+:$NODE_PATH}"

        XDG_CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}"
        if [ -f "$XDG_CONFIG_HOME/opnix/secrets/env-vars.sh" ]; then
          . "$XDG_CONFIG_HOME/opnix/secrets/env-vars.sh"
        fi

        if [ -n "$BRAVE_SEARCH_API_KEY" ] && [ -z "$BRAVE_API_KEY" ]; then
          export BRAVE_API_KEY="$BRAVE_SEARCH_API_KEY"
        fi

        exec ${pi-coding-agent}/bin/pi "$@"
      '')

      pkgs."poppler-utils"

      pinvim
      p
    ];
    sessionVariables = {
      PI_STATE_DIR = piStateDir;

      # web-browser skill uses chrome-devtools MCP server (configured in mcp.json).
      # No env vars needed — executable path and profile dirs are in mcp.json.
    };

    file = {
      ".pi/agent/AGENTS.md".source = ./sources/GLOBAL_AGENTS.md;
      ".pi/agent/APPEND_SYSTEM.md".source = ./sources/APPEND_SYSTEM.md;

      # Pi MCP adapter extension - built with deps
      ".pi/agent/extensions/pi-mcp-adapter".source = pi-mcp-adapter;

      # Pi web access extension - built with deps
      ".pi/agent/extensions/pi-web-access".source = pi-web-access;

      # pi-subagents extension - multi-agent orchestration
      ".pi/agent/extensions/pi-subagents".source = pi-subagents;

      # pi-ralph-loop extension - autonomous coding loops
      # ".pi/agent/extensions/pi-ralph-loop".source = pi-ralph-loop;

      # pi-ralph-loop skills
      # ".pi/agent/skills/ralph-loop".source = "${pi-ralph-loop}/skills/ralph-loop";
      # ".pi/agent/skills/ralph-draft".source = "${pi-ralph-loop}/skills/ralph-draft";
      # ".pi/agent/skills/ralph-finalize".source = "${pi-ralph-loop}/skills/ralph-finalize";

      # Plain JSON configs — keybindings uses out-of-store symlink so pi can write to it
      ".pi/agent/keybindings.json".source = ./keybindings.json;
      # config.lib.mega.linkDotfile "home/common/programs/pi-coding-agent/keybindings.json";
      ".pi/agent/models.json".source = ./models.json;
      ".pi/agent/mcp.json".source = ./mcp.json;
      ".pi/agent/extensions/sentinel-rules.json".source = ./extensions/sentinel-rules.json;
    }
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
