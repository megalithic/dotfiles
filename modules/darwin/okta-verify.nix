# Okta Verify — nix-darwin SYSTEM module (single-use, bespoke)
#
# Okta Verify is NOT a simple .app: its .pkg runs a privileged (auth="root")
# postinstall that loads LaunchDaemons (com.okta.authentication.service,
# autoupdate.daemon, deviceaccess.servicedaemon), installs a SecurityAgentPlugin
# bundle, and drops /usr/local/bin/AutoUpdateDaemon. mkApp/extract only places
# the .app in the nix store and never runs that postinstall, so device-access
# auth breaks. brewCasks/brew-nix also fail on its pkg pipeline.
#
# Approach: pin the official .pkg in the nix store (fetchurl, sha256 from the
# Homebrew cask), then run Apple's own /usr/sbin/installer during darwin
# activation (root) so the real postinstall executes. Idempotent on the
# com.okta.mobile pkgutil receipt version. No Homebrew, no modules/brew.nix.
#
# Updating: bump version/build/sha256 to match the current cask:
#   curl -fsSL https://raw.githubusercontent.com/Homebrew/homebrew-cask/HEAD/Casks/o/okta-verify.rb
{ pkgs, ... }:
let
  version = "9.63.0";
  build = "6186-0c33212";

  oktaVerifyPkg = pkgs.fetchurl {
    url = "https://okta.okta.com/artifacts/OKTA_VERIFY_MACOS/${version}/OktaVerify-${version}-${build}.pkg";
    sha256 = "0a40d8af3a8cf2eb2a6e0125821b557416f88c2ff59f6fe49c0d7c6318be82ee";
  };
in
{
  system.activationScripts.postActivation.text = ''
    # Okta Verify: run Apple's installer (root) so the privileged postinstall
    # that loads LaunchDaemons + SecurityAgentPlugin actually executes.
    OV_WANT="${version}"
    OV_HAVE="$(/usr/sbin/pkgutil --pkg-info com.okta.mobile 2>/dev/null | /usr/bin/awk '/^version:/ {print $2}')"
    if [ "$OV_HAVE" != "$OV_WANT" ]; then
      echo "okta-verify: installing $OV_WANT (was: $OV_HAVE)..."
      /usr/sbin/installer -pkg ${oktaVerifyPkg} -target / || \
        echo "okta-verify: installer failed (non-fatal, continuing activation)"
    else
      echo "okta-verify: $OV_WANT already installed, skipping"
    fi
  '';
}
