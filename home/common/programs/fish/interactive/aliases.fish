status is-interactive; or return

if command -sq eza
    alias ls 'eza --all --group-directories-first --color=always --hyperlink'
    alias l 'eza --all --long --color=always --color-scale=all --group-directories-first --sort=type --hyperlink --icons=always --octal-permissions'
    alias ll 'eza -lahF --group-directories-first --color=always --icons=always --hyperlink'
    alias la 'eza -lahF --group-directories-first --color=always --icons=always --hyperlink'
    alias tree 'eza --tree --color=always'
end

if command -sq trash
    alias rm 'trash -v'
end

alias q exit
alias ,q exit
alias :q exit
alias :Q exit
alias :e nvim
alias mega 'ftm mega'

if command -sq pbcopy
    alias copy pbcopy
else if command -sq xclip
    alias copy 'xclip -selection clipboard'
end

if command -sq pbpaste
    alias paste pbpaste
else if command -sq xclip
    alias paste 'xclip -o -selection clipboard'
end

if command -sq bat
    alias cat bat
end

alias !! 'eval $history[1]'
alias clear 'clear && _prompt_move_to_bottom'
