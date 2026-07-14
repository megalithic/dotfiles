// miccheck.swift — menubar push-to-talk / push-to-mute app (Hammerspoon miccheck.lua replacement)
//
// Behavior:
//   - Hold cmd+opt: unmute (push-to-talk mode) or mute (push-to-mute mode).
//     500ms debounce; any other keyDown during the debounce cancels activation
//     so chords like cmd+opt+space never trip the mic. Once active, adding
//     shift keeps the mic hot (plays nice with Handy.app transcription chords).
//   - cmd+opt+p toggles push-to-talk <-> push-to-mute (Carbon hotkey, swallowed).
//   - Mute = mute ALL input devices; unmute = unmute the default input device
//     only. Listeners re-apply state on default-device change, device
//     hot-plug, and when another app flips mute behind our back.
//   - Menubar: white slashed mic when muted, white mic on red pill when hot.
//     Menu picks the mode; Quit unmutes everything and exits.
//   - Subscribes to media-presenced's socket (~/.local/state/media-presence/sock)
//     when available: any inMeeting transition forces push-to-talk mode, so
//     meetings never start with a hot mic. Reconnects every 5s; miccheck works
//     standalone when the presence daemon is absent. Disable with --no-presence.
//   - Unix socket (~/.local/state/miccheck/sock) accepts line-delimited JSON:
//       {"cmd":"get"}                                  -> {"ok":true,"mode":...,"live":...}
//       {"cmd":"set-mode","mode":"push-to-talk"}       -> {"ok":true}
//       {"cmd":"set-mode","mode":"push-to-mute"}       -> {"ok":true}
//       {"cmd":"toggle-mode"}                          -> {"ok":true,"mode":...}
//       {"cmd":"quit"}                                 -> {"ok":true}
//
// Build: bin/miccheck-build (swiftc -> ~/.local/bin/miccheckd, Developer ID
// signed with a stable identifier so TCC grants survive rebuilds).
// Requires Input Monitoring (TCC) for the listen-only CGEvent tap.

import AppKit
import Carbon.HIToolbox
import CoreAudio
import Foundation

// MARK: - Logging

func log(_ msg: String) {
    let ts = ISO8601DateFormatter().string(from: Date())
    print("\(ts) \(msg)")
    fflush(stdout)
}

// MARK: - Mode

enum Mode: String {
    case pushToTalk = "push-to-talk"
    case pushToMute = "push-to-mute"
}

// MARK: - CoreAudio helpers

private func caAddr(_ sel: AudioObjectPropertySelector,
                    _ scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
                    _ element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain) -> AudioObjectPropertyAddress {
    AudioObjectPropertyAddress(mSelector: sel, mScope: scope, mElement: element)
}

private func caObjectList(_ sel: AudioObjectPropertySelector) -> [AudioObjectID] {
    var addr = caAddr(sel)
    var size: UInt32 = 0
    let sys = AudioObjectID(kAudioObjectSystemObject)
    guard AudioObjectGetPropertyDataSize(sys, &addr, 0, nil, &size) == noErr else { return [] }
    let count = Int(size) / MemoryLayout<AudioObjectID>.size
    var ids = [AudioObjectID](repeating: 0, count: count)
    guard AudioObjectGetPropertyData(sys, &addr, 0, nil, &size, &ids) == noErr else { return [] }
    return ids
}

private func caGetUInt32(_ obj: AudioObjectID, _ addr: inout AudioObjectPropertyAddress) -> UInt32? {
    guard AudioObjectHasProperty(obj, &addr) else { return nil }
    var value: UInt32 = 0
    var size = UInt32(MemoryLayout<UInt32>.size)
    guard AudioObjectGetPropertyData(obj, &addr, 0, nil, &size, &value) == noErr else { return nil }
    return value
}

private func caSetUInt32(_ obj: AudioObjectID, _ addr: inout AudioObjectPropertyAddress, _ value: UInt32) -> Bool {
    var settable: DarwinBoolean = false
    guard AudioObjectHasProperty(obj, &addr),
          AudioObjectIsPropertySettable(obj, &addr, &settable) == noErr, settable.boolValue else { return false }
    var v = value
    return AudioObjectSetPropertyData(obj, &addr, 0, nil, UInt32(MemoryLayout<UInt32>.size), &v) == noErr
}

