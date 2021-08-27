#u Load universal config when it's changed

set -l fish_config_mtime
if test -d /Applications
    set fish_config_mtime (/usr/bin/stat -f %m $__fish_config_dir/config.fish)
else
    set fish_config_mtime (/usr/bin/stat -c %Y $__fish_config_dir/config.fish)
end

set -gx EDITOR nvim
if test "$fish_config_changed" = "$fish_config_mtime"
    exit
else
    set -U fish_config_changed $fish_config_mtime
end

set -Ux fish_user_paths
# Path
fish_add_path ~/.cargo/bin
fish_add_path ~/.local/bin
fish_add_path ~/Library/Python/3.{8,9}/bin
fish_add_path /usr/local/opt/sqlite/bin
fish_add_path /usr/local/sbin
fish_add_path ~/.gem/ruby/2.6.0/bin
fish_add_path ~/.local/bin/pnpm

# Fish
set -U fish_emoji_width 2
# alias -s fish_greeting color-test
set -U fish_greeting ""

# Emacs
# set -l emacs_path /Applications/Emacs.app/Contents/MacOS
# set -Ux EMACS $emacs_path/Emacs
fish_add_path ~/.emacs.d/bin
# alias -s emacs $EMACS

# Go
set -Ux GOPATH ~/go
fish_add_path $GOPATH $GOPATH/bin


# fish_add_path -m ~/.nix-profile/bin /etc/profiles/per-user/folke/bin /run/current-system/sw/bin /nix/var/nix/profiles/default/bin
# Exports
set -Ux EDITOR nvim
set -Ux VISUAL nvim
set -Ux LESS -rF
set -Ux BAT_THEME Dracula
set -Ux COMPOSE_DOCKER_CLI_BUILD 1
set -Ux HOMEBREW_NO_AUTO_UPDATE 1
set -Ux DOTDROP_AUTOUPDATE no
set -Ux MANPAGER "nvim +Man!"
set -Ux MANROFFOPT -c
#set -Ux MANPAGER "sh -c 'col -bx | bat -l man -p'" # use bat to format man pages
#set -Ux MANPAGER "most" # use bat to format man pages


# Tmux
abbr t tmux
abbr tc 'tmux attach'
abbr ta 'tmux attach -t'
abbr tad 'tmux attach -d -t'
abbr ts 'tmux new -s'
abbr tl 'tmux ls'
abbr tk 'tmux kill-session -t'
abbr mux tmuxinator

# Files & Directories
abbr mv "mv -iv"
abbr cp "cp -riv"
abbr mkdir "mkdir -vp"
alias -s ls="exa --color=always --icons --group-directories-first"
alias -s la 'exa --color=always --icons --group-directories-first --all'
alias -s ll 'exa --color=always --icons --group-directories-first --all --long'
abbr l ll
abbr ncdu "ncdu --color dark"

# Config Edits
abbr ef "nvim $HOME/.config/fish/config.fish"
abbr ez "nvim $ZDOTDIR/.zshrc"
abbr ezz "nvim $ZDOTDIR/.zshenv"
abbr ezl "nvim $HOME/.localrc"
abbr eza "nvim $HOME/.config/zsh/**/aliases.zsh"
abbr ezf "nvim $HOME/.config/zsh/**/functions.zsh"
abbr ezo "nvim $HOME/.config/zsh/**/opts.zsh"
abbr ehs "nvim $HOME/.config/hammerspoon/config.lua"
abbr eh "nvim $HOME/.config/hammerspoon/init.lua"
abbr eg "nvim $HOME/.gitconfig"
abbr eb "nvim $HOME/.dotfiles/Brewfile"
abbr essh "nvim $HOME/.ssh/config"
abbr eze "nvim $HOME/.config/zsh/**/env.zsh"
abbr ezkb "nvim $HOME/.config/zsh/**/keybindings.zsh"
abbr ev "nvim $HOME/.config/nvim/init.lua"
abbr evv "nvim $HOME/.config/nvim/.vimrc"
abbr evp "nvim $HOME/.config/nvim/lua/plugins.lua"
abbr evs "nvim $HOME/.config/nvim/lua/settings.lua"
abbr evl "nvim $HOME/.config/nvim/lua/lsp.lua"
abbr evm "nvim $HOME/.config/nvim/lua/mappings.lua"
abbr ek "nvim $HOME/.config/kitty/kitty.conf"
abbr et "nvim $HOME/.tmux.conf"

# Editor
abbr vim nvim
abbr vi nvim
abbr vm nvim
abbr v nvim

