set -x SHELL /usr/local/bin/fish

source /usr/local/share/chruby/chruby.fish
source /usr/local/share/chruby/auto.fish

# apps launching and such
alias mux="tmux"
alias vim="nvim"
alias updatenvim="brew update; pip3 install --upgrade neovim; npm install -g neovim; chruby system; gem install neovim; nvim +PlugUpgrade +qall; nvim +PlugUpdate +qall; nvim +UpdateRemotePlugins +qall; brew outdated"
alias nvimupdate="updatenvim"

# file edits
alias ev="vim ~/.dotfiles/nvim/init.vim"
alias ef="vim ~/.dotfiles/fish/config.fish"
alias sf="source ~/.dotfiles/fish/config.fish"
alias et="vim ~/.dotfiles/tmux/tmux.conf.symlink"
alias ez="vim ~/.dotfiles/zsh/zshrc.symlink"
alias sz="source ~/.zshrc"

# ruby/rails
alias be="bundle exec"
