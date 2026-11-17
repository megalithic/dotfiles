#!/bin/sh
set -e
src="$ULTIMATE_SOURCE"

[ -f .env ] || cp "$src/.env" .env
mise trust --quiet .

for dir in deps _build assets/node_modules; do
  [ -e "$dir" ] || [ ! -d "$src/$dir" ] || /bin/cp -Rc "$src/$dir" "$dir"
done

case "$PWD" in
  */lander/* | */ult-lander-*)
    name=ult_lander
    ;;
  *)
    id=$(basename "$PWD")
    id=${id##*-}
    name=ult_$id
    port=$((20000 + id % 1000 * 10))
    ;;
esac

status=0
grep -v -e '^GIT_WORKTREE=' -e '^PORT=' -e '^LIVE_DEBUGGER_PORT=' -e '^RX_METRICS_PORT=' .env >.env.tmp || status=$?
[ "$status" -le 1 ]
echo "GIT_WORKTREE=$name" >>.env.tmp
[ -z "$port" ] || printf 'PORT=%s\nLIVE_DEBUGGER_PORT=%s\nRX_METRICS_PORT=%s\n' "$port" $((port + 1)) $((port + 2)) >>.env.tmp
mv .env.tmp .env

mise exec -- mix deps.get
mise exec -- mix compile
MIX_ENV=test mise exec -- mix compile
