---
name: activate-dotfiles
description: Activate a landing that changed deployed dotfiles (home/.ultimate/**, home/.pi/**, config/**, bin/**) on this Mac and the other hubs, then report landed, pushed and active separately. Use after every such landing in ~/.dotfiles, and whenever someone asks to apply, deploy or activate dotfiles changes.
---

# Activate landed dotfiles

A landing is active on a host only when its links are applied and every Ultimate instance that reads the changed
files has been observed to load them. Observe; never assume either way. Linked user extensions, overlays and skills
usually reload live, but not always: an instance gets restarted only when it shows it did not reload.

## 1. Links and settings: run the script

```bash
~/.dotfiles/.ultimate/skills/activate-dotfiles/activate [base]
```

`base` is the revision before the landing (default `main@{1}`, the previous `main`). It prints one line each:

- **revision:** `main`, the landed sha, a `warn` listing dirty files. A dirty file an app wrote through its link
  (`home/.claude/settings.json`, `home/.pi/agent/settings.json`) is fine; anything else unlanded: stop and ask.
- **pushed:** whether `origin/main` contains `HEAD` (it fetches first).
- **changed:** the deployed files since `base`, then one `ult` line per changed `~/.ultimate` file with its commit
  time. A change to `mise/templates/ultimate/settings.json` counts as `~/.ultimate/settings.json`.
- **links:** `mise run update:dotfiles` (never `--force`), then `mise dotfiles diff` must say "all files are
  applied". On a refusal over an existing real file, compare it with the source, resolve it by hand, re-run, and
  report what you did.
- **settings:** when the repo has `mise/scripts/render-ultimate-settings`, it renders `~/.ultimate/settings.json`
  from `mise/templates/ultimate/settings.json` (fails, leaving the file as it was, when Tailscale is missing or logged
  out; edit the template, never the rendered file). Without it, `~/.ultimate/settings.json` must equal
  `home/.ultimate/settings.json`.
- **observe:** printed when `~/.ultimate` files changed: step 2 is due. Exit status is 1 when any step failed.

## 2. Observe what each instance loaded

User-level `~/.ultimate` files are read by every Ultimate instance on the Mac, not only this hub. For each `ult`
line, check this hub, then every other running instance (`ultimate.projects()` entries with `running`):

- **Extension** (`extensions/<name>/`): its `ultimate.extensions()` entry has `server.loadedAt` later than the
  commit time, no load or server error, and the feature present (its tool in `server.tools`, its action in
  `actions`, its panel or command in the UI).
- **Settings** (`extensions.enable`/`disable`, `mcpServers`, `remotes`): the extension listed with `enabled` as set,
  `ultimate.action('mcp', 'status')` showing the server connected, the remote listed.
- **Agent overlay** (`agents/*.md`): `ultimate.agents()` shows the new instructions in that definition.
- **AGENTS.md, skills:** the new text is in your next turn's system prompt (`project_instructions`, `available_skills`),
  or a newly started branch's.

For another instance on this Mac, @ultimate sends `ultimate.tell({project: <name>, text, reply: true})` (a branch
asks @ultimate to relay): list the
changed files with commit times and ask it to report, per file, `loadedAt`, any load error and whether the feature
is present. Do not tell it to restart.

## 3. Restart only an instance that did not reload

Restart an instance only when step 2 shows it did not load a change (`loadedAt` older than the commit, the feature
missing), or when the Ultimate clone landed changes to `server/`, `shared/`, `patches/` or `pnpm-lock.yaml`. This
hub: the `restart` tool, never `POST /api/restart`. Another instance: ask its @ultimate to restart itself. Then repeat
step 2 for that instance.

## 4. Health check (always, on every instance you checked)

- `ultimate.agents().errors` is empty, and `projectSetup` is `trusted`.
- No `ultimate.extensions()` entry has a load or server error.
- `ultimate.action('mcp', 'status')`: every server `connected`, except a known missing secret already in the Inbox.

Any failure: find the cause before reporting. Code newer than the running host means restart and re-check; a missing
secret or login goes to the user's Inbox; anything else is a bug for a branch. Never report a landing active over a
load error.

## 5. Visible checks

A check Seth would see (a test toast, a panel opening, a sound) runs only while he is idle:
`ioreg -c IOHIDSystem | awk '/HIDIdleTime/ {print int($NF/1e9); exit}'` at 300 seconds or more. Otherwise put it in
his Inbox as a step with what he should see.

## 6. Other machines

Other Macs in `remotes` (of `mise/templates/ultimate/settings.json`, or `home/.ultimate/settings.json` before the
template exists): only when the user wants that Mac updated. Run the script there with a pull, then ask its
@ultimate (`ultimate.tell({project: '.dotfiles', machine, reply: true})`) to do steps 2 to 5 for its instances and
report:

```bash
ssh <host> bash -s -- --pull < ~/.dotfiles/.ultimate/skills/activate-dotfiles/activate
```

`bash -s` avoids the remote login shell (it may be fish); the script puts `~/.local/share/mise/shims` on `PATH`.
An unreachable host is a result to report, not a reason to retry.

## 7. Report

Three states, never merged into one "done":

- **Landed:** the sha on `main`.
- **Pushed:** `origin/main` at or past it, or how many commits ahead `main` is.
- **Active:** per machine and per instance: links applied, each changed file loaded (`loadedAt`, feature seen),
  restarted or not and why, visible checks done or in the Inbox. Then who acts next, on which machine.
