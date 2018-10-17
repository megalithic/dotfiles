#!/usr/bin/env zsh

echo ""
echo ":: setting up elixir things"
echo ""

rm -rf $HOME/.elixir-ls
mkdir -p $HOME/.elixir-ls

cd $HOME/.elixir-ls
wget https://github.com/$(wget https://github.com/jakebecker/elixir-ls/releases/latest -O - | egrep '/.*/.*/.*zip' -o)
unzip elixir-ls.zip
rm elixir-ls.zip

if (which mix &>/dev/null); then
  echo ""
  echo ":: attempting to install elixir/mix/local.hex things"
  echo ""
  
  mix local.hex --force --if-missing
else
  echo ":: ERROR: wasn't able to run mix command from ln 19"
fi

chmod +x $HOME/.elixir-ls/language_server.sh
