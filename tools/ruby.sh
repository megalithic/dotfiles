#!/usr/bin/env zsh

mkdir -p  $HOME/.bundle
rm  -rf   $HOME/.bundle/config \
          $HOME/invoker.ini

ln -sfv $DOTS/ruby/bundler          $HOME/.bundle/config
