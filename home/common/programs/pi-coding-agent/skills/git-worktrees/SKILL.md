---
name: git-worktrees
description: Git worktree conventions and commands. Use when creating, switching to, or cleaning up git worktrees for branch work.
---

# Git worktrees

Do branch work in git worktrees under `<repo>/.worktrees/<branch>`, not in the main checkout. Pi runs non-interactive bash tool calls, so do not rely on Fish aliases/functions like `gwnew`, `gwpr`, `gwcd`, `gwprune`, `git-worktree-*`.

## Core worktree files

Some repo-local environment files are intentionally untracked but still needed in every worktree. After creating a worktree, copy missing core files from the main checkout into the new worktree.

Default core files:

```bash
worktree_core_files=(
  .env
  .envrc
  devenv.nix
  devenv.yaml
  devenv.lock
  .pre-commit-config.yaml
)
```

To add more files, extend `worktree_core_files` in the command before the copy loop. Keep this list near worktree creation commands so repo-specific additions are obvious.

Copy rules:

- Copy only files that exist in `$repo_root`.
- Do not overwrite files already present in the worktree.
- Preserve symlinks as symlinks.
- These files are often untracked or gitignored, so do not expect `git worktree add` to bring them over.

**`devenv.lock` is critical and easy to miss.** It is usually untracked/gitignored, so `git worktree add` does not bring it over. Without it, the first `devenv` call in the fresh worktree tries to re-lock flake inputs and fails with `authentication required but no callback set` (fetching `github:cachix/devenv`). Always copy `devenv.lock` so the worktree reuses the locked inputs.

**Trust mise in the new worktree (if the repo uses mise).** When the repo has a `mise.toml`/`.mise.toml`, mise treats the fresh worktree path as untrusted. The first interactive shell or direnv load in that directory blocks on a prompt:

```
mise config files in <worktree> are not trusted. Trust them?
   Yes     No     All
←/→ toggle • y/n/a/enter submit
```

Trust it **non-interactively right after copying core files** so the prompt never blocks setup or the tmux session:

```bash
if [ -e "$worktree_path/mise.toml" ] || [ -e "$worktree_path/.mise.toml" ]; then
  mise trust "$worktree_path" 2>/dev/null || (cd "$worktree_path" && mise trust 2>/dev/null) || true
fi
```

If a tmux session is already sitting on the prompt, select **All** by sending `a` (the prompt accepts `y/n/a/enter`), then confirm trust cleared:

```bash
tmux send-keys -t "$tmux_session" a
sleep 1
mise trust --show 2>&1 | rg "$tmux_session|$branch"   # expect "<worktree>: trusted"
```

After creating a worktree and copying core files, run the one-time worktree setup task when available:

- Only run this immediately after a successful `git worktree add`, not when re-entering an existing worktree.
- Require `devenv.nix` in the new worktree.
- Require a `worktree:setup` task in `devenv tasks list`.
- **Detect the task without swallowing stderr.** The first `devenv tasks list` in a fresh worktree is a cold eval (often 15-25s) and can fail (e.g. missing `devenv.lock`). Never pipe it through `2>/dev/null` — that hides lock/auth failures and yields a false "no task found", causing setup to be skipped silently. Capture combined output, then grep it; if the task is absent, print the captured output so the real failure is visible.
- Give the detection call a generous timeout (>= 300s) to absorb the cold eval.
- Run `devenv tasks run worktree:setup` from the worktree cwd.
- Log setup output to `$worktree_path/.worktree-setup.log` and run in background.
- The wrapper appends `WORKTREE_SETUP_EXIT=N` as the final line so the agent can check the result.
- **Monitor with a tight sentinel-poll, never a blind `sleep` (see "Monitoring runs" below).** Poll the log for the `WORKTREE_SETUP_EXIT=` line every ~3s and break the instant it appears; cap the loop. Do not `sleep` a fixed long duration — past runs sat idle for minutes after the task had already failed.

**Post-setup verification (REQUIRED):**

The tight-poll loop already breaks on completion. Then verify:

