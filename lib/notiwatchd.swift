// notiwatchd - macOS Notification Center watcher daemon.
//
// Watches the usernoted SQLite store (WAL file kqueue + fallback poll),
// decodes each newly delivered notification, matches it against JSON rules,
// records it (with rule metadata) into its own SQLite DB, broadcasts NDJSON
// events over a Unix socket, and routes to sinks (bin/ntfy, exec, webhook).
//
// Requirements:
// - Full Disk Access for the compiled binary (~/.local/bin/notiwatchd) to
//   read ~/Library/Group Containers/group.com.apple.usernoted/db2/db.
// - Build with lib/build-swift notiwatchd (stable codesign identity so the
//   TCC grant survives rebuilds).
//
// Config:  ~/.config/notiwatchd/config.json   (hot-reloaded on change)
// Store:   ~/.local/share/notiwatchd/notifications.db
// Socket:  ~/.local/state/notiwatchd/sock     (NDJSON broadcast, subscribe-only)

import AppKit
import ApplicationServices
import Foundation
import SQLite3

// LaunchAgent PATH is portable system/Homebrew paths; preserve the former
// wrapper's HOME-relative command lookup for exec actions and helper scripts.
let inheritedPath = ProcessInfo.processInfo.environment["PATH"] ?? "/usr/bin:/bin"
setenv("PATH", "\(NSHomeDirectory())/bin:\(NSHomeDirectory())/.local/bin:\(inheritedPath)", 1)

let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
let appleEpochOffset = 978_307_200.0

func expand(_ path: String) -> String { (path as NSString).expandingTildeInPath }

let isoFormatter = ISO8601DateFormatter()
func log(_ message: String) { print("[\(isoFormatter.string(from: Date()))] \(message)"); fflush(stdout) }
func warn(_ message: String) {
    FileHandle.standardError.write(Data("[\(isoFormatter.string(from: Date()))] WARN \(message)\n".utf8))
}

// MARK: - Config

enum StringOrArray: Decodable {
    case one(String)
    case many([String])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = .one(str)
        } else {
            self = .many(try container.decode([String].self))
        }
    }

    var values: [String] {
        switch self {
        case .one(let str): return [str]
        case .many(let arr): return arr
        }
    }
}

struct Match: Decodable {
    var bundleID: StringOrArray?    // exact match, any-of
    var title: StringOrArray?       // regex (case-insensitive), any-of
    var subtitle: StringOrArray?
    var body: StringOrArray?

    enum CodingKeys: String, CodingKey {
        case bundleID = "bundle_id"
        case title, subtitle, body
    }
}

struct Rule: Decodable {
    var name: String
    var match: Match
    var urgency: String?            // normal | high | critical (passed to ntfy -u)
    var presenceRouting: Bool?      // allow remote-only attention to add Telegram delivery
    var actions: [String]           // log | ignore | dismiss | ntfy[:phone|:telegram] | exec:<cmd> | webhook:<url>

    enum CodingKeys: String, CodingKey {
        case name, match, urgency, actions
        case presenceRouting = "presence_routing"
    }
}

struct Config: Decodable {
    var pollFallbackSeconds: Double?
    var ntfyPath: String?
    var defaultActions: [String]?
    var rules: [Rule]?

    enum CodingKeys: String, CodingKey {
        case pollFallbackSeconds = "poll_fallback_seconds"
        case ntfyPath = "ntfy_path"
        case defaultActions = "default_actions"
        case rules
    }
}

final class ConfigStore {
    let path: String
    private(set) var config = Config(pollFallbackSeconds: nil, ntfyPath: nil, defaultActions: nil, rules: nil)
    private var mtime: Date = .distantPast

    init(path: String) {
        self.path = path
        reloadIfChanged(force: true)
    }

