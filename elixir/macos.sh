#!/usr/bin/env zsh

echo ":: setting up elixir things"

if [[ ! -d "$HOME/.elixir-ls" ]]
then
  rm -rf $HOME/.elixir-ls
fi
mkdir $HOME/.elixir-ls

cd $HOME/.elixir-ls
wget https://github.com/$(wget https://github.com/jakebecker/elixir-ls/releases/latest -O - | egrep '/.*/.*/.*zip' -o)
unzip elixir-ls.zip
rm elixir-ls.zip

if (which mix &>/dev/null); then
  echo ""
  echo ":: attempting to install elixir/mix/local.hex things"
  mix local.hex --force --if-missing
else
  echo ":: ERROR: wasn't able to run mix command from ln 19"
fi

chmod +x $HOME/.elixir-ls/language_server.sh