private func caGetFloat32(_ obj: AudioObjectID, _ addr: inout AudioObjectPropertyAddress) -> Float32? {
    guard AudioObjectHasProperty(obj, &addr) else { return nil }
    var value: Float32 = 0
    var size = UInt32(MemoryLayout<Float32>.size)
    guard AudioObjectGetPropertyData(obj, &addr, 0, nil, &size, &value) == noErr else { return nil }
    return value
}

private func caSetFloat32(_ obj: AudioObjectID, _ addr: inout AudioObjectPropertyAddress, _ value: Float32) -> Bool {
    var settable: DarwinBoolean = false
    guard AudioObjectHasProperty(obj, &addr),
          AudioObjectIsPropertySettable(obj, &addr, &settable) == noErr, settable.boolValue else { return false }
    var v = value
    return AudioObjectSetPropertyData(obj, &addr, 0, nil, UInt32(MemoryLayout<Float32>.size), &v) == noErr
}

private func caDeviceName(_ dev: AudioObjectID) -> String {
    var addr = caAddr(AudioObjectPropertySelector(kAudioObjectPropertyName))
    var size: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(dev, &addr, 0, nil, &size) == noErr else { return "device \(dev)" }
    var cf: CFString = "" as CFString
    let st = withUnsafeMutablePointer(to: &cf) { AudioObjectGetPropertyData(dev, &addr, 0, nil, &size, $0) }
    guard st == noErr else { return "device \(dev)" }
    return cf as String
}

// MARK: - AudioController
//
// desiredLive == true  -> default input unmuted, all other inputs muted
// desiredLive == false -> all inputs muted
//
// Listeners re-apply the desired state when the default input changes, the
// device list changes, or another app flips a mute property.

/// Devices whose input volume has drifted low stay inaudible even when
/// unmuted (Samson GoMic routinely sits at ~17% with no user interaction).
/// When the mic goes live on the default input we push every volume scalar
/// below this floor up to it; scalars already at or above are left alone.
private let minLiveVolume: Float32 = 0.55

final class AudioController {
    private let q = DispatchQueue(label: "miccheck.audio")
    private var desiredLive = false
    private var savedVolumes: [AudioObjectID: Float32] = [:]
    private var listenedDevices: Set<AudioObjectID> = []
    private var pendingApply: DispatchWorkItem?

