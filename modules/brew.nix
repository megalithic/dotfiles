{
  environment.systemPath = ["/opt/homebrew/bin"];
  homebrew = {
    enable = true;
    # Note: `caskArgs.no_quarantine = true` was removed — Homebrew disabled the
    # `--no-quarantine` switch with no replacement. Casks now go through normal
    # quarantine; first launch may prompt. brew-nix-managed casks bypass
    # quarantine entirely (installed from /nix/store).
    brews = [
      # whisperkit-cli moved to nix derivation: pkgs/cli/whisperkit-cli.nix
      "jundot/omlx/omlx" # Apple Silicon native LLM inference server (oMLX)
    ];
    # Casks migrated to brew-nix overlay (pkgs.brewCasks.*) — see
    # home/common/programs/gui-apps.nix. Keeping list here as documentation
    # of which apps moved:
    #   1password, 1password-cli, colorsnapper, contexts, hammerspoon,
    #   homerow, kitty, mouseless, okta-verify, protonvpn, proton-drive,
    #   obs@beta, yubico-authenticator, visual-studio-code, zed
    casks = [
      # Raycast serves a zlib-wrapped DMG that brew-nix's 7zz unpack can't
      # handle. Keep on homebrew until upstream fixes the wrapping.
      "raycast"
      # Okta Verify ships a .pkg with URL-encoded paths that brew-nix's
      # cpio/gzip pipeline can't extract. Keep on homebrew.
      "okta-verify"
      # 1Password's anti-tamper / signature checks reject /nix/store copies,
      # so install via real homebrew (writes to /Applications/ normally).
      "1password"
      "1password-cli"
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
