# Starship - cross-shell prompt
# Config ownership flipped to mise (mise/config/starship/starship.toml ->
# ~/.config/starship.toml via [dotfiles]). Keep enable=true so the HM fish
# integration still inits the prompt until the shells wave flips fish.
_: {
  programs.starship.enable = true;
}
