{
  environment.systemPath = ["/opt/homebrew/bin"];
  homebrew = {
    enable = true;
    brews = [];

    # Remove quarantine attribute from casks so they don't prompt on first launch
    caskArgs.no_quarantine = true;
    # taps = [];
    casks = [
      "1password"
      "1password-cli"
      # "brave-browser@nightly"
      "colorsnapper"
      "contexts"
      "discord"
      # FIXME: create derivation to pull the 3.x.x archive from their website
      # "fantastical"
      "figma"
      "ghostty@tip"
      "hammerspoon"
      "homerow"
      "iina"
      "inkscape"
      "jordanbaird-ice"
      "karabiner-elements"
      "kitty"
      "macwhisper"
      "microsoft-teams"
      "mouseless"
      "protonvpn"
      "proton-drive"
      "obs@beta"
      "orcaslicer"
      "raycast"
      "slack"
      "spotify"
      # "thingsmacsandboxhelper"
      "vial"
      "yubico-authenticator"
      "visual-studio-code"
      "zed"
    ];
    masApps = {
      "Xcode" = 497799835;
      # "Fantastical" = 975937182;
      # "Fantastical" = 435003921;  # Not available via mas CLI (subscription app with restricted API access)
      # "Things" = 904280696;
    };
    onActivation = {
      cleanup = "zap";
      upgrade = true;
    };
  };
}
