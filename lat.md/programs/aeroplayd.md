# AeroPlay

`AeroPlay.app` is a SwiftUI menubar app that routes one selected app's audio only to one AirPlay or local CoreAudio output.

Sources live in `lib/aeroplayd.swift` (capture and routing), `lib/aeroplayd-cli.swift` (argument parsing and app listing), `lib/aeroplayd-idle.swift` (idle-timeout config and tracking), and `lib/aeroplayd-ui.swift` (discovery and UI). The signed executable is named `aeroplayd`.

## Routing model

AeroPlay captures the selected app through a private CoreAudio process tap. The tap uses `.muted`, so that app plays only through the selected route while other apps keep their normal output.

The selected PID is translated into CoreAudio process objects and passed to `CATapDescription(stereoMixdownOfProcesses:)`.

The source match includes the selected PID, CoreAudio process objects whose bundle ID equals the selected app's bundle ID or begins with `<bundle-id>.` (common Chromium and Helium helpers), and process objects whose responsible process is the selected PID via `responsibility_get_pid_responsible_for_pid`. Responsible-process matching covers WKWebView apps such as Kaset, whose audio renders in `com.apple.WebKit.GPU` XPC services with ppid 1 and Apple bundle IDs.

The tap feeds a private aggregate device with drift compensation. A preallocated single-producer/single-consumer ring separates the CoreAudio input callback from the selected sender. The callback performs no allocation or locking. Ring metrics report captured frames, output frames, underruns, overruns, and signal level.

The menubar route stops after 60 seconds without meaningful source audio by default. Each input callback whose peak exceeds `0.0001` resets a worker-thread deadline for both AirPlay and local routes. Timeout sets the existing route-local Stop signal, so normal teardown disconnects only the current stream and leaves AeroPlay, its source selection, and its destination selection available. `~/.config/aeroplayd/config.json`, mise-symlinked from `config/aeroplayd/config.json`, overrides the positive finite `idle_audio_timeout_seconds` value; AeroPlay rereads it on every Start. Missing or invalid config uses 60 seconds.

## Destinations

Routes target either a discovered AirPlay receiver or an alive local CoreAudio output device.

### AirPlay

`NetServiceBrowser` discovers `_raop._tcp.` services in `local.` and distinguishes them by `(name, type, domain)`.

The UI shows the service name after `@`, resolves the current host and port, tracks TXT updates, rejects stale callbacks, and stops an active route when the service disappears.

AirPlay uses a patched arm64 build of `philippe44/libraop`'s `cliraop` helper at revision `4fe461a809eadd5230e3b587a3b3c948f90d9617`. `lib/build-swift` checks out that revision and its recorded submodules, applies `config/aeroplayd/cliraop-control.patch`, verifies the patched source hash, and builds with Xcode's arm64 toolchain. The cache key includes the build recipe, revision, patch, and toolchain hashes. The app invokes ALAC mode:

```text
cliraop -a -p PORT -v VOLUME -c CONTROL_FIFO -t 0,1 -m 0,1,2 HOST -
```

AeroPlay converts the tap's non-interleaved stereo Float32 stream to interleaved stereo 16-bit PCM at 44.1 kHz before writing helper stdin. Both ends use nonblocking I/O, so the helper continues reading volume commands while the source is silent. AeroPlay ignores `SIGPIPE`, checks Stop and helper liveness, and fails after five seconds without PCM write progress. A mode-0600 FIFO in a mode-0700 temporary directory carries one-byte volume percentages; the helper calls libraop's `raopcl_set_volume`, which sends an RTSP `SET_PARAMETER` request on the active session. Teardown closes both pipes, reaps the helper, and removes the FIFO directory.

AirConnect's first RTSP connect after idle can time out while its UPnP pipeline to the Sonos wakes, so a helper that exits within ten seconds of launch is reaped through the normal `stopHelper` path and relaunched once (status `Retrying connection`) before the route fails.

### CoreAudio and Bluetooth

The local destination list includes alive CoreAudio devices with a UID, positive sample rate, output streams, and at least one output channel. Bluetooth and Bluetooth LE transports receive a `Bluetooth` label.

Local routing uses `AVAudioSourceNode` and `AVAudioEngine`. AeroPlay sets `kAudioOutputUnitProperty_CurrentDevice` before engine start, lets AVAudioEngine convert linear PCM to the device format, and applies route gain in the app's mixer without changing hardware volume. The route stops when the device disappears or the engine reports a later configuration change.

