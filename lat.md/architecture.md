# Dotfiles architecture

This repo is a single-flake nix-darwin + Home Manager setup for macOS. One root `flake.nix` produces both `darwinConfigurations` and `homeConfigurations` for two hosts; it does not mirror the two-flake layout some other setups use.

## Flake topology

`flake.nix` pins `nixpkgs-unstable` and makes `home-manager` and `nix-darwin` follow it.

Other inputs include `opnix`, `neovim-nightly-overlay`, `devenv`, `hunk`, `nh`, `kanata-darwin`, `yazi`, `nix-homebrew` plus the Homebrew taps, and `brew-nix` for cask and `mas` packaging.

Global constants live in the flake `let`: `arch = "aarch64-darwin"`, `version` (Home Manager/system state version), and `username = "seth"`. `lib` is `nixpkgs.lib` extended with `./lib/default.nix`, and `overlays` come from `./overlays`.

Outputs are built by three builders and cover two hosts:

- `darwinConfigurations.megabookpro` and `darwinConfigurations.workbookpro` via `mkDarwin`
- `homeConfigurations."seth@megabookpro"` and `"seth@workbookpro"` via `mkHome`
- `apps.${arch}.default` bootstrap script via `mkInit`

`megabookpro` is the personal laptop and `workbookpro` is the work laptop; per-host overrides live in `hosts/<host>.nix` and `home/<host>.nix`.

## lib.mega and builders

Custom helpers are namespaced under `lib.mega`, added by `lib.extend (import ./lib/default.nix inputs)`. `lib/default.nix` also merges `home-manager.lib` and `nix-darwin.lib` into the extended `lib`.

Builders under `lib/`:

- `mkDarwin.nix` — builds a nix-darwin system; receives `hostname` and `username`, plus shared `inputs`, `lib`, `overlays`, `brew_config`, `version`.
- `mkHome.nix` — builds a standalone Home Manager configuration with matching special args.
- `mkInit.nix` — wraps a bootstrap shell script as the flake's default app.
- `mkApp.nix` (+ `lib/mkApp/extract.nix`) — macOS `.app` builder that extracts DMG/ZIP/PKG into the store and symlinks or copies into `/Applications`.
- `builders/mkChromiumBrowser.nix` and `builders/mkWrapperApp.nix` — `.app` wrappers for Chromium-family browsers and custom-arg app wrappers.
- `paths.nix` — canonical path helpers (`home`, `config`, `localBin`, `dotfiles`, cloud dirs) passed through special args as `paths`.

`mkDarwin` and `mkHome` must pass identical special args (`inputs`, `username`, `hostname`, `version`, `overlays`, `lib`, `paths`, `arch`, `self`). App installation into `/Applications` is driven by `lib.mega.mkAppActivation`, which reads `config.mega.customApps` and also links exposed CLI binaries into `~/.local/bin`, cleaning up orphaned apps and binaries by metadata files under `~/.local/share/nix-apps` and `nix-bins`.

## Custom packages overlay

`pkgs/default.nix` is one overlay that auto-discovers every non-`default.nix` `.nix` file under `pkgs/` recursively and exposes it by filename in the nixpkgs namespace.

Each file is a single-package module. If a module's arguments include `mkApp`, the overlay injects the shared macOS app builder. If a same-name override such as `pkgs/mise.nix` needs the upstream package, the overlay injects `prev.mise` to avoid self-recursion. Otherwise it uses normal `callPackage`. `pkgs/mise.nix` deliberately consumes mise's tagged macOS release asset instead of rebuilding the Rust crate from source. Current custom packages include `mise`, `helium-browser`, `brave-browser-nightly`, `bloom`, `slk`, `handy`, `tidewave`, `tidewave-cli`, `chrome-devtools-mcp`, and `cli/whisperkit-cli`; `pkgs.handy` remains exposed as a backport, but active install comes from mise's `brew-cask:handy` to avoid Home Manager source builds.

External overlays and input aliases live separately in `overlays/default.nix`.

## Out-of-store config symlinks

