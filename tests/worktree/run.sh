#!/usr/bin/env bash
# Phase 1 black-box contract tests. All Git and tmux mutations stay under TMPDIR.
set -u

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HERE="$(cd "$(dirname "$0")" && pwd)"
MODE="${1:-self-test}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/wt-fixture.XXXXXX")"
# Physical path: kernel-reported pane cwds (#{pane_current_path}) resolve
# symlinks (/var -> /private/var on macOS), so fixture paths must be physical
# for exact-path comparisons.
TMP="$(cd "$TMP" && pwd -P)"
REAL_TMUX="$(command -v tmux || true)"
TMUX_SOCKET="wt-fixture-${TMP##*.}"
LOG="$TMP/events.tsv"
OUT="$TMP/stdout"
ERR="$TMP/stderr"
PASS_COUNT=0
FAIL_COUNT=0
WHY=""

cleanup() {
  trap - EXIT INT TERM
  if [ -n "$REAL_TMUX" ]; then
    "$REAL_TMUX" -L "$TMUX_SOCKET" -f /dev/null kill-server >/dev/null 2>&1 || true
  fi
  trash "$TMP" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}
need() { command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"; }
for command in git jq rg awk perl trash; do need "$command"; done
[ -n "$REAL_TMUX" ] || fail 'missing required command: tmux'

mkdir -p "$TMP/bin" "$TMP/home" "$TMP/tmux"
: >"$LOG"
: >"$OUT"
: >"$ERR"
export HOME="$TMP/home" XDG_CONFIG_HOME="$TMP/home/.config" XDG_STATE_HOME="$TMP/home/.local/state"
export TMUX=""
SOURCE_STATUS_BEFORE="$(git -C "$ROOT" status --porcelain=v1 -z | shasum -a 256 | awk '{print $1}')"
SOURCE_README_BEFORE="$(shasum -a 256 "$ROOT/README.md" | awk '{print $1}')"
export FIXTURE_LOG="$LOG" FIXTURE_BACKEND="$TMP/bin/wt-backend" WT_VERSION=0.76.0
export FIXTURE_REPO="$TMP/repo" FIXTURE_WORKTREE="$TMP/repo/.worktrees/feature-login"
export FIXTURE_SECOND_WORKTREE="$TMP/repo/.worktrees/feature-two" FIXTURE_OUTSIDE_WORKTREE="$TMP/outside-linked"
export FIXTURE_BROKEN_WORKTREE="$TMP/repo/.worktrees/broken-private"
export FIXTURE_OTHER_REPO="$TMP/other" FIXTURE_ESCAPE="$TMP/repo/.worktrees/escape"
export FTM_STATE_DIR="$TMP/ftm" TMUX_LAYOUTS="$TMP/layouts" TMUX_HOOKS="$TMP/hooks"

cp "$HERE/fixtures.sh" "$TMP/bin/fixture"
chmod +x "$TMP/bin/fixture"
for name in mise pi service; do ln -s fixture "$TMP/bin/$name"; done
ln -s fixture "$TMP/bin/wt-backend"
cat >"$TMP/bin/tmux" <<'TMUX_WRAPPER'
#!/usr/bin/env bash
printf 'tmux\t%s\t%s\t%s\tstdin=unchecked\tauto_install=%s\n' "${WT_SCENARIO:-success}" "$PWD" "$*" "${MISE_AUTO_INSTALL:-unset}" >>"${FIXTURE_LOG:?}"
exec "${REAL_TMUX:?}" -L "${TMUX_SOCKET:?}" -f /dev/null "$@"
TMUX_WRAPPER
cat >"$TMP/bin/ftm" <<'FTM_WRAPPER'
#!/usr/bin/env bash
printf 'ftm\t%s\t%s\t%s\tstdin=unchecked\tauto_install=%s\n' "${WT_SCENARIO:-success}" "$PWD" "$*" "${MISE_AUTO_INSTALL:-unset}" >>"${FIXTURE_LOG:?}"
[ "${FIXTURE_FTM_RECORD_ONLY:-0}" = 0 ] || exit 0
exec "${FIXTURE_FTM_BIN:?}" "$@"
FTM_WRAPPER
chmod +x "$TMP/bin/tmux" "$TMP/bin/ftm"
export REAL_TMUX TMUX_SOCKET PATH="$TMP/bin:$PATH"

setup_git() {
  git init -q --bare "$TMP/origin.git" || return 1
  git clone -q "$TMP/origin.git" "$FIXTURE_REPO" || return 1
  git -C "$FIXTURE_REPO" config user.email fixture@example.test
  git -C "$FIXTURE_REPO" config user.name fixture
  printf 'main\n' >"$FIXTURE_REPO/tracked.txt"
  git -C "$FIXTURE_REPO" add tracked.txt
  git -C "$FIXTURE_REPO" commit -qm initial
  git -C "$FIXTURE_REPO" branch -M main
  git -C "$FIXTURE_REPO" push -q -u origin main
  git -C "$FIXTURE_REPO" worktree add -q -b feature/login "$FIXTURE_WORKTREE" main
  printf 'feature\n' >>"$FIXTURE_WORKTREE/tracked.txt"
  git -C "$FIXTURE_WORKTREE" commit -qam feature
  git -C "$FIXTURE_REPO" worktree add -q -b feature/two "$FIXTURE_SECOND_WORKTREE" main
  git -C "$FIXTURE_REPO" worktree add -q -b outside-linked "$FIXTURE_OUTSIDE_WORKTREE" main
  git -C "$FIXTURE_REPO" branch remote-only main
  git -C "$FIXTURE_REPO" push -q origin remote-only
  git -C "$FIXTURE_REPO" branch -D remote-only >/dev/null
  git init -q "$FIXTURE_OTHER_REPO"
  git -C "$FIXTURE_OTHER_REPO" config user.email fixture@example.test
  git -C "$FIXTURE_OTHER_REPO" config user.name fixture
  : >"$FIXTURE_OTHER_REPO/other"
  git -C "$FIXTURE_OTHER_REPO" add other
  git -C "$FIXTURE_OTHER_REPO" commit -qm other
  ln -s "$FIXTURE_OTHER_REPO" "$FIXTURE_ESCAPE"
  mkdir -p "$FIXTURE_BROKEN_WORKTREE"
  printf 'gitdir: %s\n' "$TMP/nonexistent-private-git-dir" >"$FIXTURE_BROKEN_WORKTREE/.git"
  FIXTURE_MAIN_HEAD="$(git -C "$FIXTURE_REPO" rev-parse main)"
  FIXTURE_FEATURE_HEAD="$(git -C "$FIXTURE_REPO" rev-parse feature/login)"
  FIXTURE_COMMON_DIR="$(git -C "$FIXTURE_REPO" rev-parse --path-format=absolute --git-common-dir)"
  FIXTURE_PRIVATE_DIR="$(git -C "$FIXTURE_WORKTREE" rev-parse --path-format=absolute --git-dir)"
  export FIXTURE_MAIN_HEAD FIXTURE_FEATURE_HEAD FIXTURE_COMMON_DIR FIXTURE_PRIVATE_DIR
}

reset_case() {
  "$REAL_TMUX" -L "$TMUX_SOCKET" -f /dev/null kill-server >/dev/null 2>&1 || true
  : >"$LOG"
  : >"$OUT"
  : >"$ERR"
  WHY=""
  unset FIXTURE_SETUP_RC FIXTURE_TASKS FIXTURE_BLOCK_READY FIXTURE_BLOCK_RELEASE FIXTURE_SWITCH_BRANCH
  trash "$TMP/block-ready" "$TMP/block-release" "$TMP/first-out" "$TMP/first-err" "$TMP/second-out" >/dev/null 2>&1 || true
  git -C "$FIXTURE_REPO" update-ref refs/heads/feature/login "$FIXTURE_FEATURE_HEAD" >/dev/null 2>&1 || true
}

bounded_capture() {
  run_cwd="$1"
  shift
  perl -MPOSIX -e 'POSIX::setpgid(0, 0); chdir shift @ARGV or exit 125; exec @ARGV' \
    "$run_cwd" "$@" </dev/null >"$OUT" 2>"$ERR" &
  run_pid=$!
  ticks=0
  while kill -0 "$run_pid" 2>/dev/null; do
    ticks=$((ticks + 1))
    if [ "$ticks" -ge 50 ]; then
      kill -TERM -- "-$run_pid" >/dev/null 2>&1 || kill "$run_pid" >/dev/null 2>&1 || true
      sleep 0.1
      kill -KILL -- "-$run_pid" >/dev/null 2>&1 || true
      wait "$run_pid" >/dev/null 2>&1 || true
      RUN_RC=124
      return 0
    fi
    sleep 0.1
  done
  set +e
  wait "$run_pid"
  RUN_RC=$?
  set -e
}

wt_capture() {
  scenario="$1"
  run_cwd="$2"
  shift 2
  bounded_capture "$run_cwd" env \
    MISE_AUTO_INSTALL=false WORKTRUNK_BIN="$FIXTURE_BACKEND" FTM_NO_ATTACH=1 \
    WT_SCENARIO="$scenario" FIXTURE_FTM_BIN="$FTM_BIN" TMUX="" \
    "$WT_BIN" "$@"
}

ftm_capture() {
  scenario="$1"
  shift
  bounded_capture "$FIXTURE_REPO" env \
    MISE_AUTO_INSTALL=false WT_SCENARIO="$scenario" FIXTURE_FTM_BIN="$FTM_BIN" \
    FTM_NO_ATTACH=1 TMUX="$TMP/not-a-client,0,0" \
    "$FTM_BIN" "$@"
}

picker_capture() {
  command -v script >/dev/null 2>&1 || {
    RUN_RC=125
    WHY='script command unavailable'
    return 0
  }
  bounded_capture "$FIXTURE_REPO" script -q /dev/null env \
    MISE_AUTO_INSTALL=false WORKTRUNK_BIN="$FIXTURE_BACKEND" WT_SCENARIO=success \
    FIXTURE_FTM_BIN="$FTM_BIN" FIXTURE_FTM_RECORD_ONLY=1 TMUX="$TMP/not-a-client,0,0" \
    "$WT_BIN" open
}

assert_rc() { [ "$RUN_RC" -eq "$1" ] || {
  WHY="expected exit $1, got $RUN_RC"
  return 1
}; }
assert_event() { rg -q -- "$1" "$LOG" || {
  WHY="missing event: $1"
  return 1
}; }
assert_no_event() { ! rg -q -- "$1" "$LOG" || {
  WHY="unexpected event: $1"
  return 1
}; }
assert_json() { jq -e "$@" "$OUT" >/dev/null 2>&1 || {
  WHY="JSON assertion failed: $*"
  return 1
}; }
assert_one_json() { jq -s -e 'length == 1' "$OUT" >/dev/null 2>&1 || {
  WHY='stdout is not exactly one JSON document'
  return 1
}; }
assert_error() {
  expected_rc="$1"
  code="$2"
  assert_rc "$expected_rc" && assert_one_json || return 1
  # shellcheck disable=SC2016 # $code is a jq variable supplied by --arg.
  assert_json --arg code "$code" '.schema_version == 1 and (.status == "error" or .status == "refused" or .status == "partial") and .error.code == $code and .attached == false'
}
assert_success() {
  assert_rc 0 && assert_one_json &&
    assert_json '.schema_version == 1 and .status == "ok" and .attached == false'
}
event_line() { rg -n -- "$1" "$LOG" | awk -F: 'NR==1 {print $1}'; }
assert_order() {
  previous=0
  for pattern in "$@"; do
    line="$(event_line "$pattern")"
    [ -n "$line" ] || {
      WHY="ordering event missing: $pattern"
      return 1
    }
    [ "$line" -gt "$previous" ] || {
      WHY="ordering violation at: $pattern"
      return 1
    }
    previous="$line"
  done
}

assert_source_unchanged() {
  current_status="$(git -C "$ROOT" status --porcelain=v1 -z | shasum -a 256 | awk '{print $1}')"
  current_readme="$(shasum -a 256 "$ROOT/README.md" | awk '{print $1}')"
  [ "$current_status" = "$SOURCE_STATUS_BEFORE" ] || fail 'source checkout status changed during fixture run'
  [ "$current_readme" = "$SOURCE_README_BEFORE" ] || fail 'README.md changed during fixture run'
}

validate_manifest() {
  implemented='target-local target-remote target-missing target-direct target-picker schema-normalize schema-reject precedence duplicate-remote resolver create-base copy-order setup-gate lock-same lock-new lock-legacy lock-cross-worktree lock-repair lock-prune lock-stale lock-lease identity json-exits windows repair pi-cwd prune-refusals prune-partial prune-race prune-remote integration generic-ftm pi-uuid'
  while IFS=$'\t' read -r requirement test_id; do
    [ "$requirement" = requirement ] && continue
    [ -n "$requirement" ] && [ -n "$test_id" ] || fail 'invalid cases.tsv row'
    case " $implemented " in *" $test_id "*) : ;; *) fail "manifest points to missing test: $test_id" ;; esac
  done <"$HERE/cases.tsv"
  for test_id in $implemented; do
    rg -q $'\t'"$test_id"'$' "$HERE/cases.tsv" || fail "test missing from manifest: $test_id"
  done
}