    func reloadIfChanged(force: Bool = false) {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let modDate = attrs[.modificationDate] as? Date else {
            if force { warn("config missing at \(path); using defaults (log everything)") }
            return
        }
        guard force || modDate > mtime else { return }
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            config = try JSONDecoder().decode(Config.self, from: data)
            mtime = modDate
            log("config loaded: \(config.rules?.count ?? 0) rule(s)")
        } catch {
            warn("config parse failed, keeping previous: \(error)")
        }
    }
}

// MARK: - Notification event

struct Event {
    var recID: Int64
    var uuid: String
    var bundleID: String
    var title: String?
    var subtitle: String?
    var body: String?
    var deliveredAt: Double?    // unix epoch
    var presented: Bool?
    var style: Int?
    var rule: String?
    var urgency: String
    var presenceRouting: Bool
    var actions: [String]

    func json() -> String {
        var dict: [String: Any] = [
            "rec_id": recID, "uuid": uuid, "bundle_id": bundleID,
            "urgency": urgency, "presence_routing": presenceRouting, "actions": actions,
        ]
        dict["title"] = title
        dict["subtitle"] = subtitle
        dict["body"] = body
        if let when = deliveredAt {
            dict["delivered_at"] = isoFormatter.string(from: Date(timeIntervalSince1970: when))
        }
        dict["presented"] = presented
        dict["style"] = style
        dict["rule"] = rule
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys]) else { return "{}" }
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}

// MARK: - SQLite helpers

func sqOpen(_ path: String, readonly: Bool) -> OpaquePointer? {
    var handle: OpaquePointer?
    let flags = readonly ? SQLITE_OPEN_READONLY : (SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE)
    guard sqlite3_open_v2(path, &handle, flags, nil) == SQLITE_OK else {
        warn("sqlite open failed: \(path): \(handle.map { String(cString: sqlite3_errmsg($0)) } ?? "?")")
        if let handle = handle { sqlite3_close(handle) }
        return nil
    }
    sqlite3_busy_timeout(handle, 2000)
    return handle
}

func sqText(_ stmt: OpaquePointer?, _ index: Int32) -> String? {
    guard let cstr = sqlite3_column_text(stmt, index) else { return nil }
    return String(cString: cstr)
}

// MARK: - Own store

final class Store {
    let handle: OpaquePointer

    init?(path: String) {
        try? FileManager.default.createDirectory(atPath: (path as NSString).deletingLastPathComponent,
                                                 withIntermediateDirectories: true)
        guard let handle = sqOpen(path, readonly: false) else { return nil }
        self.handle = handle
        let schema = """
        CREATE TABLE IF NOT EXISTS notifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          rec_id INTEGER, uuid TEXT, bundle_id TEXT,
          title TEXT, subtitle TEXT, body TEXT,
          delivered_at REAL, presented INTEGER, style INTEGER,
          rule TEXT, urgency TEXT, actions TEXT, action_results TEXT,
          raw TEXT, created_at REAL DEFAULT (unixepoch('subsec'))
        );
        CREATE INDEX IF NOT EXISTS idx_notif_bundle ON notifications(bundle_id);
        CREATE INDEX IF NOT EXISTS idx_notif_created ON notifications(created_at);
        CREATE TABLE IF NOT EXISTS state (key TEXT PRIMARY KEY, value TEXT);
        """
        sqlite3_exec(handle, schema, nil, nil, nil)
        sqlite3_exec(handle, "PRAGMA journal_mode=WAL;", nil, nil, nil)
    }

    func stateGet(_ key: String) -> String? {
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(handle, "SELECT value FROM state WHERE key=?", -1, &stmt, nil) == SQLITE_OK else {
            return nil
        }
        sqlite3_bind_text(stmt, 1, key, -1, sqliteTransient)
        return sqlite3_step(stmt) == SQLITE_ROW ? sqText(stmt, 0) : nil
    }

