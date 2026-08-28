# workbookpro - Work laptop configuration
# Host-specific settings that differ from common.nix
{
  pkgs,
  ...
}:
{
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

    # kanata removed 2026-08 — mise owns it everywhere (brew:kanata +
    # setup:kanata task; workbookpro is fully mise-managed anyway)
  ];

  # Work-specific system settings can go here
}