Apps that need live-editable config use out-of-store symlinks into `config/` rather than nix-store copies, so edits apply without a rebuild.

`config/` holds `hammerspoon/`, `nvim/`, `tmux/`, `ghostty/`, `kitty/`, `kanata/`, `espanso/`, and `ssh/`. Program modules under `home/common/programs/<tool>/` own the symlink wiring. Config fragments that need nix-interpolated values are generated into `~/.local/share/...` and sourced from the live config, keeping the editable tree in `config/`.

## Parallel mise migration

Nix/Home Manager and mise coexist during migration. `mise/config/mise/global_config.toml` `[dotfiles]` is mise's ownership map; inspect each mapping before changing a config.

On megabookpro, mise itself is now standalone-owned: the binary is installed by `bootstrap.sh`'s installer path to `~/.local/bin/mise`, `~/.config/mise/config.toml` symlinks to the repo global config, and the former nix `programs.mise` module (with its stub global config) is removed. The nix fish module activates the standalone binary and sets `MISE_DISABLE_TOOLS` for `github:megalithic/helium-macos-releases` and `github:megalithic/shade-next`, which stay nix-owned on that host. Only the pi targets, `~/.config/mise/config.toml`, and the sesame fragment are applied through `mise dotfiles apply <targets>`; the remaining `[dotfiles]` mappings stay nix-owned until their programs migrate. `mise bootstrap launchd apply` is skipped on megabookpro because it has no target filter and the other `com.megadots.*` agents would duplicate nix-run services; the session indexers stay unloaded pending a move to nicknisi's `sessions` tool.

