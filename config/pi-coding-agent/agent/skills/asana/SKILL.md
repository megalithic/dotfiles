---
name: asana
description: Read and update Asana tasks (tickets) via API token or the logged-in browser session. Use when asked to review, summarize, audit, comment on, or update Asana tasks/subtasks, or when given an app.asana.com URL.
---

# Asana

CLI for the Asana REST API. Accepts full Asana URLs or bare task gids.

```bash
scripts/asana.mjs me                                  # auth sanity check
scripts/asana.mjs task <url|gid> [--fields a,b,c]     # task name/notes/status/assignee/…
scripts/asana.mjs subtasks <url|gid>                  # all subtasks, auto-paginated
scripts/asana.mjs stories <url|gid>                   # comments + activity log
scripts/asana.mjs comment <url|gid> <text>            # add a comment
scripts/asana.mjs update <url|gid> '{"name":"..."}'   # PUT arbitrary task fields
scripts/asana.mjs complete <url|gid> [true|false]     # toggle completion
scripts/asana.mjs api GET '/projects/123/tasks?opt_fields=name' [--all]
scripts/asana.mjs api POST '/tasks' '{"data":{...}}'  # raw passthrough
```

Output is pretty-printed JSON. `--all` on `api GET` follows `next_page` pagination
(`subtasks`/`stories` always do).

## Auth (resolved in order)

1. `$ASANA_ACCESS_TOKEN` — personal access token, direct API.
2. `~/.config/asana/token` (or `$ASANA_TOKEN_FILE`) — same, from file.
3. **Browser session proxy** — no token needed. Finds a Chromium-family browser
   (Helium/Chrome/Brave) running with `--remote-debugging-port`, locates an open
   logged-in `app.asana.com` tab, and evaluates `fetch()` inside that tab so the
   session cookies authenticate the request.
   - Port discovery: `$ASANA_CDP_PORT` → scan `ps` for `--remote-debugging-port=N` → probe 9222/9223.
   - `DevToolsActivePort` files can be stale; the process args are the source of truth.
   - Requires an Asana tab open. If missing, the script says so — ask the user to
     open Asana in that browser (do not navigate their tabs without asking).
   - Read AND write ops work. Writes require the `X-Allow-Asana-Client: 1`
     header (the script sends it automatically); without it cookie-session
     POST/PUT/DELETE return 401. If a write still fails, report the error and
     suggest setting up `ASANA_ACCESS_TOKEN`
     (create at https://app.asana.com/0/my-apps).
   - File attachments need multipart (`FormData`), which the script's JSON-only
     `api` passthrough doesn't do. Upload via CDP eval in the Asana tab:
     build a `File` from base64 bytes, `FormData` with `file` + `parent`
     (task gid), POST to `/api/1.0/attachments` with `X-Allow-Asana-Client: 1`
     and no explicit Content-Type.

## Recipes

Review subtasks of a ticket (e.g. "are these still relevant?"):

```bash
scripts/asana.mjs subtasks "https://app.asana.com/1/<ws>/home/task/<gid>" \
  | jq -r '.data[] | (if .completed then "[x] " else "[ ] " end) + .name + "  gid:" + .gid'
# then fetch notes for the interesting ones:
scripts/asana.mjs task <subtask-gid> --fields name,notes,completed
```

Summarize a ticket: `task` for name/notes, `stories` for discussion context.

Close a subtask with rationale:

```bash
scripts/asana.mjs comment <gid> "Closing: already implemented in core_components.ex"
scripts/asana.mjs complete <gid>
```

Useful `opt_fields`: `name,notes,completed,assignee.name,due_on,permalink_url,parent.name,num_subtasks,custom_fields.(name|display_value),memberships.project.name,tags.name`.

## Notes

- Task gid extraction handles `/task/<gid>` URLs, bare gids, and any long numeric id in the string.
- API docs: https://developers.asana.com/reference/rest-api-reference
- Mutating actions (comment/update/complete/DELETE): confirm with the user first
  unless they explicitly asked for the change.
