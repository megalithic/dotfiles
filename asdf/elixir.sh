#!/usr/bin/env zsh

echo ""
echo ":: setting up elixir things"
echo ""

rm -rf $HOME/.elixir-ls
mkdir -p $HOME/.elixir-ls

cd $HOME/.elixir-ls

# install elixir-ls via latest zip archive
# wget https://github.com/$(wget https://github.com/jakebecker/elixir-ls/releases/latest -O - | egrep '/.*/.*/.*zip' -o)
# unzip elixir-ls.zip
# rm elixir-ls.zip

if (which mix &>/dev/null); then
  echo ""
  echo ":: attempting to install elixir/mix/local.hex things"
  echo ""

  # install elixir-ls via git and compile
  git clone git@github.com:JakeBecker/elixir-ls.git "$HOME/.elixir-ls"
  cd "$HOME/.elixir-ls" && mkdir rel
  mix deps.get && mix compile
  mix elixir_ls.release -o rel

  mix local.hex --force --if-missing
else
  echo ":: ERROR: unable to run mix command from ln 20; likely elixir/mix isn't available"
fi

if [[ -f "$HOME/.elixir-ls/language_server.sh" ]]; then
  chmod +x $HOME/.elixir-ls/language_server.sh
fi