    private lazy var changeBlock: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
        self?.scheduleApply()
    }

    func start() {
        q.sync {
            var defAddr = caAddr(kAudioHardwarePropertyDefaultInputDevice)
            AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &defAddr, q, changeBlock)
            var devsAddr = caAddr(kAudioHardwarePropertyDevices)
            AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &devsAddr, q, changeBlock)
            refreshDeviceListeners()
            if let def = defaultInput() {
                log("default input: \(caDeviceName(def)) (id \(def))")
            } else {
                log("default input: none")
            }
        }
    }

    func setLive(_ live: Bool) {
        q.async { [self] in
            desiredLive = live
            applyDesired()
        }
    }

    /// Unmute everything (used on quit so nothing stays hardware-muted).
    func releaseAll() {
        q.sync { [self] in
            desiredLive = true
            for dev in inputDevices() { setDeviceMuted(dev, false) }
        }
    }

    // MARK: internals (all on q)

    private func scheduleApply() {
        pendingApply?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.refreshDeviceListeners()
            self.applyDesired()
        }
        pendingApply = work
        q.asyncAfter(deadline: .now() + .milliseconds(50), execute: work)
    }

    private func inputDevices() -> [AudioObjectID] {
        caObjectList(kAudioHardwarePropertyDevices).filter { dev in
            var addr = caAddr(kAudioDevicePropertyStreams, kAudioDevicePropertyScopeInput)
            var size: UInt32 = 0
            guard AudioObjectGetPropertyDataSize(dev, &addr, 0, nil, &size) == noErr else { return false }
            return size > 0
        }
    }

    private func defaultInput() -> AudioObjectID? {
        var addr = caAddr(kAudioHardwarePropertyDefaultInputDevice)
        guard let id = caGetUInt32(AudioObjectID(kAudioObjectSystemObject), &addr), id != 0 else { return nil }
        return AudioObjectID(id)
    }

    private func refreshDeviceListeners() {
        for dev in inputDevices() where !listenedDevices.contains(dev) {
            var addr = caAddr(kAudioDevicePropertyMute, kAudioDevicePropertyScopeInput)
            if AudioObjectHasProperty(dev, &addr),
               AudioObjectAddPropertyListenerBlock(dev, &addr, q, changeBlock) == noErr {
                listenedDevices.insert(dev)
            }
        }
    }

    private func applyDesired() {
        let def = defaultInput()
        for dev in inputDevices() {
            let wantMuted = !(desiredLive && dev == def)
            setDeviceMuted(dev, wantMuted)
            // Keep a drifted-low default input audible while live. Only the
            // default device is unmuted while live, so only boost that one;
            // other inputs stay muted and untouched.
            if desiredLive, dev == def {
                ensureMinVolume(dev)
            }
        }
    }

    private func ensureMinVolume(_ dev: AudioObjectID) {
        let elements: [AudioObjectPropertyElement] = [kAudioObjectPropertyElementMain, 1, 2]
        for el in elements {
            var addr = caAddr(kAudioDevicePropertyVolumeScalar, kAudioDevicePropertyScopeInput, el)
            guard let v = caGetFloat32(dev, &addr) else { continue }
            if v < minLiveVolume {
                if caSetFloat32(dev, &addr, minLiveVolume) {
                    log("input volume floor: \(caDeviceName(dev)) ch\(el) \(v) -> \(minLiveVolume)")
                }
            }
        }
    }

    /// Mute via kAudioDevicePropertyMute (main element, then channels 1-2);
    /// falls back to zeroing/restoring input volume for devices without mute.
    private func setDeviceMuted(_ dev: AudioObjectID, _ muted: Bool) {
        var handled = false
        var main = caAddr(kAudioDevicePropertyMute, kAudioDevicePropertyScopeInput)
        if caGetUInt32(dev, &main) != nil {
            if caGetUInt32(dev, &main) == (muted ? 1 : 0) { return }
            handled = caSetUInt32(dev, &main, muted ? 1 : 0)
        }
        if !handled {
            for ch: AudioObjectPropertyElement in [1, 2] {
                var addr = caAddr(kAudioDevicePropertyMute, kAudioDevicePropertyScopeInput, ch)
                if caSetUInt32(dev, &addr, muted ? 1 : 0) { handled = true }
            }
        }
        if !handled {
            setVolumeFallback(dev, muted)
        }
    }

    private func setVolumeFallback(_ dev: AudioObjectID, _ muted: Bool) {
        let elements: [AudioObjectPropertyElement] = [kAudioObjectPropertyElementMain, 1, 2]
        if muted {
            for el in elements {
                var addr = caAddr(kAudioDevicePropertyVolumeScalar, kAudioDevicePropertyScopeInput, el)
                if let vol = caGetFloat32(dev, &addr) {
                    if vol > 0 { savedVolumes[dev] = vol }
                    _ = caSetFloat32(dev, &addr, 0)
                }
            }
        } else {
            let restore = savedVolumes[dev] ?? 1.0
            for el in elements {
                var addr = caAddr(kAudioDevicePropertyVolumeScalar, kAudioDevicePropertyScopeInput, el)
                if caGetFloat32(dev, &addr) != nil {
                    _ = caSetFloat32(dev, &addr, restore)
                }
            }
        }
    }
}

// MARK: - ChordMonitor
//
// Listen-only CGEvent tap on flagsChanged + keyDown. Exact cmd+opt starts a
// 500ms debounce; any keyDown other than "p" cancels it (so cmd+opt+<key>
// chords never activate). Once active, shift may be added without dropping
// the chord; releasing cmd or opt (or adding ctrl) ends it.

final class ChordMonitor {
    var onChordDown: (() -> Void)?
    var onChordUp: (() -> Void)?

    private let debounce: DispatchTimeInterval = .milliseconds(500)
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var pending: DispatchWorkItem?
    private(set) var active = false

    private var requestedAccess = false

