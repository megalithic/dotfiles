---
name: jam-demo
description: Record a captioned demo video of the Strive Provider Portal (provider_portal / rx Phoenix dev app, main checkout or any worktree) from a natural-language prompt and upload it to jam.dev. Turns the prompt into a step script, drives the app through Tidewave browser_eval with vision-mode recording (burned-in overlay captions, no audio), transcodes the WebM to H.264 with ffmpeg, uploads it with the Jam CLI into the "Demos (Seth)" Jam folder, and reports the share link plus any DB side effects. Holds a global recorder lock so only one pi instance records at a time. Use when asked to "record a demo", "make a jam of X", "jam demo", "demo video of the X flow", "record X for stakeholders", or "show X in a video", and when a message starts with "jam-demo:" (recorder waiting/available hand-offs).
---

# Jam demo — prompt to captioned jam.dev video

- **Capture:** Tidewave vision mode records the app iframe to WebM
  (`browser.startRecording` / `stopRecording`). `browser.overlay(text)` burns a
  subtitle into the video, and `click`/`fill` are animated. Captions replace
  narration; there is no audio.
- **Upload:** ffmpeg transcodes the WebM to a 1920-wide H.264 MP4, and the Jam
  CLI (`jam create jam`) uploads it as a video Jam and prints the share URL.
- **Never drive the Jam browser extension.** It injects nothing until a real
  user gesture, accepts messages only from `*.jam.dev`, and its shortcuts ignore
  synthetic key events.

`help` does not list the recording API. It exists only while vision mode is on:
`startRecording({description, sfx, narration})`, `stopRecording()`,
`abortRecording()`, `overlay(text)`, `zoom(scale, locator?)`, `screenshot()`,
`saveScreenshot()`.

## Prerequisites

- Phoenix dev server running for this checkout (port `$PHX_PORT`; the main
  checkout uses 4000) and Tidewave MCP reachable.
- Helium is the Tidewave-connected browser. The `chrome-cdp` skill reaches it
  (script: `~/.pi/agent/skills/chrome-cdp/scripts/cdp.mjs`).
- Jam CLI comes from mise: the main checkout's `.config/mise.local.toml` pins
  `http:jam`, and worktrees inherit it. Always call it as `mise exec -- jam …`.
  `mise exec -- jam auth status` must show a login. If not, run
  `mise exec -- jam auth login` through `interactive_shell` (hands-free) and
  have the user approve the OAuth page.
- Jam folder "Demos (Seth)" has short ID `ymfx`. Pass the ID, not the name;
  folder names are not unique.

## Dev DB fixtures

These rows live in the main checkout's database (`rx_dev`, port 4000). Each
worktree has its own port, database (`rx_dev` plus a worktree suffix), and
`tmp/tidewave/recordings/`, so check its fixtures with `project_eval` there and
ask before changing any rows. In the main checkout, use these rows freely and
ask before touching any other row.

| Row | State |
|---|---|
| User 99 `csv.tester@example.com` / `CsvTester!2345678` | Practice Manager, `onboarding_status: :prescriber_enrollment_submitted`, email verified, pending invitation (provider 23) so `/invitations` renders |
| Practice 10 "CSV Test Clinic" | `verification_status: :verified`, no `lf_practice_id` |
| Provider 20 | `:rejected`, note "No active state medical license found for this NPI." |
| Provider 21 / 22 | `:pending` / `:verified` |
| Provider 23 | invitation pending, NPI `1626129518` |
| Provider 24 | practice 1, user 99, invitation pending; Seth approved it for multi-invitation demos |

Accepting on `/invitations` writes:
- `license_review_consented_at` and `invitation_accepted_at` on each pending
  provider (23, 24)
- `users.invitation_accepted_at` for user 99
- a Physician `user_practice_roles` row for each invited practice (10, 1)

The role rows are outside this scope, so ask first. Afterwards, restore to
the baseline: user 99 holds only role row 25 (Practice Manager, practice 10),
and every timestamp above is nil.

## Script format (prompt → script)

Translate the prompt into this script and show it to the user. Wait for approval
only when a step writes data; otherwise go on to rehearsal.

This is the script behind the proof demo in the "Demos (Seth)" folder:

