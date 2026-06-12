# Shared home-manager configuration for all hosts
# Host-specific overrides go in home/<hostname>.nix
{
  config,
  pkgs,
  lib,
  inputs,
  username,
  version,
  paths,
  ...
}:
let
  programEntries = builtins.readDir ./programs;
  programModules = builtins.filter (
    name:
    programEntries.${name} == "directory"
    && builtins.pathExists ./programs/${name}/default.nix
    # worktrunk depends on an optional flake input.
    && (name != "worktrunk" || inputs ? worktrunk)
  ) (builtins.attrNames programEntries);
  programImports = map (name: ./programs/${name}) programModules;
in
{
  imports = [
    ./lib.nix
    ./modules/settings-sync.nix
    ./packages.nix
    ./services.nix
  ]
  ++ programImports;

  home.username = username;
  home.homeDirectory = paths.home;
  home.stateVersion = version;
  home.sessionPath = [
    paths.localBin
    paths.bin
    "${paths.dotfiles}/bin"
    "${paths.cargoHome}/bin"
  ];

  home.sessionVariables = {
    XDG_DATA_DIRS = "${config.home.profileDirectory}/share:${"\${GHOSTTY_SHELL_INTEGRATION_XDG_DIR:+\$GHOSTTY_SHELL_INTEGRATION_XDG_DIR:}"}$XDG_DATA_DIRS";

    # Make Nix-provided pkg-config files visible to builds
    PKG_CONFIG_PATH = "${config.home.profileDirectory}/lib/pkgconfig:${config.home.profileDirectory}/share/pkgconfig";
  };

  home.file = {
    # Note: ~/Applications is managed by macOS with special permissions - don't use home.file for it
    "code/.keep".text = "";
    "src/.keep".text = "";
    "tmp/.keep".text = "";
    "_screenshots/.keep".text = "";
    ".hushlogin".text = "";
    "bin".source = config.lib.mega.linkBin;
    ".editorconfig".text = ''
      root = true
      [*]
      indent_style = space
      indent_size = 2
      end_of_line = lf
      insert_final_newline = true
      trim_trailing_whitespace=true
      charset = utf-8
    '';
    "iclouddrive".source =
      config.lib.file.mkOutOfStoreSymlink "${paths.home}/Library/Mobile Documents/com~apple~CloudDocs";
  }
  //
    lib.optionalAttrs
      (builtins.pathExists "${paths.home}/Library/CloudStorage/ProtonDrive-seth@megalithic.io-folder")
      {
        "protondrive".source =
          config.lib.file.mkOutOfStoreSymlink "${paths.home}/Library/CloudStorage/ProtonDrive-seth@megalithic.io-folder";
      };

  home.preferXdgDirectories = true;

  home.activation.linkSystemApplications = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    lib.mega.mkAppActivation {
      inherit pkgs;
      packages = config.mega.customApps;
    }
  );

  xdg.enable = true;

  fonts = {
    fontconfig.enable = true;
  };

  programs.home-manager.enable = true;

  # use copyApps for GUI apps (works with Spotlight)
  targets.darwin.linkApps.enable = false;
  targets.darwin.copyApps.enable = true;
}
