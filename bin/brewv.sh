#!/bin/bash
#
# Install specific version of a Homebrew formula
#
# Usage: brewv.sh formula_name desired_version
#
# Notes:
# - this will unshallow your brew repo copy. It might take some time the first time
#   you call this script
# - it will uninstall (instead of unlink) all your other versions of the formula.
#   Proper version management is out of scope of this script. Feel free to improve.
# - my "git log" uses less by default and when that happens it breaks the script
#   Therefore we have the "--max-count=20" parameter. This might fail to find proper
#   version if the one you wish to install is outside of this count.
#
# Author: Stanimir Karoserov ( demosten@gmail.com )
#

if [ "$#" -ne 2 ]; then
  echo "brewv.sh - installs specific version of a brew formula"
  echo "syntax: brewv.sh formula_name desired_version"
  echo "e.g.: brewv.sh swiftformat 0.39.1"
  exit 1
fi

git -C "$(brew --repo homebrew/core)" fetch --unshallow || echo "Homebrew repo already unshallowed"

# commit=$(brew log --max-count=20 --oneline $1|grep $2| head -n1| cut -d ' ' -f1)
# formula=$(brew log --max-count=20 --oneline $1|grep $2| head -n1| cut -d ':' -f1|cut -d ' ' -f2)

# if [ -z ${commit} ] || [ -z ${formula} ]; then
#   echo "No version matching '$2' for '$1'"
#   exit 1
# else
  if [[ -e $formula ]]; then
    /usr/local/bin/brew uninstall --force $1
  fi
  /usr/local/bin/brew tap-new $USER/local-tap || echo "Homebrew local-tap already exists" # /usr/local/Homebrew/Library/Taps/replicant/homebrew-local-tap/README.md
  /usr/local/bin/brew extract --version=$2 $1 $USER/local-tap
  /usr/local/bin/brew install $1@$2
  # /usr/local/bin/brew install https://raw.githubusercontent.com/Homebrew/homebrew-core/$commit/Formula/$formula.rb

  echo "$1@$2 installed."
# fi