```yaml
title: Enrollment invitation page        # Jam title
path: /invitations                       # start page, loaded before recording
viewport: [1440, 900]                    # CSS px; the video matches it
db:                                      # project_eval snippets; null when unused
  assert: "Rx.Accounts.Invitations.pending(Rx.Repo.get!(Rx.Accounts.User, 99)) |> Enum.map(& &1.id) == [23]"
  seed: null                             # read-only demo
  restore: null                          # nothing is submitted
steps:
  - caption: An invited provider opens their Strive Provider Portal enrollment invitation
    do: wait 1500
  - caption: The heading names the practice that sent the invitation
    do: zoom 1.8 '#invitations-heading'
  - caption: The page shows their login email and the NPI the practice invited
    do: zoom 1.8 '#practice-invitations'
  - caption: They confirm the details and consent to a license and NPI review
    do: zoom 1, click 'input[type="checkbox"][name="user[license_review_consent]"]'
  - caption: Accepting adds them to CSV Test Clinic as a Physician
    do: zoom 1.6 '#invitation-accept'
  - caption: Demo stops before submitting, so the invitation stays pending
    do: zoom 1, wait 5000
```

A demo that needs a fixture put back in place uses `seed` and `restore`. For
example, to record the STEP 3 rejected-provider row with a fresh note, then
return provider 20 to its fixture state:

```yaml
db:
  assert: "Rx.Repo.get!(Rx.Providers.Provider, 20).practice_id == 10"
  seed: "Rx.Repo.get!(Rx.Providers.Provider, 20) |> Ecto.Changeset.change(verification_status: :rejected, verdoc_note: \"License expired 2026-09-30.\") |> Rx.Repo.update!()"
  restore: "Rx.Repo.get!(Rx.Providers.Provider, 20) |> Ecto.Changeset.change(verification_status: :rejected, verdoc_note: \"No active state medical license found for this NPI.\") |> Rx.Repo.update!()"
```

Rules:

- One caption per action. Write it in the present tense from the viewer's side
  ("The provider sees…"), in at most ~80 characters so it stays on one line.
- Each caption stays up about 5 seconds whatever its length. `overlay()`
  returns at once, and the next `overlay()` waits for the current one to finish,
  so each action runs while its caption is on screen.
- Open with an establishing caption on the start page. Close with a summary
  caption followed by `wait 5000`, because `stopRecording()` does not wait for
  the last caption.
- Use selectors that survive reloads: IDs, `name` attributes, and
  `browser.locator(css, {hasText})`. Never use snapshot refs.
- Put at most ~8 steps in one tool call. Split longer scripts across calls; the
  recording pauses between them and may total 5 minutes.
- Add a step that writes data only when the prompt asks for it. List the rows
  it touches.

Map each step to `await browser.overlay(caption);` followed by its action:

| `do` | Code |
|---|---|
| `navigate P` | `await browser.reload(P);` then the hide-toolbar snippet |
| `click S` | `await browser.click(browser.locator(S));` |
| `fill S V` | `await browser.fill(browser.locator(S), V);` (typed per character) |
| `scroll S` | `await browser.eval((el) => el.scrollIntoView({ behavior: 'smooth', block: 'center' }), [browser.locator(S)]); await browser.wait(800);` |
| `zoom N S` | `await browser.zoom(N, browser.locator(S));` (`zoom 1` resets, ~0.7 s) |
| `wait MS` | `await browser.wait(MS);` |

Hide-toolbar snippet. Run it after every `reload()`; the Tidewave toolbar
otherwise shows in the video. It injects about a second after load, so the
snippet waits for it. An injected `<style>` tag does nothing here: the app's CSP
(`default-src`, no `'unsafe-inline'`) blocks it, so set the inline style:

```js
await browser.eval(async () => { let t = null; for (let i = 0; i < 40 && !(t = document.getElementById('tidewave-toolbar')); i++) await new Promise((r) => setTimeout(r, 100)); if (t) t.style.setProperty('display', 'none', 'important'); });
```

## Workflow

### 1. Connect Tidewave

Call `mcp__tidewave__browser_eval` with `action: "help"` and read the active
`sid`. If no browser is connected:

