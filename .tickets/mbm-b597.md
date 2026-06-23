---
id: mbm-b597
status: closed
deps: []
links: []
created: 2026-06-22T20:32:32Z
type: feature
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Prototype fnox replacement for OpNix-rendered secrets

Make the fnox migration path concrete without committing plaintext secrets. The current plan is to keep 1Password as the vault, use fnox as user-land resolver, and render legacy files under ~/.config/fnox/secrets/ so Pi, shell startup, Apple notarization, and .s3cfg keep working while callers move away from OpNix paths.

Context: migration session chose fnox.jdx.dev to replace OpNix declarations while retaining 1Password.

File hints: mise/fnox/config.toml, scripts/mise/render-fnox-files, mise.toml task `fnox:render`, existing OpNix/secrets references under home/common/ and modules/.

## Acceptance Criteria

1. Existing OpNix-managed secret outputs used by this repo are inventoried with destination paths and consumers.
2. `mise/fnox/config.toml` contains placeholder-safe mappings for required secrets and no plaintext secret values.
3. `scripts/mise/render-fnox-files` can run in dry-run/check mode or otherwise validates prerequisites before writing.
4. Legacy output paths under ~/.config/fnox/secrets/ are documented so existing consumers can migrate gradually.
5. 1Password service account token handling is local-only/encrypted and never committed as plaintext.
6. `lat.md/migration/mise-bootstrap.md` is updated if the secrets ownership model changes; `lat_check` passes.

## Notes

**2026-06-23T16:47:57Z**

Implemented fnox prototype:

1. Secret inventory documented (5 common + 1 work): ENV_VARS_SH, S3CFG, APPLE_ID_EMAIL, APPLE_TEAM_ID, APPLE_NOTARYTOOL_PASSWORD, WORK_ENV_VARS_SH.
2. mise/fnox/config.toml: placeholder-safe (AGE_RECIPIENT_REPLACE_ME), all 1Password refs use op:// URIs, work secrets commented out.
3. scripts/mise/render-fnox-files: added --check, --dry-run, --inventory modes. Dry-run reports prerequisites without writing.
4. Shell init snippets: mise/dotfiles/fish/conf.d/fnox.fish (fish), mise/dotfiles/bash/fnox.sh (bash). Both load env-vars.sh, LAT*LLM*\*, apple secrets, work secrets. Replaces OpNix programs.{fish,bash,zsh} shell init.
5. Legacy output paths: ~/.config/fnox/secrets/env-vars.sh, ~/.s3cfg, ~/.config/fnox/secrets/apple-developer/\*. Documented in inventory.
6. Token: OP_SERVICE_ACCOUNT_TOKEN stays local/encrypted via fnox age provider, never committed.
7. mise.toml: added fnox:check, fnox:dry-run tasks; bash dotfile target for fnox.sh.
8. lat_check passed, shellcheck clean.
