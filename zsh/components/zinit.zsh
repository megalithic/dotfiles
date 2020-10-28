# -- zinit configuration

# REF: https://github.com/davidkna/dotfiles/blob/master/dot_zshrc
zinit wait lucid for \
  atinit"zpcompinit; zpcdreplay" \
    Aloxaf/fzf-tab \
  blockf \
    zdharma/fast-syntax-highlighting \
  atload"_zsh_autosuggest_start" atinit='ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6A7D89,bg=#3c4c55"; ZSH_AUTOSUGGEST_USE_ASYNC=1' \
    zsh-users/zsh-autosuggestions \
  blockf \
    zsh-users/zsh-completions \
  bindmap='UPAR -> ^history-substring-search-up; DOWNAR -> history-substring-search-down' \
    zsh-users/zsh-history-substring-search
 # atclone="dircolors -b LS_COLORS > c.zsh" atpull='%atclone' pick='c.zsh' \
 #    trapd00r/LS_COLORS
 # REF: ^ https://github.com/MiracleKaze/dotfiles/blob/master/dotfiles/zshrc

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

# reminders for aliases if whole command is typed
# zinit light djui/alias-tips

# # zsh-abbr manages abbreviations - user-defined words that are replaced with longer phrases after they are entered.
# zinit ice wait lucid
# zinit light olets/zsh-abbr


# REF OMZ and more: https://github.com/ztoiax/home/blob/master/.zshrc
zinit light-mode for \
  zpm-zsh/colors

# # OMZ
# zinit wait lucid for \
#     OMZP::git-extras \
#     OMZP::git \
#     OMZL::clipboard.zsh

# zinit ice mv=":cht.sh -> cht.sh" atclone="chmod +x cht.sh" as="program"
# zinit snippet https://cht.sh/:cht.sh

# zinit ice mv=":zsh -> _cht" as="completion"
# zinit snippet https://cheat.sh/:zsh

zinit ice as="completion" for \
    OMZP::docker/_docker \
    OMZP::fd/_fd \
    OMZP::cargo/_cargo \
    OMZP::rust/_rust \
    esc/conda-zsh-completion

# my custom prompt with gitstatus plugin
zinit ice as"program" src"gitstatus.plugin.zsh"
zinit light romkatv/gitstatus
zinit snippet ~/.dotfiles/zsh/components/prompt.zsh
