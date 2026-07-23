# Starship prompt (non-nix twin of home/common/programs/starship, which used
# programs.starship.enable to inject this into the HM-generated fish config).
# Config lives at ~/.config/starship.toml (linked by the mise [dotfiles] table).
status is-interactive; or exit
command -sq starship; or exit

starship init fish | source
