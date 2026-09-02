function pr
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

    set -l opener
    if command -sq open
        set opener open
    else if command -sq xdg-open
        set opener xdg-open
    else
        echo "Error: neither open nor xdg-open found"
        return 1
    end

    $opener "https://github.com/$PROJECT_PATH/compare/$MASTER_BRANCH...$GIT_BRANCH"
end
