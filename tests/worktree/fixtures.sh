#!/usr/bin/env bash
set -eu

kind="${FIXTURE_KIND:-${0##*/}}"
[ "$kind" = wt-backend ] && kind=backend
scenario="${WT_SCENARIO:-success}"

log_event() {
  stdin_state=eof
  if [ -t 0 ]; then
    stdin_state="tty"
  elif IFS= read -r -n 1 _byte; then
    stdin_state=data
  fi
  printf '%s\t%s\t%s\t%s\tstdin=%s\tauto_install=%s\n' \
    "$kind" "$scenario" "$PWD" "$*" "$stdin_state" "${MISE_AUTO_INSTALL:-unset}" >>"${FIXTURE_LOG:?}"
}

emit_item() {
  path="$1"
  branch="$2"
  main="$3"
  modified="$4"
  state="$5"
  reason="$6"
  jq -nc \
    --arg path "$path" --arg branch "$branch" --arg sha "${FIXTURE_FEATURE_HEAD:?}" \
    --argjson main "$main" --argjson modified "$modified" --arg state "$state" --arg reason "$reason" '
      {
        branch: $branch,
        head: {sha: $sha, short_sha: $sha[0:7], subject: "fixture", committed_at: null},
        worktree: {
          path: $path, main: $main, current: false, previous: false,
          detached: false, branch_mismatch: false, duplicate_branch: false,
          changes: {
            staged: false, modified: $modified, untracked: false, renamed: false,
            deleted: false, conflicted: false, diff: {added: 0, deleted: 0}
          }
        },
        default_branch: ({ahead: 0, behind: 0, diff: {added: 0, deleted: 0}, orphan: false, merge_conflicts: false}
          + (if $reason == "" then {} else {integration: {reason: $reason}} end)),
        display: (if $state == "" then {} else {state: $state} end)
      }'
}

emit_remote_item() {
  remote="$1"
  branch="$2"
  jq -nc --arg remote "$remote" --arg branch "$branch" '
    {branch: $branch, head: null, remote: $remote, display: {}}'
}

emit_list() {
  items='[]'
  case "$scenario" in
  missing) ;;
  remote-only)
    items="[$(emit_remote_item origin remote-only)]"
    ;;
  duplicate-remote)
    items="[$(emit_remote_item origin feature/login),$(emit_remote_item upstream feature/login)]"
    ;;
  main)
    items="[$(emit_item "$FIXTURE_REPO" main true false is_main same_commit)]"
    ;;
  dirty)
    items="[$(emit_item "$FIXTURE_WORKTREE" feature/login false true ahead '')]"
    ;;
  unintegrated)
    items="[$(emit_item "$FIXTURE_WORKTREE" feature/login false false ahead '')]"
    ;;
  integration-patch)
    items="[$(emit_item "$FIXTURE_WORKTREE" feature/login false false integrated patch_id_match)]"
    ;;
  path-escape)
    items="[$(emit_item "$FIXTURE_ESCAPE" feature/login false false integrated ancestor)]"
    ;;
  identity-mismatch)
    items="[$(emit_item "$FIXTURE_OTHER_REPO" feature/login false false integrated ancestor)]"
    ;;
  outside-root)
    items="[$(emit_item "$FIXTURE_OUTSIDE_WORKTREE" outside-linked false false integrated ancestor)]"
    ;;
  private-git-mismatch)
    items="[$(emit_item "$FIXTURE_BROKEN_WORKTREE" feature/login false false integrated ancestor)]"
    ;;
  branch-mismatch)
    items="[$(emit_item "$FIXTURE_WORKTREE" wrong/branch false false integrated ancestor)]"
    ;;
  head-mismatch)
    item="$(emit_item "$FIXTURE_WORKTREE" feature/login false false integrated ancestor)"
    items="[$(printf '%s' "$item" | jq -c --arg sha "$FIXTURE_MAIN_HEAD" '.head.sha = $sha')]"
    ;;
  other-worktree)
    items="[$(emit_item "$FIXTURE_SECOND_WORKTREE" feature/two false false integrated ancestor)]"
    ;;
  local-over-remote)
    items="[$(emit_item "$FIXTURE_WORKTREE" feature/login false false integrated ancestor),$(emit_remote_item origin feature/login)]"
    ;;
  *)
    items="[$(emit_item "$FIXTURE_WORKTREE" feature/login false false integrated ancestor),$(emit_remote_item origin remote-only)]"
    ;;
  esac
  jq -nc --argjson items "$items" '{schema: 2, repo: {default_branch: "main"}, collected: {ci: false, summary: false}, items: $items}'
}

find_command() {
  for arg in "$@"; do
    case "$arg" in list | switch | open | step | remove)
      printf '%s' "$arg"
      return 0
      ;;
    esac
  done
  return 1
}

