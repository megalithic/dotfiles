#!/usr/bin/env bash
# Start the shared postgres in the background (log: ./tmp/pg/postgres.log).
# Run by `mise run start:db` (after the `setup:db` dependency).
# Reads PGDATA/PG_LOG/PGHOST/PGPORT from the mise env.
set -euo pipefail
if pg_ctl -D "$PGDATA" status >/dev/null 2>&1; then
  # running, but maybe on a stale port (setup-db syncs postgresql.conf to the
  # resolved PGPORT; a cluster started before that sync listens on the old
  # one — the socket file is .s.PGSQL.<port>, so pg_isready detects it)
  if pg_isready -q -h "$PGHOST" -p "$PGPORT" 2>/dev/null; then
    echo "postgres already running"
  else
    echo "postgres running on stale port - restarting on $PGPORT"
    pg_ctl -D "$PGDATA" -l "$PG_LOG" restart
  fi
else
  # pg_ctl start daemonizes; -l appends server log; waits (-w) by default
  # until the server accepts connections.
  pg_ctl -D "$PGDATA" -l "$PG_LOG" start
fi
pg_isready -h "$PGHOST" -p "$PGPORT"