## Menubar behavior

The popover provides source and destination pickers, route status, live metrics, volume, Start, Stop, and Quit. Source and destination controls stay disabled until route cleanup finishes.

Two compact buttons labeled `Kaset → Office+` and `Helium → Office+` quick-route either app to the `Office+` AirPlay destination. Each button stays disabled unless its app is running, `Office+` is resolved, and no route or cleanup is active.

The app activates when it opens the transient popover. The popover closes when AeroPlay resigns active status, including keyboard-driven app switches. A global mouse-down monitor also closes it after outside clicks without consuming the click. Every close path removes the monitor, and a presentation generation prevents a queued event from closing a newly reopened popover.

While a route is active, the single variable-length status item draws the source app icon immediately left of the AeroPlay symbol. It returns to the AeroPlay symbol when the route ends or AeroPlay quits.

The volume slider stays active during routing and writes a shared atomic percent. Local routes apply it to the engine mixer on the next monitor tick without changing device hardware volume. AirPlay routes pass the Start-time volume through `cliraop -v`, then send changes through the control FIFO so the receiver changes its destination volume without restarting the stream. AirPlay audio samples remain unscaled, which avoids software amplification and clipping. CLI routes ignore the atomic and keep `--volume`.

Live metrics cover level, sent duration, peak, underruns, and overruns. `NSWorkspace.shared.notificationCenter` app-launch and app-termination notifications refresh source PIDs, and every popover open refreshes both the source list and local devices, so a relaunched app reappears with its new PID; each Start validates the current PID and bundle ID again.

Source and destination rows share a fixed-width label column and equal-width pickers.

Stop, source exit, destination removal, helper failure, device failure, Quit, `SIGINT`, and `SIGTERM` all reach the same cleanup path. Teardown stops callbacks before releasing their storage, destroys the IOProc, aggregate device, and process tap, then closes and reaps the AirPlay helper. Quit waits asynchronously for cleanup through `applicationShouldTerminate`.

## CLI diagnostics

The app bundle executable also supports bounded diagnostics:

```text
aeroplayd --list-apps
aeroplayd --capture-pid PID --seconds N --output PATH
aeroplayd --route-pid PID --seconds N --host HOST --port PORT --helper PATH [--volume 0...100]
aeroplayd --route-pid PID --seconds N --device-uid UID [--volume 0...100]
```

Route arguments require exactly one destination shape. PIDs must be positive; AirPlay ports must be in `1...65535`. Bounded CLI routes use only `--seconds`; the menubar idle-audio timeout does not change CLI diagnostics.

## Build and deployment

`lib/build-swift aeroplayd` builds and verifies the signed app before atomically installing it at `~/Applications/AeroPlay.app`.

The build verifies that the patched `cliraop` is arm64, exposes the control-FIFO option, and links no user, Homebrew, or Nix libraries. It then packages and signs the helper, signs the outer bundle with Developer ID team `3ZJ3F5RFBZ`, and verifies both signatures. The bundle ID is `com.megadots.aeroplayd`; no ad-hoc fallback exists.

The non-sandboxed `LSUIElement` bundle declares `NSAudioCaptureUsageDescription`, `_raop._tcp` in `NSBonjourServices`, and `NSLocalNetworkUsageDescription`. macOS prompts for system-audio and local-network access when first needed.

Mise task `setup:aeroplayd` tracks the build script, all four Swift sources, the cliraop control patch, and the libraop license. LaunchAgent `dev.mise.com.megadots.aeroplayd` runs `~/Applications/AeroPlay.app/Contents/MacOS/aeroplayd` at login with `keep_alive = false`, so Quit lasts until the next login or explicit service start. `bin/smoke-test-macos.sh` verifies the app and nested helper signatures, bundle and team identifiers, hardened runtime, menubar and audio-capture metadata, config symlink, and LaunchAgent executable path.

## Verification

Controlled AirPlay, local-device, and stalled-helper tests verified the route paths and deterministic cleanup.

The AirPlay run captured 287,232 frames at 48 kHz and sent 263,879 frames at 44.1 kHz over 5.984 seconds with peak `0.0375`, zero overruns, no helper leak, and no AirConnect restart. Nobody was near Office+ to confirm audible Sonos output, so that listening check remains manual.

A non-audible local route through `Splashtop Remote Sound` captured 163,328 frames and delivered 154,924 frames with zero underruns, zero overruns, and no process leak. A fake helper that stopped reading stdin failed with `helper pipe made no progress` and left no child process.
