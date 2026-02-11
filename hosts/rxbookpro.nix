# rxbookpro - Work laptop configuration
# Host-specific settings that differ from common.nix
{
  pkgs,
  lib,
  paths,
  ...
}: {
  # Work laptop specific packages
  environment.systemPackages = with pkgs; [
    # Rust toolchain
    rustc
    cargo
    clippy
    rustfmt
    rust-analyzer

    # CLI tools
    bat
    delta
    dust
    eza
    fd
    jq
    just
    jujutsu
    mise
    nvim-nightly
    openssl
    ripgrep
    starship
    yazi
    zoxide
  ];

  # Work-specific system settings can go here
}
