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

An HTTP 200 from the app's `/tidewave` or `/tidewave/mcp` means it serves Tidewave, not that a browser is attached. `browser_eval` runs in a browser tab connected to the control page, `http://127.0.0.1:<PORT>/tidewave`; with none, it answers "No browser is connected to the Tidewave control page". Before calling it, open that page in Helium, the browser pidewave links over CDP (`bin/pidewave`, `home/.pi/agent/extensions/pidewave/`): `helium-launch http://127.0.0.1:<PORT>/tidewave`, wait for the tab to load, then call `browser_eval` with `{"action": "help"}`. A plain `open` hands the URL to Hammerspoon, which may pick another browser.

## Baton

While pi holds the worktree's baton (`pi-sessions`), only read-only calls pass the guard: listing, `get_logs`, `get_docs` and `get_source_location`. `project_eval`, `execute_sql_query` and the browser tools are blocked like any other writing tool.

## Tests

`home/.pi/tests/tidewave-ultimate.test.ts` (resolution, a fake Tidewave MCP server) and `pi-sessions-ultimate.test.ts` (the baton guard), run by `mise run check:ts`.
