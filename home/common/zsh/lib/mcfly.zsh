setopt histignorespace
export MCFLY_INTERFACE_VIEW=TOP # alts: TOP,BOTTOM
export MCFLY_DISABLE_MENU=TRUE
export MCFLY_PROMPT="→"
export MCFLY_RESULTS=25
export MCFLY_RESULTS_SORT=LAST_RUN
export MCFLY_FUZZY=2 # alts: 0 for off
export MCFLY_KEY_SCHEME=vim

eval "$(mcfly init zsh)"
