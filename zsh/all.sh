#!/usr/bin/env zsh

echo ""
echo ":: setting up zsh related things"
echo ""

ln -sfv $DOTS/zsh $HOME/.zsh
ln -sfv $DOTS/zsh $HOME/.config/zsh

# to hopefully pull down what we need for the gitstatus plugin submodule
cd $DOTS/zsh/plugins/gitstatus && git pull && git submodule update --init --recursive && cd -
