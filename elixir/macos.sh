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

mix local.hex --force --if-missing

chmod +x $HOME/.elixir-ls/language_server.sh
