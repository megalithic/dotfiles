function git-worktree-new
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
end
