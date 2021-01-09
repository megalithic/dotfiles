#!/usr/bin/env zsh

if (command -v luarocks &> /dev/null); then
  (! command -v luacheck &> /dev/null) && luarocks install luacheck
  (! command -v lcf &> /dev/null) && luarocks install lcf
  (! command -v lua-lsp &> /dev/null) && luarocks install --server=https://luarocks.org/dev lua-lsp
  (! command -v lua-format &> /dev/null) && luarocks install --server=https://luarocks.org/dev luaformatter
fi
