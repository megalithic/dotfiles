# Ghostty

Ghostty is the primary terminal. mise owns it on megabookpro: the app comes from `brew-cask:ghostty@tip` and behavior lives in raw config at `mise/config/ghostty/`, linked to `~/.config/ghostty` via mise `[dotfiles]`.

The HM module (`home/common/programs/ghostty/`) and the `config/ghostty` twin were removed in the 2026-08 GUI dedupe wave. The twins had diverged only on `font-size` (mise 14 vs twin 15); the newer mise value survived.

## Raw config, no module

Behavior settings stay in the raw config file so comments and live edits survive without rebuilds.

macOS Ghostty supports the XDG path, so `~/.config/ghostty/config` is the only config location — the old duplicate `~/Library/Application Support/com.mitchellh.ghostty/config` link stays intentionally absent.

Ghostty handles fish shell integration itself; no shell module sources Ghostty integration files. Ghostty uses native `maximize = true` instead of oversized explicit window dimensions, and the animated boo cursor shader is disabled by default. Cursor shaders ship alongside the config in `mise/config/ghostty/shaders/`.

## Bell-driven Pi notifications

`bell-features = title,attention,border` and `working-directory = ~/.dotfiles` are set in the raw config. Pi's notification path emits BEL so Ghostty triggers its configured title, attention, and border bell effects when a session needs attention.
