# -- zinit configuration

zinit light-mode for \
  zdharma/history-search-multi-word \
  zsh-users/zsh-history-substring-search \
  zinit-zsh/z-a-submods \

zinit wait'0a' lucid for \
  atinit"zicompinit; zicdreplay" \
      zdharma/fast-syntax-highlighting \
  atload"_zsh_autosuggest_start" \
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

# Replace zsh's default completion selection menu with fzf!
zinit light Aloxaf/fzf-tab

# reminders for aliases if whole command is typed
zinit light djui/alias-tips
