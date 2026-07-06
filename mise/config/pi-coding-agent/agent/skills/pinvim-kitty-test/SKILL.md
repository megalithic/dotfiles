---
name: pinvim-kitty-test
description: Use the running kitty app plus tmux to run real end-to-end pinvim rewrite tests across Nvim, Pi, pimux, sockets, manifests, registry state, and nested sessions. Use when testing or manually verifying pinvim, :PiPanel, :PiSplit, gps/gpa, /pinvim-health, /pinvim-doctor, editor-service, registry fast path, dirty-buffer safety, or nested Pi safety.
---

# Pinvim kitty test

Use the kitty app for real pinvim tests. Start kitty when needed, put the test window in the current working directory, then exercise macOS app env, kitty, tmux, Nvim, Pi, `pimux`, Home Manager-installed wrappers, sockets, manifests, and registry files together.

Do not rely only on `--no-session` shims for pinvim rewrite tickets. Use shims for targeted state checks, then run one real kitty/tmux/Nvim/Pi smoke when behavior crosses process boundaries.

## Safety rules

- Never disturb the user's existing panes or tmux sessions. Create a dedicated kitty window and a private tmux server/socket for this run.
- Never attach to, send keys to, or kill panes from existing tmux servers. All tmux commands in this skill must use `-S "$TEST_TMUX_SOCKET"`.
- Never kill panes you did not create. Record pane IDs before cleanup.
- Run from the directory under test. Use the caller's current working directory, whether it is `~/.dotfiles`, a worktree, or another repo checkout.
- Apply Home Manager before testing installed wrappers: `devenv shell -- just home`.
- Keep test artifacts under a clearly named tmux session and optional test state dir.
- Prefer `trash` over `rm` for file deletion.

## Required setup

```bash
WT="${PINVIM_TEST_CWD:-$PWD}"
KITTY_TO="unix:/tmp/mykitty"
TEST_RUN_ID="$(date +%Y%m%d-%H%M%S)-$$"
TEST_SESSION="pinvim-rewrite-test-$TEST_RUN_ID"
TEST_TMUX_SOCKET="/tmp/pinvim-kitty-$TEST_RUN_ID.tmux.sock"
PINVIM_TEST_INSIDE_RIG=0
cd "$WT"
mkdir -p "$WT/.local_scripts"

# If this skill is run from inside a prior pinvim kitty test tmux session,
# reuse that session instead of starting tmux inside tmux.
if [ -n "${TMUX:-}" ]; then
  CURRENT_TMUX_SOCKET="${TMUX%%,*}"
  CURRENT_TMUX_SOCKET_NAME="$(basename "$CURRENT_TMUX_SOCKET")"
  case "$CURRENT_TMUX_SOCKET_NAME" in
    pinvim-kitty-*.tmux.sock)
      PINVIM_TEST_INSIDE_RIG=1
      TEST_TMUX_SOCKET="$CURRENT_TMUX_SOCKET"
      TEST_SESSION="$(tmux -S "$TEST_TMUX_SOCKET" display-message -p '#S')"
      ;;
  esac
fi
```

Start or select the kitty window for this test. Skip this whole window-start section when `PINVIM_TEST_INSIDE_RIG=1`; the skill is already running inside the ephemeral test tmux session, so starting tmux again would create nested tmux.

```bash
KITTY_WAS_RUNNING=0
if pgrep -x kitty >/dev/null 2>&1; then
  KITTY_WAS_RUNNING=1
fi
```

If kitty is not running, open kitty's startup window in the test cwd and run the private tmux session there:

```bash
if [ "$PINVIM_TEST_INSIDE_RIG" -eq 0 ] && [ "$KITTY_WAS_RUNNING" -eq 0 ]; then
  open -a kitty --args \
    --directory "$WT" \
    fish -lc "cd '$WT'; devenv shell -- tmux -S '$TEST_TMUX_SOCKET' new-session -s '$TEST_SESSION'"
fi
```

