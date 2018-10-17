#!/usr/bin/env zsh

# installs lua things

echo ""
echo ":: setting up lua things..."
echo ""

luarocks install --server=http://luarocks.org/dev lua-lsp
luarocks install luacheck
luarocks install lcf