    func stateSet(_ key: String, _ value: String) {
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        let sql = "INSERT INTO state(key,value) VALUES(?,?) ON CONFLICT(key) DO UPDATE SET value=excluded.value"
        guard sqlite3_prepare_v2(handle, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        sqlite3_bind_text(stmt, 1, key, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 2, value, -1, sqliteTransient)
        sqlite3_step(stmt)
    }

    @discardableResult
    func insert(_ event: Event, raw: String?, results: String?) -> Int64 {
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        let sql = """
        INSERT INTO notifications
          (rec_id, uuid, bundle_id, title, subtitle, body, delivered_at, presented, style,
           rule, urgency, actions, action_results, raw)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        """
        guard sqlite3_prepare_v2(handle, sql, -1, &stmt, nil) == SQLITE_OK else { return 0 }
        func bindOpt(_ index: Int32, _ value: String?) {
            if let value = value {
                sqlite3_bind_text(stmt, index, value, -1, sqliteTransient)
            } else {
                sqlite3_bind_null(stmt, index)
            }
        }
        sqlite3_bind_int64(stmt, 1, event.recID)
        sqlite3_bind_text(stmt, 2, event.uuid, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 3, event.bundleID, -1, sqliteTransient)
        bindOpt(4, event.title)
        bindOpt(5, event.subtitle)
        bindOpt(6, event.body)
        if let when = event.deliveredAt { sqlite3_bind_double(stmt, 7, when) } else { sqlite3_bind_null(stmt, 7) }
        if let presented = event.presented {
            sqlite3_bind_int(stmt, 8, presented ? 1 : 0)
        } else {
            sqlite3_bind_null(stmt, 8)
        }
        if let style = event.style { sqlite3_bind_int(stmt, 9, Int32(style)) } else { sqlite3_bind_null(stmt, 9) }
        bindOpt(10, event.rule)
        sqlite3_bind_text(stmt, 11, event.urgency, -1, sqliteTransient)
        bindOpt(12, event.actions.joined(separator: ","))
        bindOpt(13, results)
        bindOpt(14, raw)
        if sqlite3_step(stmt) != SQLITE_DONE {
            warn("store insert failed: \(String(cString: sqlite3_errmsg(handle)))")
            return 0
        }
        return sqlite3_last_insert_rowid(handle)
    }

    func updateResults(_ rowID: Int64, _ results: String) {
        guard rowID > 0 else { return }
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(handle, "UPDATE notifications SET action_results=? WHERE id=?",
                                 -1, &stmt, nil) == SQLITE_OK else { return }
        sqlite3_bind_text(stmt, 1, results, -1, sqliteTransient)
        sqlite3_bind_int64(stmt, 2, rowID)
        sqlite3_step(stmt)
    }
}

// MARK: - Source (usernoted) reader

struct SourceRow {
    var recID: Int64
    var uuid: String
    var identifier: String?
    var data: Data?
    var deliveredDate: Double?  // apple epoch
    var requestDate: Double?
    var presented: Bool?
    var style: Int?
}

final class SourceDB {
    let path: String
    private var conn: OpaquePointer?

    init(path: String) { self.path = path }

    private func handle() -> OpaquePointer? {
        if let conn = conn { return conn }
        conn = sqOpen(path, readonly: true)
        return conn
    }

    func close() {
        if let conn = conn { sqlite3_close(conn) }
        conn = nil
    }

    func maxRecID() -> Int64? {
        guard let conn = handle() else { return nil }
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(conn, "SELECT COALESCE(MAX(rec_id),0) FROM record", -1, &stmt, nil) == SQLITE_OK,
              sqlite3_step(stmt) == SQLITE_ROW else {
            close()
            return nil
        }
        return sqlite3_column_int64(stmt, 0)
    }