If kitty is already running, always open a new kitty OS window in the test cwd and run the private tmux session there:

```bash
if [ "$PINVIM_TEST_INSIDE_RIG" -eq 0 ] && [ "$KITTY_WAS_RUNNING" -eq 1 ]; then
  for _ in {1..30}; do
    if kitty @ --to "$KITTY_TO" ls >/tmp/pinvim-kitty-ls.json 2>/tmp/pinvim-kitty-ls.err; then
      break
    fi
    sleep 1
  done

  if ! kitty @ --to "$KITTY_TO" ls >/tmp/pinvim-kitty-ls.json 2>/tmp/pinvim-kitty-ls.err; then
    cat /tmp/pinvim-kitty-ls.err
    echo "kitty remote control unavailable at $KITTY_TO"
    echo "Cannot open an isolated new kitty window while kitty is already running."
    echo "Check config/kitty/kitty.conf for:"
    echo "  allow_remote_control yes"
    echo "  listen_on unix:/tmp/mykitty"
    exit 1
  fi

  kitty @ --to "$KITTY_TO" launch \
    --type=os-window \
    --os-window-title "$TEST_SESSION" \
    --cwd "$WT" \
    --title "$TEST_SESSION" \
    fish -lc "cd '$WT'; devenv shell -- tmux -S '$TEST_TMUX_SOCKET' new-session -s '$TEST_SESSION'"
fi
```

Then wait for the private tmux session. The short `/tmp` socket path avoids macOS `File name too long` failures.

```bash
if [ "$PINVIM_TEST_INSIDE_RIG" -eq 0 ]; then
  for _ in {1..30}; do
    if tmux -S "$TEST_TMUX_SOCKET" has-session -t "$TEST_SESSION" 2>/dev/null; then
      break
    fi
    sleep 1
  done
fi

tmux -S "$TEST_TMUX_SOCKET" has-session -t "$TEST_SESSION"
```

This keeps cwd behavior predictable:

- If the skill runs from `~/.dotfiles`, kitty starts in `~/.dotfiles`.
- If the skill runs from a worktree, kitty starts in that worktree.
- If kitty is already running, the skill creates a new OS window and leaves existing kitty windows untouched.
- If kitty is not running, the startup window becomes the test window.
- If the skill is already running inside a `pinvim-kitty-*.tmux.sock` tmux session, it reuses that session and does not start nested tmux.

## Start visible test rig

The dedicated kitty window already runs a real tmux session in the test cwd. This must use a private tmux socket so the test rig is ephemeral and isolated from every existing tmux session.

Then drive only that private tmux server from normal tool calls:

```bash
tmux -S "$TEST_TMUX_SOCKET" has-session -t "$TEST_SESSION"
TEST_WINDOW=$(tmux -S "$TEST_TMUX_SOCKET" display-message -p '#I')
tmux -S "$TEST_TMUX_SOCKET" rename-window -t "$TEST_SESSION:$TEST_WINDOW" nvim
NVIM_PANE=$(tmux -S "$TEST_TMUX_SOCKET" display-message -t "$TEST_SESSION:$TEST_WINDOW" -p '#{pane_id}')
```

Start Nvim in the test pane:

```bash
tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$NVIM_PANE" "cd '$WT' && devenv shell -- nvim README.md" Enter
sleep 2
tmux -S "$TEST_TMUX_SOCKET" display-message -t "$NVIM_PANE" -p '#{pane_current_command}'
```

## Pane discovery helpers

After each `:PiPanel` or `:PiSplit`, rediscover panes. Do not assume pane numbers.

```bash
tmux -S "$TEST_TMUX_SOCKET" list-panes -t "$TEST_SESSION" -F '#{pane_id}	#{pane_index}	#{pane_current_command}	#{pane_title}	#{pane_current_path}'
```

Find likely panes:

