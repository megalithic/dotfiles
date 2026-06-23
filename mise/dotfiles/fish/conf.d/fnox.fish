# fnox secret loading for fish shell.
# Replaces OpNix-generated programs.fish.interactiveShellInit.
# Source this from mise/dotfiles/fish/config.fish or conf.d/fnox.fish.

set -q __fnox_secrets_sourced; and exit
set -g __fnox_secrets_sourced 1

set -g secrets_dir "$XDG_CONFIG_HOME/fnox/secrets"

# Load POSIX-style KEY=value secrets as fish environment variables
function __fnox_source_env_file --argument-names file
  test -f "$file" || return
  while read -l line
    set -l line (string trim -- "$line")
    test -z "$line" && continue
    string match -qr '^#' -- "$line" && continue
    set line (string replace -r '^export[[:space:]]+' "" -- "$line")
    string match -qr '^[A-Za-z_][A-Za-z0-9_]*=' -- "$line" || continue
    set -l parts (string split -m1 = -- "$line")
    set -gx $parts[1] $parts[2]
  end < "$file"
end

__fnox_source_env_file "$secrets_dir/env-vars.sh"

# lat.md semantic search → synthetic embeddings (exempt from chat rate limit)
if set -q SYNTHETIC_API_KEY
  set -gx LAT_LLM_KEY $SYNTHETIC_API_KEY
  set -gx LAT_LLM_BASE_URL "https://api.synthetic.new/openai/v1"
  set -gx LAT_LLM_MODEL "hf:nomic-ai/nomic-embed-text-v1.5"
  set -gx LAT_LLM_DIMENSIONS 768
end

# Apple developer secrets (exported as env vars for notarization)
test -f "$secrets_dir/apple-developer/apple-id"
  and set -gx APPLE_ID_EMAIL (string collect < "$secrets_dir/apple-developer/apple-id")
test -f "$secrets_dir/apple-developer/team-id"
  and set -gx APPLE_TEAM_ID (string collect < "$secrets_dir/apple-developer/team-id")
test -f "$secrets_dir/apple-developer/notarytool-password"
  and set -gx APPLE_NOTARYTOOL_PASSWORD (string collect < "$secrets_dir/apple-developer/notarytool-password")

# Work host secrets (workbookpro only)
__fnox_source_env_file "$secrets_dir/work-env-vars.sh"

functions -e __fnox_source_env_file
