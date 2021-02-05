#!/usr/bin/env zsh

if [ -n "$(command -v fzf)" ]; then
  [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

  export FZF_TMUX_HEIGHT='20%'
  export FZF_DEFAULT_OPTS="
  --inline-info
  --select-1
  --ansi
  --extended
  --bind ctrl-j:ignore,ctrl-k:ignore
  --bind ctrl-f:page-down,ctrl-b:page-up,J:down,K:up
  --cycle
  --no-multi
  --no-border
  --preview-window=right:60%:wrap
  --preview 'bat --theme="base16" --style=numbers,changes --color always {}'
  "

  _fzf_nova() {
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

    export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS
    --color=bg:$colorbg,bg+:$colorbg,spinner:$color0C,hl:$color06,gutter:$color02
    --color=fg:$color05,header:$color0D,info:$color0A,pointer:$color09
    --color=marker:$color0C,fg+:$color06,prompt:$color0A,hl+:$color0C
    --color=border:$color12
    "
  }

_fzf_gruvbox() {
  local color00='#32302f'
  local color01='#3c3836'
  local color02='#504945'
  local color03='#665c54'
  local color04='#bdae93'
  local color05='#d5c4a1'
  local color06='#ebdbb2'
  local color07='#fbf1c7'
  local color08='#fb4934'
  local color09='#fe8019'
  local color0A='#fabd2f'
  local color0B='#b8bb26'
  local color0C='#8ec07c'
  local color0D='#83a598'
  local color0E='#d3869b'
  local color0F='#d65d0e'

  export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS
  --color=bg+:$color01,bg:$color00,spinner:$color0C,hl:$color0D
  --color=fg:$color04,header:$color0D,info:$color0A,pointer:$color0C
  --color=marker:$color0C,fg+:$color06,prompt:$color0A,hl+:$color0D
  "
}

_fzf_forest_night() {
  local color00='#323d43'
  local color01='#3c474d'
  local color02='#465258'
  local color03='#505a60'
  local color04='#d8caac'
  local color05='#d5c4a1'
  local color06='#ebdbb2'
  local color07='#fbf1c7'
  local color08='#fb4934'
  local color09='#fe8019'
  local color0A='#fabd2f'
  local color0B='#b8bb26'
  local color0C='#8ec07c'
  local color0D='#83a598'
  local color0E='#d3869b'
  local color0F='#d65d0e'

  export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS
  --color=bg+:$color01,bg:$color00,spinner:$color0C,hl:$color0D
  --color=fg:$color04,header:$color0D,info:$color0A,pointer:$color0C
  --color=marker:$color0C,fg+:$color06,prompt:$color0A,hl+:$color0D
  "
}

# TODO: figure out how to automate this based on the loaded kitty theme, mayhaps?
_fzf_forest_night

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

fi