    func rows(after recID: Int64) -> [SourceRow] {
        guard let conn = handle() else { return [] }
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        let sql = """
        SELECT r.rec_id, hex(r.uuid), a.identifier, r.data,
               r.delivered_date, r.request_date, r.presented, r.style
        FROM record r LEFT JOIN app a ON a.app_id = r.app_id
        WHERE r.rec_id > ? ORDER BY r.rec_id
        """
        guard sqlite3_prepare_v2(conn, sql, -1, &stmt, nil) == SQLITE_OK else {
            close()
            return []
        }
        sqlite3_bind_int64(stmt, 1, recID)
        var out: [SourceRow] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            var row = SourceRow(recID: sqlite3_column_int64(stmt, 0),
                                uuid: sqText(stmt, 1) ?? "",
                                identifier: sqText(stmt, 2),
                                data: nil, deliveredDate: nil, requestDate: nil,
                                presented: nil, style: nil)
            if let blob = sqlite3_column_blob(stmt, 3) {
                row.data = Data(bytes: blob, count: Int(sqlite3_column_bytes(stmt, 3)))
            }
            if sqlite3_column_type(stmt, 4) != SQLITE_NULL { row.deliveredDate = sqlite3_column_double(stmt, 4) }
            if sqlite3_column_type(stmt, 5) != SQLITE_NULL { row.requestDate = sqlite3_column_double(stmt, 5) }
            if sqlite3_column_type(stmt, 6) != SQLITE_NULL { row.presented = sqlite3_column_int(stmt, 6) != 0 }
            if sqlite3_column_type(stmt, 7) != SQLITE_NULL { row.style = Int(sqlite3_column_int(stmt, 7)) }
            out.append(row)
        }
        return out
    }
}

// MARK: - File watcher (kqueue via DispatchSource)

final class FileWatcher {
    private let path: String
    private let queue: DispatchQueue
    private let onEvent: () -> Void
    private var descriptor: Int32 = -1
    private var source: DispatchSourceFileSystemObject?

    init(path: String, queue: DispatchQueue, onEvent: @escaping () -> Void) {
        self.path = path
        self.queue = queue
        self.onEvent = onEvent
        start()
    }

    private func start() {
        descriptor = open(path, O_EVTONLY)
        guard descriptor >= 0 else {
            // File may not exist yet (e.g. wal after full checkpoint); retry.
            queue.asyncAfter(deadline: .now() + 5) { [weak self] in self?.start() }
            return
        }
        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor, eventMask: [.write, .extend, .delete, .rename], queue: queue)
        src.setEventHandler { [weak self] in
            guard let self = self else { return }
            let flags = src.data
            self.onEvent()
            if flags.contains(.delete) || flags.contains(.rename) {
                self.stop()
                self.queue.asyncAfter(deadline: .now() + 1) { self.start() }
            }
        }
        src.setCancelHandler { [descriptor = self.descriptor] in if descriptor >= 0 { close(descriptor) } }
        src.resume()
        source = src
    }

    private func stop() {
        source?.cancel()
        source = nil
        descriptor = -1
    }
}

// MARK: - Unix socket broadcast server

final class SocketServer {
    private let queue = DispatchQueue(label: "notiwatchd.socket")
    private var listenFD: Int32 = -1
    private var acceptSource: DispatchSourceRead?
    private var clients: Set<Int32> = []

    init?(path: String) {
        try? FileManager.default.createDirectory(atPath: (path as NSString).deletingLastPathComponent,
                                                 withIntermediateDirectories: true)
        unlink(path)
        listenFD = socket(AF_UNIX, SOCK_STREAM, 0)
        guard listenFD >= 0 else { return nil }
        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let copied = path.withCString { cstr -> Bool in
            withUnsafeMutableBytes(of: &addr.sun_path) { buf in
                guard strlen(cstr) < buf.count else { return false }
                strcpy(buf.baseAddress!.assumingMemoryBound(to: CChar.self), cstr)
                return true
            }
        }
        guard copied else {
            close(listenFD)
            return nil
        }
        let len = socklen_t(MemoryLayout<sockaddr_un>.size)
        let bound = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(listenFD, $0, len) }
        }
        guard bound == 0, listen(listenFD, 8) == 0 else {
            close(listenFD)
            return nil
        }
        let src = DispatchSource.makeReadSource(fileDescriptor: listenFD, queue: queue)
        src.setEventHandler { [weak self] in
            guard let self = self else { return }
            let clientFD = accept(self.listenFD, nil, nil)
            guard clientFD >= 0 else { return }
            var one: Int32 = 1
            setsockopt(clientFD, SOL_SOCKET, SO_NOSIGPIPE, &one, socklen_t(MemoryLayout<Int32>.size))
            self.clients.insert(clientFD)
        }
        src.resume()
        acceptSource = src
        log("socket listening: \(path)")
    }

    func broadcast(_ line: String) {
        queue.async { [weak self] in
            guard let self = self, !self.clients.isEmpty else { return }
            let data = Array((line + "\n").utf8)
            for clientFD in self.clients {
                let sent = data.withUnsafeBytes { send(clientFD, $0.baseAddress, $0.count, 0) }
                if sent < 0 {
                    close(clientFD)
                    self.clients.remove(clientFD)
                }
            }
        }
    }
}

