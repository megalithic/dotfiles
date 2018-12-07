#!/usr/bin/env zsh

echo ""
echo ":: setting up elixir things"
echo ""
echo "CWD: $CWD"
echo "PWD: $PWD"

# rm -rf $HOME/.elixir-ls
# mkdir -p $HOME/.elixir-ls/rel

# cd $HOME/.elixir-ls/rel

# # install elixir-ls via latest zip archive
# wget https://github.com/$(wget https://github.com/jakebecker/elixir-ls/releases/latest -O - | egrep '/.*/.*/.*zip' -o)
# unzip elixir-ls.zip
# rm elixir-ls.zip

if (which mix &>/dev/null); then
  echo ""
  echo ":: attempting to install elixir/mix/local.hex things"
  echo ""

  # install elixir-ls via git and compile
  if [[ -d "$PWD/.elixir_ls" ]]; then
    echo "local .elixir_ls already exists; deleting existing folder and re-installing fresh."
    rm -rf .elixir_ls
  fi

  git clone git@github.com:JakeBecker/elixir-ls.git .elixir_ls
  cd .elixir_ls && mkdir rel
  mix deps.get && mix compile
  mix elixir_ls.release -o rel

  mix local.hex --force --if-missing
else
  echo ":: ERROR: unable to run mix command; likely elixir/mix isn't available"
fi

# if [[ -f "$HOME/.elixir-ls/rel/language_server.sh" ]]; then
#   chmod +x $HOME/.elixir-ls/rel/language_server.sh
# fi
