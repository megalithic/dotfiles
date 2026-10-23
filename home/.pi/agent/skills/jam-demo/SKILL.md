---
name: jam
description: Record a captioned demo video of the Strive Provider Portal (provider_portal Phoenix dev app) with Tidewave vision mode and upload it to Jam. Use for "record a demo", "make a jam of X", "jam demo", "demo video of the X flow", "record X for stakeholders", "show X in a video", and messages starting with "jam-demo:".
---

# Jam demo - prompt to captioned jam.dev video

- **Capture:** Tidewave vision mode records the app iframe to WebM
  (`browser.startRecording` / `stopRecording`). `browser.overlay(text)` burns a
  subtitle into the video, and `click`/`fill` are animated. Captions replace
  narration; there is no audio.
- **Output:** ffmpeg transcodes the WebM to an H.264 MP4 that fits in
  1920x1920. The workflow opens the recordings folder and asks before uploading
  to Jam.
- **Upload:** On approval, the Jam CLI (`jam create jam`) uploads the MP4 as a
  video Jam and prints the share URL.
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

## Script format (prompt -> script)

Translate the prompt into a script and show it to the user: a title, a start
path, a viewport, the steps as `step()` calls, and the `db` snippets
(`assert`, `seed`, `restore`; "none" when unused). Wait for approval only when
a step writes data; otherwise go on to rehearsal.

Every `eval` call that loads a page starts with these helpers. The Tidewave
toolbar injects about a second after every page load, including redirects in
the middle of a take. `hide` waits for it, hides it, and logs the path the page
landed on; `go` reloads, then hides. An injected `<style>` tag does nothing
here: the app's CSP (`default-src`, no `'unsafe-inline'`) blocks it, so `hide`
sets the inline style.

```js
const hide = (next) => browser.eval(async () => { let t = null; for (let i = 0; i < 160 && !(t = document.getElementById('tidewave-toolbar')); i++) await new Promise((r) => setTimeout(r, 25)); if (t) t.style.setProperty('display', 'none', 'important'); console.log('page:', location.pathname); }, next ? [next] : []);
const go = async (path) => { await browser.reload(path); await hide(); };
const step = async (caption, act, hold = 1500) => { await browser.overlay(caption); await browser.wait(1000); await act?.(); await browser.wait(hold); };
```

This is the record call behind the proof demo in the "Demos (Seth)" folder.
Its `db.assert` is
`Rx.Accounts.Invitations.pending(Rx.Repo.get!(Rx.Accounts.User, 99)) |> Enum.map(& &1.id) == [23]`;
it has no seed or restore because it submits nothing.

