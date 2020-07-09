# -- zinit configuration

zinit light-mode for \
  zdharma/history-search-multi-word \
  zsh-users/zsh-history-substring-search \
  zinit-zsh/z-a-submods \

zinit wait'0a' lucid for \
  atinit"zicompinit; zicdreplay" \
      zdharma/fast-syntax-highlighting \
  atload"_zsh_autosuggest_start" atinit='ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6A7D89,bg=#3c4c55"; ZSH_AUTOSUGGEST_USE_ASYNC=1' \
      zsh-users/zsh-autosuggestions \
  blockf \
    svn submods'zsh-users/zsh-completions -> external' \
      PZT::modules/completion \
  nocd depth=1 atinit='ZSH_BASH_COMPLETIONS_FALLBACK_LAZYLOAD_DISABLE=true' \
      3v1n0/zsh-bash-completions-fallback \

# Load OMZ Git library
zinit snippet OMZ::lib/git.zsh

# Install OMZ git aliases
zinit snippet OMZ::plugins/git/git.plugin.zsh

# Install OMZ elixir mix completions
zinit ice as"completion"
zinit snippet OMZ::plugins/mix/_mix

zinit ice as"completion"
zinit snippet OMZ::plugins/mix-fast/mix-fast.plugin.zsh

zinit ice as"completion"
zinit snippet https://github.com/docker/cli/blob/master/contrib/completion/zsh/_docker

# Replace zsh's default completion selection menu with fzf!
zinit light Aloxaf/fzf-tab

# reminders for aliases if whole command is typed
zinit light djui/alias-tips

# zsh-abbr manages abbreviations - user-defined words that are replaced with longer phrases after they are entered.
zinit ice wait lucid
zinit light olets/zsh-abbr # or `load` instead of `light` to enable zinit reporting

# my custom prompt with gitstatus plugin
zinit ice wait lucid
zinit light romkatv/gitstatus
# zinit light-mode src"gitstatus.plugin.zsh" romkatv/gitstatus
zinit snippet ~/.dotfiles/zsh/components/prompt.zsh
