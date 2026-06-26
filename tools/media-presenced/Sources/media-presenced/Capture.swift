// Capture layer: OS-level mic / camera in-use detection with owner attribution.
//
// - Mic:    CoreAudio process objects (kAudioHardwarePropertyProcessObjectList,
//           kAudioProcessPropertyIsRunningInput) → owner pid + bundle id.
// - Camera: CoreMediaIO device kAudioDevicePropertyDeviceIsRunningSomewhere,
//           with a property listener for change events.
//
// Validated against macOS Tahoe in .local_scripts/media-privacy-probe.
import Foundation
import CoreAudio
import CoreMediaIO
import AppKit

struct MicOwner: Equatable {
    var pid: pid_t
    var bundleID: String
    var name: String
}

struct CaptureState: Equatable {
    var micActive: Bool = false
    var micOwners: [MicOwner] = []
    var cameraActive: Bool = false
}

// MARK: - CoreAudio helpers

private func caUInt32(_ obj: AudioObjectID, _ sel: AudioObjectPropertySelector,
                      _ scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal) -> UInt32? {
    var addr = AudioObjectPropertyAddress(mSelector: sel, mScope: scope, mElement: kAudioObjectPropertyElementMain)
    var value: UInt32 = 0
    var size = UInt32(MemoryLayout<UInt32>.size)
    guard AudioObjectGetPropertyData(obj, &addr, 0, nil, &size, &value) == noErr else { return nil }
    return value
}

private func caString(_ obj: AudioObjectID, _ sel: AudioObjectPropertySelector) -> String? {
    var addr = AudioObjectPropertyAddress(mSelector: sel, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
    var size: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(obj, &addr, 0, nil, &size) == noErr else { return nil }
    var cf: CFString = "" as CFString
    let st = withUnsafeMutablePointer(to: &cf) { AudioObjectGetPropertyData(obj, &addr, 0, nil, &size, $0) }
    guard st == noErr else { return nil }
    return cf as String
}

private func caObjectList(_ sel: AudioObjectPropertySelector) -> [AudioObjectID] {
    var addr = AudioObjectPropertyAddress(mSelector: sel, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
    var size: UInt32 = 0
    let sys = AudioObjectID(kAudioObjectSystemObject)
    guard AudioObjectGetPropertyDataSize(sys, &addr, 0, nil, &size) == noErr else { return [] }
    let count = Int(size) / MemoryLayout<AudioObjectID>.size
    var ids = [AudioObjectID](repeating: 0, count: count)
    guard AudioObjectGetPropertyData(sys, &addr, 0, nil, &size, &ids) == noErr else { return [] }
    return ids
}

// MARK: - CMIO helpers

private func cmioUInt32(_ obj: CMIOObjectID, _ sel: CMIOObjectPropertySelector) -> UInt32? {
    var addr = CMIOObjectPropertyAddress(mSelector: sel,
                                         mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
                                         mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
    var value: UInt32 = 0
    var size = UInt32(MemoryLayout<UInt32>.size)
    guard CMIOObjectGetPropertyData(obj, &addr, 0, nil, size, &size, &value) == noErr else { return nil }
    return value
}

private func cmioDevices() -> [CMIOObjectID] {
    var addr = CMIOObjectPropertyAddress(mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
                                         mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
                                         mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
    var size: UInt32 = 0
    let sys = CMIOObjectID(kCMIOObjectSystemObject)
    guard CMIOObjectGetPropertyDataSize(sys, &addr, 0, nil, &size) == noErr else { return [] }
    let count = Int(size) / MemoryLayout<CMIOObjectID>.size
    var ids = [CMIOObjectID](repeating: 0, count: count)
    guard CMIOObjectGetPropertyData(sys, &addr, 0, nil, size, &size, &ids) == noErr else { return [] }
    return ids
}

// MARK: - CaptureMonitor

final class CaptureMonitor {
    private let queue = DispatchQueue(label: "media-presenced.capture")
    private var current = CaptureState()
    var onChange: ((CaptureState) -> Void)?

    private var audioListenerInstalled = false
    private var cameraListeners: [(CMIOObjectID, CMIOObjectPropertyAddress)] = []

    func start() {
        installAudioProcessListListener()
        installCameraListeners()
        refresh()
    }

    // Re-read full state and emit if changed.
    func refresh() {
        let new = CaptureMonitor.snapshot()
        queue.async { [weak self] in
            guard let self else { return }
            if new != self.current {
                self.current = new
                DispatchQueue.main.async { self.onChange?(new) }
            }
        }
    }

    static func snapshot() -> CaptureState {
        var s = CaptureState()
        // Mic via process objects.
        var owners: [MicOwner] = []
        for proc in caObjectList(kAudioHardwarePropertyProcessObjectList) {
            guard (caUInt32(proc, kAudioProcessPropertyIsRunningInput) ?? 0) != 0 else { continue }
            let pid = pid_t(Int32(caUInt32(proc, kAudioProcessPropertyPID) ?? 0))
            var bundle = caString(proc, kAudioProcessPropertyBundleID) ?? ""
            var name = ""
            if let app = NSRunningApplication(processIdentifier: pid) {
                if bundle.isEmpty { bundle = app.bundleIdentifier ?? "" }
                name = app.localizedName ?? ""
            }
            owners.append(MicOwner(pid: pid, bundleID: bundle, name: name))
        }
        s.micActive = !owners.isEmpty
        s.micOwners = owners
        // Camera via CMIO device running flag.
        for dev in cmioDevices() {
            if (cmioUInt32(dev, CMIOObjectPropertySelector(kAudioDevicePropertyDeviceIsRunningSomewhere)) ?? 0) != 0 {
                s.cameraActive = true
                break
            }
        }
        return s
    }

    // MARK: listeners

    private func installAudioProcessListListener() {
        var addr = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyProcessObjectList,
                                              mScope: kAudioObjectPropertyScopeGlobal,
                                              mElement: kAudioObjectPropertyElementMain)
        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in self?.refresh() }
        let st = AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &addr, queue, block)
        audioListenerInstalled = (st == noErr)
        // Also listen on each input device's IsRunningSomewhere for robustness.
        for dev in caObjectList(kAudioHardwarePropertyDevices) {
            var a = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
                                               mScope: kAudioObjectPropertyScopeGlobal,
                                               mElement: kAudioObjectPropertyElementMain)
            AudioObjectAddPropertyListenerBlock(dev, &a, queue, block)
        }
    }

    private func installCameraListeners() {
        let block: CMIOObjectPropertyListenerBlock = { [weak self] _, _ in self?.refresh() }
        for dev in cmioDevices() {
            var addr = CMIOObjectPropertyAddress(mSelector: CMIOObjectPropertySelector(kAudioDevicePropertyDeviceIsRunningSomewhere),
                                                 mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
                                                 mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
            if CMIOObjectAddPropertyListenerBlock(dev, &addr, queue, block) == noErr {
                cameraListeners.append((dev, addr))
            }
        }
    }
}
