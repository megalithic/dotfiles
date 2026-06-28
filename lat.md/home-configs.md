# Home Manager configuration

This file covers the user-level layer: how program modules are discovered, package and app composition, per-tool config conventions, and an index of the tools managed under `home/common/programs/`. Apply with `just home`.

## Module auto-import

`home/common/default.nix` auto-imports every `home/common/programs/<tool>/` directory that contains a `default.nix`, so the layout stays one directory per tool instead of a hand-maintained import list.

The auto-import filters by directory shape and gates optional modules: `worktrunk` imports only when `inputs ? worktrunk`; when enabled, `home/common/default.nix` also imports `inputs.worktrunk.homeModules.default` before the local `home/common/programs/worktrunk/` config so the `programs.worktrunk` option exists. Alongside the program modules it imports `lib.nix`, `modules/settings-sync.nix`, `packages.nix`, `services.nix`, and `accounts.nix`. `mkHome` imports `inputs.pi-nix.homeModules.default` so `programs.pi.coding-agent` can manage the wrapped Pi package declaratively.

`home/common/default.nix` also sets `home.sessionPath`, session variables, the `~/bin` link, an `.editorconfig`, and out-of-store symlinks for iCloud and Proton drives. It enables `targets.darwin.copyApps` (not `linkApps`) so GUI apps work with Spotlight, and runs `lib.mega.mkAppActivation` over `config.mega.customApps`.

## Package and app composition

Home Manager package composition avoids direct `pkgs.poppler` plus `pkgs."poppler-utils"` installs; PDF CLI tools come from `poppler-utils`.

Hunk is installed from the `hunk` flake input (`inputs.hunk.packages.${pkgs.stdenv.hostPlatform.system}.hunk`) rather than nixpkgs.

GUI `.app` packages built through `mkApp` register in `config.mega.customApps`, and `mkAppActivation` copies or symlinks them into `/Applications` and links any exposed CLI binaries into `~/.local/bin`. Custom `mkApp` packages managed by a wrapper module should set `appLocation = "wrapper"` so the base package is not also added to `home.packages`.

Local inference uses llama.cpp, not Ollama. `home/common/programs/llama-cpp-local/` owns the service, options, and model directory activation; `home/common/programs/ollama/` stays an inert compatibility module. `bin/llm-pull` defaults to the `llamacpp` backend and creates GGUF alias symlinks (`qwen3.6.gguf`, `deepseek14b.gguf`, `gemma4.gguf`) so `llama-server --models-dir` exposes the IDs Pi expects.

## Per-tool config conventions

Tool-specific dotfiles and XDG links live beside their owning Home Manager module rather than in a central config block.

