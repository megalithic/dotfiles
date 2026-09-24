#!/usr/bin/env bash
set -euo pipefail

updater="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)/update-pi"
test_root="$(mktemp -d)"
cleanup() {
	if [ -x /usr/bin/trash ]; then
		/usr/bin/trash "$test_root"
	else
		trash "$test_root"
	fi
}
trap cleanup EXIT

run() {
	# Bash 3.2 inherits ERR into substitutions even for expected failures.
	output="$(
		trap - ERR
		"$@" 2>&1
	)" && status=0 || status=$?
}

setup() {
	export HOME="$test_dir/home"
	export XDG_DATA_HOME="$HOME/.local/share"
	export DOTFILES_DIR="$test_dir/dotfiles"
	export CALLS="$test_dir/calls"
	export AUX_CALLS="$test_dir/aux-calls"
	src="$DOTFILES_DIR/config/pi-coding-agent"
	runtime="$HOME/.pi/agent/settings.json"
	managed="$src/agent/settings.json"
	mkdir -p "$src/agent" "$src/scripts" "$src/bin" "$HOME/.pi/agent" "$XDG_DATA_HOME/mise/shims"
	printf '%s\n' '{"packages":["npm:current"],"retry":{"enabled":true}}' >"$managed"
	printf '%s\n' '{"theme":"system","extensions":["old.ts"],"skills":["old"],"packages":["npm:old"],"retry":{"enabled":false,"stale":true}}' >"$runtime"
	mkdir -p "$HOME/.pi/agent/sessions"
	printf '%s\n' '{"sentinel":true}' >"$HOME/.pi/agent/auth.json"
	printf '%s\n' 'session sentinel' >"$HOME/.pi/agent/sessions/keep.jsonl"
	printf '%s\n' '#!/usr/bin/env bash' 'echo helpers >>"$AUX_CALLS"' 'exit "${HELPER_STATUS:-0}"' >"$src/scripts/install-pi-tools"
	printf '%s\n' '#!/usr/bin/env bash' \
		'printf "pi %s\n" "$*" >>"$CALLS"' \
		'if [ "${EXPECT_TTY:-0}" = 1 ]; then [ -t 0 ] && [ -t 1 ] && [ -t 2 ] || exit 91; fi' \
		'printf "pi stdout: %s\n" "$*"; printf "pi stderr: %s\n" "$*" >&2' \
		'if [ "$*" = update ]; then exit "${PI_SELF_STATUS:-0}"; fi' \
		'exit "${PI_EXTENSIONS_STATUS:-0}"' >"$src/bin/pi"
	printf '%s\n' '#!/usr/bin/env bash' \
		'printf "mise %s\n" "$*" >>"$CALLS"' \
		'if [ "${EXPECT_TTY:-0}" = 1 ]; then [ -t 0 ] && [ -t 1 ] && [ -t 2 ] || exit 91; fi' \
		'if [[ " $* " != *" --raw "* ]]; then printf "\033[H\033[2J"; fi' \
		'if [ -t 1 ]; then printf "\033[32mmise color retained\033[0m\n"; fi' \
		'exit "${MISE_STATUS:-0}"' >"$XDG_DATA_HOME/mise/shims/mise"
	printf '%s\n' '#!/usr/bin/env bash' 'echo sessions >>"$AUX_CALLS"' \
		'[ -d "$SESSIONS_HOME" ] && [ "$SESSIONS_HOME" != "$HOME" ] || exit 92' \
		'[ "$SESSIONS_DATA_DIR" = "$HOME/.local/share/sessions" ] || exit 93' \
		'if [ "${SESSIONS_STATUS:-0}" != 0 ]; then exit "$SESSIONS_STATUS"; fi' \
		'for skill in context memory recall session-metrics standup weekly-summary; do' \
		'mkdir -p "$SESSIONS_DATA_DIR/plugin/skills/$skill"' \
		'touch "$SESSIONS_DATA_DIR/plugin/skills/$skill/SKILL.md"' \
		'done' >"$XDG_DATA_HOME/mise/shims/sessions"
	chmod +x "$src/scripts/install-pi-tools" "$src/bin/pi" "$XDG_DATA_HOME/mise/shims/"*
}

test_replacement_and_idempotence() {
	run bash "$updater"
	[ "$status" -eq 0 ]
	run jq -es '.[0] == .[1]' "$managed" "$runtime"
	[ "$status" -eq 0 ]
	run rg -Fx 'pi update --extensions' "$CALLS"
	[ "$status" -eq 0 ]
	cp "$runtime" "$test_dir/first.json"
	run bash "$updater"
	[ "$status" -eq 0 ]
	cmp "$runtime" "$test_dir/first.json"
}

test_invalid_source_preserves_runtime() {
	cp "$runtime" "$test_dir/before.json"
	for invalid in '{' '[]' 'null' '' '{} {}'; do
		printf '%s\n' "$invalid" >"$managed"
		run bash "$updater"
		[ "$status" -ne 0 ]
		cmp "$runtime" "$test_dir/before.json"
		[ ! -e "$CALLS" ]
		[ ! -e "$AUX_CALLS" ]
	done
}

test_dry_run() {
	cp "$runtime" "$test_dir/before.json"
	run bash "$updater" --dry-run
	[ "$status" -eq 0 ]
	[[ "$output" == *'npm:current'* ]]
	[[ "$output" != *'npm:old'* ]]
	[[ "$output" != *'old.ts'* ]]
	[[ "$output" == *'[would run] mise upgrade npm:@earendil-works/pi-coding-agent --yes --raw'* ]]
	cmp "$runtime" "$test_dir/before.json"
	[ ! -e "$CALLS" ]
	[ ! -e "$AUX_CALLS" ]
}

