{mkApp}:

mkApp {
  pname = "brave-browser-nightly";
  version = "1.89.41.0";
  appName = "Brave Browser Nightly.app";
  src = {
    url = "https://updates-cdn.bravesoftware.com/sparkle/Brave-Browser/nightly-arm64/189.41/Brave-Browser-Nightly-arm64.dmg";
    sha256 = "15aq7bsr12xbrnfq40siij2fcxxcg4br0fbg1qjvplpnpd1fkh8r";
  };
  appLocation = "wrapper";
  desc = "Privacy-focused web browser - Nightly build";
  homepage = "https://brave.com/download-nightly/";
}
