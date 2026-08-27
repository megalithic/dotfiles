# Fish completion for `devenv tasks run <task>`

function __fish_devenv_list_tasks
    type -q devenv; or return 0
    devenv tasks list 2>/dev/null | string replace -r '^.*── ' ''
end

function __fish_devenv_should_complete_tasks
    __fish_seen_subcommand_from tasks; or return 1
    __fish_seen_subcommand_from run; or return 1

    set -l token (commandline -ct)
    string match -qr '^-' -- $token; and return 1

    __fish_prev_arg_in \
        --mode -m \
        --log-format \
        --trace-export-file \
        --max-jobs -j \
        --cores -u \
        --system -s \
        --clean -c \
        --nix-option -n \
        --override-input -o \
        --option -O \
        --profile -P
    and return 1

    return 0
end

complete -c devenv -n __fish_devenv_should_complete_tasks -f -a '(__fish_devenv_list_tasks)' -d Task
