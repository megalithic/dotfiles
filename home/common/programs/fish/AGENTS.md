# Fish Shell Configuration

## Structure

```
fish/
├── default.nix      # Main config, imports all modules
├── aliases.nix      # Shell aliases (ls, cat, rm, etc.)
├── abbr.nix         # Abbreviations (vim→nvim, j→just)
├── functions.nix    # Fish functions (pr, nix-shell wrapper, fzf widgets)
├── plugins.nix      # Fish plugins (autopair, nix-env, done)
├── completions.nix  # Custom completions (jj bookmarks, mix tasks)
├── keybindings.nix  # Keybindings (ctrl-a/e, fzf widgets, bang shortcuts)
├── theme.nix        # Everforest color scheme
└── AGENTS.md        # This file
```

## Module pattern

Each `.nix` file is a pure function or expression:

```nix
# aliases.nix - function taking dependencies
{ pkgs, isDarwin }:
{
  ls = "${pkgs.eza}/bin/eza ...";
  copy = if isDarwin then "pbcopy" else "xclip";
}

# abbr.nix - pure attribute set (no deps)
{
  vim = "nvim -O";
  j = "just";
}

# completions.nix - string (shellInit content)
''
  complete -c jj -n "..." -xa "..."
''
```

## Key behaviors

- **Prompt at bottom**: `_prompt_move_to_bottom` keeps prompt at terminal bottom
- **Notifications**: Uses `ntfy` for fish-done plugin (not terminal-notifier)
- **nix-shell wrapper**: Auto-runs fish inside nix-shell
- **FZF widgets**: ctrl-d (dirs), ctrl-b (jj bookmarks), ctrl-o (vim files)

## Adding new content

| Type | File | Format |
|------|------|--------|
| Alias | `aliases.nix` | `name = "command";` |
| Abbreviation | `abbr.nix` | `name = "expansion";` |
| Function | `functions.nix` | `name = "body";` or `name = { onEvent; body; };` |
| Plugin | `plugins.nix` | `{ name; src; }` |
| Completion | `completions.nix` | Append to string |
| Keybinding | `keybindings.nix` | Append to string |
| Theme color | `theme.nix` | Append to string |

## Platform handling

Use `isDarwin` flag (passed from default.nix):

```nix
copy = if isDarwin then "pbcopy" else "xclip -selection clipboard";
```
