# Browser configurations
# - chromium.nix: Chromium-based browsers (Brave, Helium)
# - firefox.nix: Firefox-based browsers (placeholder)
{
  imports = [
    ./chromium.nix
    ./firefox.nix
  ];
}
