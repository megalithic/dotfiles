{
  config,
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  aliases = import ./aliases.nix { inherit pkgs isDarwin; };
  abbr = import ./abbr.nix;
  functions = import ./functions.nix {
    inherit isDarwin;
    wtBin = "${pkgs.worktrunk}/bin/wt";
  };
  plugins = import ./plugins.nix { inherit pkgs; };
  completions = import ./completions.nix { wtBin = "${pkgs.worktrunk}/bin/wt"; };
  keybindings = import ./keybindings.nix;
  theme = import ./theme.nix;
  ghosttyFishIntegration = "${pkgs.ghostty-bin}/Applications/Ghostty.app/Contents/Resources/ghostty/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish";
in
{
  programs.fish = {
    enable = true;
    package = pkgs.fish;

    shellInit = ''
      # put Nix profile *first* on my PATH
      export PATH="/etc/profiles/per-user/${config.home.username}/bin:$PATH"
      set -g fish_prompt_pwd_dir_length 20

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

      # Ghostty's own env can point at a deleted local dev build. Source only
      # existing integration files, with the Nix package as fallback.
      if set -q GHOSTTY_RESOURCES_DIR
          set -l ghostty_fish_integration "$GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish"
          if test -f "$ghostty_fish_integration"
              source "$ghostty_fish_integration"
          else if test -f "${ghosttyFishIntegration}"
              source "${ghosttyFishIntegration}"
          end
      end
    '';

    inherit functions;
    shellAliases = aliases;
    shellAbbrs = abbr;
    inherit plugins;
  };
}
