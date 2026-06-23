# mise + fnox shell integration.
if command -q mise
  mise activate fish | source
end

if command -q fnox
  fnox activate fish | source
end

# Legacy OpNix-compatible env files rendered by scripts/mise/render-fnox-files.
function __fnox_source_posix_env --argument-names file
  test -f "$file" || return
  while read -l line
    set -l line (string trim -- "$line")
    test -z "$line" && continue
    string match -qr '^#' -- "$line" && continue
    set line (string replace -r '^export[[:space:]]+' '' -- "$line")
    string match -qr '^[A-Za-z_][A-Za-z0-9_]*=' -- "$line" || continue
    set -l parts (string split -m1 = -- "$line")
    set -gx $parts[1] $parts[2]
  end < "$file"
end

__fnox_source_posix_env "$XDG_CONFIG_HOME/fnox/secrets/env-vars.sh"
__fnox_source_posix_env "$XDG_CONFIG_HOME/fnox/secrets/work-env-vars.sh"

if set -q SYNTHETIC_API_KEY
  set -gx LAT_LLM_KEY $SYNTHETIC_API_KEY
  set -gx LAT_LLM_BASE_URL "https://api.synthetic.new/openai/v1"
  set -gx LAT_LLM_MODEL "hf:nomic-ai/nomic-embed-text-v1.5"
  set -gx LAT_LLM_DIMENSIONS 768
end

set -l apple_dir "$XDG_CONFIG_HOME/fnox/secrets/apple-developer"
test -f "$apple_dir/apple-id"; and set -gx APPLE_ID_EMAIL (string collect < "$apple_dir/apple-id")
test -f "$apple_dir/team-id"; and set -gx APPLE_TEAM_ID (string collect < "$apple_dir/team-id")
test -f "$apple_dir/notarytool-password"; and set -gx APPLE_NOTARYTOOL_PASSWORD (string collect < "$apple_dir/notarytool-password")

functions -e __fnox_source_posix_env
