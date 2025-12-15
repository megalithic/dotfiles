# Karabiner-Elements - Keyboard customizer for macOS
#
# This app requires native PKG installation because:
#   - Uses DriverKit system extension for virtual HID device
#   - Code signatures must be validated against original paths
#   - PKG postinstall scripts handle privileged operations
#
# Built with mkApp { installMethod = "native"; }
{
  pkgs,
  lib,
}: let
  version = "15.7.0";
in
  lib.mega.mkApp {inherit pkgs lib;} {
    pname = "karabiner-elements";
    inherit version;

    src = {
      url = "https://github.com/pqrs-org/Karabiner-Elements/releases/download/v${version}/Karabiner-Elements-${version}.dmg";
      sha256 = "1bhmv8adwsxraffcczqx36378cg8zw815wb8yzipvbv43kij8bak";
    };

    installMethod = "native";
    pkgName = "Karabiner-Elements.pkg";
    appName = "Karabiner-Elements.app";

    desc = "Keyboard customizer for macOS";
    homepage = "https://karabiner-elements.pqrs.org/";

    # Activate the system extension after installation
    postNativeInstall = ''
      echo "[karabiner] Checking system extension status..."
      # rg: -i = case insensitive
      SYSEXT_STATUS=$(systemextensionsctl list 2>/dev/null | ${pkgs.ripgrep}/bin/rg -i "org.pqrs.Karabiner-DriverKit-VirtualHIDDevice" || true)

      # rg: -q = quiet (exit status only)
      if echo "$SYSEXT_STATUS" | ${pkgs.ripgrep}/bin/rg -q "activated enabled"; then
        echo "[karabiner] System extension already activated"
      else
        echo "[karabiner] Activating system extension..."
        if [ -x "/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager" ]; then
          timeout 5 "/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager" activate 2>/dev/null || true
        fi
        echo "[karabiner] NOTE: You may need to approve in System Settings > Privacy & Security"
      fi
    '';

    # Custom uninstall script using official uninstallers
    uninstallScript = ''
      set -e
      echo "[karabiner] Uninstalling Karabiner-Elements..."

      # Run official uninstall scripts if they exist
      if [ -x "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/scripts/uninstall/remove_files.sh" ]; then
        "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/scripts/uninstall/remove_files.sh"
      fi

      if [ -x "/Library/Application Support/org.pqrs/Karabiner-Elements/uninstall_core.sh" ]; then
        "/Library/Application Support/org.pqrs/Karabiner-Elements/uninstall_core.sh"
      fi

      # Remove apps
      rm -rf "/Applications/Karabiner-Elements.app"
      rm -rf "/Applications/Karabiner-EventViewer.app"
      rm -rf "/Applications/.Karabiner-VirtualHIDDevice-Manager.app"

      # Remove support files
      rm -rf "/Library/Application Support/org.pqrs"

      # Remove package receipts
      pkgutil --forget org.pqrs.Karabiner-Elements 2>/dev/null || true
      pkgutil --forget org.pqrs.Karabiner-DriverKit-VirtualHIDDevice 2>/dev/null || true

      # Remove metadata
      rm -rf "/var/lib/nix-native-pkgs/karabiner-elements"

      echo "[karabiner] Uninstall complete"
    '';
  }