```bash
NVIM_PANE=$(tmux -S "$TEST_TMUX_SOCKET" list-panes -t "$TEST_SESSION" -F '#{pane_id}	#{pane_current_command}	#{pane_title}' | awk '$2 ~ /nvim/ {print $1; exit}')
PI_PANE=$(tmux -S "$TEST_TMUX_SOCKET" list-panes -t "$TEST_SESSION" -F '#{pane_id}	#{pane_current_command}	#{pane_title}' | awk '$3 ~ /^π/ || $2 ~ /^(pi|pinvim|node)$/ {print $1; exit}')
```

Capture output:

```bash
tmux -S "$TEST_TMUX_SOCKET" capture-pane -p -J -t "$PI_PANE" -S -120
tmux -S "$TEST_TMUX_SOCKET" capture-pane -p -J -t "$NVIM_PANE" -S -80
```

## Nvim command and action checks

Exercise Nvim commands and mappings directly. For each command/action, capture Nvim and Pi panes, then record pass/fail in `$RESULTS`.

### Read-only Nvim commands

```bash
for cmd in PiInfo PiHealth PiDoctor PiStatus; do
  tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$NVIM_PANE" Escape ":$cmd" Enter
  sleep 1
  tmux -S "$TEST_TMUX_SOCKET" capture-pane -p -J -t "$NVIM_PANE" -S -80 >"$WT/.local_scripts/${cmd}.nvim.capture"
done
```

Expected:

- `:PiInfo` shows socket/source, lifecycle, registry identity, peer protocol, and active file.
- `:PiHealth` shows ok/attention state, active peer, hello/heartbeat state, and socket.
- `:PiDoctor` shows registry files, parent/workspace/instance ids, editor-service state, and hints without mutating state.
- `:PiStatus` shows concise link state without opening a new pane.

### Target and session actions

```bash
tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$NVIM_PANE" Escape ':PiSessions' Enter
sleep 1
tmux -S "$TEST_TMUX_SOCKET" capture-pane -p -J -t "$NVIM_PANE" -S -120 >"$WT/.local_scripts/PiSessions.nvim.capture"

tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$NVIM_PANE" Escape ':PiTarget' Enter
sleep 1
tmux -S "$TEST_TMUX_SOCKET" capture-pane -p -J -t "$NVIM_PANE" -S -120 >"$WT/.local_scripts/PiTarget.nvim.capture"
```

Expected:

- `:PiSessions` lists explicit selectable sessions only on request.
- `:PiTarget` shows or changes buffer-local target without stealing parent main.
- Neither command starts an agent turn by itself.

### Mapping actions

Run normal-mode and visual-mode variants when ticket scope touches context delivery:

```bash
# normal cursor attach
tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$NVIM_PANE" Escape 'gg' 'gpa'
sleep 1
tmux -S "$TEST_TMUX_SOCKET" capture-pane -p -J -t "$PI_PANE" -S -120 >"$WT/.local_scripts/gpa.pi.capture"

# normal cursor prompt
tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$NVIM_PANE" Escape 'gg' 'gps'
sleep 1
tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$NVIM_PANE" 'Say only: gps received' Enter
sleep 6
tmux -S "$TEST_TMUX_SOCKET" capture-pane -p -J -t "$PI_PANE" -S -180 >"$WT/.local_scripts/gps.pi.capture"

# visual selection attach
tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$NVIM_PANE" Escape 'gg' 'V' 'j' 'gpa'
sleep 1
tmux -S "$TEST_TMUX_SOCKET" capture-pane -p -J -t "$PI_PANE" -S -120 >"$WT/.local_scripts/gpa-visual.pi.capture"
```

Expected:

- `gpa` / visual `gpa` attach context only; no Pi turn starts.
- `gps` starts a Pi turn with Nvim context and user prompt.
- Context includes focused file, cursor or selected lines, filetype, and user input when applicable.

## Pi command checks

Run Pi-side commands in the main Pi pane and record pass/fail.

