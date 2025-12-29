# Terminal Mouse Tracking Escape Sequence Leak

## Problem Description

When using TUI applications like Claude Code (or OpenCode) inside Ghostty + tmux,
trackball/mouse movements can appear as garbage characters in the terminal:

```
[<35;94;34M[<35;93;34M[<35;92;34M[<35;91;34M...
```

This happens during and after Claude Code sessions, particularly noticeable with
high-frequency input devices like the Ploopy Adept trackball.

### Related Issues

- https://github.com/anthropics/claude-code/issues/1509

## Root Cause

### What These Sequences Mean

The sequences are **SGR extended mouse mode** (mode 1006) escape sequences:

```
CSI < Cb ; Cx ; Cy M
\e[ <  35 ; 94 ; 34 M
```

- `\e[<` — CSI + SGR mouse mode indicator
- `35` — Button code: 32 (motion) + 3 (no button) = mouse move event
- `94` — Column position
- `34` — Row position
- `M` — Button press (`m` = release)

### The Leak Chain

1. **TUI app enables mouse tracking** — Claude Code sends:
   ```
   \e[?1003h  (enable any-event tracking — reports ALL mouse motion)
   \e[?1006h  (enable SGR encoding — the [<Cb;Cx;CyM format)
   ```

2. **App exits without cleanup** — Should send but doesn't:
   ```
   \e[?1006l  (disable SGR encoding)
   \e[?1003l  (disable any-event tracking)
   ```

3. **Terminal keeps reporting** — Ghostty dutifully sends mouse events, but
   nothing consumes them. They go: Ghostty → tmux passthrough → fish → display

4. **High-frequency device amplifies** — A trackball generates continuous motion
   events, making the problem very visible.

### Contributing Factors

- `allow-passthrough on` in tmux.conf allows apps to negotiate mouse tracking
  directly with Ghostty, bypassing tmux's mouse handling
- `set -g mouse on` in tmux means tmux is also doing mouse handling
- Claude Code uses Ink/React TUI which enables mouse tracking for interactions

## Solution

### 1. Fish Prompt Auto-Reset (Primary Fix)

Added to `home/programs/fish.nix` in `interactiveShellInit`:

```fish
# Reset leaked mouse tracking modes on every prompt
function __reset_mouse_mode --on-event fish_prompt
    printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l'
end
```

This fires every time fish displays a prompt, cleaning up any leaked state.

### 2. Fish Manual Reset Command

Added to `home/programs/fish.nix` in `functions`:

```fish
reset-mouse = ''
  printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l'
  echo "Mouse tracking modes reset"
'';
```

Type `reset-mouse` at the prompt to manually reset.

### 3. Fish Emergency Keybind (ctrl+g)

Added to `home/programs/fish.nix` in `interactiveShellInit`:

```fish
bind \cg 'printf "\e[?1000l\e[?1002l\e[?1003l\e[?1006l"; commandline -f repaint'
```

Press `ctrl+g` to reset mouse modes while typing a command (before pressing enter).

### 4. Ghostty Panic Button (cmd+shift+m)

Added to `home/ghostty/config`:

```
keybind = cmd+shift+m=text:\x1b[?1000l\x1b[?1002l\x1b[?1003l\x1b[?1006l
```

This works **inside any application** including Claude Code, since it's handled
at the terminal level before the app sees it.

## Usage Guide

| Situation | Solution |
|-----------|----------|
| Garbage at fish prompt | Automatic (fish resets on every prompt) |
| Garbage while typing in fish | `ctrl+g` |
| Garbage inside Claude Code | `cmd+shift+m` (Ghostty keybind) |
| Garbage in any app, anywhere | `cmd+shift+m` (Ghostty keybind) |
| Manual reset from fish | `reset-mouse` command |

### Workflow When Issue Occurs In Claude Code

1. **Try `cmd+shift+m` first** — clears garbage without leaving Claude
2. If garbage keeps returning, Claude Code may be continuously re-enabling mouse
   tracking (a bug in Claude Code itself)
3. In that case: exit Claude → fish prompt resets state → re-enter with
   `claude --continue` or `claude --resume`
4. Session data is NOT affected — it's stored server-side and in `~/.claude/`

## Technical Reference

### Mouse Tracking Modes (DECSET/DECRST)

| Mode | Name | Description |
|------|------|-------------|
| 9 | X10 | Button press only, basic encoding |
| 1000 | VT200/Normal | Press + release, with modifiers |
| 1002 | Button-event | Normal + motion while button pressed |
| 1003 | Any-event | Report ALL mouse motion |

### Protocol Encoding Modes

| Mode | Name | Format |
|------|------|--------|
| 1005 | UTF-8 | Encode coords as UTF-8 |
| 1006 | SGR | `CSI < Cb;Cx;Cy M/m` (modern, preferred) |
| 1015 | URXVT | `CSI Cb;Cx;Cy M` |

### Escape Sequences

```bash
# Enable mouse tracking
printf '\e[?1003h'  # Any-event tracking
printf '\e[?1006h'  # SGR encoding

# Disable mouse tracking
printf '\e[?1003l'  # Disable any-event
printf '\e[?1006l'  # Disable SGR encoding

# Disable ALL mouse modes (the nuclear option)
printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l'
```

### Button Code Encoding

Low 2 bits = button number:
- `0` = Left (MB1)
- `1` = Middle (MB2)
- `2` = Right (MB3)
- `3` = Release (in non-SGR modes)

Modifier bits (added to base):
- `4` = Shift
- `8` = Meta/Alt
- `16` = Control
- `32` = Motion indicator
- `64` = Wheel mouse
- `128` = Extended buttons

Example: `35` = `32 + 3` = motion event, no button pressed

## Files Modified

- `home/programs/fish.nix` — Fish shell configuration
- `home/ghostty/config` — Ghostty terminal configuration

## Why This Preserves Mouse Functionality

The reset sequences are **idempotent** — if mouse tracking is already disabled,
they do nothing. Applications like neovim and tmux re-enable mouse tracking when
they start, so they're unaffected by the prompt reset.

The only "cost" is ~20 bytes sent per prompt, which is negligible.

## Future Considerations

If Claude Code fixes their cleanup handling, this workaround becomes unnecessary
but harmless. The proper fix would be in Claude Code's TUI layer ensuring it
always sends disable sequences on exit, even during crashes (via signal handlers
or terminal state restoration).
