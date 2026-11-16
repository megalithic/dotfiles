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
  DO_SPACES_CAPS_SECRET) echo "${FAKE_SECRET-test-secret-value}" ;;
  DO_SPACES_CAPS_SPACE) echo caps ;;
  DO_SPACES_CAPS_REGION) echo nyc3 ;;
  DO_SPACES_CAPS_CDN_URL) echo https://caps.nyc3.cdn.digitaloceanspaces.com/ ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$test_dir/bin/fnox"
export PATH="$test_dir/bin:$PATH" MACSHOT_RESTART=0
export MACSHOT_DOMAIN="$test_dir/macshot.plist"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

out="$("$script" 2>&1)"
[[ "$out" != *test-secret-value* ]] || fail "secret printed"
[[ "$out" == *"wrote uploadProvider"* ]] || fail "first run wrote nothing: $out"

read_pref() { defaults read "$MACSHOT_DOMAIN" "$1"; }
[[ "$(read_pref uploadProvider)" == s3 ]] || fail uploadProvider
[[ "$(read_pref s3Endpoint)" == https://nyc3.digitaloceanspaces.com ]] || fail s3Endpoint
[[ "$(read_pref s3Region)" == nyc3 ]] || fail s3Region
[[ "$(read_pref s3Bucket)" == caps ]] || fail s3Bucket
[[ "$(read_pref s3SecretAccessKey)" == test-secret-value ]] || fail s3SecretAccessKey
[[ "$(read_pref s3PublicURLBase)" == https://caps.nyc3.cdn.digitaloceanspaces.com ]] || fail s3PublicURLBase
[[ "$(read_pref s3PathPrefix)" == screenshots/ ]] || fail s3PathPrefix
[[ "$(read_pref s3PublicRead)" == 1 ]] || fail s3PublicRead

out="$("$script" 2>&1)"
[[ "$out" == "setup-macshot: unchanged" ]] || fail "second run not idempotent: $out"

out="$(FAKE_SECRET="" "$script" 2>&1)" && fail "empty secret accepted"
[[ "$out" == *"empty DO_SPACES_CAPS_SECRET"* ]] || fail "unclear empty-value error: $out"

echo "setup-macshot: ok"