```bash
for cmd in /pinvim-info /pinvim-health /pinvim-status /pinvim-doctor /pinvim-context; do
  tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$PI_PANE" "$cmd" Enter
  sleep 2
  safe=$(printf '%s' "$cmd" | tr -cd '[:alnum:]-')
  tmux -S "$TEST_TMUX_SOCKET" capture-pane -p -J -t "$PI_PANE" -S -160 >"$WT/.local_scripts/${safe}.pi.capture"
done
```

Expected:

- `/pinvim-info` shows local identity, relation, nested attach-only flag, active peer, repair state, editor-service state, and socket.
- `/pinvim-health` gives a concise ok/attention state and enough relation detail to know whether behavior is expected.
- `/pinvim-status` shows concise routing state without side effects.
- `/pinvim-doctor` diagnoses parent/workspace/instance ids, peer identity, tmux state, editor-service state, and hints.
- `/pinvim-context` fetches current Nvim context through editor service when available, or reports a clear fallback/error.

## Baseline command checks

Run these before manual behavior checks:

```bash
cd "$WT"
devenv shell -- bin/pinvim-protocol-smoke
devenv shell -- nvim --headless '+lua require("pinvim").setup(); vim.cmd("PiDoctor"); print("doctor ok")' +qa
devenv shell -- just validate home
```

Start a result log before interactive checks. Fill it as you go; do not wait until the end and reconstruct from memory.

```bash
RESULTS="$WT/.local_scripts/pinvim-kitty-results-$(date +%Y%m%d-%H%M%S).md"
mkdir -p "$WT/.local_scripts"
cat >"$RESULTS" <<EOF
# Pinvim kitty test results

session: $TEST_SESSION
kitty: $KITTY_TO
worktree: $WT

| Test | Expected | Observed | Pass/fail | Evidence |
| --- | --- | --- | --- | --- |
EOF
```

Append one row per check:

```bash
record_result() {
  local test="$1" expected="$2" observed="$3" verdict="$4" evidence="$5"
  printf '| %s | %s | %s | %s | %s |\n' \
    "$test" "$expected" "$observed" "$verdict" "$evidence" >>"$RESULTS"
}
```

Verdict rules:

- `pass` means observed behavior matches all listed expectations.
- `fail` means observed behavior contradicts an expectation.
- `blocked` means the test could not run because setup failed.
- `needs-investigation` means output was ambiguous; include capture path or pane lines.

## Main panel reuse test

Goal: `:PiPanel`, `:PiPanel!`, then `:PiPanel` reuse one durable parent-owned main session.

```bash
tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$NVIM_PANE" Escape ':PiPanel' Enter
sleep 4
tmux -S "$TEST_TMUX_SOCKET" list-panes -t "$TEST_SESSION" -F '#{pane_id}	#{pane_current_command}	#{pane_title}'
PI_PANE=$(tmux -S "$TEST_TMUX_SOCKET" list-panes -t "$TEST_SESSION" -F '#{pane_id}	#{pane_current_command}	#{pane_title}' | awk '$3 ~ /^π/ || $2 ~ /^(pi|pinvim|node)$/ {print $1; exit}')

tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$PI_PANE" '/pinvim-health' Enter
sleep 1
tmux -S "$TEST_TMUX_SOCKET" capture-pane -p -J -t "$PI_PANE" -S -80
```

Expected:

- `/pinvim-health` shows `Relation: parent` or equivalent parent/main state.
- Socket points at registry `main.sock` or current parent-owned socket.
- Active peer is an Nvim peer with matching parent/workspace/instance identity.

Repeat panel open and verify pane/socket stays stable:

