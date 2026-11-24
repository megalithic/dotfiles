import Foundation

/// `rtm needs --json`: what waits on the user, per Ultimate hub. rtm owns the
/// count (open questions to the user plus open Inbox items), so this app, the
/// rtm picker and Ultimate's own Inbox badge never disagree.
struct Needs: Decodable, Equatable {
    var host: String
    var total: Int
    var hubs: [Hub]
}

struct Hub: Decodable, Equatable {
    var host: String
    var project: String
    var url: String
    /// nil when the hub could not be read: unreachable is never 0.
    var count: Int?
    var error: String?
    var inbox: [Entry]
    /// Pinned first, then worst first; nil from an rtm before automations.
    var automations: [Automation]?
    var automations_error: String?
}

/// One hub automation, its state in the words of Ultimate's Automations panel.
struct Automation: Decodable, Equatable {
    var id: String
    var name: String
    var pinned: Bool
    var enabled: Bool
    /// schedule, event, context or script
    var kind: String
    /// failed, investigating, writing, working, watching, scheduled, armed, waiting, paused or done
    var state: String
    var last_fire_at: Int?
    var error: String?
}

extension Automation {
    /// The `rtm automation` operation that switches it: a script is started by resume too.
    var toggle: (operation: String, title: String) {
        enabled ? ("pause", "Pause") : ("resume", kind == "script" ? "Start" : "Resume")
    }

    /// `run` fires a trigger now, or relaunches a script from the top.
    var runTitle: String { kind == "script" ? "Restart" : "Run now" }

    var attention: Bool { state == "failed" || state == "investigating" }

    /// "Dream after a pause  armed · fired 2h ago"
    func label(now: Date = Date()) -> String {
        var line = "\(name)  \(state)"
        if let at = last_fire_at {
            line += " · fired \(Self.ago(Date(timeIntervalSince1970: Double(at) / 1000), now: now))"
        }
        return line
    }

    static func ago(_ date: Date, now: Date) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(date)))
        switch seconds {
        case ..<60: return "just now"
        case ..<3600: return "\(seconds / 60)m ago"
        case ..<86400: return "\(seconds / 3600)h ago"
        default: return "\(seconds / 86400)d ago"
        }
    }
}

struct Entry: Decodable, Equatable {
    var key: String
    var kind: String
    var title: String
    var detail: String?
    var at: Int
}

/// One host's hubs, in rtm's order: this Mac first, then the others.
struct HostGroup: Equatable {
    var host: String
    var hubs: [Hub]
}

extension Needs {
    static func decode(_ data: Data) throws -> Needs {
        try JSONDecoder().decode(Needs.self, from: data)
    }

    var unreachable: Int { hubs.filter { $0.count == nil }.count }

    /// The menu bar title beside the icon: the count when anything waits,
    /// nothing when all is clear, and a "?" while a hub can't be read.
    var title: String {
        let suffix = unreachable > 0 ? "?" : ""
        return total > 0 ? "\(total)\(suffix)" : suffix
    }

    var groups: [HostGroup] {
        var groups: [HostGroup] = []
        for hub in hubs {
            if let index = groups.firstIndex(where: { $0.host == hub.host }) {
                groups[index].hubs.append(hub)
            } else {
                groups.append(HostGroup(host: hub.host, hubs: [hub]))
            }
        }
        return groups
    }
}

extension Hub {
    /// "<url>/?inbox=<key>" opens that item in the hub's Inbox; without a key, the oldest.
    func link(_ key: String? = nil) -> URL? {
        guard var components = URLComponents(string: url) else { return nil }
        if components.path.isEmpty { components.path = "/" }
        components.queryItems = [URLQueryItem(name: "inbox", value: key ?? inbox.first?.key ?? "")]
        return components.url
    }

    var label: String {
        guard let count else { return "\(project)  unreachable" }
        return "\(project)  \(count)"
    }

    var pinned: [Automation] { (automations ?? []).filter(\.pinned) }
}
