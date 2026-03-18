{
  environment.systemPath = ["/opt/homebrew/bin"];
  homebrew = {
    enable = true;
    # Remove quarantine attribute from casks so they don't prompt on first launch
    caskArgs.no_quarantine = true;
    brews = [
      "whisperkit-cli" # Apple Silicon native speech recognition
    ];
    casks = [
      "1password"
      "1password-cli"
      "colorsnapper"
      "contexts"
      # "figma"
      "hammerspoon"
      "homerow"
      # "karabiner-elements"
      "kitty"
      # "microsoft-teams"
      "mouseless"
      "protonvpn"
      "proton-drive"
      "obs@beta"
      # "raycast"
      # "spotify"
      # "thingsmacsandboxhelper"
      # "vial"
      "yubico-authenticator"
      "visual-studio-code"
      "zed"
    ];
    masApps = {
      "Xcode" = 497799835;
      "Things3" = 904280696;
      # "Fantastical" = 975937182;
      # "Fantastical" = 435003921;  # Not available via mas CLI (subscription app with restricted API access)
    };
    onActivation = {
      cleanup = "zap";
      upgrade = true;
    };
  };
}