1. `open http://localhost:$PHX_PORT/tidewave/connect`. Never open bare
   `/tidewave`.
2. Wait with one `mcp__tidewave__project_eval` call:
   `Enum.find_value(1..200, fn _ -> Tidewave.BrowserSessions.list_clients() != [] || (Process.sleep(50) && nil) end) || :timeout`.
   Report `:timeout` to the user instead of retrying.
3. `action: "new-session"`.

Sessions change whenever the browser drops, so re-read the `sid` after any
failure.

### 2. Claim the recorder

Only one recording may run at a time across every checkout and worktree.
All ports share one Helium window and one `_rx_key` login cookie (cookies
ignore the port). Each Tidewave control page also keeps a single "current"
recording, and its stop/abort code does not check which session started it. `scripts/recording-lock.mjs` (next to this file) holds a global lock
in `~/.local/state/jam-demo/recording.lock/`. It also asks every Tidewave
Connect tab, through CDP, whether a `MediaRecorder` is active, so it catches
recordings that were not started through this skill.

1. Find your own tell ID: call `list_pi_sessions` and take the `target=` value
   of the entry whose `<…>` session ID equals `$PI_SESSION_ID`.
2. Note who asked for the demo (`requested-by`): the target named in the
   `[TELL:… from <target>]` header of the request, or `user`.
3. Claim the lock:

   ```bash
   lock=~/.pi/agent/skills/jam-demo/scripts/recording-lock.mjs
   $lock acquire "$me" "http://localhost:$PHX_PORT$path" "$title" "$requested_by"
   ```

   - Exit 0: you hold the recorder. Keep it from here through `stopRecording()`.
   - Exit 3: busy. Follow "When the recorder is busy" below and end your turn.
     Do not poll, do not enable vision mode, and do not log in.

`$lock status` prints the lock, its waiters, and every control page's
recording state. A lock older than 15 minutes, with nothing recording, counts
as stale, and the next `acquire` takes it over.

### 3. Turn vision mode on (chrome-cdp)

Every request turns vision mode on here and off again in step 7, so it is
never left on between requests:

```bash
vision=~/.pi/agent/skills/jam-demo/scripts/vision-mode.sh
PHX_PORT=$PHX_PORT $vision on    # exit 0 only once the switch reads on
```

- The script finds this port's Tidewave Connect tab, then clicks the switch
  through chrome-cdp and waits for it to change. Each worktree has its own tab
  and switch. Exit 1 with "no Tidewave Connect tab" means open it with step 1.
- Turning it on activates Helium and brings the tab to the front, which would
  push another agent's recording tab into the background. Run it only while
  you hold the lock.
- If Helium shows "Allow localhost to see this tab?", ask the user to click
  Allow; CDP cannot click browser-native dialogs.
- The toast "Screen capture was denied or failed. Invalid state" means Helium
  did not have OS focus. Run the script again.
- If the script reports the switch is missing, find `[switch] Vision mode` with
  `~/.pi/agent/skills/chrome-cdp/scripts/cdp.mjs snap <target>`.

### 4. Log in when needed

`await browser.reload('/')`. If the page lands on `/login`:

- Fill `input[name="user[email]"]` and `input[name="user[password]"]`, then
  click `#login-form-wrapper button[type="submit"]`.
- The login POST is a full-page redirect and can drop the Tidewave client. On
  any session error, run `new-session` and continue.
- On `/login/verify`, fill `input[aria-label="Digit N of 6"]` for N = 1..6 with
  `123456`. It auto-submits on the sixth digit.
- `/testing/setup/login/:user_id` does not work (ActionClauseError).
- Updating user 99's row logs the browser session out, so log in again after
  DB edits to that user.

### 5. Seed and assert DB state

Run `db.assert` and `db.seed` with `mcp__tidewave__project_eval`, using
`Rx.Repo` and `Ecto.Changeset.change/2`. Before recording any step that writes
data, capture the "before" values of every row it changes so `db.restore` can
put them back.

### 6. Rehearse

1. `browser.resize(w, h)`, `browser.reload(path)`, then the hide-toolbar
   snippet.
2. Run every action without `startRecording` and without overlays. Confirm each
   locator resolves (log `getBoundingClientRect()` through `browser.eval`) and
   that the page reacts.
