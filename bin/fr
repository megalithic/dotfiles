#!/usr/bin/env bash
# Find a pattern with rg and fzf.  Preview contents with bat.  Edit File.
#
# Dependencies:
#   1. rg  | recursively search current directory for lines matching a pattern
#   2. fzf | command-line fuzzy finder
#   3. bat | a cat clone with syntax highlighting and Git integration
#   4. $EDITOR | Exported environment variable referring to your editor.
#
# Shout Out:
# https://github.com/junegunn/fzf/blob/master/ADVANCED.md#using-fzf-as-interactive-ripgrep-launcher
#
# 1. Search for text in files using Ripgrep
# 2. Interactively restart Ripgrep with reload action
# 3. Open the file in $EDITOR

RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case "
INITIAL_QUERY="${*:-}"
IFS=: read -ra selected < <(
  FZF_DEFAULT_COMMAND="$RG_PREFIX $(printf %q "$INITIAL_QUERY")" \
  fzf --ansi \
      --disabled --query "$INITIAL_QUERY" \
      --bind "change:reload:sleep 0.1; $RG_PREFIX {q} || true" \
      --delimiter : \
      --preview 'bat --color=always {1} --highlight-line {2}' \
      --preview-window 'left,50%,border-bottom,+{2}+3/3,~3'
)
[ -n "${selected[0]}" ] && $EDITOR "${selected[0]}" "+${selected[1]}"
