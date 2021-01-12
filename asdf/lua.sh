#!/usr/bin/env zsh
# shellcheck shell=bash

log "installing luarocks modules"
if (command -v luarocks &> /dev/null); then
  (! command -v luacheck &> /dev/null) && luarocks install luacheck
  (! command -v lcf &> /dev/null) && luarocks install lcf
  (! command -v lua-lsp &> /dev/null) && luarocks install --server=https://luarocks.org/dev lua-lsp
  (! command -v lua-format &> /dev/null) && luarocks install --server=https://luarocks.org/dev luaformatter
fi

log "installing sumneko lua-language-server"
build_path="$XDG_CONFIG_HOME/sumneko_lua"

git clone https://github.com/sumneko/lua-language-server "$build_path"
cd "$build_path"
git submodule update --init --recursive

cd 3rd/luamake
ninja -f "ninja/$PLATFORM.ninja"
cd ../..
./3rd/luamake/luamake rebuild && log_ok "DONE building sumneko_lua" || log_error "failed to build sumneko_lua"

unset build_path
