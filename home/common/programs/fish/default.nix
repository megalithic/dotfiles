{
  config,
  pkgs,
  username,
  hostname,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  aliases = import ./aliases.nix {inherit pkgs isDarwin;};
  abbr = import ./abbr.nix;
  functions = import ./functions.nix {inherit config isDarwin;};
  plugins = import ./plugins.nix {inherit pkgs;};
  completions = import ./completions.nix;
  keybindings = import ./keybindings.nix;
  theme = import ./theme.nix;
in {
  programs.fish = {
    enable = true;

    shellInit = ''
      # put Nix profile *first* on my PATH
      export PATH="/etc/profiles/per-user/${config.home.username}/bin:$PATH"
      set -g fish_prompt_pwd_dir_length 20

      ${completions}
    '';

    interactiveShellInit = ''
      ${keybindings}
      ${theme}
    '';

    inherit functions;
    shellAliases = aliases;
    shellAbbrs = abbr;
    inherit plugins;
  };
}
