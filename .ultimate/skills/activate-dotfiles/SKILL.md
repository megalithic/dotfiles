---
name: activate-dotfiles
description: Activate a landing that changed deployed dotfiles (home/.ultimate/**, home/.pi/**, config/**, bin/**) on this Mac and the other hubs, then report landed, pushed and active separately. Use after every such landing in ~/.dotfiles, and whenever someone asks to apply, deploy or activate dotfiles changes.
---

# Activate landed dotfiles

A landing is not active until its links are applied and every Ultimate that reads them has loaded the change.
Run the steps in order; record each step's result per host.

## 1. Links and settings: run the script

```bash
~/.dotfiles/.ultimate/skills/activate-dotfiles/activate [base]
```

`base` is the revision before the landing (default `main@{1}`, the previous `main`). It checks, one line each:

- **revision:** `main`, the landed sha, a `warn` listing dirty files. A dirty file an app wrote through its link
  (`home/.claude/settings.json`) is fine; anything else unlanded: stop and ask.
- **pushed:** whether `origin/main` contains `HEAD` (it fetches first).
- **changed:** the deployed files since `base`, with the `~/.ultimate` ones listed.
- **links:** `mise run update:dotfiles` (never `--force`), then `mise dotfiles diff` must say "all files are
  applied". On a refusal over an existing real file, compare it with the source, resolve it by hand, re-run, and
  report what you did.
- **settings:** re-creates the `~/.ultimate/settings.json` link; watchers miss edits to its target.
- **restart check:** printed when user-level Ultimate files changed. Exit status is 1 when any step failed.

## 2. Confirm Ultimate loaded it

For each changed `home/.ultimate` file, check the running host, not the file:

- `mcpServers`: `ultimate.action('mcp', 'status')` lists the server, connected.
- `extensions.enable`/`disable`, a user extension: `ultimate.extensions()` lists it (or not) with no load error,
  and its tools appear.
- An agent overlay (`agents/*.md`): `ultimate.agents()` shows the new instructions. Overlays usually load live.
- A skill: it appears in the skills list (the Info tab).

## 3. Restart only when needed

Restart when step 2 shows the change did not load (a new extension folder, `extensions.disable` never do), or the
Ultimate clone landed changes to `server/`, `shared/`, `patches/` or `pnpm-lock.yaml`. Use the `restart` tool, never
`POST /api/restart`. Afterwards repeat step 2: the extension listed without error, its tool present.

## 4. Other hubs

Only when the landing touched user-level `~/.ultimate` files:

- Other projects on this Mac (`ultimate.projects()` with a running instance): `ultimate.tell` their @ultimate to
  restart, `reply: false`.
- Other machines in `remotes` of `home/.ultimate/settings.json`: when the user wants that Mac updated, run the script
  there with a pull, then tell its @ultimate (`ultimate.tell({project: '.dotfiles', machine})`) to verify and restart:

  ```bash
  ssh <host> bash -s -- --pull < ~/.dotfiles/.ultimate/skills/activate-dotfiles/activate
  ```

  `bash -s` avoids the remote login shell (it may be fish); the script puts `~/.local/share/mise/shims` on `PATH`.
  An unreachable host is a result to report, not a reason to retry.

## 5. Report

Three states, each with evidence, never merged into one "done":

- **Landed:** the sha on `main`.
- **Pushed:** `origin/main` at or past it, or how many commits ahead `main` is.
- **Active:** per host, links applied and the change loaded (what you checked), restarted or not, or why not.
