# if [[ -n $SSH_CONNECTION ]]; then
#   export PS1='%m:%3~$(git_info_for_prompt)%# '
# else
#   export PS1='%3~$(git_info_for_prompt)%# '
# fi

# umask
# https://github.com/pjg/dotfiles/blob/master/.zshrc#L24
umask 022

fpath=($ZSH/completions/src $ZSH/functions $fpath)

autoload -U $ZSH/functions/*(:t)

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# for eager loading all files for ternjs
#  - https://github.com/carlitux/deoplete-ternjs
ulimit -n 2048

setopt NO_BG_NICE # don't nice background tasks
setopt NO_HUP
setopt NO_LIST_BEEP
setopt LOCAL_OPTIONS # allow functions to have local options
setopt LOCAL_TRAPS # allow functions to have local traps
setopt PROMPT_SUBST
setopt CORRECT
setopt COMPLETE_IN_WORD
setopt IGNORE_EOF
# Report the status of background jobs immediately, rather than waiting until just before printing a prompt.
setopt notify

# don't expand aliases _before_ completion has finished
#   like: git comm-[tab]
setopt COMPLETE_ALIASES


# ===== Basics
setopt NO_BEEP # don't beep on error
setopt INTERACTIVE_COMMENTS # Allow comments even in interactive shells (especially for Muness)

# ===== Changing Directories
setopt AUTO_CD # If you type foo, and it isn't a command, and it is a directory in your cdpath, go there
setopt CDABLEVARS # if argument to cd is the name of a parameter whose value is a valid directory, it will become the current directory
setopt PUSHD_IGNORE_DUPS # don't push multiple copies of the same directory onto the directory stack

# ===== Expansion and Globbing
setopt EXTENDED_GLOB # treat #, ~, and ^ as part of patterns for filename generation

# ===== History
setopt APPEND_HISTORY # allow multiple terminal sessions to all append to one zsh command history
setopt EXTENDED_HISTORY # save timestamp of command and duration
setopt INC_APPEND_HISTORY # Add comamnds as they are typed, don't wait until shell exit
setopt INC_APPEND_HISTORY SHARE_HISTORY  # adds history incrementally and share it across sessions
setopt HIST_EXPIRE_DUPS_FIRST # when trimming history, lose oldest duplicates first
setopt HIST_IGNORE_DUPS # Do not write events to history that are duplicates of previous events
setopt HIST_IGNORE_ALL_DUPS # If a new command line being added to the history list duplicates an older one, the older command is removed from the list (even if it is not the previous event)
setopt HIST_SAVE_NO_DUPS # When writing out the history file, older commands that duplicate newer ones are omitted.
setopt HIST_IGNORE_SPACE # remove command line from history list when first character on the line is a space
setopt HIST_FIND_NO_DUPS # When searching history don't display results already cycled through twice
setopt HIST_REDUCE_BLANKS # Remove extra blanks from each command line being added to history
setopt HIST_VERIFY # don't execute, just expand history
setopt SHARE_HISTORY # imports new commands and appends typed commands to history
setopt histignoredups

# ===== Completion
setopt always_to_end # When completing from the middle of a word, move the cursor to the end of the word
# setopt auto_menu # show completion menu on successive tab press. needs unsetop menu_complete to work
setopt auto_name_dirs # any parameter that is set to the absolute name of a directory immediately becomes a name for that directory
setopt complete_in_word # Allow completion from within a word/phrase

# ===== Prompt
setopt prompt_subst # Enable parameter expansion, command substitution, and arithmetic expansion in the prompt
setopt transient_rprompt # only show the rprompt on the current prompt

# ===== Scripts and Functions
setopt multios # perform implicit tees or cats when multiple redirections are attempted

KEYTIMEOUT=1

zle -N newtab
