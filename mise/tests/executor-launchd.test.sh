#!/usr/bin/env bash
# executor-launchd: refuses to start without keys, hands the keys to
# `executor serve`, and backs up the data directory on a version change
# (keeping two backups). mise and executor are stubs.
set -euo pipefail

launcher="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)/executor-launchd"
test_root="$(mktemp -d)"
cleanup() {
  if [ -x /usr/bin/trash ]; then
    /usr/bin/trash "$test_root"
  else
    trash "$test_root"
  fi
}
trap cleanup EXIT

fail() {
  echo "FAIL: $1" >&2
  [ -n "${output:-}" ] && echo "$output" >&2
  exit 1
}

run() {
  output="$(
    trap - ERR
    "$launcher" 2>&1
  )" && status=0 || status=$?
}

export HOME="$test_root/home"
export XDG_CONFIG_HOME="$HOME/.config"
unset EXECUTOR_DATA_DIR
installs="$test_root/installs"
bin="$test_root/bin"
data="$HOME/.executor/v2/cli"
backups="$HOME/.executor/v2/backups"
mkdir -p "$HOME" "$bin"
export PATH="$bin:/usr/bin:/bin"

# `mise which executor` names the stub of $VERSION; the stub records its env.
printf '%s\n' '#!/usr/bin/env bash' \
  '[ "$1 $2" = "which executor" ] || exit 2' \
  "echo \"$installs/\$VERSION/executor\"" >"$bin/mise"
chmod +x "$bin/mise"
install_version() {
  mkdir -p "$installs/$1"
  printf '%s\n' '#!/usr/bin/env bash' \
    "echo \"\$* key=\$EXECUTOR_API_KEY enc=\$EXECUTOR_ENCRYPTION_KEY dnt=\$DO_NOT_TRACK\" >\"$test_root/calls\"" \
    >"$installs/$1/executor"
  chmod +x "$installs/$1/executor"
}

export VERSION=2.0.0-beta.1
install_version "$VERSION"

run
[ "$status" -ne 0 ] || fail "starts without keys"
[[ "$output" == *"run mise run setup:executor"* ]] || fail "missing-key message"

mkdir -p "$XDG_CONFIG_HOME/executor"
printf 'api-key-0123456789abcdef0123456789abcdef\n' >"$XDG_CONFIG_HOME/executor/api_key"
printf '%064d\n' 7 >"$XDG_CONFIG_HOME/executor/encryption_key"

run
[ "$status" -eq 0 ] || fail "first start"
expected="serve key=api-key-0123456789abcdef0123456789abcdef enc=$(printf '%064d' 7) dnt=1"
[ "$(cat "$test_root/calls")" = "$expected" ] || fail "serve env: $(cat "$test_root/calls")"
[ ! -e "$data" ] || fail "created the data directory itself"

mkdir -p "$data" && echo state >"$data/db"
run
[ "$status" -eq 0 ] || fail "second start"
[ "$(cat "$data/.megadots-version")" = 2.0.0-beta.1 ] || fail "version marker"
[ ! -d "$backups" ] || fail "backed up without a version change"

# Each version writes its own state; the next upgrade backs that state up.
for n in 2 3 4; do
  export VERSION="2.0.0-beta.$n"
  install_version "$VERSION"
  run
  [ "$status" -eq 0 ] || fail "start on beta.$n"
  echo "state $n" >"$data/db"
  sleep 1 # backup names carry the second
done
[ "$(cat "$data/.megadots-version")" = 2.0.0-beta.4 ] || fail "marker after upgrades"
kept="$(cd "$backups" && printf '%s ' mise-* | sed -E 's/mise-[0-9]{8}T[0-9]{6}-//g')"
[ "$kept" = "2.0.0-beta.2 2.0.0-beta.3 " ] || fail "kept backups: $kept"
[ "$(cat "$backups"/mise-*-2.0.0-beta.3/db)" = "state 3" ] || fail "backup content"

echo "executor-launchd: ok"
