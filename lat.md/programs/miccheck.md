# miccheck

`bin/miccheck.swift` is a menubar push-to-talk / push-to-mute app (a local MicDrop-style tool) that replaced the Hammerspoon `miccheck.lua` module; Hammerspoon only sends it mode commands over a Unix socket.

## Keybinding behavior

Hold cmd+opt to activate the chord: unmute in push-to-talk mode, mute in push-to-mute mode. cmd+opt+p toggles the mode.

The chord starts only on an exact cmd+opt (no shift/ctrl) and arms a 500ms debounce; any keyDown other than `p` during the debounce cancels activation so chords like cmd+opt+space never trip the mic. Once active, adding shift keeps the mic hot — this lets a Handy.app transcription chord (cmd+opt+shift) run while the mic stays open. Releasing cmd or opt (or adding ctrl) ends the chord. cmd+opt+p is a Carbon `RegisterEventHotKey` (swallowed system-wide); the chord itself uses a listen-only CGEvent tap on flagsChanged+keyDown, which requires an Input Monitoring TCC grant.

## Mute semantics

Muted state mutes **all** input devices; live state unmutes only the default input device.

CoreAudio listeners re-apply the desired state when the default input changes, when devices hot-plug, and when another app flips a device's mute property behind the app's back (50ms debounced). Devices without a mute property fall back to zeroing input volume and restoring the saved value on unmute. On quit (menu Quit, SIGTERM, or socket `quit`) every input is unmuted so nothing stays hardware-muted.

## Menubar

Same iconography as the old Lua module: white slashed mic (template) when muted, white mic on a `#c43e1f` rounded pill when the mic is hot; the menu picks the mode and quits.

The persisted mode lives in `UserDefaults` (`~/Library/Preferences/miccheckd.plist`, key `mode`).

## Socket protocol

The Unix socket (`~/.local/state/miccheck/sock`) accepts line-delimited JSON commands with one-line replies.

Commands: `{"cmd":"get"}` → `{"ok":true,"mode":...,"live":...}`; `{"cmd":"set-mode","mode":"push-to-talk"|"push-to-mute"}`; `{"cmd":"toggle-mode"}`; `{"cmd":"quit"}`. Hammerspoon's client is `config/hammerspoon/lib/micctl.lua` (`setPTTMode`, `toggleMode`) using the same `nc -w 1 -U` pattern as [[media-presence#Hammerspoon consumer]]; callers are `watchers/camera.lua`, `watchers/media-presence.lua`, and `contexts/co.detail.mac.lua`.

## Build and packaging

Unlike [[media-presence#Build and packaging|media-presenced]], miccheck is compiled: `bin/miccheck-build` runs `swiftc` on `bin/miccheck.swift` and installs an ad-hoc-signed binary at `~/.local/bin/miccheckd`.

A stable path + signature keeps the Input Monitoring TCC grant attached to the binary (the kanata pattern); rebuilding changes the code hash, so macOS may require re-approving Input Monitoring afterward. The build script unsets nix `SDKROOT`/`DEVELOPER_DIR` and resolves the SDK via `/usr/bin/xcrun` because the nix apple-sdk mismatches the system Swift toolchain.

Both config systems run the same wrapper `bin/miccheck-launchd`, which exits with a helpful error when the binary is missing:

- nix: `home/common/programs/miccheck/default.nix` LaunchAgent (`org.nix-community.home.miccheck`)
- mise: `_mise.toml` agent `com.megadots.miccheck` plus task `miccheck:setup` (runs `bin/miccheck-build`)
