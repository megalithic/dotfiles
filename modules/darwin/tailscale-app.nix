# Tailscale macOS GUI app — nix-darwin SYSTEM module
#
# The official Tailscale app cask is a .pkg that installs the GUI app,
# system/network extension support, login item helpers, and /usr/local/bin/tailscale.
# Do not install it through mkApp/brewCasks: extracting the package would skip the
# installer behavior macOS expects for the network extension.
#
# Updating: bump version/hash to match the current Homebrew cask:
#   https://raw.githubusercontent.com/Homebrew/homebrew-cask/HEAD/Casks/t/tailscale-app.rb
{ pkgs, ... }:
let
  version = "1.98.10";

  tailscalePkg = pkgs.fetchurl {
    url = "https://pkgs.tailscale.com/stable/Tailscale-${version}-macos.pkg";
    sha256 = "c2eaf5f660ad45a64d1ba43ee72401029a5cb06e6d148c5e90a987a6f546bc58";
  };
in
{
  system.activationScripts.postActivation.text = ''
    # Tailscale: run Apple's installer (root) so the GUI app and network
    # extension support are installed the same way as the official cask/pkg.
    TS_WANT="${version}"
    TS_HAVE="$(/usr/sbin/pkgutil --pkg-info com.tailscale.ipn.macsys 2>/dev/null | /usr/bin/awk '/^version:/ {print $2}')"
    if [ "$TS_HAVE" != "$TS_WANT" ]; then
      echo "tailscale-app: installing $TS_WANT (was: $TS_HAVE)..."
      /usr/sbin/installer -pkg ${tailscalePkg} -target / || \
        echo "tailscale-app: installer failed (non-fatal, continuing activation)"
    else
      echo "tailscale-app: $TS_WANT already installed, skipping"
    fi
  '';
}
