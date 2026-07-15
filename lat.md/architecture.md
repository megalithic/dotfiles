# Dotfiles architecture

This repo is a single-flake nix-darwin + Home Manager setup for macOS. One root `flake.nix` produces both `darwinConfigurations` and `homeConfigurations` for two hosts; it does not mirror the two-flake layout some other setups use.

## Flake topology

`flake.nix` pins `nixpkgs-unstable` and makes `home-manager` and `nix-darwin` follow it.

Other inputs include `pi-nix`, `opnix`, `neovim-nightly-overlay`, `devenv`, `hunk`, `nh`, `kanata-darwin`, `yazi`, `nix-homebrew` plus the Homebrew taps, and `brew-nix` for cask and `mas` packaging.

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

Each file is a single-package module. If a module's arguments include `mkApp`, the overlay injects the shared macOS app builder. If a same-name override such as `pkgs/mise.nix` needs the upstream package, the overlay injects `prev.mise` to avoid self-recursion. Otherwise it uses normal `callPackage`. `pkgs/mise.nix` deliberately consumes mise's tagged macOS release asset instead of rebuilding the Rust crate from source. Current custom packages include `mise`, `helium-browser`, `brave-browser-nightly`, `bloom`, `slk`, `handy`, `tidewave`, `tidewave-cli`, `chrome-devtools-mcp`, and `cli/whisperkit-cli`.

External overlays and input aliases live separately in `overlays/default.nix`.

## Out-of-store config symlinks

Apps that need live-editable config use out-of-store symlinks into `config/` rather than nix-store copies, so edits apply without a rebuild.

`config/` holds `hammerspoon/`, `nvim/`, `tmux/`, `ghostty/`, `kitty/`, `kanata/`, `espanso/`, and `ssh/`. Program modules under `home/common/programs/<tool>/` own the symlink wiring. Config fragments that need nix-interpolated values are generated into `~/.local/share/...` and sourced from the live config, keeping the editable tree in `config/`.

## Parallel mise migration

Nix/Home Manager and mise coexist during migration. `_mise.toml` `[dotfiles]` is mise's ownership map; inspect each mapping before changing a config.

Literal copy twins require recursive diff and deliberate sync on each related change: `config/` and `mise/config/` currently include Hammerspoon, Neovim, tmux, Kitty, Ghostty, and Pi. The active Nix-side tree remains source of truth unless a program section records another owner or divergence. [[programs/hammerspoon#Hammerspoon#Parallel mise configuration|Hammerspoon]] documents its required kanata launchd-label difference.

Generated Nix files and static mise files, including fish, git, SSH/1Password, and other per-file mappings, require behavior parity rather than byte equality. Shared-source mappings, including Kanata, Espanso, and selected SSH paths, link same repository files and must not be copied. Update this policy and program documentation whenever ownership or a divergence changes; run `devenv shell -- lat check` after doc changes.

## Mise GUI app migration

Mise installs only casks its current bootstrap backend can reproduce; app-only casks belong in `[bootstrap.packages]`, while casks with binary, package, completion, preflight, or privileged artifacts retain explicit handling.

The mise 2026.6.12 audit verified Homebrew casks for every tracked GUI app. Declarative app-only casks cover Discord, Handy, MeetingBar, ColorSnapper, Contexts, Slack, Proton Drive, Proton VPN, Raycast, Yubico Authenticator, and 1Password. Hammerspoon and Espanso retain real-Brew hooks because their casks ship binaries. Ghostty, IINA, Inkscape, Obsidian, MailMate, OBS beta, and Kitty have unsupported extra artifacts; Zoom and Okta Verify require package installation, with Okta's privileged postinstall remaining Nix-owned. Brave Nightly needs its Nix Chromium wrapper and flags; Tidewave has no cask; Helium must use [[helium#Helium browser|its authenticated private-release installer]]. Do not replace any special path with `brew-cask:` without re-auditing backend support and matching its activation semantics.

## Rebuild commands

Rebuild recipes keep nix-darwin and Home Manager switches separate while still allowing one full sync path.

`just rebuild` syncs current jj work with remote `main`, then runs `just darwin --skip-sync` and `just home --skip-sync`. `just darwin` owns system changes and uses `sudo darwin-rebuild switch --show-trace -L`. `just home` owns user-level changes, runs `home-manager switch --show-trace -L`, then refreshes Pi packages with `pi update --extensions`.

Both recipes accept `--dry-run` for build-only validation and `--skip-sync` when called from the full flow. `just validate` builds Darwin and Home Manager configs without switching and removes any `result` symlink. `just bootstrap` rebuilds without `just` on `PATH`.

## Devenv shell activation

The repo devenv entry uses shell hooks plus direnv support, and generated caches stay ignored.

Home Manager exports `DEVENV_TUI=false` from `home/common/programs/devenv/default.nix` so direnv-triggered `devenv direnv-export` stays non-interactive. The root `.envrc` drives direnv workflows with `eval "$(devenv direnvrc)"` and `use devenv`.

`devenv.yaml` imports the shared `devenv-base` module and pins GitHub-hosted devenv inputs with `git+ssh://git@github.com/...` URLs. This keeps `devenv update`, `devenv shell`, and direnv activation working with the global gitconfig rewrite from `https://github.com/` to SSH, and lets the private `megalithic/devenv-base` repo fetch through normal SSH auth.

Repo-local `.devenv` and `.direnv` plus `.local_scripts/` are ignored. Unused flake inputs should be removed from `flake.lock` after their `flake.nix` references are gone.

## Secrets management

Agenix is retired. Secrets are declared in `home/common/programs/opnix/default.nix` and resolved by the OpNix Home Manager module during activation, backed by 1Password.

The 1Password service account token is the only unmanaged secret input and must stay out of the Nix store. It lives at `${XDG_CONFIG_HOME:-$HOME/.config}/opnix/token` with mode `0600`; `just opnix-token` provisions it. Managed secrets land under `${XDG_CONFIG_HOME:-$HOME/.config}/opnix/secrets/`.

Shell secret loading is shell-specific: zsh uses `programs.zsh.initContent`, bash uses `programs.bash.bashrcExtra`, and fish parses the same files in `programs.fish.interactiveShellInit`.

The OpNix module also derives `LAT_LLM_*` environment for `lat search`, and the Pi wrapper duplicates that derivation so GUI or non-interactive Pi launches still see the same lat provider config. Switching embedding providers changes vector dimensions, so `lat.md/.cache/vectors.db` must be deleted and rebuilt with `lat search --reindex`.

## Git hooks and Nix linting

Git hooks are managed by prek from the generated `.pre-commit-config.yaml`.

Global git tooling ignores `.worktrees/` through `home/common/programs/git/tool-ignore`; global Git excludes also ignore `.worktrees/` and `.worktreeinclude` in both the nix (`home/common/programs/git/gitignore`) and mise (`mise/config/git/ignore`) config trees. The active hooks check merge conflicts, secrets, Nix dead code and style, shell scripts, formatting, and commit-message convention. The typos hook is disabled in `devenv.nix`, and treefmt is configured so this repo's local formatter choices override imported defaults.

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