```js
await browser.resize(1440, 900);
await go('/invitations');
await browser.startRecording({ description: 'Enrollment invitation page', sfx: false, narration: false });
await step('An invited provider opens their Strive Provider Portal enrollment invitation');
await step('The heading names the practice that sent the invitation', () => browser.zoom(1.8, browser.locator('#invitations-heading')));
await step('The page shows their login email and the NPI the practice invited', () => browser.zoom(1.8, browser.locator('#practice-invitations')));
await step('They confirm the details and consent to a license and NPI review', async () => { await browser.zoom(1); await browser.click(browser.locator('input[type="checkbox"][name="user[license_review_consent]"]')); });
await step('Accepting adds them to CSV Test Clinic as a Physician', () => browser.zoom(1.6, browser.locator('#invitation-accept')));
await step('Demo stops before submitting, so the invitation stays pending', () => browser.zoom(1), 5000);
await browser.stopRecording();
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

Actions to pass as `act`:

| Action | `act` |
|---|---|
| navigate | `() => go(P)` |
| click that loads a new page | `async () => { await browser.click(browser.locator(S)); await hide(browser.locator(N)); }`, where N matches only on the new page, so `hide` waits for that page instead of hiding on the old one |
| click | `() => browser.click(browser.locator(S))` |
| fill | `() => browser.fill(browser.locator(S), V)` (typed per character) |
| scroll | `async () => { await browser.eval((el) => el.scrollIntoView({ behavior: 'smooth', block: 'center' }), [browser.locator(S)]); await browser.wait(800); }` |
| zoom | `() => browser.zoom(N, browser.locator(S))` (`browser.zoom(1)` resets, ~0.7 s) |

Rules:

- One caption per action. Write it in the present tense from the viewer's side
  ("The provider sees…"), in at most ~80 characters so it stays on one line.
- Never use an em dash (U+2014) or an en dash (U+2013) in the title, captions
  or description, not even for ranges. Use a plain hyphen `-`: `STEPS 1-3`,
  `Page 2 - practice details`.
- Each caption stays up 5.0 seconds whatever its length. `overlay()`
  returns at once, and the next `overlay()` waits for the current one to finish,
  so each action runs while its caption is on screen.
- `step()` paces each step as caption, 1 s wait, action, `hold` (1.5 s).
  Measured: `click` takes about 1.4 s (cursor travel plus click), `zoom N S`
  returns at once and animates for about 0.7 s, `zoom 1` takes about 0.7 s.
  Without the first wait the cursor starts moving the instant the caption
  appears, before anyone has read it; the hold keeps the result on screen. A
  step therefore lasts max(5 s, 1 s + action + hold); raise `hold` when the
  result needs more than the remaining caption time.
- Open with an establishing caption on the start page and no action. Close with
  a summary caption held 5000 ms, because `stopRecording()` does not wait for
  the last caption.
- Use selectors that survive reloads: IDs, `name` attributes, and
  `browser.locator(css, {hasText})`. Never use snapshot refs.
- Put at most ~8 steps in one tool call. Split longer scripts across calls,
  each with the helpers; the recording pauses between them and may total 5
  minutes.
- Add a step that writes data only when the prompt asks for it. List the rows
  it touches.

## Workflow

### 1. Connect Tidewave

Call `mcp__tidewave__browser_eval` with `action: "new-session"` and note the
`sid`. Only if it fails with "No browser is connected...":

1. `open http://localhost:$PHX_PORT/tidewave/connect`. Never open bare
   `/tidewave`.
2. Wait with one `mcp__tidewave__project_eval` call:
   `Enum.find_value(1..200, fn _ -> Tidewave.BrowserSessions.list_clients() != [] || (Process.sleep(50) && nil) end) || :timeout`.
   Report `:timeout` to the user instead of retrying.
3. `action: "new-session"` again.

Sessions change whenever the browser drops, so re-read the `sid` after any
failure.

### 2. Claim the recorder and turn vision mode on

Only one recording may run at a time across every checkout and worktree.
All ports share one Helium window and one `_rx_key` login cookie (cookies
ignore the port). Each Tidewave control page also keeps a single "current"
recording, and its stop/abort code does not check which session started it.
`scripts/recording-lock.mjs` (next to this file) holds a global lock in
`~/.local/state/jam-demo/recording.lock/`. It also asks every Tidewave Connect
tab, through CDP, whether a `MediaRecorder` is active or vision mode is on, so
it catches recordings that were not started through this skill.

Note who asked for the demo (`requested-by`): the target named in the
`[TELL:… from <target>]` header of the request, or `user`. Then run one bash
call, with the start URL, title and requester written as quoted literals:

```bash
me=pi:${HOSTNAME%%.*}:$PI_SESSION_ID
~/.pi/agent/skills/jam-demo/scripts/recording-lock.mjs acquire "$me" "http://localhost:$PHX_PORT/invitations" 'Enrollment invitation page' 'user' \
  && ~/.pi/agent/skills/jam-demo/scripts/vision-mode.sh on
```

- `$me` is your tell ID, in the form `tell_pi` uses. Every later bash call that
  needs it starts with the same `me=` line.
- Exit 3: busy. Vision mode stays off. Follow "When the recorder is busy" below
  and end your turn. Do not poll and do not log in.
- Otherwise you hold the recorder until the wrap-up in step 5. `vision-mode.sh`
  exits 0 only once the switch reads on.
- `recording-lock.mjs status` prints the lock, its waiters, and every control
  page's state. A lock older than 15 minutes, with no control page recording or
  in vision mode, counts as stale, and the next `acquire` takes it over. Vision
  mode stays on between takes, so a live holder's lock does not go stale.