fixture_self_test() {
  validate_manifest
  setup_git || fail 'temporary Git fixture setup failed'
  : >"$LOG"
  FIXTURE_KIND=mise MISE_AUTO_INSTALL=false mise which --tool worktrunk@0.76.0 wt </dev/null >"$OUT"
  [ "$(cat "$OUT")" = "$FIXTURE_BACKEND" ] || fail 'mise resolver output'
  rg -q $'mise\tsuccess\t.*which --tool worktrunk@0.76.0 wt\tstdin=eof\tauto_install=false' "$LOG" || fail 'mise resolver args/env/stdin'
  FIXTURE_KIND=backend WT_SCENARIO=success wt-backend --version </dev/null >"$OUT"
  [ "$(cat "$OUT")" = 'wt 0.76.0' ] || fail 'backend version fixture'
  FIXTURE_KIND=backend WT_SCENARIO=success wt-backend list --yes --branches --remotes --format=json </dev/null >"$OUT"
  jq -e '
    .schema == 2 and .repo.default_branch == "main" and
    .collected == {ci:false,summary:false} and (.items|length) == 2 and
    .items[0].branch == "feature/login" and .items[0].worktree.path == $path and
    (.items[0].worktree | has("main") and has("current") and has("previous") and has("detached") and has("branch_mismatch") and has("duplicate_branch") and has("changes")) and
    (.items[0].head | has("sha") and has("short_sha") and has("subject") and has("committed_at")) and
    (.items[0].display|type) == "object" and
    .items[1].remote == "origin" and .items[1].branch == "remote-only" and .items[1].head == null and (.items[1] | has("worktree") | not)
  ' --arg path "$FIXTURE_WORKTREE" "$OUT" >/dev/null || fail 'valid schema 2 fixture'
  FIXTURE_KIND=backend WT_SCENARIO=integration-patch wt-backend list </dev/null >"$OUT"
  jq -e '.items[0].default_branch.integration.reason == "patch_id_match" and .items[0].display.state == "integrated"' "$OUT" >/dev/null || fail 'patch integration fixture'
  FIXTURE_KIND=backend WT_SCENARIO=schema1 wt-backend list </dev/null >"$OUT"
  jq -e '.schema == 1' "$OUT" >/dev/null || fail 'schema 1 fixture'
  FIXTURE_KIND=backend WT_SCENARIO=schema-unknown wt-backend list </dev/null >"$OUT"
  jq -e '.schema == 99' "$OUT" >/dev/null || fail 'unknown schema fixture'
  FIXTURE_KIND=backend WT_SCENARIO=schema-malformed wt-backend list </dev/null >"$OUT"
  ! jq -e . "$OUT" >/dev/null 2>&1 || fail 'malformed fixture'
  git -C "$FIXTURE_WORKTREE" rev-parse --git-dir | rg -q 'worktrees' || fail 'linked worktree fixture'
  [ "$(git -C "$FIXTURE_WORKTREE" rev-parse --git-common-dir)" != "$(git -C "$FIXTURE_WORKTREE" rev-parse --git-dir)" ] || fail 'private/common Git dirs not distinct'
  : >"$LOG"
  tmux new-session -d -s isolation -c "$FIXTURE_REPO"
  "$REAL_TMUX" -L "$TMUX_SOCKET" -f /dev/null has-session -t isolation || fail 'isolated tmux session missing'
  tmux kill-server
  assert_source_unchanged
  printf 'fixture self-test: PASS\n'
}

