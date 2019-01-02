#!/usr/bin/env zsh

# super verbose debugging of the running script:
# set -x

echo ""
echo ":: setting up elixir things"
echo "░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░"
echo "▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔";

if (which mix &>/dev/null); then
  echo ":: attempting to install elixir/mix/local.hex things"
  echo ""

  project_root=$PWD

  install_elixir_ls_for_mix_file() {
    mix_file=$1
    mix_root=$(dirname "${mix_file}")

    echo ":: mix.exs found $mix_file -> starting elixir-ls setup...";
    echo "   -- preparing setup things:"
    echo "     * mix_file: $mix_file"
    echo "     * mix_root: $mix_root"
    echo "     * PWD: $PWD"
    echo ""

    # -- find existing elixir-ls installations and remove them
    if [[ -d "$mix_root/.elixir_ls" ]]; then
      echo ""
      echo "-- found existing .elixir_ls at $mix_root/.elixir_ls; deleting..."
      rm -rf "$mix_root/.elixir_ls"
    fi

    # -- install elixir-ls via git and compile
    echo ""
    echo "-- cd into $mix_root and cloning repo..."
    echo ""
    cd "$mix_root"
    git clone git@github.com:JakeBecker/elixir-ls.git .elixir_ls
    cd "$mix_root/.elixir_ls" && mkdir rel

    echo ""
    echo "-- compiling elixir-ls..."
    echo ""
    mix deps.get && mix compile
    mix elixir_ls.release -o rel

    echo ""
    echo "-- cd back to $project_root..."
    echo ""
    cd $project_root
    echo ":: finished installing elixir-ls for $mix_file...";
  }

  # -- gets all mix.exs file roots; excluding a few..
  get_mix_files() {
    find $PWD -type f -name "mix.exs" \
      ! -path "**/deps/*" \
      ! -path "**/.elixir_ls/*" \
      ! -path "**/credo_extra/*"
  }

  # -- target mix.exs root directories for setting up elixir-ls
  for mix_file in $(get_mix_files); do
    (install_elixir_ls_for_mix_file $mix_file)
  done
else
  echo ""
  echo ":: ERROR: unable to run mix command; likely elixir/mix isn't installed or in your PATH"
  echo ""
fi
