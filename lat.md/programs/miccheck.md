# miccheck

`bin/miccheck.swift` is a menubar push-to-talk / push-to-mute app (a local MicDrop-style tool) that replaced the Hammerspoon `miccheck.lua` module; Hammerspoon only sends it mode commands over a Unix socket.

## Keybinding behavior

Hold cmd+opt to activate the chord: unmute in push-to-talk mode, mute in push-to-mute mode. cmd+opt+p toggles the mode.

The chord starts only on an exact cmd+opt (no shift/ctrl) and arms a 500ms debounce; any keyDown other than `p` during the debounce cancels activation so chords like cmd+opt+space never trip the mic. Once active, adding shift keeps the mic hot — this lets a Handy.app transcription chord (cmd+opt+shift) run while the mic stays open. Releasing cmd or opt (or adding ctrl) ends the chord. cmd+opt+p is a Carbon `RegisterEventHotKey` (swallowed system-wide); the chord itself uses a listen-only CGEvent tap on flagsChanged+keyDown, which requires an Input Monitoring TCC grant.

`CGEvent.tapCreate` succeeds even without the grant but then silently delivers zero events, so startup tries the tap directly — `CGPreflightListenEventAccess()` is known to return stale false even after the TCC grant exists (Daniel Raffel 2026-02, Standlock production probe pattern). If the tap creation fails, we request access and retry every 5s until it succeeds.

## Mute semantics

Muted state mutes **all** input devices; live state unmutes only the default input device (whatever CoreAudio reports as `kAudioHardwarePropertyDefaultInputDevice` — nothing is hardcoded).

On startup, `AudioController.start()` logs the current default (`default input: <name> (id <id>)`). CoreAudio listeners re-apply the desired state when the default input changes, when devices hot-plug, and when another app flips a device's mute property behind the app's back (50ms debounced). Devices without a mute property fall back to zeroing input volume and restoring the saved value on unmute. On quit (menu Quit, SIGTERM, or socket `quit`) every input is unmuted so nothing stays hardware-muted.

### Input volume floor

While the mic is live on the default device, `AudioController` pushes every `kAudioDevicePropertyVolumeScalar` element (main, 1, 2) below 0.55 up to that floor.

Some USB mics drift to an inaudible input volume on their own (the Samson GoMic routinely sits at ~17% with no user action); a low scalar leaves the mic technically unmuted but captured almost silently, which broke Handy.app transcription. Scalars at or above the floor are left alone, so the floor never overrides a louder manual setting. The floor re-applies on every state refresh (device change, hot-plug, mute-flip-behind-back, chord transitions), so drift back low is re-boosted automatically. The floor only touches the default device — other inputs stay muted and untouched. CoreAudio quantizes scalar step, so the effective value is the nearest discrete step above 0.55 (e.g. 0.5625 on the GoMic).

## Menubar

Same iconography as the old Lua module: white slashed mic (template) when muted, white mic on a `#c43e1f` rounded pill when the mic is hot; the menu picks the mode and quits.

The persisted mode lives in `UserDefaults` (`~/Library/Preferences/miccheckd.plist`, key `mode`).

## Presence integration

miccheckd subscribes directly to [[media-presence#Socket protocol|media-presenced's socket]]: any `inMeeting` transition forces push-to-talk mode so meetings never start with a hot mic.

This moved PTT enforcement out of Hammerspoon's `watchers/media-presence.lua`, which now keeps only music pause and DND. On launch, miccheck first does a synchronous `{"cmd":"get"}` probe before its first `apply()`, so a restart during an already-live meeting cannot briefly restore saved push-to-mute hot-mic state. The client then subscribes normally, reconnects every 5s, and also forces push-to-talk on the first seeded snapshot when `inMeeting=true`; this covers miccheck/media-presenced reconnects while a meeting or Athena pre-join lobby is already open. An idle first snapshot is still ignored, so miccheck does not rewrite the user's mode outside meetings. `--presence-socket PATH` overrides the path, `--no-presence` disables the subscription. Hammerspoon interop is unchanged — both daemons stay controllable over their sockets (`lib/micctl.lua` for miccheck, `nc -w 1 -U` for media-presenced).

## Socket protocol

The Unix socket (`~/.local/state/miccheck/sock`) accepts line-delimited JSON commands with one-line replies.

Commands: `{"cmd":"get"}` → `{"ok":true,"mode":...,"live":...}`; `{"cmd":"set-mode","mode":"push-to-talk"|"push-to-mute"}`; `{"cmd":"toggle-mode"}`; `{"cmd":"quit"}`. Hammerspoon's client is `config/hammerspoon/lib/micctl.lua` (`setPTTMode`, `toggleMode`) using the same `nc -w 1 -U` pattern as [[media-presence#Hammerspoon consumer]]; callers are `watchers/camera.lua`, `watchers/media-presence.lua`, and `contexts/co.detail.mac.lua`.

## Build and packaging

Unlike [[media-presence#Build and packaging|media-presenced]], miccheck is compiled: `bin/miccheck-build` runs `swiftc` on `bin/miccheck.swift` and installs a signed binary at `~/.local/bin/miccheckd`.

Signing uses a Developer ID Application identity (auto-detected; override with `MICCHECK_CODESIGN_IDENTITY`) with the fixed identifier `com.megadots.miccheck` and hardened runtime. TCC pins grants to the designated requirement (identifier + cert + team), so Input Monitoring survives rebuilds. Without an identity the script falls back to ad-hoc signing, where every rebuild changes the code hash and the stale TCC row must be **removed** (not toggled) in System Settings before a fresh prompt can fire. The build script unsets nix `SDKROOT`/`DEVELOPER_DIR` and resolves the SDK via `/usr/bin/xcrun` because the nix apple-sdk mismatches the system Swift toolchain.

Both config systems run the same wrapper `bin/miccheck-launchd`, which exits with a helpful error when the binary is missing:

- nix: `home/common/programs/miccheck/default.nix` LaunchAgent (`org.nix-community.home.miccheck`)
- mise: `_mise.toml` agent `com.megadots.miccheck` plus task `setup:miccheck` (runs `bin/miccheck-build`)