case_target_local() {
  wt_capture success "$FIXTURE_REPO" ensure feature/login --json
  assert_success && assert_event $'backend\tsuccess\t.*\t.*list .*--branches.*--remotes' && assert_event $'backend\tsuccess\t.*\t.*switch '
}
case_target_remote() {
  wt_capture remote-only "$FIXTURE_REPO" ensure remote-only --json
  assert_success && assert_event $'backend\tremote-only\t.*\t.*list ' && assert_event $'backend\tremote-only\t.*\t.*switch '
}
case_target_missing() {
  wt_capture missing "$FIXTURE_REPO" ensure brand-new --json
  assert_success && assert_event $'backend\tmissing\t.*\t.*switch .*--create'
}
case_target_direct() {
  for target in "$FIXTURE_WORKTREE" @ mr:42 https://github.com/example/project/pull/42; do
    wt_capture success "$FIXTURE_REPO" ensure "$target" --json
    assert_success || return 1
    assert_event $'backend\tsuccess\t.*\t.*switch ' || return 1
  done
  wt_capture fork-pr "$FIXTURE_REPO" ensure pr:42 --json
  assert_success && assert_event $'backend\tfork-pr\t.*\t.*switch .*pr:42'
}
case_target_picker() {
  picker_capture
  [ "$RUN_RC" -eq 0 ] || {
    WHY="picker exited $RUN_RC"
    return 1
  }
  assert_event $'backend\tsuccess\t.*\t.*switch ' && assert_event $'backend\tsuccess\t.*\t.*stdin=tty' && assert_event $'ftm\tsuccess'
}
case_schema_normalize() {
  wt_capture success "$FIXTURE_REPO" list --json
  assert_success && assert_json '(.items|type) == "array" and (has("schema")|not)'
}
case_schema_reject() {
  for scenario in schema1 schema-unknown schema-malformed; do
    wt_capture "$scenario" "$FIXTURE_REPO" list --json
    assert_error 7 backend_parse_failed || return 1
  done
  wt_capture version-mismatch "$FIXTURE_REPO" list --json
  assert_error 7 backend_version_mismatch
}
case_precedence() {
  wt_capture local-over-remote "$FIXTURE_REPO" ensure feature/login --json
  assert_success && assert_json '.target.source != "remote"'
}
case_duplicate_remote() {
  wt_capture duplicate-remote "$FIXTURE_REPO" ensure feature/login --json
  assert_error 3 ambiguous_remote && assert_no_event $'backend\tduplicate-remote\t.*\t.*switch '
}
case_resolver() {
  wt_capture success "$FIXTURE_REPO" ensure feature/login --json
  assert_success && assert_event $'mise\tsuccess\t.*\twhich --tool worktrunk@0.76.0 wt\tstdin=eof\tauto_install=false' && assert_event $'backend\tsuccess\t.*\t--version\tstdin=eof'
}
case_create_base() {
  wt_capture missing "$FIXTURE_REPO" new feature/new --base main --json
  assert_success && assert_event $'backend\tmissing\t.*\t.*switch .*--create.*--base main'
}
case_copy_order() {
  wt_capture success "$FIXTURE_REPO" ensure feature/login --json
  assert_success && assert_event "step copy-ignored --yes --from main --require-include --format=json" && assert_event "-C $FIXTURE_WORKTREE" &&
    assert_order $'backend\tsuccess\t.*\t.*switch ' $'backend\tsuccess\t.*\t.*step copy-ignored' $'ftm\tsuccess' $'mise\tsuccess\t.*\trun dev:setup' $'tmux\tsuccess\t.*\tnew-session'
}
case_setup_gate() {
  FIXTURE_SETUP_RC=9
  export FIXTURE_SETUP_RC
  wt_capture success "$FIXTURE_REPO" ensure feature/login --json
  # Read-only tmux identity validation is allowed before setup; setup failure
  # must prevent every tmux MUTATION (design §5 "Safe existing-session repair").
  assert_error 4 setup_failed && assert_no_event $'tmux\t.*\t(new-session|new-window|respawn-pane|set-option|setenv|rename-window|kill-)' || return 1
  unset FIXTURE_SETUP_RC
  FIXTURE_TASKS=missing
  export FIXTURE_TASKS
  wt_capture success "$FIXTURE_REPO" ensure feature/login --json
  assert_success && assert_json '.setup.state == "missing"'
}

