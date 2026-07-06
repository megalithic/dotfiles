# fzf environment — non-nix port of home/common/programs/fzf/default.nix plus
# the FZF_* vars from hosts/common.nix (environment.variables).
#
# Default options live in ~/.config/fzf/fzfrc via FZF_DEFAULT_OPTS_FILE (fzf >= 0.48).
# Key bindings (ctrl-t / ctrl-r / alt-c) load in config.fish via `fzf --fish | source`,
# after fish_vi_key_bindings so the vi-mode binding reset does not wipe them.
#
# fzf-tmux integration stays disabled on purpose: it drops history entries due
# to a race condition piping large datasets through fifos. Widgets run inline.

command -sq fzf; or return

set -l config_home "$XDG_CONFIG_HOME"
test -z "$config_home"; and set config_home "$HOME/.config"
test -f "$config_home/fzf/fzfrc"; and set -gx FZF_DEFAULT_OPTS_FILE "$config_home/fzf/fzfrc"

set -gx FZF_DEFAULT_COMMAND "fd --type f --hidden --no-ignore-vcs --follow --exclude .git --exclude .jj --exclude .direnv --exclude node_modules --strip-cwd-prefix"

# fish's fzf CTRL-T widget sets $dir from the current command-line token (for
# example `nvim ~/code/<C-t>`). fd cannot combine --strip-cwd-prefix with an
# explicit search path, so pass $dir as fd's root and strip only the ./ prefix
# from cwd results. $dir must stay literal here; the widget expands it.
set -gx FZF_CTRL_T_COMMAND 'fd --type f --hidden --no-ignore-vcs --follow --exclude .git --exclude .jj --exclude .direnv . $dir | sed \'s#^\./##\''

set -gx FZF_ALT_C_COMMAND "fd --type d --hidden --follow --no-ignore-vcs --exclude .git --exclude .jj --exclude .direnv --strip-cwd-prefix"

if status is-interactive
    set -gx FZF_CTRL_T_OPTS "--preview='preview {}' --header='find files [$(tput setaf 255)ctrl-y$(tput sgr 0): $(tput setaf 245)copy to clipboard$(tput sgr 0)]'"
    set -gx FZF_CTRL_R_OPTS "--preview 'echo {}' --preview-window down:3:wrap:hidden --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort' --header 'Press CTRL-Y to copy command into clipboard'"
    set -gx FZF_ALT_C_OPTS "--preview='preview {}'"
end