    func start() -> Bool {
        // CGPreflightListenEventAccess() is known to return stale false even
        // after the TCC grant exists. Skip it; trust tapCreate as the real
        // permission gate. Standlock's probe pattern: if tapCreate returns
        // a tap, permission is truly granted.
        let mask = (CGEventMask(1) << CGEventType.flagsChanged.rawValue)
            | (CGEventMask(1) << CGEventType.keyDown.rawValue)
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: { _, type, event, refcon in
                let me = Unmanaged<ChordMonitor>.fromOpaque(refcon!).takeUnretainedValue()
                me.handle(type: type, event: event)
                return Unmanaged.passUnretained(event)
            },
            userInfo: refcon
        ) else {
            if !requestedAccess {
                requestedAccess = true
                log("input-monitoring not granted; requesting (approve in System Settings)")
                _ = CGRequestListenEventAccess()
            }
            return false
        }

        self.tap = tap
        let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = src
        CFRunLoopAddSource(CFRunLoopGetMain(), src, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func cancelPending() {
        pending?.cancel()
        pending = nil
    }

    func deactivate() {
        cancelPending()
        active = false
    }

    private func handle(type: CGEventType, event: CGEvent) {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return
        }

        if type == .keyDown {
            guard pending != nil else { return }
            let keycode = event.getIntegerValueField(.keyboardEventKeycode)
            if keycode != 35 /* p */ { cancelPending() }
            return
        }

        guard type == .flagsChanged else { return }
        let flags = event.flags
        let cmd = flags.contains(.maskCommand)
        let alt = flags.contains(.maskAlternate)
        let shift = flags.contains(.maskShift)
        let ctrl = flags.contains(.maskControl)
        let exact = cmd && alt && !shift && !ctrl // starts the chord
        let holdOK = cmd && alt && !ctrl // keeps it (shift allowed for Handy)

        if active {
            if !holdOK {
                active = false
                DispatchQueue.main.async { self.onChordUp?() }
            }
        } else if pending != nil {
            if !exact { cancelPending() }
        } else if exact {
            let work = DispatchWorkItem { [weak self] in
                guard let self else { return }
                self.pending = nil
                self.active = true
                self.onChordDown?()
            }
            pending = work
            DispatchQueue.main.asyncAfter(deadline: .now() + debounce, execute: work)
        }
    }
}

// MARK: - Carbon hotkey (cmd+opt+p, swallowed system-wide)

final class HotKey {
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private let handler: () -> Void

    init(handler: @escaping () -> Void) {
        self.handler = handler
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetEventDispatcherTarget(), { _, _, userData in
            Unmanaged<HotKey>.fromOpaque(userData!).takeUnretainedValue().handler()
            return noErr
        }, 1, &spec, refcon, &handlerRef)
        let hotKeyID = EventHotKeyID(signature: OSType(0x4D43_4B50) /* MCKP */, id: 1)
        RegisterEventHotKey(UInt32(kVK_ANSI_P), UInt32(cmdKey | optionKey), hotKeyID,
                            GetEventDispatcherTarget(), 0, &hotKeyRef)
    }
}

// MARK: - SocketServer (unix-domain, line-delimited JSON; media-presenced pattern)

final class SocketServer {
    private let path: String
    private var listenFD: Int32 = -1
    private var acceptSource: DispatchSourceRead?
    private let q = DispatchQueue(label: "miccheck.socket")
    private var clients: [Int32: DispatchSourceRead] = [:]
    private var buffers: [Int32: Data] = [:]

    var onCommand: ((_ cmd: String, _ reply: @escaping (String) -> Void) -> Void)?

    init(path: String) { self.path = path }

