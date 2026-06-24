#!/usr/bin/env bash
# fnox secret loading for bash shell.
# Replaces OpNix-generated programs.bash.bashrcExtra.
# Source from ~/.bashrc or ~/.bash_profile.
# shellcheck shell=bash

__FNOX_SECRETS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/fnox/secrets"

# Load POSIX-style KEY=value secrets as environment variables
if [ -f "$__FNOX_SECRETS_DIR/env-vars.sh" ]; then
  source "$__FNOX_SECRETS_DIR/env-vars.sh"
fi

# lat.md semantic search → synthetic embeddings (exempt from chat rate limit)
if [ -n "$SYNTHETIC_API_KEY" ]; then
  export LAT_LLM_KEY="$SYNTHETIC_API_KEY"
  export LAT_LLM_BASE_URL="https://api.synthetic.new/openai/v1"
  export LAT_LLM_MODEL="hf:nomic-ai/nomic-embed-text-v1.5"
  export LAT_LLM_DIMENSIONS="768"
fi

# Apple developer secrets (exported as env vars for notarization)
if [ -f "$__FNOX_SECRETS_DIR/apple-developer/apple-id" ]; then
  APPLE_ID_EMAIL="$(cat "$__FNOX_SECRETS_DIR/apple-developer/apple-id")"
  export APPLE_ID_EMAIL
fi
if [ -f "$__FNOX_SECRETS_DIR/apple-developer/team-id" ]; then
  APPLE_TEAM_ID="$(cat "$__FNOX_SECRETS_DIR/apple-developer/team-id")"
  export APPLE_TEAM_ID
fi
if [ -f "$__FNOX_SECRETS_DIR/apple-developer/notarytool-password" ]; then
  APPLE_NOTARYTOOL_PASSWORD="$(cat "$__FNOX_SECRETS_DIR/apple-developer/notarytool-password")"
  export APPLE_NOTARYTOOL_PASSWORD
fi

# Work host secrets (workbookpro only)
if [ -f "$__FNOX_SECRETS_DIR/work-env-vars.sh" ]; then
  source "$__FNOX_SECRETS_DIR/work-env-vars.sh"
fi

unset __FNOX_SECRETS_DIR
