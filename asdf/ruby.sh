#!/usr/bin/env zsh

echo ""
echo "### ruby-specific tasks..."
echo ""

echo ""
echo "Symlinking ruby related things..."
echo ""
mkdir -p  $HOME/.bundle
rm  -rf   $HOME/.bundle/config \
          $HOME/invoker.ini

ln -sfv $DOTS/ruby/bundler          $HOME/.bundle/config

#echo ":: installing ruby packages..."
#$DOTS/ruby/package-installer

#if (which yard &>/dev/null); then
#  echo ":: configuring yard..."
#  echo ""
#  yard config --gem-install-yri
#else
#  echo ":: ERROR: wasn't able to run yard command from ln 21"
#fi