    func start() throws {
        let dir = (path as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        unlink(path)

        listenFD = socket(AF_UNIX, SOCK_STREAM, 0)
        guard listenFD >= 0 else { throw POSIXError(.init(rawValue: errno) ?? .EIO) }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let cap = MemoryLayout.size(ofValue: addr.sun_path)
        let bytes = Array(path.utf8)
        guard bytes.count < cap else { throw POSIXError(.ENAMETOOLONG) }
        withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
            ptr.withMemoryRebound(to: CChar.self, capacity: cap) { dst in
                for i in 0..<bytes.count { dst[i] = CChar(bitPattern: bytes[i]) }
                dst[bytes.count] = 0
            }
        }
        let len = socklen_t(MemoryLayout<sockaddr_un>.size)
        let bound = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(listenFD, $0, len) }
        }
        guard bound == 0 else { throw POSIXError(.init(rawValue: errno) ?? .EIO) }
        guard listen(listenFD, 16) == 0 else { throw POSIXError(.init(rawValue: errno) ?? .EIO) }

        let src = DispatchSource.makeReadSource(fileDescriptor: listenFD, queue: q)
        src.setEventHandler { [weak self] in self?.acceptClient() }
        src.resume()
        acceptSource = src
    }

    private func acceptClient() {
        let fd = Foundation.accept(listenFD, nil, nil)
        guard fd >= 0 else { return }
        let src = DispatchSource.makeReadSource(fileDescriptor: fd, queue: q)
        src.setEventHandler { [weak self] in self?.readClient(fd) }
        src.setCancelHandler { close(fd) }
        clients[fd] = src
        buffers[fd] = Data()
        src.resume()
    }

    private func readClient(_ fd: Int32) {
        var tmp = [UInt8](repeating: 0, count: 4096)
        let n = Foundation.read(fd, &tmp, tmp.count)
        if n <= 0 { dropClient(fd); return }
        buffers[fd, default: Data()].append(contentsOf: tmp[0..<n])
        while let idx = buffers[fd]?.firstIndex(of: 0x0A) {
            let line = buffers[fd]!.subdata(in: buffers[fd]!.startIndex..<idx)
            buffers[fd]!.removeSubrange(buffers[fd]!.startIndex...idx)
            if let cmd = String(data: line, encoding: .utf8)?.trimmingCharacters(in: .whitespaces), !cmd.isEmpty {
                onCommand?(cmd) { [weak self] reply in self?.q.async { self?.writeClient(fd, reply) } }
            }
        }
    }

    private func writeClient(_ fd: Int32, _ s: String) {
        var data = Array(s.utf8)
        if data.last != 0x0A { data.append(0x0A) }
        _ = data.withUnsafeBytes { Foundation.write(fd, $0.baseAddress, data.count) }
    }

    private func dropClient(_ fd: Int32) {
        clients[fd]?.cancel()
        clients.removeValue(forKey: fd)
        buffers.removeValue(forKey: fd)
    }
}

// MARK: - PresenceClient
//
// Client for media-presenced's unix socket. Every broadcast line carries the
// full presence object; we watch inMeeting transitions and force push-to-talk
// so meetings never start with a hot mic (the job Hammerspoon's
// watchers/media-presence.lua used to do via miccheck.setPTTMode). Music
// pause / DND stay in Hammerspoon. Reconnects with a 5s backoff.

final class PresenceClient {
    private let path: String
    private let q = DispatchQueue(label: "miccheck.presence")
    private var fd: Int32 = -1
    private var source: DispatchSourceRead?
    private var buffer = Data()
    private var lastInMeeting: Bool?
    private var loggedWaiting = false

    /// Called on main with the new inMeeting value (transitions only).
    var onMeetingTransition: ((Bool) -> Void)?

    init(path: String) { self.path = path }

    func start() { q.async { self.connect() } }

    private func connect() {
        fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { scheduleReconnect(); return }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let cap = MemoryLayout.size(ofValue: addr.sun_path)
        let bytes = Array(path.utf8)
        guard bytes.count < cap else { close(fd); fd = -1; return }
        withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
            ptr.withMemoryRebound(to: CChar.self, capacity: cap) { dst in
                for i in 0..<bytes.count { dst[i] = CChar(bitPattern: bytes[i]) }
                dst[bytes.count] = 0
            }
        }
        let len = socklen_t(MemoryLayout<sockaddr_un>.size)
        let ok = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { Darwin.connect(fd, $0, len) }
        }
        guard ok == 0 else {
            close(fd)
            fd = -1
            if !loggedWaiting {
                loggedWaiting = true
                log("presence: media-presenced socket unavailable at \(path); retrying every 5s")
            }
            scheduleReconnect()
            return
        }

        loggedWaiting = false
        buffer = Data()
        let src = DispatchSource.makeReadSource(fileDescriptor: fd, queue: q)
        src.setEventHandler { [weak self] in self?.readData() }
        src.setCancelHandler { [fd = self.fd] in if fd >= 0 { close(fd) } }
        source = src
        src.resume()

        // Seed current state so we only react to real transitions.
        let get = Array("{\"cmd\":\"get\"}\n".utf8)
        _ = get.withUnsafeBytes { Foundation.write(fd, $0.baseAddress, get.count) }
        log("presence: connected to \(path)")
    }

    private func disconnect() {
        source?.cancel()
        source = nil
        fd = -1
        lastInMeeting = nil
    }

    private func scheduleReconnect() {
        q.asyncAfter(deadline: .now() + 5) { [weak self] in self?.connect() }
    }

    private func readData() {
        var tmp = [UInt8](repeating: 0, count: 4096)
        let n = Foundation.read(fd, &tmp, tmp.count)
        if n <= 0 {
            log("presence: disconnected; reconnecting")
            disconnect()
            scheduleReconnect()
            return
        }
        buffer.append(contentsOf: tmp[0..<n])
        while let idx = buffer.firstIndex(of: 0x0A) {
            let line = buffer.subdata(in: buffer.startIndex..<idx)
            buffer.removeSubrange(buffer.startIndex...idx)
            handleLine(line)
        }
    }

    private func handleLine(_ line: Data) {
        guard let obj = try? JSONSerialization.jsonObject(with: line) as? [String: Any],
              let inMeeting = obj["inMeeting"] as? Bool else { return }
        guard lastInMeeting != inMeeting else { return }
        let prev = lastInMeeting
        lastInMeeting = inMeeting
        guard prev != nil else { return } // first snapshot seeds only
        DispatchQueue.main.async { self.onMeetingTransition?(inMeeting) }
    }
}

