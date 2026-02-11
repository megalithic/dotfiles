# Pi Coding Agent Configuration
# Manages pi settings, extensions, skills, and socket naming via Nix
#
# Structure:
#   - default.nix (this file): Main config with auto-discovery
#   - extensions/: TypeScript extensions (auto-discovered)
#   - skills/: Simple skills (auto-discovered, symlinked)
#   - skills-with-deps/: Skills with npm dependencies (built with buildNpmPackage)
#   - sources/: Source files like GLOBAL_AGENTS.md
#
# Socket Configuration (single source of truth):
#   - PI_SOCKET_DIR: Directory for sockets (/tmp)
#   - PI_SOCKET_PREFIX: Socket name prefix (pi)
#   - PI_SESSION: Current tmux session name
#   - PI_SOCKET: Full socket path (/tmp/pi-{session}.sock)
#
# Socket pattern: /tmp/pi-{session}.sock
#   - One socket per tmux session (not per window)
#   - Agent window can be linked to other windows in same session
#   - Non-tmux fallback: /tmp/pi-default.sock
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
  # All socket-related config should reference these variables
  # Other files (hammerspoon, nvim, tmux) should use PI_SOCKET env var
  socketConfig = {
    dir = "/tmp";
    prefix = "pi";
    # Pattern: {dir}/{prefix}-{session}.sock
    # Example: /tmp/pi-mega.sock
  };

  # ===========================================================================
  # Skills with npm dependencies (need to be built)
  # ===========================================================================
  brave-search-skill = pkgs.buildNpmPackage {
    pname = "brave-search-skill";
    version = "1.0.0";

    src = ./skills-with-deps/brave-search;

    npmDepsHash = "sha256-BhgSY+lpkNb125ctAoIOzudqREgWSNpmU/r6pQdTlXE=";

    dontNpmBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r . $out/
      runHook postInstall
    '';
  };

  web-browser-skill = pkgs.buildNpmPackage {
    pname = "web-browser-skill";
    version = "1.0.0";

    src = ./skills-with-deps/web-browser;

    npmDepsHash = "sha256-vQxKChe57on93GAA180X/W36YNeumg7zPlcPhrT+yXQ=";

    dontNpmBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r . $out/
      runHook postInstall
    '';
  };

  # ===========================================================================
  # Auto-discovery Configuration
  # ===========================================================================

  # Extensions to exclude from auto-loading (keep source but don't install)
  # These can be loaded explicitly via the `pi` wrapper or piception
  disabledExtensions = [
    # nvim-bridge.ts now auto-loads - shows connected/disconnected status
  ];

  # Skills to exclude from auto-discovery
  disabledSkills = [
    # Add skill names here to disable them
  ];

  # ===========================================================================
  # Auto-discover extensions (.ts files in extensions/)
  # ===========================================================================
  extensionDir = ./extensions;
  extensionDirExists = builtins.pathExists extensionDir;

  extensionFiles =
    if extensionDirExists
    then
      builtins.filter (name: lib.hasSuffix ".ts" name && !builtins.elem name disabledExtensions) (
        builtins.attrNames (builtins.readDir extensionDir)
      )
    else [];

  extensionSymlinks = builtins.listToAttrs (
    map (name: {
      name = ".pi/agent/extensions/${name}";
      value = {
        source = ./extensions/${name};
      };
    })
    extensionFiles
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
      value = {
        source = ./skills/${name};
      };
    })
    skillDirs
  );

  # ===========================================================================
  # Multi-Profile Configuration
  # ===========================================================================
  # Profiles that link to master ~/.pi/agent/ (except auth.json and sessions/)
  # User sets PI_CODING_AGENT_DIR in their tmux session .envrc
  # Master (~/.pi/agent/) serves as both config source AND personal profile
  profiles = ["evirts" "cspire"];

  # Config items to symlink from master to each profile
  # Excludes: auth.json (per-profile auth), sessions/ (per-profile history)
  sharedConfigItems = [
    "AGENTS.md"
    "settings.json"
    "keybindings.json"
    "extensions"
    "skills"
  ];

  # Generate symlinks for each profile pointing to master
  profileSymlinks = builtins.listToAttrs (
    lib.flatten (
      map (
        profile:
          map (item: {
            name = ".pi/agent-${profile}/${item}";
            value.source =
              config.lib.file.mkOutOfStoreSymlink
              "${config.home.homeDirectory}/.pi/agent/${item}";
          })
          sharedConfigItems
      )
      profiles
    )
  );

  # ===========================================================================
  # Keybindings
  # ===========================================================================
  managedKeybindings = {
    # shift+enter should work via CSI u (ghostty + tmux extended-keys)
    # ctrl+j as fallback for terminals that don't support shift+enter
    newLine = ["shift+enter" "ctrl+j"];
  };

  managedKeybindingsJson = pkgs.writeText "pi-managed-keybindings.json" (builtins.toJSON managedKeybindings);

  # ===========================================================================
  # Settings to merge (not overwrite)
  # ===========================================================================
  managedSettings = {
    defaultProvider = "anthropic";
    defaultModel = "claude-opus-4-5";
    defaultThinkingLevel = "medium";
    doubleEscapeAction = "tree";
    enableSkillCommands = true;
    hideThinkingBlock = true;
    editorPaddingX = 1;
    # Only include models you have API access to
    # Pi will warn about patterns that don't match any available models
    enabledModels = [
      "claude-opus-4-*"
      "claude-sonnet-4-5"
      "gemini-3*"
    ];
  };

  managedSettingsJson = pkgs.writeText "pi-managed-settings.json" (builtins.toJSON managedSettings);