```bash
before=$(tmux -S "$TEST_TMUX_SOCKET" list-panes -t "$TEST_SESSION" -F '#{pane_id}	#{pane_pid}	#{pane_title}')
tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$NVIM_PANE" Escape ':PiPanel!' Enter
sleep 2
tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$NVIM_PANE" Escape ':PiPanel' Enter
sleep 2
after=$(tmux -S "$TEST_TMUX_SOCKET" list-panes -t "$TEST_SESSION" -F '#{pane_id}	#{pane_pid}	#{pane_title}')
printf 'before:\n%s\nafter:\n%s\n' "$before" "$after"
```

## `gpa` attach-only test

Goal: Nvim sends context without starting a turn; next user prompt consumes it once.

```bash
tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$NVIM_PANE" Escape 'gg'
tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$NVIM_PANE" 'gpa'
sleep 1
tmux -S "$TEST_TMUX_SOCKET" capture-pane -p -J -t "$PI_PANE" -S -80
```

Expected:

- Pi reports attached context or shows pending context status.
- No agent turn starts from `gpa` alone.

Consume context:

```bash
tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$PI_PANE" 'Say only: got pinvim attached context' Enter
sleep 8
tmux -S "$TEST_TMUX_SOCKET" capture-pane -p -J -t "$PI_PANE" -S -160
```

Expected:

- Provider receives `[NEOVIM ATTACHED CONTEXT]` or `[NEOVIM LIVE CONTEXT]` as visible custom context.
- Pending context clears after one prompt.

## `gps` prompt-delivery test

Goal: Nvim sends context plus prompt and starts a Pi turn immediately.

```bash
tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$NVIM_PANE" Escape 'gg'
tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$NVIM_PANE" 'gps'
sleep 1
# If prompted in Nvim command/input UI, type concise prompt.
tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$NVIM_PANE" 'Say only: gps received' Enter
sleep 8
tmux -S "$TEST_TMUX_SOCKET" capture-pane -p -J -t "$PI_PANE" -S -160
```

Expected:

- Pi turn starts without manually typing in Pi.
- Context payload includes focused file/selection/cursor data.

## Child split isolation test

Goal: `:PiSplit` creates explicit child session and never replaces main.

```bash
tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$NVIM_PANE" Escape ':PiSplit' Enter
sleep 4
tmux -S "$TEST_TMUX_SOCKET" list-panes -t "$TEST_SESSION" -F '#{pane_id}	#{pane_current_command}	#{pane_title}'
```

Find child pane by new pane/title, then:

```bash
CHILD_PANE=$(tmux -S "$TEST_TMUX_SOCKET" list-panes -t "$TEST_SESSION" -F '#{pane_id}	#{pane_current_command}	#{pane_title}' | awk '$1 != ENVIRON["PI_PANE"] && ($3 ~ /^π/ || $2 ~ /^(pi|pinvim|node)$/) {print $1; exit}')
tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$CHILD_PANE" '/pinvim-health' Enter
sleep 1
tmux -S "$TEST_TMUX_SOCKET" capture-pane -p -J -t "$CHILD_PANE" -S -100
```

Expected:

- Child shows `Relation: child`.
- Child has same parent/workspace identity as main but child role/session id.
- Sending `gpa`/`gps` from original Nvim to main still routes to main unless buffer target selects child.

Close child safely and verify main still works:

```bash
[ -n "$CHILD_PANE" ] && tmux -S "$TEST_TMUX_SOCKET" kill-pane -t "$CHILD_PANE"
tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$PI_PANE" '/pinvim-health' Enter
sleep 1
tmux -S "$TEST_TMUX_SOCKET" capture-pane -p -J -t "$PI_PANE" -S -80
```

## Nested Pi safety test

Goal: starting pinvim inside existing parent context does not steal original Nvim link.

First capture main health:

```bash
tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$PI_PANE" '/pinvim-health' Enter
sleep 1
before=$(tmux -S "$TEST_TMUX_SOCKET" capture-pane -p -J -t "$PI_PANE" -S -80)
printf '%s\n' "$before"
```

Create a shim nested pane with inherited registry identity. Read identity from the Pi manifest if needed:

```bash
MANIFEST=$(ls -t "$HOME/.local/state/pi/manifests"/pi-*.info | head -1)
PARENT_ID=$(jq -r '.parentId // empty' "$MANIFEST")
WORKSPACE_ID=$(jq -r '.workspaceId // empty' "$MANIFEST")
INSTANCE_ID=$(jq -r '.instanceId // empty' "$MANIFEST")
REGISTRY_ROOT=$(jq -r '.registryRoot // empty' "$MANIFEST")
ORIGINAL_SOCKET=$(jq -r '.socket // empty' "$MANIFEST")
```

Launch nested pinvim from the Pi side of the tmux layout:

```bash
tmux -S "$TEST_TMUX_SOCKET" split-window -h -l 45 -t "$PI_PANE" \
  -e "PINVIM_PARENT_ID=$PARENT_ID" \
  -e "PINVIM_WORKSPACE_ID=$WORKSPACE_ID" \
  -e "PINVIM_INSTANCE_ID=$INSTANCE_ID" \
  -e "PINVIM_REGISTRY_ROOT=$REGISTRY_ROOT" \
  -e "PI_SOCKET=$ORIGINAL_SOCKET" \
  "cd '$WT' && devenv shell -- pinvim --no-session -p '/pinvim-health'; read -n 1"
sleep 5
NESTED_PANE=$(tmux -S "$TEST_TMUX_SOCKET" list-panes -t "$TEST_SESSION" -F '#{pane_id}	#{pane_current_command}	#{pane_title}' | tail -1 | cut -f1)
tmux -S "$TEST_TMUX_SOCKET" capture-pane -p -J -t "$NESTED_PANE" -S -120
```

Expected nested output:

- `Relation: attach-only`
- `Nested attach-only: yes`
- `Socket: (disabled)` or no bound original socket

Verify original link still works:

```bash
tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$PI_PANE" '/pinvim-health' Enter
sleep 1
tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$NVIM_PANE" Escape 'gpa'
sleep 1
tmux -S "$TEST_TMUX_SOCKET" capture-pane -p -J -t "$PI_PANE" -S -120
```

Expected:

- Original Pi remains active parent link.
- `gpa` from original Nvim targets original Pi, not nested pane.

## Registry fast-path test

Goal: exact parent registry wins; scans do not pick unrelated child/ephemeral sockets.

```bash
tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$PI_PANE" '/pinvim-doctor' Enter
sleep 1
tmux -S "$TEST_TMUX_SOCKET" capture-pane -p -J -t "$PI_PANE" -S -160

tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$NVIM_PANE" Escape ':PiInfo' Enter
sleep 1
tmux -S "$TEST_TMUX_SOCKET" capture-pane -p -J -t "$NVIM_PANE" -S -120
```

Expected:

- Doctor reports parent/workspace/instance ids.
- Socket source is registry/main for parent session.
- Repair candidate is empty during healthy exact-registry state.
- Manual `:PiSessions` / `:PiTarget` still lists selectable sessions when explicitly requested.

## Dirty-buffer safety test

Goal: external file writes do not clobber modified Nvim buffers.

```bash
TEST_FILE="$WT/.local_scripts/pinvim-dirty-test.txt"
mkdir -p "$WT/.local_scripts"
printf 'one\n' > "$TEST_FILE"
tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$NVIM_PANE" Escape ":edit $TEST_FILE" Enter
sleep 1
tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$NVIM_PANE" 'Go'
tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$NVIM_PANE" 'dirty in nvim' Escape
printf 'external write\n' > "$TEST_FILE"
```

Trigger editor refresh path for the ticket under test, usually through Pi-side editor-service method or file-change hook. Then inspect Nvim:

```bash
tmux -S "$TEST_TMUX_SOCKET" capture-pane -p -J -t "$NVIM_PANE" -S -80
```

Expected:

- Buffer remains modified.
- Nvim does not overwrite `dirty in nvim` with disk content.
- User sees warning/diagnostic about external change.

