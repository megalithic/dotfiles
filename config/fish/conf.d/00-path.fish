# PATH bootstrap. Must sort first in conf.d: later snippets (atuin, fzf, mise, starship, ...)
# guard with `command -sq <tool>; or return` and silently no-op when the tool
# isn't on PATH yet. Once mise is findable, conf.d/mise.fish activates it and
# injects tool paths plus the [env] _.path entries from the global config.
# Not interactive-gated: login/non-interactive shells need PATH too.
set -l __boot_paths \
    $HOME/.local/bin \
    $HOME/bin \
    $HOME/.dotfiles/bin \
    /opt/homebrew/bin \
    /opt/homebrew/sbin

for dir in $__boot_paths[-1..1]
    test -d $dir; and not contains -- $dir $PATH; and set -gx PATH $dir $PATH
end

# Nix profiles (megabookpro only; no-ops where the directories are absent).
for dir in $HOME/.nix-profile/bin /etc/profiles/per-user/$USER/bin
    test -d $dir; and not contains -- $dir $PATH; and set -gx PATH $dir $PATH
end
