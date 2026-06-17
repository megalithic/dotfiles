{ lib, ... }:
# Okta Verify install is handled by the nix-darwin SYSTEM module
# modules/darwin/okta-verify.nix (it runs Apple's installer as root so the
# privileged postinstall that loads LaunchDaemons + SecurityAgentPlugin runs).
# mkApp/brewCasks/mas cannot do this: extract never runs the postinstall, and
# the App Store installer needs interactive auth.
# This home module only sanity-checks presence after `just home`.
{
  home.activation.verifyOktaVerify = lib.hm.dag.entryAfter [ "copyApps" ] ''
    if [ ! -d "/Applications/Okta Verify.app" ]; then
      echo "WARNING: Okta Verify not installed. Run 'just darwin' (modules/darwin/okta-verify.nix)."
    fi
  '';
}
