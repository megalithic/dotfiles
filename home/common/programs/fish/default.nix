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

      # Set TMUX_SESSION and PLUG_EDITOR when in tmux
      # Enables clickable stacktraces in Phoenix dev error pages
      if set -q TMUX
          set -gx TMUX_SESSION (tmux display-message -p '#S')
          set -gx PLUG_EDITOR "hammerspoon://nvim-open?file=__FILE__&line=__LINE__&session=$TMUX_SESSION"
      end

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
