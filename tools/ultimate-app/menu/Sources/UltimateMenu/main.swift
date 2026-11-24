// UltimateMenu: Ultimate.app's menu bar count of what waits on the user across every
// Ultimate hub. It reads `rtm needs --json` (rtm owns the count) every 15 seconds and
// when its menu opens, and changes hub automations through `rtm automation`.
// Usage: UltimateMenu [--rtm <path>]; default mise's rtm shim,
// since launchd's PATH has no mise.
import AppKit

/// Runs `rtm needs --json` off the main thread and hands back the result.
@MainActor
final class Poller {
    private let rtm: String
    private let queue = DispatchQueue(label: "com.megadots.ultimate.menu.poll")
    /// Main-actor state: a poll asked for while one runs shares its answer.
    private var running = false

    init(rtm: String) { self.rtm = rtm }

    func poll(_ done: @escaping @MainActor (Result<Needs, Error>) -> Void) {
        guard !running else { return }
        running = true
        queue.async { [rtm] in
            let result = Result { try Self.read(rtm) }
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    self.running = false
                    done(result)
                }
            }
        }
    }

    /// `rtm automation <url> <id> <name> <operation>`: rtm refuses when the id now names another automation.
    func act(_ hub: Hub, _ automation: Automation, _ operation: String,
             _ done: @escaping @MainActor (Error?) -> Void) {
        let arguments = ["automation", hub.url, automation.id, automation.name, operation]
        queue.async { [rtm] in
            let result = Result { try Self.rtm(rtm, arguments) }
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    if case .failure(let error) = result { done(error) } else { done(nil) }
                }
            }
        }
    }

    private nonisolated static func read(_ rtm: String) throws -> Needs {
        try Needs.decode(Self.rtm(rtm, ["needs", "--json"]))
    }

    private nonisolated static func rtm(_ rtm: String, _ arguments: [String]) throws -> Data {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [rtm] + arguments
        let out = Pipe(), err = Pipe()
        process.standardOutput = out
        process.standardError = err
        try process.run()
        let data = out.fileHandleForReading.readDataToEndOfFile()
        let message = err.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw PollError(String(decoding: message, as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return data
    }
}

struct PollError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description.isEmpty ? "rtm exited non-zero" : description }
}

@MainActor
final class App: NSObject, NSApplicationDelegate {
    private let poller: Poller
    private var menuBar: MenuBar?
    private var timer: Timer?

    init(rtm: String) { poller = Poller(rtm: rtm) }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let menuBar = MenuBar(refresh: { [weak self] in self?.poll() }) { [weak self] hub, automation, operation in
            self?.act(hub, automation, operation)
        }
        self.menuBar = menuBar
        poll()
        let timer = Timer(timeInterval: 15, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.poll() }
        }
        // .common keeps polling while the menu is open.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    /// The serial queue runs the change before the next read, so the menu shows its result.
    private func act(_ hub: Hub, _ automation: Automation, _ operation: String) {
        poller.act(hub, automation, operation) { [weak self] error in
            if let error { self?.menuBar?.failAction("\(automation.name): \(error)") }
            self?.poll()
        }
    }

    private func poll() {
        poller.poll { [weak self] result in
            switch result {
            case .success(let needs): self?.menuBar?.update(needs)
            case .failure(let error): self?.menuBar?.fail("\(error)")
            }
        }
    }
}

var arguments = Array(CommandLine.arguments.dropFirst())
// $HOME like the launcher's hub script, not the account's home directory.
var rtm = (ProcessInfo.processInfo.environment["HOME"] ?? NSHomeDirectory()) + "/.local/share/mise/shims/rtm"
if arguments.first == "--rtm", arguments.count == 2 {
    rtm = arguments[1]
    arguments.removeAll()
}
guard arguments.isEmpty else {
    FileHandle.standardError.write(Data("usage: UltimateMenu [--rtm <path>]\n".utf8))
    exit(64) // EX_USAGE
}

MainActor.assumeIsolated {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    let delegate = App(rtm: rtm)
    app.delegate = delegate
    app.run()
}
