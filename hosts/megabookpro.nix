# megabookpro - Personal laptop configuration
# Host-specific settings that differ from common.nix
{
  pkgs,
  lib,
  paths,
  ...
}: {
  # Host-specific packages (in addition to common.nix system packages)
  # These are packages that shouldn't go to home-manager because:
  # - They need system-wide access
  # - They're needed before HM runs
  # - They're darwin-specific CLI tools
  environment.systemPackages = with pkgs; [
    # Rust toolchain
    rustc
    cargo
    clippy
    rustfmt
    rust-analyzer

    # CLI tools that work better system-wide
    bat
    delta
    dust
    eza
    fd
    jq
    just
    jujutsu
    ldns
    libwebp
    mise
    netcat
    nmap
    nvim-nightly
    openssl
    ripgrep
    starship
    yazi
    yq
    zoxide
    inetutils
    kanata

    # Google Cloud SDK for Vertex AI / Gemini access
    google-cloud-sdk
  ];

  # Personal laptop specific settings can go here
  # Example: different power settings, personal services, etc.
}
