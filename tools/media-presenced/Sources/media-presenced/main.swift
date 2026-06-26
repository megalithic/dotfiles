// media-presenced — fuses macOS capture-layer (mic/camera) with CDP-based Google
// Meet detection and serves a line-delimited JSON event stream + query/focus
// commands over a Unix-domain socket for Hammerspoon.
//
// Usage:
//   media-presenced [--socket PATH] [--cdp-port N]
//   echo '{"cmd":"get"}'   | nc -U <socket>   # current presence
//   echo '{"cmd":"focus"}' | nc -U <socket>   # focus current meeting
import Foundation
import AppKit

// args
var socketPath = NSString(string: "~/.local/state/media-presence/sock").expandingTildeInPath
var cdpPort = 9223
do {
    var it = CommandLine.arguments.dropFirst().makeIterator()
    while let a = it.next() {
        switch a {
        case "--socket": if let v = it.next() { socketPath = NSString(string: v).expandingTildeInPath }
        case "--cdp-port": if let v = it.next(), let n = Int(v) { cdpPort = n }
        case "--snapshot":
            let s = CaptureMonitor.snapshot()
            print(encodePresenceLine("snapshot", {
                var p = Presence(); p.micActive = s.micActive
                p.micOwners = s.micOwners.map { $0.bundleID }; p.cameraActive = s.cameraActive
                return p
            }()))
            exit(0)
        default: break
        }
    }
}

let engine = PresenceEngine()
let capture = CaptureMonitor()
let cdp = CDPClient(port: cdpPort)
let server = SocketServer(path: socketPath)

func log(_ s: String) { FileHandle.standardError.write(Data((s + "\n").utf8)) }

engine.onEvent = { event, presence in
    let line = encodePresenceLine(event, presence)
    server.broadcast(line)
    FileHandle.standardOutput.write(Data(line.utf8))
}

capture.onChange = { state in engine.applyCapture(state) }
cdp.onMeet = { event, state in engine.applyMeet(event, state) }

server.onCommand = { cmd, reply in
    guard let data = cmd.data(using: .utf8),
          let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let c = obj["cmd"] as? String else {
        reply(#"{"ok":false,"error":"bad command"}"#); return
    }
    switch c {
    case "get":
        reply(encodePresenceLine("get", engine.presence).trimmingCharacters(in: .newlines))
    case "focus":
        let p = engine.presence
        if p.inMeeting && !p.meetingTargetId.isEmpty {
            cdp.activateTarget(p.meetingTargetId)
            if let app = NSRunningApplication.runningApplications(withBundleIdentifier: p.meetingApp).first {
                app.activate(options: [.activateAllWindows])
            }
            reply(#"{"ok":true,"focused":"meet"}"#)
        } else {
            reply(#"{"ok":false,"error":"no active meeting"}"#)
        }
    default:
        reply(#"{"ok":false,"error":"unknown cmd"}"#)
    }
}

do {
    try server.start()
    log("media-presenced: socket \(socketPath)")
} catch {
    log("media-presenced: socket error \(error)")
    exit(1)
}

capture.start()
cdp.start()
log("media-presenced: started (cdp port \(cdpPort))")

// Periodic capture refresh as a safety net (listeners cover most transitions).
let refreshTimer = DispatchSource.makeTimerSource(queue: .global())
refreshTimer.schedule(deadline: .now() + 5, repeating: 5)
refreshTimer.setEventHandler { capture.refresh() }
refreshTimer.resume()

RunLoop.main.run()
