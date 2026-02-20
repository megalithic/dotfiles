# Create macOS Finder aliases for home-manager managed apps
#
# Home-manager puts apps in ~/Applications/Home Manager Apps/
# This activation script creates Finder aliases in ~/Applications/Nix/
# so Spotlight, Launchpad, and Dock all work properly.
#
# Works with:
#   - nixpkgs GUI apps (discord, slack, iina, etc.)
#   - Custom mkApp derivations (fantastical, bloom, brave, etc.)
#   - programs.* that install .app bundles (ghostty, etc.)
#
{
  config,
  lib,
  pkgs,
  self,
  ...
}: let
  createMacOSAlias = "${pkgs.callPackage (
    { stdenv }:
    stdenv.mkDerivation {
      name = "create-macos-alias";
      src = "${self}/scripts/create-macos-alias.swift";
      unpackPhase = "true";
      dontConfigure = true;
      dontBuild = true;
      installPhase = ''
        install -D -m755 $src $out/bin/create-macos-alias
      '';
      meta = {
        description = "Create macOS Finder aliases programmatically";
        license = lib.licenses.mit;
        platforms = lib.platforms.darwin;
      };
    }
  ) {}}/bin/create-macos-alias";

  aliasDir = "${config.home.homeDirectory}/Applications/Nix";
  hmAppsDir = "${config.home.homeDirectory}/Applications/Home Manager Apps";
in {
  # Create Finder aliases after home-manager copies apps
  home.activation.createAppAliases = lib.hm.dag.entryAfter ["copyApps"] ''
    aliasDir="${aliasDir}"
    hmAppsDir="${hmAppsDir}"

    if [ -d "$hmAppsDir" ]; then
      echo "Creating Finder aliases in $aliasDir..."
      mkdir -p "$aliasDir"

      # Clean stale aliases (apps that were removed)
      if [ -d "$aliasDir" ]; then
        for alias in "$aliasDir"/*.app; do
          [ -e "$alias" ] || continue
          appname="$(basename "$alias")"
          if [ ! -e "$hmAppsDir/$appname" ]; then
            echo "  Removing stale alias: $appname"
            rm -f "$alias"
          fi
        done
      fi

      # Create/update aliases for all apps
      for app in "$hmAppsDir"/*.app; do
        [ -e "$app" ] || continue
        appname="$(basename "$app")"
        dest="$aliasDir/$appname"

        # Resolve symlink to actual nix store path
        if [ -L "$app" ]; then
          src="$(/usr/bin/stat -f%Y "$app")"
        else
          src="$app"
        fi

        # Recreate alias if source changed or doesn't exist
        if [ -f "$dest" ]; then
          rm -f "$dest"
        fi
        ${createMacOSAlias} "$src" "$dest"
      done

      echo "Finder aliases updated in $aliasDir"
    fi
  '';
}
