#!/bin/zsh

echo "## RUBY..."

ruby-install ruby 2.3.1
source /usr/local/share/chruby/chruby.sh
source /usr/local/share/chruby/auto.sh
RUBIES=($HOME/.rubies/*)
chruby ruby-2.3.1

rbenv global 2.3.1
rbenv rehash
$DOTS/ruby/package-installer
rbenv rehash

mkdir -p  $HOME/.bundle
rm  -rf   $HOME/.bundle/config \
          $HOME/.gemrc         \
          $HOME/.pryrc         \
          $HOME/.rubocop.yml   \
          $HOME/.reek

ln -sfv $DOTS/ruby/bundler          $HOME/.bundle/config
# ln -s $DOTS/ruby/gemrc            $HOME/.gemrc
# ln -s $DOTS/ruby/pryrc            $HOME/.pryrc
# ln -s $DOTS/ruby/rubocop.yml      $HOME/.rubocop.yml
# ln -s $DOTS/ruby/reek.yml         $HOME/.reek

yard config --gem-install-yri
