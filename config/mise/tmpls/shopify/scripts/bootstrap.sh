#!/usr/bin/env bash
# Generate safe default Shopify, Theme Check, Biome, Prettier, gitignore, and
# package files. Run by `mise run bootstrap`. Every write is idempotent
# (write_if_missing / ensure_line), so re-running never clobbers edits.
set -euo pipefail

write_if_missing() {
  local path="$1"
  if [ -e "$path" ]; then
    echo "exists: $path"
    return 0
  fi
  mkdir -p "$(dirname "$path")"
  cat >"$path"
  echo "created: $path"
}

ensure_line() {
  local path="$1"
  local line="$2"
  touch "$path"
  if ! awk -v wanted="$line" '$0 == wanted { found = 1 } END { exit(found ? 0 : 1) }' "$path"; then
    printf "%s\n" "$line" >>"$path"
    echo "added to $path: $line"
  fi
}

project_name="$(basename "$PWD" | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-z0-9._-]/-/g' -e 's/--*/-/g' -e 's/^[._-]*//' -e 's/[._-]*$//')"
[ -n "$project_name" ] || project_name="shopify-theme"
store="${SHOPIFY_FLAG_STORE:-example.myshopify.com}"

write_if_missing package.json <<EOF
{
  "name": "$project_name",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "shopify theme dev",
    "check": "biome check . && shopify theme check && prettier --check \"**/*.liquid\"",
    "format": "biome check --write . && prettier --write \"**/*.liquid\"",
    "format:check": "biome check . && prettier --check \"**/*.liquid\""
  },
  "devDependencies": {
    "@biomejs/biome": "latest",
    "@shopify/cli": "latest",
    "@shopify/prettier-plugin-liquid": "latest",
    "prettier": "latest"
  }
}
EOF

write_if_missing biome.json <<'EOF'
{
  "$schema": "https://biomejs.dev/schemas/latest/schema.json",
  "vcs": {
    "enabled": true,
    "clientKind": "git",
    "useIgnoreFile": true
  },
  "files": {
    "includes": [
      "**",
      "!**/*.liquid",
      "!node_modules",
      "!coverage",
      "!dist",
      "!.local",
      "!.shopify",
      "!.theme-check-cache"
    ]
  },
  "formatter": {
    "enabled": true,
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 120
  },
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true
    }
  },
  "assist": {
    "enabled": true,
    "actions": {
      "source": {
        "organizeImports": "on"
      }
    }
  },
  "javascript": {
    "formatter": {
      "quoteStyle": "single",
      "semicolons": "asNeeded",
      "trailingCommas": "all"
    }
  }
}
EOF

write_if_missing .prettierrc.json <<'EOF'
{
  "plugins": ["@shopify/prettier-plugin-liquid"],
  "printWidth": 120,
  "tabWidth": 2,
  "useTabs": false,
  "singleQuote": true,
  "liquidSingleQuote": true,
  "embeddedSingleQuote": true,
  "htmlWhitespaceSensitivity": "css",
  "singleLineLinkTags": false,
  "indentSchema": true,
  "overrides": [
    {
      "files": "*.liquid",
      "options": {
        "parser": "liquid-html"
      }
    }
  ]
}
EOF

write_if_missing .prettierignore <<'EOF'
node_modules
coverage
dist
.local
.shopify
.theme-check-cache
EOF

write_if_missing .theme-check.yml <<'EOF'
extends: theme-check:recommended

ignore:
  - node_modules/**
  - coverage/**
  - dist/**
  - .local/**
  - .shopify/**
EOF

write_if_missing .shopifyignore <<'EOF'
# Repo-only files. Shopify CLI excludes these from dev/push/pull/share.
.git/
.github/
.jj/
.local/
.pi/
.mise.toml
mise.toml
.config/
.env
.env.*
AGENTS.md
README.md
node_modules/
coverage/
dist/
package.json
package-lock.json
pnpm-lock.yaml
yarn.lock
biome.json
.prettierrc*
.prettierignore
.theme-check.yml
.theme-check.yaml
EOF

write_if_missing shopify.theme.toml <<EOF
# Shopify CLI theme environments.
# Docs: https://shopify.dev/docs/storefronts/themes/tools/cli/environments
#
# Store credentials stay outside this file:
#   - browser auth: run a Shopify CLI command and log in
#   - Theme Access token: set SHOPIFY_CLI_THEME_TOKEN in .env.local

[environments.default]
store = "$store"
# theme = "1234567890"
# ignore = ["config/settings_data.json"]

[environments.staging]
store = "$store"
# theme = "1234567890"

[environments.production]
store = "$store"
# theme = "1234567890"
EOF

write_if_missing .env.example <<'EOF'
# Copy to .env.local and fill values for this machine.
SHOPIFY_FLAG_STORE=example.myshopify.com
# Optional Theme Access password / Admin API token for non-browser auth.
SHOPIFY_CLI_THEME_TOKEN=
# Optional password-protected storefront password.
SHOPIFY_FLAG_STORE_PASSWORD=
EOF

ensure_line .gitignore ".config/"
ensure_line .gitignore "node_modules/"
ensure_line .gitignore ".env.local"
ensure_line .gitignore ".env.*.local"
ensure_line .gitignore ".local/"
ensure_line .gitignore ".shopify/"
ensure_line .gitignore ".theme-check-cache/"

printf '\nNext:\n'
printf '  1. Copy .env.example to .env.local and set SHOPIFY_FLAG_STORE.\n'
printf '  2. Run `mise run install`.\n'
printf '  3. Pull an existing theme with `mise run theme:pull -- --store your-store.myshopify.com`,\n'
printf '     or initialize one with `mise run theme:init -- my-theme`.\n'
printf '  4. Run `mise run dev` and open http://127.0.0.1:%s.\n' "${SHOPIFY_THEME_PORT:-9292}"
