# 1Password — nix-darwin SYSTEM module
#
# `programs._1password` / `programs._1password-gui` are nix-darwin (and NixOS)
# system options; they do NOT exist in home-manager. See mrjones2014/dotfiles
# (a 1Password engineer) for the same pattern on nix-darwin.
#
# - programs._1password: installs the `op` CLI to /usr/local/bin/op (the path
#   the GUI expects for CLI integration).
# - programs._1password-gui: rsyncs pkgs._1password-gui to /Applications/1Password.app
#   (read-only). Installing into /Applications satisfies 1Password 8's anti-tamper
#   check (it quits when run from anywhere else, e.g. ~/Applications or the nix store).
#
# This fully replaces the Homebrew 1password + 1password-cli casks: both the GUI
# bundle (incl. op-ssh-sign used for git/jj commit signing) and the op CLI come
# from nixpkgs, installed to the locations macOS/1Password require.
_: {
  programs._1password.enable = true;
  programs._1password-gui.enable = true;
}
