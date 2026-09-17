---
name: asana
description: Asana is the source of truth for work tickets. Read/update Asana tasks, and run the Asana-first ticket workflow — link a worktree to Asana tasks, sync tk mirror tickets, decompose into local sub-task tickets, close out work. Use when asked to review, comment on, or update Asana tasks, when given an app.asana.com URL, or when starting/finishing ticket work in an Asana-linked repo.
---

# Asana

CLI for the Asana REST API plus the Asana-first ticket workflow. Accepts full
Asana URLs or bare task gids.

## Ticket model (Asana-first)

Asana tasks are the **official tickets**. tk is a per-worktree working layer:

```
Asana task(s)  ──linked via .tickets/.asana.json──▶  mirror tk tickets (read-mostly)
                                                          └── local sub-task tk tickets (your decomposition)
```

- **Mirror tickets** are plain tk tickets created by `link` (and recreated by
  `sync` if the file goes missing), keyed by `external-ref: asana-<gid>` and
  tagged `asana`. Asana wins their content; don't hand-edit them — if you do,
  sync preserves your edit and warns instead of updating that body until you
  reconcile.
- **Sub-task tickets** are normal tk tickets created with
  `tk create "..." --parent <mirror-id>`. They're local-only decomposition;
  each may become its own PR or just commits on the main ticket's PR.
  Completing a sub-task posts **nothing** to Asana — Asana only hears about
  work when the mirror closes via `sync --push`.
- Repos without `.tickets/.asana.json` have no Asana context: plain tk
  behavior, no Asana-based recommendations.

## Workflow commands

```bash
scripts/asana.mjs mine [--refresh]            # my open tasks (assignee OR "Developer" field), 24h cache
scripts/asana.mjs link [--branch b]           # link this worktree to Asana task(s)
scripts/asana.mjs link --gid <g> [--gid <g>]  # non-interactive link (after user picked)
scripts/asana.mjs sync                        # pull linked tasks -> mirror tickets
scripts/asana.mjs sync --push                 # ...and offer to complete Asana tasks (confirm-gated)
scripts/asana.mjs unlink <url|gid>            # remove link, keep mirror ticket
scripts/asana.mjs status                      # links, mirror status, orphans, cache age
```

Degradation: `mine`/`link` fall back to the stale cache with a warning when
Asana is unreachable (hard-fail only with no cache). `sync` needs live access;
per-task 404/403s mark that link `orphaned` and sync continues. Remote
reopen after a local close reopens the local mirror (Asana wins). `sync
--push` re-fetches right before completing and aborts on conflict.

### Hard rules for agents

1. **Never link silently.** Without `--gid`, `link` in a non-TTY prints
   candidates as JSON and exits 2. When that happens: present the candidates
   to the user with `ask_user_question` (multiSelect — multiple Asana tickets
   per worktree are allowed but must be user-confirmed), then re-run
   `link --gid <gid> [--gid <gid>...]`.
2. **Ask when matching is unsure.** If it's unclear which Asana ticket maps to
   this worktree/branch, or which local ticket corresponds to which Asana
   task, ask the user — never guess.
3. **Writes are confirm-gated.** `sync --push` prompts per task; only pass
   `--yes` when the user already approved completing those specific tasks.
4. **Sub-task closes stay local.** Don't comment progress to Asana when a
   sub-task ticket closes; the close-out recipe below handles Asana.

## Generic commands

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

Output is pretty-printed JSON. `--all` on `api GET` follows `next_page`
pagination (`subtasks`/`stories` always do).

## Auth (resolved in order)

1. `$ASANA_ACCESS_TOKEN` — personal access token, direct API. (Blocked by
   employer policy on work machines — expect the browser proxy.)
2. `~/.config/asana/token` (or `$ASANA_TOKEN_FILE`) — same, from file.
3. **Browser session proxy** — no token needed. Finds a Chromium-family browser
   (Helium/Chrome/Brave) running with `--remote-debugging-port`, locates an open
   logged-in `app.asana.com` tab, and evaluates `fetch()` inside that tab so the
   session cookies authenticate the request.
   - Port discovery: `$ASANA_CDP_PORT` → scan `ps` for `--remote-debugging-port=N` → probe 9222/9223.
   - `DevToolsActivePort` files can be stale; the process args are the source of truth.
   - Requires an Asana tab open. If missing, the script says so — **report this
     to the user and ask them to open Asana in that browser** (do not navigate
     their tabs without asking). All networked workflow verbs (`mine`,
     `link`, `sync`) need this; `status` and cache reads work offline.
   - Read AND write ops work. Writes require the `X-Allow-Asana-Client: 1`
     header (the script sends it automatically); without it cookie-session
     POST/PUT/DELETE return 401. If a write still fails, report the error.
   - File attachments need multipart (`FormData`), which the script's JSON-only
     `api` passthrough doesn't do. Upload via CDP eval in the Asana tab:
     build a `File` from base64 bytes, `FormData` with `file` + `parent`
     (task gid), POST to `/api/1.0/attachments` with `X-Allow-Asana-Client: 1`
     and no explicit Content-Type.

## Recipes

### Start work in a worktree (link)

```bash
scripts/asana.mjs status            # already linked?
scripts/asana.mjs link              # TTY: interactive picker; agent: candidates JSON + exit 2
# agent flow: ask_user_question with the candidates, then
scripts/asana.mjs link --gid 1211234567890123
```

### Decompose a linked ticket into sub-tasks

```bash
scripts/asana.mjs status                                  # find the mirror ticket id
tk create "Extract sync module" --parent dot-a1b2 -t task
tk create "Add bats tests for sync" --parent dot-a1b2
```

Keep sub-tasks small: own PR at most, often just commits on the mirror
ticket's PR.

### Daily sync / picking up remote changes

```bash
scripts/asana.mjs sync        # mirrors updated; remote-completed tasks close locally
```

### Close out a ticket

```bash
tk close <subtask-ids...>          # finish local sub-tasks (silent, local-only)
tk close <mirror-id>               # local mirror done
scripts/asana.mjs sync --push      # prompts: complete in Asana? [y/N]
scripts/asana.mjs comment <gid> "Shipped in PR #123"   # optional, ask user first
```

### Review a ticket's subtasks (Asana-native subtasks)

```bash
scripts/asana.mjs subtasks "https://app.asana.com/1/<ws>/home/task/<gid>" \
  | jq -r '.data[] | (if .completed then "[x] " else "[ ] " end) + .name + "  gid:" + .gid'
scripts/asana.mjs task <subtask-gid> --fields name,notes,completed
```

Summarize a ticket: `task` for name/notes, `stories` for discussion context.

Useful `opt_fields`: `name,notes,completed,assignee.name,due_on,permalink_url,parent.name,num_subtasks,custom_fields.(name|display_value),memberships.project.name,tags.name`.

## Notes

- Task gid extraction handles `/task/<gid>` URLs, bare gids, and any long numeric id in the string.
- Caches live in `~/.local/share/asana/` (`mine.json`, `tasks/<gid>.json`);
  the stop-hook reads only these + `.tickets/` — never the API.
- API docs: https://developers.asana.com/reference/rest-api-reference
- Mutating actions (comment/update/complete/DELETE, `sync --push`): confirm
  with the user first unless they explicitly asked for the change.
