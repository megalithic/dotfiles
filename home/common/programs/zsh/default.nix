{
  config,
  pkgs,
  ...
}: let
  # Git worktree functions - must be shell functions (not scripts) for cd
  worktreeFunctions = ''
    __git_worktree_names() {
      local git_common_dir
      git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
      if [ -z "$git_common_dir" ]; then
        return
      fi

      local repo_root worktrees_dir
      repo_root=$(dirname "$git_common_dir")
      worktrees_dir="$repo_root/.worktrees"

      if [ ! -d "$worktrees_dir" ]; then
        return
      fi

      for dir in "$worktrees_dir"/*/; do
        basename "$dir"
      done
    }

    git-worktree-new() {
      if [ $# -lt 1 ]; then
        echo "Usage: git-worktree-new <branch_name>"
        return 1
      fi

      local branch_name="$1"
      local repo_root
      repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
      if [ -z "$repo_root" ]; then
        echo "Error: Not in a git repository"
        return 1
      fi

      local worktree_path="$repo_root/.worktrees/$branch_name"
      mkdir -p "$repo_root/.worktrees"

      echo "Creating worktree for branch: $branch_name"
      echo "Location: $worktree_path"

      local has_git_crypt="false"
      if [ -d "$repo_root/.git/git-crypt" ]; then
        has_git_crypt="true"
      fi

      if [ "$has_git_crypt" = true ]; then
        echo "Detected git-crypt encryption"
        git -c filter.git-crypt.smudge=cat -c filter.git-crypt.clean=cat worktree add "$worktree_path" -b "$branch_name"

        local worktree_basename git_crypt_target git_crypt_link
        worktree_basename=$(basename "$worktree_path")
        git_crypt_target="$repo_root/.git/git-crypt"
        git_crypt_link="$repo_root/.git/worktrees/$worktree_basename/git-crypt"

        if [ -d "$git_crypt_target" ] && [ ! -e "$git_crypt_link" ]; then
          ln -s "$git_crypt_target" "$git_crypt_link"
        fi

        cd "$worktree_path" || return 1
        git checkout -- . 2>/dev/null
      else
        git worktree add "$worktree_path" -b "$branch_name"
        cd "$worktree_path" || return 1
      fi

      local status_output
      status_output=$(git status --short)
      if [ -n "$status_output" ]; then
        echo "Warning: Worktree has uncommitted changes:"
        echo "$status_output"
      fi

      echo ""
      echo "✓ Worktree created successfully"
    }

    git-worktree-pr() {
      if [ $# -lt 1 ]; then
        echo "Usage: git-worktree-pr <branch_name>"
        return 1
      fi

      local branch_name="$1"
      local repo_root
      repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
      if [ -z "$repo_root" ]; then
        echo "Error: Not in a git repository"
        return 1
      fi

      local pr_number
      pr_number=$(gh pr list --state open --head "$branch_name" --json number --jq '.[0].number' 2>/dev/null)
      if [ -z "$pr_number" ] || [ "$pr_number" = "null" ]; then
        echo "Error: Could not find an open PR for branch ''${branch_name}"
        return 1
      fi

      local worktree_path="$repo_root/.worktrees/$branch_name"
      mkdir -p "$repo_root/.worktrees"

      echo "Fetching PR #$pr_number ($branch_name)..."
      git fetch origin "pull/$pr_number/head:$branch_name" 2>&1 | grep -v "^From "

      echo "Creating worktree for branch: $branch_name"

      local has_git_crypt="false"
      if [ -d "$repo_root/.git/git-crypt" ]; then
        has_git_crypt="true"
      fi

      if [ "$has_git_crypt" = true ]; then
        echo "Detected git-crypt encryption"
        git -c filter.git-crypt.smudge=cat -c filter.git-crypt.clean=cat worktree add "$worktree_path" "$branch_name"

        local worktree_basename git_crypt_target git_crypt_link
        worktree_basename=$(basename "$worktree_path")
        git_crypt_target="$repo_root/.git/git-crypt"
        git_crypt_link="$repo_root/.git/worktrees/$worktree_basename/git-crypt"

        if [ -d "$git_crypt_target" ] && [ ! -e "$git_crypt_link" ]; then
          ln -s "$git_crypt_target" "$git_crypt_link"
        fi

        cd "$worktree_path" || return 1
        git checkout -- . 2>/dev/null
      else
        git worktree add "$worktree_path" "$branch_name"
        cd "$worktree_path" || return 1
      fi

      local status_output
      status_output=$(git status --short)
      if [ -n "$status_output" ]; then
        echo "Warning: Worktree has uncommitted changes:"
        echo "$status_output"
      fi

      echo ""
      echo "✓ PR #$pr_number checked out successfully"
      echo "Location: $worktree_path"
    }

    git-worktree-cd() {
      if [ $# -lt 1 ]; then
        echo "Usage: git-worktree-cd <branch_name>"
        return 1
      fi

      local branch_name="$1"
      local repo_root
      repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
      if [ -z "$repo_root" ]; then
        echo "Error: Not in a git repository"
        return 1
      fi

      local worktree_path="$repo_root/.worktrees/$branch_name"

      if [ ! -d "$worktree_path" ]; then
        echo "Error: Could not find worktree for branch ''${branch_name}"
        echo ""
        echo "Available worktrees:"
        git worktree list
        return 1
      fi

      cd "$worktree_path" || return 1
    }
  '';

  # Devenv auto-activation - override cd to check for devenv.nix
  devenvAutoActivation = ''
    __devenv_auto() {
      if [ -f "$PWD/devenv.nix" ] && [ -z "''${IN_NIX_SHELL:-}" ]; then
        devenv shell
      fi
    }

    chpwd_functions+=(__devenv_auto)
  '';

  # Zsh completions for worktree commands
  worktreeCompletions = ''
    __git_pr_branches_zsh() {
      local prs
      prs=$(gh pr list --state open --json number,title,author,createdAt,headRefName --limit 50 2>/dev/null)
      [ -z "$prs" ] && return
      echo "$prs" | jq -r '.[] | "\(.headRefName)"'
    }

    _git_worktree_names() {
      local git_common_dir
      git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
      [ -z "$git_common_dir" ] && return

      local repo_root worktrees_dir
      repo_root=$(dirname "$git_common_dir")
      worktrees_dir="$repo_root/.worktrees"

      [ ! -d "$worktrees_dir" ] && return

      local -a worktrees
      for dir in "$worktrees_dir"/*/; do
        worktrees+=($(basename "$dir"))
      done
      _describe 'worktree' worktrees
    }

    _git_pr_branches() {
      local -a branches
      branches=(''${(f)"$(__git_pr_branches_zsh)"})
      _describe 'pr branch' branches
    }

    compdef _git_worktree_names git-worktree-cd
    compdef _git_worktree_names git-worktree-new
    compdef _git_worktree_names git-worktree-prune
    compdef _git_pr_branches git-worktree-pr
  '';
in {
  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
    initContent = worktreeFunctions + devenvAutoActivation + worktreeCompletions;
  };
}
