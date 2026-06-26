{
  config,
  lib,
  pkgs,
  ...
}:
let
  fishFiles =
    dir: prefix:
    lib.mapAttrs' (name: _: lib.nameValuePair "fish/${prefix}/${name}" { source = dir + "/${name}"; }) (
      lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".fish" name) (builtins.readDir dir)
    );
in
{
  programs.fish = {
    enable = true;
    package = pkgs.fish;

    interactiveShellInit = builtins.readFile ./config.fish;

    plugins = import ./plugins.nix { inherit pkgs; };
  };

  xdg.configFile =
    fishFiles ./conf.d "conf.d"
    // fishFiles ./functions "functions"
    // fishFiles ./interactive "interactive";

  xdg.dataFile."fish/nix.fish".text = ''
    set -l per_user_profile "/etc/profiles/per-user/${config.home.username}/bin"
    test -d "$per_user_profile"; and fish_add_path --prepend "$per_user_profile"

    test -d "$HOME/.nix-profile/bin"; and fish_add_path --prepend "$HOME/.nix-profile/bin"
  '';
}
