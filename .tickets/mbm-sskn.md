---
id: mbm-sskn
status: closed
deps: 4:1:deps: [, mbm-qkmx]
links: [mbm-77a2, mbm-s5i1, mbm-9ov0]
created: 2026-06-23T16:43:27Z
type: task
priority: 2
assignee: Seth Messer
tags: [mise, migration, dotfiles]
---

# Add missing static tool configs to mise dotfiles

Port remaining Nix-store-backed tool config files to mise dotfiles as committed static files. These are small, single-file configs currently symlinked to the Nix store via Home Manager.

Files to port:

- ~/.config/bat/config (theme: everforest, syntax mapping for ghostty)
- ~/.config/direnv/direnv.toml (whitelist prefix, hide_env_diff, load_dotenv)
- ~/.config/starship.toml (already a static file copied verbatim by Nix — just add as dotfile target)
- ~/.config/karabiner/karabiner.json (already a static file copied verbatim by Nix — just add as dotfile target)
- ~/.config/eza/theme.yml (Nix-store symlink)
- ~/.config/ripgrep/rc (Nix-store symlink)

None of these have Nix interpolation — they are static content.

## Acceptance Criteria

1. All 6 config files are available as committed files under mise/dotfiles/ or mise/fragments/.
2. mise.toml [dotfiles] updated with targets for each file.
3. scripts/mise/dotfile-preflight reports correct classification for each new target.
4. lat_check passes.

## Notes

**2026-06-23T20:12:59Z**

Added 6 static tool configs to mise dotfiles:

1. ~/.config/bat/config → mise/dotfiles/bat/config (everforest theme + ghostty syntax mapping)
2. ~/.config/direnv/direnv.toml → mise/dotfiles/direnv/direnv.toml (whitelist, hide_env_diff, load_dotenv)
3. ~/.config/starship.toml → home/common/programs/starship/starship.toml (already committed, static)
4. ~/.config/karabiner/karabiner.json → home/common/programs/karabiner/karabiner.json (already committed, static)
5. ~/.config/eza/theme.yml → mise/dotfiles/eza/theme.yml (Everforest theme)
6. ~/.config/ripgrep/rc → mise/dotfiles/ripgrep/rc (flags + custom file types)
   All classify as store-flake-source → needs-handling in preflight (correct).
   lat_check passed.
