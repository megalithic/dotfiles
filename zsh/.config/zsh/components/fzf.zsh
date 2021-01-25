#!/usr/bin/env zsh

if [ -n "$(command -v fzf)" ]; then
  [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

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
  --color=bg:$colorbg,bg+:$colorbg,spinner:$color0C,hl:$color06,gutter:$color02
  --color=fg:$color05,header:$color0D,info:$color0A,pointer:$color09
  --color=marker:$color0C,fg+:$color06,prompt:$color0A,hl+:$color0C
  --color=border:$color12
  --cycle
  --no-multi
  --no-border
  --preview-window=right:60%:wrap
  --preview 'bat --theme="base16" --style=numbers,changes --color always {}'
  "

  # if (command -v rg &> /dev/null); then
  #   export FZF_CTRL_T_COMMAND='rg --files --hidden --line-number --follow -g "!{.git,node_modules,vendor,build,_build}"'
  # fi

  if (command -v fd &> /dev/null); then
    export FZF_DEFAULT_COMMAND='fd --type f --follow --hidden --color=always --exclude .git --ignore-file ~/.gitignore_global'
    export FZF_CTRL_T_COMMAND='fd --type f --follow --hidden --color=always --exclude .git --ignore-file ~/.gitignore_global'
    export FZF_ALT_C_COMMAND="fd --type d --follow --hidden --exclude 'Library'"
  elif (command -v fdfind &> /dev/null); then
    export FZF_DEFAULT_COMMAND='fdfind --type f -follow --hidden --color=always --exclude .git --ignore-file ~/.gitignore_global'
    export FZF_CTRL_T_COMMAND='fdfind --type f --follow --hidden --color=always --exclude .git --ignore-file ~/.gitignore_global'
    export FZF_ALT_C_COMMAND="fdfind --type d --follow --hidden --exclude 'Library'"
  fi

  export FZF_TMUX_HEIGHT='20%'
fi