start_blocked_wt() {
  first_scenario="$1"
  first_cwd="$2"
  shift 2
  FIXTURE_BLOCK_READY="$TMP/block-ready"
  FIXTURE_BLOCK_RELEASE="$TMP/block-release"
  export FIXTURE_BLOCK_READY FIXTURE_BLOCK_RELEASE
  perl -MPOSIX -e 'POSIX::setpgid(0, 0); chdir shift @ARGV or exit 125; exec @ARGV' \
    "$first_cwd" env MISE_AUTO_INSTALL=false WORKTRUNK_BIN="$FIXTURE_BACKEND" \
    WT_SCENARIO="$first_scenario" FIXTURE_FTM_BIN="$FTM_BIN" FTM_NO_ATTACH=1 \
    "$WT_BIN" "$@" </dev/null >"$TMP/first-out" 2>"$TMP/first-err" &
  FIRST_PID=$!
  ticks=0
  while [ ! -e "$FIXTURE_BLOCK_READY" ] && kill -0 "$FIRST_PID" 2>/dev/null; do
    ticks=$((ticks + 1))
    [ "$ticks" -lt 30 ] || break
    sleep 0.1
  done
  [ -e "$FIXTURE_BLOCK_READY" ] || {
    WHY='first mutation never reached blocking copy fixture'
    return 1
  }
}
assert_busy_second() {
  second_scenario="$1"
  second_cwd="$2"
  shift 2
  wt_capture "$second_scenario" "$second_cwd" "$@"
  second_rc="$RUN_RC"
  cp "$OUT" "$TMP/second-out"
  : >"$FIXTURE_BLOCK_RELEASE"
  wait "$FIRST_PID" >/dev/null 2>&1 || true
  RUN_RC="$second_rc"
  cp "$TMP/second-out" "$OUT"
  assert_error 7 busy
}
case_lock_same() { start_blocked_wt success "$FIXTURE_REPO" ensure feature/login --json && assert_busy_second success "$FIXTURE_REPO" ensure feature/login --json; }
case_lock_new() { start_blocked_wt missing "$FIXTURE_REPO" new feature/new --base main --json && assert_busy_second missing "$FIXTURE_REPO" new feature/new --base main --json; }
case_lock_legacy() { start_blocked_wt success "$FIXTURE_REPO" feature/login -t session && assert_busy_second success "$FIXTURE_REPO" ensure feature/login --json; }
case_lock_cross_worktree() { start_blocked_wt success "$FIXTURE_REPO" ensure feature/login --json && assert_busy_second other-worktree "$FIXTURE_REPO" ensure feature/two --json; }
case_lock_repair() { start_blocked_wt success "$FIXTURE_REPO" repair feature/login --json && assert_busy_second success "$FIXTURE_REPO" repair feature/login --json; }
case_lock_prune() { start_blocked_wt success "$FIXTURE_REPO" ensure feature/login --json && assert_busy_second integration-patch "$FIXTURE_REPO" prune feature/login --json; }
case_lock_stale() {
  start_blocked_wt success "$FIXTURE_REPO" ensure feature/login --json || return 1
  kill -KILL -- "-$FIRST_PID" >/dev/null 2>&1 || kill -KILL "$FIRST_PID" >/dev/null 2>&1 || true
  wait "$FIRST_PID" >/dev/null 2>&1 || true
  : >"$FIXTURE_BLOCK_RELEASE"
  wt_capture success "$FIXTURE_REPO" ensure feature/login --json
  assert_success
}
case_lock_lease() {
  ftm_capture success ensure --kind worktree --cwd "$FIXTURE_WORKTREE" --session fixture --worktree-id fixture --lease invalid --attach never --format json
  assert_error 7 invalid_lease || return 1
  ftm_capture success ensure --kind worktree --cwd "$FIXTURE_WORKTREE" --session fixture --worktree-id fixture --attach never --format json
  assert_success
}
case_identity() {
  for scenario in path-escape identity-mismatch outside-root private-git-mismatch branch-mismatch head-mismatch; do
    wt_capture "$scenario" "$FIXTURE_REPO" ensure feature/login --json
    assert_error 7 identity_mismatch || return 1
    assert_no_event $'mise\t.*\trun dev:setup' || return 1
  done
  wt_capture copy-path-mismatch "$FIXTURE_REPO" ensure feature/login --json
  assert_error 4 copy_destination_mismatch && assert_no_event $'mise\t.*\trun dev:setup'
}
case_json_exits() {
  wt_capture success "$FIXTURE_REPO" ensure feature/login --json
  assert_rc 0 || return 1
  wt_capture success "$FIXTURE_REPO" ensure --json
  assert_error 2 usage || return 1
  wt_capture duplicate-remote "$FIXTURE_REPO" ensure feature/login --json
  assert_rc 3 || return 1
  FIXTURE_SETUP_RC=9
  export FIXTURE_SETUP_RC
  wt_capture success "$FIXTURE_REPO" ensure feature/login --json
  assert_rc 4 || return 1
  unset FIXTURE_SETUP_RC
  wt_capture backend-error "$FIXTURE_REPO" ensure feature/login --json
  assert_rc 7 || return 1
  tmux new-session -d -s conflict -c "$FIXTURE_OTHER_REPO"
  ftm_capture success repair --kind worktree --cwd "$FIXTURE_WORKTREE" --session conflict --worktree-id fixture-id --attach never --format json
  assert_rc 5 || return 1
  wt_capture dirty "$FIXTURE_REPO" prune feature/login --json
  assert_rc 6 || return 1
  assert_one_json
}

