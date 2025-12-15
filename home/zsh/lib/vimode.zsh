# # vi mode
# bindkey -v

# # <Space> in normal mode to edit command line in $EDITOR
# autoload edit-command-line
# zle -N edit-command-line
# bindkey -M vicmd ' ' edit-command-line

# # change cursor shape depending on mode
# function zle-keymap-select {
#   if [[ ${KEYMAP} == vicmd ]] \
#     || [[ $1 == 'block' ]]; then
#     echo -ne '\e[2 q'
#   elif [[ ${KEYMAP} == main ]] \
#     || [[ ${KEYMAP} == viins ]] \
#     || [[ ${KEYMAP} == '' ]] \
#     || [[ $1 == 'beam' ]]; then
#     echo -ne '\e[6 q'
#   fi
# }
# zle -N zle-keymap-select
# zle-line-init() {
#   zle -K viins
#   echo -ne "\e[6 q"
# }
# zle -N zle-line-init
# echo -ne '\e[6 q'
# preexec() { echo -ne '\e[6 q'; }
