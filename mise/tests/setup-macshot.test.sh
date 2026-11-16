#!/usr/bin/env bash
# setup-macshot writes the DO Spaces upload settings from fnox into a plist,
# never prints the secret, and leaves unchanged settings alone.
set -euo pipefail

script="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)/setup-macshot"
test_dir="$(mktemp -d)"
trap 'trash "$test_dir"' EXIT

mkdir -p "$test_dir/bin"
cat >"$test_dir/bin/fnox" <<'EOF'
#!/usr/bin/env bash
case "$2" in
  DO_SPACES_CAPS_KEY) echo test-key ;;
  DO_SPACES_CAPS_SECRET) echo "${FAKE_SECRET-test-secret-value&<x>}" ;;
  DO_SPACES_CAPS_SPACE) echo caps ;;
  DO_SPACES_CAPS_REGION) echo nyc3 ;;
  DO_SPACES_CAPS_CDN_URL) echo https://caps.nyc3.cdn.digitaloceanspaces.com/ ;;
  *) exit 1 ;;
esac
EOF
# Records every defaults command line: the secret must never be on one.
cat >"$test_dir/bin/defaults" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >>"$test_dir/argv"
exec /usr/bin/defaults "\$@"
EOF
chmod +x "$test_dir/bin/fnox" "$test_dir/bin/defaults"
export PATH="$test_dir/bin:$PATH" MACSHOT_RESTART=0
export MACSHOT_DOMAIN="$test_dir/macshot.plist"
/usr/bin/defaults write "$MACSHOT_DOMAIN" hotkeyKeyCode -int 21

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

out="$("$script" 2>&1)" || fail "first run failed: $out"
[[ "$out" != *test-secret-value* ]] || fail "secret printed"
[[ "$out" == *"wrote uploadProvider"* ]] || fail "first run wrote nothing: $out"

read_pref() { defaults read "$MACSHOT_DOMAIN" "$1"; }
[[ "$(read_pref uploadProvider)" == s3 ]] || fail uploadProvider
[[ "$(read_pref s3Endpoint)" == https://nyc3.digitaloceanspaces.com ]] || fail s3Endpoint
[[ "$(read_pref s3Region)" == nyc3 ]] || fail s3Region
[[ "$(read_pref s3Bucket)" == caps ]] || fail s3Bucket
[[ "$(read_pref s3SecretAccessKey)" == 'test-secret-value&<x>' ]] || fail s3SecretAccessKey
[[ "$(read_pref s3PublicURLBase)" == https://caps.nyc3.cdn.digitaloceanspaces.com ]] || fail s3PublicURLBase
[[ "$(read_pref s3PathPrefix)" == screenshots/ ]] || fail s3PathPrefix
[[ "$(read_pref s3PublicRead)" == 1 ]] || fail s3PublicRead
[[ "$(read_pref hotkeyKeyCode)" == 21 ]] || fail "import dropped an existing preference"
! grep -q test-secret-value "$test_dir/argv" || fail "secret on a defaults command line"
grep -q 'import' "$test_dir/argv" || fail "settings not imported"

out="$("$script" 2>&1)"
[[ "$out" == "setup-macshot: unchanged" ]] || fail "second run not idempotent: $out"

out="$(FAKE_SECRET="" "$script" 2>&1)" && fail "empty secret accepted"
[[ "$out" == *"empty DO_SPACES_CAPS_SECRET"* ]] || fail "unclear empty-value error: $out"

echo "setup-macshot: ok"