case_windows() {
  ftm_capture success ensure --kind worktree --cwd "$FIXTURE_WORKTREE" --session fixture --worktree-id fixture-id --attach never --format json
  assert_success || return 1
  names="$(tmux list-windows -t fixture -F '#{window_name}' 2>/dev/null || true)"
  [ "$names" = $'code\nagent\nservices' ] || {
    WHY="unexpected windows: $names"
    return 1
  }
  [ "$(tmux show-options -t fixture -v @ftm_kind 2>/dev/null)" = worktree ] || {
    WHY='missing worktree tag'
    return 1
  }
  [ "$(tmux show-options -t fixture -v @ftm_worktree 2>/dev/null)" = "$FIXTURE_WORKTREE" ] || {
    WHY='missing worktree path tag'
    return 1
  }
  ftm_capture success ensure --kind worktree --cwd "$FIXTURE_WORKTREE" --session fixture --worktree-id fixture-id --attach never --format json
  assert_success || return 1
  [ "$(tmux list-windows -t fixture -F '#{window_name}' | wc -l | tr -d ' ')" -eq 3 ] || {
    WHY='repeated ensure duplicated windows'
    return 1
  }
}
case_repair() {
  tmux new-session -d -s fixture -n code -c "$FIXTURE_WORKTREE"
  tmux new-window -d -t fixture -n notes -c "$FIXTURE_WORKTREE"
  tmux set-option -t fixture @ftm_kind worktree
  tmux set-option -t fixture @ftm_worktree "$FIXTURE_WORKTREE"
  tmux set-option -t fixture @ftm_worktree_id fixture-id
  ftm_capture success repair --kind worktree --cwd "$FIXTURE_WORKTREE" --session fixture --worktree-id fixture-id --attach never --format json
  assert_success && tmux list-windows -t fixture -F '#{window_name}' | rg -qx notes && tmux list-windows -t fixture -F '#{window_name}' | rg -qx agent && tmux list-windows -t fixture -F '#{window_name}' | rg -qx services || return 1
  tmux new-session -d -s duplicate -n code -c "$FIXTURE_WORKTREE"
  tmux set-option -t duplicate @ftm_kind worktree
  tmux set-option -t duplicate @ftm_worktree "$FIXTURE_WORKTREE"
  tmux set-option -t duplicate @ftm_worktree_id fixture-id
  ftm_capture success repair --kind worktree --cwd "$FIXTURE_WORKTREE" --session fixture --worktree-id fixture-id --attach never --format json
  assert_error 5 ambiguous_session
}
case_pi_cwd() {
  ftm_capture success ensure --kind worktree --cwd "$FIXTURE_WORKTREE" --session fixture --worktree-id fixture-id --attach never --format json
  assert_success || return 1
  sleep 0.2
  assert_event $'pi\tsuccess\t' || return 1
  assert_event "$FIXTURE_WORKTREE.*-c" || return 1
  [ "$(tmux display-message -p -t fixture:agent.0 '#{pane_current_path}' 2>/dev/null)" = "$FIXTURE_WORKTREE" ] || {
    WHY='agent pane cwd mismatch'
    return 1
  }
}

