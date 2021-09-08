#!/usr/bin/env zsh
# shellcheck shell=bash

log "installing luarocks modules"

if (command -v luarocks &>/dev/null); then
	(! command -v luacheck &>/dev/null) && luarocks install luacheck
	(! command -v lcf &>/dev/null) && luarocks install lcf
	(! command -v lua-lsp &>/dev/null) && luarocks install --server=https://luarocks.org/dev lua-lsp
	(! command -v lua-format &>/dev/null) && luarocks install --server=https://luarocks.org/dev luaformatter
fi

log "beginning sumneko lua-language-server installation.."
build_path="$XDG_CONFIG_HOME/lsp/sumneko_lua"

if [[ ! -d $build_path ]]; then
	log "cloning sumneko lua-language-server.."
	git clone https://github.com/sumneko/lua-language-server "$build_path" && log_ok "DONE cloning"
else
	log "deleting; and cloning sumneko lua-language-server.."
	rm -rf "$build_path"
	git clone https://github.com/sumneko/lua-language-server "$build_path" && log_ok "DONE cloning"
fi

cd "$build_path"
log "updating submodules.."
git submodule update --init --recursive && log_ok "DONE updating submodules"

log "building sumneko lua-language-server.."
cd "$build_path/3rd/luamake"
compile/install.sh
cd ../..
./3rd/luamake/luamake rebuild && log_ok "DONE building sumneko_lua" || log_error "failed to build sumneko_lua"

# rename our build platform folder to be all lowercase if it's `macOS` or `Linux`; ugh.
[[ $PLATFORM == "macos" ]] && mv $XDG_CONFIG_HOME/lsp/sumneko_lua/bin/macOS $XDG_CONFIG_HOME/lsp/sumneko_lua/bin/$PLATFORM
[[ $PLATFORM == "linux" ]] && mv $XDG_CONFIG_HOME/lsp/sumneko_lua/bin/Linux $XDG_CONFIG_HOME/lsp/sumneko_lua/bin/$PLATFORM

unset build_path
cd $HOME/.dotfiles
