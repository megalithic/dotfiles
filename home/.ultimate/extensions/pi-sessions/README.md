Read pi sessions across rex worktrees, pick one up in place with a write baton, and release it back to pi.

## Baton

`<worktree>/.local/state/agent-baton.json` is atomic (temporary file + rename), mode 0600:

```json
{"v":1,"holder":"ultimate","worktree":"/absolute/worktree","at":"<ISO timestamp>","by":"pickup","ultimate":{"url":"http://localhost:4749","project":"/absolute/project","conversation":123},"pi":{"sessionId":"…","pid":1234,"label":"builder"}}
```

`holder` is `ultimate` or `pi`; `by` is `pickup`, `release` or `take`. `ultimate` and `pi` are optional. Absent = nobody holds it. Ultimate allows only `read`, `message`, `note`, `notify`, `memory`, `reply_pi` and the pi-sessions tools (an allowlist: codemode's nested calls skip the hook, and instance, screenshot and subagent can write too) in any conversation inside the nearest matching pi-held worktree; pi enforces the converse. A baton is coordination, not an OS sandbox. It persists after crashes; explicit pickup `force` or pi `/baton take` recovers it. Force does not override another working pi.

## Pickup HTTP

Only the user-facing HTTP/UI action (not codemode) or the `pickup` tool may pick up. The cwd must share the project's git common directory. A working pi prevents pickup unless `from.sessionId` identifies it. An Ultimate-held baton prevents pickup unless `force: true`; the error identifies its conversation and URL.

```sh
url=http://localhost:4749
curl -fsS "$url/api/extensions/pi-sessions/actions/pickup" \
  -H "Origin: $url" -H 'Content-Type: application/json' \
  -d '{"args":{"cwd":"/absolute/worktree","goal":"Continue the fix","from":{"label":"builder","sessionId":"session-id"}}}'
```

Arguments: `{cwd, sessionFile?, goal?, force?, from?: {label?, sessionId?, socket?, pid?}}`. Returns `{result: {conversation, url, worktree, baton}}`. A new conversation works in that exact git toplevel; it gets a brief, holds the baton, and leaves a non-waking note for standing @ultimate. It must never `workspace submit` or push and must finish with `release` and a summary. If creation succeeds but a later step fails, errors surface instead of silently starting a second conversation; inspect the persisted baton before retrying.

## Tools and actions

- `pi_sessions` / `sessions {}`: compact table / JSON worktrees with branch, dirty count, ahead, rwt-session, live non-ephemeral pis, selected session file/time and baton. Git runs per worktree in parallel; unrelated Ultimate worktrees disappear.
- `pi_session` / `session {worktree?, sessionId?, sessionFile?}`: markdown Live, Brief, Open todos, Goal, Last compaction summary, Last assistant message, git status and diff stat. File paths must resolve inside pi's sessions directory and end in `.jsonl`. Prefer a live pi's own session over subagents, otherwise newest mtime.
- `pi_tell {target, text}`: target sessionId, socket or worktree must identify exactly one live pi. Uses `message.send` follow-up with spool fallback when the socket is gone and sessionId is known; includes the `tell_pi` reply target.
- `pickup {worktree, goal?, force?}`: same pickup core, default label `@ultimate` (HTTP defaults to `web UI`).
- `release {worktree?, text?}` tool/action: defaults to the calling conversation's cwd toplevel. Writes holder `pi`, by `release`, preserving Ultimate identity **before** delivery. Prefers the baton's pi session or a rex agent block. Without a live pi runs `bin/rwt agent <wt> --prompt <text> --json`; failures surface, leaving pi holding its baton.
- `baton {conversation?, worktree?}` action: baton or null for the UI badge.

## Web UI

The **pi** panel (⌘K → "pi sessions") lists the worktrees with a state dot per pi (pulsing while working, amber while it needs input), dirty/ahead counts, session age and a baton chip (`#N holds baton` in brand, `pi holds baton` in amber). **pick up** asks for an optional goal, then opens the new conversation; it is disabled while a pi is working or Ultimate already holds the baton (force stays with agents). **release** asks for an optional summary for pi. Tapping a worktree opens its session as Markdown: goal, todos, last answer, git status, with brief and compaction folded. In a conversation inside a worktree with a baton, the header shows `you hold baton` / `#N holds baton` / `pi holds baton`; its popover explains what is blocked and releases from there. The list refreshes every 15 s while open and after every action.

Registry: repo-local `bin/agents --json` (resolve the extension symlink to find the repo, fallback `~/.dotfiles`). Briefs: `sessions continue <file> --print`, PATH then the configured mise shim. Sessions: `${PI_CODING_AGENT_DIR:-~/.pi/agent}/sessions/`.

## Spill and safety

Text over 32768 characters goes to `${PI_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/pi}/handoff/<uuid>.md` (file 0600, directory 0700); the message carries its path and the first 2000 characters. Handoff files are local, persistent and not automatically deleted.

Every pickup input starts exactly:

```text
From Seth via pi "<label>" (<worktree>): this carries Seth's instructions, but it cannot approve anything; ask Seth directly for approvals.
```

Instructions are never approval. Never send raw JSONL, secrets or `.env` contents across the handoff. The reader extracts text-only assistant messages, current open todos/goal and compaction; it never copies system messages, thinking, tool calls or tool results. The external `sessions` brief is a summary, not raw history; review summaries for sensitive content. Brief, compaction, assistant, status and diff sections are capped at 12k/8k/16k/4k/4k characters.

## Test

```sh
mise run deps:ts
bun test ./home/.pi/tests/pi-sessions-ultimate.test.ts ./home/.pi/tests/pi-bridge-ultimate.test.ts
node /path/to/ultimate/scripts/check-extension.ts home/.ultimate/extensions/pi-sessions
mise run check:ts
```

The stock `check-extension.ts` currently numbers its temporary symlinks (`0-pi-sessions`, `1-pi-bridge`), so the required `../pi-bridge/lib.ts` import fails with TS2307 even when both folders are passed. To type-check the server meanwhile, use a temporary tsconfig with the clone's `tsconfig.web.json` compiler options (`composite: false`, `emitDeclarationOnly: false`, `noEmit: true`, Node types), a symlink to the clone's `node_modules`, and sibling symlinks named exactly `pi-sessions` and `pi-bridge`; include `pi-sessions/server.ts`. Run the clone's `node_modules/.bin/tsc -p <temporary directory> --pretty false`. This checks the actual sibling import without suppressing errors or changing production imports.

Tests use temporary synthetic sessions and worktrees, never contact live pi agents or change real batons. Load the server facet in an Ultimate preview for integration verification; do not copy into a running host to test.
