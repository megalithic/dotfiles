#!/bin/zsh

echo "### ruby-specific tasks..."

$DOTS/ruby/package-installer

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

ln -sfv $DOTS/ruby/invoker.ini $HOME/invoker.ini
