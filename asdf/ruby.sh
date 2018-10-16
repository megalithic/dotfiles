#!/usr/bin/env zsh

echo "### ruby-specific tasks..."
echo ""

echo "Symlinking things..."
echo ""
mkdir -p  $HOME/.bundle
rm  -rf   $HOME/.bundle/config \
          $HOME/invoker.ini

ln -sfv $DOTS/ruby/bundler          $HOME/.bundle/config
#ln -sfv $DOTS/ruby/invoker.ini      $HOME/invoker.ini

#echo ":: installing ruby packages..."
#$DOTS/ruby/package-installer

if (( $+commands[yard] )); then
  echo ":: configuring yard..."
  echo ""
  yard config --gem-install-yri
else
  echo ":: ERROR: wasn't able to run `yard` command from ln 21"
fi

