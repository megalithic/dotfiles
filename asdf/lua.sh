#!/usr/bin/env zsh

echo ""
echo ":: setting up lua things"

luarocks install --server=http://luarocks.org/dev lua-lsp
luarocks install luacheck
luarocks install lcf
luarocks install --server=https://luarocks.org/dev luaformatter
