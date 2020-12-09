#!/usr/bin/env zsh

echo ""
echo ":: setting up lua things"

if (which luarocks &>/dev/null); then
  echo ""
  echo ":: attempting to install luarocks related tings"

if (which lua-lsp &>/dev/null); then
  luarocks install --server=http://luarocks.org/dev lua-lsp
fi

if (which luacheck &>/dev/null); then
    luarocks install luacheck
fi

if (which lcf &>/dev/null); then
    luarocks install lcf
fi

if (which luaformatter &>/dev/null); then
    luarocks install --server=https://luarocks.org/dev luaformatter
fi
else
  echo ":: ERROR: unable to run luarocks command from ln 12-14; likely luarocks isn't available"
fi
