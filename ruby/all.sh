#!/bin/zsh

echo "## RUBY..."

ruby-install ruby 2.3.1
source /usr/local/share/chruby/chruby.sh
source /usr/local/share/chruby/auto.sh
RUBIES=($HOMEDIR/.rubies/*)
chruby ruby-2.3.1

rbenv global 2.3.1
rbenv rehash
$DOTS/ruby/package-installer
rbenv rehash

mkdir -p  $HOMEDIR/.bundle
rm  -rf   $HOMEDIR/.bundle/config \
          $HOMEDIR/.gemrc         \
          $HOMEDIR/.pryrc         \
          $HOMEDIR/.rubocop.yml   \
          $HOMEDIR/.reek

ln -sfv $DOTS/ruby/bundler          $HOMEDIR/.bundle/config
# ln -s $DOTS/ruby/gemrc            $HOMEDIR/.gemrc
# ln -s $DOTS/ruby/pryrc            $HOMEDIR/.pryrc
# ln -s $DOTS/ruby/rubocop.yml      $HOMEDIR/.rubocop.yml
# ln -s $DOTS/ruby/reek.yml         $HOMEDIR/.reek

