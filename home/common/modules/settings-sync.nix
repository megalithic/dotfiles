# settings-sync.nix - Declarative app settings sync between machines
#
# Syncs app settings to/from a sync directory (iCloud, Syncthing, ProtonDrive).
# Handles SQLite databases safely by using sqlite3's backup command.
#
# Usage:
#   settings-sync export [app|all]   - Export to sync dir
#   settings-sync import [app|all]   - Import from sync dir
#   settings-sync status             - Show sync status
#
# IMPORTANT: Quit apps before syncing to avoid database corruption.
#
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.settings-sync;

  # Expand ~ to $HOME in paths
  expandPath = path: if hasPrefix "~" path then "\${HOME}${removePrefix "~" path}" else path;

  # =========================================================================
  # App Profiles
  # =========================================================================
  # Define what/where to sync for each app. Add new apps here.
  #
  appProfiles = {
    brave-nightly = {
      name = "Brave Browser Nightly";
      processName = "Brave Browser Nightly";
      source = "Library/Application Support/BraveSoftware/Brave-Browser-Nightly/Default";
      include = [
        "Preferences" "Bookmarks" "Bookmarks.bak" "Secure Preferences"
        "Local Extension Settings" "Extension State" "Sync Extension Settings"
        "Sessions" "IndexedDB"
      ];
      exclude = [
        "*.log" "*.tmp" "LOG" "LOG.old" "LOCK" ".DS_Store"
        "BudgetDatabase" "chrome_cart_db" "commerce_subscription_db"
        "AutofillStrikeDatabase" "optimization_guide_*" "Download Service"
        "GCM Store" "VideoDecodeStats" "blob_storage" "Cache" "Code Cache"
        "GPUCache" "DawnGraphiteCache" "DawnWebGPUCache" "Service Worker"
        "shared_proto_db" "Site Characteristics Database" "Crashpad"
      ];
      sqlite = [ "Cookies" "Web Data" "History" "Login Data" "Shortcuts" "Top Sites" "Favicons" ];
      conditionalFiles = {
        cookies = [ "Cookies" ];
        history = [ "History" ];
        logins = [ "Login Data" ];
      };
    };

    mailmate = {
      name = "MailMate";
      processName = "MailMate";
      source = "Library/Application Support/MailMate";
      include = [
        "Sources.plist" "Identities.plist" "Mailboxes.plist"
        "Signatures.plist" "Submission.plist" "Tags.plist"
        "Bundles" "Resources" "Managed"
      ];
      exclude = [ "*.log" ".DS_Store" ".database_lock" ];
      sqlite = [];
      defaults = "com.freron.MailMate";
      conditionalFiles = {
        database = [ "Database.noindex" "Messages" ];
      };
    };

    fantastical = {
      name = "Fantastical";
      processName = "Fantastical";
      source = "Library/Group Containers/85C27NK92C.com.flexibits.fantastical2.mac";
      include = [ "Database" "Library/Preferences" ];
      exclude = [ "*.log" ".DS_Store" "Cache" "Caches" ];
      sqlite = [ "Database/Fantastical-8.fcdata" ];
      defaults = "com.flexibits.fantastical2.mac";
    };

    vscode = {
      name = "VS Code";
      processName = "Code";
      source = "Library/Application Support/Code/User";
      include = [ "settings.json" "keybindings.json" "snippets" "profiles" ];
      exclude = [ "*.log" "workspaceStorage" "globalStorage" "History" ];
      sqlite = [];
    };

    raycast = {
      name = "Raycast";
      processName = "Raycast";
      source = "Library/Application Support/Raycast";
      include = [];
      exclude = [ "*.log" ".DS_Store" "Cache" "Crashpad" ];
      sqlite = [];
      defaults = "com.raycast.macos";
    };

    obsidian = {
      name = "Obsidian";
      processName = "Obsidian";
      source = "Library/Application Support/obsidian";
      include = [ "obsidian.json" ];
      exclude = [ "*.log" "Cache" "GPUCache" ];
      sqlite = [];
    };
  };

  # Get list of enabled app names
  enabledApps = filter (name: cfg.apps.${name}.enable or false) (attrNames cfg.apps);

  # =========================================================================
  # Sync Script
  # =========================================================================
  syncScript = pkgs.writeShellScriptBin "settings-sync" ''
    set -euo pipefail

    SYNC_DIR="$(eval echo "${cfg.syncDir}")"
    VERBOSE=0
    DRY_RUN=0
    FORCE=0

    # Colors
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
    BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'

    log() { echo -e "''${GREEN}●''${NC} $1"; }
    info() { echo -e "''${BLUE}ℹ''${NC} $1"; }
    warn() { echo -e "''${YELLOW}⚠''${NC} $1"; }
    error() { echo -e "''${RED}✗''${NC} $1" >&2; }
    debug() { [[ "$VERBOSE" == "1" ]] && echo -e "''${CYAN}…''${NC} $1" || true; }

    is_running() { pgrep -xq "$1" 2>/dev/null; }

    # Safe SQLite backup
    sqlite_backup() {
      local src="$1" dst="$2"
      [[ ! -f "$src" ]] && return 0
      mkdir -p "$(dirname "$dst")"
      debug "SQLite backup: $src"
      ${pkgs.sqlite}/bin/sqlite3 "$src" ".backup '$dst'" 2>/dev/null || {
        warn "SQLite busy, copying directly: $(basename "$src")"
        cp "$src" "$dst"
      }
    }

    # Rsync wrapper
    sync_dir() {
      local src="$1" dst="$2"; shift 2
      local args=(-a --delete)
      [[ "$VERBOSE" == "1" ]] && args+=(-v)
      [[ "$DRY_RUN" == "1" ]] && args+=(--dry-run)
      for ex in "$@"; do args+=(--exclude="$ex"); done
      mkdir -p "$dst"
      ${pkgs.rsync}/bin/rsync "''${args[@]}" "$src/" "$dst/"
    }

    copy_file() {
      local src="$1" dst="$2"
      [[ ! -e "$src" ]] && return 0
      mkdir -p "$(dirname "$dst")"
      if [[ "$DRY_RUN" == "1" ]]; then
        echo "[dry-run] cp $src -> $dst"
      else
        cp -R "$src" "$dst"
      fi
    }

    ${concatStringsSep "\n\n" (map (appName: let
      p = appProfiles.${appName};
      appCfg = cfg.apps.${appName};
      funcName = replaceStrings ["-"] ["_"] appName;
      srcDir = "$HOME/${p.source}";
      dstDir = "$SYNC_DIR/${appName}";
      excludeArgs = escapeShellArgs (p.exclude or []);
    in ''
    # ═══════════════════════════════════════════════════════════════════════
    # ${p.name}
    # ═══════════════════════════════════════════════════════════════════════
    export_${funcName}() {
      ${optionalString (p.processName or null != null) ''
      if is_running "${p.processName}" && [[ "$FORCE" != "1" ]]; then
        error "${p.name} is running. Quit first or use --force"
        return 1
      fi
      ''}

      log "Exporting ${p.name}..."
      mkdir -p "${dstDir}"

      ${if p.include == [] then ''
      # Sync entire directory
      sync_dir "${srcDir}" "${dstDir}" ${excludeArgs}
      '' else ''
      # Sync specific files/dirs
      ${concatMapStringsSep "\n" (item: ''
      [[ -e "${srcDir}/${item}" ]] && \
        if [[ -d "${srcDir}/${item}" ]]; then
          sync_dir "${srcDir}/${item}" "${dstDir}/${item}" ${excludeArgs}
        else
          copy_file "${srcDir}/${item}" "${dstDir}/${item}"
        fi
      '') p.include}
      ''}

      ${optionalString (p.sqlite or [] != []) ''
      # SQLite databases
      ${concatMapStringsSep "\n" (db: ''
      sqlite_backup "${srcDir}/${db}" "${dstDir}/${db}"
      '') p.sqlite}
      ''}

      ${concatStringsSep "\n" (mapAttrsToList (flag: files:
        optionalString (appCfg.${flag} or false) ''
        # Conditional: ${flag}
        ${concatMapStringsSep "\n" (f: ''
        if [[ -e "${srcDir}/${f}" ]]; then
          if [[ -d "${srcDir}/${f}" ]]; then
            sync_dir "${srcDir}/${f}" "${dstDir}/${f}" ${excludeArgs}
          else
            sqlite_backup "${srcDir}/${f}" "${dstDir}/${f}"
          fi
        fi
        '') files}
        ''
      ) (p.conditionalFiles or {}))}

      ${optionalString (p.defaults or null != null) ''
      # Export defaults
      defaults export "${p.defaults}" "${dstDir}/defaults.plist" 2>/dev/null || true
      ''}

      log "Exported ${p.name} → $SYNC_DIR/${appName}"
    }

    import_${funcName}() {
      [[ ! -d "${dstDir}" ]] && { info "No sync data for ${p.name}"; return 0; }

      ${optionalString (p.processName or null != null) ''
      if is_running "${p.processName}" && [[ "$FORCE" != "1" ]]; then
        error "${p.name} is running. Quit first or use --force"
        return 1
      fi
      ''}

      log "Importing ${p.name}..."
      mkdir -p "${srcDir}"

      # Restore everything from sync dir
      sync_dir "${dstDir}" "${srcDir}"

      ${optionalString (p.defaults or null != null) ''
      [[ -f "${dstDir}/defaults.plist" ]] && \
        defaults import "${p.defaults}" "${dstDir}/defaults.plist" 2>/dev/null || true
      ''}

      log "Imported ${p.name}"
    }

    status_${funcName}() {
      printf "  %-22s" "${p.name}"
      if [[ -d "${dstDir}" ]]; then
        local sz=$(du -sh "${dstDir}" 2>/dev/null | cut -f1)
        local tm=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "${dstDir}" 2>/dev/null || echo "?")
        echo -e "''${GREEN}✓''${NC} $sz  ($tm)"
      else
        echo -e "''${YELLOW}○''${NC} not synced"
      fi
    }
    '') enabledApps)}

    # ═══════════════════════════════════════════════════════════════════════
    # Commands
    # ═══════════════════════════════════════════════════════════════════════
    cmd_export() {
      local app="''${1:-all}"
      case "$app" in
        ${concatStringsSep "\n" (map (a: "${a}) export_${replaceStrings ["-"] ["_"] a} ;;") enabledApps)}
        all) ${concatMapStringsSep "\n" (a: "export_${replaceStrings ["-"] ["_"] a} || true") enabledApps} ;;
        *) error "Unknown app: $app"; echo "Available: ${concatStringsSep ", " enabledApps}"; exit 1 ;;
      esac
    }

    cmd_import() {
      local app="''${1:-all}"
      case "$app" in
        ${concatStringsSep "\n" (map (a: "${a}) import_${replaceStrings ["-"] ["_"] a} ;;") enabledApps)}
        all) ${concatMapStringsSep "\n" (a: "import_${replaceStrings ["-"] ["_"] a} || true") enabledApps} ;;
        *) error "Unknown app: $app"; echo "Available: ${concatStringsSep ", " enabledApps}"; exit 1 ;;
      esac
      echo ""
      info "Import complete. OAuth-based accounts (Gmail, Google Calendar) need re-auth."
    }

    cmd_status() {
      echo -e "''${BOLD}Settings Sync Status''${NC}"
      echo "Directory: $SYNC_DIR"
      echo ""
      ${concatMapStringsSep "\n" (a: "status_${replaceStrings ["-"] ["_"] a}") enabledApps}
      echo ""
      [[ -d "$SYNC_DIR" ]] && echo "Total: $(du -sh "$SYNC_DIR" 2>/dev/null | cut -f1)"
    }

    usage() {
      cat << 'EOF'
settings-sync - Sync app settings between machines

USAGE
    settings-sync <command> [app] [options]

COMMANDS
    export [app|all]    Export settings to sync directory
    import [app|all]    Import settings from sync directory
    status              Show sync status

APPS
    ${concatStringsSep ", " enabledApps}

OPTIONS
    -f, --force     Sync even if app is running (may cause corruption)
    -n, --dry-run   Show what would be done
    -v, --verbose   Verbose output

EXAMPLES
    settings-sync export all
    settings-sync import mailmate
    settings-sync status
EOF
    }

    # Parse args
    CMD=""; APP="all"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        export|import|status) CMD="$1" ;;
        -f|--force) FORCE=1 ;;
        -n|--dry-run) DRY_RUN=1 ;;
        -v|--verbose) VERBOSE=1 ;;
        -h|--help) usage; exit 0 ;;
        -*) error "Unknown option: $1"; exit 1 ;;
        *) APP="$1" ;;
      esac
      shift
    done

    case "''${CMD:-}" in
      export) cmd_export "$APP" ;;
      import) cmd_import "$APP" ;;
      status) cmd_status ;;
      *) usage ;;
    esac
  '';

in {
  options.settings-sync = {
    enable = mkEnableOption "Sync app settings between machines";

    syncDir = mkOption {
      type = types.str;
      default = "~/Library/Mobile Documents/com~apple~CloudDocs/Sync/app-settings";
      example = "~/Sync/app-settings";
      description = "Directory for synced settings (iCloud, Syncthing, etc.)";
    };

    importOnActivation = mkOption {
      type = types.bool;
      default = false;
      description = "Auto-import on home-manager activation (OVERWRITES local!)";
    };

    apps = mapAttrs (name: profile: {
      enable = mkEnableOption "Sync ${profile.name}";
    } // (mapAttrs (flag: _: mkOption {
      type = types.bool;
      default = false;
      description = "Include ${flag}";
    }) (profile.conditionalFiles or {}))) appProfiles;
  };

  config = mkIf cfg.enable {
    home.packages = [ syncScript ];

    home.activation.settingsSyncInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$(eval echo "${cfg.syncDir}")"
    '';

    home.activation.settingsSyncImport = mkIf cfg.importOnActivation (
      lib.hm.dag.entryAfter [ "settingsSyncInit" ] ''
        ${syncScript}/bin/settings-sync import all --force || true
      ''
    );
  };
}
