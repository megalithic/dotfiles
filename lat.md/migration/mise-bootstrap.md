# Mise bootstrap migration

Mise bootstrap is the proposed replacement orchestration layer for the current nix-darwin and Home Manager workstation setup.

The migration keeps Nix installed for legacy flakes, devenv itself, devenv projects, and external Nix repos, but stops treating Nix as the primary owner of macOS user configuration.

## Ownership model

Mise owns repeatable user workstation convergence where its experimental bootstrap model is strong enough.

- `mise.toml` is the workstation bootstrap config.
- `mise/Brewfile` owns GUI casks, Mac App Store apps, and the few Homebrew formulae needed to drive that app layer.
- Mise `[tools]` owns dev CLIs and runtimes, preferring Aqua-backed tools where the mise registry supports them.
- `mise/global.toml` carries the baseline Neovim LSP toolchain that should be available outside project-specific mise configs, including Tailwind, Nix, and JS/TS servers.
- `aube` is the preferred npm package manager and is installed through mise alongside Node.
- `mise/fnox/config.toml` replaces OpNix declarations for 1Password-backed user secrets.
- `scripts/mise/*` owns special cases that need imperative macOS behavior.
- `scripts/mise/dotfile-preflight` is the read-only guard for mise `[dotfiles]` adoption; it follows symlink chains and reports ownership before bootstrap mutates files. Dotfile targets were reconciled against the classifier inventory in `mbm-qkmx`: SSH, espanso, and kanata paths fixed; fish and git file handling deferred to `mbm-8afn`.
- Existing `config/*`, `bin/*`, and selected `home/common/programs/*` files remain source material while the migration is staged.

## Host overlays

Both MacBook Pro hosts share one baseline and differ only where hardware or work context requires it.

`megabookpro` and `workbookpro` share app lists, dotfiles, shell setup, Pi setup, Helium setup, and fnox secret shape. Host-specific logic lives in scripts that branch on `hostname -s`, such as llama.cpp launch parameters. Settings-sync is not migrated in v1.

## Boundaries

Mise bootstrap is not a full nix-darwin or Home Manager clone.

Keep special handling for privileged/system behavior: Determinate Nix install or repair, 1Password GUI placement in `/Applications`, Okta Verify package installation, kanata TCC-safe binary path, complex nested macOS plist writes, and any service that needs LaunchDaemons rather than user LaunchAgents.

## Host-specific configuration

Hostname-based branching uses `$(hostname -s)` in imperative scripts. `mise.toml` remains a single shared config; per-host differences are handled in scripts rather than config file variants.

**Current overrides:**

| Host          | Script                              | Behavior                                                               |
| ------------- | ----------------------------------- | ---------------------------------------------------------------------- |
| `workbookpro` | `scripts/mise/llama-server-launchd` | Higher `ctx_size` (32768), `parallel` (2), `models_max` (2) — more RAM |
| `workbookpro` | `scripts/mise/render-fnox-files`    | Conditionally renders `WORK_ENV_VARS_SH` if the 1Password item exists  |
| All           | `scripts/install.sh`                | Detects hostname, sets ComputerName/HostName/LocalHostName             |

**Pattern for adding overrides:**

```bash
case "$(hostname -s)" in
  workbookpro)
    # work-specific settings
    ;;
  megabookpro)
    # personal defaults (fallback)
    ;;
esac
```

**Future platforms** (documented, not implemented):

- Linux (UGREEN NAS, Raspberry Pi/Home Assistant): platform detection via `uname -s` and `/etc/os-release`, following the AllySummers pattern
- Platform-specific Brewfile variants, apt/pacman package lists
- Platform-agnostic dotfiles with host-specific conf.d overrides

## Secrets

Fnox becomes the user-land secret resolver and keeps 1Password as the vault.

The migration renders legacy files under `~/.config/fnox/secrets/` so Pi, shell startup, Apple notarization, and `.s3cfg` keep working while callers move from OpNix paths. The 1Password service account token must stay encrypted or local-only, never committed as plaintext.

## Project environments

Mise project configs gradually replace `devenv.nix` where project needs fit tool versions, env files, tasks, and lightweight service wrappers.

The root `mise.toml` covers `.dotfiles`; staged examples in `mise/projects/` cover `rx` and `verify-doctor`. Nix/devenv remains available for projects that still need Nix services, overlays, or exact nixpkgs package composition.

## Version gate

The migration requires mise `2026.6.6` or newer because the current installed `2026.6.5` does not include bootstrap/dotfiles commands.

Until mise is upgraded, `mise bootstrap --dry-run` reports unknown `bootstrap` and `dotfiles` fields and stops on the hard `min_version` guard. This is expected and prevents accidental partial application with an older CLI.
