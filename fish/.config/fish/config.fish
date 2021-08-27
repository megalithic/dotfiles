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
