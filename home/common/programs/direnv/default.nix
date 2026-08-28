_: {
  programs.direnv = {
    enable = true;
    # mise's direnv wins PATH; the nix binary here is a deliberate dupe —
    # programs.direnv.package is not nullable and the module provides nix-direnv
    # + direnv.toml, which are worth more than the wasted store copy (2026-08).
    enableZshIntegration = true;
    nix-direnv.enable = true;
    mise.enable = true;
    # direnv.toml is mise-owned: [dotfiles] links ~/.config/direnv/direnv.toml
    # to mise/config/direnv/direnv.toml (same content the config block used to
    # render). Declaring `config` here would collide with that symlink.
  };
}
