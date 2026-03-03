# Fish shell functions
{
  config,
  isDarwin,
}: {
  fish_greeting = "";

  # Reload shell with fresh session variables
  # Extracts hm-session-vars.fish path from config.fish (it's a nix store path)
  sz = ''
    set -e __HM_SESS_VARS_SOURCED
    set -l vars_file (string match -r '/nix/store/[^ ]+hm-session-vars\.fish' < ~/.config/fish/config.fish)
    test -n "$vars_file"; and source $vars_file
    exec fish
  '';

  _prompt_move_to_bottom = {
    onEvent = "fish_postexec";
    body = "tput cup $LINES";
  };

  _prompt_reset_mouse = {
    onEvent = "fish_postexec";
    body = ''
      printf "\e[?1000l\e[?1002l\e[?1003l\e[?1006l"; commandline -f repaint
    '';
  };

  nix-shell = {
    wraps = "nix-shell";
    body = ''
      for ARG in $argv
          if [ "$ARG" = --run ]
              command nix-shell $argv
              return $status
          end
      end
      command nix-shell $argv --run "exec fish"
    '';
  };

  ask = ''
    if test (count $argv) -eq 0
        echo "Usage: ask <question>"
        return 1
    end

    set -l question (string join " " $argv)

    # Use pi with minimal noise, pipe through glow for markdown rendering if available
    if command -q glow
        pi -p --no-session --no-tools "$question" 2>/dev/null | glow -
    else
        pi -p --no-session --no-tools "$question" 2>/dev/null
    end
  '';

  pr = ''
    set -l PROJECT_PATH (git config --get remote.origin.url)
    set -l PROJECT_PATH (string replace "git@github.com:" "" "$PROJECT_PATH")
    set -l PROJECT_PATH (string replace "https://github.com/" "" "$PROJECT_PATH")
    set -l PROJECT_PATH (string replace ".git" "" "$PROJECT_PATH")
    set -l GIT_BRANCH (git branch --show-current || echo "")
    set -l MASTER_BRANCH (git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')

    if test -z "$GIT_BRANCH"
        set GIT_BRANCH (jj log -r @- --no-graph --no-pager -T 'self.bookmarks()')
    end

    if test -z "$GIT_BRANCH"
        echo "Error: not a git repository"
        return 1
    end
    ${
      if isDarwin
      then "open"
      else "xdg-open"
    } "https://github.com/$PROJECT_PATH/compare/$MASTER_BRANCH...$GIT_BRANCH"
  '';

  bind_bang = ''
    switch (commandline -t)[-1]
        case "!"
            commandline -t -- $history[1]
            commandline -f repaint
        case "*"
            commandline -i !
    end
  '';

  bind_dollar = ''
    switch (commandline -t)[-1]
        case "!"
            commandline -f backward-delete-char history-token-search-backward
        case "*"
            commandline -i '$'
    end
  '';

  _fzf_preview_file = ''
    # because there's no way to guarantee that _fzf_search_directory passes the path to _fzf_preview_file
    # as one argument, we collect all the arguments into one single variable and treat that as the path
    set -f file_path $argv

    if test -L "$file_path" # symlink
        # notify user and recurse on the target of the symlink, which can be any of these file types
        set -l target_path (realpath "$file_path")

        set_color yellow
        echo "'$file_path' is a symlink to '$target_path'."
        set_color normal

        _fzf_preview_file "$target_path"
    else if test -f "$file_path" # regular file
        if set --query fzf_preview_file_cmd
            # need to escape quotes to make sure eval receives file_path as a single arg
            eval "$fzf_preview_file_cmd '$file_path'"
        else
            bat --style=numbers --color=always "$file_path"
        end
    else if test -d "$file_path" # directory
        if set --query fzf_preview_dir_cmd
            # see above
            eval "$fzf_preview_dir_cmd '$file_path'"
        else
            # -A list hidden files as well, except for . and ..
            # -F helps classify files by appending symbols after the file name
            # command ls -A -F "$file_path"
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
        # echo "$file_path doesn't exist." >&2
    end
  '';

  fzf-dir-widget = ''
    # Directly use fd binary to avoid output buffering delay caused by a fd alias, if any.
    # Debian-based distros install fd as fdfind and the fd package is something else, so
    # check for fdfind first. Fall back to "fd" for a clear error message.
    set -f fd_cmd (command -v fdfind || command -v fd  || echo "fd")
    set -f --append fd_cmd --color=always $fzf_fd_opts --type d

    set -f fzf_arguments --multi --ansi $fzf_directory_opts
    set -f token (commandline --current-token)
    # expand any variables or leading tilde (~) in the token
    set -f expanded_token (eval echo -- $token)
    # unescape token because it's already quoted so backslashes will mess up the path
    set -f unescaped_exp_token (string unescape -- $expanded_token)

    # If the current token is a directory and has a trailing slash,
    # then use it as fd's base directory.
    if string match --quiet -- "*/" $unescaped_exp_token && test -d "$unescaped_exp_token"
        set --append fd_cmd --base-directory=$unescaped_exp_token
        # use the directory name as fzf's prompt to indicate the search is limited to that directory
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
  '';

  fzf-jj-bookmarks = ''
    # List jj bookmarks with fzf and insert selection
    set -l bookmark (jj bookmark list --template 'if(!remote, name ++ "\n")' 2>/dev/null | fzf --height 40% --reverse --prompt="Bookmark> ")
    if test -n "$bookmark"
      commandline -i "$bookmark"
    end
    commandline -f repaint
  '';
}