3. Revert everything the rehearsal changed: `reload()` for client-only state,
   `db.restore` for writes.

### 7. Record and release

One `eval` call with `action_inputs.timeout` as an **integer** (for example
`60000`):

The proof-demo script above becomes:

```js
await browser.resize(1440, 900);
await browser.reload('/invitations');
await browser.eval(async () => { let t = null; for (let i = 0; i < 40 && !(t = document.getElementById('tidewave-toolbar')); i++) await new Promise((r) => setTimeout(r, 100)); if (t) t.style.setProperty('display', 'none', 'important'); });
await browser.startRecording({ description: 'Enrollment invitation page', sfx: false, narration: false });
await browser.overlay('An invited provider opens their Strive Provider Portal enrollment invitation');
await browser.wait(1500);
await browser.overlay('The heading names the practice that sent the invitation');
await browser.zoom(1.8, browser.locator('#invitations-heading'));
await browser.overlay('The page shows their login email and the NPI the practice invited');
await browser.zoom(1.8, browser.locator('#practice-invitations'));
await browser.overlay('They confirm the details and consent to a license and NPI review');
await browser.zoom(1);
await browser.click(browser.locator('input[type="checkbox"][name="user[license_review_consent]"]'));
await browser.overlay('Accepting adds them to CSV Test Clinic as a Physician');
await browser.zoom(1.6, browser.locator('#invitation-accept'));
await browser.overlay('Demo stops before submitting, so the invitation stays pending');
await browser.zoom(1);
await browser.wait(5000);
await browser.stopRecording();
```

- The recording calls resolve to `undefined` and report through console logs.
  Read the file path from `Video recorded: tmp/tidewave/recordings/<name>.webm`.
  "Agent Vision mode is not enabled" means go back to step 3.
- If a step throws mid-recording, run `await browser.abortRecording()` in a
  separate call, fix the step, and record again.
- "Agent is already recording" means someone else's take is current on this
  control page. Never answer it with `abortRecording()`; that would discard
  their take. Run `$lock acquire` again and follow "When the recorder is busy".
- The path is relative to the checkout that runs Phoenix (the main checkout or a
  worktree).

Wrap up as soon as the final take is stopped (its "Video recorded:" log line
has appeared) or aborted, before verifying or uploading; those steps don't need
the browser. Wrap up on failure too, in this order:

```bash
vision=~/.pi/agent/skills/jam-demo/scripts/vision-mode.sh
lock=~/.pi/agent/skills/jam-demo/scripts/recording-lock.mjs
PHX_PORT=$PHX_PORT $vision off
$lock status | jq -c '.recorders[] | {origin, active}'   # your port must show active: false
$lock release "$me"
```

- Turning vision mode off aborts any recording still in progress. That was
  tested: the recorder went inactive and no file was saved. So never turn it
  off before the "Video recorded:" line, or the take is lost.
- That is also the fix for a stuck take: `abortRecording()` can report "No
  recording active" while the take is still current. Without the fix it runs
  until Tidewave's 5-minute auto-stop and saves a near-empty WebM (a 110-byte
  file); trash it.

Send each ID in the output's `notify` list the "recorder available" message
(see below) with `tell_pi`, `mode: "follow_up"`.

### 8. Verify the video

Run from the checkout root that serves Phoenix. Aborted recordings are
discarded, so the newest file is the one just recorded:

```bash
f=$(ls -t tmp/tidewave/recordings/*.webm | head -1)
ffprobe -v error -show_entries stream=codec_name,width,height:format=duration -of compact "$f"
ffmpeg -y -loglevel error -i "$f" -vf "fps=1/3,scale=720:-1,tile=3x3" -frames:v 1 /tmp/jam-demo-sheet.png
```

Look at the contact sheet with `view_image`. Check that every caption appears,
the zooms land on the right element, and no toolbar or blank frames show. Use
ffmpeg, never magick. Scale images down until they are under 5 MB before
viewing them.

Transcode before uploading. The WebM is VP9 at the viewport times the device
pixel ratio (1440×900 records at about 5156×3222), which is wider than many
H.264 decoders accept. A 1920-wide H.264 MP4 plays everywhere, drops the silent
audio track, and the Jam CLI uploads it without converting it again:

```bash
mp4="${f%.webm}.mp4"
ffmpeg -y -loglevel error -i "$f" -vf "scale=1920:-2,fps=30" -c:v libx264 -pix_fmt yuv420p -crf 20 -preset medium -an -movflags +faststart "$mp4"
```

### 9. Upload to Jam

Same shell as step 8, with `title` and `path` from the script:

```bash
title="Enrollment invitation page"; path="/invitations"
jq -n --arg v "$PWD/$mp4" --arg t "$title" --arg u "http://localhost:$PHX_PORT$path" \
  '{kind: "video", videoPath: $v, title: $t, url: $u, screenDimensions: {width: 1440, height: 900}, micEnabled: false}' \
  | mise exec -- jam --json create jam --folder ymfx
```

- The receipt carries `id` and `url`.
- `micEnabled: false` tells Jam there is no narration, so it skips the
  transcript.
- Uploaded video Jams carry no console, network, or device data; Jam captures
  those only when it records.

### 10. Report

- Jam share URL and the local WebM path.
- The script: each step's caption and action.
- DB side effects: rows seeded, rows changed during recording, and whether
  `db.restore` put them back. Say "none" when nothing was written.

## When the recorder is busy

`acquire` exit 3 prints `holder` (the lock's `owner`, `requestedBy`, `url`,
`title`, `startedAt`) and `recording` (each control page that is recording,
with the `url` Tidewave is showing).

**If `holder` is set**, a jam-demo agent owns the take:

1. Tell whoever asked for your demo (the user, or the requester's tell target):
   "Another recording is in progress for `<recording[0].url, else holder.url>`.
   It's owned by `<holder.owner>` (requested by `<holder.requestedBy>`,
   "`<holder.title>`", since `<holder.startedAt>`). I'll ask you before
   recording once it's free."
2. Register as a waiter: `$lock wait "$me"`. Exit 5 means the lock was just
   released, so run `acquire` again.
3. Ask the owner to tell you when it's done. Use `tell_pi` with target
   `<holder.owner>` and `mode: "follow_up"`:
   "jam-demo: `<me>` is waiting for the Tidewave recorder (wants to record
   `<your url>`, "`<your title>`"). After you stop and run
   `recording-lock.mjs release`, send every ID it prints the jam-demo 'recorder
   available' message. Don't abort or stop your take because of this."
4. End your turn. Don't poll.

**If `holder` is null**, a recording that jam-demo did not start is running,
and its owner can't be found. Tell the requester that a recording is in
progress for `<recording[0].url>` with an unknown owner, and ask them to try
again later.

**The owner** does nothing extra on a "waiting" message. Finish the take, then
release and notify as in step 7.

**The "recorder available" message** the owner sends each waiter (`tell_pi`,
`mode: "follow_up"`):

> jam-demo: the Tidewave recorder is free. `<me>` finished recording
> `<lock.url>` ("`<lock.title>`"). Ask your user now with `ask_user_question`:
> question "The Tidewave recorder is free. Record your jam demo now?", header
> "Record now?", options "Yes" (claim the recorder and start the take) and "No"
> (leave the recorder free). On Yes, run `recording-lock.mjs acquire` and
> continue the jam-demo workflow from step 3. On No, stop, and tell whoever
> asked for the demo that it's postponed.

**A waiter that gets this message** asks exactly that question with
`ask_user_question`. Every waiter is notified, and the first to `acquire` wins.
If `acquire` is busy again, repeat this section with the new holder.

## Pitfalls

- Vision mode is on only between step 3 and step 7 of a request. If a request
  ends early, still run `vision-mode.sh off` before releasing the lock.
- `action_inputs.timeout` must be an integer in milliseconds, not a string.
- Tool calls cap at about 60 seconds and recordings at 5 minutes; split long
  scripts.
- `saveScreenshot()` produces full-page images at DPR 3.5. Use recording for
  demos.
- Tests touching this app need `POOL_SIZE=2 mix test …`; at the default pool
  size Postgres hits `too_many_connections`.
- Upgrading the Jam CLI: follow the `shortcut:` comment in
  `.config/mise.local.toml` (bump the version label and the sha256 together).
