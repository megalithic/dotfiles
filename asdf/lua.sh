#!/usr/bin/env zsh

echo ""
echo ":: setting up lua things"

if (which luarocks &>/dev/null); then
  echo ""
  echo ":: attempting to install luarocks related tings"

  luarocks install --server=http://luarocks.org/dev lua-lsp
  luarocks install luacheck
  luarocks install lcf
else
  echo ":: ERROR: unable to run luarocks command from ln 12-14; likely luarocks isn't available"
fi
