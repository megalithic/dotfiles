# Native PKG Installer Module
#
# Handles apps that require native macOS PKG installers to function properly.
# These are apps with system extensions, strict code signing, or other requirements
# that prevent extraction-based installation.
#
# Usage:
#   services.native-pkg-installer = {
#     enable = true;
#     packages = [ karabiner-elements-pkg ];  # Packages built with mkApp { installMethod = "native"; }
#   };
#
# Or let it auto-discover from environment.systemPackages:
#   services.native-pkg-installer.enable = true;
#   # Will find all packages with passthru.isNativeInstaller = true
{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.native-pkg-installer;

  # Find packages with isNativeInstaller passthru attribute
  # from either explicit list or system packages
  findNativePackages = packages:
    builtins.filter (
      pkg:
        pkg
        ? passthru
        && pkg.passthru
        ? isNativeInstaller
        && pkg.passthru.isNativeInstaller
    )
    packages;

  # Get packages to install - either explicit list or auto-discovered
  packagesToInstall =
    if cfg.packages != []
    then findNativePackages cfg.packages
    else findNativePackages config.environment.systemPackages;

  # Generate activation script for a single package
  mkInstallScript = pkg: ''
    echo "[native-pkg-installer] Processing ${pkg.pname}..."
    ${pkg.passthru.installScript}
  '';

  # Combined installation script for all packages
  installAllScript =
    if packagesToInstall == []
    then ''
      echo "[native-pkg-installer] No native packages to install"
    ''
    else lib.concatMapStringsSep "\n\n" mkInstallScript packagesToInstall;
in {
  options.services.native-pkg-installer = {
    enable = mkEnableOption "Native PKG installer for macOS apps requiring system-level installation";

    packages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = ''
        List of packages built with mkApp { installMethod = "native"; }.
        If empty, will auto-discover from environment.systemPackages.
      '';
    };

    runOnActivation = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to run native installers during darwin-rebuild activation.
        Set to false to only generate install scripts without running them.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Run native installers during system activation
    system.activationScripts.preActivation.text = mkIf cfg.runOnActivation ''
      echo "[native-pkg-installer] Checking native package installations..."
      ${installAllScript}
    '';

    # Provide a convenience script for manual installation/debugging
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "nix-native-pkg-install" ''
        set -e
        echo "Running native package installers..."
        ${installAllScript}
        echo "Done."
      '')
    ];

    # Log which packages are managed by this module
    # warnings =
    #   if packagesToInstall != []
    #   then [
    #     ''
    #       native-pkg-installer is managing ${toString (length packagesToInstall)} package(s):
    #       ${lib.concatMapStringsSep ", " (pkg: pkg.pname) packagesToInstall}
    #
    #       These apps are installed via native macOS PKG installers during activation.
    #       They live in /Applications (not nix store) and may require manual approval
    #       in System Settings > Privacy & Security for system extensions.
    #     ''
    #   ]
    #   else [];
  };
}