`vision-mode.sh` (`PHX_PORT`, default 4000) finds this port's Tidewave Connect
tab, clicks the switch through chrome-cdp, and waits for it to change. Each
worktree has its own tab and switch.

- Exit 1 with "no Tidewave Connect tab" means open it as in step 1.
- Turning it on activates Helium and brings the tab to the front, which would
  push another agent's recording tab into the background. The `&&` runs it only
  once you hold the lock.
- If Helium shows "Allow localhost to see this tab?", ask the user to click
  Allow; CDP cannot click browser-native dialogs.
- The toast "Screen capture was denied or failed. Invalid state" means Helium
  did not have OS focus. Run `vision-mode.sh on` again.
- If the script reports the switch is missing, find `[switch] Vision mode` with
  `~/.pi/agent/skills/chrome-cdp/scripts/cdp.mjs snap <target>`.

### 3. Rehearse

Send these two calls in the same turn:

- `mcp__tidewave__project_eval` with `db.assert` and `db.seed`, using `Rx.Repo`
  and `Ecto.Changeset.change/2`. If the seed changes what the rehearsal will
  see, run it first instead. Before rehearsing a step that writes data, capture
  the "before" values of every row it changes so `db.restore` can put them back.
- One `eval` call with the record call's code, minus `startRecording` and
  `stopRecording`, and with the `step` helper replaced by one that skips
  captions and waits: `const step = async (caption, act) => { await act?.(); };`. A locator that
  does not match exactly one element throws after `element_timeout` (5 s), so a
  clean run confirms every locator.

If the log shows `page: /login`, log in with one `eval` call, then rehearse
again:

- Fill `input[name="user[email]"]` and `input[name="user[password]"]`, then
  click `#login-form-wrapper button[type="submit"]`.
- The login POST is a full-page redirect and can drop the Tidewave client. On
  any session error, run `new-session` and continue.
- On `/login/verify`, fill `input[aria-label="Digit N of 6"]` for N = 1..6 with
  `123456`. It auto-submits on the sixth digit.
- `/testing/setup/login/:user_id` does not work (ActionClauseError).
- Updating user 99's row logs the browser session out, so log in again after
  DB edits to that user.
- To switch users, log out first. A `browser.eval` that sends DELETE `/logout`
  throws "page navigation" when the logout redirects; wait 1 s, then
  `go('/login')`.

If the rehearsal wrote data, run `db.restore` (and `db.seed` again when the
take needs it). Client-only state needs no undo: the record call starts with
`resize` and `go`.

### 4. Record

One `eval` call with `action_inputs.timeout` as an **integer** (for example
`60000`): the helpers, then the script, as in the proof demo above.

- The recording calls resolve to `undefined` and report through console logs.
  Read the file path from `Video recorded: tmp/tidewave/recordings/<name>.webm`.
  The path is relative to the checkout that runs Phoenix (the main checkout or a
  worktree). "Agent Vision mode is not enabled" means run `vision-mode.sh on`
  again.
- If a step throws mid-recording, run `await browser.abortRecording()` in a
  separate call, fix the step, and record again.
- "Agent is already recording" means someone else's take is current on this
  control page. Never answer it with `abortRecording()`; that would discard
  their take. Run `recording-lock.mjs acquire` again and follow "When the
  recorder is busy".

### 5. Wrap up and verify

As soon as the final take is stopped (its "Video recorded:" log line has
appeared) or aborted, run one bash call from the checkout root that serves
Phoenix. Do this on failure too. List each take's WebM from its "Video
recorded:" line, and leave out `open` when the prompt asked to upload:

```bash
me=pi:${HOSTNAME%%.*}:$PI_SESSION_ID
~/.pi/agent/skills/jam-demo/scripts/vision-mode.sh off
~/.pi/agent/skills/jam-demo/scripts/recording-lock.mjs release "$me"
for f in tmp/tidewave/recordings/recording-<timestamp>.webm; do
  mp4=${f%.webm}.mp4
  ffmpeg -y -loglevel error -i "$f" -vf "scale=1920:1920:force_original_aspect_ratio=decrease:force_divisible_by=2,fps=30" -c:v libx264 -pix_fmt yuv420p -crf 20 -preset medium -an -movflags +faststart "$mp4"
  ffmpeg -y -loglevel error -i "$mp4" -vf "fps=1/4,scale=480:480:force_original_aspect_ratio=decrease,tile=4x4" "/tmp/jam-demo-$(basename "$f" .webm)-sheet-%d.png"
  ls "$mp4" /tmp/jam-demo-"$(basename "$f" .webm)"-sheet-*.png
done
open tmp/tidewave/recordings
```

