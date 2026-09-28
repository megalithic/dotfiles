#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
test_home=$(mktemp -d)
out=$(mktemp)
err=$(mktemp)
trap '/usr/bin/trash "$test_home" "$out" "$err"' EXIT

ln -s "$repo_root" "$test_home/.dotfiles"
mkdir -p \
	"$test_home/.local/share/mise/shims" \
	"$test_home/.local/share/fnox/generated"
: >"$test_home/.local/share/mise/shims/lat"
: >"$test_home/.local/share/fnox/generated/s3cfg"

HOME="$test_home" \
	XDG_CONFIG_HOME="$test_home/.config" \
	XDG_DATA_HOME="$test_home/.local/share" \
	XDG_STATE_HOME="$test_home/.local/state" \
	MISE_ENV=megabookpro \
	MISE_CONFIG_FILE="$repo_root/config/mise/config.toml" \
	mise bootstrap dotfiles apply --yes >/dev/null 2>&1

while read -r target source; do
	[ -L "$test_home/$target" ]
	[ "$(realpath "$test_home/$target")" = "$repo_root/$source" ]
done <<'EOF'
.pi/agent/settings.json home/.pi/agent/settings.json
.pi/agent/APPEND_SYSTEM.md home/.pi/agent/APPEND_SYSTEM.md
.pi/agent/extensions/answer.ts home/.pi/agent/extensions/answer.ts
.pi/agent/skills/bro/SKILL.md home/.pi/agent/skills/bro/SKILL.md
.pi/agent/prompts/plan.md home/.pi/agent/prompts/plan.md
.pi/agent/agents/scout.md home/.pi/agent/agents/scout.md
.local/bin/pi home/.pi/bin/pi
EOF

[ ! -e "$test_home/.pi/agent/extensions/_sentinel.ts" ]
[ ! -L "$test_home/.pi/agent/extensions/_sentinel.ts" ]
[ ! -e "$test_home/.pi/agent/SYSTEM.md" ]
[ ! -L "$test_home/.pi/agent/SYSTEM.md" ]
[ ! -e "$test_home/.local/bin/pi-acp" ]
[ ! -L "$test_home/.local/bin/pi-acp" ]

extension_args=()
while IFS= read -r extension; do
	extension_args+=(--extension "$extension")
done < <(
	fd -H -L -t f '\.(ts|js|mjs)$' "$test_home/.pi/agent/extensions" --max-depth 1
	fd -H -L -t f '^index\.(ts|js|mjs)$' "$test_home/.pi/agent/extensions" --min-depth 2 --max-depth 2
)
[ "${#extension_args[@]}" -gt 0 ]

pi_bin=$(realpath "$(mise which pi)")
printf '%s\n' '{"id":"commands","type":"get_commands"}' |
	HOME="$test_home" \
		XDG_CONFIG_HOME="$test_home/.config" \
		XDG_DATA_HOME="$test_home/.local/share" \
		XDG_STATE_HOME="$test_home/.local/state" \
		PI_CODING_AGENT_DIR="$test_home/.pi/agent" \
		"$pi_bin" \
		--mode rpc \
		--no-session \
		--offline \
		--models '*' \
		--no-extensions \
		"${extension_args[@]}" >"$out" 2>"$err" &
pid=$!

for _ in $(seq 1 300); do
	if rg -q '"id":"commands"' "$out"; then
		break
	fi
	if ! kill -0 "$pid" 2>/dev/null; then
		break
	fi
	sleep 0.1
done
kill "$pid" 2>/dev/null || true
wait "$pid" 2>/dev/null || true

jq -e --arg prefix "$test_home/.pi/agent/extensions/" '
  select(.id == "commands" and .success == true)
  | [.data.commands[] | select(.name == "answer" or .name == "goal" or .name == "tell")]
  | length == 3 and all(.sourceInfo.path | startswith($prefix))
' "$out" >/dev/null

diff -u \
	<(fd -H -L -t f '^SKILL\.md$' "$test_home/.pi/agent/skills" --max-depth 2 | sort) \
	<(jq -r --arg prefix "$test_home/.pi/agent/skills/" '
    select(.id == "commands")
    | .data.commands[]
    | select(.source == "skill" and (.sourceInfo.path | startswith($prefix)))
    | .sourceInfo.path
  ' "$out" | sort)
diff -u \
	<(fd -H -L -t f '\.md$' "$test_home/.pi/agent/prompts" --max-depth 1 | sort) \
	<(jq -r --arg prefix "$test_home/.pi/agent/prompts/" '
    select(.id == "commands")
    | .data.commands[]
    | select(.source == "prompt" and (.sourceInfo.path | startswith($prefix)))
    | .sourceInfo.path
  ' "$out" | sort)

if [ -s "$err" ]; then
	printf 'unexpected Pi stderr:\n' >&2
	cat "$err" >&2
	exit 1
fi

echo 'PASS: applied dotfiles load moved Pi resources'
