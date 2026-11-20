Lets agents use Tidewave MCP (logs, docs, Elixir eval, SQL, browser) of the Phoenix app their own worktree runs.

## Tool

`tidewave {}` lists the app's Tidewave tools with their input schemas; `tidewave {tool, args}` calls one and returns its text and images. Phoenix's Tidewave offers `get_logs`, `get_docs`, `get_source_location`, `project_eval`, `execute_sql_query`, `browser_eval` and `create_design_canvas`.

## Which app

There is no port or host argument. Each call finds the app by process (`lib.ts`):

1. The conversation's worktree: the git toplevel of its cwd.
2. The `beam.smp` processes whose cwd is that worktree (`lsof -c beam.smp -d cwd`), and the TCP ports only they listen on, lowest first. A port any other process also listens on is skipped, whatever the addresses: a more specific bind or an IPv4 listener beside a beam on `::1` would take the connection.
3. The first port that answers MCP at `http://127.0.0.1:<port>/tidewave/mcp` within 3 s; others (Erlang distribution, debuggers) are skipped. Redirects are refused, so a call never moves to another app or host.

So a conversation reaches only the app its own worktree runs, always on loopback: never another worktree's app, a remote host or production. lsof sees only this user's processes. With no app running it says so and names the worktree. Each call connects, calls and closes; a call times out after 10 minutes without progress.

## Browser

Open `http://localhost:<PORT>/tidewave/connect` in Helium:

```sh
open -a Helium http://localhost:<PORT>/tidewave/connect
```

Never use `127.0.0.1` for that page: the app's `allowed_origins` (`//*.localhost`) rejects it on `/ws`. App tabs on `*.localhost` also work. A plain `open` without `-a Helium` hands the URL to Hammerspoon, which may pick another browser. An HTTP 200 from the app isn't proof a browser is connected.

A connected browser isn't a session. Call `browser_eval` with `{"action":"help"}` to reserve one; it returns e.g. `Active session: quiet-zephyr#1`. Drive that session with `{"action":"eval","sid":"quiet-zephyr#1","action_inputs":{"code":"document.title"}}`.

### Toolbar routing and Inspect

The user-only `attach {conversation:number}` action links all Helium tabs of the conversation's app over CDP on port 9223. A Tidewave toolbar prompt copied in any linked app tab (including `admin.localhost`) becomes input to **that owning conversation**, queued as a follow-up if busy. It is framed `From Seth via the Tidewave toolbar on <tab url>:` and the page toasts `Sent to #<id>` or the delivery error. The toolbar's focus-pi action explains that Ultimate owns the app instead.

The user-only `inspect {conversation:number}` action attaches if needed, raises Helium and starts Inspect, returning `active` on success or an explanation. Both actions discover the app through the shared `bin/agents --json` registry; neither takes a port. A live pi lease takes precedence and is named in the error. Links detach on facet close/reload and are recreated for remembered conversations on open. A process restart forgets attachments.

Call either action through the owning Ultimate instance (replace the URL and conversation):

```sh
curl --fail-with-body http://127.0.0.1:4749/api/extensions/tidewave/actions/attach \
  -H 'Origin: http://127.0.0.1:4749' -H 'Content-Type: application/json' \
  --data '{"args":{"conversation":123}}'
```

Replace `attach` with `inspect` to start Inspect. The Origin must match the Ultimate server's loopback URL and port. `bin/pidewave inspect --port <PORT>` or `--cwd <PATH>` falls back to this action when no live pi lease matches, keeping one CDP owner per app. `--rex-block <BLOCK>` first tries pi's seat, then obtains the foreground process's cwd via `rex block call -b <BLOCK> process`; `--cwd` can also be supplied explicitly. `PIDEWAVE_AGENTS` overrides the sibling `agents` executable for offline CLI tests.

## Baton

While pi holds the worktree's baton (`pi-sessions`), only read-only calls pass the guard: listing, `get_logs`, `get_docs` and `get_source_location`. `project_eval`, `execute_sql_query` and the browser tools are blocked like any other writing tool.

## Tests

`home/.pi/tests/tidewave-ultimate.test.ts` (resolution, a fake Tidewave MCP server) and `pi-sessions-ultimate.test.ts` (the baton guard), run by `mise run check:ts`.
