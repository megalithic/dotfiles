# Pi Coding Agent Configuration
# Manages pi settings, extensions, skills, and socket naming via Nix.
#
# AGENT CONTEXT — read before editing this file:
#
#   Adding a simple extension (no npm deps):
#     Just drop a .ts file in extensions/ — auto-discovered, no changes here.
#     Directories work too (e.g., extensions/subagent/).
#     To disable: add filename to disabledExtensions list below.
#
#   Adding an extension WITH npm deps:
#     1. Create packages/<name>/ with package.json + package-lock.json
#     2. Add a buildNpmPackage block below (follow existing patterns)
#     3. Add home.file mapping in the File Symlinks section
#     4. Add to PNAME_MAP in scripts/update-npm-pkg.sh
#     5. Run: just update-npm <name> && just home
#
#   Adding a skill (no npm deps):
#     Create skills/<name>/SKILL.md — auto-discovered, no changes here.
#
#   Updating pi or any npm package:
#     1. Edit version in packages/<name>/package.json (single source of truth)
#     2. Run: just update-npm <name>
#     3. Run: just home
#
#   Key patterns:
#     - npmVersion: reads version from package.json deps (no version duplication)
#     - npmDepsHash: sri hash, auto-updated by scripts/update-npm-pkg.sh
#     - Auto-discovery: extensions/ and skills/ contents auto-symlinked
#     - Patches: applied during buildNpmPackage installPhase (see patches/)
#
# Socket pattern: /tmp/pi-{session}-{window}.sock
#   - Auto-detected by bridge.ts from tmux (no shell setup needed)
#   - PI_SOCKET env var overrides auto-detection
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
  # Standalone tools
  # ===========================================================================

  # tk — minimal ticket system with dependency tracking
  # https://github.com/wedow/ticket
  tk = pkgs.stdenvNoCC.mkDerivation {
    pname = "tk";
    version = "0.3.2-patched";
    src = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/wedow/ticket/v0.3.2/ticket";
      hash = "sha256-QI8sET7MO8BxUHWTp4OG8bTMdDvmSRyenyYn79TZkCs=";
    };
    dontUnpack = true;
    # Patch generate_id: strip non-alphanumeric chars, use 3-char minimum prefix
    installPhase = ''
      install -Dm755 $src $out/bin/tk
      substituteInPlace $out/bin/tk \
        --replace-fail \
          'dir_name=$(basename "$(pwd)")' \
          'dir_name=$(basename "$(pwd)" | tr -d -c "a-zA-Z0-9-_")' \
        --replace-fail \
          '[[ ''${#prefix} -lt 2 ]] && prefix="''${dir_name:0:3}"' \
          '[[ ''${#prefix} -lt 3 ]] && prefix="''${dir_name:0:3}"'
    '';
  };

  # ===========================================================================
  # Packages (npm packages built via buildNpmPackage)
  # ===========================================================================
  # Each package: packages/<name>/ with package.json + package-lock.json
  # To add: mkdir packages/<name>, npm init, npm install <dep>, add block here,
  #         add to PNAME_MAP in scripts/update-npm-pkg.sh, run just update-npm <name>
  # To update: edit version in packages/<name>/package.json, run just update-npm <name>

  # Read version from a package's sole npm dependency (single source of truth)
  npmVersion = dir: let
    pkgJson = builtins.fromJSON (builtins.readFile (dir + "/package.json"));
  in
    builtins.head (builtins.attrValues pkgJson.dependencies);

  # Pi binary — built from npm, enables patching (retry behavior, etc.)
  pi-coding-agent = pkgs.buildNpmPackage {
    pname = "pi-coding-agent";
    version = npmVersion ./packages/pi;
    src = ./packages/pi;
    npmDepsHash = "sha256-PuNuGLWliaLn3YqDhtsr6jDxy/sSpN0ThNqiwygfMk4=";
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
    version = npmVersion ./packages/pi-mcp-adapter;
    src = ./packages/pi-mcp-adapter;
    npmDepsHash = "sha256-F1aVWQnw7dODrfcOgD4ygXiV5D+YbgY0hochO48qLzw=";
    dontNpmBuild = true;
    # TODO: patch needs path adjustment for npm package layout (was written for git repo)
    # patches = [./patches/claude-settings-support.patch];
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r node_modules/pi-mcp-adapter/* $out/
      cp -r node_modules $out/node_modules
      runHook postInstall
    '';
  };

  # Web search, content fetching, research (multi-provider: Brave, Tavily, Kagi)
  pi-internet = pkgs.buildNpmPackage {
    pname = "pi-internet";
    version = "0.1.0"; # github dep, can't use npmVersion
    src = ./packages/pi-internet;
    npmDepsHash = "sha256-A+RnTND6XHScz2d+0DHwWQb4WnEIoZs0PNVT8Ig97jQ=";
    makeCacheWritable = true;
    dontNpmBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r node_modules/pi-internet/* $out/
      cp -r node_modules $out/node_modules
      runHook postInstall
    '';
  };

  # Browser automation — peer deps only (no runtime npm deps)
  # pi-agent-browser = pkgs.buildNpmPackage {
  #   pname = "pi-agent-browser";
  #   version = npmVersion ./packages/pi-agent-browser;
  #   src = ./packages/pi-agent-browser;
  #   npmDepsHash = "sha256-fPu/KUxvqJIW/v3SvoP+ufw/hPGBrJQpJpqrry7XXXA=";
  #   dontNpmBuild = true;
  #   installPhase = ''
  #     runHook preInstall
  #     mkdir -p $out
  #     cp -r node_modules/pi-agent-browser/* $out/
  #     runHook postInstall
  #   '';
  # };

  # Subscription rotation
  pi-multi-pass = pkgs.buildNpmPackage {
    pname = "pi-multi-pass";
    version = npmVersion ./packages/pi-multi-pass;
    src = ./packages/pi-multi-pass;
    npmDepsHash = "sha256-ulNHxiWvLS9g/o3ut4AtQgMOn77xMu73ZXmRFaGLCFI=";
    dontNpmBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r node_modules/pi-multi-pass/* $out/

      # Fix upstream bug: pi.extensions points to directory, not the .ts file
      substituteInPlace "$out/package.json" \
        --replace-fail '"./extensions"' '"./extensions/multi-sub.ts"'

      runHook postInstall
    '';
  };

  # Interactive subagents — async sub-agent spawning in mux panes
  # https://github.com/HazAT/pi-interactive-subagents
  # pi-interactive-subagents = pkgs.stdenvNoCC.mkDerivation {
  #   pname = "pi-interactive-subagents";
  #   version = "3.0.0";
  #   src = pkgs.fetchFromGitHub {
  #     owner = "HazAT";
  #     repo = "pi-interactive-subagents";
  #     rev = "v3.0.0";
  #     hash = "sha256-LKv+RtU5EFp5ZYlB50laTpjkUU+tyEAN1H5/Vp6fC+0=";
  #   };
  #   installPhase = ''
  #     runHook preInstall
  #     mkdir -p $out
  #     cp -r $src/* $out/
  #     runHook postInstall
  #   '';
  # };

  # Diff review extension — interactive diff viewer/reviewer
  # https://github.com/JJGO/pi-diff-review
  # Note: --ignore-scripts skips the upstream `prepare: husky` script (devDep,
  # not needed at runtime; pi runs TS via jiti so no build step required).
  # pi-diff-review = pkgs.buildNpmPackage {
  #   pname = "pi-diff-review";
  #   version = "0.3.0"; # github dep, can't use npmVersion
  #   src = ./packages/pi-diff-review;
  #   npmDepsHash = "sha256-6/pDrbyRHlizPXHJ6LkQuF37DACQqBJFvGUbrXosLB0=";
  #   makeCacheWritable = true;
  #   dontNpmBuild = true;
  #   npmFlags = ["--ignore-scripts"];
  #   installPhase = ''
  #     runHook preInstall
  #     mkdir -p $out
  #     cp -r node_modules/pi-diff-review/* $out/
  #     cp -r node_modules $out/node_modules
  #     runHook postInstall
  #   '';
  # };

  # Synthetic.new model provider (dynamic model fetching, reasoning, vision)
  # Patch adds GLM-5.1 (and any post-1.1.10 models) to fallback list so they're
  # available at startup for `enabledModels` Ctrl+P scope resolution. Without
  # the patch, those models only appear after `session_start` async fetch.
  pi-synthetic-provider = pkgs.buildNpmPackage {
    pname = "pi-synthetic-provider";
    version = npmVersion ./packages/pi-synthetic-provider;
    src = ./packages/pi-synthetic-provider;
    npmDepsHash = "sha256-lW0n/yVTJQs2hcYTNFN/9fOIN30HFsHav5kbQ13KdaQ=";
    dontNpmBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r node_modules/@benvargas/pi-synthetic-provider/* $out/
      cp -r node_modules $out/node_modules
      ( cd $out && patch -p1 < ${./patches/synthetic-fallback-glm-5.1.patch} )
      runHook postInstall
    '';
  };
  # ===========================================================================
  # Auto-discovery Configuration
  # ===========================================================================

  # Extensions to exclude from auto-loading (filename as it appears in extensions/)
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
  # Simple extensions go in extensions/ — no need to add home.file entries.
  # Extensions with npm deps go in packages/ and need explicit home.file below.
  # ===========================================================================
  extensionDir = ./extensions;
  extensionDirExists = builtins.pathExists extensionDir;
  extensionEntries =
    if extensionDirExists
    then builtins.readDir extensionDir
    else {};

  # .ts files
  extensionTsFiles = builtins.filter (name: lib.hasSuffix ".ts" name && !builtins.elem name disabledExtensions) (
    builtins.attrNames extensionEntries
  );

  # Directories (e.g., subagent/)
  extensionDirs = builtins.filter (name: extensionEntries.${name} == "directory" && !builtins.elem name disabledExtensions) (
    builtins.attrNames extensionEntries
  );

  # Data files co-located with extensions (JSON configs, etc.)
  extensionDataFiles = builtins.filter (name: lib.hasSuffix ".json" name && name != "package.json") (
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

    # Map BRAVE_SEARCH_API_KEY → BRAVE_API_KEY (pi-internet expects the latter)
    if [ -n "$BRAVE_SEARCH_API_KEY" ] && [ -z "$BRAVE_API_KEY" ]; then
      export BRAVE_API_KEY="$BRAVE_SEARCH_API_KEY"
    fi

    # Preserve SYNTHETIC_API_KEY for pi-synthetic-provider (loaded from env, not agenix)
    if [ -n "$SYNTHETIC_API_KEY" ]; then
      export SYNTHETIC_API_KEY
    fi

    # Parse --profile flag (overrides multi-pass config only)
    MP_PROFILE=""
    PI_ARGS=()
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --profile)
          if [[ -z "''${2:-}" || "$2" == --* ]]; then
            echo "Warning: --profile requires a profile name" >&2
            shift
          else
            MP_PROFILE="$2"
            shift 2
          fi
          ;;
        *)
          PI_ARGS+=("$1")
          shift
          ;;
      esac
    done

    # Socket config — bridge.ts auto-detects tmux session/window.
    export PI_SOCKET_DIR="${socketConfig.dir}"
    export PI_SOCKET_PREFIX="${socketConfig.prefix}"

    # Detect session name (bridge.ts handles socket)
    if [ -n "$TMUX" ]; then
      PI_SESSION=$(${pkgs.tmux}/bin/tmux display-message -p '#{session_name}')
    else
      PI_SESSION="default"
    fi
    export PI_SESSION

    MASTER_DIR="$HOME/.pi/agent"

    # ---------------------------------------------------------------
    # Auto-detect profile from active agent dir or tmux session name.
    # Profile dir = ~/.pi/agent-{name}/ with auth.json
    # ---------------------------------------------------------------
    AUTO_PROFILE=""
    if [[ -n "''${PI_CODING_AGENT_DIR:-}" ]]; then
      # Extract profile from existing agent dir (e.g. ~/.pi/agent-rx → rx)
      _dir_name=$(basename "$PI_CODING_AGENT_DIR")
      if [[ "$_dir_name" == agent-* ]]; then
        AUTO_PROFILE="''${_dir_name#agent-}"
      fi
    elif [[ -f "$HOME/.pi/agent-''${PI_SESSION}/auth.json" ]]; then
      # Session name matches a profile dir
      AUTO_PROFILE="$PI_SESSION"
    fi

    # Resolve which profile to use for auth (auto-detected)
    # and which to use for multi-pass (--profile override or auto)
    AUTH_PROFILE="$AUTO_PROFILE"
    MP_PROFILE="''${MP_PROFILE:-$AUTO_PROFILE}"

    # ---------------------------------------------------------------
    # Build hybrid dir if we have a profile with auth
    # ---------------------------------------------------------------
    if [[ -n "$AUTH_PROFILE" ]]; then
      PROFILE_DIR="$HOME/.pi/agent-''${AUTH_PROFILE}"
      PROFILE_AUTH="$PROFILE_DIR/auth.json"

      if [[ -f "$PROFILE_AUTH" ]]; then
        HYBRID_DIR="/tmp/pi-config-''${PI_SESSION}-''${AUTH_PROFILE}"
        mkdir -p "$HYBRID_DIR"

        # Symlink shared config from master
        for item in ${lib.concatStringsSep " " sharedConfigItems}; do
          [[ -e "$MASTER_DIR/$item" || -L "$MASTER_DIR/$item" ]] && \
            ln -sfn "$MASTER_DIR/$item" "$HYBRID_DIR/$item"
        done

        mkdir -p "$MASTER_DIR/sessions"
        ln -sfn "$MASTER_DIR/sessions" "$HYBRID_DIR/sessions"
        ln -sfn "$PROFILE_AUTH" "$HYBRID_DIR/auth.json"

        # Symlink multi-pass config from the target profile
        # (--profile overrides which profile's multi-pass.json to use)
        MP_PROFILE_DIR="$HOME/.pi/agent-''${MP_PROFILE}"
        if [[ -f "$MP_PROFILE_DIR/multi-pass.json" ]]; then
          ln -sfn "$MP_PROFILE_DIR/multi-pass.json" "$HYBRID_DIR/multi-pass.json"
        elif [[ -f "$MASTER_DIR/multi-pass.json" ]]; then
          ln -sfn "$MASTER_DIR/multi-pass.json" "$HYBRID_DIR/multi-pass.json"
        fi

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
    tk
    pkgs.ddgr # DuckDuckGo CLI for web-search skill (free, no API limits)
    # pkgs.llm-agents.agent-browser # Browser automation CLI
  ];

  # ===========================================================================
  # File Symlinks
  # ===========================================================================
  home.file =
    {
      # Symlink pi binary directly (avoids node_modules conflict)
      ".local/bin/pi".source = "${pi-coding-agent}/bin/pi";

      # Global AGENTS.md
      ".pi/agent/AGENTS.md".source = ./sources/GLOBAL_AGENTS.md;
      ".pi/agent/APPEND_SYSTEM.md".source = ./sources/APPEND_SYSTEM.md;

      # Plain JSON configs — keybindings uses out-of-store symlink so pi can write to it
      ".pi/agent/keybindings.json".source = config.lib.mega.linkDotfile "home/common/programs/pi-coding-agent/keybindings.json";
      ".pi/agent/models.json".source = ./models.json;
      ".pi/agent/mcp.json".source = ./mcp.json;

      # Built extensions with npm dependencies
      # Full directory extensions (symlink whole package)
      # ".pi/agent/extensions/pi-agent-browser".source = pi-agent-browser;
      ".pi/agent/extensions/pi-mcp-adapter".source = pi-mcp-adapter;
      ".pi/agent/extensions/pi-internet".source = pi-internet;
      ".pi/agent/extensions/pi-multi-pass".source = pi-multi-pass;
      ".pi/agent/extensions/pi-synthetic-provider".source = pi-synthetic-provider;
      # ".pi/agent/extensions/pi-interactive-subagents".source = pi-interactive-subagents;
      # ".pi/agent/extensions/pi-diff-review".source = pi-diff-review;
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
