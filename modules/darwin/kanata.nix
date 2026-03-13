# Kanata keyboard remapper configuration for macOS
# Uses kanata-darwin module for system integration (Karabiner driver, launchd, etc.)
# Keyboard config files live in config/kanata/
{
  config,
  lib,
  pkgs,
  inputs,
  self,
  username,
  ...
}: {
  services.kanata = {
    enable = true;
    # NOTE: configSource intentionally NOT set - we manage the symlink dynamically
    # via Hammerspoon dock watcher to switch between macbook.kbd and macbook-disabled.kbd
    # based on whether external keyboard (Leeloo) is connected
    sudoers = false; # kanata-bar handles privilege escalation via TouchID

    kanata-bar = {
      enable = true;
      settings = {
        kanata.pam_tid = "auto";
        kanata_bar.autorestart_kanata = true;
        kanata_bar.autostart_kanata = true;
      };
      icons = inputs.kanata-darwin.lib.mkLayerIcons pkgs {
        font = pkgs.nerd-fonts.jetbrains-mono;
        labels = {
          default = "U+F0B34"; # nf-md-format_letter_case (Aa)
          nav = "U+F062"; # nf-fa-arrow_up (navigation layer)
        };
      };
    };
  };

  # Allow passwordless kanata kill for Hammerspoon dock watcher
  # This enables automatic config switching when external keyboard connects/disconnects
  environment.etc."sudoers.d/kanata-kill".text = ''
    ${username} ALL=(root) NOPASSWD: /usr/bin/pkill -x kanata
  '';
}
