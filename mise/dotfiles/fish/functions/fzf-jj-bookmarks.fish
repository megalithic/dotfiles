function fzf-jj-bookmarks
    # List jj bookmarks with fzf and insert selection
    set -l bookmark (jj bookmark list --template 'if(!remote, name ++ "\n")' 2>/dev/null | fzf --height 40% --reverse --prompt="Bookmark> ")
    if test -n "$bookmark"
        commandline -i "$bookmark"
    end
    commandline -f repaint
end
