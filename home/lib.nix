# Home-manager library extensions
# Provides helper functions for common patterns in home configs
#
# Usage in other modules:
#   xdg.configFile."hammerspoon".source = config.lib.mega.linkConfig "hammerspoon";
#   xdg.configFile."nvim".source = config.lib.mega.linkConfig "nvim";
#
{config, ...}: {
  config.lib.mega = {
    # Base path to the dotfiles repo
    dotfilesPath = "${config.home.homeDirectory}/.dotfiles-nix";

    # Link to files in config/ directory (out-of-store configs like hammerspoon, tmux, kitty)
    # Usage: config.lib.mega.linkConfig "hammerspoon"
    # Result: symlink to ~/.dotfiles-nix/config/hammerspoon
    linkConfig = path:
      config.lib.file.mkOutOfStoreSymlink "${config.lib.mega.dotfilesPath}/config/${path}";

    # Link to files in home/ directory (nix-managed configs like nvim)
    # Usage: config.lib.mega.linkHome "nvim"
    # Result: symlink to ~/.dotfiles-nix/home/nvim
    linkHome = path:
      config.lib.file.mkOutOfStoreSymlink "${config.lib.mega.dotfilesPath}/home/${path}";

    # Link to bin/ directory
    # Usage: config.lib.mega.linkBin
    # Result: symlink to ~/.dotfiles-nix/bin
    linkBin = config.lib.file.mkOutOfStoreSymlink "${config.lib.mega.dotfilesPath}/bin";

    # Generic link to any path within dotfiles repo
    # Usage: config.lib.mega.linkDotfile "some/nested/path"
    # Result: symlink to ~/.dotfiles-nix/some/nested/path
    linkDotfile = path:
      config.lib.file.mkOutOfStoreSymlink "${config.lib.mega.dotfilesPath}/${path}";
  };
}
