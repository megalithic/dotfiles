#!/bin/bash

# Initialize the previous directory
prev_dir=""

# Function to check dependencies
check_dependencies() {
  local DEPS=("mods")
  local MISSING_DEPS=()

  for dep in "${DEPS[@]}"; do
    if ! command -v $dep &>/dev/null; then
      MISSING_DEPS+=($dep)
    fi
  done

  if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    echo "The following dependencies are missing:"
    for dep in "${MISSING_DEPS[@]}"; do
      case $dep in
        "mods")
          echo "- mods: https://github.com/charmbracelet/mods"
          ;;
      esac
    done
    exit 1
  fi
}

# Function to determine if the current working directory is a git repository
function is_git_repository() {
  git -C . rev-parse 2>/dev/null
}

# Function to check for uncommitted changes
function has_uncommitted_changes() {
  git diff-index --quiet HEAD --
  if [ $? -ne 0 ]; then
    return 0 # has uncommitted changes
  fi
  return 1 # no uncommitted changes
}

# Prompt the user before stashing changes
function prompt_stash_changes() {
  read -p "You have uncommitted changes. Do you want to stash them? [y/N] " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    return 1 # stash changes
  fi
  return 0 # do not stash changes
}

# Determine the root directory of the current git repository
function get_repo_root() {
  git rev-parse --show-toplevel 2>/dev/null
}

# Function to check if the user has changed to a subdirectory of the repo
function changed_to_subdir() {
  local repo_root
  repo_root=$(get_repo_root)
  if [[ -z "$repo_root" ]]; then
    # not a git repository
    return 1
  fi
  local cwd
  cwd=$(realpath .)
  [[ "$cwd"/ != "$repo_root"/ && "$cwd"/ != "$repo_root/"* ]]
}

# Handle the case where the local repository's default branch has changed
function check_branch_switch() {
  local default_branch
  default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')

  git fetch origin "$default_branch"
  git checkout "$default_branch" && git pull origin "$default_branch"

}

# Check if the repository needs to be updated
function needs_pull() {
  git fetch --all --prune
  ! git diff --quiet HEAD "origin/$(git symbolic-ref --short HEAD)" 2>/dev/null && return 0 # needs to be updated
  return 1                                                                                  # up to date
}

autogit() {
  if is_git_repository; then

    # If the user navigates to a sub-directory of the original git repo, then we should not run autogit again
    if changed_to_subdir; then
      return
    fi

    # Check if the repository has any commits
    if [ -z "$(git rev-parse HEAD 2>/dev/null)" ]; then
      echo "The repository is brand new and doesn't have any commits."
      return
    fi

    # Check if the repository has a remote set up
    if [ -z "$(git config --get remote.origin.url)" ]; then
      echo "The repository doesn't have a remote set up."
      return
    fi

    # Check if the repository needs to be updated
    if ! needs_pull; then
      echo "The repository is already up to date."
      return
    fi

    # Check for uncommitted changes
    if has_uncommitted_changes; then
      if prompt_stash_changes; then
        # User chose not to stash changes, abort
        echo "Aborting: uncommitted changes detected."
        return
      fi
      # Store the current branch as dirty (with stashed changes)
      dirty_branch=$(git branch --show-current)
      git stash save -u "autogit_$(date +%s)" >/dev/null 2>&1
      if git stash list | grep -q "autogit_"; then
        echo "Local changes stashed."
      fi
    fi

    # Save the current branch
    current_branch=$(git branch --show-current)

    # Check if the local repository's default branch has changed
    check_branch_switch

    # Pull changes to the default branch
    git checkout "$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')"
    git pull

    # Reset to the saved branch
    git checkout "$current_branch"

    # Unstash changes if necessary
    if [[ -n "$dirty_branch" ]]; then
      if git stash list | grep -q "autogit_"; then
        git stash apply "$(git stash list | grep "autogit_" | awk '{print $1}')"
        echo "Stashed changes applied to $dirty_branch."
      fi
      # Reset dirty_branch variable
      dirty_branch=""
    fi

    # Notify the user of successful completion
    echo "Autogit has successfully updated the repository."
  fi
}

run_autogit() {
  # Ensure user has dependencies installed
  check_dependencies

  local current_dir
  current_dir=$(pwd)
  for subdir in $(find "$current_dir" -type d -name .git); do
    cd "$(dirname "$subdir")" # change to the repository directory
    if [ "$prev_dir" != "$(pwd)" ]; then
      prev_dir="$(pwd)"
      autogit
    fi
  done
}

run_autogit
