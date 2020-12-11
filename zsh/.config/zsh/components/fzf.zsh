#!/usr/bin/env zsh

if [ -n "$(command -v fzf)" ]; then
  # -- setup fzf
  # consider these handy fzf functions: https://github.com/junegunn/dotfiles/blob/master/bashrc#L267
  [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

  _gen_fzf_default_opts() {
    local colorbg='#3C4C55'
    local color00='#1E272C'
    local color01='#073642'
    local color02='#586E75'
    local color03='#657B83'
    local color04='#839496'
    local color05='#93A1A1'
    local color06='#EEE8D5'
    local color07='#FDF6E3'
    local color08='#DC322F'
    local color09='#CB4B16'
    local color10='#F2C38F'
    local color11='#70562A'
    local color12='#59818B'
    local color0A='#B58900'
    local color0B='#859900'
    local color0C='#2AA198'
    local color0D='#268BD2'
    local color0E='#6C71C4'
    local color0F='#D33682'

    export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS"
    --inline-info
    --select-1
    --ansi
    --extended
    --bind ctrl-j:ignore,ctrl-k:ignore
    --bind ctrl-f:page-down,ctrl-b:page-up,J:down,K:up
    --color=bg:$colorbg,bg+:$colorbg,spinner:$color0C,hl:$color06,gutter:$color02
    --color=fg:$color05,header:$color0D,info:$color0A,pointer:$color09
    --color=marker:$color0C,fg+:$color06,prompt:$color0A,hl+:$color0C
    --color=border:$color12
    --cycle
    --no-multi
    --no-border
    --preview-window=right:60%:wrap
    --preview 'bat --theme="base16" --style=numbers,changes --color always {}'
    --layout=reverse
    "
    # --color=bg+:$color00,bg:$colorbg
    # --preview 'bat {}'
    # --border
    # --height 40%
    # --layout=reverse

    # FZF_TAB_COMMAND=(
    #   fzf
    #   --ansi   # Enable ANSI color support, necessary for showing groups
    #   --expect='$continuous_trigger' # For continuous completion
    #   --color=bg:$colorbg,bg+:$colorbg,spinner:$color0C,hl:$color06,gutter:$color02
    #   --color=fg:$color05,header:$color0D,info:$color0A,pointer:$color09
    #   --color=marker:$color0C,fg+:$color06,prompt:$color0A,hl+:$color0C
    #   --color=border:$color12
    #   --nth=2,3 --delimiter='\x00'  # Don't search prefix
    #   --layout=reverse --height='${FZF_TMUX_HEIGHT:=75%}'
    #   --tiebreak=begin -m --bind=tab:down,btab:up,change:top,ctrl-space:toggle --cycle
    #   '--query=$query'   # $query will be expanded to query string at runtime.
    #   '--header-lines=$#headers' # $#headers will be expanded to lines of headers at runtime
    # )
    # # '--color=hl:$(( $#headers == 0 ? 108 : 255 ))'
    # zstyle ':fzf-tab:*' command $FZF_TAB_COMMAND
  }
  _gen_fzf_default_opts


  # -- using ripgrep/rg
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --color=always --exclude .git --ignore-file ~/.gitignore 2> /dev/null'
  export FZF_CTRL_T_COMMAND='rg --files --hidden --line-number --follow -g "!{.git,node_modules,vendor,build,_build}" 2> /dev/null'
  export FZF_ALT_C_COMMAND="fd --type d --exclude 'Library'"
  export FZF_TMUX_HEIGHT='20%'

  # export FZF_CTRL_R_OPTS=""
  # export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:wrap --bind"

  # fixing fzf-tab color issues on macos:
  # https://github.com/Aloxaf/fzf-tab/issues/32#issuecomment-623717139
  # zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
  zstyle ':completion:*:descriptions' format '-- %d --'

# # fzf_tab
# FZF_TAB_COMMAND=(
#     fzf
#     --ansi   # Enable ANSI color support, necessary for showing groups
#     --border
#     --height 80%
#     --expect='$continuous_trigger,$print_query' # For continuous completion and print query
#     '--color=hl:$(( $#headers == 0 ? 108 : 255 ))'
#     --nth=2,3 --delimiter='\x00'  # Don't search prefix
#     --layout=reverse
#     --bind alt-p:preview-up,alt-n:preview-down
#     --bind ctrl-u:half-page-up
#     --bind ctrl-d:half-page-down
#     --bind alt-a:select-all,ctrl-r:toggle-all
#     --bind ctrl-s:toggle-sort
#     --tiebreak=begin
#     --multi
#     --cycle
#     '--query=$query'   # $query will be expanded to query string at runtime.
#     '--header-lines=$#headers' # $#headers will be expanded to lines of headers at runtime
#     --print-query
# )
# zstyle ':fzf-tab:*' command $FZF_TAB_COMMAND
# # disable sort when completing options of any command
# zstyle ':completion:complete:*:options' sort false
# # use input as query string when completing zlua
# zstyle ':fzf-tab:complete:_zlua:*' query-string input

# # (experimental, may change in the future)
# # some boilerplate code to define the variable `extract` which will be used later
# # please remember to copy them
# local extract="
# # trim input(what you select)
# local in=\${\${\"\$(<{f})\"%\$'\0'*}#*\$'\0'}
# # get ctxt for current completion(some thing before or after the current word)
# local -A ctxt=(\"\${(@ps:\2:)CTXT}\")
# # real path
# local realpath=\${ctxt[IPREFIX]}\${ctxt[hpre]}\$in
# realpath=\${(Qe)~realpath}
# "
# zstyle ':fzf-tab:*' continuous-trigger '/'
# zstyle ':fzf-tab:*' print-query alt-enter
# zstyle ':fzf-tab:*' ignore false
# zstyle ':fzf-tab:*' single-group color header
# FZF_TAB_GROUP_COLORS=(
#     $'\033[94m' $'\033[32m' $'\033[33m' $'\033[35m' $'\033[31m' $'\033[38;5;27m' $'\033[36m' \
#     $'\033[38;5;100m' $'\033[38;5;98m' $'\033[91m' $'\033[38;5;80m' $'\033[92m' \
#     $'\033[38;5;214m' $'\033[38;5;165m' $'\033[38;5;124m' $'\033[38;5;120m'
# )
# zstyle ':fzf-tab:*' group-colors $FZF_TAB_GROUP_COLORS

# # give a preview of commandline arguments when completing `kill`
# zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm,cmd -w -w"
# zstyle ':fzf-tab:complete:kill:argument-rest' extra-opts --preview=$extract'ps --pid=$in[(w)1] -o cmd --no-headers -w -w' --preview-window=down:3:wrap
# # give a preview of directory by exa when completing cd
# # zstyle ':fzf-tab:complete:cd:*' extra-opts --preview=$extract'exa -1 --color=always $realpath'
fi
