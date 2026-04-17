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

      # Restore cached 1Password sessions (from `opl`)
      if test -f ~/.local/cache/op/sessions
        while read -l line
          set -l parts (string split -m1 = $line)
          if test (count $parts) -eq 2
            set -gx $parts[1] $parts[2]
          end
        end < ~/.local/cache/op/sessions
      end

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
