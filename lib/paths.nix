# Centralized path definitions
# Single source of truth for all paths used across the configuration
#
# Usage in modules:
#   let paths = lib.mega.paths username; in
#   paths.icloud, paths.proton, etc.
username: {
  home = "/Users/${username}";
  icloud = "/Users/${username}/iclouddrive";
  proton = "/Users/${username}/protondrive";
  notes = "/Users/${username}/iclouddrive/Documents/_notes";
  obsidian = "/Users/${username}/Documents/obsidian";
  nvimDb = "/Users/${username}/protondrive/configs/sql";
  dotfiles = "/Users/${username}/.dotfiles";
  config = "/Users/${username}/.config";
  localBin = "/Users/${username}/.local/bin";
  bin = "/Users/${username}/bin";
  cargoHome = "/Users/${username}/.cargo";
}
