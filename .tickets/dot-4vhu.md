---
id: dot-4vhu
status: closed
deps: []
links: []
created: 2026-09-01T12:23:37Z
type: feature
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Build Heimdall bridge from agent tools to extension slash-command behavior

Pi agents cannot invoke slash commands. Upstream Pi intentionally treats `sendUserMessage("/cmd")` as model input instead of command dispatch (earendil-works/pi #4754, closed "on purpose"); the `ExtensionAPI.executeCommand` request closed as not planned (#6010), and the official queued-command workaround is known broken (#6574). No published Pi package found during research exposed a generic command-to-tool bridge.

Heimdall works around that boundary. It is an extension-agnostic bridge that gives agents access to extension slash-command behavior by loading target extensions' exported factories, capturing selected `registerCommand` handlers, and invoking those exact handlers from agent tools. Heimdall is not a Plannotator integration with a reusable name. Plannotator is the first adapter and proof of the adapter contract.

Each adapter must preserve its target slash command's lifecycle, configuration, prompts, result routing, flags, session handling, and errors. Adapters must not reimplement command internals when the registered handler can be reused. A command that starts background work and returns immediately must remain non-blocking through Heimdall.

## Research and design

`@plannotator/pi-extension` exports its default Pi extension factory from `index.ts`. That factory registers `/plannotator-review`, `/plannotator-annotate`, and `/plannotator-last`. Those handlers already own browser startup, remote URL guidance, URL/live-app/file/folder handling, configured prompts, annotation outcome classification, recent-message targeting, cross-session feedback fallback, stopped-session handling, and asynchronous `pi.sendUserMessage(..., { deliverAs: "followUp" })` delivery.

Capturing and invoking those handlers gives stronger parity and less code than calling lower-level browser functions and copying handler logic. Heimdall loads the factory through a proxy `ExtensionAPI`:

- `registerCommand` captures command metadata and handlers.
- Other registration and lifecycle methods are suppressed so Heimdall does not duplicate the extension's tools, flags, shortcuts, providers, or event hooks. All common event-listener APIs are suppressed; adapters can selectively forward only lifecycle hooks required by captured commands.
- Runtime API calls made later by a captured handler delegate to Heimdall's real `ExtensionAPI`, including `sendUserMessage`, notifications, active tools, model state, and event emission.
- Adapters can isolate and restore target-specific process-global state changed during factory initialization.
- Required command names and the default factory export are validated before caching.

## Implementation

Path: `mise/config/pi-coding-agent/agent/extensions/heimdall/`, linked into `~/.pi/agent/extensions/` through the existing `symlink-each` mapping.

- `index.ts`: extension entry and adapter registration. Defines Heimdall as a generic command-behavior bridge and links to the Pi extension lat.md section.
- `lib.ts`: guarded Pi-package import, extension-factory command capture, event/registration suppression, selective lifecycle forwarding, factory-state isolation, runtime delegation, required-command validation, and text-result helpers.
- `plannotator.ts`: thin first adapter. It maps typed tool parameters to native command argument strings and invokes the captured handlers:
  - `plannotator_review` -> `/plannotator-review`.
  - `plannotator_annotate` -> `/plannotator-annotate`.
  - `plannotator_annotate_last` -> `/plannotator-last`.

The Plannotator adapter restores Plannotator's global current-session store after factory capture, then forwards only the first `session_start` and `session_shutdown` handlers which maintain background-feedback routing. It invokes commands through a context proxy that records native notifications while delegating them unchanged: error notifications become tool errors, and a tool reports `pending` only when Plannotator emitted an `opened` notification.

The Plannotator tools expose common structured arguments and `rawArgs` escape hatches for exact or future command syntax. `/plannotator-annotate` mapping includes path/folder/URL/live-app targets and `--gate`, `--json`, `--render-html`, `--markdown`, `--no-jina`, `--app`, and `--static`. `/plannotator-last` includes `--gate`. `/plannotator-review` includes PR URL, Git/GitButler selection, and local-checkout behavior.

User extensions cannot resolve Pi-installed npm packages by bare specifier because normal Node walk-up resolution never reaches `~/.pi/agent/npm/node_modules`. Heimdall lazily imports target extension factories by absolute path under Pi's jiti loader. Missing packages, missing default exports, factory initialization failures, and missing required command registrations return clear tool errors instead of crashing Pi startup.

## Risks

Heimdall depends on target extension factories remaining callable and registering commands during factory initialization. Required-command validation detects incompatible registration changes. Plannotator adapter was developed against `@plannotator/pi-extension` 0.27.9 and Pi 0.58.4.

A captured factory runs its initialization code through a registration-suppressing proxy. Future extensions with unavoidable initialization side effects need adapter-specific isolation, lifecycle forwarding, and review before addition. Typed argument serializers reject values their target parser cannot represent safely and direct callers to `rawArgs`.

## Acceptance criteria

1. `heimdall/index.ts`, `heimdall/lib.ts`, and `heimdall/plannotator.ts` load through `~/.pi/agent/extensions/heimdall/index.ts`.
2. Heimdall core comments and docs define an extension-agnostic slash-command behavior bridge; Plannotator appears only as its first adapter.
3. Heimdall captures required handlers from a target extension's exported default factory while suppressing duplicate registrations and lifecycle hooks.
4. Missing packages, default factories, required commands, or `pi.events` support return clear bridge behavior without crashing Pi startup.
5. A fresh or reloaded Pi session exposes `plannotator_review`, `plannotator_annotate`, and `plannotator_annotate_last`.
6. Each Plannotator tool invokes the corresponding captured command handler and returns when that handler returns; it reports `pending` only after Plannotator emits an `opened` notification and surfaces native startup/validation errors instead of false success.
7. Code-review feedback uses Plannotator's native configured prompts, denied suffix, remote-session guidance, stopped-session handling, and cross-session fallback.
8. File/folder/URL/live-app annotation uses Plannotator's native target resolution, flags, conversion, outcome prompts, background feedback, and error behavior.
9. Last-message annotation uses Plannotator's native gate flag, recent-message picker, selected-message targeting, anchoring, and cross-session fallback.
10. Structured tool parameters produce parser-compatible native command arguments; unrepresentable quoted targets return a clear `rawArgs` instruction, and `rawArgs` passes exact strings for unsupported or future syntax.
11. A fresh headless Pi run loads Heimdall and invokes a captured Plannotator command without extension-load or uncaught runtime errors.
12. `lat.md/programs/pi-coding-agent.md` documents command capture, generic adapter contract, and Plannotator parity; Heimdall code links back to that section and `lat_check` passes.

## Notes

**2026-09-02T13:07:33Z**

2026-09-01 final validation: reviewed Heimdall implementation against all 12 acceptance criteria. Fresh headless Pi run loaded Heimdall and exposed plannotator_review, plannotator_annotate, and plannotator_annotate_last. A fresh headless invocation of plannotator_annotate exercised the captured native handler; Plannotator returned its native file-not-found validation error with no extension-load or uncaught runtime errors. Symlink loading, command capture, registration/event suppression, lifecycle forwarding, factory-state isolation, required-command validation, native notification/error routing, structured argument serialization, and rawArgs escape behavior verified by code inspection. lat_check passed. All acceptance criteria satisfied.
