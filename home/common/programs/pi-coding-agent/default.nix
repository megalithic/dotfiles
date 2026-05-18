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
#   Adding a skill (no npm deps):
#     Create skills/<name>/SKILL.md — auto-discovered, no changes here.
#
#   Adding an extension WITH npm deps — pick a build pattern:
#
#   Pattern A: wrapper + buildNpmPackage
#     Use when: npm-only release, no public repo, or upstream lockfile broken
#     Examples: pi-coding-agent, pi-internet, pi-agent-browser, pi-diff-review
#       1. mkdir packages/<name>; create wrapper package.json (single dep at pinned ver)
#       2. cd packages/<name> && npm install --package-lock-only
#       3. Add a buildNpmPackage block (src = ./packages/<name>)
#       4. Add to PNAME_MAP in scripts/update-npm-pkg.sh
#       5. just update-npm <name> && just home
#
#   Pattern B: fetchFromGitHub + buildNpmPackage
#     Use when: public GitHub repo + has npm deps + lockfile available (or vendorable)
#     Examples: pi-mcp-adapter (vendored lockfile from previous tag at v2.6.0)
#       1. Add a buildNpmPackage block with src = pkgs.fetchFromGitHub { rev="v<x>"; hash=...; }
#       2. If upstream has no lockfile: vendor one in patches/, copy via postPatch
#       3. Add to GITHUB_NPM_PKG_MAP in scripts/update-npm-pkg.sh
#       4. just update-npm <name> && just home (fake hash workflow gets npmDepsHash)
#
#   Pattern C: fetchFromGitHub + stdenvNoCC
#     Use when: public GitHub repo + zero npm deps
#     Examples: pi-multi-pass
#       1. stdenvNoCC.mkDerivation with src = pkgs.fetchFromGitHub { ... }
#       2. installPhase: cp -r $src/* $out/
#       3. Add to GITHUB_NO_DEPS_PKG_MAP in scripts/update-npm-pkg.sh
#       4. just update-npm <name> && just home
#
#   Pattern D: fetchurl (npm tarball) + stdenvNoCC
#     Use when: npm-only release + zero npm deps
#     Examples: pi-synthetic-provider
#       1. stdenvNoCC.mkDerivation with src = pkgs.fetchurl { url; hash; }
#       2. Default unpackPhase handles .tgz
#       3. installPhase: cp -r ./* $out/
#       4. Add to FETCHURL_PKG_MAP in scripts/update-npm-pkg.sh
#       5. just update-npm <name> && just home
#
#   Decision tree:
#     no deps + GitHub repo → Pattern C
#     no deps + npm-only    → Pattern D
#     deps + GitHub + lockfile (or vendorable) → Pattern B
#     deps + npm-only or broken upstream lockfile → Pattern A
#
#   Updating any package:
#     just update-npm <name>          # one package, latest
#     just update-npm <name> <version> # specific version
#     just update-npm                  # all packages
#
#   Patch status:
#     - synthetic-fallback-glm-5.1.patch: DROPPED (obsolete, features upstream at v1.1.12)
#     - claude-settings-support.patch: DISABLED, awaiting rewrite for v2.6.0 architecture
#     - pi-mcp-adapter-2.6.0-package-lock.json: vendored lockfile generated from v2.6.0
#       package.json; required because v2.6.0 does not include a lockfile
#     - pi retry patches: inline substituteInPlace in installPhase (still active)
#
#   Key patterns:
#     - npmVersion: reads version from package.json deps (Pattern A only, single source of truth)
#     - npmDepsHash: SRI hash, auto-updated by scripts/update-npm-pkg.sh
#     - Auto-discovery: extensions/ and skills/ contents auto-symlinked
#
# Socket pattern: ${PI_STATE_DIR}/sockets/pi-{session}-{window}.sock
#   - Auto-detected by bridge.ts from tmux (no shell setup needed)
#   - PI_SOCKET env var overrides auto-detection
#   - Non-tmux fallback: ${PI_STATE_DIR}/sockets/pi-default-0.sock
#
# Based on: https://github.com/otahontas/nix/tree/main/home/configs/pi-coding-agent
{
  config,
  pkgs,
  lib,
  ...
}: let
  # ===========================================================================
  # Pi Runtime State (single source of truth)
  # ===========================================================================
  piStateDir = "${config.xdg.stateHome}/pi";

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
    npmDepsHash = "sha256-Y/L4wcndcDor200xtwTPtmXuxA0+1VMRE6G2xW+ft34=";
    dontNpmBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib
      cp -r node_modules $out/lib/node_modules
      mkdir -p $out/bin
      ln -s $out/lib/node_modules/@earendil-works/pi-coding-agent/dist/cli.js $out/bin/pi

      # Patch: unlimited 429 retries + capped backoff
      TARGET=$out/lib/node_modules/@earendil-works/pi-coding-agent/dist/core/agent-session.js

      # 1. Skip maxRetries cap for 429/rate-limit errors
      substituteInPlace "$TARGET" \
        --replace-fail 'if (this._retryAttempt > settings.maxRetries) {' \
        'const _is429 = /429|rate.?limit|too many requests/i.test(message.errorMessage || ""); if (!_is429 && this._retryAttempt > settings.maxRetries) {'

      # 2. Cap delay at maxDelayMs (set to 900000/15min in settings.json)
      substituteInPlace "$TARGET" \
        --replace-fail 'const delayMs = settings.baseDelayMs * 2 ** (this._retryAttempt - 1);' \
        'const delayMs = Math.min(settings.baseDelayMs * 2 ** (this._retryAttempt - 1), settings.maxDelayMs);'

      # 3. Expose setScopedModels to extensions via providerActions
      substituteInPlace "$TARGET" \
        --replace-fail \
          'unregisterProvider: (name) => {' \
          'setScopedModels: (models) => { this.setScopedModels(models); }, unregisterProvider: (name) => {'

      # Patch runner.js to wire setScopedModels through to extension runtime
      RUNNER=$out/lib/node_modules/@earendil-works/pi-coding-agent/dist/core/extensions/runner.js
      substituteInPlace "$RUNNER" \
        --replace-fail \
          'this.runtime.registerProvider = (name, config) => {' \
          'this.runtime.setScopedModels = providerActions?.setScopedModels ?? (() => {}); this.runtime.registerProvider = (name, config) => {'

      runHook postInstall
    '';
  };

  # MCP adapter extension (has npm dependencies)
  # https://github.com/nicobailon/pi-mcp-adapter — v2.6.0.
  # Upstream does not include package-lock.json; a lockfile generated from
  # v2.6.0 package.json is vendored below. npmDepsHash captures full transitive
  # closure.
  # NOTE: claude-settings-support.patch was disabled here (TODO since v2.4.1) and
  # needs full rewrite for the current ConfigSourceSpec architecture. Tracked in
  # a separate ticket; not blocking the migration.
  pi-mcp-adapter = pkgs.buildNpmPackage {
    pname = "pi-mcp-adapter";
    version = "2.6.0";
    src = pkgs.fetchFromGitHub {
      owner = "nicobailon";
      repo = "pi-mcp-adapter";
      rev = "v2.6.0";
      hash = "sha256-An8T5HCzofCZ0iNDaUPu8NDk+8ndPgAm+owm6F9kmYM=";
    };
    npmDepsHash = "sha256-w0wWJuUQAclQn7CV880bC2m9IX/5iMYKS45A5X4To/8=";
    dontNpmBuild = true;
    # Upstream does not include package-lock.json; vendor one generated from
    # v2.6.0 package.json.
    postPatch = ''
      cp ${./patches/pi-mcp-adapter-2.6.0-package-lock.json} package-lock.json
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r . $out/
      runHook postInstall
    '';
  };

  # web-browser skill scripts — bakes node_modules (ws) into a derivation so
  # CDP-using scripts (cdp.js + dependents) can resolve `ws` at runtime even
  # though the skill dir is read-only in nix-store.
  webBrowserScripts = pkgs.buildNpmPackage {
    pname = "web-browser-scripts";
    version = "0.1.0";
    src = ./skills/web-browser/scripts;
    npmDepsHash = "sha256-vQxKChe57on93GAA180X/W36YNeumg7zPlcPhrT+yXQ=";
    dontNpmBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r . $out/
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

  # pi-multi-pass: now installed as a standalone extension file (extensions/multi-sub.ts)
  # with local alias support patches. Removed from nix derivation pattern C.
  # https://github.com/hjanuschka/pi-multi-pass

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

  # Synthetic.new model provider — zero runtime deps, npm tarball direct
  # https://www.npmjs.com/package/@benvargas/pi-synthetic-provider
  # GLM-5.1 patch dropped — v1.1.12 already includes GLM-5.1, Kimi-K2.6, Nemotron upstream.
  pi-synthetic-provider = pkgs.stdenvNoCC.mkDerivation {
    pname = "pi-synthetic-provider";
    version = "1.1.12";
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@benvargas/pi-synthetic-provider/-/pi-synthetic-provider-1.1.12.tgz";
      hash = "sha256-fYGVipd4047IcEToU0oxcR0RnQBHWJAFo6c26Sh+BJM=";
    };
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r ./* $out/
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
  # web-browser is wired manually below (needs buildNpmPackage for ws)
  disabledSkills = [
    "web-browser"
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
  # Profile is env-var-only (PI_PROFILE, PI_MULTI_PASS_PRESET, PI_MODEL_SCOPE).
  # All config lives in ~/.pi/agent/ — no hybrid dirs, no profile borrowing.

  pinvim = pkgs.writeShellScriptBin "pinvim" ''
    # Source agenix secrets for API keys (BRAVE_SEARCH_API_KEY, etc.)
    AGENIX_DIR="$(${pkgs.darwin.system_cmds}/bin/getconf DARWIN_USER_TEMP_DIR)/agenix"
    if [ -f "$AGENIX_DIR/env-vars" ]; then
      . "$AGENIX_DIR/env-vars"
    fi

    # Clear conflicting env from previous pinvim sessions
    unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN 2>/dev/null || true
    unset PI_CODING_AGENT_DIR 2>/dev/null || true

    # Map BRAVE_SEARCH_API_KEY → BRAVE_API_KEY (pi-internet expects the latter)
    if [ -n "$BRAVE_SEARCH_API_KEY" ] && [ -z "$BRAVE_API_KEY" ]; then
      export BRAVE_API_KEY="$BRAVE_SEARCH_API_KEY"
    fi

    # Preserve SYNTHETIC_API_KEY for pi-synthetic-provider (loaded from env, not agenix)
    if [ -n "$SYNTHETIC_API_KEY" ]; then
      export SYNTHETIC_API_KEY
    fi

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

    # ---------------------------------------------------------------
    # Profile detection: --profile flag > tmux session > default mega
    # No profile dirs, no hybrid dirs — just env vars.
    # ---------------------------------------------------------------
    PI_PROFILE="''${EXPLICIT_PROFILE:-$PI_SESSION}"
    export PI_PROFILE
    export PI_MULTI_PASS_PRESET="$PI_PROFILE"

    MASTER_DIR="$HOME/.pi/agent"

    # ---------------------------------------------------------------
    # Model scope: export PI_MODEL_SCOPE for multi-sub.ts extension.
    # The extension applies scoped models at session_start (after
    # extension-registered providers like rx-anthropic are available).
    # ---------------------------------------------------------------
    export PI_MODEL_SCOPE="''${PI_MODEL_SCOPE:-$PI_PROFILE}"

    exec ${pi-coding-agent}/bin/pi "''${PI_ARGS[@]}"
  '';

  p = pkgs.writeShellScriptBin "p" ''exec ${pinvim}/bin/pinvim "$@"'';
in {
  home.sessionVariables.PI_STATE_DIR = piStateDir;

  # web-browser skill (skills/web-browser/scripts/start.js)
  # Defaults to Helium binary + Brave Nightly profile source. start.js falls
  # back to other Chromium-family installs if these paths are missing.
  home.sessionVariables.WEB_BROWSER_PATH = "/Applications/Helium.app/Contents/MacOS/Helium";
  home.sessionVariables.WEB_BROWSER_PROFILE = "${config.home.homeDirectory}/Library/Application Support/BraveSoftware/Brave-Browser-Nightly";

  home.packages = [
    pinvim
    p
    tk
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
      ".pi/agent/multi-pass.json".source = config.lib.mega.linkDotfile "home/common/programs/pi-coding-agent/multi-pass.json";

      ".pi/agent/models.json".source = ./models.json;
      ".pi/agent/mcp.json".source = ./mcp.json;

      # Built extensions with npm dependencies
      # Full directory extensions (symlink whole package)
      # ".pi/agent/extensions/pi-agent-browser".source = pi-agent-browser;
      ".pi/agent/extensions/pi-mcp-adapter".source = pi-mcp-adapter;

      # web-browser skill: SKILL.md from source, scripts/ from built derivation
      # (scripts need node_modules/ws baked in by buildNpmPackage)
      ".pi/agent/skills/web-browser/SKILL.md".source = ./skills/web-browser/SKILL.md;
      ".pi/agent/skills/web-browser/scripts".source = webBrowserScripts;
      ".pi/agent/extensions/pi-internet".source = pi-internet;
      # pi-multi-pass: auto-discovered as extensions/multi-sub.ts (no nix derivation needed)
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

  home.activation.cleanProfileMultiPass = lib.hm.dag.entryAfter ["writeBoundary"] ''
    for profile in rx evirts cspire; do
      path="$HOME/.pi/agent-$profile/multi-pass.json"
      if [ -L "$path" ]; then
        target="$(${pkgs.coreutils}/bin/readlink "$path")"
        case "$target" in
          /nix/store/*|$HOME/.dotfiles/*)
            run rm "$path"
            ;;
        esac
      fi
    done
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
