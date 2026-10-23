#!/usr/bin/env bash
set -euo pipefail

lock="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../agent/skills/jam-demo/scripts/recording-lock.mjs"
JAM_DEMO_STATE_DIR=$(mktemp -d)
export JAM_DEMO_STATE_DIR JAM_DEMO_RECORDERS='[]'
trap 'trash "$JAM_DEMO_STATE_DIR"' EXIT

exit_code() {
  set +e
  "$@" >/dev/null 2>&1
  local code=$?
  set -e
  echo "$code"
}

[ "$(exit_code "$lock" acquire pi:a http://localhost:4000/invitations "A demo" pi:requester)" = 0 ]
"$lock" acquire pi:a http://localhost:4000/invitations "A demo" | jq -e '.reentered == true' >/dev/null

[ "$(exit_code "$lock" acquire pi:b http://localhost:4372/register "B demo")" = 3 ]
busy=$("$lock" acquire pi:b http://localhost:4372/register "B demo" || true)
echo "$busy" | jq -e '.busy and .holder.owner == "pi:a" and .holder.requestedBy == "pi:requester"' >/dev/null

"$lock" wait pi:b | jq -e '.waiting and .waiters == ["pi:b"]' >/dev/null
"$lock" wait pi:b | jq -e '.waiters == ["pi:b"]' >/dev/null
[ "$(exit_code "$lock" release pi:b)" = 4 ]
"$lock" release pi:a | jq -e '.released and .notify == ["pi:b"]' >/dev/null
[ "$(exit_code "$lock" wait pi:b)" = 5 ]

[ "$(exit_code "$lock" acquire pi:b http://localhost:4372/register "B demo")" = 0 ]
"$lock" release pi:b | jq -e '.released and .notify == []' >/dev/null

mkdir "$JAM_DEMO_STATE_DIR/recording.lock"
echo '{"owner":"pi:gone","url":"http://localhost:4000/","title":"old","startedAt":"2020-01-01T00:00:00Z"}' >"$JAM_DEMO_STATE_DIR/recording.lock/owner.json"
"$lock" acquire pi:c http://localhost:4000/ "C demo" | jq -e '.acquired and .tookOverStale.owner == "pi:gone"' >/dev/null
"$lock" release pi:c >/dev/null

export JAM_DEMO_RECORDERS='[{"target":"T1","origin":"http://localhost:4000","url":"http://localhost:4000/invitations","active":true}]'
busy=$("$lock" acquire pi:d http://localhost:4000/ "D demo" || true)
echo "$busy" | jq -e '.busy and .holder == null and .recording[0].url == "http://localhost:4000/invitations"' >/dev/null
[ ! -e "$JAM_DEMO_STATE_DIR/recording.lock" ]

# A holder between takes leaves vision mode on: its stale lock must stay busy, not be taken over.
mkdir "$JAM_DEMO_STATE_DIR/recording.lock"
echo '{"owner":"pi:slow","url":"http://localhost:4000/","title":"slow","startedAt":"2020-01-01T00:00:00Z"}' >"$JAM_DEMO_STATE_DIR/recording.lock/owner.json"
export JAM_DEMO_RECORDERS='[{"target":"T1","origin":"http://localhost:4000","url":"http://localhost:4000/","vision":true,"active":true}]'
busy=$("$lock" acquire pi:e http://localhost:4000/ "E demo" || true)
echo "$busy" | jq -e '.busy and .holder.owner == "pi:slow" and .recording[0].vision' >/dev/null
"$lock" acquire pi:slow http://localhost:4000/ "slow" | jq -e '.reentered == true' >/dev/null

echo "recording-lock: all checks passed"
