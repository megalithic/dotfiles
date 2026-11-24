// UltimateMenu: Ultimate.app's menu bar count of what waits on the user across every
// Ultimate hub. It reads `rtm needs --json` (rtm owns the count) every 15 seconds and
// when its menu opens. Usage: UltimateMenu [--rtm <path>]; default mise's rtm shim,
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

    private nonisolated static func read(_ rtm: String) throws -> Needs {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [rtm, "needs", "--json"]
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
        return try Needs.decode(data)
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
        let menuBar = MenuBar { [weak self] in self?.poll() }
        self.menuBar = menuBar
        poll()
        let timer = Timer(timeInterval: 15, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.poll() }
        }
        // .common keeps polling while the menu is open.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
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
