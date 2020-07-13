#!/usr/bin/env zsh

# REF: handy ways of asdf/elixir/erlang setup:
# https://github.com/skbolton/titan/blob/master/elixir/init.sls

# super verbose debugging of the running script:
# set -x

echo ""
echo ":: setting up elixir things"
echo "░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░"
echo "▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔";

if (which mix &>/dev/null); then
  echo ":: attempting to install elixir_ls/mix/local.hex related things..."
  echo ""

  project_root=$PWD

  # installs elixir_ls based on our $mix_root
  install_elixir_ls() {
    # FIXME: do we still need this?
    # if [[ -f "$mix_root/mix.exs" ]]; then
    #   pushd "$mix_root" && mix deps.get && popd
    # fi

    # -- find existing elixir-ls installations and remove them
    if [[ -d "$mix_root/.elixir_ls" ]]; then
      echo ""
      echo "-- found existing .elixir_ls at $mix_root/.elixir_ls; deleting..."
      echo ""

      rm -rf "$mix_root/.elixir_ls"
    fi

    echo ""
    echo "-- cloning elixir-ls into $mix_root..."
    echo ""

    pushd $mix_root && git clone git@github.com:elixir-lsp/elixir-ls.git .elixir_ls && popd

    echo ""
    echo "-- compiling elixir-ls..."
    echo ""
    pushd "$mix_root/.elixir_ls" \
      && rm .tool-versions \
      && mix local.hex --force \
      && mkdir rel \
      && mix deps.get \
      && mix compile \
      && mix elixir_ls.release -o rel \
      && chmod +x ./rel/language_server.sh \
      && popd
  }

  # initiates elixir_ls installation for a given $mix_file (from $1)
  install_elixir_ls_for_mix_file() {
    mix_file=$1
    mix_root=$(dirname "${mix_file}")

    echo ""
    echo ":: mix.exs found -> starting elixir-ls setup..."
    echo "   -- preparing setup..."
    echo "     * mix_file: $mix_file"
    echo "     * mix_root: $mix_root"
    echo "     * PWD: $PWD"
    echo ""

    (install_elixir_ls)

    echo ""
    echo " :: final mix deps.get for mix_root, $mix_root"
    echo ""

    pushd "$mix_root" \
      && mix deps.get \
      && popd


    echo ""
    echo ":: finished installing elixir-ls for $mix_file..."
    echo "░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░"
    echo ""
  }

  # initiates elixir_ls installation for $HOME
  install_elixir_ls_for_home() {
    mix_root="$HOME"

    echo ""
    echo ":: attempting install of elixir_ls into $mix_root..."
    echo ""

    (install_elixir_ls)

    echo ""
    echo ":: finished installing elixir-ls for $HOME..."
    echo "░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░"
    echo ""
  }

  # -- gets all mix.exs file roots; excluding a few..
  get_mix_files() {
    find $PWD -type f -name "mix.exs" \
      ! -path "**/deps/*" \
      ! -path "**/.elixir_ls/*" \
      ! -path "**/credo_extra/*"
  }

  if [[ "$#" -eq 1 && ("$1" == "-f" || "$1" == "--force") ]]; then
    (install_elixir_ls_for_home)
  else
    # -- target mix.exs root directories for setting up elixir-ls
    for mix_file in $(get_mix_files); do
      (install_elixir_ls_for_mix_file $mix_file)
    done
  fi
else
  echo ""
  echo ":: ERROR: unable to run mix command; likely elixir/mix isn't installed or in your PATH"
  echo ""
fi
