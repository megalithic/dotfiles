# Dotfiles architecture

This repo is a single-flake nix-darwin + Home Manager setup for macOS. One root `flake.nix` produces both `darwinConfigurations` and `homeConfigurations` for two hosts; it does not mirror the two-flake layout some other setups use.

## Flake topology

`flake.nix` pins `nixpkgs-unstable` and makes `home-manager` and `nix-darwin` follow it.

Other inputs include `devenv`, `hunk`, `nh`, `kanata-darwin`, `yazi`, `nix-homebrew` plus the Homebrew taps, and `brew-nix` for cask and `mas` packaging (`opnix` removed 2026-08 with the fnox cutover).

Global constants live in the flake `let`: `arch = "aarch64-darwin"`, `version` (Home Manager/system state version), and `username = "seth"`. `lib` is `nixpkgs.lib` extended with `./nix/lib/default.nix`, and `overlays` come from `./nix/overlays`.

Outputs are built by three builders and cover two hosts:

- `darwinConfigurations.megabookpro` and `darwinConfigurations.workbookpro` via `mkDarwin`
- `homeConfigurations."seth@megabookpro"` and `"seth@workbookpro"` via `mkHome`
- `apps.${arch}.default` bootstrap script via `mkInit`

`megabookpro` is the personal laptop and `workbookpro` is the work laptop; per-host overrides live in `nix/hosts/<host>.nix` and `nix/home/<host>.nix`.

## lib.mega and builders

Custom helpers are namespaced under `lib.mega`, added by `lib.extend (import ./nix/lib/default.nix inputs)`. `nix/lib/default.nix` also merges `home-manager.lib` and `nix-darwin.lib` into the extended `lib`.

Builders under `nix/lib/`:

- `mkDarwin.nix` — builds a nix-darwin system; receives `hostname` and `username`, plus shared `inputs`, `lib`, `overlays`, `brew_config`, `version`.
- `mkHome.nix` — builds a standalone Home Manager configuration with matching special args.
- `mkInit.nix` — wraps a bootstrap shell script as the flake's default app.
- `mkApp.nix` (+ `nix/lib/mkApp/extract.nix`) — macOS `.app` builder that extracts DMG/ZIP/PKG into the store and symlinks or copies into `/Applications`.
- `builders/mkChromiumBrowser.nix` and `builders/mkWrapperApp.nix` — `.app` wrappers for Chromium-family browsers and custom-arg app wrappers.
- `paths.nix` — canonical path helpers (`home`, `config`, `localBin`, `dotfiles`, cloud dirs) passed through special args as `paths`.

`mkDarwin` and `mkHome` must pass identical special args (`inputs`, `username`, `hostname`, `version`, `overlays`, `lib`, `paths`, `arch`, `self`). App installation into `/Applications` is driven by `lib.mega.mkAppActivation`, which reads `config.mega.customApps` and also links exposed CLI binaries into `~/.local/bin`, cleaning up orphaned apps and binaries by metadata files under `~/.local/share/nix-apps` and `nix-bins`.

## Custom packages overlay

`nix/pkgs/default.nix` is one overlay that auto-discovers every non-`default.nix` `.nix` file under `nix/pkgs/` recursively and exposes it by filename in the nixpkgs namespace.

Each file is a single-package module. If a module's arguments include `mkApp`, the overlay injects the shared macOS app builder. If a same-name override such as `nix/pkgs/mise.nix` needs the upstream package, the overlay injects `prev.mise` to avoid self-recursion. Otherwise it uses normal `callPackage`. `nix/pkgs/mise.nix` deliberately consumes mise's tagged macOS release asset instead of rebuilding the Rust crate from source. Current custom packages include `mise`, `helium-browser`, `brave-browser-nightly`, `bloom`, `slk`, `handy`, `tidewave`, `tidewave-cli`, `chrome-devtools-mcp`, and `cli/whisperkit-cli`; `pkgs.handy` remains exposed as a backport, but active install comes from mise's `brew-cask:handy` to avoid Home Manager source builds.

