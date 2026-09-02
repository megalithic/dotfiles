#!/usr/bin/env bash
# Print Shopify local development diagnostics. Run by `mise run doctor`.
# Reads SHOPIFY_THEME_* from the mise env.
set -euo pipefail
printf "node: "
node --version
printf "npm: "
npm --version
printf "shopify: "
shopify version
printf "biome: "
biome --version
printf "prettier: "
prettier --version
printf "theme env: %s\n" "$SHOPIFY_THEME_ENV"
printf "theme host: %s\n" "$SHOPIFY_THEME_HOST"
printf "theme port: %s\n" "$SHOPIFY_THEME_PORT"
printf "theme live reload: %s\n" "$SHOPIFY_THEME_LIVE_RELOAD"
if [ -f shopify.theme.toml ]; then
  echo "shopify.theme.toml: present"
else
  echo "shopify.theme.toml: missing (run mise run bootstrap)"
fi
if [ -f .theme-check.yml ] || [ -f .theme-check.yaml ]; then
  echo "theme check config: present"
else
  echo "theme check config: missing (run shopify theme check --init or mise run bootstrap)"
fi
if [ -f biome.json ] || [ -f biome.jsonc ]; then
  echo "biome config: present"
else
  echo "biome config: missing (run mise run bootstrap)"
fi
if [ -f .prettierrc.json ] || [ -f .prettierrc ] || [ -f prettier.config.js ]; then
  echo "prettier config: present (Liquid only)"
else
  echo "prettier config: missing (run mise run bootstrap)"
fi
