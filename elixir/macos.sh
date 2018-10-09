#!/bin/zsh

if [[ ! -d $HOME/.elixir-ls ]]
then
  mkdir $HOME/.elixir-ls
fi

cd $HOME/.elixir-ls
wget https://github.com/$(wget https://github.com/jakebecker/elixir-ls/releases/latest -O - | egrep '/.*/.*/.*zip' -o)
unzip elixir-ls.zip
rm elixir-ls.zip

mix local.hex --force --if-missing

chmod +x $HOME/.elixir-ls/language_server.sh