1. Sentinel present and zero: `rg -o 'WORKTREE_SETUP_EXIT=[0-9]+' "$setup_log" | tail -1` must be `WORKTREE_SETUP_EXIT=0`.
2. If the loop hit its cap without a sentinel, setup is still running or wedged — report last 30 lines, do not claim ready.
3. Scan for failures: `rg -i 'failed|\(exit status|exception|authentication required|eaddrinuse|WORKTREE_SETUP_EXIT=[^0]' "$setup_log" | head -20`.
4. **If any errors found:** report them with relevant log lines. Do NOT say "worktree is ready".
5. **Only if `WORKTREE_SETUP_EXIT=0` and no error patterns:** confirm worktree is fully ready.

After setup completes, create a detached tmux session for the worktree:

- Session name: `<repo_basename>-<branch>` (e.g. repo at `~/code/work/strive/rx` with branch `sm-spp-custom-strength` → session `rx-sm-spp-custom-strength`).
- Start detached (`-d`) so it doesn't switch focus.
- Two windows, both cwd'd to the worktree path: window 1 named `code`, window 2 named `services`.
- After `worktree:setup`, if a `worktree:services` devenv task exists, run `devenv tasks run worktree:services` in the `services` window (window 2). Leave focus on window 2.
- Skip if a tmux session with that name already exists.

```bash
for file in "${worktree_core_files[@]}"; do
  src="$repo_root/$file"
  dest="$worktree_path/$file"
  if [ -e "$src" ] || [ -L "$src" ]; then
    if [ ! -e "$dest" ] && [ ! -L "$dest" ]; then
      mkdir -p "$(dirname "$dest")"
      cp -a "$src" "$dest"
    fi
  fi
done

# GIT_WORKTREE: read by config/dev.exs & config/test.exs for the per-worktree DB suffix + port offset.
# Append to the worktree's .env so mise (_.file = '.env') / direnv export it into every interactive
# and login shell, and into mix/devenv subprocesses run from the worktree. Sanitize the name to
# [A-Za-z0-9_-] (spaces, slashes, etc. -> '-') so it is a valid Postgres database-name suffix.
if [ ! -f "$worktree_path/.env" ] || ! rg -q '^GIT_WORKTREE=' "$worktree_path/.env"; then
  git_worktree=$(printf '%s' "$branch" | sed 's/[^A-Za-z0-9_-]/-/g')
  printf 'GIT_WORKTREE=%s\n' "$git_worktree" >> "$worktree_path/.env"
fi

# Trust mise in the fresh worktree so its prompt never blocks setup/tmux.
if [ -e "$worktree_path/mise.toml" ] || [ -e "$worktree_path/.mise.toml" ]; then
  mise trust "$worktree_path" 2>/dev/null || (cd "$worktree_path" && mise trust 2>/dev/null) || true
fi

# Detect + run the one-time setup task. Keep stderr; tolerate the slow cold eval.
if [ -e "$worktree_path/devenv.nix" ] || [ -L "$worktree_path/devenv.nix" ]; then
  tasks_out=$(cd "$worktree_path" && devenv tasks list 2>&1)
  if printf '%s\n' "$tasks_out" | rg -q 'worktree:setup'; then
    setup_log="$worktree_path/.worktree-setup.log"
    (cd "$worktree_path" && devenv tasks run worktree:setup; echo "WORKTREE_SETUP_EXIT=$?") > "$setup_log" 2>&1 &
    setup_pid=$!
    echo "Setup running in background (PID $setup_pid), log: $setup_log"
  else
    echo "No worktree:setup task found, or devenv failed to load. devenv output:"
    printf '%s\n' "$tasks_out" | tail -20
  fi
fi

# Create detached tmux session for the worktree
repo_name=$(basename "$repo_root")
tmux_session="${repo_name}-${branch}"
if ! tmux has-session -t "$tmux_session" 2>/dev/null; then
  tmux new-session -d -s "$tmux_session" -c "$worktree_path" -n code
  tmux setenv -t "$tmux_session" DEVENV_CWD "$worktree_path"
  tmux new-window -t "$tmux_session" -c "$worktree_path" -n services
  # After worktree:setup, start services in window 2 when the task exists.
  if printf '%s\n' "$tasks_out" | rg -q 'worktree:services'; then
    tmux send-keys -t "${tmux_session}:services" 'devenv tasks run worktree:services' Enter
  fi
  # Leave focus on the services window (window 2).
  tmux select-window -t "${tmux_session}:services"
fi
```