case_prune_refusals() {
  wt_capture dirty "$FIXTURE_REPO" prune feature/login --json
  assert_error 6 dirty_worktree && assert_no_event $'backend\t.*\t.*remove ' || return 1
  wt_capture unintegrated "$FIXTURE_REPO" prune feature/login --json
  assert_error 6 not_integrated && assert_no_event $'backend\t.*\t.*remove ' || return 1
  wt_capture main "$FIXTURE_REPO" prune main --json
  assert_error 6 main_worktree && assert_no_event $'backend\t.*\t.*remove ' || return 1
  tmux new-session -d -s duplicate-a -c "$FIXTURE_WORKTREE"
  tmux new-session -d -s duplicate-b -c "$FIXTURE_WORKTREE"
  for session in duplicate-a duplicate-b; do
    tmux set-option -t "$session" @ftm_kind worktree
    tmux set-option -t "$session" @ftm_worktree "$FIXTURE_WORKTREE"
    tmux set-option -t "$session" @ftm_worktree_id repo-feature-login
  done
  wt_capture integration-patch "$FIXTURE_REPO" prune feature/login --json
  assert_error 6 ambiguous_session || return 1
  tmux kill-server
  wt_capture integration-patch "$FIXTURE_WORKTREE" prune feature/login --json
  assert_error 6 current_worktree
}
setup_prune_session() {
  tmux new-session -d -s repo-feature-login -c "$FIXTURE_WORKTREE"
  tmux set-option -t repo-feature-login @ftm_kind worktree
  tmux set-option -t repo-feature-login @ftm_worktree "$FIXTURE_WORKTREE"
  tmux set-option -t repo-feature-login @ftm_worktree_id repo-feature-login
}
case_prune_partial() {
  setup_prune_session
  wt_capture prune-partial "$FIXTURE_REPO" prune feature/login --json
  assert_error 7 prune_backend_failed && assert_json '.status == "partial"'
}
case_prune_race() {
  setup_prune_session
  wt_capture branch-race "$FIXTURE_REPO" prune feature/login --json
  assert_error 7 branch_moved
}
case_prune_remote() {
  before="$(git -C "$FIXTURE_REPO" for-each-ref --format='%(refname) %(objectname)' refs/remotes | sort)"
  wt_capture dirty "$FIXTURE_REPO" prune feature/login --json
  after="$(git -C "$FIXTURE_REPO" for-each-ref --format='%(refname) %(objectname)' refs/remotes | sort)"
  [ "$before" = "$after" ] || {
    WHY='remote refs changed'
    return 1
  }
  assert_rc 6
}
case_integration() {
  wt_capture integration-patch "$FIXTURE_REPO" prune feature/login --json
  assert_event $'backend\tintegration-patch\t.*\t.*remove ' && assert_no_event 'not_integrated'
}
case_generic_ftm() {
  ftm_capture success ensure --kind generic --cwd "$FIXTURE_REPO" --session generic --attach never --format json
  assert_success && [ "$(tmux show-options -t generic -v @ftm_kind 2>/dev/null)" = generic ]
}
case_pi_uuid() {
  uuid=01a069c5-9dbc-76ed-a951-1b70905357d5
  ftm_capture success ensure --kind generic --cwd "$FIXTURE_REPO" --session generic --pi-session "$uuid" --attach never --format json
  assert_success || return 1
  sleep 0.2
  assert_event "pi --session $uuid"
}

