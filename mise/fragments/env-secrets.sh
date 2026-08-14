#!/bin/sh
# Sourced by mise [env] _.source (global_config.toml). Secrets chain:
# fnox when configured (workbookpro), else opnix-rendered env vars
# (megabookpro during the nix -> mise migration). Keeping this in a script
# lets hosts without fnox avoid per-shell "fnox export" failures.
if command -v fnox >/dev/null 2>&1 && [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/fnox/config.toml" ]; then
  eval "$(fnox export --format shell 2>/dev/null || true)"
elif [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/opnix/secrets/env-vars.sh" ]; then
  # shellcheck disable=SC1091
  . "${XDG_CONFIG_HOME:-$HOME/.config}/opnix/secrets/env-vars.sh"
fi
