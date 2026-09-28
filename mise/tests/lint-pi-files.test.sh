#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
test_dir=$(mktemp -d)
trap 'trash "$test_dir"' EXIT

mkdir -p \
	"$test_dir/config/pi-coding-agent/agent/extensions" \
	"$test_dir/home/.pi/agent/extensions" \
	"$test_dir/bin"

old="$test_dir/config/pi-coding-agent/agent/extensions/example.ts"
new="$test_dir/home/.pi/agent/extensions/example.ts"
printf 'export const value = 1;\n' >"$old"
cp "$old" "$new"

cat >"$test_dir/bin/oxlint" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >>"$OXLINT_LOG"
EOF
chmod +x "$test_dir/bin/oxlint"

git -C "$test_dir" init -q
git -C "$test_dir" add config/pi-coding-agent/agent/extensions/example.ts
git -C "$test_dir" -c user.name=test -c user.email=test@example.invalid -c commit.gpgSign=false commit -qm base

run_helper() {
	(
		cd "$test_dir"
		PATH="$test_dir/bin:$PATH" \
			OXLINT_LOG="$test_dir/oxlint.log" \
			"$repo_root/mise/scripts/lint-pi-files" home/.pi/agent/extensions/example.ts
	)
}

run_helper
rg -F -- 'home/.pi/agent/extensions/example.ts' "$test_dir/oxlint.log" >/dev/null

: >"$test_dir/oxlint.log"
git -C "$test_dir" add home/.pi/agent/extensions/example.ts
run_helper
rg -F -- 'home/.pi/agent/extensions/example.ts' "$test_dir/oxlint.log" >/dev/null

: >"$test_dir/oxlint.log"
git -C "$test_dir" rm -q "$old"
run_helper
test ! -s "$test_dir/oxlint.log"

printf 'export const value = 2;\n' >"$new"
run_helper
rg -F -- 'home/.pi/agent/extensions/example.ts' "$test_dir/oxlint.log" >/dev/null

: >"$test_dir/oxlint.log"
git -C "$test_dir" add home/.pi/agent/extensions/example.ts
run_helper
rg -F -- 'home/.pi/agent/extensions/example.ts' "$test_dir/oxlint.log" >/dev/null

printf 'export const value = 1;\n' >"$new"
git -C "$test_dir" add home/.pi/agent/extensions/example.ts
git -C "$test_dir" -c user.name=test -c user.email=test@example.invalid -c commit.gpgSign=false commit -qm move-source
: >"$test_dir/oxlint.log"
run_helper
rg -F -- 'home/.pi/agent/extensions/example.ts' "$test_dir/oxlint.log" >/dev/null

echo 'PASS: only staged, byte-identical moves skip lint'
