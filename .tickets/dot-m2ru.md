---
id: dot-m2ru
status: open
deps: [swi-f8tj]
links: [swi-f8tj]
created: 2026-09-18T15:59:47Z
type: bug
priority: 1
assignee: dotfiles
external-ref: swifties:swi-f8tj
tags: [avwatchd, jam, screen-capture, ready-for-development]
---
# Deploy and validate the avwatchd Jam Window capture fix

Owner: dotfiles runtime/integration maintainer (this repo). Swifties owns the implementation in avwatch/. This ticket owns approved deployment and whole-machine verification after swifties:swi-f8tj is closed with passing regression evidence. Do not implement an independent detector fix in the dotfiles copy.

Blocked by swifties:swi-f8tj at ~/code/swifties/.tickets/swi-f8tj.md. Inspect the upstream ticket for the root cause, fix commit/artifact, tests, and capture semantics before proceeding. tk does not resolve another repo's status automatically: leave the local dependency blocked until upstream completion is verified, then append the verified commit/test result and remove the external dependency with tk undep. Keep the reciprocal external reference for history.

Observed 2026-09-18 on workbookpro: Jam/Helium Entire screen start/stop detected as os-capture; three confirmed Window recordings never set sharing=true. Mic on/off worked. Window pause/resume retained microphone use and produced no presence change; this alone is not a pause bug. The user is done demonstrating; use saved evidence first and request a separate live retest only when a candidate fix is ready.

Evidence: ~/.local/share/pi/docs/.dotfiles/jam-avwatchd-20260918-103109/ and ~/.local/share/pi/docs/.dotfiles/jam-avwatchd-pause-20260918-113149/ (including observations.json).

Relevant paths: mise/scripts/setup-avwatchd, lib/build-swift, lib/avwatchd.swift, config/avwatchweb/, config/hammerspoon/watchers/avwatchd.lua, config/hammerspoon/lib/notifications/send.lua, and lat.md/programs/avwatchd.md. Running artifact: ~/.local/bin/avwatchd; service: dev.mise.com.megadots.avwatchd; socket: ~/.local/state/avwatchd/sock. Follow the source ownership/cutover boundary in ~/code/swifties/AGENTS.md. At ticket creation Swifties and dotfiles Swift sources match, but deployment has not been migrated by this ticket.

No implicit deployment approval: obtain Seth's explicit go-ahead before replacing the signed binary, restarting the service, or reloading Helium/Hammerspoon. Use bin/hs-reload if a Hammerspoon reload is required. Preserve a named known-good artifact and provide manual rollback instructions; do not auto-rollback or touch unrelated working-tree changes.

## Acceptance criteria

1. Verify swifties:swi-f8tj is closed with a fix commit/artifact and passing offline regression results. Record that handoff before removing the external blocker; avoid a divergent dotfiles-only source fix.
2. With explicit approval, deploy through the current mise/build-signing ownership path and verify the artifact identity, running LaunchAgent, native-host connection, protocol v2 socket, and idle baseline.
3. A newly agreed live test shows Jam Window capture start/active/stop correctly and clears sharing after stop within the upstream documented bound. Entire screen remains correct; canceling a picker or taking a screenshot does not create sustained sharing.
4. Verify Window and Entire screen pause/resume against actual stream lifetime, not recorder UI alone. Record microphone/camera toggle behavior where available and keep unsupported recorder-only states explicit.
5. Verify Hammerspoon receives matching sharing transitions and notification HUD suppression follows sharing; existing meeting, browser-tab sharing, playback, and miccheck integrations retain their behavior.
6. Run node config/avwatchweb/smoke-test.mjs plus scoped hk validation/checks for changed files. Update lat.md/programs/avwatchd.md with the confirmed behavior, source owner/sync direction, and deployment path; run lat check. Existing applicable checks pass.
7. Save a bounded validation report, stop all temporary monitors, and close only after live results satisfy the criteria. No further demo is required while work remains offline.