// MARK: - Icons

private extension NSImage {
    func tinted(_ color: NSColor) -> NSImage {
        let img = NSImage(size: size, flipped: false) { rect in
            color.set()
            rect.fill()
            self.draw(in: rect, from: .zero, operation: .destinationIn, fraction: 1)
            return true
        }
        img.isTemplate = false
        return img
    }
}

enum Icons {
    // Matches miccheck.lua: white slashed mic when muted; white mic on a
    // #c43e1f rounded pill when the mic is hot.
    static let pillRed = NSColor(calibratedRed: 0xC4 / 255.0, green: 0x3E / 255.0, blue: 0x1F / 255.0, alpha: 1)

    static func muted() -> NSImage {
        let cfg = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        let img = NSImage(systemSymbolName: "mic.slash", accessibilityDescription: "mic muted")!
            .withSymbolConfiguration(cfg)!
        img.isTemplate = true
        return img
    }

    static func live() -> NSImage {
        let size = NSSize(width: 38, height: 20)
        let mic = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "mic live")!
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 12, weight: .medium))!
            .tinted(.white)
        let img = NSImage(size: size, flipped: false) { rect in
            pillRed.setFill()
            NSBezierPath(roundedRect: rect, xRadius: rect.height / 2, yRadius: rect.height / 2).fill()
            let m = mic.size
            mic.draw(in: NSRect(x: (rect.width - m.width) / 2, y: (rect.height - m.height) / 2,
                                width: m.width, height: m.height))
            return true
        }
        img.isTemplate = false
        return img
    }
}