## Ephemeral auto-resume retirement test

Goal: old ephemeral/child panes do not become parent target automatically.

```bash
tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$NVIM_PANE" Escape ':PiSplit' Enter
sleep 3
# Close or park child, then reopen main panel.
tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$NVIM_PANE" Escape ':PiPanel' Enter
sleep 2
tmux -S "$TEST_TMUX_SOCKET" send-keys -t "$PI_PANE" '/pinvim-status' Enter
sleep 1
tmux -S "$TEST_TMUX_SOCKET" capture-pane -p -J -t "$PI_PANE" -S -100
```

Expected:

- Parent status never reports `manifest-ephemeral` as automatic target source.
- Main panel returns to durable parent-owned session.
- Child remains child-only or exits.

## Cleanup

Only clean up the dedicated test session on the private tmux socket:

```bash
tmux -S "$TEST_TMUX_SOCKET" list-panes -t "$TEST_SESSION" -F '#{pane_id}	#{pane_current_command}	#{pane_title}'
tmux -S "$TEST_TMUX_SOCKET" kill-session -t "$TEST_SESSION"
```

If the private socket remains after the tmux server exits, remove it with `trash`. Also trash scratch files you created:

```bash
[ -S "$TEST_TMUX_SOCKET" ] && trash "$TEST_TMUX_SOCKET" 2>/dev/null || true
trash "$WT/.local_scripts/pinvim-dirty-test.txt" 2>/dev/null || true
```

## Required final report

Every run must end with a concise pass/fail overview. Do not say "seems fine" without this matrix.

Use this shape:

| Test                | Expected                     | Observed                             | Pass/fail | Evidence                     |
| ------------------- | ---------------------------- | ------------------------------------ | --------- | ---------------------------- |
| Kitty remote        | `kitty @ ls` connects        | `unix:/tmp/mykitty-64529` connected  | pass      | `/tmp/pinvim-kitty-ls.json`  |
| Nvim `:PiPanel`     | opens/reuses parent Pi       | one Pi pane, stable socket           | pass      | pane list + `/pinvim-health` |
| Nvim `gpa`          | attach-only; no turn         | pending context notice               | pass      | `gpa.pi.capture`             |
| Nvim `gps`          | starts Pi turn with context  | response received                    | pass      | `gps.pi.capture`             |
| Pi `/pinvim-health` | relation/socket/peer clear   | relation parent, active peer nvim... | pass      | `pinvim-health.pi.capture`   |
| Nested pinvim       | attach-only, socket disabled | relation attach-only                 | pass      | nested pane capture          |

For each pinvim ticket, report:

- Commands run.
- Kitty/tmux session name and kitty remote socket.
- Pane IDs for Nvim, main Pi, child Pi, nested Pi.
- Full result matrix with `pass`, `fail`, `blocked`, or `needs-investigation` for each test.
- Key health lines: relation, socket, active peer, editor-service state.
- Nvim command results: `:PiInfo`, `:PiHealth`, `:PiDoctor`, `:PiStatus`, `:PiSessions`, `:PiTarget` when relevant.
- Nvim action results: `:PiPanel`, `:PiPanel!`, `:PiSplit`, `gpa`, visual `gpa`, `gps`, visual `gps` when relevant.
- Pi command results: `/pinvim-info`, `/pinvim-health`, `/pinvim-status`, `/pinvim-doctor`, `/pinvim-context` when relevant.
- Whether Nvim actions routed to expected Pi pane.
- Whether Pi commands reported enough state to know behavior is working as expected.
- Any screenshots/captures if behavior is ambiguous.
- Cleanup result.

If any row is `fail` or `needs-investigation`, include:

- exact observed output line(s),
- expected output line(s),
- likely layer: kitty, tmux, Nvim, `pimux`, Pi wrapper, Pi extension, registry, editor service, model/provider,
- next diagnostic command.