// MARK: - On-screen dismissal (Accessibility)
//
// Tahoe renders Notification Center banners/alerts with system SwiftUI. The
// notification elements are AXGroups with subroles like
// AXNotificationCenterAlertStack (stacked) whose AXDescription contains the
// app name, title, and body. Close/Clear All are exposed as SwiftUI custom
// actions whose AX action *names* are literal "Name:...\nTarget:...\n
// Selector:(null)" strings; match them by AXActionDescription instead.
// Discovered with .local_scripts/nc-ax-probe.swift (see lat.md).

func axAttr(_ element: AXUIElement, _ name: String) -> AnyObject? {
    var value: AnyObject?
    guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
    return value
}

func axFindNotification(_ element: AXUIElement, needles: [String], depth: Int = 0) -> AXUIElement? {
    if depth > 12 { return nil }
    if let subrole = axAttr(element, kAXSubroleAttribute) as? String,
       subrole.hasPrefix("AXNotificationCenter") {
        let desc = (axAttr(element, kAXDescriptionAttribute) as? String) ?? ""
        if needles.contains(where: { desc.range(of: $0, options: .caseInsensitive) != nil }) {
            return element
        }
        return nil  // notification element, but not ours; children are just static texts
    }
    if let children = axAttr(element, kAXChildrenAttribute) as? [AXUIElement] {
        for child in children {
            if let found = axFindNotification(child, needles: needles, depth: depth + 1) { return found }
        }
    }
    return nil
}

func axCloseNotification(_ target: AXUIElement) -> String {
    var actionNames: CFArray?
    guard AXUIElementCopyActionNames(target, &actionNames) == .success,
          let names = actionNames as? [String] else { return "no-actions" }
    for name in names {
        var descRef: CFString?
        AXUIElementCopyActionDescription(target, name as CFString, &descRef)
        let actionDesc = (descRef as String?) ?? ""
        if actionDesc == "Close" || actionDesc == "Clear All" || actionDesc == "Clear" {
            let err = AXUIElementPerformAction(target, name as CFString)
            return err == .success ? "ok" : "ax-error=\(err.rawValue)"
        }
    }
    return "no-close-action"
}

// Not fire-and-forget: retries the find→close→verify cycle until the banner
// is confirmed gone or the deadline passes. Banners can render after the
// usernoted commit (find race), so a single scan loses reposted BTM alerts.
// Blocking is fine here — dismiss runs on the concurrent sinkQueue.
func dismissOnScreen(_ event: Event) -> String {
    guard AXIsProcessTrusted() else { return "ax-not-trusted" }
    guard let ncApp = NSWorkspace.shared.runningApplications.first(where: {
        $0.bundleIdentifier == "com.apple.notificationcenterui"
    }) else { return "nc-not-running" }
    let needles = [event.title, event.body].compactMap { $0 }.filter { !$0.isEmpty }
    guard !needles.isEmpty else { return "no-title-or-body" }
    let appElement = AXUIElementCreateApplication(ncApp.processIdentifier)
    let deadline = Date().addingTimeInterval(15)
    var lastResult = "not-on-screen"
    while true {
        if let target = axFindNotification(appElement, needles: needles) {
            lastResult = axCloseNotification(target)
            if lastResult == "ok" {
                Thread.sleep(forTimeInterval: 0.5)
                if axFindNotification(appElement, needles: needles) == nil { return "ok" }
                lastResult = "still-on-screen"
            }
        }
        if Date() >= deadline { return lastResult }
        Thread.sleep(forTimeInterval: 2)
    }
}

