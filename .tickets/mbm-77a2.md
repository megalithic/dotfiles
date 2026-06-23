---
id: mbm-77a2
status: closed
deps: 4:1:deps: 4:1:deps: [, mbm-8afn, mbm-b597]
links: [mbm-sskn, mbm-s5i1, mbm-9ov0]
created: 2026-06-23T16:43:19Z
type: feature
priority: 1
assignee: Seth Messer
tags: [mise, migration, fish]
---

# Port Nix-generated fish config to static mise dotfiles

Port all Home Manager-generated fish shell configuration to committed static files under mise/dotfiles/fish/. Current mise/dotfiles/fish/ is ~25 lines; HM generates 279-line config.fish + 20 functions + 3 plugins + keybindings + theme + completions.

Files to port:

- config.fish: shell init, PATH, PLUG_EDITOR, TMUX_SESSION, completions, keybindings, theme, ghostty integration, HM session vars (replaced with fnox/mise equivalents)
- conf.d/plugin-autopair.fish, plugin-done.fish, plugin-nix-env.fish (nix-env plugin may be retired)
- conf.d/devenv-tasks-run.fish
- functions/\*.fish (jj, fzf widgets, git-worktree, helium, nix-shell, ask, bind_bang, bind_dollar, fish_greeting, pr, sz, yy, etc.)

All content is static — no Nix interpolation needed. PATH references switch from Nix store to Brew/MAS paths. Secret loading switches from opnix to fnox.

## Acceptance Criteria

1. mise/dotfiles/fish/config.fish contains all shell init, PATH, PLUG_EDITOR, TMUX_SESSION, and keybindings from the HM-generated version.
2. mise/dotfiles/fish/conf.d/ contains all plugin and integration files (autopair, done, devenv-tasks-run). nix-env plugin may be intentionally removed.
3. mise/dotfiles/fish/functions/ contains all 20 fish functions (jj, fzf widgets, git-worktree, helium, etc.).
4. mise/dotfiles/fish/completions/ contains generated completions (jj, mix, git-worktree, etc.).
5. Theme file is committed under mise/dotfiles/fish/conf.d/ or mise/dotfiles/fish/theme.fish.
6. Ghostty shell integration is resolved (either via Brew ghostty or committed snippet).
7. Secret/env loading is wired to fnox (or documented as deferred to mbm-b597).
8. mise bootstrap --dry-run notes fish as expected conflict requiring --force-dotfiles after backup.
9. lat_check passes.

## Notes

**2026-06-23T17:43:21Z**

Ported all Nix-generated fish config to static mise/dotfiles/fish/:

1. config.fish (8.0KB) — complete port of HM's 279-line generated config: shell init, PATH (Brew paths), jj/mix/git-worktree completions, env vars, PLUG_EDITOR, TMUX_SESSION, abbreviations, aliases, fzf integration, keybindings (ctrl-a/e/y/v/s/c/d/b/o, bang shortcuts), Everforest theme, Ghostty integration (Brew cask path), zoxide/starship/mise/direnv init, conf.d sourcing.
2. 20 fish functions — all ported: \_\_git_worktree_names, \_fzf_preview_file, \_prompt_move_to_bottom, \_prompt_reset_mouse, ask, bind_bang, bind_dollar, fish_greeting, fzf-dir-widget, fzf-jj-bookmarks, git-worktree-cd/new/pr/prune, helium, jj, nix-shell, pr, sz (simplified — no HM session vars), yy.
3. 5 conf.d files: devenv-tasks-run, fnox (secret loading from mbm-b597), mise (mise+fnox activation), plugin-autopair, plugin-done.
4. nix-env plugin intentionally removed (no Nix shell management).
5. Nix store paths replaced with Brew/MAS equivalents (eza, trash, fzf, starship, ghostty, etc.).
6. OpNix secret paths replaced with fnox paths.
7. Fish syntax validated (fish -n passes).
8. Preflight: fish shows as real-directory (expected — requires --force-dotfiles after backup).
   lat_check passed.
