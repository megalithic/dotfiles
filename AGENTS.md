# Agent Instructions

This is a **nix-darwin + home-manager** managed dotfiles repo.

## Nix-Managed Config Files (CRITICAL)

**Before editing ANY config file outside `~/.dotfiles/`:**

1. Check if it's a symlink: `ls -la <path>`
2. If symlinked to `/nix/store/` → find source in `~/.dotfiles/` and edit there
3. If it doesn't exist but should be managed → add to appropriate nix module
4. Run appropriate rebuild command after Nix changes and monitor output

**Common nix-managed paths:**

- `~/.pi/agent/*` → `home/common/programs/pi-coding-agent/`
- `~/.config/fish/*` → `home/common/programs/fish/`
- `~/.config/ghostty/*` → `config/ghostty/` (out-of-store symlink)
- `~/.config/tmux/*` → `config/tmux/` (out-of-store symlink)
- `~/.config/nvim/*` → `config/nvim/` (out-of-store symlink)
- `~/Applications/Nix/*` → Finder aliases created by `home/common/mac-aliases.nix`
- Most `~/.config/<app>/*` → check `home/common/programs/<app>/` first

**Never:**

- Write directly to symlinked files (will fail or be overwritten)
- Use `brew install` - all packages via Nix
- Edit files in `/nix/store/` (read-only)
- Create `result` symlinks in this repo (default `nix build` behavior)
- Run `nix build` without `--out-link /tmp/<name>` or `-o /tmp/<name>`

### Nix Build Output

**Never create `result` symlinks in this repo.** Use `nix build --no-link` or
`-o /tmp/nix-build-result` and clean up immediately. If `result` appears:
`rm -f ~/.dotfiles/result*`

## Repository Structure

```
~/.dotfiles/
├── flake.nix              # Nix flake: inputs, outputs, host definitions
├── flake.lock             # Pinned dependency versions
├── hosts/                 # Per-host nix-darwin config
│   ├── common.nix         # Shared system settings (minimal packages)
│   ├── megabookpro.nix    # Personal laptop
│   └── workbookpro.nix      # Work laptop
├── home/                  # Home-manager config
│   ├── common/            # Shared across all hosts
│   │   ├── packages.nix   # CLI + GUI packages (nixpkgs + custom)
│   │   ├── mac-aliases.nix # Finder aliases for Spotlight/Launchpad
│   │   ├── services.nix   # User launchd services (omlx, ollama opt-in)
│   │   ├── mas.nix        # Mac App Store apps
│   │   └── programs/      # Per-tool config (fish/, jj/, browsers/, ai/)
│   ├── megabookpro.nix    # Personal overrides
│   └── workbookpro.nix      # Work overrides
├── modules/               # nix-darwin modules
│   ├── system.nix         # Core system settings
│   ├── brew.nix           # Homebrew casks (last resort)
│   └── darwin/
│       └── services.nix   # System launchd services
├── lib/                   # Nix helpers (lib.mega.*)
│   ├── mkDarwinHost.nix   # Darwin system builder
│   ├── mkHome.nix         # Standalone HM builder
│   ├── mkApp.nix          # macOS app builder (DMG/ZIP)
│   └── builders/          # Reusable build utilities
│       ├── mkWrapperApp.nix         # .app wrapper (custom CLI args)
│       └── mkMacOSAlias.nix         # Finder alias module
├── pkgs/                  # Custom package overlay
│   └── default.nix        # Brave Nightly, Fantastical, Bloom, etc.
├── overlays/              # Nixpkgs overlays
├── config/                # Out-of-store app configs (live symlinks)
│   ├── hammerspoon/       # macOS automation (Lua)
│   ├── nvim/              # Neovim config (Lua)
│   ├── tmux/              # Terminal multiplexer
│   └── ghostty/           # Terminal emulator
├── bin/                   # User scripts (symlinked to ~/bin/)
└── docs/                  # Curated architecture docs, skills, agents, commands
```

Directory-specific `AGENTS.md` files are removed; use this root file for repo guidance.

## Parallel mise migration

Nix/Home Manager remains active while mise migration proceeds. Treat `mise/config/mise/global_config.toml` `[dotfiles]` as mise ownership map; inspect its exact source and target before editing either world.

- Literal twins (`config/` and `mise/config/` copies such as Hammerspoon, Neovim, tmux, Kitty, Ghostty, and Pi) require a recursive diff and an intentional sync on every related change. Preserve documented per-world divergences.
- Generated Nix config and static mise config (fish, git, SSH/1Password, and similar) require behavior review, not byte comparison. Keep resulting user behavior equivalent until one owner retires.
- Shared-source mappings (for example Kanata, Espanso, and some SSH paths) already link same repo files. Do not create copies; verify mapping before changing them.
- Record owner, sync direction, and intentional divergence in `lat.md/`. Run `devenv shell -- lat check` after changing those docs.