case "$kind" in
mise)
  log_event "$@"
  if [ "${1:-}" = which ] && [ "${2:-}" = --tool ] &&
    [ "${3:-}" = "worktrunk@${WT_VERSION:-0.76.0}" ] && [ "${4:-}" = wt ] &&
    [ "${MISE_AUTO_INSTALL:-}" = false ]; then
    printf '%s\n' "${FIXTURE_BACKEND:?}"
    exit 0
  fi
  if [ "${1:-}" = tasks ] && [ "${2:-}" = info ] && [ "${3:-}" = --json ]; then
    task="${4:-}"
    [ "$task" = dev:setup ] || [ "$task" = dev:services ] || exit 1
    [ "${FIXTURE_TASKS:-present}" = present ] || exit 1
    printf '{"name":"%s","source":"fixture"}\n' "$task"
    exit 0
  fi
  if [ "${1:-}" = run ]; then
    task="${2:-}"
    [ "$task" = dev:setup ] || [ "$task" = dev:services ] || exit 1
    [ "${FIXTURE_TASKS:-present}" = present ] || exit 1
    [ "$task" != dev:setup ] || exit "${FIXTURE_SETUP_RC:-0}"
    exit 0
  fi
  exit 2
  ;;
backend)
  log_event "$@"
  if [ "${1:-}" = --version ]; then
    [ "$scenario" != version-mismatch ] || {
      printf 'wt 0.75.0\n'
      exit 0
    }
    printf 'wt %s\n' "${WT_VERSION:-0.76.0}"
    exit 0
  fi
  command="$(find_command "$@" || true)"
  case "$command" in
  list)
    case "$scenario" in
    schema1) printf '{"schema":1,"items":[]}\n' ;;
    schema-unknown) printf '{"schema":99,"items":[]}\n' ;;
    schema-malformed) printf '{bad\n' ;;
    backend-error)
      printf 'backend exploded\n' >&2
      exit 19
      ;;
    *) emit_list ;;
    esac
    ;;
  switch | open)
    [ "$scenario" != backend-error ] || {
      printf 'backend exploded\n' >&2
      exit 19
    }
    path="$FIXTURE_WORKTREE"
    [ "$scenario" != path-escape ] || path="$FIXTURE_ESCAPE"
    [ "$scenario" != identity-mismatch ] || path="$FIXTURE_OTHER_REPO"
    [ "$scenario" != outside-root ] || path="$FIXTURE_OUTSIDE_WORKTREE"
    [ "$scenario" != private-git-mismatch ] || path="$FIXTURE_BROKEN_WORKTREE"
    [ "$scenario" != other-worktree ] || path="$FIXTURE_SECOND_WORKTREE"
    branch="${FIXTURE_SWITCH_BRANCH:-feature/login}"
    [ "$scenario" != branch-mismatch ] || branch=wrong/branch
    jq -nc --arg branch "$branch" --arg path "$path" \
      '{branch: $branch, path: $path}'
    ;;
  step)
    if [ -n "${FIXTURE_BLOCK_READY:-}" ]; then
      : >"$FIXTURE_BLOCK_READY"
      ticks=0
      while [ ! -e "${FIXTURE_BLOCK_RELEASE:?}" ]; do
        ticks=$((ticks + 1))
        [ "$ticks" -lt 100 ] || exit 18
        sleep 0.1
      done
    fi
    path="$FIXTURE_WORKTREE"
    [ "$scenario" != copy-path-mismatch ] || path="$FIXTURE_OTHER_REPO"
    jq -nc --arg path "$path" '{step: "copy-ignored", path: $path, state: "completed"}'
    ;;
  remove)
    if [ "$scenario" = prune-partial ]; then
      printf 'remove refused\n' >&2
      exit 19
    fi
    if [ "$scenario" = branch-race ]; then
      git -C "$FIXTURE_REPO" update-ref refs/heads/feature/login "${FIXTURE_MAIN_HEAD:?}"
      printf 'branch moved\n' >&2
      exit 19
    fi
    jq -nc --arg path "$FIXTURE_WORKTREE" '{path: $path, branch_outcome: "deleted"}'
    ;;
  *) exit 2 ;;
  esac
  ;;
pi)
  log_event "$@"
  # Stay alive so window/pane assertions can inspect a live agent pane
  # (#{pane_current_path} needs a running process). The pane's process group
  # receives SIGHUP when the isolated tmux server is killed.
  sleep 600
  exit 0
  ;;
service)
  log_event "$@"
  exit 0
  ;;
*)
  printf 'unknown fixture: %s\n' "$kind" >&2
  exit 2
  ;;
esac
