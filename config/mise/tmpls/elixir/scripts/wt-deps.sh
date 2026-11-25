#!/usr/bin/env bash
# Fetch deps, set up assets, and compile dev and test side by side.
# Run by `mise run wt:deps`, which puts the project's own Elixir on PATH: a
# mix from another Elixir would rebuild every dependency in _build.
#
# The two compiles write separate _build/dev and _build/test trees, so they
# run in parallel (measured 28.6 s instead of 37 s on provider_portal).
set -euo pipefail

mix deps.get
mix assets.setup

log_dir=.local/log
mkdir -p "$log_dir"
env MIX_ENV=dev mix compile >"$log_dir/compile-dev.log" 2>&1 &
pids=($!)
env MIX_ENV=test mix compile >"$log_dir/compile-test.log" 2>&1 &
pids+=($!)

failed=0
for env in dev test; do
  if wait "${pids[0]}"; then
    echo "compiled $env"
  else
    failed=1
    echo "error: $env compile failed; output follows ($log_dir/compile-$env.log)" >&2
    cat "$log_dir/compile-$env.log" >&2
  fi
  pids=("${pids[@]:1}")
done
exit "$failed"
