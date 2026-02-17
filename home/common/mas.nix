{
  config,
  pkgs,
  lib,
  ...
}: {
  # Mac App Store apps - installed via `mas` CLI during activation
  # To add apps: mas search "App Name" → get ID → add below
  home.activation.installMasApps = lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo "Checking Mac App Store apps..."
    INSTALLED=$(${pkgs.mas}/bin/mas list 2>/dev/null || true)

    # Xcode (497799835)
    if echo "$INSTALLED" | ${pkgs.ripgrep}/bin/rg -q "^497799835 "; then
      echo "✓ Xcode already installed"
    else
      echo "→ Installing Xcode..."
      ${pkgs.mas}/bin/mas install 497799835 || echo "⚠ Failed - install manually from App Store"
    fi

    # Add more apps here:
    # if echo "$INSTALLED" | ${pkgs.ripgrep}/bin/rg -q "^409183694 "; then
    #   echo "✓ Keynote already installed"
    # else
    #   ${pkgs.mas}/bin/mas install 409183694
    # fi
  '';
}