Examples: git files under `home/common/programs/git/`, ripgrep config under `ripgrep/`, Yazi plugins under `yazi/`. Apps that need live-editable config use out-of-store symlinks into the repo `config/` tree (see [[architecture#Out-of-store config symlinks]]). VS Code is not installed; Neovim is the editor path.

## Fish shell helpers

Fish carries repo workflow helpers and desktop integration environment variables.

Fish config is kept as portable fish files under `home/common/programs/fish/`: `config.fish`, `conf.d/*.fish`, `functions/*.fish`, and `interactive/*.fish`. Home Manager installs these files and only generates `~/.local/share/fish/nix.fish` for Nix-specific PATH setup.

Fish fzf Ctrl-T uses fzf's fish token parser, so the current path token becomes `$dir` and the Home Manager fzf `fileWidgetCommand` passes `$dir` as fd's explicit search path. Fish defines a `jj` wrapper that runs real `jj` inside jj repos, allows `jj git init`, and falls back to `git` with a hint in plain git repos. `PLUG_EDITOR` is exported as a `hammerspoon://nvim-open` URL so stack-trace links delegate final Neovim target resolution to Hammerspoon.

Fish owns the Worktrunk integration locally instead of upstream's `wt config shell init fish` (which is disabled via `programs.worktrunk.enableFishIntegration = false`; bash/zsh stay on upstream). The local `wt` function in `functions/wt.fish` resolves the real binary from `WORKTRUNK_BIN` or `command -s wt` so it never hard-codes a Nix store path, and vendors upstream directive handling: it creates `WORKTRUNK_DIRECTIVE_CD_FILE` and `WORKTRUNK_DIRECTIVE_EXEC_FILE`, sets `WORKTRUNK_SHELL=fish`, then runs `cd` and `eval` on the directives so parent-shell cwd and `--execute` still work. On top of that it adds two local behaviors: implicit switch (`wt @` / `wt some-branch` become `wt switch …`, while known built-ins and `--help`/`--version` stay pass-through) and tmux targets (`-t/--target window|session`, parseable before `--` and in any position). Target mode forces `switch --no-cd --format=json`, parses `branch`/`path` from the JSON, and hands navigation to `bin/wt-tmux-target` so the calling shell's cwd never changes. `home/common/programs/worktrunk/default.nix` writes `~/.config/worktrunk/config.toml` with `worktree-path = "{{ repo_path }}/.worktrees/{{ branch | sanitize }}"`, keeping new worktrees under the repo. Completions in `interactive/completions.fish` resolve the real `wt` binary the same way and suggest worktree branches for explicit (`wt switch <TAB>`) and implicit (`wt <TAB>`) switch, plus `window`/`session` for `-t/--target`. Ghostty fish integration is not sourced here; Ghostty handles it itself.

## User bin scripts

User scripts in `bin/` provide repo workflow shortcuts that are linked into `~/bin` by Home Manager.

The `m` script wraps common Mix/Phoenix commands. Its `m s` Phoenix server command always starts a named IEx node: an explicit argument is used as-is; without an argument, the name is derived from the current directory basename, or from the main checkout basename plus linked-worktree directory basename when inside a Git worktree. Derived names are lowercased and use dashes unless the source name already uses underscores.

Two scripts back the fish `wt` wrapper's tmux target mode. `wt-tmux-target --target window|session --branch <branch> --path <path>` derives a sanitized tmux name (non-`[A-Za-z0-9_.-]` collapsed to `-`, short `cksum` hash appended when sanitization changed the name). Session target creates or reuses a per-worktree session rooted at the worktree with `code` and `services` windows (idempotent — never duplicates windows or kills panes), switching the client inside tmux or attaching outside it. Window target creates or reuses a single current-session window inside tmux and degrades to session behavior outside tmux. `wt-tail-logs [branch]` feeds the `services` window: it polls `wt config state logs --format=json`, filters `.hook_output[]` by branch and `post-start`/`post-switch` hook, tails the discovered paths with `tail -F` (paths come from JSON metadata, never guessed), and prints a waiting message with retry when no logs exist yet. It only tails logs; it never starts services.

## Tmux layouts

Tmux layout scripts are Bash-compatible session builders discovered by `ftm` from `TMUX_LAYOUTS`.

Scripts use `.sh` names and `#!/usr/bin/env bash` so they run through bash regardless of the interactive shell. Fixed canonical layouts set explicit roots: `mega` in `/Users/seth/.dotfiles`, `rx` in `/Users/seth/code/work/strive/rx`, and `verify-doctor` in `/Users/seth/code/work/strive/verify-doctor`. Generic layouts may resolve through zoxide and fall back to `$HOME/code`.

## Notable program docs

A handful of programs have enough intricacy to warrant their own files instead of a one-line index row:

- [[pi-coding-agent]] — Pi packaging, wrapper, runtime settings, extensions, and the `pi-acp` adapter.
- [[neovim-pinvim]] — Neovim nightly notes plus the pinvim registry, editor-service RPC, context delivery, and peer repair.
- [[helium]] — declarative Darwin build with Widevine, custom re-signing for 1Password pairing, rsync install, and Hammerspoon launch path.
- [[hammerspoon]] — shade-next panel, `wm.lua` window management, miccheck menubar, and the `bin/hs-reload` rule.
- [[ghostty]] — module-vs-raw-config split and bell-driven Pi notifications.

## Config index

Tools managed under `home/common/programs/`, one line each. Tools with their own notable doc are linked above.

| Tool                                    | What it manages                                                                                                                               |
| --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| aerc / mailmate                         | mail clients                                                                                                                                  |
| bash / fish                             | shells; fish is default and carries repo helpers                                                                                              |
| bat                                     | cat replacement                                                                                                                               |
| brave-browser-nightly                   | Chromium browser wrapper app                                                                                                                  |
| claude-code                             | parked until its old dependency is restored                                                                                                   |
| codex                                   | OpenAI Codex CLI via `programs.codex`                                                                                                         |
| colorsnapper / contexts                 | macOS GUI utilities from brew-nix casks                                                                                                       |
| csvlens                                 | CSV terminal viewer                                                                                                                           |
| desktoppr                               | wallpaper activation                                                                                                                          |
| devenv                                  | devenv integration; exports `DEVENV_TUI=false`                                                                                                |
| direnv                                  | direnv + nix-direnv                                                                                                                           |
| discord                                 | chat app                                                                                                                                      |
| espanso                                 | text expander (config in `config/espanso/`)                                                                                                   |
| eza                                     | ls replacement                                                                                                                                |
| fd                                      | find replacement                                                                                                                              |
| firefox                                 | browser                                                                                                                                       |
| fzf                                     | fuzzy finder                                                                                                                                  |
| ghostty                                 | terminal emulator — see [[ghostty]]                                                                                                           |
| git                                     | git, signing, gitignore/tool-ignore; `git wt` forwards to Worktrunk `wt`                                                                      |
| hammerspoon                             | macOS automation — see [[hammerspoon]]                                                                                                        |
| handy                                   | macOS app (local nixpkgs backport)                                                                                                            |
| helium-browser                          | primary browser — see [[helium]]                                                                                                              |
| htop / k9s                              | process and Kubernetes TUIs                                                                                                                   |
| jj                                      | Jujutsu VCS                                                                                                                                   |
| jq                                      | JSON processor                                                                                                                                |
| kanata / karabiner                      | keyboard remapping                                                                                                                            |
| khard / notmuch / mbsync / msmtp / tiny | mail/contacts stack                                                                                                                           |
| kitty                                   | terminal emulator (config in `config/kitty/`)                                                                                                 |
| llama-cpp-local                         | local inference service and models                                                                                                            |
| man                                     | manpage config                                                                                                                                |
| meetingbar                              | calendar menu bar app                                                                                                                         |
| mise                                    | tool version manager; local override uses tagged macOS binary asset                                                                           |
| neomd                                   | markdown tooling                                                                                                                              |
| nh                                      | nix helper                                                                                                                                    |
| nvim                                    | editor — see [[neovim-pinvim]]                                                                                                                |
| obsidian                                | notes vault activation                                                                                                                        |
| ollama                                  | inert compatibility module (local inference uses llama.cpp)                                                                                   |
| opnix                                   | 1Password-backed secrets — see [[architecture#Secrets management]]                                                                            |
| pi-coding-agent                         | Pi CLI and extensions — see [[pi-coding-agent]]                                                                                               |
| process-compose                         | process orchestration                                                                                                                         |
| proton-drive                            | Proton Drive GUI app from brew-nix cask                                                                                                       |
| ripgrep                                 | search tool                                                                                                                                   |
| rust                                    | rustup + bacon toolchain                                                                                                                      |
| shade / shade-next                      | Hammerspoon launcher panels — see [[hammerspoon]]                                                                                             |
| slk                                     | Slack CLI (upstream static tarball package)                                                                                                   |
| ssh                                     | SSH config (1Password agent provides keys)                                                                                                    |
| starship                                | shell prompt; git modules use `git rev-parse` guards so `.git` file worktrees render                                                          |
| surfingkeys                             | browser keyboard nav (enabled on Tidewave)                                                                                                    |
| television                              | fuzzy TUI                                                                                                                                     |
| tmux                                    | terminal multiplexer; layouts via `ftm`                                                                                                       |
| worktrunk                               | worktree manager (cached `pkgs.worktrunk`); fish integration owned locally — see Fish shell helpers, `bin/wt-tmux-target`, `bin/wt-tail-logs` |
| yazi                                    | file manager + plugins                                                                                                                        |
| yubico-authenticator                    | Yubico Authenticator GUI app from brew-nix cask                                                                                               |
| zoxide                                  | directory jumper                                                                                                                              |
