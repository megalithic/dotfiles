function wt --description "Worktrunk wrapper: vendored directives + implicit switch + tmux targets"
    set -l wt_bin "$WORKTRUNK_BIN"
    # WORKTRUNK_BIN overrides the binary (e.g. for testing dev builds).
    test -z "$wt_bin"; and set wt_bin (command -s wt)
    if test -z "$wt_bin"
        echo "wt: could not find Worktrunk binary on PATH" >&2
        return 127
    end

    # Split args at `--`: only our flags before it are parsed; everything from
    # `--` onward is forwarded verbatim (execute args).
    set -l pre
    set -l post
    set -l seen_ddash false
    set -l target ""
    set -l i 1
    set -l n (count $argv)
    while test $i -le $n
        set -l a $argv[$i]
        if test "$seen_ddash" = true
            set -a post $a
            set i (math $i + 1)
            continue
        end
        switch $a
            case --
                set seen_ddash true
                set -a post $a
            case -t --target
                set i (math $i + 1)
                if test $i -gt $n
                    echo "wt: $a requires a value (window|session)" >&2
                    return 2
                end
                set target $argv[$i]
            case '--target=*'
                set target (string replace -- '--target=' "" $a)
            case '-t=*'
                set target (string replace -- '-t=' "" $a)
            case '*'
                set -a pre $a
        end
        set i (math $i + 1)
    end

    if test -n "$target"; and test "$target" != window; and test "$target" != session
        echo "wt: invalid target '$target' (expected window|session)" >&2
        return 2
    end

    # Find the first non-flag token: that is the (potential) subcommand.
    set -l builtins switch list remove merge select step hook config
    set -l first_cmd ""
    for t in $pre
        if string match -q -- '-*' $t
            continue
        end
        set first_cmd $t
        break
    end

    set -l help_or_version false
    for t in $pre
        if contains -- $t --help -h --version -V
            set help_or_version true
            break
        end
    end
    test "$first_cmd" = help; and set help_or_version true

    set -l is_builtin false
    if contains -- $first_cmd $builtins
        set is_builtin true
    end

    # Decide whether to inject an implicit `switch`.
    set -l inject_switch false
    if test "$help_or_version" = false
        if test -n "$target"
            test "$is_builtin" = false; and set inject_switch true
        else if test "$is_builtin" = false; and test (count $pre) -gt 0
            set inject_switch true
        end
    end

    set -l call_args
    if test "$inject_switch" = true
        set call_args switch $pre
    else
        set call_args $pre
    end
    set -a call_args $post

    # ---- Target mode: Worktrunk owns the worktree, tmux helper owns nav ----
    if test -n "$target"
        if not contains -- switch $call_args
            set call_args switch $call_args
        end
        if not contains -- --no-cd $call_args
            set -a call_args --no-cd
        end
        set -l has_format false
        for a in $call_args
            if string match -q -- '--format*' $a
                set has_format true
                break
            end
        end
        test "$has_format" = false; and set -a call_args --format=json

        # Capture stdout (JSON). stderr/human lines pass through to terminal.
        set -l out ($wt_bin $call_args)
        set -l rc $status
        if test $rc -ne 0
            return $rc
        end

        # wt may emit human text alongside JSON; pick the line that parses.
        set -l branch ""
        set -l wpath ""
        for line in $out
            set -l p (printf '%s' $line | jq -r '.path // empty' 2>/dev/null)
            if test -n "$p"
                set wpath $p
                set branch (printf '%s' $line | jq -r '.branch // empty' 2>/dev/null)
            end
        end
        if test -z "$wpath"
            echo "wt: could not parse worktree path from Worktrunk JSON" >&2
            printf '%s\n' $out >&2
            return 1
        end

        wt-tmux-target --target $target --branch $branch --path $wpath
        test -n "$branch"; and set -gx GIT_WORKTREE "$branch"
        return $status
    end

    # ---- Normal mode: vendored upstream directive handling ----
    set -l cd_file (mktemp)
    set -l exec_file (mktemp)
    # WORKTRUNK_SHELL=fish makes the binary escape the exec directive for
    # fish's `eval` (fish treats `\` inside '...' unlike POSIX).
    env WORKTRUNK_DIRECTIVE_CD_FILE=$cd_file WORKTRUNK_DIRECTIVE_EXEC_FILE=$exec_file \
        WORKTRUNK_SHELL=fish \
        $wt_bin $call_args
    set -l exit_code $status

    # cd file holds a raw path — fish builtin read (no cat subprocess, safe
    # even if CWD was removed by worktree removal).
    if test -s "$cd_file"
        set -l tgt (string trim < "$cd_file")
        cd -- "$tgt"
        set -l cd_exit $status
        test $exit_code -eq 0; and set exit_code $cd_exit
        # Set GIT_WORKTREE so shells/services know the active worktree.
        set -l wt_branch (git branch --show-current 2>/dev/null)
        test -n "$wt_branch"; and set -gx GIT_WORKTREE "$wt_branch"
    end

    if test -s "$exec_file"
        set -l directive (string collect < "$exec_file")
        eval $directive
        set -l src_exit $status
        test $exit_code -eq 0; and set exit_code $src_exit
    end

    command rm -f "$cd_file" "$exec_file"
    return $exit_code
end
