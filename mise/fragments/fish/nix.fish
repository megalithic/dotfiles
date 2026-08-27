# Nix profile PATH setup (megabookpro). Sourced by conf.d/env.fish when present.
# Static port of the retired Home Manager xdg.dataFile."fish/nix.fish".
# No-ops on hosts without nix (guards with test -d).
set -l per_user_profile "/etc/profiles/per-user/$USER/bin"
test -d "$per_user_profile"; and fish_add_path --prepend "$per_user_profile"

test -d "$HOME/.nix-profile/bin"; and fish_add_path --prepend "$HOME/.nix-profile/bin"