// MARK: - Sinks

let sinkQueue = DispatchQueue(label: "notiwatchd.sinks", attributes: .concurrent)

func runProcess(_ exe: String, _ args: [String], stdinData: Data? = nil) -> String {
    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: exe)
    proc.arguments = args
    let pipe = Pipe()
    proc.standardOutput = pipe
    proc.standardError = pipe
    if let data = stdinData {
        let inPipe = Pipe()
        proc.standardInput = inPipe
        do { try proc.run() } catch { return "spawn-failed: \(error)" }
        inPipe.fileHandleForWriting.write(data)
        inPipe.fileHandleForWriting.closeFile()
    } else {
        do { try proc.run() } catch { return "spawn-failed: \(error)" }
    }
    proc.waitUntilExit()
    let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    return proc.terminationStatus == 0 ? "ok" : "exit=\(proc.terminationStatus) \(out.prefix(200))"
}

func dispatchAction(_ action: String, event: Event, cfg: Config, done: @escaping (String, String) -> Void) {
    let parts = action.split(separator: ":", maxSplits: 1).map(String.init)
    let kind = parts[0]
    let arg = parts.count > 1 ? parts[1] : nil

    switch kind {
    case "log", "ignore":
        done(action, "ok")
    case "dismiss":
        // Needs an Accessibility grant for this binary (in addition to FDA).
        // Dismisses the whole stack when the target is stacked (Clear All).
        sinkQueue.async { done(action, dismissOnScreen(event)) }
    case "ntfy":
        sinkQueue.async {
            let ntfy = expand(cfg.ntfyPath ?? "~/.dotfiles/bin/ntfy")
            // -b: HUD shows the app's icon and Hammerspoon can suppress when the
            // user is already engaged with that app/conversation.
            // -S: keep the raw title (sender) unprefixed for engagement matching.
            var args = ["send", "-t", event.title ?? event.bundleID,
                        "-m", [event.subtitle, event.body].compactMap { $0 }.joined(separator: " — "),
                        "-u", event.urgency, "-b", event.bundleID, "-S"]
            if event.presenceRouting { args.append("--presence-routing") }
            if arg == "phone" { args.append("-p") }
            if arg == "telegram" { args.append("-T") }
            done(action, runProcess(ntfy, args))
        }
    case "exec":
        guard let cmd = arg else {
            done(action, "missing-command")
            return
        }
        sinkQueue.async {
            done(action, runProcess("/bin/sh", ["-c", cmd], stdinData: Data(event.json().utf8)))
        }
    case "webhook":
        guard let urlStr = arg, let url = URL(string: urlStr) else {
            done(action, "bad-url")
            return
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = Data(event.json().utf8)
        URLSession.shared.dataTask(with: req) { _, resp, err in
            if let err = err {
                done(action, "error: \(err.localizedDescription)")
            } else {
                done(action, "http=\((resp as? HTTPURLResponse)?.statusCode ?? -1)")
            }
        }.resume()
    default:
        done(action, "unknown-action")
    }
}

// MARK: - Rule matching

func matchesAny(_ value: String?, patterns: StringOrArray?, exact: Bool) -> Bool {
    guard let patterns = patterns else { return true }   // field absent = wildcard
    guard let value = value else { return false }
    for pattern in patterns.values {
        if exact {
            if value.caseInsensitiveCompare(pattern) == .orderedSame { return true }
        } else if value.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil {
            return true
        }
    }
    return false
}

func matchRule(_ rules: [Rule], bundleID: String, title: String?, subtitle: String?, body: String?) -> Rule? {
    for rule in rules {
        if matchesAny(bundleID, patterns: rule.match.bundleID, exact: true),
           matchesAny(title, patterns: rule.match.title, exact: false),
           matchesAny(subtitle, patterns: rule.match.subtitle, exact: false),
           matchesAny(body, patterns: rule.match.body, exact: false) {
            return rule
        }
    }
    return nil
}

// MARK: - Main

var sourcePath = expand("~/Library/Group Containers/group.com.apple.usernoted/db2/db")
var configPath = expand("~/.config/notiwatchd/config.json")
var storePath = expand("~/.local/share/notiwatchd/notifications.db")
var socketPath = expand("~/.local/state/notiwatchd/sock")
var runOnce = false
var replay: Int64 = 0
var verbose = false

var argIter = CommandLine.arguments.dropFirst().makeIterator()
while let arg = argIter.next() {
    switch arg {
    case "--source": sourcePath = expand(argIter.next() ?? sourcePath)
    case "--config": configPath = expand(argIter.next() ?? configPath)
    case "--store": storePath = expand(argIter.next() ?? storePath)
    case "--socket": socketPath = expand(argIter.next() ?? socketPath)
    case "--once": runOnce = true
    case "--replay": replay = Int64(argIter.next() ?? "0") ?? 0
    case "--verbose", "-v": verbose = true
    case "--help", "-h":
        print("""
        usage: notiwatchd [--config PATH] [--store PATH] [--socket PATH] [--source PATH]
                          [--once] [--replay N] [--verbose]
          --once      drain new notifications and exit
          --replay N  rewind high-water mark by N records (testing)
        """)
        exit(0)
    default:
        warn("unknown argument: \(arg)")
        exit(2)
    }
}

guard FileManager.default.isReadableFile(atPath: sourcePath) else {
    warn("""
    cannot read \(sourcePath)
    Grant Full Disk Access to this binary (System Settings > Privacy & Security \
    > Full Disk Access), or run from a terminal that has it.
    """)
    exit(1)
}

let configStore = ConfigStore(path: configPath)
guard let store = Store(path: storePath) else {
    warn("cannot open store \(storePath)")
    exit(1)
}
let source = SourceDB(path: sourcePath)
let mainQueue = DispatchQueue(label: "notiwatchd.main")
let server = runOnce ? nil : SocketServer(path: socketPath)

// High-water mark: first run starts at current max (no backlog spam).
var highWater: Int64
if let saved = store.stateGet("high_water"), let value = Int64(saved) {
    highWater = value
} else {
    highWater = source.maxRecID() ?? 0
    store.stateSet("high_water", String(highWater))
    log("first run: high-water initialized to rec_id \(highWater)")
}
if replay > 0 {
    highWater = max(0, highWater - replay)
    log("replay: high-water rewound to \(highWater)")
}

@Sendable func processRow(_ row: SourceRow, cfg: Config) {
    var bundleID = row.identifier ?? "unknown"
    var title: String?
    var subtitle: String?
    var body: String?
    var rawJSON: String?

    if let data = row.data,
       let plist = (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil))
        as? [String: Any] {
        if let app = plist["app"] as? String { bundleID = app }
        if let req = plist["req"] as? [String: Any] {
            title = req["titl"] as? String
            subtitle = req["subt"] as? String
            body = req["body"] as? String
            var rawReq = req.filter { $0.value is String || $0.value is NSNumber }
            rawReq["app"] = bundleID
            if let data = try? JSONSerialization.data(withJSONObject: rawReq, options: [.sortedKeys]) {
                rawJSON = String(data: data, encoding: .utf8)
            }
        }
    }

    let rule = matchRule(configStore.config.rules ?? [], bundleID: bundleID,
                         title: title, subtitle: subtitle, body: body)
    let actions = rule?.actions ?? configStore.config.defaultActions ?? ["log"]
    let deliveredUnix = (row.deliveredDate ?? row.requestDate).map { $0 + appleEpochOffset }

    let event = Event(recID: row.recID, uuid: row.uuid, bundleID: bundleID,
                      title: title, subtitle: subtitle, body: body,
                      deliveredAt: deliveredUnix, presented: row.presented, style: row.style,
                      rule: rule?.name, urgency: rule?.urgency ?? "normal",
                      presenceRouting: rule?.presenceRouting ?? false, actions: actions)

    let ignored = actions.contains("ignore")
    if !ignored || verbose {
        let ruleName = rule?.name ?? "-"
        log("notif rec=\(row.recID) app=\(bundleID) rule=\(ruleName) " +
            "actions=\(actions.joined(separator: ",")) title=\(title ?? "-")")
    }

    server?.broadcast(event.json())

    var results: [String: String] = [:]
    let group = DispatchGroup()
    let resultsLock = NSLock()
    for action in actions where !ignored || action == "ignore" {
        group.enter()
        dispatchAction(action, event: event, cfg: cfg) { name, result in
            resultsLock.lock()
            results[name] = result
            resultsLock.unlock()
            if result != "ok" { warn("action \(name): \(result)") }
            group.leave()
        }
    }

    func resultsJSON() -> String? {
        resultsLock.lock()
        defer { resultsLock.unlock() }
        return (try? JSONSerialization.data(withJSONObject: results, options: [.sortedKeys]))
            .flatMap { String(data: $0, encoding: .utf8) }
    }

    if runOnce {
        group.wait()
        store.insert(event, raw: rawJSON, results: resultsJSON())
    } else {
        // Insert immediately, then patch in action results when sinks finish
        // (store access stays on mainQueue).
        let rowID = store.insert(event, raw: rawJSON, results: nil)
        group.notify(queue: mainQueue) {
            if let json = resultsJSON() { store.updateResults(rowID, json) }
        }
    }
}

