#!/bin/zsh

echo "### ruby-specific tasks..."
echo ""

echo "Symlinking things..."
echo ""
mkdir -p  $HOME/.bundle
rm  -rf   $HOME/.bundle/config \
          $HOME/.gemrc         \
          $HOME/.pryrc         \
          $HOME/.rubocop.yml   \
          $HOME/.reek          \
          $HOME/invoker.ini

ln -sfv $DOTS/ruby/bundler          $HOME/.bundle/config
ln -sfv $DOTS/ruby/gemrc            $HOME/.gemrc
ln -sfv $DOTS/ruby/pryrc            $HOME/.pryrc
# ln -sfv $DOTS/ruby/rubocop.yml      $HOME/.rubocop.yml
# ln -sfv $DOTS/ruby/reek.yml         $HOME/.reek
ln -sfv $DOTS/ruby/invoker.ini      $HOME/invoker.ini

if type "yard" > /dev/null; then
  echo "Configuring yard..."
  echo ""
  yard config --gem-install-yri
fi

