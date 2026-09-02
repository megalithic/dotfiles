function _fzf_preview_file
    # Collect args into one variable because fzf preview may split paths.
    set -f file_path $argv

    if test -L "$file_path"
        set -l target_path (realpath "$file_path")

        set_color yellow
        echo "'$file_path' is a symlink to '$target_path'."
        set_color normal

        _fzf_preview_file "$target_path"
    else if test -f "$file_path"
        if set --query fzf_preview_file_cmd
            eval "$fzf_preview_file_cmd '$file_path'"
        else
            bat --style=numbers --color=always "$file_path"
        end
    else if test -d "$file_path"
        if set --query fzf_preview_dir_cmd
            eval "$fzf_preview_dir_cmd '$file_path'"
        else
            command eza -ahFT -L=1 --color=always --icons=always --sort=size --group-directories-first "$file_path"
        end
    else if test -c "$file_path"
        _fzf_report_file_type "$file_path" "character device file"
    else if test -b "$file_path"
        _fzf_report_file_type "$file_path" "block device file"
    else if test -S "$file_path"
        _fzf_report_file_type "$file_path" socket
    else if test -p "$file_path"
        _fzf_report_file_type "$file_path" "named pipe"
    else
        command preview "$file_path"
    end
end