## GIT_WORKTREE env var

`config/dev.exs` and `config/test.exs` read `GIT_WORKTREE` to derive a per-worktree database-name suffix and a deterministic port offset. When it is unset (the main checkout) names and ports keep their plain base values, so concurrent worktrees get isolated databases and a collision-free port block.

Set it per worktree by appending `GIT_WORKTREE=<worktree name>` to the worktree's own `.env`. The repo loads `.env` through mise (`[env] _.file = '.env'`), and direnv if present, so the variable is exported into every interactive and login shell in that directory and into `mix`/`devenv` subprocesses run there. The creation commands below do this idempotently right after copying core files (skipped if a `GIT_WORKTREE=` line already exists).

The value is sanitized to `[A-Za-z0-9_-]` — spaces, slashes, and other characters are replaced with `-`, while existing `-` and `_` are kept — so a branch like `feat/new ui` yields `GIT_WORKTREE=feat-new-ui`, a valid Postgres database-name suffix.

## Commands

### New branch worktree

```bash
repo_root=$(git rev-parse --show-toplevel)
worktree_path="$repo_root/.worktrees/$branch"
worktree_core_files=(.env .envrc devenv.nix devenv.yaml devenv.lock .pre-commit-config.yaml)
mkdir -p "$repo_root/.worktrees"
git worktree add "$worktree_path" -b "$branch"
for file in "${worktree_core_files[@]}"; do
  src="$repo_root/$file"
  dest="$worktree_path/$file"
  if [ -e "$src" ] || [ -L "$src" ]; then
    if [ ! -e "$dest" ] && [ ! -L "$dest" ]; then
      mkdir -p "$(dirname "$dest")"
      cp -a "$src" "$dest"
    fi
  fi
done
if [ ! -f "$worktree_path/.env" ] || ! rg -q '^GIT_WORKTREE=' "$worktree_path/.env"; then
  git_worktree=$(printf '%s' "$branch" | sed 's/[^A-Za-z0-9_-]/-/g')
  printf 'GIT_WORKTREE=%s\n' "$git_worktree" >> "$worktree_path/.env"
fi
if [ -e "$worktree_path/mise.toml" ] || [ -e "$worktree_path/.mise.toml" ]; then
  mise trust "$worktree_path" 2>/dev/null || (cd "$worktree_path" && mise trust 2>/dev/null) || true
fi
if [ -e "$worktree_path/devenv.nix" ] || [ -L "$worktree_path/devenv.nix" ]; then
  tasks_out=$(cd "$worktree_path" && devenv tasks list 2>&1)
  if printf '%s\n' "$tasks_out" | rg -q 'worktree:setup'; then
    setup_log="$worktree_path/.worktree-setup.log"
    (cd "$worktree_path" && devenv tasks run worktree:setup; echo "WORKTREE_SETUP_EXIT=$?") > "$setup_log" 2>&1 &
    echo "Setup running in background (PID $!), log: $setup_log"
  else
    echo "No worktree:setup task found, or devenv failed to load. devenv output:"
    printf '%s\n' "$tasks_out" | tail -20
  fi
fi
repo_name=$(basename "$repo_root")
tmux_session="${repo_name}-${branch}"
if ! tmux has-session -t "$tmux_session" 2>/dev/null; then
  tmux new-session -d -s "$tmux_session" -c "$worktree_path" -n code
  tmux setenv -t "$tmux_session" DEVENV_CWD "$worktree_path"
  tmux new-window -t "$tmux_session" -c "$worktree_path" -n services
  # After worktree:setup, start services in window 2 when the task exists.
  if printf '%s\n' "$tasks_out" | rg -q 'worktree:services'; then
    tmux send-keys -t "${tmux_session}:services" 'devenv tasks run worktree:services' Enter
  fi
  # Leave focus on the services window (window 2).
  tmux select-window -t "${tmux_session}:services"
fi
```

> To branch off a specific base (e.g. latest `origin/main`), `git fetch origin` first and use `git worktree add "$worktree_path" -b "$branch" origin/main`.

