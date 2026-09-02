function __fzf_complete
    set -l buffer (commandline -b)
    set -l token (commandline -ct)
    set -l cursor (commandline -C)

    set -l trimmed (string sub -s 1 -l $cursor -- "$buffer")

    set -l dir (
        if type -q eza
            echo "eza -lah --git --icons --color=always"
        else
            echo "ls -lah"
        end
    )

    set -l file (
        if type -q bat
            echo "bat --style=numbers --color=always --paging=never --wrap=never"
        else
            echo "cat"
        end
    )

    set -l preview '
fish -c "
    set f {}

    if test -d \$f
        '"$dir"' \$f
    else if test -f \$f
        '"$file"' \$f
    else if command -q \$f
        whatis \$f 2>/dev/null
    else if test -e \$f
        '"$dir"' \$f
    else
        echo \$f
    end
"
'

    set -l fzf_flags \
        --query="$token" \
        --height=~40% \
        --layout=reverse \
        --ansi \
        --preview="$preview" \
        --preview-window=down:50%:wrap

    set -l matches (complete --do-complete "$trimmed")

    set -l selected

    if test (count $matches) -eq 1
        set selected $matches[1]
    else
        set selected (
            printf '%s\n' $matches |
            fzf $fzf_flags $fzf_complete_opts
        )
    end

    set -l completion (string split \t -- "$selected")[1]

    if test -n "$completion"
        commandline -t -- (string replace -a ' ' '\ ' -- "$completion")
    end

    commandline -f repaint
end

