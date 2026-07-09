#!/usr/bin/env bash
# Start the shared postgres in the background (log: ./tmp/pg/postgres.log).
# Run by `mise run start:db` (after the `setup:db` dependency).
# Reads PGDATA/PG_LOG/PGHOST/PGPORT from the mise env.
set -euo pipefail
if pg_ctl -D "$PGDATA" status >/dev/null 2>&1; then
  echo "postgres already running"
else
  # pg_ctl start daemonizes; -l appends server log; waits (-w) by default
  # until the server accepts connections.
  pg_ctl -D "$PGDATA" -l "$PG_LOG" start
fi
pg_isready -h "$PGHOST" -p "$PGPORT"
