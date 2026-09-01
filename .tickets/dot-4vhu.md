---
id: dot-4vhu
status: open
deps: []
links: []
created: 2026-09-01T12:23:37Z
type: feature
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Build heimdall bridge extension exposing plannotator browser sessions as agent tools

Problem: pi agents cannot invoke slash commands. Upstream pi (earendil-works/pi) intentionally blocks it: sendUserMessage("/cmd") from a tool sends plain text to the model instead of dispatching the command (issue #4754, closed 'on purpose'); ExtensionAPI.executeCommand feature request closed not_planned (#6010); the official reload-runtime.ts example is known-broken (#6574). No published pi-package extension bridges commands to tools (~250 npm packages scanned). Result: when told 'send this doc to plannotator', agents shell out to the plannotator CLI binary and build broken watcher/sleep loops that time out.

Key research finding: plannotator does not need command dispatch at all. @plannotator/pi-extension ships TS source with exported, ctx-driven session functions in plannotator-browser.ts, and its existing plannotator_submit_plan tool proves browser sessions open fine from a plain agent tool (ExtensionContext is sufficient; only ctx.reload()/newSession() need command context, which plannotator flows never use).

Verified exports in ~/.pi/agent/npm/node_modules/@plannotator/pi-extension/plannotator-browser.ts:

- openCodeReview(ctx, options: CodeReviewOptions = {}) -> Promise<CodeReviewDecision>  (awaits waitForDecision internally; options: prUrl, vcsType, useLocal)
- startCodeReviewBrowserSession(ctx, options) -> BrowserDecisionSession<CodeReviewDecision>
- openMarkdownAnnotation(ctx, filePath, markdown, mode: AnnotateMode, folderPath?, sourceInfo?, sourceConverted?, gate?) -> Promise<{feedback, exit?, approved?, ...}>  (caller reads the markdown file content itself)
- openLastMessageAnnotation(ctx, lastText, gate?, recentMessages?) -> same decision shape
- AnnotateMode = 'annotate' | 'annotate-folder' | 'annotate-last' | 'annotate-app'
- Arg parsing for review lives in ./generated/review-args.ts (parseReviewArgs) if we want CLI-style parity, but tool params should be a typed schema instead.
- Sessions throw if !ctx.hasUI or built HTML missing — surface as tool error text, do not crash.

Build: new extension dir mise/config/pi-coding-agent/agent/extensions/heimdall/ (symlink into ~/.pi/agent/extensions/ like siblings — see existing symlink pattern in that dir, e.g. tell.ts, bridge.ts).

Structure:

- heimdall/index.ts — extension entry: guarded dynamic import of @plannotator/pi-extension internals; if import fails (package missing/incompatible after version bump), register nothing or register tools that return a clear 'plannotator extension incompatible with heimdall' error; never crash session startup.
- heimdall/lib.ts — shared glue for future adapters: error wrapping, decision->tool-result formatting (feedback text + approved flag in details), import guard helper.
- heimdall/plannotator.ts — adapter registering agent tools:
  1. plannotator_review: params {prUrl?: string, vcsType?: 'git'|'gitbutler', useLocal?: boolean}. Calls openCodeReview, awaits decision, returns feedback/annotations as tool result. Description must tell the model when to use it (current changes, commit range, PR URL, branch review).
  2. plannotator_annotate: params {path: string (md/mdx file or folder)}. Reads file content, calls openMarkdownAnnotation with mode 'annotate' (or 'annotate-folder' for dirs), awaits decision, returns feedback as tool result.
  3. plannotator_annotate_last: no params. Uses getLastAssistantMessageText export (re-exported from plannotator-browser.ts line 49) + openLastMessageAnnotation.

Design decisions already made:

- Await the decision inside the tool call (blocking the turn) so user feedback returns directly as the tool result to the invoking agent — mirrors plannotator_submit_plan UX; no watcher/polling.
- Thin adapter-per-target pattern, NOT declarative config — signatures differ too much across extensions. lib.ts is the only shared layer. Future targets = new adapter file.
- Skills are out of scope: markdown, no functions; agent already invokes them natively.

Risks: adapter couples to plannotator internal exports (not a documented contract; package ships TS source). Import guard is the mitigation. Currently installed: @plannotator/pi-extension 0.27.9, pi 0.58.4.

Follow-up (separate, optional): upstream issue/PR to backnotprop/plannotator proposing first-class opt-in agent tools for review/annotate.

## Acceptance Criteria

1. New extension at mise/config/pi-coding-agent/agent/extensions/heimdall/ with index.ts, lib.ts, plannotator.ts; symlinked into ~/.pi/agent/extensions/ following the existing symlink pattern
2. In a fresh pi session, tools plannotator_review, plannotator_annotate, plannotator_annotate_last appear in the tool list
3. Agent calling plannotator_review with no params opens the code review browser UI for current changes; submitting feedback in the UI returns that feedback as the tool result (verify with a test prompt like 'open a plannotator review of my unstaged changes')
4. Agent calling plannotator_annotate with a markdown file path opens the annotation UI; annotations come back as the tool result
5. plannotator_review accepts prUrl and forwards it (PR mode)
6. With @plannotator/pi-extension renamed/removed temporarily, pi session still starts cleanly and heimdall tools (if registered) return a clear incompatibility error instead of throwing
7. Tool calls in a session without UI (pi -p / RPC without hasUI) return the plannotator 'unavailable in this session' error as tool result text, no crash
8. lat.md/ updated if it documents pi extension layout; lat check passes if docs changed
