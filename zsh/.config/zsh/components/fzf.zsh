#!/usr/bin/env zsh

# https://github.com/junegunn/fzf/wiki/Color-schemes#color-configuration
# interactive color picker for fzf themes: https://minsw.github.io/fzf-color-picker/
#
# https://github.com/junegunn/fzf/wiki/Configuring-shell-key-bindings
# https://gist.github.com/junegunn/8b572b8d4b5eddd8b85e5f4d40f17236

if [ -n "$(command -v fzf)" ]; then
	# -- use this if not using zsh-vi-mode
	# TODO: need a condition to make this cleaner
	# [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

	# -- this fixes an issue with zsh-vi-mode gobbling fzf keybindings
	zvm_after_init_commands+=('[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh')

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

	_fzf_megaforest() {
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
	_fzf_megaforest

	# if (command -v rg &> /dev/null); then
	#   export FZF_CTRL_T_COMMAND='rg --files --hidden --line-number --follow -g "!{.git,node_modules,vendor,build,_build}"'
	# fi
	#

	if (command -v fd &>/dev/null); then
		LIST_DIR_CONTENTS='ls --almost-all --group-directories-first --color=always {}'
		LIST_FILE_CONTENTS='head -n128 {}'
		FZF_ALT_C_OPTS="--preview '$LIST_DIR_CONTENTS'"
		FZF_CTRL_T_OPTS="--preview 'if [[ -f {} ]]; then $LIST_FILE_CONTENTS; elif [[ -d {} ]]; then $LIST_DIR_CONTENTS; fi'"

		export FZF_DEFAULT_COMMAND='fd --type f --follow --hidden --color=always --exclude .git --ignore-file ~/.gitignore_global --ignore-file .gitignore'
		export FZF_CTRL_T_COMMAND='fd --type f --follow --hidden --color=always --exclude .git --ignore-file ~/.gitignore_global --ignore-file .gitignore'
		export FZF_ALT_C_COMMAND="fd --type d --follow --hidden --exclude 'Library'"
	fi
fi