Then monitor setup with the tight sentinel-poll (separate bash call, timeout 300s) — see "Monitoring runs" below. It breaks the instant `WORKTREE_SETUP_EXIT=` appears:

```bash
setup_log="$worktree_path/.worktree-setup.log"
t=0; cap=280
while [ "$t" -lt "$cap" ]; do
  rg -q 'WORKTREE_SETUP_EXIT=' "$setup_log" 2>/dev/null && break
  sleep 3; t=$((t+3))
done
code=$(rg -o 'WORKTREE_SETUP_EXIT=[0-9]+' "$setup_log" | tail -1)
echo "setup ${code:-<none: still running after ${cap}s>} (~${t}s)"
rg -i 'failed|\(exit status|exception|authentication required|eaddrinuse|could not start' "$setup_log" | tail -20 || true
```

### PR branch worktree (branch name known)

```bash
repo_root=$(git rev-parse --show-toplevel)
worktree_path="$repo_root/.worktrees/$branch"
worktree_core_files=(.env .envrc devenv.nix devenv.yaml devenv.lock .pre-commit-config.yaml)
mkdir -p "$repo_root/.worktrees"
pr_number=$(gh pr list --state open --head "$branch" --json number --jq '.[0].number')
git fetch origin "pull/$pr_number/head:$branch"
git worktree add "$worktree_path" "$branch"
for file in "${worktree_core_files[@]}"; do
  src="$repo_root/$file"
  dest="$worktree_path/$file"
  if [ -e "$src" ] || [ -L "$src" ]; then
    if [ ! -e "$dest" ] && [ ! -L "$dest" ]; then
      mkdir -p "$(dirname "$dest")"
      cp -a "$src" "$dest"
    fi
  fi
done
if [ ! -f "$worktree_path/.env" ] || ! rg -q '^GIT_WORKTREE=' "$worktree_path/.env"; then
  git_worktree=$(printf '%s' "$branch" | sed 's/[^A-Za-z0-9_-]/-/g')
  printf 'GIT_WORKTREE=%s\n' "$git_worktree" >> "$worktree_path/.env"
fi
if [ -e "$worktree_path/mise.toml" ] || [ -e "$worktree_path/.mise.toml" ]; then
  mise trust "$worktree_path" 2>/dev/null || (cd "$worktree_path" && mise trust 2>/dev/null) || true
fi
if [ -e "$worktree_path/devenv.nix" ] || [ -L "$worktree_path/devenv.nix" ]; then
  tasks_out=$(cd "$worktree_path" && devenv tasks list 2>&1)
  if printf '%s\n' "$tasks_out" | rg -q 'worktree:setup'; then
    setup_log="$worktree_path/.worktree-setup.log"
    (cd "$worktree_path" && devenv tasks run worktree:setup; echo "WORKTREE_SETUP_EXIT=$?") > "$setup_log" 2>&1 &
    echo "Setup running in background (PID $!), log: $setup_log"
  else
    echo "No worktree:setup task found, or devenv failed to load. devenv output:"
    printf '%s\n' "$tasks_out" | tail -20
  fi
fi
repo_name=$(basename "$repo_root")
tmux_session="${repo_name}-${branch}"
if ! tmux has-session -t "$tmux_session" 2>/dev/null; then
  tmux new-session -d -s "$tmux_session" -c "$worktree_path" -n code
  tmux setenv -t "$tmux_session" DEVENV_CWD "$worktree_path"
  tmux new-window -t "$tmux_session" -c "$worktree_path" -n services
  # After worktree:setup, start services in window 2 when the task exists.
  if printf '%s\n' "$tasks_out" | rg -q 'worktree:services'; then
    tmux send-keys -t "${tmux_session}:services" 'devenv tasks run worktree:services' Enter
  fi
  # Leave focus on the services window (window 2).
  tmux select-window -t "${tmux_session}:services"
fi
```

Then tail + verify same as new branch worktree above.

## Monitoring runs (no blind sleeps)

Never wait on a fixed `sleep` for a worktree task/server — it wastes minutes after a run has already finished or failed. Use the matching event-driven pattern. All three below are tested and proven on the rx repo.

