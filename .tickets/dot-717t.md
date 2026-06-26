---
id: dot-717t
status: open
deps: []
links: []
created: 2026-06-26T21:03:08Z
type: feature
priority: 1
assignee: Seth Messer
tags: [media-presence, swift, hammerspoon, meetings]
---

# Finish media-presence meeting/AV watcher (Swift daemon)

Continue tools/media-presenced (Swift daemon). Working vertical slice already committed (093a6662a): capture layer (mic owner via CoreAudio process objects, camera via CoreMediaIO) + CDP Google Meet detection (lobby/joined/sharing/participants, event-driven, debounced) + Unix-socket JSON events with get/focus commands. See lat.md/programs/media-presence and tools/media-presenced/README.md. Resume by asking to 'start back on the media watcher swift binary'.

## Design

Daemon must run as its own LaunchAgent with its own TCC identity so screen/automation prompts attribute to it, not the terminal host (Ghostty re-prompt problem). CDP is authority for Meet (TCC/replayd logs unreliable for already-granted apps). Avoid CGWindowList/System Events window-title reads (trigger Screen Recording prompts). Helium launched with --remote-debugging-port=9223. Build needs Xcode SDK forced over nix SDKROOT.

## Acceptance Criteria

1. nix package (pkgs/media-presenced.nix) building the Swift binary, wired into home-manager. 2. LaunchAgent runs it at login with its own Screen Recording/Automation TCC grant (no terminal re-prompts). 3. Hammerspoon consumer: connect to the Unix socket, dispatch events to ptt mute, music pause, DND/focus on screenshare.start/stop, and Slack status; replace watchers/camera.lua heuristics. 4. Repoint hyper+z (bindings.lua loadMeeting) to send {cmd:focus} to the daemon instead of window-size guessing. 5. Slack huddle resolver (capture signals + window/AX), validated live. 6. Native Zoom/Teams resolver. 7. Camera owner attribution (not just on/off). 8. Live-validate meeting.left, screenshare stop, and lobby->joined transitions end to end. 9. lat.md/programs/media-presence updated; lat check passes.

## Notes

**2026-06-26T21:04:58Z**

mise-bootstrap-migration notes (for the mise worktree): the daemon and its launch must be dotfiles-agnostic, so plan the non-nix path now.

- CDP flag portability: --remote-debugging-port=9223 is currently injected via nix (fish helium function + helium-browser commandLineArgs + mkChromiumBrowser wrapper). Under mise there is no nix wrapper, so provide a portable launcher (wrapper script or .app shim using 'open -a Helium --args --remote-debugging-port=9223', or a login launcher) that does not edit the Helium bundle (preserve codesign/Widevine/1Password/TCC). Daemon already capability-detects CDP and degrades if the port is absent.
- Build: the Xcode-SDK-forced 'swift build' (env -u SDKROOT DEVELOPER_DIR=... SDKROOT=<Xcode SDK>) is a NIX-only workaround because the nix apple-sdk shadows Xcode via SDKROOT. Under mise (no nix SDKROOT), plain 'swift build -c release' with the Xcode toolchain should just work. Add a mise task (or Makefile) for build + ad-hoc codesign + install to keep it reproducible without nix.
- LaunchAgent: under nix it is home-manager launchd. Under mise, install a plain ~/Library/LaunchAgents plist (RunAtLoad/KeepAlive) via a mise task or bootstrap script, pointing at the installed binary/.app. The agent (not a terminal child) must own the Screen Recording/Automation TCC grant.
- Config: keep a plain config file (socket path, cdp port, browser bundle/path) read at runtime, NOT nix-interpolated, so the same daemon works under nix or mise.
- Packaging parity: ship both paths from one source tree (tools/media-presenced) - pkgs/media-presenced.nix for nix, and a mise task + plist for mise - so the migration is a swap of install mechanism, not a rewrite.
