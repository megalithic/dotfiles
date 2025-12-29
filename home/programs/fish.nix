{
  config,
  pkgs,
  username,
  hostname,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
in {
  programs.fish = {
    # REF: https://github.com/agdral/home-default/blob/main/shell/fish/functions/develop.nix
    enable = true;
    shellInit = ''
      export PATH="/etc/profiles/per-user/${username}/bin:$PATH"
      set -g fish_prompt_pwd_dir_length 20
    '';
    interactiveShellInit = ''
      # Reset leaked mouse tracking modes on every prompt
      # Fixes: TUI apps (Claude Code, etc.) that enable SGR mouse mode (1003+1006)
      # but don't clean up on exit, causing trackball/mouse movements to appear
      # as garbage like "[<35;94;34M" in the prompt
      # Modes: 1000=basic, 1002=button-motion, 1003=any-motion, 1006=SGR encoding
      function __reset_mouse_mode --on-event fish_prompt
          printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l'
      end

      # I like to keep the prompt at the bottom rather than the top
      # of the terminal window so that running `clear` doesn't make
      # me move my eyes from the bottom back to the top of the screen;
      # keep the prompt consistently at the bottom
      # _prompt_move_to_bottom # call function manually to load it since event handlers don't get autoloaded

      set fish_cursor_default     block      blink
      set fish_cursor_insert      line       blink
      set fish_cursor_replace_one underscore blink
      set fish_cursor_visual      underscore blink

      # quickly open text file
      # bind -M insert ctrl-o '${pkgs.fzf}/bin/fzf | xargs -r $EDITOR'
      # bind ctrl-o '${pkgs.fzf}/bin/fzf | xargs -r $EDITOR'

      bind -M insert ctrl-a beginning-of-line
      bind -M normal ctrl-a beginning-of-line
      bind -M default ctrl-a beginning-of-line

      bind -M insert ctrl-e end-of-line
      bind -M normal ctrl-e end-of-line
      bind -M default ctrl-e end-of-line

      bind -M insert ctrl-y accept-autosuggestion
      bind -M normal ctrl-y accept-autosuggestion
      bind -M default ctrl-y accept-autosuggestion

      # edit command in $EDITOR
      bind -M insert ctrl-v edit_command_buffer
      bind ctrl-v edit_command_buffer

      # Rerun previous command
      bind -M insert ctrl-s 'commandline $history[1]' 'commandline -f execute'

      # restore old ctrl+c behavior; it should not clear the line in case I want to copy it or something
      # the new default behavior is stupid and bad, it just clears the current prompt
      # https://github.com/fish-shell/fish-shell/issues/11327
      bind -M insert -m insert ctrl-c cancel-commandline

      bind -M insert ctrl-d fzf-dir-widget
      bind -M normal ctrl-d fzf-dir-widget
      bind -M default ctrl-d fzf-dir-widget

      bind -M insert ctrl-b fzf-jj-bookmarks
      bind -M normal ctrl-b fzf-jj-bookmarks
      bind -M default ctrl-b fzf-jj-bookmarks

      bind -M insert ctrl-o fzf-vim-widget
      bind -M normal ctrl-o fzf-vim-widget
      bind -M default ctrl-o fzf-vim-widget


      # Emergency mouse mode reset (ctrl+shift+m doesn't work in fish, use escape sequence)
      # If garbage appears mid-command, press ctrl+g to reset mouse modes
      bind \cg 'printf "\e[?1000l\e[?1002l\e[?1003l\e[?1006l"; commandline -f repaint'

      # for `!!` and `!$`-like behaviour:
      bind ! bind_bang
      bind '$' bind_dollar

      # everforest theme
      set -l foreground d3c6aa
      set -l selection 2d4f67
      set -l comment 859289
      set -l red e67e80
      set -l orange ff9e64
      set -l yellow dbbc7f
      set -l green a7c080
      set -l purple d699b6
      set -l cyan 7fbbb3
      set -l pink d699b6

      # Syntax Highlighting Colors
      set -g fish_color_normal $foreground
      set -g fish_color_command $cyan
      set -g fish_color_keyword $pink
      set -g fish_color_quote $yellow
      set -g fish_color_redirection $foreground
      set -g fish_color_end $orange
      set -g fish_color_error $red
      set -g fish_color_param $purple
      set -g fish_color_comment $comment
      set -g fish_color_selection --background=$selection
      set -g fish_color_search_match --background=$selection
      set -g fish_color_operator $green
      set -g fish_color_escape $pink
      set -g fish_color_autosuggestion $comment

      # Completion Pager Colors
      set -g fish_pager_color_progress $comment
      set -g fish_pager_color_prefix $cyan
      set -g fish_pager_color_completion $foreground
      set -g fish_pager_color_description $comment

      # Darker background settings
      set -g fish_color_host_remote d699b6
      set -g fish_color_host 7fbbb3
      set -g fish_color_cancel e67e80
      set -g fish_pager_color_prefix 7fbbb3
      set -g fish_pager_color_completion d3c6aa
      set -g fish_pager_color_description 6c7b77
      set -g fish_pager_color_progress 7fbbb3

      # Set darker background for prompt
      set -g fish_color_cwd_root e67e80
      set -g fish_color_user 7fbbb3
    '';
    functions = {
      fish_greeting = "";

      # Manual mouse mode reset - call when you see garbage like "[<35;94;34M"
      # Also bound to ctrl+shift+m
      reset-mouse = ''
        printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l'
        echo "Mouse tracking modes reset"
      '';
      # _prompt_move_to_bottom = {
      #   onEvent = "fish_postexec";
      #   body = "tput cup $LINES";
      # };

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

      fzf-jj-bookmarks = ''
        set -l selected_bookmark (jj bookmark list | fzf --height 40%)
        if test -n "$selected_bookmark"
            # parse the bookmark name out of the full bookmark info line
            set -l bookmark_name (string split ":" "$selected_bookmark" | head -n 1 | string trim)
            commandline -i " $bookmark_name "
        end
        commandline -f repaint
      '';

      # ─────────────────────────────────────────────────────────────────
      # JJ Workspace Management (jj-ws-*)
      # ─────────────────────────────────────────────────────────────────

      # Create a new jj workspace with tmux window and optional bead task
      # Usage: jj-ws-new <name> [--no-task] [--base <revision>]
      jj-ws-new = ''
        argparse 'no-task' 'base=' -- $argv
        or return 1

        set -l ws_name $argv[1]
        if test -z "$ws_name"
            echo "Usage: jj-ws-new <name> [--no-task] [--base <revision>]"
            return 1
        end

        # Find repo root
        set -l repo_root (jj workspace root 2>/dev/null)
        if test -z "$repo_root"
            echo "Error: Not in a jj repository"
            return 1
        end

        set -l ws_dir "$repo_root/.workspaces/$ws_name"
        set -l base_rev (if set -q _flag_base; echo $_flag_base; else; echo "main"; end)

        # Check if workspace already exists
        if jj workspace list 2>/dev/null | grep -q "^$ws_name:"
            echo "Workspace '$ws_name' already exists. Use jj-ws-switch to switch to it."
            return 1
        end

        # Create workspace directory and jj workspace
        mkdir -p (dirname "$ws_dir")
        echo "Creating workspace '$ws_name' at $ws_dir..."
        jj workspace add "$ws_dir" --name "$ws_name" -r "$base_rev"
        or return 1

        # Create bead task if not --no-task and bd is available
        if not set -q _flag_no_task; and command -q bd
            # Check if task with this name exists
            set -l repo_prefix (basename $repo_root)
            if not bd show "$repo_prefix-$ws_name" 2>/dev/null
                echo "Creating bead task for workspace..."
                bd create "$ws_name" -t task -p P2 -l "workspace" -d "Workspace task for $ws_name" --silent
            end
        end

        # Create tmux window if in tmux
        if set -q TMUX
            set -l project_name (basename $repo_root)
            set -l window_name "$project_name:$ws_name"

            # Create new window and cd to workspace
            tmux new-window -n "$window_name" -c "$ws_dir"
            echo "Created tmux window '$window_name'"
        else
            # Not in tmux, just cd
            cd "$ws_dir"
            echo "Switched to workspace directory. (Not in tmux, no window created)"
        end

        echo "Workspace '$ws_name' ready!"
      '';

      # Switch to an existing jj workspace
      # Usage: jj-ws-switch <name>
      jj-ws-switch = ''
        set -l ws_name $argv[1]

        if test -z "$ws_name"
            # No name provided, use fzf picker
            set ws_name (jj-ws-list --picker)
            if test -z "$ws_name"
                return 0  # User cancelled
            end
        end

        # Find repo root
        set -l repo_root (jj workspace root 2>/dev/null)
        if test -z "$repo_root"
            echo "Error: Not in a jj repository"
            return 1
        end

        # Handle "default" workspace specially
        if test "$ws_name" = "default"
            set -l ws_dir "$repo_root"
        else
            set -l ws_dir "$repo_root/.workspaces/$ws_name"
        end

        # Verify workspace exists
        if not jj workspace list 2>/dev/null | grep -q "^$ws_name:"
            echo "Error: Workspace '$ws_name' does not exist"
            echo "Available workspaces:"
            jj workspace list
            return 1
        end

        # Switch tmux window if in tmux
        if set -q TMUX
            set -l project_name (basename $repo_root)
            set -l window_name "$project_name:$ws_name"

            # Check if window exists
            if tmux list-windows -F '#{window_name}' | grep -q "^$window_name\$"
                tmux select-window -t "$window_name"
            else
                # Window doesn't exist, create it
                if test "$ws_name" = "default"
                    tmux new-window -n "$window_name" -c "$repo_root"
                else
                    tmux new-window -n "$window_name" -c "$repo_root/.workspaces/$ws_name"
                end
            end
        else
            # Not in tmux, just cd
            if test "$ws_name" = "default"
                cd "$repo_root"
            else
                cd "$repo_root/.workspaces/$ws_name"
            end
        end
      '';

      # List jj workspaces, optionally with fzf picker
      # Usage: jj-ws-list [--picker]
      jj-ws-list = ''
        argparse 'picker' -- $argv
        or return 1

        # Find repo root
        set -l repo_root (jj workspace root 2>/dev/null)
        if test -z "$repo_root"
            echo "Error: Not in a jj repository"
            return 1
        end

        if set -q _flag_picker
            # Return just the name for scripting
            jj workspace list 2>/dev/null | fzf --height 40% --prompt="Workspace> " | string split ":" | head -n 1 | string trim
        else
            # Pretty print
            echo "Workspaces in "(basename $repo_root)":"
            jj workspace list
        end
      '';

      # Remove a jj workspace and its tmux window
      # Usage: jj-ws-rm <name> [--force]
      jj-ws-rm = ''
        argparse 'force' -- $argv
        or return 1

        set -l ws_name $argv[1]
        if test -z "$ws_name"
            echo "Usage: jj-ws-rm <name> [--force]"
            return 1
        end

        if test "$ws_name" = "default"
            echo "Error: Cannot remove the default workspace"
            return 1
        end

        # Find repo root
        set -l repo_root (jj workspace root 2>/dev/null)
        if test -z "$repo_root"
            echo "Error: Not in a jj repository"
            return 1
        end

        set -l ws_dir "$repo_root/.workspaces/$ws_name"

        # Check if we're currently in this workspace
        if test (pwd) = "$ws_dir"; or string match -q "$ws_dir/*" (pwd)
            echo "Error: Cannot remove workspace you're currently in"
            echo "Switch to another workspace first: jj-ws-switch default"
            return 1
        end

        # Confirm unless --force
        if not set -q _flag_force
            read -l -P "Remove workspace '$ws_name'? [y/N] " confirm
            if test "$confirm" != "y" -a "$confirm" != "Y"
                echo "Cancelled"
                return 0
            end
        end

        # Close tmux window if it exists
        if set -q TMUX
            set -l project_name (basename $repo_root)
            set -l window_name "$project_name:$ws_name"
            if tmux list-windows -F '#{window_name}' | grep -q "^$window_name\$"
                tmux kill-window -t "$window_name"
                echo "Closed tmux window '$window_name'"
            end
        end

        # Forget the workspace in jj
        jj workspace forget "$ws_name"
        or return 1

        # Remove the directory
        if test -d "$ws_dir"
            rm -rf "$ws_dir"
            echo "Removed workspace directory"
        end

        echo "Workspace '$ws_name' removed"
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
        # expand any variables or leading tilde (~) in the token
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
      fzf-vim-widget = ''
        # modified from fzf-file-widget
        set -l commandline $(__fzf_parse_commandline)
        set -l dir $commandline[1]
        set -l fzf_query $commandline[2]
        set -l prefix $commandline[3]

        # fd: -L = follow symlinks, --min-depth 1 = skip root dir, -tf -td -tl = files, dirs, symlinks
        # fd excludes hidden files by default (use -H to include them)
        test -n "$FZF_CTRL_T_COMMAND"; or set -l FZF_CTRL_T_COMMAND "
        fd -L --min-depth 1 -tf -td -tl . \$dir 2>/dev/null"

        test -n "$FZF_TMUX_HEIGHT"; or set FZF_TMUX_HEIGHT 40%
        begin
            set -lx FZF_DEFAULT_OPTS "--height $FZF_TMUX_HEIGHT --reverse --bind=ctrl-z:ignore $FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS"
            eval "$FZF_CTRL_T_COMMAND | "(__fzfcmd)' -m --query "'$fzf_query'"' | while read -l r
                set result $result $r
            end
        end
        if [ -z "$result" ]
            # _prompt_move_to_bottom
            commandline -f repaint
            return
        end
        set -l filepath_result
        for i in $result
            set filepath_result "$filepath_result$prefix"
            set filepath_result "$filepath_result$(string escape $i)"
            set filepath_result "$filepath_result "
        end
        # _prompt_move_to_bottom
        commandline -f repaint
        $EDITOR $result
      '';
    };

    shellAliases = {
      ls = "${pkgs.eza}/bin/eza --all --group-directories-first --color=always --hyperlink";
      l = "${pkgs.eza}/bin/eza --all --long --color=always --color-scale=all --group-directories-first --sort=type --hyperlink --icons=always --octal-permissions";
      # l = "${pkgs.eza}/bin/eza -lhF --group-directories-first --color=always --icons=always --hyperlink";
      ll = "${pkgs.eza}/bin/eza -lahF --group-directories-first --color=always --icons=always --hyperlink";
      la = "${pkgs.eza}/bin/eza -lahF --group-directories-first --color=always --icons=always --hyperlink";
      tree = "${pkgs.eza}/bin/eza --tree --color=always";
      # opencode = "${pkgs.opencode}";
      # oc = "op run --no-masking -- opencode";
      # claude = "op run --no-masking -- claude --allow-dangerously-skip-permissions";
      # claude = "op run --no-masking -- CLAUDE_CONFIG_DIR=~/.claude ${pkgs.ai-tools.claude-code} --allow-dangerously-skip-permissions";
      # claude-cspire = "op run --no-masking -- ${pkgs.ai-tools.claude-code} --allow-dangerously-skip-permissions";
      rm = "${pkgs.darwin.trash}/bin/trash -v";
      q = "exit";
      ",q" = "exit";
      mega = "ftm mega";
      copy =
        if isDarwin
        then "pbcopy"
        else "xclip -selection clipboard";
      paste =
        if isDarwin
        then "pbpaste"
        else "xlip -o -selection clipboard";
      cat = "bat";
      # clear = "clear && _prompt_move_to_bottom";
      # inspect $PATH
      pinspect = ''echo "$PATH" | tr ":" "\n"'';
      pathi = ''echo "$PATH" | tr ":" "\n"'';
      # brew = "op plugin run -- brew";
    };

    shellAbbrs = {
      nvim = "nvim -O";
      # "nh\ mac" = "nh darwin switch ./";
      vim = "nvim -O";
      j = "just";
      z = "zoxide";
      ju = "just";
      "!!" = "eval \\$history[1]";
    };

    plugins = [
      {
        name = "autopair";
        inherit (pkgs.fishPlugins.autopair) src;
      }
      {
        name = "nix-env";
        src = pkgs.fetchFromGitHub {
          owner = "lilyball";
          repo = "nix-env.fish";
          rev = "7b65bd228429e852c8fdfa07601159130a818cfa";
          hash = "sha256-RG/0rfhgq6aEKNZ0XwIqOaZ6K5S4+/Y5EEMnIdtfPhk";
        };
      }
      {
        name = "done";
        src = pkgs.fetchFromGitHub {
          owner = "franciscolourenco";
          repo = "done";
          rev = "d6abb267bb3fb7e987a9352bc43dcdb67bac9f06";
          sha256 = "6oeyN9ngXWvps1c5QAUjlyPDQwRWAoxBiVTNmZ4sG8E=";
        };
      }
    ];
  };
}
