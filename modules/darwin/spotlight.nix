# Spotlight exclusion management
#
# Excludes directories matching patterns from Spotlight indexing.
# Patterns come from a gitignore-style file and/or an explicit nix list.
# Exclusions are applied via `mdutil -i off` on matching paths under scanPaths.
#
# Usage (common.nix or hosts/<hostname>.nix):
#   spotlight.exclusions.paths = [ "node_modules" ".devenv" "_build" "deps" ];
#   spotlight.exclusions.fromFile = ./path/to/gitignore;
#   spotlight.exclusions.scanPaths = [ "/Users/seth/code" ];
#
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.spotlight.exclusions;

  # Parse a gitignore-style file into a list of directory name patterns.
  # Strips comments, blank lines, negations, and file-glob patterns.
  # Keeps simple directory names (no wildcards, no dots-only entries).
  patternsFromFile =
    file:
    if file == null then
      [ ]
    else
      let
        lines = lib.splitString "\n" (builtins.readFile file);
        # Remove comments, blank lines, negations, and leading/trailing slashes/globs
        clean =
          line:
          let
            trimmed = lib.trim line;
            stripped = lib.removePrefix "**/" (lib.removePrefix "/" (lib.removeSuffix "/" trimmed));
          in
          stripped;
        isUsable =
          line:
          let
            trimmed = lib.trim line;
          in
          trimmed != ""
          && !(lib.hasPrefix "#" trimmed)
          && !(lib.hasPrefix "!" trimmed)
          && !(lib.hasPrefix "*" (lib.trim line))
          && !(lib.hasPrefix "[" (lib.trim line))
          && !(lib.hasPrefix "." (clean line) && builtins.stringLength (clean line) <= 2)
          && !lib.hasInfix "*" (clean line);
      in
      map clean (lib.filter isUsable lines);

  allPatterns = lib.unique (cfg.paths ++ (patternsFromFile cfg.fromFile));

  # Build the find + mdutil script
  excludeScript = pkgs.writeShellScript "spotlight-exclude" ''
    set -euo pipefail

    PATTERNS=(${lib.concatMapStringsSep " " (p: ''"${p}"'') allPatterns})
    SCAN_PATHS=(${lib.concatMapStringsSep " " (p: ''"${p}"'') cfg.scanPaths})

    if [ ''${#PATTERNS[@]} -eq 0 ] || [ ''${#SCAN_PATHS[@]} -eq 0 ]; then
      echo "spotlight-exclude: nothing to do"
      exit 0
    fi

    # Build -name args for find
    FIND_ARGS=()
    first=true
    for pat in "''${PATTERNS[@]}"; do
      if [ "$first" = true ]; then
        first=false
      else
        FIND_ARGS+=("-o")
      fi
      FIND_ARGS+=("-name" "$pat")
    done

    echo "spotlight-exclude: scanning ''${SCAN_PATHS[*]} for ''${#PATTERNS[@]} patterns..."

    count=0
    while IFS= read -r dir; do
      # Place .metadata_never_index to prevent Spotlight from indexing
      if [ ! -f "$dir/.metadata_never_index" ]; then
        touch "$dir/.metadata_never_index"
        count=$((count + 1))
      fi
    done < <(find "''${SCAN_PATHS[@]}" -maxdepth ${toString cfg.maxDepth} -type d \( "''${FIND_ARGS[@]}" \) 2>/dev/null || true)

    echo "spotlight-exclude: marked $count new directories"
  '';
in
{
  options.spotlight.exclusions = {
    enable = lib.mkEnableOption "Spotlight directory exclusions";

    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Directory names to exclude from Spotlight indexing.";
      example = [
        "node_modules"
        ".devenv"
        "_build"
        "deps"
        ".direnv"
      ];
    };

    fromFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Gitignore-style file to parse for additional directory exclusion patterns.";
      example = lib.literalExpression "./home/common/programs/git/gitignore";
    };

    scanPaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Root paths to scan for directories matching exclusion patterns.";
      example = [ "/Users/seth/code" ];
    };

    maxDepth = lib.mkOption {
      type = lib.types.int;
      default = 6;
      description = "Maximum directory depth to scan.";
    };

    interval = lib.mkOption {
      type = lib.types.int;
      default = 3600;
      description = "How often to re-scan (in seconds). Default: hourly.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Run once on activation (darwin-rebuild switch)
    system.activationScripts.postActivation.text = ''
      echo "spotlight-exclude: applying exclusions..."
      ${excludeScript}
    '';

    # Periodic re-scan via launchd
    launchd.daemons.spotlight-exclude = {
      serviceConfig = {
        Label = "org.nix.spotlight-exclude";
        ProgramArguments = [ "${excludeScript}" ];
        StartInterval = cfg.interval;
        StandardOutPath = "/var/log/spotlight-exclude.log";
        StandardErrorPath = "/var/log/spotlight-exclude.log";
      };
    };
  };
}
