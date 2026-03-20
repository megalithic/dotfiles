# Browser configurations
# - chromium.nix: Chromium-based browsers (Brave, Helium)
# - firefox.nix: Firefox-based browsers (placeholder)
{
  imports = [
    ./brave-browser-nightly.nix
    ./firefox.nix
  ];
}