External overlays and input aliases live separately in `nix/overlays/default.nix`.

## Out-of-store config symlinks

The legacy `config/` out-of-store tree is retired (2026-08): every app config lives under `config/<tool>/` and is linked by mise `[dotfiles]`.

The last holdouts flipped as follows: kanata's `.kbd` profiles and icons moved to `config/kanata/` (`scripts/mise/setup-kanata` icons fallback repointed too), `~/.ssh/config` became host-specific (`config/ssh/config.<hostname>`, each `Include`-ing `config/ssh/shared.config`; mapped from `config/mise/hosts/*.toml`, not the global `[dotfiles]`), and `~/.iex.exs` links to `home/iex.exs`. Shared SSH config gives both laptops bare-name and `.local` aliases, pins LAN authentication to the 1Password agent's `~/.ssh/id_ed25519.pub`, and accepts newly seen host keys. `home/` is the location for sources symlinked to `~/*` dotfiles; `config/` for `~/.config/*` targets. DevSpace ssh blocks were dropped from the ssh configs (devspace is no longer used). The `linkConfig` helper in `nix/home/common/lib.nix` has no callers. Config fragments that need Nix-interpolated values are generated into `~/.local/share/...` and sourced from the live config.

## Parallel mise migration

Nix/Home Manager and mise coexist during migration. `config/mise/config.toml` `[dotfiles]` is mise's ownership map; inspect each mapping before changing a config.

On megabookpro, mise itself is standalone-owned: the binary is installed by `bootstrap.sh`'s installer path to `~/.local/bin/mise`, `~/.config/mise/config.toml` symlinks to the repo global config, and the former nix `programs.mise` module (with its stub global config) is removed. The nix fish module activates the standalone binary; `MISE_DISABLE_TOOLS` is gone — helium and shade-next install through their mise `github:` tools on both hosts. Stale-env trap: a leftover `MISE_DISABLE_TOOLS` (old shells, tmux server env) silently strips a disabled tool's options — asset_pattern/postinstall vanish and github: `.dmg` installs fail with "No matching asset found"; verify with `mise tool <name>` and purge via `tmux set-environment -gu MISE_DISABLE_TOOLS`. The wave-1 in-place flip (see `~/.local/share/pi/docs/.dotfiles/megabookpro-mise-migration.md`) moved these targets to mise ownership and removed their HM modules: bat, eza, ripgrep, fd, worktrunk, surfingkeys, karabiner, jj, git, ssh signing files (allowed_signers, 1Password agent.toml), shade-next (config + hammerspoon fragment), helium-browser, plus the adopted atuin config and the starship.toml link. The shells wave then completed the flip: the HM starship, fzf, zoxide, and direnv modules are removed; their fish hooks live in `config/fish/conf.d/` (`starship.fish`, `fzf.fish`, `zoxide.fish`, `direnv.fish`). Direnv itself and its config are mise-owned, with no nix-direnv integration. nix-darwin fish is removed (`programs.fish`, `environment.shells`, user shell) and the login shell is `/opt/homebrew/bin/fish` (brew formula from `[bootstrap.packages]`), matching `[bootstrap.user]`. Hammerspoon flipped after wave 1: the HM module is removed, the app comes from a real Homebrew install (`brew install --cask hammerspoon`; the broken nix-homebrew remnant at `/opt/homebrew` was cleaned out and official Homebrew installed to support it), and `~/.config/hammerspoon` plus the `nix_path.lua` fragment are mise `[dotfiles]` targets. Tmux then flipped fully to mise: `[tools]` and `mise.lock` own the binary version, `config/tmux/` owns `~/.config/tmux`, and `[env]` owns its layout and plugin paths. The Home Manager module, package, generated `nix.conf`, legacy `config/tmux/` twin, and Nix package override are removed. Espanso and kitty flipped next: `config/espanso/` is the sole config source (the `config/espanso` out-of-store tree was merged into its identical mise twin), the HM espanso module/agent/pinned package and the `nixpkgs-espanso` flake input are removed, the cask `espanso` app is installed with a staged (unloaded) `dev.mise.com.megadots.espanso` plist from `scripts/mise/espanso-service`, and the nix `com.federicoterzi.espanso` agent keeps running until the next `just home` removes it (then: open Espanso.app once for Gatekeeper, grant Accessibility, load the staged plist). Kitty's HM module and `config/kitty` twin are gone; `brew-cask:kitty` + `config/kitty/` own it. `mise run up` now runs `bootstrap launchd apply` and unscoped `bootstrap dotfiles apply --force` on megabookpro too: the `dev.mise.com.megadots.*` agents (llama-cpp, avwatchd, miccheck) are the live owners and their nix twins (`org.nix-community.home.{llama-cpp,media-presenced}`, plus the HM media-presence module and megabookpro's `programs.llamaCppLocal` enable) are removed — duplicate agents previously fought over the media-presence socket and port 18080. Raycast is fully removed (HM module, post-packages install, `com.raycast.macos` defaults, updater agent) in favor of Tuna; syncthing is removed entirely (2026-08) — declarations, `STCONFDIR`, and `config/syncthing/` are gone; re-add from scratch if ever needed. macOS defaults that both worlds write (KeyRepeat/InitialKeyRepeat, screencapture location) are value-synced between `nix/modules/system.nix` and `[bootstrap.macos.*]` to stop rebuild ping-pong.

