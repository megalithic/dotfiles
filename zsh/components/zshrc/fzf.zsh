#!/bin/zsh

# -- setup fzf
# consider these handy fzf functions: https://github.com/junegunn/dotfiles/blob/master/bashrc#L267
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

_gen_fzf_default_opts() {
  local color00='#002b36'
  local color01='#073642'
  local color02='#586e75'
  local color03='#657b83'
  local color04='#839496'
  local color05='#93a1a1'
  local color06='#eee8d5'
  local color07='#fdf6e3'
  local color08='#dc322f'
  local color09='#cb4b16'
  local color0A='#b58900'
  local color0B='#859900'
  local color0C='#2aa198'
  local color0D='#268bd2'
  local color0E='#6c71c4'
  local color0F='#d33682'

  export FZF_DEFAULT_OPTS="
  --inline-info
  --select-1
  --ansi
  --extended
  --bind ctrl-j:ignore,ctrl-k:ignore
  --bind ctrl-f:page-down,ctrl-b:page-up,J:down,K:up
  --color=spinner:$color0C,hl:$color0D
  --color=fg:$color04,header:$color0D,info:$color0A,pointer:$color0C
  --color=marker:$color0C,fg+:$color06,prompt:$color0A,hl+:$color0D
  "
	# --color=bg+:$color01,bg:$color00,spinner:$color0C,hl:$color0D
	# --no-height
}
_gen_fzf_default_opts


# -- using ripgrep/rg
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --line-number --glob "!{.git,deps,_build,node_modules}/*" 2> /dev/null'
export FZF_CTRL_T_COMMAND='rg --files --hidden --follow --line-number --glob "!{.git,deps,_build,node_modules}/*" 2> /dev/null'
export FZF_TMUX_HEIGHT='20%'
# thieved from: https://github.com/evantravers/dotfiles/blob/master/zsh/.zshrc#L86
# FZF_DEFAULT_COMMAND="rg --no-ignore --hidden --files --follow -g '!{.git,node_modules,vendor}'"
# FZF_CTRL_T_COMMAND="rg --no-ignore --hidden --files --follow -g '!{.git,node_modules,vendor}'"


# -- these must be set *after* loading fzf:
# export FZF_COMPLETION_TRIGGER=''
# bindkey '^G' fzf-completion
# bindkey '^I' $fzf_default_completion
