function wt --description 'Worktrunk wrapper: thin shell glue around ~/.dotfiles/bin/wt'
    # All logic (config path, implicit switch, --create/--yes injection,
    # target mode) lives in the shell-agnostic script. This function only
    # applies the things a child process cannot do: cd, env vars, exec eval.
    set -l d (mktemp -d)
    env WT_SHELL=fish WT_CD_FILE=$d/cd WT_ENV_FILE=$d/env WT_EXEC_FILE=$d/exec \
        ~/.dotfiles/bin/wt $argv
    set -l rc $status

    if test -s $d/cd
        cd -- (string trim <$d/cd)
        set -l cd_rc $status
        test $rc -eq 0; and set rc $cd_rc
    end
    if test -s $d/env
        source $d/env
    end
    if test -s $d/exec
        eval (string collect <$d/exec)
        set -l ex_rc $status
        test $rc -eq 0; and set rc $ex_rc
    end

    command rm -rf $d
    return $rc
end
