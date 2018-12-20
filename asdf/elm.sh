#!/usr/bin/env zsh

echo ""
echo ":: setting up elm things"
echo ""

echo "PWD: $PWD"

if [[ -f "$HOME/.dotfiles/bin/elm-language-server-exe" ]]; then
  echo ""
  echo ":: found existing elm-language-server-exe binary; deleting it.."
  echo ""

  rm $HOME/.dotfiles/bin/elm-language-server-exe
fi

cd $HOME/.dotfiles/bin

# -- install elm-language-server via latest binary release
wget https://github.com/$(wget https://github.com/jaredramirez/elm-language-server/releases/latest -O - | egrep '/.*/.*/.*elm-language-server-exe' -o)
chmod +x elm-language-server-exe
cd -
