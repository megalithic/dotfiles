---
id: dot-l66f
status: closed
deps: 4:1:deps: [, dot-h8zv]
links: []
created: 2026-06-10T00:23:36Z
type: feature
priority: 2
assignee: Seth Messer
tags: [shade-next, ready-for-development, phase-2]
---

# shade-next .app bundle assembly (registered bundle id + URL scheme)

Add a build step that assembles shade-next into a proper macOS .app bundle so it has a registered bundle id (io.shade.next) and URL scheme (shade-next://). This unlocks: (a) hyper+enter launch via Hammerspoon launchOrFocusByBundleID, and (b) URL-scheme handling required by the dot-j262 remote-control work.

Mirror the proven pattern in current shade (justfile 'bundle' recipe): build the SwiftPM binary, create Contents/MacOS + Contents/Resources, copy the binary, copy the existing Resources/Info.plist (already declares CFBundleIdentifier io.shade.next, CFBundleExecutable shade-next, CFBundleURLTypes shade-next://, LSUIElement), write Contents/PkgInfo (APPL????), and register with lsregister so Launch Services knows the bundle id + scheme.

File hints: ~/code/shade-next/justfile (add 'bundle [config]' recipe), reuse ~/code/shade-next/Resources/Info.plist. Optionally an 'install' recipe to copy into a stable location. Keep current shade and its Shade.app untouched (different name/bundle id).

## Acceptance Criteria

1. A documented build step (e.g. just bundle) produces shade-next.app with Contents/MacOS/shade-next, Contents/Info.plist (bundle id io.shade.next, scheme shade-next://, LSUIElement), and Contents/PkgInfo.
2. The app launches from the bundle (open shade-next.app) and shows the menubar ghost + panel.
3. The bundle id resolves: launchOrFocusByBundleID(io.shade.next) finds it (after lsregister), so the Hammerspoon hyper+enter binding can launch/toggle it.
4. The URL scheme is registered (open 'shade-next://' targets the app), providing the hook dot-j262 builds on.
5. Current shade / Shade.app remain untouched.
6. Evidence: commands run + lsregister/registration check output.
