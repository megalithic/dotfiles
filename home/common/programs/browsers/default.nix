# Browser configurations
# - chromium.nix: Chromium-based browsers (Brave, Helium)
# - firefox.nix: Firefox-based browsers (placeholder)
{
  imports = [
    ./mkChromiumBrowser.nix
    ./brave-browser-nightly.nix
    ./firefox.nix
    ./helium.nix
  ];
}
