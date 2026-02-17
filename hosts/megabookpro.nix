# megabookpro - Personal laptop configuration
# Host-specific settings that differ from common.nix
{
  pkgs,
  lib,
  paths,
  ...
}: {
  # Host-specific system packages
  # Most tools should go to home-manager (home/common/packages.nix)
  # Only keep here what needs system-wide access or is needed before HM runs
  environment.systemPackages = with pkgs; [
    # Rust toolchain - keep system-wide for cargo install workflows
    rustc
    cargo
    clippy
    rustfmt
    rust-analyzer

    # Google Cloud SDK for Vertex AI / Gemini access
    google-cloud-sdk

    # kanata - keyboard remapping daemon (needs system access)
    kanata
  ];

  # Personal laptop specific settings can go here
}
