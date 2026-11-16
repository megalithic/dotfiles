#!/usr/bin/env bash
# Refuse to init or start the shared cluster while an orphaned server still
# claims $PGDATA. An orphan is a postgres started with `-D $PGDATA` that is
# not the pid in $PGDATA/postmaster.pid: its data dir was moved or deleted
# (rx's tmp/ went to the Trash while its server ran) or its lock file is gone.
# Starting anyway would run a second server for one repo, or two servers on
# one data dir. Run by setup-db.sh and start-db.sh; exit 1 lists the orphans.
set -euo pipefail

orphans() {
  local owner="" pid args
  [ -f "$PGDATA/postmaster.pid" ] && owner="$(head -n 1 "$PGDATA/postmaster.pid")"
  while read -r pid args; do
    [ "$pid" = "$owner" ] && continue
    case "$args" in
      *postgres" -D $PGDATA" | *postgres" -D $PGDATA "*) echo "$pid" ;;
    esac
  done < <(ps -axo pid=,args=)
}

found="$(orphans)"
# A server another checkout is starting right now may not have written
# postmaster.pid yet; give it a moment before calling it an orphan.
[ -z "$found" ] || {
  sleep 1
  found="$(orphans)"
}
[ -z "$found" ] && exit 0

{
  echo "error: a postgres server still runs for $PGDATA but does not own it:"
  for pid in $found; do
    echo "  pid $pid ($(lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p'))"
  done
  echo "Refusing to start a second server. Check it holds nothing you need, then"
  echo "stop it (kill -INT <pid>, a fast clean shutdown) and rerun."
} >&2
exit 1