## Research and audit artifacts

- Ad-hoc agent-generated docs (audits, research, mental-model writeups, investigation reports) live in `~/.local/share/pi/docs/.dotfiles/`, NOT in the repo.
- Pattern mirrors `~/.local/share/pi/handoffs/.dotfiles/` and plans. Filename should be descriptive (e.g., `helium-audit.md`); companion HTML/diagrams sit next to the markdown.
- The in-repo `docs/` directory holds only curated, durable architecture docs and skill/agent/command resources that ship with the repo.
- Promote an ad-hoc doc into `docs/` (or `lat.md/`) only when it becomes durable reference material.

## Package Placement (Where to Add Things)

| What                                | Where                                |
| ----------------------------------- | ------------------------------------ |
| CLI tool from nixpkgs               | `home/common/packages.nix`           |
| GUI app from nixpkgs                | `home/common/packages.nix` (guiPkgs) |
| Custom .app not in nixpkgs          | `pkgs/default.nix` (mkApp)           |
| Tool with HM config (`programs.*`)  | `home/common/programs/<tool>.nix`    |
| Homebrew-only (accessibility, kext) | `modules/brew.nix`                   |
| Mac App Store                       | `home/common/mas.nix`                |
| System service (all hosts)          | `modules/darwin/services.nix`        |
| User service (all hosts)            | `home/common/services.nix`           |

## Nix Module Rules

### File references in nix modules

- **Always use `self` (flake root) for cross-directory file references**
- Never use relative paths like `../../lib/` or `../../../../docs/` — they break
  when modules move
- `self` is available in all modules via `specialArgs`/`extraSpecialArgs`

```nix
# WRONG — fragile, breaks if module moves
src = ../../lib/builders/my-script.swift;
source = ../../../../docs/skills/nix.md;

# CORRECT — deterministic, refactor-proof
src = "${self}/lib/builders/my-script.swift";
source = "${self}/docs/skills/nix.md";
```

### Bootstrap-critical packages

These must be in `hosts/common.nix` `environment.systemPackages` (not just
home-manager), because they're needed before HM runs:

- `just` — runs `just rebuild` / `just home`
- `git` — needed by nix flakes
- `curl`, `vim` — basic system operation

### mkDarwinHost / mkHome parity

Both builders must pass identical `specialArgs`/`extraSpecialArgs`:

- `inputs`, `username`, `hostname`, `version`, `overlays`, `lib`, `paths`,
  `arch`, `self`
- If you add an arg to one, add it to the other

### Activation environment constraints

Home-manager and darwin activation scripts run in restricted environments:

- **Minimal PATH** — `/usr/bin` may not be available via `env`
- **No Aqua domain** — `launchctl managername` returns `Background` in tmux
- **No TTY** — agent/automation contexts don't have a terminal
- **TCC required** — App Management permission needed for app bundle operations

Rules:

- Use absolute shebangs (`#!/usr/bin/swift`) not `#!/usr/bin/env swift` in
  scripts installed for activation
- Test activation from both interactive terminal AND agent/tmux context

### Nix-generated config fragments

For config files that need nix-interpolated values but live in out-of-store
symlinked directories:

1. Generate a fragment file via `xdg.dataFile` (e.g.,
   `~/.local/share/tmux/nix.conf`)
2. Source it from the main config file

Pattern (already used):

- `~/.local/share/hammerspoon/nix_path.lua` — PATH + env vars for Hammerspoon

### Custom app packages (pkgs/default.nix)

When adding a custom `mkApp` package that's managed by a wrapper module (e.g.,
`mkChromiumBrowser`), always set `appLocation = "wrapper"` to prevent the base
package from also being added to `home.packages`:

```nix
brave-browser-nightly = mkApp {
  pname = "brave-browser-nightly";
  appLocation = "wrapper";
  # ...
};
```

### Rebuilding

After touching Nix configuration, run the narrowest activation command that matches the changed files and monitor output until completion:

```bash
just darwin           # nix-darwin only: hosts/, modules/, system settings, brew
just home             # home-manager only: home/, user packages, dotfiles
just rebuild          # both darwin + home, or when unsure which applies (syncs from remote first)
just validate         # build both without switching (catches errors)
just validate darwin  # darwin-only validation
just validate home    # home-manager-only validation
just bootstrap        # emergency: rebuild from scratch without just in PATH
```

Rules:

- Run `just darwin` and monitor output when any nix-darwin config files were touched.
- Run `just home` and monitor output when any home-manager config files were touched.
- Run `just rebuild` and monitor output when both were touched, or when unable to determine the correct narrower command.

### Hammerspoon

**CRITICAL** You must always use `bin/hs-reload` to initiate a Hammerspoon reload. Any other way will crash Hammerspoon.
