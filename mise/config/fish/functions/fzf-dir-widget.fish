function fzf-dir-widget
    # Directly use fd binary to avoid output buffering delay caused by aliases.
    # Debian-based distros install fd as fdfind and the fd package is something else.
    set -f fd_cmd (command -v fdfind || command -v fd || echo "fd")
    set -f --append fd_cmd --color=always $fzf_fd_opts --type d

    set -f fzf_arguments --multi --ansi $fzf_directory_opts
    set -f token (commandline --current-token)
    set -f expanded_token (eval echo -- $token)
    set -f unescaped_exp_token (string unescape -- $expanded_token)

    if string match --quiet -- "*/" $unescaped_exp_token; and test -d "$unescaped_exp_token"
        set --append fd_cmd --base-directory=$unescaped_exp_token
        set --prepend fzf_arguments --prompt="Directory $unescaped_exp_token> " --preview="_fzf_preview_file $expanded_token{}"
        set -f file_paths_selected $unescaped_exp_token($fd_cmd 2>/dev/null | command fzf $fzf_arguments)
    else
        set --prepend fzf_arguments --prompt="Directory> " --query="$unescaped_exp_token" --preview='_fzf_preview_file {}'
        set -f file_paths_selected ($fd_cmd 2>/dev/null | command fzf $fzf_arguments)
    end

    if test $status -eq 0
        commandline --current-token --replace -- (string escape -- $file_paths_selected | string join ' ')
    end

    commandline --function repaint
end
