function jj --description="Run jj, or git with same args inside git repos without .jj" --wraps="jj"
    if command jj root --ignore-working-copy >/dev/null 2>&1
        command jj $argv
        return $status
    end

    if test "$argv[1]" = git; and test "$argv[2]" = init
        command jj $argv
        return $status
    end

    if command git rev-parse --is-inside-work-tree >/dev/null 2>&1
        set_color dbbc7f
        printf 'Hint: '
        set_color normal
        printf 'not a jj repo in "."; run '
        set_color 7fbbb3
        printf '`jj git init`'
        set_color normal
        printf ' to initialize this repo. Using '
        set_color 7fbbb3
        printf '`git`'
        set_color normal
        printf ' instead.\n'

        command git $argv
        return $status
    end

    command jj $argv
end
