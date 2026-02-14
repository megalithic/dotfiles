# mkMacOSAlias - Create macOS Finder aliases for nix-managed apps
#
# Unlike symlinks, Finder aliases are:
#   - Indexed by Spotlight (⌘ Space → app name)
#   - Visible in Launchpad
#   - Pinnable to the Dock (persists across nix updates)
#   - Treated as real apps by Finder
#
# Based on mhanberg's approach:
# https://github.com/mhanberg/.dotfiles/blob/main/nix/darwin/link-apps/
#
# Usage in nix-darwin config:
#   services.mac-aliases = {
#     enable = true;
#     userName = "seth";
#     userHome = "/Users/seth";
#   };
#
{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.mac-aliases;

  createMacOSAlias = "${pkgs.callPackage (
    { stdenv }:
    stdenv.mkDerivation {
      name = "create-macos-alias";
      src = ./create-macos-alias.swift;
      unpackPhase = "true";
      dontConfigure = true;
      dontBuild = true;
      installPhase = ''
        install -D -m755 $src $out/bin/create-macos-alias
      '';
      meta = {
        description = "Create macOS Finder aliases programmatically";
        license = licenses.mit;
        platforms = platforms.darwin;
      };
    }
  ) {}}/bin/create-macos-alias";
in
{
  options.services.mac-aliases = {
    enable = mkEnableOption "Create Finder aliases (not symlinks) for nix-managed apps";

    userName = mkOption {
      type = types.str;
      description = "Username for setting ownership on alias directory";
    };

    userHome = mkOption {
      type = types.path;
      description = "User home directory path";
    };

    dest = mkOption {
      type = types.path;
      default = "${cfg.userHome}/Applications/Nix";
      description = "Directory where Finder aliases will be created";
    };
  };

  config = mkIf cfg.enable {
    system.activationScripts.postActivation.text = ''
      echo "Creating Finder aliases in ${cfg.dest}..."
      mkdir -p "${cfg.dest}"
      chown ${cfg.userName} "${cfg.dest}"

      # Alias apps from nix-darwin system applications
      if [ -d "${config.system.build.applications}/Applications" ]; then
        /usr/bin/find "${config.system.build.applications}/Applications" -maxdepth 1 -type l | while read -r f; do
          src="$(/usr/bin/stat -f%Y "$f")"
          appname="$(basename "$src")"
          dest="${cfg.dest}/$appname"
          [ -f "$dest" ] && rm "$dest"
          ${createMacOSAlias} "$src" "$dest"
        done
      fi

      echo "Finder aliases updated in ${cfg.dest}"
    '';
  };
}
