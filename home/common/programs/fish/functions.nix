# Fish shell functions
{ isDarwin, wtBin }:
{
  fish_greeting = "";

  # Local Worktrunk wrapper (replaces upstream `wt config shell init fish`).
  # Vendors upstream directive handling (cd/exec temp files + WORKTRUNK_SHELL=fish)
  # and adds two local behaviors:
  #   - implicit switch: `wt @` / `wt some-branch` => `wt switch ...`
  #   - tmux targets: `-t/--target window|session` routes navigation through
  #     bin/wt-tmux-target using Worktrunk JSON metadata, leaving parent cwd intact.
  # Known built-ins stay pass-through; help/version never become switches.
  wt = {
    description = "Worktrunk wrapper: vendored directives + implicit switch + tmux targets";
    body = ''
      set -l wt_bin "${wtBin}"
      # WORKTRUNK_BIN overrides the binary (e.g. for testing dev builds).
      test -n "$WORKTRUNK_BIN"; and set wt_bin "$WORKTRUNK_BIN"

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
    '';
  };

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

  helium = {
    description = "Launch Helium with declarative flags";
    body = ''
      set -l helium /Applications/Helium.app/Contents/MacOS/Helium
      if not test -x $helium
        echo "Helium executable not found: $helium" >&2
        return 1
      end

      $helium \
        --no-first-run \
        --no-default-browser-check \
        --hide-crashed-bubble \
        --ignore-gpu-blocklist \
        --disable-breakpad \
        --disable-wake-on-wifi \
        --no-pings \
        --disable-features=OutdatedBuildDetector \
        $argv \
        >/dev/null 2>&1 &
      disown
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

  jj = {
    wraps = "jj";
    description = "Run jj, or git with same args inside git repos without .jj";
    body = ''
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
    '';
  };

  ask = ''
    set -l model "hf:deepseek-ai/DeepSeek-V3.2"
    set -l question
    set -l args

    # Parse flags
    while test (count $argv) -gt 0
        switch $argv[1]
            case -m --model
                # Present synthetic models to choose from
                set -l models (pi --list-models 2>/dev/null | rg "^synthetic" | awk '{print $2}')
                if test -z "$models"
                    echo "No synthetic models found"
                    return 1
                end
                set model (printf "%s\n" $models | gum choose --header "Select model:")
                if test -z "$model"
                    return 0  # User cancelled
                end
                set -e argv[1]
            case '*'
                set -a args $argv[1]
                set -e argv[1]
        end
    end

    # If no arguments, prompt for input with textarea
    if test (count $args) -eq 0
        set question (gum write --placeholder "Ask pi a question..." --header "Question:" --char-limit 0)
        if test -z "$question"
            return 0  # User cancelled
        end
    else
        set question (string join " " $args)
    end

    # Run pi with spinner, capture output to temp file (avoids quoting issues)
    set -l outfile (mktemp)
    gum spin --spinner dot --title "Asking $model..." -- sh -c 'pi -p --no-session --no-tools --provider synthetic --model "$1" "$2" 2>/dev/null > "$3"' _ "$model" "$question" "$outfile"

    # Render with glow if available
    if command -q glow
        glow < $outfile
    else
        cat $outfile
    end

    rm -f $outfile
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
      if isDarwin then "open" else "xdg-open"
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

  # Git worktree helper - list worktree names
  __git_worktree_names = ''
    set -l git_common_dir (git rev-parse --git-common-dir 2>/dev/null)
    test -z "$git_common_dir"; and return

    set -l repo_root (dirname "$git_common_dir")
    set -l worktrees_dir "$repo_root/.worktrees"

    test -d "$worktrees_dir"; or return

    for dir in "$worktrees_dir"/*/
      basename "$dir"
    end
  '';

  # Create new worktree for a branch
  git-worktree-new = ''
    if test (count $argv) -lt 1
      echo "Usage: git-worktree-new <branch_name>"
      return 1
    end

    set -l branch_name $argv[1]
    set -l repo_root (git rev-parse --show-toplevel 2>/dev/null)
    if test -z "$repo_root"
      echo "Error: Not in a git repository"
      return 1
    end

    set -l worktree_path "$repo_root/.worktrees/$branch_name"
    mkdir -p "$repo_root/.worktrees"

    echo "Creating worktree for branch: $branch_name"
    echo "Location: $worktree_path"

    set -l has_git_crypt false
    if test -d "$repo_root/.git/git-crypt"
      set has_git_crypt true
    end

    if test "$has_git_crypt" = true
      echo "Detected git-crypt encryption"
      git -c filter.git-crypt.smudge=cat -c filter.git-crypt.clean=cat worktree add "$worktree_path" -b "$branch_name"

      set -l worktree_basename (basename "$worktree_path")
      set -l git_crypt_target "$repo_root/.git/git-crypt"
      set -l git_crypt_link "$repo_root/.git/worktrees/$worktree_basename/git-crypt"

      if test -d "$git_crypt_target"; and not test -e "$git_crypt_link"
        ln -s "$git_crypt_target" "$git_crypt_link"
      end

      cd "$worktree_path"; or return 1
      git checkout -- . 2>/dev/null
    else
      git worktree add "$worktree_path" -b "$branch_name"
      cd "$worktree_path"; or return 1
    end

    set -l status_output (git status --short)
    if test -n "$status_output"
      echo "Warning: Worktree has uncommitted changes:"
      echo "$status_output"
    end

    echo ""
    echo "✓ Worktree created successfully"
  '';

  # Create worktree from PR branch
  git-worktree-pr = ''
    if test (count $argv) -lt 1
      echo "Usage: git-worktree-pr <branch_name>"
      return 1
    end

    set -l branch_name $argv[1]
    set -l repo_root (git rev-parse --show-toplevel 2>/dev/null)
    if test -z "$repo_root"
      echo "Error: Not in a git repository"
      return 1
    end

    set -l pr_number (gh pr list --state open --head "$branch_name" --json number --jq '.[0].number' 2>/dev/null)
    if test -z "$pr_number"; or test "$pr_number" = "null"
      echo "Error: Could not find an open PR for branch $branch_name"
      return 1
    end

    set -l worktree_path "$repo_root/.worktrees/$branch_name"
    mkdir -p "$repo_root/.worktrees"

    echo "Fetching PR #$pr_number ($branch_name)..."
    git fetch origin "pull/$pr_number/head:$branch_name" 2>&1 | grep -v "^From "

    echo "Creating worktree for branch: $branch_name"

    set -l has_git_crypt false
    if test -d "$repo_root/.git/git-crypt"
      set has_git_crypt true
    end

    if test "$has_git_crypt" = true
      echo "Detected git-crypt encryption"
      git -c filter.git-crypt.smudge=cat -c filter.git-crypt.clean=cat worktree add "$worktree_path" "$branch_name"

      set -l worktree_basename (basename "$worktree_path")
      set -l git_crypt_target "$repo_root/.git/git-crypt"
      set -l git_crypt_link "$repo_root/.git/worktrees/$worktree_basename/git-crypt"

      if test -d "$git_crypt_target"; and not test -e "$git_crypt_link"
        ln -s "$git_crypt_target" "$git_crypt_link"
      end

      cd "$worktree_path"; or return 1
      git checkout -- . 2>/dev/null
    else
      git worktree add "$worktree_path" "$branch_name"
      cd "$worktree_path"; or return 1
    end

    set -l status_output (git status --short)
    if test -n "$status_output"
      echo "Warning: Worktree has uncommitted changes:"
      echo "$status_output"
    end

    echo ""
    echo "✓ PR #$pr_number checked out successfully"
    echo "Location: $worktree_path"
  '';

  # Remove worktree and delete its branch
  git-worktree-prune = ''
    if test (count $argv) -lt 1
      echo "Usage: git-worktree-prune <branch_name>"
      return 1
    end

    set -l branch_name $argv[1]
    set -l repo_root (git rev-parse --show-toplevel 2>/dev/null)
    if test -z "$repo_root"
      echo "Error: Not in a git repository"
      return 1
    end

    set -l worktree_path "$repo_root/.worktrees/$branch_name"

    if not test -d "$worktree_path"
      echo "Error: Could not find worktree for branch $branch_name"
      echo ""
      echo "Available worktrees:"
      git worktree list
      return 1
    end

    echo "Removing worktree: $worktree_path"
    git worktree remove "$worktree_path" --force
    echo "✓ Worktree removed"

    if git show-ref --verify --quiet "refs/heads/$branch_name"
      echo "Deleting branch: $branch_name"
      git branch -D "$branch_name"
      echo "✓ Branch deleted"
    end
  '';

  # Change directory to existing worktree
  git-worktree-cd = ''
    if test (count $argv) -lt 1
      echo "Usage: git-worktree-cd <branch_name>"
      return 1
    end

    set -l branch_name $argv[1]
    set -l repo_root (git rev-parse --show-toplevel 2>/dev/null)
    if test -z "$repo_root"
      echo "Error: Not in a git repository"
      return 1
    end

    set -l worktree_path "$repo_root/.worktrees/$branch_name"

    if not test -d "$worktree_path"
      echo "Error: Could not find worktree for branch $branch_name"
      echo ""
      echo "Available worktrees:"
      git worktree list
      return 1
    end

    cd "$worktree_path"; or return 1
  '';

  # Devenv auto-activation on directory change — disabled for now; may re-enable later.
  # __devenv_auto = {
  #   onEvent = "fish_postexec";
  #   body = ''
  #     if test -f "$PWD/devenv.nix"; and not set -q IN_NIX_SHELL
  #       devenv shell
  #     end
  #   '';
  # };
}