- Turning vision mode off aborts any recording still in progress. That was
  tested: the recorder went inactive and no file was saved. So never turn it
  off before the "Video recorded:" line, or the take is lost.
- That is also the fix for a stuck take: `abortRecording()` can report "No
  recording active" while the take is still current. Without the fix it runs
  until Tidewave's 5-minute auto-stop and saves a near-empty WebM (a 110-byte
  file); trash it.
- The WebM is VP9 at the viewport times the device pixel ratio (about 3.6),
  wider than many H.264 decoders accept. The MP4 fits in 1920x1920 (a phone
  viewport comes out 1920 tall), plays everywhere, drops the silent audio
  track, and the Jam CLI uploads it without converting it again.

In the next turn, `view_image` every sheet, and send each ID in the release
output's `notify` list the "recorder available" message (see below) with
`tell_pi`, `mode: "follow_up"`. Each sheet holds one frame every 4 seconds, so
one sheet covers 64 seconds. Check that every caption appears, the zooms land on
the right element, and no toolbar or blank frames show. Use ffmpeg, never
magick. To redo a take, start again from step 2.

### 6. Decide whether to upload

Ask the user with `ask_user_question`:

- Question: `Upload the recorded demo(s) to Jam?`
- Header: `Upload to Jam?`
- `Yes`: upload with the Jam CLI into the "Demos (Seth)" folder.
- `No`: keep the local MP4s only and skip the upload.

If the original prompt explicitly asks to upload, such as "record and upload",
"upload it to Jam", or "jam it", skip the question and upload directly.
Otherwise, wait for the user's answer before continuing. On `No`, skip to step
8.

### 7. Upload to Jam

Run one bash call from the checkout root that serves Phoenix, with one `jq` and
`jam` pair per MP4. Write the video path, title and start URL as quoted
literals, never through shell variables (see Pitfalls). Set `screenDimensions`
to the script's `browser.resize` viewport. The description is `PR: <url>` for
the branch's pull request (open, draft, merged or closed), and is left out when
there is none; the main checkout's `main` never has one. The `jq -e` check
stops the upload if the title is empty or any text has an em or en dash:

```bash
jq -n \
  --arg v "$PWD/tmp/tidewave/recordings/recording-<timestamp>.mp4" \
  --arg t 'Enrollment invitation page' \
  --arg u "http://localhost:$PHX_PORT/invitations" \
  --arg d "$(gh pr list --head "$(git branch --show-current)" --state all --json url --jq '.[0].url // empty' | sed 's/^/PR: /')" \
  '{kind: "video", videoPath: $v, title: $t, url: $u, screenDimensions: {width: <w>, height: <h>}, micEnabled: false} + (if $d == "" then {} else {description: $d} end)' \
  > /tmp/jam-payload.json
jq -e '(.title | length > 0) and ([.title, (.description // "")] | all(test("[\u2013\u2014]") | not))' /tmp/jam-payload.json \
  && mise exec -- jam --json create jam @/tmp/jam-payload.json --folder ymfx
```

- Each receipt carries an `id` and `url`.
- Don't pipe `jam` output into `jq` or `rg`: it prints "Update available" on
  stderr, which breaks the parse and looks like a failed upload. Before
  retrying an upload that seems to have failed, check
  `mise exec -- jam list jams --query '<title>' --folder ymfx` (at most 8
  words); retrying a finished upload makes a duplicate.
- `micEnabled: false` tells Jam there is no narration, so it skips the
  transcript.
- Uploaded video Jams carry no console, network, or device data; Jam captures
  those only when it records.

### 8. Report

When uploaded, report the Jam share URL and the local WebM and MP4 paths. When
not uploaded, say "not uploaded" and report the local MP4 and WebM paths.

