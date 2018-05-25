#!/bin/sh

echo "installing python packages"

pip3 install --upgrade pip
sh ~/.dotfiles/python/package-installer

echo "finished python setup"
