import AppKit

/// The menu bar item: an icon with the waiting count beside it, and a menu that
/// breaks it down per host and Ultimate instance. It never shows a window or a
/// notification; the count changes in place.
@MainActor
final class MenuBar: NSObject, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let refresh: () -> Void
    private var needs: Needs?
    private var failure: String?
    /// Titles per hub in each submenu, oldest first.
    static let shown = 10

    init(refresh: @escaping () -> Void) {
        self.refresh = refresh
        super.init()
        let image = NSImage(systemSymbolName: "tray", accessibilityDescription: "Waiting on you")
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.imagePosition = .imageLeading
        menu.delegate = self
        statusItem.menu = menu
        render()
    }

    func update(_ needs: Needs) {
        self.needs = needs
        failure = nil
        render()
    }

    func fail(_ message: String) {
        failure = message
        render()
    }

    /// Fresh numbers each time the menu opens; it redraws when they arrive.
    func menuWillOpen(_ menu: NSMenu) { refresh() }

    private func render() {
        let title = failure == nil ? needs?.title ?? "" : "!"
        statusItem.button?.title = title.isEmpty ? "" : " \(title)"
        statusItem.button?.toolTip = failure ?? needs.map { "\($0.total) waiting on you" }
        menu.removeAllItems()
        if let failure {
            menu.addItem(disabled("rtm needs failed: \(failure)"))
        }
        if let needs {
            menu.addItem(disabled("\(needs.total) waiting on you"))
            for group in needs.groups {
                menu.addItem(.separator())
                menu.addItem(disabled(group.host))
                for hub in group.hubs { menu.addItem(item(for: hub)) }
            }
        }
        menu.addItem(.separator())
        // No Quit: Ultimate.app would start it again; it stops with the hub.
        menu.addItem(withTitle: "Refresh", action: #selector(refreshNow), keyEquivalent: "r").target = self
    }

    private func item(for hub: Hub) -> NSMenuItem {
        let item = NSMenuItem(title: hub.label, action: nil, keyEquivalent: "")
        item.indentationLevel = 1
        guard hub.count != nil else {
            item.toolTip = hub.error
            item.isEnabled = false
            return item
        }
        item.representedObject = hub.link()
        item.action = #selector(open(_:))
        item.target = self
        guard !hub.inbox.isEmpty else { return item }
        // A row with a submenu only opens it, so the Inbox gets its own first row.
        let submenu = NSMenu()
        let inbox = NSMenuItem(title: "Open Inbox", action: #selector(open(_:)), keyEquivalent: "")
        inbox.target = self
        inbox.representedObject = hub.link()
        submenu.addItem(inbox)
        submenu.addItem(.separator())
        for entry in hub.inbox.prefix(Self.shown) {
            let row = NSMenuItem(title: entry.title, action: #selector(open(_:)), keyEquivalent: "")
            row.target = self
            row.representedObject = hub.link(entry.key)
            row.toolTip = entry.detail
            submenu.addItem(row)
        }
        if hub.inbox.count > Self.shown {
            submenu.addItem(disabled("\(hub.inbox.count - Self.shown) more in the Inbox"))
        }
        item.submenu = submenu
        return item
    }

    private func disabled(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    @objc private func open(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSWorkspace.shared.open(url)
    }

    @objc private func refreshNow() { refresh() }
}
