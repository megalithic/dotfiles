import AppKit

/// The menu bar item: an icon with the waiting count beside it, and a menu that
/// breaks it down per host and Ultimate instance, with each instance's pinned
/// automations and their Pause/Resume and Run now. It never shows a window or a
/// notification; the count changes in place.
@MainActor
final class MenuBar: NSObject, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let refresh: () -> Void
    private let act: (Hub, Automation, String) -> Void
    private var needs: Needs?
    private var failure: String?
    /// The last automation change rtm refused or failed; cleared by the next one.
    private var actionFailure: String?
    /// Titles per hub in each submenu, oldest first.
    static let shown = 10

    init(refresh: @escaping () -> Void, act: @escaping (Hub, Automation, String) -> Void) {
        self.refresh = refresh
        self.act = act
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

    func failAction(_ message: String) {
        actionFailure = message
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
        if let actionFailure {
            menu.addItem(disabled("Not changed: \(actionFailure)"))
        }
        if let needs {
            menu.addItem(disabled("\(needs.total) waiting on you"))
            for group in needs.groups {
                menu.addItem(.separator())
                menu.addItem(disabled(group.host))
                for hub in group.hubs {
                    menu.addItem(item(for: hub))
                    for automation in hub.count == nil ? [] : hub.pinned {
                        menu.addItem(item(for: automation, in: hub, indent: 2))
                    }
                }
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
        let all = hub.automations ?? []
        guard !hub.inbox.isEmpty || !all.isEmpty || hub.automations_error != nil else { return item }
        // A row with a submenu only opens it, so the Inbox gets its own first row.
        let submenu = NSMenu()
        let inbox = NSMenuItem(title: "Open Inbox", action: #selector(open(_:)), keyEquivalent: "")
        inbox.target = self
        inbox.representedObject = hub.link()
        submenu.addItem(inbox)
        if !all.isEmpty || hub.automations_error != nil {
            let automations = NSMenuItem(title: "All automations", action: nil, keyEquivalent: "")
            let list = NSMenu()
            if let error = hub.automations_error {
                list.addItem(disabled("Unreadable: \(error)"))
            }
            for automation in all { list.addItem(self.item(for: automation, in: hub, indent: 0)) }
            automations.submenu = list
            submenu.addItem(automations)
        }
        if !hub.inbox.isEmpty { submenu.addItem(.separator()) }
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

    /// One automation: its state on the row, and its changes in a submenu.
    private func item(for automation: Automation, in hub: Hub, indent: Int) -> NSMenuItem {
        let item = NSMenuItem(title: automation.label(), action: nil, keyEquivalent: "")
        item.indentationLevel = indent
        item.toolTip = automation.error
        let image = NSImage(
            systemSymbolName: automation.pinned ? "pin.fill" : automation.attention ? "exclamationmark.circle" : "circle",
            accessibilityDescription: automation.state)
        image?.isTemplate = true
        item.image = image
        let changes = NSMenu()
        let toggle = automation.toggle
        changes.addItem(change(toggle.title, hub, automation, toggle.operation))
        changes.addItem(change(automation.runTitle, hub, automation, "run"))
        if let error = automation.error {
            changes.addItem(.separator())
            changes.addItem(disabled(error))
        }
        item.submenu = changes
        return item
    }

    private func change(_ title: String, _ hub: Hub, _ automation: Automation, _ operation: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(change(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = Change(hub: hub, automation: automation, operation: operation)
        return item
    }

    private final class Change: NSObject {
        let hub: Hub, automation: Automation, operation: String
        init(hub: Hub, automation: Automation, operation: String) {
            self.hub = hub; self.automation = automation; self.operation = operation
        }
    }

    @objc private func change(_ sender: NSMenuItem) {
        guard let change = sender.representedObject as? Change else { return }
        actionFailure = nil
        act(change.hub, change.automation, change.operation)
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