Machine updates use public `<verb>:<subject>` tasks declared only in `config/mise/config.toml`; standalone implementations live in `scripts/mise/`, so helper filenames no longer leak through mise task discovery. `up` (alias `dot`) runs `update:tools`, `update:packages`, `update:dotfiles`, `install:fonts`, `update:system`, `update:nvim`, `update:fnox`, `update:pi`, and `reload:hammerspoon` sequentially and stops on the first failure. `update:system` prepares the signed miccheck, notiwatchd, and avwatchd binaries through setup tasks before applying LaunchAgents. `sync:fantastical` and `doctor` stay outside `up`. `scripts/mise/update-machine` sends each phase's combined stdout and stderr directly to the terminal so child tools retain native TTY behavior, prints each exit code, and exits immediately when a phase fails. Tool updates use normal `mise upgrade`; they never use `--bump`.

The `config/`–`config/` copy-twin era is over: the legacy `config/` tree is deleted and `config/<tool>/` directories are sole owners (see [[programs/pi-coding-agent#Pi coding agent]] and [[programs/hammerspoon#Ownership flip from nix]] for the flip pattern). Tuna's app-managed directory follows the same pattern: `~/.config/tuna` links to `config/tuna/`, while mise defaults select that absolute custom folder.

Generated Nix files and static mise files, including fish, git, SSH/1Password, and other per-file mappings, require behavior parity rather than byte equality. Update this policy and program documentation whenever ownership or a divergence changes; run `lat check` after doc changes.

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
afterward. Keep ordered first-run tasks in `config/mise/config.toml`,
not duplicated in shell. macOS defaults set `AppleFnUsageType = 0`, so a
standalone Globe/Fn press does nothing while the held key remains the Fn modifier.
The `update:system` task applies that phase with top-level `mise bootstrap
--only macos-defaults`; the direct defaults subcommand bypasses `post-defaults`
hooks.

## Host-specific mise config

Per-host mise config uses mise's native `MISE_ENV` merge:
`~/.config/mise/config.$MISE_ENV.toml` loads on top of the global config,
with `MISE_ENV` set to the short hostname.

`MISE_ENV` is exported before `mise activate` by fish `conf.d/env.fish`,
`bashrc`, `zshrc` (before their interactive guards), and by `bootstrap.sh`
right after the hostname prompt. The bootstrap-backed `update:packages`,
`update:dotfiles`, and `update:system` tasks derive it from the short hostname
when missing. `clean` and `bin/smoke-test-macos.sh` retain their safety fallback:
stale shells would otherwise run `mise prune` blind to host config and delete
host-scoped tool installs.

Host files live at `config/mise/hosts/{megabookpro,workbookpro}.toml`.
The global `[dotfiles]` table links both onto every machine; only the file
matching `MISE_ENV` is loaded, so unused links are inert.

megabookpro's file owns AirConnect: the `github:philippe44/AirConnect` tool
(release zip carries all-platform binaries; postinstall chmods the macOS
ones; mise kebab-cases the install dir to `github-philippe44-air-connect`)
plus the `com.megadots.airupnp` launchd agent. The agent runs
`scripts/mise/airupnp-launchd`, which execs the `-static` arm64 binary — the
dynamic one dlopens unversioned libcrypto and macOS kills it with SIGABRT —
with `-Z` (no TTY under launchd; interactive mode spins CPU), Sonos latency
`-l 1000:2000`, and `-b <default-route interface>` so it does not bind to
Tailscale's utun. The upstream README's example plist is not used: it pairs
`LaunchOnlyOnce` with `KeepAlive`, which contradict each other.

workbookpro's file is an empty placeholder for work-only tools and agents.

## Mise GUI app migration

Mise 2026.8.14's cask backend handles app, binary, command-wrapper, font, installer, and supported `pkg` artifacts. Direct `[bootstrap.packages]` casks are preferred; real-Brew hooks remain only for verified lifecycle/DSL gaps.

The 2026-08 first-wave re-audit dry-ran IINA, Inkscape, Slack, and OBS beta successfully. Tailscale and Okta Verify now use direct cask package support; Hammerspoon uses direct binary-artifact support. Espanso keeps its verified real-Brew/service chain, and Zoom keeps a real-Brew package hook while its `on_arch_conditional` clean-machine path remains unproven. Tidewave's CLI uses Aqua and its GUI DMG uses a GitHub tool plus `install-app.sh`. Helium uses the same [[helium#Signed release package|declarative github: backend tool]] pattern.

The 2026-08 GUI dedupe wave removed the HM twins on megabookpro: Brave Nightly (mkChromiumBrowser wrapper with managed extensions and flags — dropped, cask `brave-browser@nightly` is sole owner), Ghostty, Discord, MeetingBar, ColorSnapper, Contexts, Obsidian, Proton Drive, Proton VPN, and Yubico Authenticator now exist only as brew casks in `/Applications`; dock pins point there. Raycast is removed entirely (Tuna replaces it).

## Rebuild commands

Rebuild recipes keep nix-darwin and Home Manager switches separate while still allowing one full sync path.

`just rebuild` syncs current jj work with remote `main`, then runs `just darwin --skip-sync` and `just home --skip-sync`. `just darwin` owns system changes and uses `sudo darwin-rebuild switch --show-trace -L`. `just home` owns user-level changes, runs `home-manager switch --show-trace -L`, then refreshes Pi packages with `pi update --extensions`.

Both recipes accept `--dry-run` for build-only validation and `--skip-sync` when called from the full flow. `just validate` builds Darwin and Home Manager configs without switching and removes any `result` symlink. `just bootstrap` rebuilds without `just` on `PATH`.

## Repo dev environment (mise)

Devenv is removed from this repo as part of the mise migration; the global mise config and `hk.pkl` replace it.

The removal covers `devenv.nix`, `devenv.yaml`, `devenv.lock`, and the git-hooks.nix shims in `.git/hooks`. The system-wide devenv tool from `nix/home/common/programs/devenv/default.nix` remains for other projects.

The repo-root `mise.toml` that briefly replaced devenv is dissolved into `config/mise/config.toml` — the single source of truth for anything mise-related. It carries the git-hook tools (`hk`, `gitleaks`, `shellcheck`) and `npm:lat.md` for the `lat` CLI; the former `nix:*` tasks are removed — nix apply/update goes through `just` (`just home`, `just darwin`, `just update-flake`) on megabookpro. Both hosts run this global config; megabookpro's former nix-managed stub is gone. `[env]` secrets sourcing goes through `mise/fragments/env-secrets.sh`, which prefers fnox and falls back to opnix on hosts without a fnox config.

`tk` is vendored at `bin/tk` (on `PATH` via mise `_.path` and the `~/bin` symlinks). Upstream `wedow/ticket` publishes no release assets, and the vendored copy preserves the devenv-base patch that sanitizes the directory basename when deriving ticket ID prefixes — existing `.tickets/dot-*` IDs depend on it.

Git hooks are defined in `hk.pkl` ([hk](https://hk.jdx.dev)) mirroring the old set: check-merge-conflict, detect-private-key, gitleaks (staged-only override), shellcheck at warning severity, and conventional-commit checking on commit-msg. Hooks are configured but not installed; enable with `hk install --global` (git 2.54+) or per-repo `hk install`, bypass with `HK=0 git commit`. Nix linters (deadnix, statix) from the old setup are not yet ported.

Repo-local `.devenv` and `.direnv` plus `.local_scripts/` are ignored. Unused flake inputs should be removed from `flake.lock` after their `flake.nix` references are gone. Flake updates are manual via `just update-flake`; no scheduled GitHub workflow updates `flake.lock`.

## Secrets management

Agenix and OpNix are both retired; fnox (mise) is the sole secret loader on megabookpro since 2026-08.

The former Nix secret module, its `nix/lib/mkHome.nix` import, and its flake input are removed. No tracked script or config reads its state; the former local state under `~/.config/opnix/` was deleted in 2026-08.

Shell secret loading is mise-owned: interactive fish/bash/zsh load fnox secrets through `fnox activate` in their mise-managed shell configs.

On both hosts, `config/fnox/shared.toml` is the committed source of truth: it declares exported environment variables (plus on-demand `env = false` entries) as individual 1Password field references and enables fnox's memory-only daemon cache. The only public fnox task, `mise run update:fnox`, idempotently creates the mode-0600 per-machine software age key at `~/.config/fnox/age-cache-key.txt`, verifies 1Password access, builds a staged global config from the shared body, appends the `agecache` provider, syncs every onepass-backed secret, and verifies every declaration received an encrypted `sync` entry. Source, sync, verification, and artifact-rendering failures leave the active cache unchanged. The task renders dependent artifacts from the staged config, clears the fnox daemon cache, then activates config and changed artifacts with rollback backups. Fnox prefers the encrypted sync cache, so shells and `fnox exec` launchers work offline with no 1Password round-trips until the next sync. `mise run up` invokes `update:fnox` once explicitly; full machine bootstrap invokes it once through the post-tools hook. The providers pin `account = "my.1password.com"` so machines also signed into a work 1Password account still resolve the personal `Crypt` vault. Non-shell Pi and capper launches enter through `fnox exec --replace`; interactive fish, bash, and zsh load secrets through `fnox activate` in their mise-managed shell configs. Prompt hooks detect the replaced global config and refresh the current shell on its next prompt; the child mise task cannot directly mutate its parent shell. `~/.s3cfg` is a mise-managed symlink to the mode-0600 artifact at `~/.local/share/fnox/generated/s3cfg`; `scripts/mise/render-s3cfg`, run automatically at the end of `mise run update:fnox`, renders it from the sanitized `config/s3cmd/s3cfg.template` using three cached `fnox get` lookups. The mise toolset includes `github:str4d/age-plugin-yubikey` for YubiKey-backed age decryption, `pipx:yubikey-manager` for the `ykman` PIV diagnostics CLI, and `pipx:s3cmd` for capper uploads.

### YubiKey fleet

Three hardware keys, always addressed by explicit serial (`ykman -d <serial>`, `age-plugin-yubikey --serial <serial>`) because multiple keys are routinely connected:

- `15759055` — YubiKey 5C NFC, fw 5.2.7, keychain (USB-C): primary daily-use key, carried on keychain. PIV provisioned (custom PIN/PUK, PIN-protected random management key) and holds the active `fnox-crypt` age identity (slot 1 / retired slot 82, PIN policy never, touch cached).
- `6933956` — YubiKey 4, fw 4.3.7 (USB-A): resident laptop key, pending enrollment as fnox recipient #2. Limits vs the 5 series: no FIDO2 (U2F only, no resident SSH keys, no `ed25519-sk`), OpenPGP card spec 2.1 (RSA only, no ed25519/cv25519), no NFC, TDES-era PIV management key, `ykman piv keys info` unsupported (needs fw 5.3+).
- `15759652` — YubiKey 5C NFC, fw 5.2.7: GUARDED. Its PIV PIN is blocked and the PUK is unknown; `scripts/mise/setup-yubikey` hard-refuses it via `GUARDED_SERIALS`. The `OP_SERVICE_ACCOUNT_TOKEN` blob no longer depends on it (re-encrypted 2026-08-25 to the fleet recipient set), so it can be PIV-reset and re-enrolled as an offline backup mirror whenever convenient.

Application responsibilities are kept separate per key: PIV retired slots hold age-plugin-yubikey identities for fnox bootstrap; OpenPGP holds Git/GPG/SSH subkeys; FIDO2/U2F is for WebAuthn; OATH for TOTP; Yubico OTP is unused. PIN/PUK/management-key values live in 1Password items named by serial (e.g. `yubikey-5c-nfc (15759055)`), never in the repo.

#### Provisioning and replacing a key

Provisioning is serial-safe and repeatable: PIV credentials are set per key with explicit `-d <serial>` commands, then `mise run setup:yubikey -- <serial>` converges identity, stubs, and fnox config.

1. Verify the target: `ykman list` (and `ykman list --serials`); every mutating command below names that serial explicitly.
2. PIV credentials (store each in the key's 1Password item as you go): `ykman -d <serial> piv access change-pin`, `... change-puk`, then `... change-management-key --generate --protect` (random key stored on-device behind the PIN; blank/default is accepted for the current key on a factory-fresh device).
3. `mise run setup:yubikey -- <serial>` — generates a `fnox-crypt` age identity in the first empty retired slot if the key has none (policies via `YK_PIN_POLICY`/`YK_TOUCH_POLICY`, defaults never/cached), writes `config/fnox/yubikey-identity-<serial>.txt`, rebuilds the combined `yubikey-identity.txt` from all per-serial stubs, and appends the recipient to the age provider in `config/fnox/shared.toml`.
4. Re-encrypt existing blobs to the grown recipient set: `fnox reencrypt -p age` (needs a connected key that can decrypt the current blob), then verify `fnox get OP_SERVICE_ACCOUNT_TOKEN` and `op whoami`.

The combined `yubikey-identity.txt` (the age provider `key_file`) holds one identity line per fleet member, so decryption works with whichever key is plugged in; the per-serial stubs are the committable records. Losing a key costs nothing cryptographically: any surviving recipient decrypts, and the token itself lives in 1Password (`Shared/(fnox) Service Account Auth Token`) as the final fallback — worst case, mint a new `ops_...` service account (READ on Crypt) and store it with `fnox set -g OP_SERVICE_ACCOUNT_TOKEN --provider age`. Remove a lost key's recipient from the config and re-encrypt to evict it.

#### Yubico OTP interface policy

The factory Yubico OTP credential in slot 1 types `cccc…` one-time passwords into the focused window on accidental touch, so the OTP **USB interface** is disabled on daily-use keys instead of deleting the credential.

Deletion is irreversible — Yubico never re-provisions the factory AES secret — while interface disable preserves the credential. Currently disabled on `15759055` (OTP over NFC remains enabled there). Fully reversible:

- Re-enable: `ykman -d <serial> config usb --enable OTP` (the key reboots; re-run `ykman list` to confirm).
- Repurpose slot 1 later (self-generated Yubico OTP, static password, challenge-response, or HOTP): re-enable the interface, then program with `ykman -d <serial> otp` subcommands (`yubiotp`, `static`, `chalresp`, `hotp`). A new self-generated Yubico OTP credential can be uploaded to YubiCloud at upload.yubico.com; the factory registration cannot be restored once overwritten or deleted.
- Inspect state: `ykman -d <serial> otp info` (slot programmed/empty status only; secrets are never readable).

LAT's active embedding backend is temporarily the bundled offline MiniLM model (`local:minilm-l6-v2`, 384 dimensions): the index was rebuilt with `lat reindex` run with every `LAT_LLM_*` variable unset, which records a durable per-repo local preference that wins even when the ambient Synthetic `LAT_LLM_*` environment is present. Fnox still exports that Synthetic-pointed `LAT_LLM_*` environment. The local llama.cpp router remains ready and verified — it serves `nomic-embed` through OpenAI-compatible `/v1/embeddings` with 768-dimensional output — but released `lat.md` 0.12.2 cannot select a custom endpoint, so the final Nomic cutover is blocked on upstream PR [vercel-labs/lat.md#70](https://github.com/vercel-labs/lat.md/pull/70) landing in a release. After that release, switch LAT to the local endpoint and run `lat reindex` again (dimensions change 384 → 768, so a full rebuild is required).

## Git hooks and Nix linting

Git hooks are defined in `hk.pkl` via hk (see "Repo dev environment (mise)" above).

Global git tooling ignores `.worktrees/` through `config/git/tool-ignore` (linked to `~/.ignore`); global Git excludes also ignore `.worktrees/`, `.worktreeinclude`, and wrapper-generated `.pi-lens.json` via `config/git/ignore` — the sole owner since the wave-1 flip removed the nix git module. The active hooks check merge conflicts, secrets, Nix dead code and style, shell scripts, formatting, and commit-message convention. The typos hook is disabled in `devenv.nix`, and treefmt is configured so this repo's local formatter choices override imported defaults.

`statix.toml` disables the `repeated_keys` lint because repeated top-level Nix module keys are intentional: related Home Manager and nix-darwin options stay near the context that explains them.

`just scan` is the on-demand security check, separate from the commit hooks. It currently runs `gitleaks detect` over git history and the working tree; the recipe is structured so more checks (PII, dependency, or SAST scans) can be added to the same `just scan` entry over time.

## Agent guidance and task tooling

Agent guidance is centralized in the repo-root `AGENTS.md`. `CLAUDE.md` and directory-local `AGENTS.md` files are intentionally removed so project policy has one durable source.

Nix activation guidance is explicit: run `just darwin` for nix-darwin changes, `just home` for Home Manager changes, and `just rebuild` when both changed or scope is unclear, always monitoring output.

`docs/` is ignored and treated as local or generated reference. Durable design notes belong in `lat.md/`. Ad-hoc research and audit docs go to `~/.local/share/pi/docs/.dotfiles/`, mirroring the handoffs and plans layout. The repo no longer depends on the old file-backed task tracker; agent tooling uses jj/git state plus harness-provided ticket context.

## Global Pi agent policy

`config/pi-coding-agent/agent/AGENTS.md` is the mise `[dotfiles]` source for `~/.pi/agent/AGENTS.md`; Pi's system additions live in the adjacent `SYSTEM.md`. No `APPEND_SYSTEM.md` is managed.

The global policy mirrors the structure of the repo-root `AGENTS.md` instead of being a separate mini-policy. It covers preferred tools, writing rules, vision-model subprocesses for images, git conventions, KISS/YAGNI coding, lat.md sync, subagent delegation, ralph-loop, and the local docs/handoffs directories.

Repo-specific nix-darwin and Home Manager rules stay in the repo-root `AGENTS.md`. Keep portable rules global and dotfiles-specific rules local.
