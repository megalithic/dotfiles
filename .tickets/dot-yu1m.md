---
id: dot-yu1m
status: open
deps: []
links: []
created: 2026-09-01T00:34:06Z
type: feature
priority: 2
assignee: Seth Messer
---
# notiwatchd: dismiss on-screen alerts/banners (Tahoe AX probe)

Implement the reserved 'dismiss' action in notiwatchd so rules can auto-hide still-visible notifications, especially persistent system alerts like BTM 'App Background Activity' (Login Items & Extensions) banners that sit on screen until manually closed. The usernoted DB is read-only for us; on-screen dismissal requires the Accessibility route. Tahoe changed the Notification Center AX tree (banners rendered by system SwiftUI; stacked notifications expose no recognized subrole - see PingPlace issue #44), so first write a probe script (.local_scripts/) that dumps the NC process AX tree while a persistent alert is visible to find the new element structure and close-button/AXPress path. Then implement: probably a small AX helper in the notiwatchd binary (needs Accessibility TCC grant in addition to FDA) or a helper the daemon execs. Persistent alerts (style=2) sit on screen indefinitely so no race; the daemon already knows bundle_id/title/body to target the right banner. Config already reserves actions:[\dismiss\] and logs unsupported-yet.

## Acceptance Criteria

1. AX probe documents Tahoe NC tree structure for banners and persistent alerts. 2. A rule with action 'dismiss' removes a visible BTM 'App Background Activity' alert from screen without user interaction. 3. Dismissal recorded in notifications.db action_results. 4. Accessibility grant documented in lat.md/programs/notiwatchd.md.