Literal copy twins require recursive diff and deliberate sync on each related change: `config/` and `mise/config/` currently include Hammerspoon, Neovim, tmux, Kitty, and Ghostty. Pi is no longer a twin — `mise/config/pi-coding-agent/` is the sole owner (see [[programs/pi-coding-agent#Pi coding agent]]). The active Nix-side tree remains source of truth for the remaining twins unless a program section records another owner or divergence. [[programs/hammerspoon#Parallel mise configuration|Hammerspoon]] documents its required kanata launchd-label difference.

Generated Nix files and static mise files, including fish, git, SSH/1Password, and other per-file mappings, require behavior parity rather than byte equality. Shared-source mappings, including Kanata, Espanso, and selected SSH paths, link same repository files and must not be copied. Update this policy and program documentation whenever ownership or a divergence changes; run `lat check` after doc changes.

## Mise bootstrap

`bootstrap.sh` keeps mise self-hosted: it installs or updates only
`~/.local/bin/mise` through the standalone installer and `mise self-update`.

Homebrew is still installed for packages used later by mise bootstrap, but it
must not install or upgrade the mise binary. Prepending `~/.local/bin` makes
bootstrap use the standalone binary even when Nix or Homebrew also provides
`mise`.

`bootstrap.sh` has no dry-run mode; bootstrap mutates machine state and should
fail fast instead of carrying preview branches. It lets `mise bootstrap` run
`[tasks.bootstrap]`; the script only handles shell setup and lockfile refresh
afterward. Keep ordered first-run tasks in `mise/config/mise/global_config.toml`,
not duplicated in shell.

## Mise GUI app migration

Mise installs only casks its current bootstrap backend can reproduce; app-only casks belong in `[bootstrap.packages]`, while casks with binary, package, completion, preflight, or privileged artifacts retain explicit handling.

The mise 2026.6.12 audit verified Homebrew casks for every tracked GUI app. Declarative app-only casks cover Discord, Handy, MeetingBar, ColorSnapper, Contexts, Slack, Proton Drive, Proton VPN, Yubico Authenticator, and 1Password. Hammerspoon and Espanso retain real-Brew hooks because their casks ship binaries. Raycast also uses the real-Brew `post-packages` hook: its cask URL ends in an extension-less `download?build=arm` path, and the backend infers archive type from the URL filename (magic-byte sniffing covers only zip), so it mistakes the DMG for a raw binary and fails with `app artifact 'Raycast.app' was not found`. Ghostty, IINA, Inkscape, Obsidian, MailMate, OBS beta, and Kitty have unsupported extra artifacts; Zoom and Okta Verify require package installation, with Okta's privileged postinstall remaining Nix-owned. Brave Nightly needs its Nix Chromium wrapper and flags; Tidewave has no cask; Helium installs as a [[helium#Signed release package|declarative github: backend tool]] (public releases repo, DMG handled by the `install-app.sh` postinstall). Do not replace any special path with `brew-cask:` without re-auditing backend support and matching its activation semantics.

## Rebuild commands

Rebuild recipes keep nix-darwin and Home Manager switches separate while still allowing one full sync path.

`just rebuild` syncs current jj work with remote `main`, then runs `just darwin --skip-sync` and `just home --skip-sync`. `just darwin` owns system changes and uses `sudo darwin-rebuild switch --show-trace -L`. `just home` owns user-level changes, runs `home-manager switch --show-trace -L`, then refreshes Pi packages with `pi update --extensions`.

Both recipes accept `--dry-run` for build-only validation and `--skip-sync` when called from the full flow. `just validate` builds Darwin and Home Manager configs without switching and removes any `result` symlink. `just bootstrap` rebuilds without `just` on `PATH`.

## Repo dev environment (mise)

Devenv is removed from this repo as part of the mise migration; the global mise config and `hk.pkl` replace it.

The removal covers `devenv.nix`, `devenv.yaml`, `devenv.lock`, and the prek/git-hooks.nix shims in `.git/hooks`. The system-wide devenv tool from `home/common/programs/devenv/default.nix` remains for other projects.

The repo-root `mise.toml` that briefly replaced devenv is dissolved into `mise/config/mise/global_config.toml` — the single source of truth for anything mise-related. It carries the `nix:update`, `nix:apply:home`, and `nix:apply:darwin` tasks (megabookpro-only; harmless elsewhere), the git-hook tools (`hk`, `gitleaks`, `shellcheck`), and `npm:lat.md` for the `lat` CLI. Both hosts run this global config; megabookpro's former nix-managed stub is gone. `[env]` secrets sourcing goes through `mise/fragments/env-secrets.sh`, which prefers fnox and falls back to opnix on hosts without a fnox config.

`tk` is vendored at `bin/tk` (on `PATH` via mise `_.path` and the `~/bin` symlinks). Upstream `wedow/ticket` publishes no release assets, and the vendored copy preserves the devenv-base patch that sanitizes the directory basename when deriving ticket ID prefixes — existing `.tickets/dot-*` IDs depend on it.

Git hooks are defined in `hk.pkl` ([hk](https://hk.jdx.dev)) mirroring the old set: check-merge-conflict, detect-private-key, gitleaks (staged-only override), shellcheck at warning severity, and conventional-commit checking on commit-msg. Hooks are configured but not installed; enable with `hk install --global` (git 2.54+) or per-repo `hk install`, bypass with `HK=0 git commit`. Nix linters (deadnix, statix) from the old setup are not yet ported.

Repo-local `.devenv` and `.direnv` plus `.local_scripts/` are ignored. Unused flake inputs should be removed from `flake.lock` after their `flake.nix` references are gone.

## Secrets management

Agenix is retired. Secrets are declared in `home/common/programs/opnix/default.nix` and resolved by the OpNix Home Manager module during activation, backed by 1Password.

The 1Password service account token is the only unmanaged secret input and must stay out of the Nix store. It lives at `${XDG_CONFIG_HOME:-$HOME/.config}/opnix/token` with mode `0600`; `just opnix-token` provisions it. Managed secrets land under `${XDG_CONFIG_HOME:-$HOME/.config}/opnix/secrets/`.

Shell secret loading is shell-specific: zsh uses `programs.zsh.initContent`, bash uses `programs.bash.bashrcExtra`, and fish parses the same files in `programs.fish.interactiveShellInit`.

The staged mise twin is fnox: `mise/config/fnox/config.toml` (linked to `~/.config/fnox/config.toml`) declares the same 1Password-backed secrets and is rendered by `mise/tasks/fnox-render-secrets` into `~/.config/fnox/secrets/env-vars.sh`. Its providers pin `account = "my.1password.com"` so machines also signed into a work 1Password account (workbookpro) still resolve the personal `Crypt` vault; the personal account must be added to that machine's 1Password app with CLI integration enabled. The render task warns and exits 0 when the vault is unreachable so bootstrap continues. The mise toolset includes `github:str4d/age-plugin-yubikey` for YubiKey-backed age decryption and `pipx:yubikey-manager` for the `ykman` PIV diagnostics CLI.

### YubiKey fleet

Three hardware keys, always addressed by explicit serial (`ykman -d <serial>`, `age-plugin-yubikey --serial <serial>`) because multiple keys are routinely connected:

- `15759055` — YubiKey 5C NFC, fw 5.2.7, keychain (USB-C): primary daily-use key, carried on keychain. PIV provisioned (custom PIN/PUK, PIN-protected random management key) and holds the active `fnox-crypt` age identity (slot 1 / retired slot 82, PIN policy never, touch cached).
- `6933956` — YubiKey 4, fw 4.3.7 (USB-A): resident laptop key, pending enrollment as fnox recipient #2. Limits vs the 5 series: no FIDO2 (U2F only, no resident SSH keys, no `ed25519-sk`), OpenPGP card spec 2.1 (RSA only, no ed25519/cv25519), no NFC, TDES-era PIV management key, `ykman piv keys info` unsupported (needs fw 5.3+).
- `15759652` — YubiKey 5C NFC, fw 5.2.7: GUARDED. Its PIV PIN is blocked and the PUK is unknown; `mise/tasks/yubikey-setup` hard-refuses it via `GUARDED_SERIALS`. The `OP_SERVICE_ACCOUNT_TOKEN` blob no longer depends on it (re-encrypted 2026-08-25 to the fleet recipient set), so it can be PIV-reset and re-enrolled as an offline backup mirror whenever convenient.

Application responsibilities are kept separate per key: PIV retired slots hold age-plugin-yubikey identities for fnox bootstrap; OpenPGP holds Git/GPG/SSH subkeys; FIDO2/U2F is for WebAuthn; OATH for TOTP; Yubico OTP is unused. PIN/PUK/management-key values live in 1Password items named by serial (e.g. `yubikey-5c-nfc (15759055)`), never in the repo.

#### Provisioning and replacing a key

Provisioning is serial-safe and repeatable: PIV credentials are set per key with explicit `-d <serial>` commands, then `mise run setup:yubikey -- <serial>` converges identity, stubs, and fnox config.

1. Verify the target: `ykman list` (and `ykman list --serials`); every mutating command below names that serial explicitly.
2. PIV credentials (store each in the key's 1Password item as you go): `ykman -d <serial> piv access change-pin`, `... change-puk`, then `... change-management-key --generate --protect` (random key stored on-device behind the PIN; blank/default is accepted for the current key on a factory-fresh device).
3. `mise run setup:yubikey -- <serial>` — generates a `fnox-crypt` age identity in the first empty retired slot if the key has none (policies via `YK_PIN_POLICY`/`YK_TOUCH_POLICY`, defaults never/cached), writes `mise/config/fnox/yubikey-identity-<serial>.txt`, rebuilds the combined `yubikey-identity.txt` from all per-serial stubs, and appends the recipient to the age provider in `mise/config/fnox/config.toml`.
4. Re-encrypt existing blobs to the grown recipient set: `fnox reencrypt -p age` (needs a connected key that can decrypt the current blob), then verify `fnox get OP_SERVICE_ACCOUNT_TOKEN` and `op whoami`.

The combined `yubikey-identity.txt` (the age provider `key_file`) holds one identity line per fleet member, so decryption works with whichever key is plugged in; the per-serial stubs are the committable records. Losing a key costs nothing cryptographically: any surviving recipient decrypts, and the token itself lives in 1Password (`Shared/(fnox) Service Account Auth Token`) as the final fallback — worst case, mint a new `ops_...` service account (READ on Crypt) and store it with `fnox set -g OP_SERVICE_ACCOUNT_TOKEN --provider age`. Remove a lost key's recipient from the config and re-encrypt to evict it.

#### Yubico OTP interface policy

The factory Yubico OTP credential in slot 1 types `cccc…` one-time passwords into the focused window on accidental touch, so the OTP **USB interface** is disabled on daily-use keys instead of deleting the credential.

Deletion is irreversible — Yubico never re-provisions the factory AES secret — while interface disable preserves the credential. Currently disabled on `15759055` (OTP over NFC remains enabled there). Fully reversible:

- Re-enable: `ykman -d <serial> config usb --enable OTP` (the key reboots; re-run `ykman list` to confirm).
- Repurpose slot 1 later (self-generated Yubico OTP, static password, challenge-response, or HOTP): re-enable the interface, then program with `ykman -d <serial> otp` subcommands (`yubiotp`, `static`, `chalresp`, `hotp`). A new self-generated Yubico OTP credential can be uploaded to YubiCloud at upload.yubico.com; the factory registration cannot be restored once overwritten or deleted.
- Inspect state: `ykman -d <serial> otp info` (slot programmed/empty status only; secrets are never readable).

The OpNix module also derives `LAT_LLM_*` environment for `lat search`, and the Pi wrapper duplicates that derivation so GUI or non-interactive Pi launches still see the same lat provider config. Switching embedding providers changes vector dimensions, so `lat.md/.cache/vectors.db` must be deleted and rebuilt with `lat search --reindex`.

## Git hooks and Nix linting

Git hooks are managed by prek from the generated `.pre-commit-config.yaml`.

Global git tooling ignores `.worktrees/` through `home/common/programs/git/tool-ignore`; global Git excludes also ignore `.worktrees/`, `.worktreeinclude`, and wrapper-generated `.pi-lens.json` in both the nix (`home/common/programs/git/gitignore`) and mise (`mise/config/git/ignore`) config trees. The active hooks check merge conflicts, secrets, Nix dead code and style, shell scripts, formatting, and commit-message convention. The typos hook is disabled in `devenv.nix`, and treefmt is configured so this repo's local formatter choices override imported defaults.

`statix.toml` disables the `repeated_keys` lint because repeated top-level Nix module keys are intentional: related Home Manager and nix-darwin options stay near the context that explains them.

`just scan` is the on-demand security check, separate from the commit hooks. It currently runs `gitleaks detect` over git history and the working tree; the recipe is structured so more checks (PII, dependency, or SAST scans) can be added to the same `just scan` entry over time.

## Agent guidance and task tooling

Agent guidance is centralized in the repo-root `AGENTS.md`. `CLAUDE.md` and directory-local `AGENTS.md` files are intentionally removed so project policy has one durable source.

Nix activation guidance is explicit: run `just darwin` for nix-darwin changes, `just home` for Home Manager changes, and `just rebuild` when both changed or scope is unclear, always monitoring output.

`docs/` is ignored and treated as local or generated reference. Durable design notes belong in `lat.md/`. Ad-hoc research and audit docs go to `~/.local/share/pi/docs/.dotfiles/`, mirroring the handoffs and plans layout. The repo no longer depends on the old file-backed task tracker; agent tooling uses jj/git state plus harness-provided ticket context.

## Global Pi agent policy

`home/common/programs/pi-coding-agent/sources/GLOBAL_AGENTS.md` is the Home Manager source for `~/.pi/agent/AGENTS.md`; `APPEND_SYSTEM.md` is intentionally empty.

The global policy mirrors the structure of the repo-root `AGENTS.md` instead of being a separate mini-policy. It covers preferred tools, writing rules, vision-model subprocesses for images, git conventions, KISS/YAGNI coding, lat.md sync, subagent delegation, ralph-loop, and the local docs/handoffs directories.

Repo-specific nix-darwin and Home Manager rules stay in the repo-root `AGENTS.md`. Keep portable rules global and dotfiles-specific rules local.