**Important shell note:** the worktree tmux windows run **fish**, so bash syntax sent via `tmux send-keys` (`{ ...; }`, `$?`) silently fails to execute. Always send commands through a **bash runner script** so they run under bash regardless of the window shell. Parse exit codes with `sed` (not `rg`) — a user `rg` config may force `line:col:` prefixes that corrupt captured values.

### Pattern A — background task with a sentinel file (e.g. `worktree:setup`)

**Two hard rules, both learned the hard way:**

1. **Fully detach the launch** so it survives the launching bash call, and let that call **return immediately** (do not wait). A plain `( … ) &` that the same call then waits on is a child of that shell — if the call is aborted or times out, the child is killed mid-build (no sentinel). Use `nohup … & disown` (note: `setsid` does NOT exist on macOS — use `nohup`).
2. **Poll in SHORT, SEPARATE bash calls** — never bundle the launch and a long wait loop into one call. A fresh worktree's `worktree:setup` (cold `deps.get` + full compile + `assets.setup` + `ecto.setup`) can exceed **5 minutes**, far past any single ~300s tool timeout. One blocking wait will hit the ceiling _and_ (if it kills the child) destroy the run. Launch in call 1; poll briefly in call 2, 3, … each returning immediately.

Launch (call 1) — detached, log ends in `WORKTREE_SETUP_EXIT=N`:

```bash
setup_log="$worktree_path/.worktree-setup.log"; : > "$setup_log"
nohup bash -c "cd '$worktree_path' && devenv tasks run worktree:setup; echo WORKTREE_SETUP_EXIT=\$?" > "$setup_log" 2>&1 < /dev/null &
disown
echo "setup launched (detached, pid $!)"   # this call returns NOW; do not wait here
```

Poll (each a SEPARATE short call — returns immediately):

```bash
setup_log="$worktree_path/.worktree-setup.log"
if rg -q 'WORKTREE_SETUP_EXIT=' "$setup_log" 2>/dev/null; then
  echo "done -> $(rg -o 'WORKTREE_SETUP_EXIT=[0-9]+' "$setup_log" | tail -1)"   # expect =0
  rg -i 'eaddrinuse|could not start|\(exit status|constraint|exception' "$setup_log" | tail -8 || true
else
  echo "still running ($(wc -l < "$setup_log") log lines); last:"; tail -2 "$setup_log"
fi
```

Repeat the poll call (optionally `sleep 15` _inside that short call_ first) until it reports done. Never sit in a single call burning the whole timeout budget.

### Pattern B — command in a tmux window that EXITS (event-driven via `tmux wait-for`)

Returns the instant the command finishes (proven ~0.06–0.2s), with exact exit code and an error scan. One-time runner:

```bash
cat > /tmp/wt_run.sh <<'EOF'
#!/usr/bin/env bash
chan="$1"; shift
"$@"; code=$?
printf '\n__WT_EXIT_%s__\n' "$code"
tmux wait-for -S "$chan"
exit "$code"
EOF
chmod +x /tmp/wt_run.sh
```

```bash
watch_win() {  # $1=session:window  $2=timeout_secs  rest=command
  local win="$1" to="$2"; shift 2
  local log chan; log="$(mktemp /tmp/wtmon.XXXX.log)"; chan="wtmon-$RANDOM"
  tmux pipe-pane -t "$win" -o "cat >> '$log'"
  tmux send-keys -t "$win" "bash /tmp/wt_run.sh $chan $*" Enter
  timeout "$to" tmux wait-for "$chan" || { echo "[monitor] TIMEOUT ${to}s log=$log"; tmux pipe-pane -t "$win"; return 124; }
  tmux pipe-pane -t "$win"
  local code; code="$(sed -n 's/.*__WT_EXIT_\([0-9]\{1,\}\)__.*/\1/p' "$log" | tail -1)"
  echo "[monitor] exit=${code:-?}  errors=$(rg -ic 'eaddrinuse|could not start|\(exit status|exception' "$log" 2>/dev/null || echo 0)  log=$log"
}
# usage: watch_win "rx-$branch:services" 180 devenv tasks run worktree:setup
```

### Pattern C — long-running SERVER in a tmux window (e.g. `worktree:services` → `start-phx`)

