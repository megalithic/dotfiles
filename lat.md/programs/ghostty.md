# Ghostty

Ghostty is the primary terminal, with behavior kept in a raw config file so comments and live edits survive without rebuilds.

The module is `home/common/programs/ghostty/`; the raw config is `config/ghostty/config`.

## Module vs raw config

The module enables `programs.ghostty`, installs `pkgs.ghostty-bin`, and keeps behavior settings out of `programs.ghostty.settings`.

Home Manager's direct fish integration is disabled because it sources `$GHOSTTY_RESOURCES_DIR` without checking the file exists. Fish sources Ghostty integration from `home/common/programs/fish/default.nix` with a file-exists guard and a `pkgs.ghostty-bin` fallback so stale local Ghostty build paths do not break shell startup.

Behavior lives in raw `config/ghostty/config` instead, exposed through exactly one managed link: `$XDG_CONFIG_HOME/ghostty/config` via `xdg.configFile."ghostty"`. macOS Ghostty supports that path, so the old duplicate `~/Library/Application Support/com.mitchellh.ghostty/config` link is intentionally removed. Ghostty uses native `maximize = true` instead of oversized explicit window dimensions, and the animated boo cursor shader is disabled by default.

## Bell-driven Pi notifications

Bell features and startup cwd belong in the raw config, not top-level `programs.ghostty.*` options.

`bell-features = title,attention,border` and `working-directory = ~/.dotfiles` are set in the raw config. Pi's notification path emits BEL so Ghostty triggers its configured title, attention, and border bell effects when a session needs attention.
