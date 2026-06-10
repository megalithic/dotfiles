{ lib, ... }:
let
  # Homebrew can fail during activation if an installed formula came from a tap
  # that is no longer configured in nix-homebrew. Remove retired formulae before
  # nix-darwin runs brew bundle/upgrade so deleted taps do not break rebuilds.
  retiredBrews = [
    "omlx"
  ];
  retiredBrewCleanup = lib.concatMapStringsSep "\n" (formula: ''
    if /opt/homebrew/bin/brew list --formula ${lib.escapeShellArg formula} >/dev/null 2>&1; then
      echo "homebrew: uninstalling retired formula ${formula}"
      /opt/homebrew/bin/brew services stop ${lib.escapeShellArg formula} >/dev/null 2>&1 || true
      /opt/homebrew/bin/brew uninstall --formula --force ${lib.escapeShellArg formula} || true
    fi
  '') retiredBrews;
in
{
  environment.systemPath = [ "/opt/homebrew/bin" ];

  system.activationScripts.preActivation.text = lib.mkBefore ''
    if [ -x /opt/homebrew/bin/brew ]; then
    ${retiredBrewCleanup}
    fi
  '';

  homebrew = {
    enable = true;
    casks = [
      "hammerspoon"
      "raycast"
      "okta-verify"
      "1password"
      "1password-cli"
      "protonvpn"
    ];
    masApps = {
      "Xcode" = 497799835;
      # "Things3" = 904280696;
      # "Fantastical" = 975937182;
      # "Fantastical" = 435003921;  # Not available via mas CLI (subscription app with restricted API access)
    };
    onActivation = {
      cleanup = "zap";
      upgrade = true;
    };
  };
}
