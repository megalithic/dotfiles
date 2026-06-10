---
id: dot-j262
status: closed
deps: 4:1:deps: 4:1:deps: 4:1:deps: 4:1:deps: 4:1:deps: [, dot-e5sy, dot-ol5u, dot-xwa4, dot-6fon, dot-l66f]
links: []
created: 2026-06-10T00:13:23Z
type: feature
priority: 2
assignee: Seth Messer
tags: [shade-next, ready-for-development, phase-2]
---

# shade-next remote control: control socket + URL scheme for Pi/Hammerspoon (show/toggle/prefill/route/input)

Build a remote-control surface for shade-next so external tools (Pi and Hammerspoon) can drive it: launch/toggle visibility, prefill the input (optionally with a route prefix), read/replace the current input text, and trigger commit — without the user typing.

Two transports, mirroring how current shade already works (Unix-domain JSON-RPC socket at ~/.local/state/shade/shade.sock with show/toggle handlers in Sources/ShadeServer.swift) and shade-next's own dev identity:

1. Control socket: a Unix-domain socket at ~/.local/state/shade-next/shade-next.sock speaking line-delimited JSON-RPC. Methods (at minimum): show, hide, toggle, prefill {text, route?, focus?}, getInput, setInput {text}, commit, ping/version. This is what Pi uses to interact with the input itself (set/get text, commit) and what Hammerspoon can use for richer control than a URL.

2. URL scheme: extend the existing shade-next:// scheme (CFBundleURLTypes already declared) to handle launch+prefill, e.g. shade-next://prefill?text=...&route=pi&focus=1 and shade-next://toggle. This is the low-friction path for Hammerspoon bindAppChord-style launches that open the panel pre-filled.

Reuse existing pieces: PanelController.show/hide/toggle + onVisibilityChange (already added), Router for route prefixes, and the Nix-generated Hammerspoon fragment at ~/.local/share/hammerspoon/fragments/shade-next.lua. Keep Pi handoff safety from dot-e5sy intact (PiMirror has no submit effect; never auto-submit).

Security/safety: only bind a user-owned socket under the user state dir (0600), validate/escape URL params, and never auto-submit or auto-commit mutation routes without the existing confirmation hooks.

File hints: new Sources/ShadeNextApp/ControlServer.swift (or ShadeNextCore for the protocol), URL handling in the app delegate (application(\_:open:) / NSAppleEventManager kAEGetURL), wire into PanelController. Dotfiles: a small helper so Pi/Hammerspoon can send commands (e.g. a bin script or extend the fragment). Reference current shade Sources/ShadeServer.swift for the socket accept loop and handler-registry pattern.

## Design

Transport choice: line-delimited JSON-RPC over a Unix-domain socket is the proven pattern in current shade (handler registry keyed by method name). Mirror it for shade-next under its own state dir. The URL scheme is complementary: best for launch-and-prefill from Hammerspoon, while the socket is best for live interaction from Pi (get/set input, commit) on an already-running instance.

Open decisions for the implementer:

- exact JSON-RPC envelope (id/method/params vs simple {cmd,args}); prefer matching current shade for consistency
- whether the control protocol lives in ShadeNextCore (testable, headless) with a thin AppKit server in the app, like the SearchService/PiMirror split
- whether prefill replaces or appends to existing input, and whether focus is forced
- how commit interacts with route behavior (immediate vs requiresConfirmation vs handoff): commit over the socket must honor the same confirmation/no-auto-submit rules as the UI

## Acceptance Criteria

1. A control socket exists under ~/.local/state/shade-next/ (0600) speaking line-delimited JSON-RPC with at least: show, hide, toggle, prefill{text,route?,focus?}, getInput, setInput{text}, commit, ping/version.
2. From a shell/Pi, sending prefill opens (or focuses) the panel with the input pre-populated and routed correctly (e.g. route=pi expands the composer); getInput returns the current text; setInput replaces it.
3. shade-next:// URL scheme handles at least toggle and prefill (launching the app if needed), with params validated/escaped.
4. commit over the transport honors existing route safety: immediate (calc) may publish; mutation routes (note/reminder/event) require the same confirmation hooks; pi uses PiMirror and never auto-submits.
5. Protocol logic is unit-tested headlessly (e.g. request parsing/dispatch in ShadeNextCore); manual notes/commands show a live prefill + getInput round-trip.
6. A documented example shows Hammerspoon (or a bin helper) launching shade-next prefilled with input, and Pi setting/reading the input.
7. Current shade and its socket are untouched; shade-next uses its own socket path and bundle id.

## Notes

**2026-06-10T00:31:39Z**

Implemented: control socket (~/.local/state/shade-next/shade-next.sock, 0600) + shade-next:// URL scheme (show/hide/toggle/prefill) + commit wiring shared with Enter key. Verified live prefill/getInput/setInput/commit round-trips. Note: plain Enter commits (launcher convention); cmd+enter-specific binding can be revisited when multiline/Nvim composer lands. shade-next repo commit 9dba06e.