A server never exits, so do NOT wait for completion and do NOT grep the log for a "ready" line (iex buffers it and `pipe-pane` may miss it). The robust signal is **the port actually listening**. start-phx writes the chosen port to `.devenv/state/phoenix.port`:

```bash
tmux send-keys -t "rx-$branch:services" 'devenv tasks run worktree:services' Enter
portfile="$worktree_path/.devenv/state/phoenix.port"
t=0; cap=180; res=PENDING
while [ "$t" -lt "$cap" ]; do
  if [ -f "$portfile" ] && lsof -iTCP:"$(cat "$portfile")" -sTCP:LISTEN -t >/dev/null 2>&1; then res=UP; break; fi
  # fail fast on a hard boot error in the visible pane
  tmux capture-pane -t "rx-$branch:services" -p | rg -qi 'eaddrinuse|in use by another|validate_compile_env|could not start' && { res=FAILED; break; }
  sleep 3; t=$((t+3))
done
echo "phoenix=$res after ~${t}s"
[ "$res" = UP ] && curl -s -o /dev/null -w 'http %{http_code}\n' --max-time 4 "http://127.0.0.1:$(cat "$portfile")/"
```

Proven: with metrics + live_debugger disabled, a unique `SNAME`, and free `PORT`/`PGPORT`, the worktree app runs concurrently with the main checkout (e.g. listening on `:4001`, node `rx-<branch>`, postgres on its own allocated port).

**If `curl` returns `503` from a worktree that otherwise booted clean**, the most common cause is `Phoenix.Ecto.PendingMigrationError` (visible in the HTML body / `<title>`). Two flavors:

1. **App talked to the wrong DB** (the worktree's setup migrated DB `A` on its allocated port, but the running app fell back to `PGPORT=5432` and hit the _main checkout's_ DB `B`). Fix: ensure the launcher (e.g. `start-phx`) **exports `PGPORT`** — read the real port from `.devenv/state/postgres/postmaster.pid` line 4 and `export PGPORT="$PG_PORT"` before starting the server.
2. **DB legitimately needs migrating.** From the worktree run: `mix ecto.migrate` (and `MIX_ENV=test mix ecto.migrate` if tests will run). Pair with `mix ecto.migrations` to see pending ones.

Quick diagnose via `curl -s -i http://127.0.0.1:<port>/ | head -3` — if you see `Phoenix.Ecto.PendingMigrationError`, it's one of the above, not infra.

### Remove/prune

**ALWAYS run a full teardown BEFORE removing a worktree/branch.** Otherwise leftover postgres data, a running phoenix/iex node, and bound ports survive and corrupt the next run (stale `phoenix.port`, ports still held, DB not purged — the exact mess that produces phantom `503`s and `eaddrinuse`). Prefer the repo's `worktree:teardown` devenv task (stops phoenix by freeing its port, kills the iex node, runs `devenv processes down`); fall back to inline kills if the task is absent.

```bash
wt="$repo_root/.worktrees/$branch"
repo_name=$(basename "$repo_root")
tmux_session="${repo_name}-${branch}"

# 1. Full teardown while the directory still exists. Prefer the devenv task.
if (cd "$wt" 2>/dev/null && devenv tasks list 2>&1 | rg -q 'worktree:teardown'); then
  (cd "$wt" && devenv tasks run worktree:teardown) || true
else
  # fallback: free the phoenix port + stop devenv processes inline
  [ -f "$wt/.devenv/state/phoenix.port" ] && lsof -tiTCP:"$(cat "$wt/.devenv/state/phoenix.port")" -sTCP:LISTEN 2>/dev/null | xargs -r kill 2>/dev/null || true
  (cd "$wt" && devenv processes down 2>/dev/null) || true
fi

# 2. Kill the tmux session.
tmux kill-session -t "$tmux_session" 2>/dev/null || true

# 3. Remove the worktree (this also deletes its .devenv/state → fresh PGDATA next time) and branch.
git worktree remove "$wt" --force
git branch -D "$branch"  # only if branch exists
```

### Run commands in a worktree

Each bash call starts from session cwd:

```bash
cd "$repo_root/.worktrees/$branch" && <command>
```
