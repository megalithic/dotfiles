# Kanata keyboard remapper configuration for macOS
# Uses kanata-darwin module for system integration (Karabiner driver, launchd, etc.)
# Keyboard config files live in config/kanata/
#
# Architecture:
#   - daemon mode: runs kanata via sudo launchd (bypasses Input Monitoring)
#   - kanata-bar: runs separately as UI-only (connects to daemon via TCP)
#
# Usage:
#   Logs:    tail -f /tmp/kanata.log /tmp/kanata.err
#   Restart: launchctl kickstart -k gui/$(id -u)/org.kanata.daemon
#   Stop:    launchctl stop org.kanata.daemon
#   Start:   launchctl start org.kanata.daemon
#
# Hammerspoon config switching:
#   The config symlink at ~/.config/kanata/kanata.kbd can be changed by
#   Hammerspoon, then restart the service to apply.
{
  config,
  lib,
  pkgs,
  inputs,
  self,
  username,
  ...
}: let
  kanataConfigDir = "/Users/${username}/.config/kanata";

  # Stable binary path outside the nix store.
  # Each nix rebuild produces a new /nix/store/...-kanata/bin/kanata path.
  # macOS TCC (Input Monitoring) tracks binaries by canonical path (resolved
  # symlinks), so a stable symlink does NOT help — TCC follows it to the
  # nix store path and creates a new entry per rebuild.
  #
  # Strategy: copy the real binary to a stable path. Only re-copy on actual
  # version change so cdhash stays stable across same-version rebuilds and
  # macOS does not re-prompt for Input Monitoring.
  kanataStableBin = "/usr/local/bin/kanata";

  # kanata-bar app for UI feedback (runs separately from daemon)
  kanata-bar-version = "1.1.1";
  kanata-bar-app = pkgs.stdenv.mkDerivation {
    pname = "kanata-bar-app";
    version = kanata-bar-version;
    src = pkgs.fetchurl {
      url = "https://github.com/not-in-stock/kanata-bar/releases/download/v${kanata-bar-version}/kanata-bar.app.zip";
      hash = "sha256-dsfPifT+pOxOE2/UfQzyugwuqSbomKP6D5Deo+wVyew=";
    };
    dontUnpack = true;
    nativeBuildInputs = [ pkgs.unzip ];
    installPhase = ''
      mkdir -p "$out/Applications"
      unzip $src -d "$out/Applications"
    '';
  };

  # SF Symbol icons for menu bar (pre-generated, committed to repo)
  # Icons: base (b.square), nav (n.square), disabled (square.stack.3d.up.slash)
  kanata-bar-icons = "${self}/config/kanata/icons";

  # kanata-bar config for UI-only mode
  kanata-bar-config = pkgs.writeText "kanata-bar-config.toml" ''
    [kanata]
    path = "${config.services.kanata.package}/bin/kanata"
    config = "${kanataConfigDir}/kanata.kbd"
    port = 5829

    [kanata_bar]
    autostart_kanata = false
    autorestart_kanata = false
    icons_dir = "${kanata-bar-icons}"
  '';
