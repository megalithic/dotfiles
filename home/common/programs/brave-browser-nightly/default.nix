{
  config,
  pkgs,
  self,
  ...
}: let
  # Convert {id, version, sha256} → {id, version, crxPath} for mkChromiumBrowser
  mkExtension = {id, version, sha256}: {
    inherit id version;
    crxPath = pkgs.fetchurl {
      url = "https://clients2.google.com/service/update2/crx?response=redirect&acceptformat=crx3&prodversion=120.0.0.0&x=id%3D${id}%26installsource%3Dondemand%26uc";
      inherit sha256;
      name = "${id}-${version}.crx";
    };
  };
  extensions = map mkExtension [
    { id = "gfbliohnnapiefjpjlpjnehglfpaknnc"; version = "1.17.11";
      sha256 = "sha256-ITHfwWSqRxSwk2ignuHq5Bnl3H8abikOaBqmv/3/xn0="; }
    { id = "egpjdkipkomnmjhjmdamaniclmdlobbo"; version = "0.2.16";
      sha256 = "sha256-QFQjBG7fOyj7rRNSby7enwCIhjXqyRPpm+AwqBM9sv4="; }
    { id = "gmdfnfcigbfkmghbjeelmbkbiglbmbpe"; version = "0.6.3";
      sha256 = "1jdm92arkrsj8l0g03g66ml86inn75i91bcxxajdg87s25lls9f4"; }
    { id = "cdglnehniifkbagbbombnjghhcihifij"; version = "1.2.2.5";
      sha256 = "sha256-weiUUUiZeeIlz/k/d9VDSKNwcQtmAahwSIHt7Frwh7E="; }
    { id = "dpaefegpjhgeplnkomgbcmmlffkijbgp"; version = "1.0.1";
      sha256 = "sha256-BnnCPisSxlhTSoQQeZg06Re8MhgwztRKmET9D93ghiw="; }
    { id = "cfcmijalplpjkfihjkdjdkckkglehgcf"; version = "1.4";
      sha256 = "14wg8bcjbwvr9mmp4rhhfk8hnbaibclav2gqjnfi5lx78dppaic4"; }
  ];
in {
  imports = ["${self}/lib/builders/mkChromiumBrowser.nix"];

  programs.brave-browser-nightly = {
    enable = true;
    package = pkgs.brave-browser-nightly;
    bundleId = "com.brave.Browser.nightly";
    applicationSupportDir = "BraveSoftware/Brave-Browser-Nightly";
    appName = "Brave Browser Nightly.app";
    executableName = "Brave Browser Nightly";
    iconFile = "app.icns";
    dictionaries = [pkgs.hunspellDictsChromium.en_US];
    inherit extensions;
    commandLineArgs = [
      "--remote-debugging-port=9222"
      "--ignore-gpu-blocklist"
      "--no-first-run"
      "--no-default-browser-check"
      "--hide-crashed-bubble"
      "--disable-breakpad"
      "--disable-wake-on-wifi"
      "--no-pings"
      "--disable-features=OutdatedBuildDetector"
      "--disk-cache=${config.home.homeDirectory}/Library/Caches/brave-browser-nightly"
    ];

    keyEquivalents = {
      "Close Tab" = "^w";
      "New Tab" = "^t";
      "Select Previous Tab" = "^h";
      "Select Next Tab" = "^l";
      "Reload This Page" = "^r";
      "Reopen Closed Tab" = "^$t";
      "Reset zoom" = "^0";
      "Zoom In" = "^=";
      "Zoom Out" = "^-";
      "New Private Window" = "^$n";
    };

    darwinWrapperApp = {
      enable = true;
      name = "Brave Browser Nightly";
      bundleId = "com.nix.brave-browser-nightly";
    };
  };
}