# Dev
abbr git hub
abbr g hub
abbr lg lazygit
abbr gl 'hub l --color | devmoji --log --color | less -rXF'
abbr st "hub st"
abbr push "hub push"
abbr pull "hub pull"
alias -s tn "npx --no-install ts-node --transpile-only"
abbr tt "tn src/tt.ts"
alias -s todo "ag --color-line-number '1;36' --color-path '1;36' --print-long-lines --silent '((//|#|<!--|;|/\*|^)\s*(TODO|FIXME|FIX|BUG|UGLY|HACK|NOTE|IDEA|REVIEW|DEBUG|OPTIMIZE|REF)|^\s*- \[ \])'"

# Nix
abbr ni "nix-env -f '<nixpkgs>' -iA"
abbr nq "nix-env -q"
abbr nqa "nix-env -qa"
abbr nd "nix-env -e"
abbr nu "nix-env -u"

# Other
abbr df "grc /bin/df -h"
abbr ntop "ultra --monitor"
abbr ytop btm
abbr gotop btm
abbr fda "fd -IH"
abbr rga "rg -uu"
abbr grep rg
abbr suod sudo
abbr helpme "bat ~/HELP.md"
abbr weather "curl -s wttr.in/Ghent | grep -v Follow"
abbr show-cursor "tput cnorm"
abbr hide-cursor "tput civis"
abbr aria2c-daemon "aria2c -D"
alias -s apropos "MANPATH=$HOME/.cache/fish command apropos"
alias -s whatis "MANPATH=$HOME/.cache/fish command whatis"

# FZF

# https://github.com/folke/dot/blob/master/config/fish/conf.d/fzf.fish
bind \cr __fzf_history
bind \ch __fzf_tldr
bind \ct __fzf_files

set -l color00 '#323d43'
set -l color01 '#3c474d'
set -l color02 '#465258'
set -l color03 '#505a60'
set -l color04 '#d8caac'
set -l color05 '#d5c4a1'
set -l color06 '#ebdbb2'
set -l color07 '#fbf1c7'
set -l color08 '#fb4934'
set -l color09 '#fe8019'
set -l color0A '#fabd2f'
set -l color0B '#b8bb26'
set -l color0C '#8ec07c'
set -l color0D '#83a598'
set -l color0E '#d3869b'
set -l color0F '#d65d0e'


# # set -q FZF_TMUX_HEIGHT; or set -U FZF_TMUX_HEIGHT "40%"
# # set -q FZF_DEFAULT_OPTS; or set -U FZF_DEFAULT_OPTS "--height $FZF_TMUX_HEIGHT"
# # set -q FZF_LEGACY_KEYBINDINGS; or set -U FZF_LEGACY_KEYBINDINGS 1
# # set -q FZF_DISABLE_KEYBINDINGS; or set -U FZF_DISABLE_KEYBINDINGS 0
# # set -q FZF_PREVIEW_FILE_CMD; or set -U FZF_PREVIEW_FILE_CMD "head -n 10"
# # set -q FZF_PREVIEW_DIR_CMD; or set -U FZF_PREVIEW_DIR_CMD ls

# set -xUa FZF_TMUX 1
# set -xUa FZF_TMUX_HEIGHT "30%"
# set -xUa FZF_DEFAULT_OPTS " \
# --inline-info \
# --select-1 \
# --ansi \
# --extended \
# --bind ctrl-j:ignore,ctrl-k:ignore \
# --bind ctrl-f:page-down,ctrl-b:page-up,J:down,K:up \
# --cycle \
# --no-multi \
# --no-border \
# --layout=reverse \
# --preview-window=right:60%:wrap \
# --preview 'bat --theme="base16" --style=numbers,changes --color always {}' \
# "
# set -xUa FZF_DEFAULT_OPTS " \
#   --color=bg+:$color01,bg:$color00,spinner:$color0C,hl:$color0D \
#   --color=fg:$color04,header:$color0D,info:$color0A,pointer:$color0C \
#   --color=marker:$color0C,fg+:$color06,prompt:$color0A,hl+:$color0D \
# "

# # set -x FZF_DEFAULT_OPTS "--cycle --layout=reverse --border --height 40% --preview-window=right:70% \
# #     --color=bg+:$color01,bg:$color00,spinner:$color0C,hl:$color0D \
# #     --color=fg:$color04,header:$color0D,info:$color0A,pointer:$color0C \
# #     --color=marker:$color0C,fg+:$color06,prompt:$color0A,hl+:$color0D"