func drain() {
    configStore.reloadIfChanged()
    if let maxID = source.maxRecID(), maxID < highWater {
        warn("source rec_id went backwards (\(highWater) -> \(maxID)); DB reset? re-anchoring")
        highWater = maxID
        store.stateSet("high_water", String(highWater))
        return
    }
    let rows = source.rows(after: highWater)
    guard !rows.isEmpty else { return }
    for row in rows {
        processRow(row, cfg: configStore.config)
        highWater = max(highWater, row.recID)
    }
    store.stateSet("high_water", String(highWater))
}

if runOnce {
    drain()
    exit(0)
}

// Debounced drain on WAL/db writes.
var pending: DispatchWorkItem?
func scheduleDrain() {
    pending?.cancel()
    let work = DispatchWorkItem { drain() }
    pending = work
    mainQueue.asyncAfter(deadline: .now() + 0.2, execute: work)
}

let walWatcher = FileWatcher(path: sourcePath + "-wal", queue: mainQueue) { scheduleDrain() }
let dbWatcher = FileWatcher(path: sourcePath, queue: mainQueue) { scheduleDrain() }
_ = (walWatcher, dbWatcher)

// Fallback poll.
let pollTimer = DispatchSource.makeTimerSource(queue: mainQueue)
let pollInterval = configStore.config.pollFallbackSeconds ?? 30
pollTimer.schedule(deadline: .now() + pollInterval, repeating: pollInterval)
pollTimer.setEventHandler { drain() }
pollTimer.resume()

// Signals.
signal(SIGHUP, SIG_IGN)
signal(SIGINT, SIG_IGN)
signal(SIGTERM, SIG_IGN)
var signalSources: [DispatchSourceSignal] = []
let hupSource = DispatchSource.makeSignalSource(signal: SIGHUP, queue: mainQueue)
hupSource.setEventHandler {
    configStore.reloadIfChanged(force: true)
    drain()
}
hupSource.resume()
signalSources.append(hupSource)
for sig in [SIGINT, SIGTERM] {
    let src = DispatchSource.makeSignalSource(signal: sig, queue: mainQueue)
    src.setEventHandler {
        log("exiting on signal \(sig)")
        exit(0)
    }
    src.resume()
    signalSources.append(src)
}

log("notiwatchd started (source=\(sourcePath), high-water=\(highWater))")
mainQueue.async { drain() }
RunLoop.main.run()