in {
  # ===========================================================================
  # Pi Wrapper Scripts
  # ===========================================================================
  # NOTE: Base `pi` binary is installed via pkgs.llm-agents.pi in ../default.nix
  # These wrappers add environment setup (agenix secrets, tmux socket naming)
  home.packages = [
    # Pi agent wrapper with socket configuration
    # Socket pattern: /tmp/pi-{session}.sock (one per tmux session)
    # Alias: pisock (preferred), pinvim (legacy)
    (pkgs.writeShellScriptBin "pinvim" ''
      # Source agenix secrets for API keys (BRAVE_SEARCH_API_KEY, etc.)
      AGENIX_DIR="$(${pkgs.darwin.system_cmds}/bin/getconf DARWIN_USER_TEMP_DIR)/agenix"
      if [ -f "$AGENIX_DIR/env-vars" ]; then
        . "$AGENIX_DIR/env-vars"
      fi

      # Clear conflicting AWS credentials (pi doesn't need them for Anthropic)
      unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN 2>/dev/null || true

      # Socket configuration (matches socketConfig in default.nix)
      export PI_SOCKET_DIR="${socketConfig.dir}"
      export PI_SOCKET_PREFIX="${socketConfig.prefix}"

      # Set up socket for tmux integration
      # Format: /tmp/pi-{session}.sock (one socket per tmux session)
      if [ -n "$TMUX" ]; then
        PI_SESSION=$(${pkgs.tmux}/bin/tmux display-message -p '#{session_name}')
        export PI_SESSION
        export PI_SOCKET="${socketConfig.dir}/${socketConfig.prefix}-''${PI_SESSION}.sock"
      else
        # Non-tmux fallback
        export PI_SESSION="default"
        export PI_SOCKET="${socketConfig.dir}/${socketConfig.prefix}-default.sock"
      fi

      exec pi "$@"
    '')
  ];

  # ===========================================================================
  # File Symlinks
  # ===========================================================================
  home.file =
    {
      # Global AGENTS.md for pi
      ".pi/agent/AGENTS.md".source = ./sources/GLOBAL_AGENTS.md;

      # Skills with npm dependencies (built via buildNpmPackage)
      ".pi/agent/skills/brave-search".source = brave-search-skill;
      ".pi/agent/skills/web-browser".source = web-browser-skill;
    }
    // extensionSymlinks
    // skillSymlinks;

  # ===========================================================================
  # Settings Merge Activation
  # ===========================================================================
  # Merges our managed settings into ~/.pi/agent/settings.json
  # Preserves user settings managed by pi itself
  home.activation.mergePiSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    SETTINGS_FILE="${config.home.homeDirectory}/.pi/agent/settings.json"
    MERGE_JSON="${managedSettingsJson}"

    # Create settings directory if it doesn't exist
    mkdir -p "$(dirname "$SETTINGS_FILE")"

    # If settings.json doesn't exist, create minimal config
    if [[ ! -f "$SETTINGS_FILE" ]]; then
      echo '{}' > "$SETTINGS_FILE"
    fi

    # Merge settings, preserving existing keys unless overridden
    ${pkgs.jq}/bin/jq -s '.[0] * .[1]' \
      "$SETTINGS_FILE" \
      "$MERGE_JSON" > "''${SETTINGS_FILE}.tmp"

    mv "''${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
  '';

  # ===========================================================================
  # Keybindings Merge Activation
  # ===========================================================================
  # Merges our managed keybindings into ~/.pi/agent/keybindings.json
  home.activation.mergePiKeybindings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    KEYBINDINGS_FILE="${config.home.homeDirectory}/.pi/agent/keybindings.json"
    MERGE_JSON="${managedKeybindingsJson}"

    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$KEYBINDINGS_FILE")"

    # If keybindings.json doesn't exist, create minimal config
    if [[ ! -f "$KEYBINDINGS_FILE" ]]; then
      echo '{}' > "$KEYBINDINGS_FILE"
    fi

    # Merge keybindings, preserving existing keys unless overridden
    ${pkgs.jq}/bin/jq -s '.[0] * .[1]' \
      "$KEYBINDINGS_FILE" \
      "$MERGE_JSON" > "''${KEYBINDINGS_FILE}.tmp"

    mv "''${KEYBINDINGS_FILE}.tmp" "$KEYBINDINGS_FILE"
  '';

  # ===========================================================================
  # Profile Symlinks Activation
  # ===========================================================================
  # Creates symlinks in profile directories pointing to master ~/.pi/agent/
  # This is done via activation script because mkOutOfStoreSymlink doesn't work
  # reliably for symlinks-to-symlinks
  # Run after ALL other activations to ensure the symlink cleanup happens last
  home.activation.createPiProfiles = lib.hm.dag.entryAfter ["linkGeneration" "onFilesChange" "setupLaunchAgents"] ''
    MASTER_DIR="${config.home.homeDirectory}/.pi/agent"
    PROFILES="${lib.concatStringsSep " " profiles}"
    SHARED_ITEMS="${lib.concatStringsSep " " sharedConfigItems}"

    # WORKAROUND: remove recursive symlink if created by linkGeneration
    [[ -L "$MASTER_DIR/skills/skills" ]] && unlink "$MASTER_DIR/skills/skills" 2>/dev/null || true

    for profile in $PROFILES; do
      PROFILE_DIR="${config.home.homeDirectory}/.pi/agent-''${profile}"
      mkdir -p "$PROFILE_DIR"

      for item in $SHARED_ITEMS; do
        TARGET="$MASTER_DIR/$item"
        LINK="$PROFILE_DIR/$item"
        RESOLVED_TARGET=$(cd "$MASTER_DIR" && pwd -P)/$item
        RESOLVED_LINK_DIR=$(cd "$PROFILE_DIR" && pwd -P)

        # Skip if this would create recursion
        [[ "$RESOLVED_LINK_DIR" == "$RESOLVED_TARGET"* ]] && continue

        # Create symlink if target exists
        [[ -e "$TARGET" || -L "$TARGET" ]] && ln -sfn "$TARGET" "$LINK"
      done
    done

    echo "Activated pi profile symlinks"
  '';

  # ===========================================================================
  # Fish Shell Aliases
  # ===========================================================================
  programs.fish.shellAliases = {
    pic = "pi -c"; # Continue last session
    pir = "pi -r"; # Resume mode
    pisock = "pinvim"; # pi with socket connection
    pis = "pinvim"; # pi with socket connection
  };
}
