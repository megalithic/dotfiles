-- Committed static fragment linked to ~/.local/share/hammerspoon/nix_path.lua
-- by the mise [dotfiles] table. Replaces the Home Manager-generated file of
-- the same name; preflight.lua does pcall(require, "nix_path") and consumes
-- the NIX_PATH / NIX_ENV globals (variable names kept for compatibility).
local home = os.getenv("HOME")

-- PATH prefix for GUI-app context: mise shims expose all mise-managed tools.
NIX_PATH = home .. "/.local/share/mise/shims"

NIX_ENV = {
  NOTES_HOME = home .. "/iclouddrive/Documents/_notes",
  OBSIDIAN_HOME = home .. "/iclouddrive/Documents/_notes",
  NVIM_DB_HOME = home .. "/protondrive/configs/sql",
  DOTS = home .. "/.dotfiles",
  XDG_CONFIG_HOME = home .. "/.config",
  XDG_DATA_HOME = home .. "/.local/share",
  XDG_CACHE_HOME = home .. "/.cache",
}
