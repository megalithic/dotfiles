#!/usr/bin/env zsh

if (command -v luarocks &> /dev/null); then
  luarocks install --server=http://luarocks.org/dev lua-lsp
  luarocks install luacheck
  luarocks install lcf
  luarocks install --server=https://luarocks.org/dev luaformatter
fi