in {
  services.kanata = {
    enable = true;
    user = username; # Explicit user for sudoers and paths
    sudoers = true; # Run via sudo NOPASSWD - bypasses Input Monitoring permission

    # Use out-of-store symlink so Hammerspoon can switch configs without rebuild
    # Hammerspoon will manage ~/.config/kanata/kanata.kbd -> macbook.kbd or macbook-disabled.kbd
    configFile = "${kanataConfigDir}/kanata.kbd";

    # Daemon mode: headless launchd service with logs
    daemon = {
      enable = true;
      # kanata-darwin renamed daemon.launchd -> daemon.extraLaunchdConfig in 9bfd469
      extraLaunchdConfig = {
        # Expose TCP port for kanata-bar and Hammerspoon to connect
        ProgramArguments = [
          "/usr/bin/sudo"
          kanataStableBin
          "--cfg"
          config.services.kanata.configFile
          "--nodelay"
          "--port"
          "5829"
        ];
      };
    };
  };

  # Install kanata-bar app to /Applications/Nix Apps
  environment.systemPackages = [ kanata-bar-app ];

  # Ensure config directory and default symlink exist
  # Also set up kanata-bar config for UI-only mode
  system.activationScripts.postActivation.text = lib.mkAfter ''
    # Copy real kanata binary to stable path (Mode 3: only on version change).
    # Symlinks resolve to nix store path → TCC duplicates per rebuild.
    # Same-version rebuilds skip copy → cdhash stable → no re-prompt.
    mkdir -p "$(dirname ${kanataStableBin})"
    KANATA_SRC="${config.services.kanata.package}/bin/kanata"
    KANATA_DST="${kanataStableBin}"
    NEW_VER=$("$KANATA_SRC" --version 2>/dev/null | head -1 || echo "unknown")
    OLD_VER=""
    if [ -f "$KANATA_DST" ] && [ ! -L "$KANATA_DST" ]; then
      OLD_VER=$("$KANATA_DST" --version 2>/dev/null | head -1 || echo "")
    fi
    if [ -L "$KANATA_DST" ] || [ "$NEW_VER" != "$OLD_VER" ]; then
      rm -f "$KANATA_DST"
      cp "$KANATA_SRC" "$KANATA_DST"
      chmod +x "$KANATA_DST"
      echo "kanata: copied binary to $KANATA_DST (was: '$OLD_VER', now: '$NEW_VER')"
    else
      echo "kanata: $KANATA_DST already at $NEW_VER, skipping copy"
    fi

    KANATA_DIR="${kanataConfigDir}"
    mkdir -p "$KANATA_DIR"
    chown ${username}:staff "$KANATA_DIR"

    # Create/fix mutable symlink for Hammerspoon to switch configs
    # If symlink points to nix store (from old home-manager config), recreate it
    # Must be owned by user so Hammerspoon can switch it
    # Use /usr/bin/stat (BSD) not nix stat (GNU) for -f '%Su' format
    if [ -L "$KANATA_DIR/kanata.kbd" ]; then
      TARGET=$(readlink "$KANATA_DIR/kanata.kbd")
      OWNER=$(/usr/bin/stat -f '%Su' "$KANATA_DIR/kanata.kbd")
      if [[ "$TARGET" == /nix/store/* ]] || [[ "$OWNER" != "${username}" ]]; then
        rm -f "$KANATA_DIR/kanata.kbd"
        echo "kanata: removed stale symlink (target=$TARGET, owner=$OWNER)"
      fi
    fi
    if [ ! -e "$KANATA_DIR/kanata.kbd" ]; then
      sudo -u ${username} ln -sf "$KANATA_DIR/macbook.kbd" "$KANATA_DIR/kanata.kbd"
      echo "kanata: created config symlink (owned by ${username})"
    fi

    # Symlink config files to config dir for Hammerspoon to switch between
    ln -sf "${self}/config/kanata/macbook.kbd" "$KANATA_DIR/macbook.kbd"
    ln -sf "${self}/config/kanata/macbook-disabled.kbd" "$KANATA_DIR/macbook-disabled.kbd"

    # Set up kanata-bar config for UI-only mode (connects to daemon via TCP)
    # kanata-bar reads from ~/.config/kanata-bar/ by default
    KANATA_BAR_DIR="/Users/${username}/.config/kanata-bar"
    mkdir -p "$KANATA_BAR_DIR"
    chown ${username}:staff "$KANATA_BAR_DIR"
    cp -f "${kanata-bar-config}" "$KANATA_BAR_DIR/config.toml"
    chown ${username}:staff "$KANATA_BAR_DIR/config.toml"
    echo "kanata-bar: config created at $KANATA_BAR_DIR"

    # Restart kanata daemon (killed in kanata-darwin preActivation)
    # KeepAlive=true doesn't trigger restart after pkill, need explicit kickstart
    USER_UID=$(id -u ${username})
    launchctl kickstart -k "gui/$USER_UID/org.kanata.daemon" 2>/dev/null || true
    echo "kanata: daemon restarted"

    # Restart kanata-bar (KeepAlive=false, needs explicit start)
    sleep 1  # Give kanata time to start TCP listener on port 5829
    launchctl kickstart "gui/$USER_UID/com.kanata-bar.ui" 2>/dev/null || true
    echo "kanata-bar: started"
  '';

  # Launch kanata-bar after rebuild (UI-only, connects to daemon)
  # Config is placed in ~/Library/Application Support/kanata-bar/ (macOS default location)
  # Use /usr/bin/open to launch as proper macOS GUI app (needed for menu bar visibility)
  launchd.user.agents.kanata-bar = {
    serviceConfig = {
      Label = "com.kanata-bar.ui";
      ProgramArguments = [
        "/usr/bin/open"
        "-a"
        "${kanata-bar-app}/Applications/Kanata Bar.app"
      ];
      RunAtLoad = true;
      KeepAlive = false; # Don't restart on crash - UI is optional
    };
  };

  # Allow passwordless kanata kill for Hammerspoon dock watcher
  # This enables automatic config switching when external keyboard connects/disconnects
  environment.etc."sudoers.d/kanata-kill".text = ''
    ${username} ALL=(root) NOPASSWD: /usr/bin/pkill -x kanata
  '';
}
