#!/usr/bin/env bash
# Init the shared postgres cluster in ./tmp/pg (idempotent).
# Run by `mise run setup:db`. Reads PG_ROOT/PGDATA/HOST/PGPORT from the mise env.
set -euo pipefail
mkdir -p "$PG_ROOT"
if [ ! -s "$PGDATA/PG_VERSION" ]; then
  # -U postgres: superuser named "postgres", default local trust auth.
  # dev.exs sends password "postgres" but trust auth never checks it.
  initdb -D "$PGDATA" -U postgres --encoding=UTF8 --locale=C
fi
conf="$PGDATA/postgresql.conf"
if ! grep -q '^# rx local settings' "$conf"; then
  cat >>"$conf" <<EOF

# rx local settings (appended by setup:db)
listen_addresses = '$HOST'
port = $PGPORT
unix_socket_directories = '$PG_ROOT'
# One instance shared by main repo + all .worktrees checkouts:
# 3 repos x pool_size 10 per checkout, plus test runs. Stock 100 is too tight.
max_connections = 300
EOF
fi
echo "cluster ready: $PGDATA"
