{
  pkgs,
  lib ? pkgs.lib,
  ...
}: appAttrs: let
  # Convert attrset of "App Name" = id to a list for processing
  appList = lib.attrsets.mapAttrsToList (name: id: {inherit name id;}) appAttrs;

  # Generate the installation script
  installScript = pkgs.writeShellScript "install-mas-apps" ''
    set -euo pipefail

    # Colors for output
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color

    echo -e "''${BLUE}📦 Installing Mac App Store applications...''${NC}"

    # Check if signed into App Store by trying to list purchased apps
    # Note: 'mas account' doesn't work on macOS 12+ due to Apple's API changes
    if ! ${pkgs.mas}/bin/mas list &>/dev/null; then
      echo -e "''${RED}❌ Unable to access Mac App Store. Please ensure you're signed in.''${NC}"
      echo -e "''${YELLOW}ℹ''${NC}  Open App Store.app and sign in, then try again."
      exit 1
    fi

    # Get list of installed apps once for efficiency
    INSTALLED_APPS=$(${pkgs.mas}/bin/mas list)

    ${lib.concatMapStringsSep "\n" (app: ''
      # Check if app is already installed
      # rg: -q = quiet, regex matches start of line with app ID
      if echo "$INSTALLED_APPS" | ${pkgs.ripgrep}/bin/rg -q "^${toString app.id} "; then
        echo -e "''${GREEN}✓''${NC} ${app.name} (${toString app.id}) - already installed"
      else
        echo -e "''${BLUE}→''${NC} Installing ${app.name} (${toString app.id})..."

        # Try installing by ID first
        # Note: mas install returns 0 even on failure, so we need to check output
        INSTALL_OUTPUT=$(${pkgs.mas}/bin/mas install ${toString app.id} 2>&1)

        # rg: -q = quiet, regex matches Warning or Error
        if echo "$INSTALL_OUTPUT" | ${pkgs.ripgrep}/bin/rg -q "(Warning|Error):"; then
          # Installation failed, check if we can find it by name
          echo -e "''${YELLOW}⚠''${NC}  Failed to install by ID ${toString app.id}, searching by name..."

          SEARCH_RESULT=$(${pkgs.mas}/bin/mas search "${app.name}" 2>/dev/null | head -1 || echo "")

          if [ -n "$SEARCH_RESULT" ]; then
            FOUND_ID=$(echo "$SEARCH_RESULT" | awk '{print $1}')
            FOUND_NAME=$(echo "$SEARCH_RESULT" | sed 's/^[0-9]\+[[:space:]]\+//' | sed 's/[[:space:]]\+([^)]\+)$//')

            echo -e "''${YELLOW}ℹ''${NC}  Found '${app.name}' as: $FOUND_NAME (ID: $FOUND_ID)"
            echo -e "''${BLUE}→''${NC} Attempting install with ID $FOUND_ID..."

            INSTALL_OUTPUT2=$(${pkgs.mas}/bin/mas install "$FOUND_ID" 2>&1)
            if ! echo "$INSTALL_OUTPUT2" | ${pkgs.ripgrep}/bin/rg -q "(Warning|Error):"; then
              echo -e "''${GREEN}✓''${NC} Installed $FOUND_NAME ($FOUND_ID)"
              echo -e "''${YELLOW}⚠''${NC}  Note: Original ID ${toString app.id} was incorrect. Use ID $FOUND_ID instead."
            else
              echo -e "''${RED}❌''${NC} Failed to install ${app.name}"
              echo -e "''${YELLOW}ℹ''${NC}  Error: $INSTALL_OUTPUT2"
              echo -e "''${YELLOW}ℹ''${NC}  This might mean the app hasn't been 'purchased' (downloaded) before."
              echo -e "''${YELLOW}ℹ''${NC}  Try: mas purchase $FOUND_ID"
            fi
          else
            echo -e "''${RED}❌''${NC} Could not find '${app.name}' in App Store"
            echo -e "''${YELLOW}ℹ''${NC}  Error: $INSTALL_OUTPUT"
            echo -e "''${YELLOW}ℹ''${NC}  Search manually with: mas search \"${app.name}\""
          fi
        else
          echo -e "''${GREEN}✓''${NC} Installed ${app.name} (${toString app.id})"
        fi
      fi
    '') appList}

    echo -e "''${GREEN}✓ Mac App Store installation complete''${NC}"
  '';
in {
  script = installScript;

  # Provide activation command for darwin-rebuild
  activationScript = ''
    echo "Installing Mac App Store applications..."
    ${installScript}
  '';
}
