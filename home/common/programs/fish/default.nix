{
  config,
  pkgs,
  username,
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
    package = pkgs.unstable.fish;

    shellInit = ''
      # put Nix profile *first* on my PATH
      export PATH="/etc/profiles/per-user/${config.home.username}/bin:$PATH"
      set -g fish_prompt_pwd_dir_length 20

      # OP_SESSION restore is set in home/common/programs/1password

      # PLUG_EDITOR for clickable stacktraces (Phoenix dev / browser devtools).
      # Always set — Hammerspoon resolves target nvim instance dynamically at
      # click time (file-already-open > active tmux client > most-recent socket).
      # No session param: server-startup-time session is the wrong signal.
      set -gx PLUG_EDITOR "hammerspoon://nvim-open?file=__FILE__&line=__LINE__"

      # Capture tmux session name (consumed by other tools)
      if set -q TMUX
          set -gx TMUX_SESSION (tmux display-message -p '#S')
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