run_test() {
  id="$1"
  function_name="$2"
  reset_case
  if "$function_name"; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf 'PASS %s\n' "$id"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    [ -n "$WHY" ] || WHY='assertion returned nonzero'
    printf 'FAIL %s: %s\n' "$id" "$WHY"
  fi
}

contract() {
  validate_manifest
  setup_git || fail 'temporary Git fixture setup failed'
  WT_BIN="${WT_BIN:-$ROOT/bin/wt}"
  FTM_BIN="${FTM_BIN:-$ROOT/bin/ftm}"
  [ -x "$WT_BIN" ] || fail "WT_BIN is not executable: $WT_BIN"
  [ -x "$FTM_BIN" ] || fail "FTM_BIN is not executable: $FTM_BIN"
  export WT_BIN FTM_BIN FIXTURE_FTM_BIN="$FTM_BIN"
  tests='target-local:case_target_local target-remote:case_target_remote target-missing:case_target_missing target-direct:case_target_direct target-picker:case_target_picker schema-normalize:case_schema_normalize schema-reject:case_schema_reject precedence:case_precedence duplicate-remote:case_duplicate_remote resolver:case_resolver create-base:case_create_base copy-order:case_copy_order setup-gate:case_setup_gate lock-same:case_lock_same lock-new:case_lock_new lock-legacy:case_lock_legacy lock-cross-worktree:case_lock_cross_worktree lock-repair:case_lock_repair lock-prune:case_lock_prune lock-stale:case_lock_stale lock-lease:case_lock_lease identity:case_identity json-exits:case_json_exits windows:case_windows repair:case_repair pi-cwd:case_pi_cwd prune-refusals:case_prune_refusals prune-partial:case_prune_partial prune-race:case_prune_race prune-remote:case_prune_remote integration:case_integration generic-ftm:case_generic_ftm pi-uuid:case_pi_uuid'
  for entry in $tests; do run_test "${entry%%:*}" "${entry#*:}"; done
  assert_source_unchanged
  printf 'contract summary: pass=%s fail=%s\n' "$PASS_COUNT" "$FAIL_COUNT"
  [ "$FAIL_COUNT" -eq 0 ]
}

case "$MODE" in
self-test) fixture_self_test ;;
contract) contract ;;
*)
  printf 'usage: %s [self-test|contract]\n' "$0" >&2
  exit 2
  ;;
esac
