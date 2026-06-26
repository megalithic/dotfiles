function fzf-jj-bookmarks
    set -l bookmark (jj bookmark list --template 'if(!remote, name ++ "\n")' 2>/dev/null | fzf --height 40% --reverse --prompt="Bookmark> ")
    if test -n "$bookmark"
        commandline -i "$bookmark"
    end
    commandline -f repaint
end
