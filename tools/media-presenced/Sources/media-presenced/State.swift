// State machine: fuse capture layer (mic/cam) + CDP layer (Meet) into a single
// presence model, emit discrete events, and expose the "current meeting" record
// that Hammerspoon's hyper+z uses to focus the right window/tab.
import Foundation

struct Presence: Codable, Equatable {
    // capture layer
    var micActive = false
    var micOwners: [String] = []        // bundle ids
    var cameraActive = false
    // meeting layer (Meet via CDP)
    var inMeeting = false               // lobby or joined
    var meetingState = "idle"           // idle | lobby | joined
    var sharing = false
    var meetingApp = ""                 // bundle id owning the meeting
    var meetingURL = ""
    var meetingTitle = ""
    var meetingTargetId = ""            // CDP target id (for focus)
    var participants: [String] = []
    var inAppMic = "?"                  // on | muted | ?
    var inAppCamera = "?"               // on | off | ?
}

final class PresenceEngine {
    private(set) var presence = Presence()
    var onEvent: ((_ event: String, _ presence: Presence) -> Void)?

    private let meetBundle = "net.imput.helium"  // browser hosting Meet tabs

    func applyCapture(_ c: CaptureState) {
        var p = presence
        let micWas = p.micActive, camWas = p.cameraActive
        p.micActive = c.micActive
        p.micOwners = c.micOwners.map { $0.bundleID }
        p.cameraActive = c.cameraActive
        commit(p)
        if p.micActive != micWas { emit(p.micActive ? "mic.on" : "mic.off") }
        if p.cameraActive != camWas { emit(p.cameraActive ? "camera.on" : "camera.off") }
    }

    func applyMeet(_ event: String, _ m: MeetState) {
        var p = presence
        switch event {
        case "meet.left":
            // Only clear if this was the tracked meeting target (or none tracked).
            if p.meetingTargetId.isEmpty || p.meetingTargetId == m.targetId {
                let wasSharing = p.sharing
                p = clearMeeting(p)
                commit(p)
                if wasSharing { emit("screenshare.stop") }
                emit("meeting.left")
            }
        case "meet.appeared":
            p.meetingApp = meetBundle
            p.meetingTargetId = m.targetId
            p.meetingURL = m.url
            p.meetingTitle = m.title
            commit(p)
        case "meet.state":
            let stateWas = p.meetingState
            let sharingWas = p.sharing
            p.meetingApp = meetBundle
            p.meetingTargetId = m.targetId
            p.meetingURL = m.url
            p.meetingTitle = m.title
            p.meetingState = m.dom.state            // lobby | joined | unknown
            p.inMeeting = (m.dom.state == "lobby" || m.dom.state == "joined")
            p.sharing = m.dom.presenting
            p.participants = m.dom.participants
            p.inAppMic = m.dom.micSelf
            p.inAppCamera = m.dom.camSelf
            commit(p)
            if p.meetingState != stateWas {
                if p.meetingState == "lobby" { emit("meeting.lobby") }
                if p.meetingState == "joined" { emit("meeting.joined") }
            }
            if p.sharing != sharingWas { emit(p.sharing ? "screenshare.start" : "screenshare.stop") }
        default:
            break
        }
    }

    private func clearMeeting(_ p: Presence) -> Presence {
        var p = p
        p.inMeeting = false; p.meetingState = "idle"; p.sharing = false
        p.meetingApp = ""; p.meetingURL = ""; p.meetingTitle = ""; p.meetingTargetId = ""
        p.participants = []; p.inAppMic = "?"; p.inAppCamera = "?"
        return p
    }

    private func commit(_ p: Presence) { presence = p }
    private func emit(_ event: String) { onEvent?(event, presence) }
}

func encodePresenceLine(_ event: String, _ p: Presence) -> String {
    var dict: [String: Any] = [
        "t": ISO8601DateFormatter().string(from: Date()),
        "event": event,
        "micActive": p.micActive,
        "micOwners": p.micOwners,
        "cameraActive": p.cameraActive,
        "inMeeting": p.inMeeting,
        "meetingState": p.meetingState,
        "sharing": p.sharing,
        "meetingApp": p.meetingApp,
        "meetingURL": p.meetingURL,
        "meetingTitle": p.meetingTitle,
        "meetingTargetId": p.meetingTargetId,
        "participants": p.participants,
        "inAppMic": p.inAppMic,
        "inAppCamera": p.inAppCamera,
    ]
    dict["v"] = 1
    guard let data = try? JSONSerialization.data(withJSONObject: dict),
          let s = String(data: data, encoding: .utf8) else { return "{}" }
    return s + "\n"
}