- The PR link (the Jam description), or "no PR" when the branch has none. Say
  "no PR" when the upload was skipped.
- The script: each step's caption and action.
- DB side effects: rows seeded, rows changed during recording, and whether
  `db.restore` put them back. Say "none" when nothing was written.

## When the recorder is busy

`acquire` exit 3 prints `holder` (the lock's `owner`, `requestedBy`, `url`,
`title`, `startedAt`) and `recording` (each control page that is recording or
in vision mode, with the `url` Tidewave is showing and `vision`).

**If `holder` is set**, a jam-demo agent owns the take:

1. Tell whoever asked for your demo (the user, or the requester's tell target):
   "Another recording is in progress for `<recording[0].url, else holder.url>`.
   It's owned by `<holder.owner>` (requested by `<holder.requestedBy>`,
   "`<holder.title>`", since `<holder.startedAt>`). I'll ask you before
   recording once it's free."
2. Register as a waiter: `recording-lock.mjs wait "$me"` (with the `me=` line
   from step 2). Exit 5 means the lock was just released, so go back to step 2.
3. Ask the owner to tell you when it's done. Use `tell_pi` with target
   `<holder.owner>` and `mode: "follow_up"`:
   "jam-demo: `<me>` is waiting for the Tidewave recorder (wants to record
   `<your url>`, "`<your title>`"). After you stop and run
   `recording-lock.mjs release`, send every ID it prints the jam-demo 'recorder
   available' message. Don't abort or stop your take because of this."
4. End your turn. Don't poll.

If `tell_pi` cannot find `<holder.owner>`, the holder died and may have left
vision mode on. Turn it off with
`PHX_PORT=<port of holder.url> ~/.pi/agent/skills/jam-demo/scripts/vision-mode.sh off`.
Once the lock is 15 minutes old (`holder.startedAt`), the next `acquire` takes
it over. Tell the requester when that is, since no "recorder available" message
will come.

**If `holder` is null**, a recording or vision mode that jam-demo did not start
is on, and its owner can't be found. Tell the requester it is busy at
`<recording[0].url>` with an unknown owner. When the entry shows `vision: true`
and the requester confirms nothing is being recorded there, run
`PHX_PORT=<port> vision-mode.sh off` and go back to step 2. Otherwise ask them
to try again later.

**The owner** does nothing extra on a "waiting" message. Finish the take, then
release and notify as in step 5.

**The "recorder available" message** the owner sends each waiter (`tell_pi`,
`mode: "follow_up"`):

> jam-demo: the Tidewave recorder is free. `<me>` finished recording
> `<lock.url>` ("`<lock.title>`"). Ask your user now with `ask_user_question`:
> question "The Tidewave recorder is free. Record your jam demo now?", header
> "Record now?", options "Yes" (claim the recorder and start the take) and "No"
> (leave the recorder free). On Yes, continue the jam-demo workflow from step 2
> (claim the recorder). On No, stop, and tell whoever asked for the demo that
> it's postponed.

**A waiter that gets this message** asks exactly that question with
`ask_user_question`. Every waiter is notified, and the first to `acquire` wins.
If `acquire` is busy again, repeat this section with the new holder.

## Pitfalls

- Vision mode is on only between step 2 and the step 5 wrap-up of a request.
  If a request ends early, still run `vision-mode.sh off` before releasing the
  lock.
- `action_inputs.timeout` must be an integer in milliseconds, not a string.
- Tool calls cap at about 60 seconds and recordings at 5 minutes; split long
  scripts.
- Pi's Bash tool loses a quoted shell assignment that shares its line with
  `;` or `&&`: `title="Demo"; path="/x"` leaves both variables empty, and Jam
  then stores the title as `{}`. A quoted assignment alone on its line, or an
  unquoted one, survives. Each tool call is a new shell anyway, so pass Jam
  values to `jq` as quoted literals.
- `saveScreenshot()` produces full-page images at DPR 3.5. Use recording for
  demos.
- Upgrading the Jam CLI: follow the `shortcut:` comment in
  `.config/mise.local.toml` (bump the version label and the sha256 together).
