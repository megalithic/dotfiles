#!/bin/zsh

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

    export FZF_DEFAULT_OPTS="
    --inline-info
    --select-1
    --ansi
    --extended
    --bind ctrl-j:ignore,ctrl-k:ignore
    --bind ctrl-f:page-down,ctrl-b:page-up,J:down,K:up
    --color=bg+:$color00,bg:$colorbg,spinner:$color0C,hl:$color06
    --color=fg:$color05,header:$color0D,info:$color0A,pointer:$color09
    --color=marker:$color0C,fg+:$color06,prompt:$color0A,hl+:$color0C
    --cycle
    --no-multi
    --preview 'bat {}'
    --preview-window=right:60%:wrap
    "
    # --border
    # --height 40%
    # --layout=reverse
  }
  _gen_fzf_default_opts


  # -- using ripgrep/rg
  export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --line-number --glob "!{.git,deps,_build,node_modules}/*" 2> /dev/null'
  export FZF_CTRL_T_COMMAND='rg --files --hidden --follow --line-number --glob "!{.git,deps,_build,node_modules}/*" 2> /dev/null'
  export FZF_ALT_C_COMMAND="fd --type d --exclude 'Library'"
  export FZF_TMUX_HEIGHT='20%'

  # export FZF_DEFAULT_COMMAND="rg --no-ignore --hidden --files --follow -g '!{.git,node_modules,vendor,build,_build}'"
  # export FZF_CTRL_T_COMMAND="rg --no-ignore --hidden --files --follow -g '!{.git,node_modules,vendor,build,_build}'"

  # # -- using fd
  # export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  # export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  # export FZF_ALT_C_COMMAND="fd --type d . $HOME"


  # -- these must be set *after* loading fzf:
  # export FZF_COMPLETION_TRIGGER=''
  # bindkey '^G' fzf-completion
  # bindkey '^I' $fzf_default_completion
fi