test_malformed_runtime() {
	printf '%s\n' '{broken' >"$runtime"
	run bash "$updater"
	[ "$status" -eq 0 ]
	run jq -es '.[0] == .[1]' "$managed" "$runtime"
	[ "$status" -eq 0 ]
}

test_helper_failure() {
	export HELPER_STATUS=73
	run bash "$updater"
	[ "$status" -eq 73 ]
	[[ "$output" == *'FAILED: Install pinned helpers (exit 73)'* ]]
	[[ "$output" != *'OK: Install pinned helpers'* ]]
	[[ "$output" != *'update:pi done.'* ]]
	run jq -es '.[0] == .[1]' "$managed" "$runtime"
	[ "$status" -eq 0 ]
	[ ! -e "$CALLS" ]
}

test_missing_runtime_preserves_auth_and_sessions() {
	mv "$runtime" "$test_dir/old-runtime.json"
	mkdir -p "$HOME/.pi/agent/sessions"
	printf '%s\n' 'session sentinel' >"$HOME/.pi/agent/sessions/keep.jsonl"
	cp "$HOME/.pi/agent/auth.json" "$test_dir/auth.json"
	run bash "$updater"
	[ "$status" -eq 0 ]
	run jq -es '.[0] == .[1]' "$managed" "$runtime"
	[ "$status" -eq 0 ]
	cmp "$HOME/.pi/agent/auth.json" "$test_dir/auth.json"
	[ "$(<"$HOME/.pi/agent/sessions/keep.jsonl")" = 'session sentinel' ]
}

test_progress_and_command_order() {
	run bash "$updater"
	[ "$status" -eq 0 ]
	local remaining="$output" step marker
	for step in "Sync settings" "Install pinned helpers" "Remove disabled Pi links" \
		"Refresh sessions plugin" "Clean redundant extension dependencies" \
		"Upgrade mise-managed Pi" "Check Pi self-update" "Update extension packages"; do
		for marker in "==> $step" "OK: $step (exit 0)"; do
			[[ "$remaining" == *"$marker"* ]]
			remaining="${remaining#*"$marker"}"
		done
	done
	[[ "$remaining" == *'update:pi done.'* ]]
	[[ "$output" == *'pi stdout: update --extensions'* ]]
	[[ "$output" == *'pi stderr: update --extensions'* ]]
	[[ "$output" != *$'\033[2J'* ]]
	[ "$(<"$CALLS")" = $'mise upgrade npm:@earendil-works/pi-coding-agent --yes --raw\npi update\npi update --extensions' ]
}

test_step_failures_stop_updates() {
	local failure step
	for failure in SESSIONS_STATUS MISE_STATUS PI_SELF_STATUS PI_EXTENSIONS_STATUS; do
		: >"$CALLS"
		case "$failure" in
		SESSIONS_STATUS) step="Refresh sessions plugin" ;;
		MISE_STATUS) step="Upgrade mise-managed Pi" ;;
		PI_SELF_STATUS) step="Check Pi self-update" ;;
		PI_EXTENSIONS_STATUS) step="Update extension packages" ;;
		esac
		run env "$failure=37" bash "$updater"
		[ "$status" -eq 37 ]
		[[ "$output" == *"FAILED: $step (exit 37)"* ]]
		[[ "$output" != *"OK: $step"* ]]
		[[ "$output" != *'update:pi done.'* ]]
		case "$failure" in
		SESSIONS_STATUS) [ ! -s "$CALLS" ] ;;
		MISE_STATUS) [[ "$(<"$CALLS")" != *'pi update'* ]] ;;
		PI_SELF_STATUS) [[ "$(<"$CALLS")" != *'pi update --extensions'* ]] ;;
		esac
	done
}

test_internal_failure_keeps_errexit() {
	cp "$runtime" "$test_dir/before.json"
	printf '%s\n' '#!/usr/bin/env bash' 'exit 72' >"$XDG_DATA_HOME/mise/shims/mv"
	chmod +x "$XDG_DATA_HOME/mise/shims/mv"
	run bash "$updater"
	[ "$status" -eq 72 ]
	[[ "$output" == *'FAILED: Sync settings (exit 72)'* ]]
	[[ "$output" != *'synced settings'* ]]
	cmp "$runtime" "$test_dir/before.json"
	[ ! -e "$CALLS" ]
}

test_direct_tty_output() {
	# macOS script allocates a test-only PTY; it never touches a user's pane.
	run env EXPECT_TTY=1 /usr/bin/script -q "$test_dir/tty.log" bash "$updater" </dev/null
	[ "$status" -eq 0 ]
	[[ "$output" == *'OK: Update extension packages (exit 0)'* ]]
	[[ "$output" == *$'\033[32mmise color retained\033[0m'* ]]
	[[ "$output" != *$'\033[2J'* ]]
}

for test in test_replacement_and_idempotence test_invalid_source_preserves_runtime \
	test_dry_run test_malformed_runtime test_helper_failure \
	test_missing_runtime_preserves_auth_and_sessions test_progress_and_command_order \
	test_step_failures_stop_updates test_internal_failure_keeps_errexit test_direct_tty_output; do
	test_dir="$test_root/$test"
	(
		set -E
		trap 'printf "FAIL: %s\n%s\n" "$test" "${output:-}" >&2' ERR
		setup
		"$test"
		[ "$(<"$HOME/.pi/agent/auth.json")" = '{"sentinel":true}' ]
		[ "$(<"$HOME/.pi/agent/sessions/keep.jsonl")" = 'session sentinel' ]
	)
	printf 'PASS: %s\n' "$test"
done
