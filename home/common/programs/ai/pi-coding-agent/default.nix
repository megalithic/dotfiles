# Pi Coding Agent Configuration
# Manages pi settings, extensions, skills, and socket naming via Nix
#
# Structure:
#   - default.nix (this file): Main config with packages/ builds + auto-discovery
#   - packages/: npm packages built via buildNpmPackage (pi binary, extensions with deps)
#   - extensions/: TypeScript extensions (auto-discovered)
#   - skills/: Simple skills (auto-discovered, symlinked)
#   - agents/: Agent definitions (auto-discovered .md files)
#   - prompts/: Prompt templates (auto-discovered .md files)
#   - patches/: Patches applied to built packages
#   - sources/: Source files like GLOBAL_AGENTS.md
#   - settings.json: Plain JSON settings (merged into ~/.pi/agent/settings.json)
#   - keybindings.json: Plain JSON keybindings (symlinked directly)
#   - models.json: Custom model/provider definitions (symlinked directly)
#   - mcp.json: MCP server configuration (symlinked directly)
#   - merge-settings.sh: Idempotent settings merge script
#
# Socket Configuration (single source of truth):
#   - PI_SOCKET_DIR: Directory for sockets (/tmp)
#   - PI_SOCKET_PREFIX: Socket name prefix (pi)
#   - PI_SESSION: Current tmux session name
#   - PI_WINDOW: Current tmux window index
#   - PI_SOCKET: Full socket path (/tmp/pi-{session}-{window}.sock)
#
# Socket pattern: /tmp/pi-{session}-{window}.sock
#   - One socket per tmux window (allows multiple pi instances)
#   - Enables multi-instance workflows (e.g., mega:0 and mega:agent)
#   - Non-tmux fallback: /tmp/pi-default-0.sock
#
# Based on: https://github.com/otahontas/nix/tree/main/home/configs/pi-coding-agent
{
  config,
  pkgs,
  lib,
  ...
}: let
  # ===========================================================================
  # Socket Configuration (single source of truth)
  # ===========================================================================
  socketConfig = {
    dir = "/tmp";
    prefix = "pi";
  };

  # ===========================================================================
  # Packages (npm packages built via buildNpmPackage)
  # ===========================================================================
  # Each package has a package.json + package-lock.json in packages/<name>/
  # To add: mkdir packages/<name>, npm init + npm install <dep>, add buildNpmPackage here
  # To update: bump version in package.json, run npm install --package-lock-only, update npmDepsHash

  # Pi binary — built from npm, enables patching (retry behavior, etc.)
  pi-coding-agent = pkgs.buildNpmPackage {
    pname = "pi-coding-agent";
    version = "0.62.0";
    src = ./packages/pi;
    npmDepsHash = "sha256-bdwceF6m2X+hfEMRQajMqjXUxJU0a338KdHvpP4nokQ=";
    dontNpmBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib
      cp -r node_modules $out/lib/node_modules
      mkdir -p $out/bin
      ln -s $out/lib/node_modules/@mariozechner/pi-coding-agent/dist/cli.js $out/bin/pi

      # Patch: unlimited 429 retries + capped backoff
      TARGET=$out/lib/node_modules/@mariozechner/pi-coding-agent/dist/core/agent-session.js

      # 1. Skip maxRetries cap for 429/rate-limit errors
      substituteInPlace "$TARGET" \
        --replace-fail 'if (this._retryAttempt > settings.maxRetries) {' \
        'const _is429 = /429|rate.?limit|too many requests/i.test(message.errorMessage || ""); if (!_is429 && this._retryAttempt > settings.maxRetries) {'

      # 2. Cap delay at maxDelayMs (set to 900000/15min in settings.json)
      substituteInPlace "$TARGET" \
        --replace-fail 'const delayMs = settings.baseDelayMs * 2 ** (this._retryAttempt - 1);' \
        'const delayMs = Math.min(settings.baseDelayMs * 2 ** (this._retryAttempt - 1), settings.maxDelayMs);'

      runHook postInstall
    '';
  };

  # MCP adapter extension (has npm dependencies)
  pi-mcp-adapter = pkgs.buildNpmPackage {
    pname = "pi-mcp-adapter";
    version = "2.3.5";
    src = ./packages/pi-mcp-adapter;
    npmDepsHash = "sha256-/lkw32MJicaEmu4fFppQOiXTorpZUtCnA+t+L656rIs=";
    dontNpmBuild = true;
    # TODO: patch needs path adjustment for npm package layout (was written for git repo)
    # patches = [./patches/claude-settings-support.patch];
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r . $out/
      runHook postInstall
    '';
  };

  # Web search/extraction extension (has npm dependencies)
  pi-web-access = pkgs.buildNpmPackage {
    pname = "pi-web-access";
    version = "0.10.6";
    src = ./packages/pi-web-access;
    npmDepsHash = "sha256-by5B1kvgCJ2w+plBRgQHTDWuMyh7IWsivtUNqhwvdlI=";
    dontNpmBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r . $out/
      runHook postInstall
    '';
  };

  # Terminal diff renderer (has npm dependencies — @shikijs/cli)
  # NOTE: Known broken upstream — if build fails, disable in disabledExtensions
  pi-diff = pkgs.buildNpmPackage {
    pname = "pi-diff";
    version = "0.2.1";
    src = ./packages/pi-diff;
    npmDepsHash = "sha256-78lR0MMdNFbLoWydfEIjBsSu20nLLc7rodwjrxRWO80=";
    dontNpmBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r . $out/
      runHook postInstall
    '';
  };

  # Syntax highlighting for reads (has npm dependencies)
  # NOTE: Known broken upstream — if build fails, disable in disabledExtensions
  pi-pretty = pkgs.buildNpmPackage {
    pname = "pi-pretty";
    version = "0.3.2";
    src = ./packages/pi-pretty;
    npmDepsHash = "sha256-KQfiB06n2qv77GvG1ILHKgY7L1rLrTk4x8UZMg14uzM=";
    dontNpmBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r . $out/
      runHook postInstall
    '';
  };

  # Subscription rotation
  pi-multi-pass = pkgs.buildNpmPackage {
    pname = "pi-multi-pass";
    version = "1.3.0";
    src = ./packages/pi-multi-pass;
    npmDepsHash = "sha256-iF8uoumQk3faBj9RAgxoGmmqU/OvM7ATV/hrWvYogHs=";
    dontNpmBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r . $out/
      runHook postInstall
    '';
  };

  # Knowledge graph CLI (used by lat-md skill)
  lat-md = pkgs.buildNpmPackage {
    pname = "lat-md";
    version = "0.11.0";
    src = ./packages/lat-md;
    npmDepsHash = "sha256-gTTGSh/JHPD0Q8tPqpWIl+2GWtcoDDmpEh/wDIJcttg=";
    dontNpmBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib
      cp -r node_modules $out/lib/node_modules
      mkdir -p $out/bin
      ln -s $out/lib/node_modules/lat.md/dist/src/cli/index.js $out/bin/lat
      runHook postInstall
    '';
  };

  # ===========================================================================
  # Auto-discovery Configuration
  # ===========================================================================

  # Extensions to exclude from auto-loading
  disabledExtensions = [
    "checkpoint.ts" # Too intrusive
    "subscription-fallback.ts" # Doesn't support everything we need
  ];

  # Skills to exclude from auto-discovery
  disabledSkills = [
    # Add skill names here to disable them
  ];

  # ===========================================================================
  # Auto-discover extensions (.ts files and directories in extensions/)
  # ===========================================================================
  extensionDir = ./extensions;
  extensionDirExists = builtins.pathExists extensionDir;
  extensionEntries =
    if extensionDirExists
    then builtins.readDir extensionDir
    else {};

  # .ts files
  extensionTsFiles =
    builtins.filter (name: lib.hasSuffix ".ts" name && !builtins.elem name disabledExtensions) (
      builtins.attrNames extensionEntries
    );

  # Directories (e.g., subagent/)
  extensionDirs =
    builtins.filter (name: extensionEntries.${name} == "directory") (
      builtins.attrNames extensionEntries
    );

  # Data files co-located with extensions (JSON configs, etc.)
  extensionDataFiles =
    builtins.filter (name: lib.hasSuffix ".json" name && name != "package.json") (
      builtins.attrNames extensionEntries
    );

  extensionSymlinks = builtins.listToAttrs (
    map (name: {
      name = ".pi/agent/extensions/${name}";
      value.source = ./extensions/${name};
    })
    (extensionTsFiles ++ extensionDataFiles ++ extensionDirs)
  );

  # ===========================================================================
  # Auto-discover agents (.md files in agents/)
  # ===========================================================================
  agentsDir = ./agents;
  agentsDirExists = builtins.pathExists agentsDir;

  agentFiles =
    if agentsDirExists
    then
      builtins.filter (name: lib.hasSuffix ".md" name) (
        builtins.attrNames (builtins.readDir agentsDir)
      )
    else [];

  agentSymlinks = builtins.listToAttrs (
    map (name: {
      name = ".pi/agent/agents/${name}";
      value.source = ./agents/${name};
    })
    agentFiles
  );

  # ===========================================================================
  # Auto-discover skills (directories in skills/)
  # ===========================================================================
  skillsDir = ./skills;
  skillsDirExists = builtins.pathExists skillsDir;

  skillDirs =
    if skillsDirExists
    then
      builtins.filter (name: !builtins.elem name disabledSkills) (
        builtins.attrNames (builtins.readDir skillsDir)
      )
    else [];

  skillSymlinks = builtins.listToAttrs (
    map (name: {
      name = ".pi/agent/skills/${name}";
      value.source = ./skills/${name};
    })
    skillDirs
  );

  # ===========================================================================
  # Auto-discover prompts (.md files in prompts/)
  # ===========================================================================
  promptsDir = ./prompts;
  promptsDirExists = builtins.pathExists promptsDir;

  promptFiles =
    if promptsDirExists
    then
      builtins.filter (name: lib.hasSuffix ".md" name) (
        builtins.attrNames (builtins.readDir promptsDir)
      )
    else [];

  promptSymlinks = builtins.listToAttrs (
    map (name: {
      name = ".pi/agent/prompts/${name}";
      value.source = ./prompts/${name};
    })
    promptFiles
  );

  # ===========================================================================
  # Pi Wrapper Script
  # ===========================================================================
  # NOTE: pinvim kept as-is for now. Future: tmux-nvim-pi script (Phase 8).
  # Profile borrowing still works if profile dirs exist, degrades gracefully if not.

  profiles = ["rx" "cspire"];
  sharedConfigItems = [
    "AGENTS.md"
    "settings.json"
    "keybindings.json"
    "extensions"
    "skills"
    "prompts"
  ];

  pinvim = pkgs.writeShellScriptBin "pinvim" ''
    # Source agenix secrets for API keys (BRAVE_SEARCH_API_KEY, etc.)
    AGENIX_DIR="$(${pkgs.darwin.system_cmds}/bin/getconf DARWIN_USER_TEMP_DIR)/agenix"
    if [ -f "$AGENIX_DIR/env-vars" ]; then
      . "$AGENIX_DIR/env-vars"
    fi

    # Clear conflicting AWS credentials
    unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN 2>/dev/null || true

    # Parse --profile flag
    PROFILE=""
    PI_ARGS=()
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --profile)
          if [[ -z "''${2:-}" || "$2" == --* ]]; then
            echo "Warning: --profile requires a profile name, using default" >&2
            shift
          else
            PROFILE="$2"
            shift 2
          fi
          ;;
        *)
          PI_ARGS+=("$1")
          shift
          ;;
      esac
    done

    # Socket configuration
    export PI_SOCKET_DIR="${socketConfig.dir}"
    export PI_SOCKET_PREFIX="${socketConfig.prefix}"

    if [ -n "$TMUX" ]; then
      PI_SESSION=$(${pkgs.tmux}/bin/tmux display-message -p '#{session_name}')
      WIN_NAME=$(${pkgs.tmux}/bin/tmux display-message -p '#{window_name}' | tr -d ' ')
      WIN_INDEX=$(${pkgs.tmux}/bin/tmux display-message -p '#{window_index}')
      if [[ -n "$WIN_NAME" && "$WIN_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        PI_WINDOW="$WIN_NAME"
      else
        PI_WINDOW="$WIN_INDEX"
      fi
      export PI_SESSION PI_WINDOW
      export PI_SOCKET="${socketConfig.dir}/${socketConfig.prefix}-''${PI_SESSION}-''${PI_WINDOW}.sock"
    else
      export PI_SESSION="default"
      export PI_WINDOW="0"
      export PI_SOCKET="${socketConfig.dir}/${socketConfig.prefix}-default-0.sock"
    fi

    # Add tools to PATH
    export PATH="${pkgs.ast-grep}/bin:${lat-md}/bin:$PATH"

    # Handle profile auth borrowing
    if [[ -n "$PROFILE" ]]; then
      MASTER_DIR="$HOME/.pi/agent"
      PROFILE_DIR="$HOME/.pi/agent-''${PROFILE}"
      PROFILE_AUTH="$PROFILE_DIR/auth.json"

      if [[ ! -f "$PROFILE_AUTH" ]]; then
        echo "Warning: Profile auth not found: $PROFILE_AUTH" >&2
        echo "Available profiles:" >&2
        for d in "$HOME"/.pi/agent-*/; do
          [[ -f "$d/auth.json" ]] && echo "  --profile $(basename "$d" | sed 's/^agent-//')" >&2
        done
        echo "" >&2
        echo "Using default auth instead." >&2
      else
        HYBRID_DIR="/tmp/pi-config-''${PI_SESSION}-''${PROFILE}"
        mkdir -p "$HYBRID_DIR"

        for item in ${lib.concatStringsSep " " sharedConfigItems}; do
          [[ -e "$MASTER_DIR/$item" || -L "$MASTER_DIR/$item" ]] && \
            ln -sfn "$MASTER_DIR/$item" "$HYBRID_DIR/$item"
        done

        mkdir -p "$MASTER_DIR/sessions"
        ln -sfn "$MASTER_DIR/sessions" "$HYBRID_DIR/sessions"
        ln -sfn "$PROFILE_AUTH" "$HYBRID_DIR/auth.json"

        export PI_CODING_AGENT_DIR="$HYBRID_DIR"

        cleanup() { rm -rf "$HYBRID_DIR" 2>/dev/null; }
        trap cleanup EXIT INT TERM
        ${pi-coding-agent}/bin/pi "''${PI_ARGS[@]}"
        exit $?
      fi
    fi

    exec ${pi-coding-agent}/bin/pi "''${PI_ARGS[@]}"
  '';

  p = pkgs.writeShellScriptBin "p" ''exec ${pinvim}/bin/pinvim "$@"'';
in {
  home.packages = [
    pinvim
    p
    pkgs.llm-agents.agent-browser # Browser automation CLI
    lat-md
  ];

  # ===========================================================================
  # File Symlinks
  # ===========================================================================
  home.file =
    {
      # Global AGENTS.md
      ".pi/agent/AGENTS.md".source = ./sources/GLOBAL_AGENTS.md;

      # Plain JSON configs (keybindings, models, mcp symlinked directly)
      # force = true: keybindings.json was previously a regular file from activation script
      ".pi/agent/keybindings.json" = { source = ./keybindings.json; force = true; };
      ".pi/agent/models.json".source = ./models.json;
      ".pi/agent/mcp.json".source = ./mcp.json;

      # Built extensions with npm dependencies
      ".pi/agent/extensions/pi-mcp-adapter".source = pi-mcp-adapter;
      ".pi/agent/extensions/pi-web-access".source = pi-web-access;
      # ".pi/agent/extensions/pi-diff".source = "${pi-diff}/node_modules/@heyhuynhgiabuu/pi-diff/src/index.ts";
      # ".pi/agent/extensions/pi-pretty".source = "${pi-pretty}/node_modules/@heyhuynhgiabuu/pi-pretty/src/index.ts";
      ".pi/agent/extensions/pi-multi-pass".source = pi-multi-pass;
    }
    // extensionSymlinks
    // agentSymlinks
    // skillSymlinks
    // promptSymlinks;

  # ===========================================================================
  # Settings Merge Activation
  # ===========================================================================
  home.activation.mergeSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${pkgs.bash}/bin/bash ${./merge-settings.sh} ${./settings.json}
  '';

  # ===========================================================================
  # Clean Extension Deps Activation
  # ===========================================================================
  # Remove stale node_modules/package.json from extensions dir (pi's jiti resolves internally)
  home.activation.cleanExtensionDeps = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ext_dir="$HOME/.pi/agent/extensions"
    for f in "$ext_dir/package.json" "$ext_dir/package-lock.json"; do
      [ -f "$f" ] && run rm "$f"
    done
    [ -d "$ext_dir/node_modules" ] && run rm -rf "$ext_dir/node_modules"
  '';

  # ===========================================================================
  # Session Indexer (for search-sessions extension)
  # ===========================================================================
  launchd.agents.pi-session-indexer = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.bash}/bin/bash"
        "${./scripts/build-session-index.sh}"
      ];
      StartInterval = 7200; # Every 2 hours
      RunAtLoad = true;
      StandardOutPath = "${config.home.homeDirectory}/.cache/pi-session-indexer.log";
      StandardErrorPath = "${config.home.homeDirectory}/.cache/pi-session-indexer.log";
      ProcessType = "Background";
      LowPriorityIO = true;
    };
  };

  # ===========================================================================
  # Fish Shell Aliases
  # ===========================================================================
  programs.fish.shellAliases = {
    pic = "pi -c"; # Continue last session
    pir = "pi -r"; # Resume mode
    pisock = "pinvim"; # pi with socket connection
    pis = "pinvim"; # Short alias
  };
}