// MARK: - App

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let audio = AudioController()
    private let chord = ChordMonitor()
    private var hotkey: HotKey?
    private var server: SocketServer?
    private var presence: PresenceClient?
    private var statusItem: NSStatusItem!
    private var tapRetryTimer: Timer?
    private var signalSources: [DispatchSourceSignal] = []

    private var mode: Mode = .pushToTalk
    private var chordActive = false

    private var micLive: Bool { mode == .pushToTalk ? chordActive : !chordActive }

    private let socketPath: String = {
        var path = NSHomeDirectory() + "/.local/state/miccheck/sock"
        let args = CommandLine.arguments
        if let i = args.firstIndex(of: "--socket"), i + 1 < args.count { path = args[i + 1] }
        return path
    }()

    private let presenceSocketPath: String? = {
        let args = CommandLine.arguments
        if args.contains("--no-presence") { return nil }
        if let i = args.firstIndex(of: "--presence-socket"), i + 1 < args.count { return args[i + 1] }
        return NSHomeDirectory() + "/.local/state/media-presence/sock"
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let saved = UserDefaults.standard.string(forKey: "mode"), let m = Mode(rawValue: saved) {
            mode = m
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        rebuildMenu()

        audio.start()

        chord.onChordDown = { [weak self] in self?.setChordActive(true) }
        chord.onChordUp = { [weak self] in self?.setChordActive(false) }
        startTapWithRetry()

        hotkey = HotKey { [weak self] in self?.toggleMode() }

        let server = SocketServer(path: socketPath)
        server.onCommand = { [weak self] cmd, reply in
            DispatchQueue.main.async { self?.handleCommand(cmd, reply: reply) }
        }
        do {
            try server.start()
            self.server = server
            log("socket listening at \(socketPath)")
        } catch {
            log("socket failed: \(error)")
        }

        if let presencePath = presenceSocketPath {
            let client = PresenceClient(path: presencePath)
            client.onMeetingTransition = { [weak self] inMeeting in
                guard let self else { return }
                log("presence: inMeeting=\(inMeeting) -> push-to-talk")
                self.setMode(.pushToTalk)
            }
            client.start()
            presence = client
        }

        installSignalHandlers()
        apply()
        log("started mode=\(mode.rawValue)")
    }

    func applicationWillTerminate(_ notification: Notification) {
        audio.releaseAll()
        unlink(socketPath)
        log("stopped (all inputs unmuted)")
    }

    // MARK: state

    private func setChordActive(_ active: Bool) {
        guard chordActive != active else { return }
        chordActive = active
        apply()
    }

    private func setMode(_ m: Mode) {
        chord.deactivate()
        chordActive = false
        mode = m
        UserDefaults.standard.set(m.rawValue, forKey: "mode")
        apply()
        log("mode=\(m.rawValue)")
    }

    @objc private func toggleMode() {
        setMode(mode == .pushToTalk ? .pushToMute : .pushToTalk)
    }

    private func apply() {
        audio.setLive(micLive)
        statusItem.button?.image = micLive ? Icons.live() : Icons.muted()
        rebuildMenu()
    }

    // MARK: menu

    private func rebuildMenu() {
        let menu = NSMenu()
        let ptt = NSMenuItem(title: "Push-to-talk", action: #selector(pickPTT), keyEquivalent: "")
        ptt.target = self
        ptt.state = mode == .pushToTalk ? .on : .off
        menu.addItem(ptt)
        let ptm = NSMenuItem(title: "Push-to-mute", action: #selector(pickPTM), keyEquivalent: "")
        ptm.target = self
        ptm.state = mode == .pushToMute ? .on : .off
        menu.addItem(ptm)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit MicCheck", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        statusItem.menu = menu
    }

    @objc private func pickPTT() { setMode(.pushToTalk) }
    @objc private func pickPTM() { setMode(.pushToMute) }
    @objc private func quitApp() { NSApp.terminate(nil) }

    // MARK: event tap

    private func startTapWithRetry() {
        if chord.start() {
            log("event tap active")
            return
        }
        log("event tap waiting for Input Monitoring grant (retrying every 5s; if the chord stays dead after granting, kickstart the agent)")
        tapRetryTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] t in
            guard let self else { t.invalidate(); return }
            if self.chord.start() {
                t.invalidate()
                self.tapRetryTimer = nil
                log("event tap active")
            }
        }
    }

    // MARK: socket commands

    private func handleCommand(_ raw: String, reply: @escaping (String) -> Void) {
        guard let data = raw.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let cmd = obj["cmd"] as? String
        else {
            reply(#"{"ok":false,"error":"bad json"}"#)
            return
        }
        switch cmd {
        case "get":
            reply(#"{"ok":true,"mode":"\#(mode.rawValue)","live":\#(micLive)}"#)
        case "set-mode":
            guard let m = (obj["mode"] as? String).flatMap(Mode.init(rawValue:)) else {
                reply(#"{"ok":false,"error":"bad mode"}"#)
                return
            }
            setMode(m)
            reply(#"{"ok":true}"#)
        case "toggle-mode":
            toggleMode()
            reply(#"{"ok":true,"mode":"\#(mode.rawValue)"}"#)
        case "quit":
            reply(#"{"ok":true}"#)
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50)) { NSApp.terminate(nil) }
        default:
            reply(#"{"ok":false,"error":"unknown cmd"}"#)
        }
    }

    // MARK: signals

    private func installSignalHandlers() {
        for sig in [SIGTERM, SIGINT] {
            signal(sig, SIG_IGN)
            let src = DispatchSource.makeSignalSource(signal: sig, queue: .main)
            src.setEventHandler { NSApp.terminate(nil) }
            src.resume()
            signalSources.append(src)
        }
    }
}

// MARK: - main

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
